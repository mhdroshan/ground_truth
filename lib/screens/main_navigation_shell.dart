import 'dart:ui';
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? 4 : 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0F0F172A),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: AppColors.primaryNavy.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.explore_outlined, Icons.explore_rounded, 'Read'),
                    _buildNavItem(2, Icons.edit_note_outlined, Icons.edit_note_rounded, 'Write'),
                    _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryNavy.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(
                    color: AppColors.primaryNavy.withValues(alpha: 0.12),
                    width: 1,
                  )
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? filledIcon : outlineIcon,
                  color: isSelected ? AppColors.primaryNavy : const Color(0xFF64748B),
                  size: 21,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryNavy : const Color(0xFF64748B),
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: isSelected ? 0.3 : 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
