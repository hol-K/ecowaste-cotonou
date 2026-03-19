import 'package:flutter/material.dart';

/// Centralise toutes les couleurs utilisées dans l'application
class AppColors {
  // ========== COULEURS PRINCIPALES ==========
  
  static const Color primary = Color(0xFF2D5F4F);
  static const Color primaryDark = Color(0xFF1E4538);
  static const Color accent = Color(0xFF4A9B7F);
  static const Color background = Color(0xFF1A3329);
  static const Color surface = Color(0xFF234037);
  
  // ========== COULEURS FONCTIONNELLES ==========
  
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);
  
  // ========== TEXTE ==========
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8C5C0);
  static const Color textDisabled = Color(0xFF5A6B64);
  
  // ========== TYPES DE DÉCHETS ==========
  
  static const Color wasteGeneral = Color(0xFF2D5F4F);
  static const Color wasteRecyclable = Color(0xFF42A5F5);
  static const Color wasteGlass = Color(0xFFFFA726);
  static const Color wasteDangerous = Color(0xFFEF5350);
  static const Color wasteOrganic = Color(0xFF66BB6A);
  static const Color wasteElectronic = Color(0xFFAB47BC);
  
  // ========== OVERLAYS ==========
  
  static const Color cardBackground = Color(0x14FFFFFF);
  static const Color hoverOverlay = Color(0x334A9B7F);
  static const Color shadow = Color(0x4D000000);
  
  // Empêche l'instanciation
  AppColors._();
}