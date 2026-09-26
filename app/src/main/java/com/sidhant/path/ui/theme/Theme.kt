package com.sidhant.path.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.sidhant.path.R

val LimeAccent = Color(0xFFC7F900)
val PinkAccent = Color(0xFFFF007F)
val BlueAccent = Color(0xFF007BFF)
val GreenAccent = Color(0xFF2ECC71)
val OrangeAccent = Color(0xFFE67E22)

fun getAccentColor(name: String): Color {
    return when (name) {
        "Pink" -> PinkAccent
        "Blue" -> BlueAccent
        "Green" -> GreenAccent
        "Orange" -> OrangeAccent
        else -> LimeAccent
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
    surface = Color(0xFF121212),
    onPrimary = Color.Black,
    onBackground = Color.White,
    onSurface = Color.White
)

private val LightColorScheme = lightColorScheme(
    primary = LimeAccent,
    background = Color.White,
    surface = Color(0xFFF5F5F5),
    onPrimary = Color.Black,
    onBackground = Color.Black,
    onSurface = Color.Black
)

@Composable
fun PathTheme(
    themeMode: String = "system",
    content: @Composable () -> Unit
) {
    val darkTheme = when (themeMode) {
        "light" -> false
        "dark" -> true
        else -> isSystemInDarkTheme()
    }

    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        content = content
    )
}
