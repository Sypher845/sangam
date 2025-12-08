import 'package:flutter/material.dart';
import 'package:sangam/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Placeholder content
          Center(
            child: Text(
              'Home Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Floating navigation bar
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildNavigationSlider(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSlider() {
    final List<NavigationItem> items = [
      NavigationItem(icon: Icons.home_rounded, label: 'Home'),
      NavigationItem(icon: Icons.share_rounded, label: 'Social\nmedia'),
      NavigationItem(
        icon: Icons.camera_alt_rounded,
        label: 'Capture\nHazard',
        isCenter: true,
      ),
      NavigationItem(icon: Icons.cloud_outlined, label: 'Weather'),
      NavigationItem(icon: Icons.phone_in_talk_rounded, label: 'Emergency'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.asMap().entries.map((entry) {
          int index = entry.key;
          NavigationItem item = entry.value;
          bool isActive = _selectedIndex == index;
          return Expanded(child: _buildNavItem(item, index, isActive));
        }).toList(),
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, int index, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          _animationController.forward().then(
            (_) => _animationController.reverse(),
          );
          setState(() => _selectedIndex = index);
        }

        // Handle center button (camera capture)
        if (index == 2 && item.isCenter) {
          // TODO: Navigate to camera capture
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera capture coming soon')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isCenter)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: AppColors.white, size: 28),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: isActive ? AppColors.primary : Colors.grey.shade600,
                  size: 24,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isActive ? AppColors.primary : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final bool isCenter;

  NavigationItem({
    required this.icon,
    required this.label,
    this.isCenter = false,
  });
}
