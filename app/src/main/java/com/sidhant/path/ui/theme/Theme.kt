package com.sidhant.path.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.core.view.WindowCompat
import com.sidhant.path.R

val LimeAccent = Color(0xFFC7F900)
val PinkAccent = Color(0xFFFF007F)
val BlueAccent = Color(0xFF007BFF)
val GreenAccent = Color(0xFF2ECC71)
val OrangeAccent = Color(0xFFE67E22)

fun getAccentColor(name: String): Color {
    return when (name.lowercase()) {
        "pink" -> PinkAccent
        "blue" -> BlueAccent
        "green" -> GreenAccent
        "orange" -> OrangeAccent
        "lime" -> LimeAccent
        else -> runCatching {
            val hex = if (name.startsWith("#")) name else "#$name"
            Color(android.graphics.Color.parseColor(hex))
        }.getOrDefault(LimeAccent)
    }
}

val SpaceGroteskFontFamily = FontFamily(
    Font(R.font.space_grotesk, FontWeight.Normal),
    Font(R.font.space_grotesk, FontWeight.Medium),
    Font(R.font.space_grotesk, FontWeight.SemiBold),
    Font(R.font.space_grotesk, FontWeight.Bold),
    Font(R.font.space_grotesk, FontWeight.ExtraBold)
)

val AppTypography = Typography(
    displayLarge = TextStyle(fontFamily = SpaceGroteskFontFamily),
    displayMedium = TextStyle(fontFamily = SpaceGroteskFontFamily),
    displaySmall = TextStyle(fontFamily = SpaceGroteskFontFamily),
    headlineLarge = TextStyle(fontFamily = SpaceGroteskFontFamily),
    headlineMedium = TextStyle(fontFamily = SpaceGroteskFontFamily),
    headlineSmall = TextStyle(fontFamily = SpaceGroteskFontFamily),
    titleLarge = TextStyle(fontFamily = SpaceGroteskFontFamily),
    titleMedium = TextStyle(fontFamily = SpaceGroteskFontFamily),
    titleSmall = TextStyle(fontFamily = SpaceGroteskFontFamily),
    bodyLarge = TextStyle(fontFamily = SpaceGroteskFontFamily),
    bodyMedium = TextStyle(fontFamily = SpaceGroteskFontFamily),
    bodySmall = TextStyle(fontFamily = SpaceGroteskFontFamily),
    labelLarge = TextStyle(fontFamily = SpaceGroteskFontFamily),
    labelMedium = TextStyle(fontFamily = SpaceGroteskFontFamily),
    labelSmall = TextStyle(fontFamily = SpaceGroteskFontFamily)
)

private val DarkColorScheme = darkColorScheme(
    primary = LimeAccent,
    background = Color.Black,
    surface = Color(0xFF1A1A1A),
    onPrimary = Color.Black,
    onBackground = Color.White,
    onSurface = Color.White,
    surfaceVariant = Color(0xFF2C2C2C),
    onSurfaceVariant = Color.Gray,
    surfaceContainer = Color(0xFF0D0D0D),
    surfaceContainerHigh = Color(0xFF2A2A2A),
    outline = Color(0xFF333333),
    outlineVariant = Color(0xFF222222)
)

private val LightColorScheme = lightColorScheme(
    primary = LimeAccent,
    background = Color.White,
    surface = Color(0xFFF2F2F2),
    onPrimary = Color.Black,
    onBackground = Color.Black,
    onSurface = Color.Black,
    surfaceVariant = Color(0xFFE0E0E0),
    onSurfaceVariant = Color.Gray,
    surfaceContainer = Color.White,
    surfaceContainerHigh = Color(0xFFE0E0E0),
    outline = Color(0xFFD6D6D6),
    outlineVariant = Color(0xFFEAEAEA)
)

@Composable
fun PathTheme(
    themeMode: String = "system",
    accentColorName: String = "Lime",
    content: @Composable () -> Unit
) {
    val darkTheme = when (themeMode) {
        "light" -> false
        "dark" -> true
        else -> isSystemInDarkTheme()
    }

    val accentColor = getAccentColor(accentColorName)
    val baseScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    val colorScheme = baseScheme.copy(
        primary = accentColor,
        onPrimary = if (accentColor == BlueAccent || accentColor.luminance() < 0.4f) Color.White else Color.Black
    )

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                window.statusBarColor = colorScheme.background.toArgb()
                window.navigationBarColor = colorScheme.background.toArgb()
                WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
                WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        content = content
    )
}
