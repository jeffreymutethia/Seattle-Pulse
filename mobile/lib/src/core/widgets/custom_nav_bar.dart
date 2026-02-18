import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/screens/add_story_screen.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/service/user_secure_storage.dart';
import 'package:seattle_pulse_mobile/src/features/feed/screens/feed_screen.dart';
import 'package:seattle_pulse_mobile/src/features/mypulse/screens/mypulse_screen.dart';
import 'package:seattle_pulse_mobile/src/features/profile/screens/profile_screen.dart';
import 'package:seattle_pulse_mobile/src/features/notification/screens/notification_screen.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({Key? key}) : super(key: key);

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  String? _username;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await SecureStorageService.getUser();
    setState(() {
      _username = user?.username;
      print("Username: $_username");
      _isLoading = false;
    });
  }

  List<Widget> _buildScreens() {
    return [
      const FeedScreen(),
      const MyPulseScreen(),
      const AddStoryScreen(),
      ProfileScreen(username: _username ?? "loading..."),
      const NotificationScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: _navIcon("assets/icons/feed.png", "Feed"),
        activeColorPrimary: Colors.black,
        inactiveColorPrimary: const Color(0xFF5D6778),
      ),
      PersistentBottomNavBarItem(
        icon: _navIcon("assets/icons/pulse.png", "My Pulse"),
        activeColorPrimary: Colors.black,
        inactiveColorPrimary: const Color(0xFF5D6778),
      ),
      PersistentBottomNavBarItem(
        icon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
          ),
          child: const Icon(Icons.add, size: 28, color: Colors.black),
        ),
        title: "Add",
        activeColorPrimary: Colors.transparent,
        inactiveColorPrimary: Colors.transparent,
      ),
      PersistentBottomNavBarItem(
        icon: _navIcon("assets/icons/person.png", "Profile"),
        activeColorPrimary: Colors.black,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: _navIcon("assets/icons/notification.png", "Notifications"),
        activeColorPrimary: Colors.black,
        inactiveColorPrimary: const Color(0xFF5D6778),
      ),
    ];
  }

  Widget _navIcon(String assetPath, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Image.asset(assetPath, width: 24, height: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF5D6778))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      navBarStyle: NavBarStyle.style15,
      navBarHeight: 70,
      stateManagement: true,
      resizeToAvoidBottomInset: true,
    );
  }
}
