import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'dart:convert';
import 'cycle.dart';
import 'hydration.dart';
import 'emergency.dart';
import 'user.dart';
import 'menu.dart';
import 'login.dart';
import 'database_helper.dart';

void main() {
  runApp(const GuardianCareApp());
}

class GuardianCareApp extends StatelessWidget {
  const GuardianCareApp({super.key});

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

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
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == true) {
            return const MainNavigation();
          }
          return const LoginScreen();
        },
      ),
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

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    await DatabaseHelper().database;
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return DashboardScreen(onOpenTracker: () => setState(() => _selectedIndex = 1));
      case 1: return const CycleScreen();
      case 2: return const HydrationScreen();
      case 3: return const EmergencyScreen();
      default: return DashboardScreen(onOpenTracker: () => setState(() => _selectedIndex = 1));
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
                ).then((result) {
                  if (result == "open_cycle") {
                    setState(() => _selectedIndex = 1);
                  } else {
                    setState(() {});
                  }
                });
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

class ActivityReportScreen extends StatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  State<ActivityReportScreen> createState() => _ActivityReportScreenState();
}

class _ActivityReportScreenState extends State<ActivityReportScreen> {
  int _steps = 0;
  int _mins = 0;
  int _kcal = 0;
  double _water = 0.0;
  int _goal = 5000;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _steps = prefs.getInt('steps_walked') ?? 0;
      _mins = prefs.getInt('walking_mins') ?? 0;
      _kcal = prefs.getInt('calories_burned') ?? 0;
      _water = prefs.getDouble('current_intake') ?? 0.0;
      _goal = prefs.getInt('step_goal') ?? 5000;
    });
  }

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
            const Text("Today's Progress", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildActivityMetric("Steps", "$_steps / $_goal", (_steps / _goal).clamp(0, 1), Colors.pink),
            _buildActivityMetric("Walking Time", "$_mins mins", (_mins / 60).clamp(0, 1), Colors.purple),
            _buildActivityMetric("Calories Burned", "$_kcal kcal", (_kcal / 500).clamp(0, 1), Colors.blue),
            _buildActivityMetric("Hydration", "${_water.toStringAsFixed(1)}L / 2.5L", (_water / 2.5).clamp(0, 1), Colors.cyan),
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
                    "• Your activity levels are tracked in real-time.\n• Stay hydrated to maintain energy levels.\n• Consistency in reaching your daily goal is improving.",
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
  final VoidCallback? onOpenTracker;
  const DashboardScreen({super.key, this.onOpenTracker});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = "User";
  List<String> _emergencyContacts = [];
  
  // Stats
  int _stepsWalked = 0;
  int _walkingMins = 0;
  int _caloriesBurned = 0;
  int _stepGoal = 5000;
  double _currentIntake = 0.0;
  double _dailyGoal = 2.5;

  // Cycle Status
  int _daysUntilPeriod = 0;
  String _currentPhase = "Luteal Phase";
  Stream<StepCount>? _stepCountStream;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initPedometer();
    _requestPermissions();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadData(); // Reload data when the widget is rebuilt (e.g., returning from Profile)
  }

  Future<void> _requestPermissions() async {
    await [Permission.location, Permission.sms, Permission.activityRecognition].request();
  }

  void _initPedometer() {
    try {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream?.listen((event) {
        if (mounted) {
          setState(() {
            _stepsWalked = event.steps;
            _walkingMins = (_stepsWalked / 100).round();
            _caloriesBurned = (_stepsWalked * 0.04).round();
          });
          _saveActivityData();
        }
      }).onError((e) => debugPrint("Pedometer Error: $e"));
    } catch (e) {
      debugPrint("Pedometer Init Error: $e");
    }
  }

  Future<void> _saveActivityData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps_walked', _stepsWalked);
    await prefs.setInt('walking_mins', _walkingMins);
    await prefs.setInt('calories_burned', _caloriesBurned);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    setState(() {
      _userName = prefs.getString('user_name') ?? "User";
      _stepsWalked = prefs.getInt('steps_walked') ?? 0;
      _walkingMins = prefs.getInt('walking_mins') ?? 0;
      _caloriesBurned = prefs.getInt('calories_burned') ?? 0;
      _stepGoal = prefs.getInt('step_goal') ?? 5000;
      _currentIntake = prefs.getDouble('current_intake') ?? 0.0;
    });

    if (userId != null) {
      final dbHelper = DatabaseHelper();
      
      // Load Personal Info
      final info = await dbHelper.getPersonalInfo(userId);
      if (info != null) {
        setState(() {
          _emergencyContacts = [
            info['emergency_number1'],
            info['emergency_number2'],
          ].where((n) => n != null && n.toString().isNotEmpty).map((n) => n.toString()).toList();
        });
      }

      // Load Cycle Info
      final cycleData = await dbHelper.getCycleInfo(userId);
      if (cycleData != null) {
        DateTime lastDate = DateTime.parse(cycleData['last_period_date']);
        int cycleLen = cycleData['cycle_length'] ?? 28;
        int periodLen = cycleData['period_length'] ?? 5;
        int diff = DateTime.now().difference(lastDate).inDays;
        int dayOfCycle = (diff % cycleLen) + 1;
        
        setState(() {
          _daysUntilPeriod = cycleLen - (diff % cycleLen);
          if (dayOfCycle <= periodLen) {
            _currentPhase = "Menstrual Phase";
            _daysUntilPeriod = 0;
          } else if (dayOfCycle <= 14) {
            _currentPhase = "Follicular Phase";
          } else if (dayOfCycle <= 17) {
            _currentPhase = "Ovulatory Phase";
          } else {
            _currentPhase = "Luteal Phase";
          }
        });
      }
    }
    
    // Fallback to legacy contact if DB is empty
    if (_emergencyContacts.isEmpty) {
      String? legacy = prefs.getString('emergency_contact');
      if (legacy != null) setState(() => _emergencyContacts.add(legacy));
    }
  }

  Future<void> _sendSOS() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No emergency contacts found. Please add them in Profile.")),
      );
      return;
    }

    try {
      Position? pos;
      try {
        // Added 10 second timeout to prevent "Requested times out" error
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        // Fallback to last known position if current one times out or fails
        pos = await Geolocator.getLastKnownPosition();
      }

      String locationLink = pos != null 
          ? "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}"
          : "[Location Unavailable]";

      String msg = "I am in danger! My location: $locationLink";

      for (String phone in _emergencyContacts) {
        final Uri uri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': msg});
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("SOS failed: ${e.toString()}")),
        );
      }
    }
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
              const Text("Today's Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityReportScreen())), icon: const Icon(Icons.bar_chart, color: Color(0xFFD81B60))),
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
              _buildSummaryItem(Icons.directions_walk, _stepsWalked.toString(), "STEPS WALKED", Colors.pink[50]!, Colors.pink),
              _buildSummaryItem(Icons.timer, "$_walkingMins", "MINS", Colors.purple[50]!, Colors.purple),
              _buildSummaryItem(Icons.local_fire_department, "$_caloriesBurned", "CALORIES", Colors.blue[50]!, Colors.blue),
              _buildSummaryItem(Icons.flag, "$_stepsWalked/$_stepGoal", "GOAL", Colors.green[50]!, Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          _buildGuardianNetwork(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shield, size: 14, color: Color(0xFFD81B60)),
              SizedBox(width: 4),
              Text("SAFE & SECURE", style: TextStyle(color: Color(0xFFD81B60), fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 16),
          Text("Hello, $_userName.", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("You're protected.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
          const SizedBox(height: 8),
          const Text("SOS system active. Tapping the button\nwill alert all emergency contacts.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _sendSOS,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: const Color(0xFFD81B60), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFD81B60).withOpacity(0.3), spreadRadius: 10, blurRadius: 20)]),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.location_on, color: Colors.white, size: 30),
                Text('SOS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(color: const Color(0xFFFFF0F3), borderRadius: BorderRadius.circular(12)), 
              child: const Icon(Icons.calendar_month, color: Color(0xFFE55F81), size: 20)
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                const Text("Cycle Phase", style: TextStyle(color: Colors.grey, fontSize: 12)), 
                Text(_currentPhase, style: const TextStyle(fontWeight: FontWeight.bold))
              ]
            )),
          ]),
          const SizedBox(height: 16),
          Text(
            _daysUntilPeriod == 0 ? "Period Starts Today" : "Period in $_daysUntilPeriod days", 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, 
            child: ElevatedButton(
              onPressed: widget.onOpenTracker ?? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CycleScreen())).then((_) => _loadData()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE55F81), 
                foregroundColor: Colors.white, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ), 
              child: const Text("Open Tracker", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ),
        ],
      ),
    );
  }

  Widget _buildHydrationCard() {
    double progress = (_currentIntake / _dailyGoal).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.pink[50], borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.water_drop, color: Color(0xFFD81B60), size: 20)),
            Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          const Text("Hydration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("${_currentIntake.toStringAsFixed(1)}L of ${_dailyGoal}L goal", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress, color: const Color(0xFFD81B60), backgroundColor: const Color(0xFFFCE4EC), minHeight: 8, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: iconColor, size: 18),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildGuardianNetwork() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFFFF5F8), borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Guardian Network", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text("Trusted circle is active.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 16),
        if (_emergencyContacts.isEmpty)
          const Text("No contacts saved. Add them in Profile.", style: TextStyle(color: Colors.grey, fontSize: 12))
        else
          ..._emergencyContacts.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildNetworkMember("Guardian ${entry.key + 1}", entry.value),
            );
          }).toList(),
      ]),
    );
  }

  Widget _buildNetworkMember(String name, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(status, style: const TextStyle(color: Colors.grey, fontSize: 11))])),
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
      ]),
    );
  }
}
