import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'emergency_screen.dart';
import 'camera_capture_page.dart';
import '../services/permission_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onNavigationTap(int index) {
    debugPrint('_onNavigationTap called: index=$index, current=$_selectedIndex');
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
        debugPrint('State updated: _selectedIndex=$_selectedIndex');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MainNavigationScreen build: _selectedIndex=$_selectedIndex');
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreenContent(onNavigationTap: _onNavigationTap, currentIndex: _selectedIndex),
          const Center(child: Text('Social Media - Coming Soon', style: TextStyle(fontSize: 24))),
          const Center(child: Text('Camera Capture', style: TextStyle(fontSize: 24))),
          const Center(child: Text('Weather - Coming Soon', style: TextStyle(fontSize: 24))),
          const EmergencyScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildNavigationBar() {
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
        color: Colors.white.withOpacity(0.95),
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
        debugPrint('Navigation tapped: index=$index, isCenter=${item.isCenter}, currentSelected=$_selectedIndex');
        // Handle camera capture separately (center button)
        if (index == 2 && item.isCenter) {
          _handleCameraCapture();
        } else {
          _onNavigationTap(index);
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3498DB).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 28),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF3498DB).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: isActive
                      ? const Color(0xFF3498DB)
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isActive
                    ? const Color(0xFF3498DB)
                    : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCameraCapture() async {
    // Import required services
    final permissionService = PermissionService();

    // Check if permissions are granted
    final hasPermissions = await permissionService.hasAllRequiredPermissions();

    if (!hasPermissions) {
      if (!mounted) return;
      final granted = await permissionService.requestAllPermissions(context);
      if (!granted) {
        return; // User denied permissions
      }
    }

    // Navigate to camera capture page
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraCapturePage()),
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

// Wrapper for HomeScreen content without its own navigation
class HomeScreenContent extends StatelessWidget {
  final Function(int) onNavigationTap;
  final int currentIndex;

  const HomeScreenContent({
    super.key,
    required this.onNavigationTap,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
