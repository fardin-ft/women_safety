import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'cycle.dart';
import 'hydration.dart';
import 'emergency.dart';
import 'user.dart';
import 'menu.dart';

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
        fontFamily: 'Roboto',
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return const DashboardScreen();
      case 1: return const CycleScreen();
      case 2: return const HydrationScreen();
      case 3: return const EmergencyScreen();
      default: return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'GuardianCare',
          style: TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundImage: const NetworkImage('https://i.pravatar.cc/150?u=sarah'),
                backgroundColor: Colors.grey[200],
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD81B60),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'CYCLE'),
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'HYDRATION'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'SOS'),
        ],
      ),
    );
  }
}

class ActivityReportScreen extends StatelessWidget {
  const ActivityReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Activity & Health Report", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Weekly Activity", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildActivityMetric("Steps", "58,432 total", 0.8, Colors.pink),
            _buildActivityMetric("Active Minutes", "320 mins", 0.6, Colors.purple),
            _buildActivityMetric("Sleep Quality", "82% average", 0.82, Colors.blue),
            _buildActivityMetric("Safety Checkins", "45 successful", 1.0, Colors.green),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Monthly Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 12),
                  Text(
                    "• Your activity levels are 12% higher than last week.\n• You tend to be most active between 5 PM and 7 PM.\n• Sleep consistency has improved by 5 days this month.",
                    style: TextStyle(color: Colors.black87, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityMetric(String label, String value, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _emergencyNumber;
  String _userName = "Sarah";
  final TextEditingController _controller = TextEditingController();

  // Cycle Logic Variables
  DateTime _lastPeriodDate = DateTime.now().subtract(const Duration(days: 22));
  int _cycleLength = 28;

  // Hydration Logic Variables
  double _currentIntake = 0.0;
  double _dailyGoal = 2.5;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _requestPermissions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.sms,
    ].request();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Sarah";
      _emergencyNumber = prefs.getString('emergency_contact');
      if (_emergencyNumber != null) {
        _controller.text = _emergencyNumber!;
      }
      String? dateStr = prefs.getString('last_period_date');
      if (dateStr != null) {
        _lastPeriodDate = DateTime.parse(dateStr);
      }
      _cycleLength = prefs.getInt('cycle_length') ?? 28;
      String? lastHydrationDate = prefs.getString('last_hydration_date');
      String today = DateTime.now().toIso8601String().split('T')[0];
      if (lastHydrationDate == today) {
        _currentIntake = prefs.getDouble('current_intake') ?? 0.0;
      } else {
        _currentIntake = 0.0;
      }
    });
  }

  int get _daysUntilNextPeriod {
    final difference = DateTime.now().difference(_lastPeriodDate).inDays;
    int currentDay = (difference % _cycleLength) + 1;
    int days = _cycleLength - currentDay;
    return days < 0 ? 0 : days;
  }

  String get _currentPhase {
    final difference = DateTime.now().difference(_lastPeriodDate).inDays;
    int day = (difference % _cycleLength) + 1;
    if (day <= 5) return "Menstrual Phase";
    if (day <= 13) return "Follicular Phase";
    if (day <= 15) return "Ovulatory Phase";
    return "Luteal Phase";
  }

  Future<void> _saveContact(String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contact', number);
    setState(() {
      _emergencyNumber = number;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact Saved!')),
      );
    }
  }

  Future<void> _sendSOS() async {
    if (_emergencyNumber == null || _emergencyNumber!.isEmpty) {
      _showContactDialog();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String message =
          "I am in danger! My location: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      final Uri smsLaunchUri = Uri(
        scheme: 'sms',
        path: _emergencyNumber,
        queryParameters: <String, String>{
          'body': message,
        },
      );

      if (await canLaunchUrl(smsLaunchUri)) {
        await launchUrl(smsLaunchUri);
      } else {
        throw 'Could not launch SMS';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency Contact"),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: "Enter phone number"),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _saveContact(_controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSafetyCard(),
          const SizedBox(height: 20),
          _buildCycleCard(),
          const SizedBox(height: 20),
          _buildHydrationCard(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActivityReportScreen()),
                  );
                },
                child: const Text("View All", style: TextStyle(color: Color(0xFFD81B60))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildSummaryItem(Icons.directions_walk, "8,432", "STEPS WALKED", Colors.pink[50]!, Colors.pink),
              _buildSummaryItem(Icons.fitness_center, "42", "ACTIVE MINS", Colors.purple[50]!, Colors.purple),
              _buildSummaryItem(Icons.nights_stay, "7h 20m", "REST QUALITY", Colors.blue[50]!, Colors.blue),
              _buildSummaryItem(Icons.shield, "12", "SAFETY CHECKINS", Colors.green[50]!, Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          _buildGuardianNetwork(),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: _showContactDialog,
              icon: const Icon(Icons.settings, size: 16),
              label: const Text("Set Emergency Contact", style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, size: 14, color: Color(0xFFD81B60)),
                SizedBox(width: 4),
                Text(
                  "SAFE & SECURE",
                  style: TextStyle(color: Color(0xFFD81B60), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Hello, $_userName.",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            "You're protected.",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD81B60)),
          ),
          const SizedBox(height: 8),
          const Text(
            "All safety systems are active and your\nemergency contacts are synced.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
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
                    color: const Color(0xFFD81B60).withOpacity(0.3),
                    spreadRadius: 10,
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 30),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CycleReportScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Cycle Phase", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(_currentPhase, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _daysUntilNextPeriod == 0 ? "Period Today" : "Period in $_daysUntilNextPeriod days",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildChip("Moderate Flow"),
                const SizedBox(width: 8),
                _buildChip("Low Cramps"),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CycleReportScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("View Detailed Report"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    );
  }

  Widget _buildHydrationCard() {
    double progress = (_currentIntake / _dailyGoal).clamp(0.0, 1.0);
    int percentage = (progress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.water_drop, color: Color(0xFFD81B60), size: 20),
              ),
              Text("$percentage%", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Hydration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("${_currentIntake.toStringAsFixed(1)}L of ${_dailyGoal}L goal", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            color: const Color(0xFFD81B60),
            backgroundColor: const Color(0xFFFCE4EC),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              _quickAddWater(0.25);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
              side: BorderSide(color: Colors.grey[200]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Add 250ml", style: TextStyle(color: Color(0xFFD81B60))),
          )
        ],
      ),
    );
  }

  Future<void> _quickAddWater(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Also update history to reflect in Recent Activity
    String? activitiesJson = prefs.getString('hydration_activities');
    List<Map<String, dynamic>> activities = [];
    if (activitiesJson != null && activitiesJson.isNotEmpty) {
      try {
        activities = List<Map<String, dynamic>>.from(json.decode(activitiesJson));
      } catch (e) {
        activities = [];
      }
    }
    
    final now = DateTime.now();
    final timeStr = "${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
    
    activities.insert(0, {
      "title": "Home Quick Add",
      "time": timeStr,
      "amount": "+${(amount * 1000).toInt()}ml",
      "value": amount,
      "icon": Icons.water_drop.codePoint,
    });

    setState(() {
      _currentIntake += amount;
      if (_currentIntake > _dailyGoal * 2) _currentIntake = _dailyGoal * 2;
    });

    await prefs.setDouble('current_intake', _currentIntake);
    await prefs.setString('hydration_activities', json.encode(activities));
    await prefs.setString('last_hydration_date', DateTime.now().toIso8601String().split('T')[0]);
  }

  Widget _buildSummaryItem(IconData icon, String value, String label, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianNetwork() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Guardian Network", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.settings, color: Colors.pink[200], size: 20),
            ],
          ),
          const Text(
            "Stay updated with your trusted circle's status.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildNetworkMember("Mom", "Checked in from Home • 20m ago"),
          const SizedBox(height: 12),
          _buildNetworkMember("David (Partner)", "At Office • 2h ago"),
        ],
      ),
    );
  }

  Widget _buildNetworkMember(String name, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(status, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          )
        ],
      ),
    );
  }
}
