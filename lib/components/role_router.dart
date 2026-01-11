import 'package:flutter/material.dart';
import 'package:laundry_lens/pages/admin_dashboard.dart';
import 'package:laundry_lens/pages/dormitory_dashboard.dart';
import 'package:laundry_lens/pages/university_dashboard.dart';

void navigateByRole(
    BuildContext context,
    String role,
    ) {
  switch (role) {
    case 'super_admin':
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        ),
      );
      break;

    case 'university_admin':
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const UniversityDashboard(),
        ),
      );
      break;

    case 'dorm_admin':
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DormitoryDashboard(),
        ),
      );
      break;

    default:
      throw Exception('Rôle inconnu : $role');
  }
}
