import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user.dart';
import 'login.dart';

class AppDrawer extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = "User";
  String _userEmail = "user@example.com";
  String _userMascot = "https://i.pravatar.cc/150?u=sarah";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didUpdateWidget(covariant AppDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "User";
      _userEmail = prefs.getString('user_email') ?? "user@example.com";
      _userMascot = prefs.getString('user_mascot') ?? "https://i.pravatar.cc/150?u=sarah";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFD81B60)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(_userMascot),
                ),
                const SizedBox(height: 10),
                Text(
                  _userName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _userEmail,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: widget.selectedIndex == 0 ? const Color(0xFFD81B60) : Colors.grey),
            title: Text(
              'Dashboard',
              style: TextStyle(color: widget.selectedIndex == 0 ? const Color(0xFFD81B60) : Colors.black),
            ),
            selected: widget.selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              widget.onTabSelected(0);
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_month, color: widget.selectedIndex == 1 ? const Color(0xFFD81B60) : Colors.grey),
            title: Text(
              'Cycle Tracker',
              style: TextStyle(color: widget.selectedIndex == 1 ? const Color(0xFFD81B60) : Colors.black),
            ),
            selected: widget.selectedIndex == 1,
            onTap: () {
              Navigator.pop(context);
              widget.onTabSelected(1);
            },
          ),
          ListTile(
            leading: Icon(Icons.water_drop, color: widget.selectedIndex == 2 ? const Color(0xFFD81B60) : Colors.grey),
            title: Text(
              'Hydration',
              style: TextStyle(color: widget.selectedIndex == 2 ? const Color(0xFFD81B60) : Colors.black),
            ),
            selected: widget.selectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              widget.onTabSelected(2);
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on, color: widget.selectedIndex == 3 ? const Color(0xFFD81B60) : Colors.grey),
            title: Text(
              'SOS Emergency',
              style: TextStyle(color: widget.selectedIndex == 3 ? const Color(0xFFD81B60) : Colors.black),
            ),
            selected: widget.selectedIndex == 3,
            onTap: () {
              Navigator.pop(context);
              widget.onTabSelected(3);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              ).then((result) {
                _loadUserData();
                if (result == "open_cycle") {
                  widget.onTabSelected(1);
                }
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', false);
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
