import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème de l'application EcoWaste Cotonou
/// Palette de couleurs inspirée de l'écologie et de la nature
class AppTheme {
  // COULEURS PRINCIPALES 
  
  /// Couleur principale (Vert forêt profond)
  static const Color primary = Color(0xFF2D5F4F);
  
  /// Couleur principale foncée (Vert très sombre)
  static const Color primaryDark = Color(0xFF1E4538);
  
  /// Couleur d'accent (Vert émeraude)
  static const Color accent = Color(0xFF4A9B7F);
  
  /// Couleur de fond (Vert presque noir)
  static const Color background = Color(0xFF1A3329);
  
  /// Couleur de surface (Vert moyen foncé)
  static const Color surface = Color(0xFF234037);
  
  // COULEURS FONCTIONNELLES
  
  /// Succès / Actions positives
  static const Color success = Color(0xFF66BB6A);
  
  /// Avertissement / Alertes
  static const Color warning = Color(0xFFFFA726);
  
  /// Erreur / Danger
  static const Color error = Color(0xFFEF5350);
  
  /// Information
  static const Color info = Color(0xFF42A5F5);
  
  // ========== COULEURS DE TEXTE ==========
  
  /// Texte principal (Blanc)
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Texte secondaire (Gris-vert clair)
  static const Color textSecondary = Color(0xFFB8C5C0);
  
  /// Texte désactivé (Gris foncé)
  static const Color textDisabled = Color(0xFF5A6B64);
  
  // ========== COULEURS DES TYPES DE DÉCHETS ==========
  
  /// Ordures ménagères
  static const Color wasteGeneral = Color(0xFF2D5F4F);
  
  /// Recyclables (Bleu)
  static const Color wasteRecyclable = Color(0xFF42A5F5);
  
  /// Verre (Jaune-Orange)
  static const Color wasteGlass = Color(0xFFFFA726);
  
  /// Dangereux (Rouge)
  static const Color wasteDangerous = Color(0xFFEF5350);
  
  /// Organique (Vert clair)
  static const Color wasteOrganic = Color(0xFF66BB6A);
  
  /// Électronique (Violet)
  static const Color wasteElectronic = Color(0xFFAB47BC);
  
  // ========== EFFETS ET OVERLAYS ==========
  
  /// Fond de carte avec effet glassmorphism
  static const Color cardBackground = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  
  /// État hover/pressed
  static const Color hoverOverlay = Color(0x334A9B7F); // rgba(74,155,127,0.2)
  
  /// Ombre
  static const Color shadow = Color(0x4D000000); // rgba(0,0,0,0.3)
  
  // ========== DÉGRADÉS ==========
  
  /// Dégradé principal (fond splash, cards importantes)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  /// Dégradé d'accent
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, primary],
  );
  
  // ========== THÈME CLAIR (Mode par défaut) ==========
  
  static ThemeData get lightTheme {
    return ThemeData(
      // Couleurs de base
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      
      // Typographie avec Poppins
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          // Titres principaux
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          
          // Titres de sections
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          
          // Corps de texte
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          ),
          
          // Labels et captions
          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          labelMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: textSecondary,
          ),
        ),
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 24),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: textPrimary,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: textPrimary,
        elevation: 6,
        shape: CircleBorder(),
      ),
      
      // Inputs / TextFields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0x1AFFFFFF), // rgba(255,255,255,0.1)
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0x1AFFFFFF),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: accent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: error,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryDark,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accent,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF),
        thickness: 1,
        space: 1,
      ),
      
      // Progress Indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        circularTrackColor: Color(0x33FFFFFF),
      ),
      
      // Icons
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
    );
  }
  
  // ========== THÈME SOMBRE (Pour Phase 2) ==========
  
  static ThemeData get darkTheme {
    // Pour l'instant identique au lightTheme
    // Peut être personnalisé plus tard si besoin d'un mode encore plus sombre
    return lightTheme;
  }
  
  // ========== HELPERS ==========
  
  /// Convertit une couleur hex en Color
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
  
  /// Obtient une couleur avec opacité
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// Obtient la couleur d'un type de déchet
  static Color getWasteTypeColor(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'general':
        return wasteGeneral;
      case 'recyclable':
        return wasteRecyclable;
      case 'glass':
        return wasteGlass;
      case 'organic':
        return wasteOrganic;
      case 'dangerous':
        return wasteDangerous;
      case 'electronic':
        return wasteElectronic;
      default:
        return primary;
    }
  }
}