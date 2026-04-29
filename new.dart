import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const GuardianCareApp());
}

class GuardianCareApp extends StatelessWidget {
  const GuardianCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuardianCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD81B60),
          primary: const Color(0xFFD81B60),
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.sms,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {}),
        title: const Text(
          'GuardianCare',
          style: TextStyle(
              color: Color(0xFFD81B60), fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSafetyCard(context),
            const SizedBox(height: 20),
            _buildCycleCard(),
            const SizedBox(height: 20),
            _buildHydrationCard(),
            const SizedBox(height: 24),
            const Text("Today's Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryItem(
                    Icons.directions_walk, "8,432", "STEPS WALKED",
                    Colors.pink),
                _buildSummaryItem(
                    Icons.fitness_center, "42", "ACTIVE MINS", Colors.purple),
                _buildSummaryItem(
                    Icons.nights_stay, "7h 20m", "REST QUALITY", Colors.blue),
                _buildSummaryItem(
                    Icons.shield, "12", "SAFETY CHECKINS", Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Text("Hello, Sarah. You're protected.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _sendSOS,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFD81B60),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFD81B60).withValues(alpha: 0.3),
                      spreadRadius: 10,
                      blurRadius: 20)
                ],
              ),
              child: const Center(child: Text("SOS", style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20))),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _sendSOS() async {
    final prefs = await SharedPreferences.getInstance();
    String? contact = prefs.getString('emergency_contact');
    if (contact == null) return;

    Position pos = await Geolocator.getCurrentPosition();
    String msg = "I'm in danger! My location: https://www.google.com/maps/search/?api=1&query=${pos
        .latitude},${pos.longitude}";
    launchUrl(
        Uri(scheme: 'sms', path: contact, queryParameters: {'body': msg}));
  }

  Widget _buildCycleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: const ListTile(
        leading: Icon(Icons.calendar_today, color: Colors.purple),
        title: Text(
            "Period in 4 days", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Follicular Phase"),
      ),
    );
  }

  Widget _buildHydrationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              "Hydration - 75%", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: 0.75,
              color: Colors.pink,
              backgroundColor: Colors.pink[50]),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String val, String label,
      Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const Spacer(),
          Text(val, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}