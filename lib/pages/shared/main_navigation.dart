// pages/shared/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

// Student Pages
import '../student/student_home_page.dart';
import '../student/search_tutor_page.dart';
import '../student/session_history_page.dart';
import '../student/student_profile_page.dart';

// Tutor Pages
import '../tutor/tutor_dashboard_page.dart';
import '../tutor/schedule_page.dart';
import '../tutor/session_history_page.dart' as tutor_history;
import '../tutor/tutor_profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          // Redirect to login if not logged in
          return Container();
        }

        final isStudent = authProvider.isStudent;
        
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: isStudent ? _studentPages : _tutorPages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textHint,
            backgroundColor: AppColors.surface,
            elevation: 8,
            items: isStudent ? _studentNavItems : _tutorNavItems,
          ),
        );
      },
    );
  }

  // Student Pages
  List<Widget> get _studentPages => [
    const StudentHomePage(),
    const SearchTutorPage(),
    const SessionHistoryPage(),
    const StudentProfilePage(),
  ];

  // Tutor Pages
  List<Widget> get _tutorPages => [
    const TutorDashboardPage(),
    const SchedulePage(),
    const tutor_history.SessionHistoryPage(),
    const TutorProfilePage(),
  ];

  // Student Navigation Items
  List<BottomNavigationBarItem> get _studentNavItems => [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Beranda',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search_outlined),
      activeIcon: Icon(Icons.search),
      label: 'Cari Tutor',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history),
      label: 'Riwayat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outlined),
      activeIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];

  // Tutor Navigation Items
  List<BottomNavigationBarItem> get _tutorNavItems => [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.schedule_outlined),
      activeIcon: Icon(Icons.schedule),
      label: 'Jadwal',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history),
      label: 'Riwayat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outlined),
      activeIcon: Icon(Icons.person),
      label: 'Profil',
    ),
  ];
}