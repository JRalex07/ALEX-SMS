import 'package:flutter/material.dart';

class UserRoles {
  static const String schoolAdmin = 'school_admin';
  static const String teacher = 'teacher';
  static const String accountant = 'accountant';
  static const String admissionsOfficer = 'admissions_officer';
  static const String librarian = 'librarian';
  static const String parentGuardian = 'parent_guardian';

  static const List<String> allRoles = [
    schoolAdmin,
    teacher,
    accountant,
    admissionsOfficer,
    librarian,
    parentGuardian,
  ];

  static bool isValidRole(String role) => allRoles.contains(role);
  static bool isStaffRole(String role) =>
      isValidRole(role) && role != parentGuardian;

  static String getRoleDisplayName(String role) {
    switch (role) {
      case schoolAdmin:
        return 'School Administrator';
      case teacher:
        return 'Teacher';
      case accountant:
        return 'Accountant';
      case admissionsOfficer:
        return 'Admissions Officer';
      case librarian:
        return 'Librarian';
      case parentGuardian:
        return 'Parent / Guardian';
      default:
        return 'Unknown Role';
    }
  }
}

class AppColors {
  // Institutional Core
  static const Color brandNavy = Color(0xFF1E3A8A);
  static const Color brandNavyDark = Color(0xFF172554);
  static const Color surfaceBackground = Color(0xFFF8FAFC);
  static const Color cardSurface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Status & Feedback
  static const Color successGreen = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color infoSky = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);

  // Extended Ergonomic & Status Aliases
  static const Color tealSuccess = Color(0xFF0D9488);
  static const Color infoBlue = Color(0xFF0284C7);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color slateGray = Color(0xFF64748B);

  // Role Accents (6 Authorized Institutional Roles)
  static const Color adminIndigo = Color(0xFF4F46E5); // Royal indigo
  static const Color adminViolet = Color(0xFF7C3AED); // Electric violet
  static const Color teacherTeal = Color(0xFF0D9488); // Teal
  static const Color teacherGreen = Color(0xFF059669); // Ocean green
  static const Color teacherEmerald = Color(0xFF0D9488); // Teal / Emerald alias
  static const Color accountantEmerald = Color(0xFF059669); // Emerald
  static const Color accountantJade = Color(0xFF10B981); // Jade
  static const Color accountantAmber =
      Color(0xFF059669); // Emerald / Amber alias
  static const Color admissionsAmber = Color(0xFFD97706); // Warm amber
  static const Color admissionsOrange = Color(0xFFEA580C); // Orange
  static const Color admissionsTeal = Color(0xFFD97706); // Amber / Teal alias
  static const Color librarianViolet = Color(0xFF7C3AED); // Rich violet
  static const Color librarianPurple = Color(0xFF8B5CF6); // Purple
  static const Color parentBlue = Color(0xFF2563EB); // Bright blue
  static const Color parentCyan = Color(0xFF0284C7); // Sky cyan

  // Module Identity Accents
  static const Color studentModule = Color(0xFF2563EB);
  static const Color attendanceModule = Color(0xFF0D9488);
  static const Color academicsModule = Color(0xFF7C3AED);
  static const Color feesModule = Color(0xFF059669);
  static const Color staffModule = Color(0xFF0284C7);
  static const Color libraryModule = Color(0xFF8B5CF6);
  static const Color homeworkModule = Color(0xFF06B6D4);
  static const Color transportModule = Color(0xFFD97706);
  static const Color noticesModule = Color(0xFFF43F5E);
  static const Color reportsModule = Color(0xFF6366F1);
  static const Color idCardsModule = Color(0xFF4F46E5);
  static const Color syllabusModule = Color(0xFF10B981);
  static const Color chatModule = Color(0xFF3B82F6);
  static const Color complaintModule = Color(0xFFE11D48);
  static const Color routineModule = Color(0xFF8B5CF6);
  static const Color onlineClassModule = Color(0xFFEF4444);
  static const Color calendarModule = Color(0xFFF59E0B);
  static const Color onlineTestModule = Color(0xFF6366F1);
  static const Color locationModule = Color(0xFF0EA5E9);
  static const Color passwordModule = Color(0xFF64748B);

  static Color getRoleColor(String role) {
    switch (role) {
      case UserRoles.schoolAdmin:
        return adminIndigo;
      case UserRoles.teacher:
        return teacherTeal;
      case UserRoles.accountant:
        return accountantEmerald;
      case UserRoles.admissionsOfficer:
        return admissionsAmber;
      case UserRoles.librarian:
        return librarianViolet;
      case UserRoles.parentGuardian:
        return parentBlue;
      default:
        return brandNavy;
    }
  }
}

