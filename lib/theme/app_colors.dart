import 'package:flutter/material.dart';

class AppColors {
  // --- 2026 Core Surfaces & Translucent Liquid Glass ---
  static const Color background = Color(0xFFF6F8FB);
  static const Color backgroundAtmosphere = Color(0xFFEDF2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color surfaceMuted = Color(0xFFE2E8F0);
  static const Color surfaceGlass = Color(0xCCFFFFFF); // 80% frosted glass
  static const Color surfaceUltraGlass = Color(0x99FFFFFF); // 60% frosted

  // Liquid Glass Tokens (2026 Trend)
  static const Color liquidGlassFill = Color(0xDDFFFFFF); // 87% translucent
  static const Color liquidGlassBorder = Color(0x80FFFFFF); // Specular highlight border
  static const Color liquidGlassBorderSubtle = Color(0x1F0F172A); // Micro dark border rim
  static const Color liquidGlassGlow = Color(0x140038A8); // Soft ambient glow
  static const Color liquidGlassSpecular = Color(0xE6FFFFFF); // 90% top light sheen
  static const Color liquidGlassTint = Color(0x0A0038A8);

  // Bento Modular Grid Tokens (2026 Trend)
  static const Color bentoSurface = Color(0xFFFFFFFF);
  static const Color bentoSurfaceSecondary = Color(0xFFF8FAFC);
  static const Color bentoSurfaceDark = Color(0xFF0F172A);
  static const Color bentoBorder = Color(0xFFE2E8F0);
  static const Color bentoBorderActive = Color(0xFFCBD5E1);
  static const Color bentoDivider = Color(0xFFEDF2F7);

  // Borders & Specular Lines
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEEF2F6);
  static const Color borderHighContrast = Color(0xFFCBD5E1);

  // Figma Primary Brand Deep Royal Navy & Electric Accents
  static const Color primaryNavy = Color(0xFF0038A8);
  static const Color primaryNavyDark = Color(0xFF002266);
  static const Color primaryBlue = Color(0xFF0047AB);
  static const Color primaryBlueLight = Color(0xFFD0E1FD); // Active nav pill
  static const Color primaryBlueHover = Color(0xFF002D80);
  static const Color electricBlue = Color(0xFF2563EB); // 2026 vivid electric blue
  static const Color radarCyan = Color(0xFF0284C7);
  static const Color accentBlue = Color(0xFF0038A8);

  // GroundTruth Verification Signature Greens (Liquid Emerald)
  static const Color verifiedGreen = Color(0xFF00875A);
  static const Color verifiedGreenDark = Color(0xFF006C35); // FAB Dark green
  static const Color verifiedGreenBg = Color(0xFFE6F4EA); // On-site pill bg
  static const Color verifiedGreenText = Color(0xFF0D652D); // On-site pill text
  static const Color verifiedGreenBorder = Color(0xFFB7E1CD);
  static const Color liquidEmerald = Color(0xFF10B981);
  static const Color liquidEmeraldGlow = Color(0x3310B981);

  // Alert & Severity Colors
  static const Color alertRed = Color(0xFFD92D20); // Ongoing / Disasters
  static const Color alertRedBg = Color(0xFFFEE4E2);
  static const Color alertAmber = Color(0xFFD97706);
  static const Color alertAmberBg = Color(0xFFFEF3C7);
  static const Color solarAmber = Color(0xFFF59E0B);
  static const Color hyperCrimson = Color(0xFFEF4444);

  // Voting
  static const Color upvote = Color(0xFF0D652D);
  static const Color downvote = Color(0xFFD92D20);

  // Typography Colors (Exaggerated Minimalism)
  static const Color textPrimary = Color(0xFF090D16); // High-contrast deep obsidian
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Remote badge & neutral tags
  static const Color tagBg = Color(0xFFF1F5F9);
  static const Color tagText = Color(0xFF475569);

  // Category Accent Colors
  static const Color catProtestBlue = Color(0xFF1E40AF);
  static const Color catDisasterRed = Color(0xFF991B1B);
  static const Color catElectionGreen = Color(0xFF15803D);
  static const Color catSafetyNavy = Color(0xFF1E293B);
  static const Color catEnvironment = Color(0xFF166534);

  // 2026 Liquid Glass Gradients
  static const LinearGradient liquidGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xF2FFFFFF), // 95% opacity
      Color(0xD9FFFFFF), // 85% opacity
      Color(0xC4F8FAFC), // 77% opacity
    ],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient liquidHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF091427),
      Color(0xFF11284E),
      Color(0xFF1B3D73),
    ],
  );

  static const LinearGradient electricPillGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0038A8),
      Color(0xFF1D4ED8),
    ],
  );

  static const LinearGradient emeraldPillGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00875A),
      Color(0xFF059669),
    ],
  );
}
