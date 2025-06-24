import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

// Student Pages
import '../student/student_home_page.dart';
import '../student/search_tutor_page.dart';
import '../student/student_booking_page.dart';
import '../student/session_history_page.dart';
import '../student/student_profile_page.dart';

// Tutor Pages
import '../tutor/tutor_dashboard_page.dart';
import '../tutor/schedule_page.dart';
import '../tutor/session_history_page.dart' as tutor_history;
import '../tutor/tutor_profile_page.dart';

// Setup Page
import '../auth/tutor_setup_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Method publik untuk navigasi programatik
  void navigateToTab(int index) {
    if (index >= 0 && index < _getMaxTabIndex()) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Method untuk mendapatkan index maksimum berdasarkan role
  int _getMaxTabIndex() {
    final authProvider = context.read<AuthProvider>();
    return authProvider.isStudent ? 5 : 4; 
  }

  // Method untuk navigasi ke halaman booking dengan tab tertentu
  void navigateToBookingTab(int tabIndex) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isStudent) {
      // Navigasi ke tab booking (index 2)
      navigateToTab(2);

      // Delay untuk memastikan halaman sudah ter-render
      Future.delayed(Duration(milliseconds: 100), () {
        final studentBookingContext = context;
        // Cari StudentBookingPage di widget tree dan arahkan ke tab yang diminta
        _navigateToBookingSubTab(studentBookingContext, tabIndex);
      });
    }
  }

  void _navigateToBookingSubTab(BuildContext context, int tabIndex) { }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          // Redirect to login if not logged in
          return Container();
        }

        // Check if tutor needs setup
        if (authProvider.needsTutorSetup) {
          return TutorSetupPage(
            onSetupComplete: () {
              authProvider.completeTutorSetup();
            },
          );
        }

        final isStudent = authProvider.isStudent;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: isStudent ? _studentPages : _tutorPages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: navigateToTab,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: isStudent
                ? AppColors.primary
                : AppColors.tutorColor,
            unselectedItemColor: AppColors.textHint,
            backgroundColor: AppColors.surface,
            elevation: 8,
            items: isStudent ? _studentNavItems : _tutorNavItems,
          ),
        );
      },
    );
  }

  List<Widget> get _studentPages => [
    const StudentHomePage(),
    const SearchTutorPage(),
    const StudentBookingPage(), 
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

  // Student Navigation Items - UPDATED: Added booking tab
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
      icon: Icon(Icons.bookmark_outlined), 
      activeIcon: Icon(Icons.bookmark),
      label: 'Booking', 
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

// Global Key untuk MainNavigation
final GlobalKey<MainNavigationState> mainNavigationKey =
    GlobalKey<MainNavigationState>();

// Extension untuk navigasi dari child widgets
extension NavigationHelper on BuildContext {
  // Navigasi ke tab tertentu
  void navigateToMainTab(int index) {
    final mainNavState = findAncestorStateOfType<MainNavigationState>();
    mainNavState?.navigateToTab(index);
  }

  // Navigasi ke halaman booking dengan tab tertentu
  void navigateToBookingWithTab(int tabIndex) {
    final mainNavState = findAncestorStateOfType<MainNavigationState>();
    mainNavState?.navigateToBookingTab(tabIndex);
  }

  // Navigasi ke halaman search tutor
  void navigateToSearchTutor() {
    navigateToMainTab(1); // Index 1 untuk SearchTutorPage
  }

  // Navigasi ke halaman session history
  void navigateToSessionHistory() {
    navigateToMainTab(3); // Index 3 untuk SessionHistoryPage
  }
}
