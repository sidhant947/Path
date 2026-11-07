package com.sidhant.path.data

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log

class AutoBackup(private val context: Context, private val repository: StepRepository) {

    fun selectFolder(folderUri: Uri): Boolean {
        return try {
            context.contentResolver.takePersistableUriPermission(
                folderUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
            repository.setAutoBackupFolderUri(folderUri.toString())
            repository.setAutoBackupFolderName(getFolderName(folderUri) ?: folderUri.lastPathSegment ?: "")
            repository.setAutoBackupEnabled(true)
            val success = run()
            if (!success) repository.setAutoBackupEnabled(false)
            success
        } catch (e: Exception) {
            Log.w(TAG, "Could not access backup folder", e)
            false
        }
    }

    fun setEnabled(enabled: Boolean) {
        repository.setAutoBackupEnabled(enabled)
    }

    fun runIfDue(): Boolean = synchronized(LOCK) {
        if (!repository.isAutoBackupEnabled()) return false
        if (repository.getLastAutoBackupDate() == repository.getCurrentDateString()) return false
        runLocked()
    }

    fun run(): Boolean = synchronized(LOCK) {
        runLocked()
    }

    private fun runLocked(): Boolean {
        val folderUriString = repository.getAutoBackupFolderUri() ?: return false
        if (!repository.isAutoBackupEnabled()) return false
        return try {
            val folderUri = Uri.parse(folderUriString)
            val resolver = context.contentResolver
            val parentId = DocumentsContract.getTreeDocumentId(folderUri)
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(folderUri, parentId)
            val fileUri = findChild(resolver, childrenUri, FILE_NAME)
                ?: DocumentsContract.createDocument(resolver, childrenUri, MIME_TYPE, FILE_NAME)
                ?: return false

            resolver.openOutputStream(fileUri, "wt")?.use { outputStream ->
                repository.exportBackup(outputStream)
            } ?: return false

            repository.setLastAutoBackupDate(repository.getCurrentDateString())
            true
        } catch (e: Exception) {
            Log.w(TAG, "Auto backup failed", e)
            false
        }
    }

    private fun getFolderName(folderUri: Uri): String? {
        val documentUri = DocumentsContract.buildDocumentUriUsingTree(
            folderUri,
            DocumentsContract.getTreeDocumentId(folderUri)
        )
        context.contentResolver.query(
            documentUri,
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getString(0)
            }
        }
        return null
    }

    private fun findChild(resolver: ContentResolver, childrenUri: Uri, name: String): Uri? {
        resolver.query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME
            ),
            null,
            null,
            null
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val nameIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            while (cursor.moveToNext()) {
                if (cursor.getString(nameIndex) == name) {
                    return DocumentsContract.buildDocumentUriUsingTree(
                        childrenUri,
                        cursor.getString(idIndex)
                    )
                }
            }
        }
        return null
    }

    companion object {
        private val LOCK = Any()
        const val FILE_NAME = "Path.json"
        private const val MIME_TYPE = "application/json"
        private const val TAG = "AutoBackup"
    }
}