/// Comprehensive, accessible material palette for each authenticated role.
class RoleThemePalette {
  final String role;
  final String displayName;
  final Color primary;
  final Color secondary;
  final Color claySurface;
  final Color clayBorder;
  final Color navSelectedBg;
  final Color navSelectedFg;
  final LinearGradient accentGradient;

  const RoleThemePalette({
    required this.role,
    required this.displayName,
    required this.primary,
    required this.secondary,
    required this.claySurface,
    required this.clayBorder,
    required this.navSelectedBg,
    required this.navSelectedFg,
    required this.accentGradient,
  });

  static RoleThemePalette forRole(String role) {
    switch (role) {
      case UserRoles.schoolAdmin:
        return const RoleThemePalette(
          role: UserRoles.schoolAdmin,
          displayName: 'School Administrator',
          primary: AppColors.adminIndigo,
          secondary: AppColors.adminViolet,
          claySurface: Color(0xFFEEF2FF),
          clayBorder: Color(0xFFC7D2FE),
          navSelectedBg: Color(0xFFE0E7FF),
          navSelectedFg: AppColors.adminIndigo,
          accentGradient: LinearGradient(
            colors: [AppColors.adminIndigo, AppColors.adminViolet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case UserRoles.teacher:
        return const RoleThemePalette(
          role: UserRoles.teacher,
          displayName: 'Teacher',
          primary: AppColors.teacherTeal,
          secondary: AppColors.teacherGreen,
          claySurface: Color(0xFFF0FDFA),
          clayBorder: Color(0xFF99F6E4),
          navSelectedBg: Color(0xFFCCFBF1),
          navSelectedFg: AppColors.teacherTeal,
          accentGradient: LinearGradient(
            colors: [AppColors.teacherTeal, AppColors.teacherGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case UserRoles.accountant:
        return const RoleThemePalette(
          role: UserRoles.accountant,
          displayName: 'Accountant',
          primary: AppColors.accountantEmerald,
          secondary: AppColors.accountantJade,
          claySurface: Color(0xFFECFDF5),
          clayBorder: Color(0xFFA7F3D0),
          navSelectedBg: Color(0xFFD1FAE5),
          navSelectedFg: AppColors.accountantEmerald,
          accentGradient: LinearGradient(
            colors: [AppColors.accountantEmerald, AppColors.accountantJade],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case UserRoles.admissionsOfficer:
        return const RoleThemePalette(
          role: UserRoles.admissionsOfficer,
          displayName: 'Admissions Officer',
          primary: AppColors.admissionsAmber,
          secondary: AppColors.admissionsOrange,
          claySurface: Color(0xFFFFFBEB),
          clayBorder: Color(0xFFFDE68A),
          navSelectedBg: Color(0xFFFEF3C7),
          navSelectedFg: AppColors.admissionsAmber,
          accentGradient: LinearGradient(
            colors: [AppColors.admissionsAmber, AppColors.admissionsOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case UserRoles.librarian:
        return const RoleThemePalette(
          role: UserRoles.librarian,
          displayName: 'Librarian',
          primary: AppColors.librarianViolet,
          secondary: AppColors.librarianPurple,
          claySurface: Color(0xFFFAF5FF),
          clayBorder: Color(0xFFDDD6FE),
          navSelectedBg: Color(0xFFEDE9FE),
          navSelectedFg: AppColors.librarianViolet,
          accentGradient: LinearGradient(
            colors: [AppColors.librarianViolet, AppColors.librarianPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case UserRoles.parentGuardian:
      default:
        return const RoleThemePalette(
          role: UserRoles.parentGuardian,
          displayName: 'Parent / Guardian',
          primary: AppColors.parentBlue,
          secondary: AppColors.parentCyan,
          claySurface: Color(0xFFEFF6FF),
          clayBorder: Color(0xFFBFDBFE),
          navSelectedBg: Color(0xFFDBEAFE),
          navSelectedFg: AppColors.parentBlue,
          accentGradient: LinearGradient(
            colors: [AppColors.parentBlue, AppColors.parentCyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }
}
