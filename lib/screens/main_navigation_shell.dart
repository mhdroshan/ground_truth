import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_feed_screen.dart';
import 'read_screen.dart';
import 'write_screen.dart';
import 'profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeFeedScreen(),     // Tab 0: Home
    ReadScreen(),         // Tab 1: Read
    WriteScreen(),        // Tab 2: Write
    ProfileScreen(),      // Tab 3: Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Read'),
            _buildNavItem(2, Icons.edit_note_outlined, Icons.edit_note_rounded, 'Write'),
            _buildNavItem(3, Icons.person_outline, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD0E1FD) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? filledIcon : outlineIcon,
                color: isSelected ? AppColors.primaryNavy : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryNavy : const Color(0xFF64748B),
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
