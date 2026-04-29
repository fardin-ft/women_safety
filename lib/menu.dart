import 'package:flutter/material.dart';
import 'user.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFD81B60)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=sarah'),
                ),
                SizedBox(height: 10),
                Text(
                  "Sarah",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "sarah@guardian.care",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: selectedIndex == 0 ? const Color(0xFFD81B60) : Colors.grey),
            title: Text(
              'Dashboard',
              style: TextStyle(color: selectedIndex == 0 ? const Color(0xFFD81B60) : Colors.black),
            ),
            selected: selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              onTabSelected(0);
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_month, color: selectedIndex == 1 ? const Color(0xFFD81B60) : Colors.grey),
            title: Text(
              'Cycle Tracker',
              style: TextStyle(color: selectedIndex == 1 ? const Color(0xFFD81B60) : Colors.black),
            ),
            selected: selectedIndex == 1,
            onTap: () {
              Navigator.pop(context);
              onTabSelected(1);
            },
          ),
          ListTile(
            leading: Icon(Icons.water_drop, color: selectedIndex == 2 ? const Color(0xFFD81B60) : Colors.grey),
            title: Text(
              'Hydration',
              style: TextStyle(color: selectedIndex == 2 ? const Color(0xFFD81B60) : Colors.black),
            ),
            selected: selectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              onTabSelected(2);
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on, color: selectedIndex == 3 ? const Color(0xFFD81B60) : Colors.grey),
            title: Text(
              'SOS Emergency',
              style: TextStyle(color: selectedIndex == 3 ? const Color(0xFFD81B60) : Colors.black),
            ),
            selected: selectedIndex == 3,
            onTap: () {
              Navigator.pop(context);
              onTabSelected(3);
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
              );
            },
          ),
        ],
      ),
    );
  }
}
