import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  double currentIntake = 0.0;
  double dailyGoal = 2.5;
  
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadHydrationData();
  }

  Future<void> _loadHydrationData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if it's a new day
    String? lastDate = prefs.getString('last_hydration_date');
    String today = DateTime.now().toIso8601String().split('T')[0];

    setState(() {
      if (lastDate != today) {
        currentIntake = 0.0;
        _activities = [];
        prefs.setString('last_hydration_date', today);
        _saveData();
      } else {
        currentIntake = prefs.getDouble('current_intake') ?? 0.0;
        String? activitiesJson = prefs.getString('hydration_activities');
        if (activitiesJson != null) {
          _activities = List<Map<String, dynamic>>.from(json.decode(activitiesJson));
        }
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('current_intake', currentIntake);
    await prefs.setString('hydration_activities', json.encode(_activities));
  }

  void _addWater(double amount, String title, IconData icon) {
    setState(() {
      currentIntake += amount;
      final now = DateTime.now();
      final timeStr = "${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
      
      _activities.insert(0, {
        "title": title,
        "time": timeStr,
        "amount": "+${(amount * 1000).toInt()}ml",
        "value": amount,
        "icon": icon.codePoint,
      });
      
      if (currentIntake > dailyGoal * 2) currentIntake = dailyGoal * 2;
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    double progress = (currentIntake / dailyGoal).clamp(0.0, 1.0);
    int percentage = (progress * 100).toInt();
    double remaining = (dailyGoal - currentIntake).clamp(0.0, dailyGoal);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildProgressSection(progress, percentage),
          const SizedBox(height: 32),
          _buildStatusText(remaining),
          const SizedBox(height: 32),
          _buildQuickLogSection(),
          const SizedBox(height: 20),
          _buildCustomIntakeButton(),
          const SizedBox(height: 32),
          _buildRecentActivitySection(),
          const SizedBox(height: 32),
          _buildDailyTipCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double progress, int percentage) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 16,
              backgroundColor: Colors.grey[100],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD81B60)),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentIntake.toStringAsFixed(1),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              Text(
                "/ ${dailyGoal}L",
                style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$percentage% GOAL",
                  style: const TextStyle(color: Color(0xFFD81B60), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(double remaining) {
    return Column(
      children: [
        const Text(
          "Almost there!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          remaining > 0
              ? "You need ${(remaining * 1000).toInt()}ml more to reach your daily\nsanctuary goal."
              : "Daily goal reached! Great job staying hydrated.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildQuickLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "QUICK LOG",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildLogCard("Small Cup", "200 ml", Icons.local_drink, 0.2)),
            const SizedBox(width: 16),
            Expanded(child: _buildLogCard("Bottle", "500 ml", Icons.liquor, 0.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildLogCard(String title, String amount, IconData icon, double val) {
    return GestureDetector(
      onTap: () => _addWater(val, title, icon),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFD81B60), size: 20),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(amount, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomIntakeButton() {
    return InkWell(
      onTap: () => _addWater(0.25, "Custom Intake", Icons.add_circle),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD81B60),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Custom Intake", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Log any specific amount", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            Icon(Icons.add_circle, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HydrationHistoryScreen(),
                  ),
                );
                _loadHydrationData(); // Refresh data when coming back
              },
              child: const Text("See All", style: TextStyle(color: Color(0xFFD81B60))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._activities.take(3).map((activity) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildActivityItem(
            activity["title"], 
            activity["time"], 
            activity["amount"], 
            IconData(activity["icon"], fontFamily: 'MaterialIcons')
          ),
        )),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, String amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFD81B60), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DAILY TIP",
            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          SizedBox(height: 12),
          Text(
            "Stay calm, stay\nhydrated.",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Proper hydration reduces cortisol levels and helps you stay composed throughout the day.",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class HydrationHistoryScreen extends StatefulWidget {
  const HydrationHistoryScreen({super.key});

  @override
  State<HydrationHistoryScreen> createState() => _HydrationHistoryScreenState();
}

class _HydrationHistoryScreenState extends State<HydrationHistoryScreen> {
  List<Map<String, dynamic>> _activities = [];
  double _currentIntake = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIntake = prefs.getDouble('current_intake') ?? 0.0;
      String? activitiesJson = prefs.getString('hydration_activities');
      if (activitiesJson != null) {
        _activities = List<Map<String, dynamic>>.from(json.decode(activitiesJson));
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('current_intake', _currentIntake);
    await prefs.setString('hydration_activities', json.encode(_activities));
  }

  void _removeItem(int index) {
    setState(() {
      double amountToRemove = _activities[index]["value"] ?? 0.0;
      _currentIntake = (_currentIntake - amountToRemove).clamp(0.0, 10.0);
      _activities.removeAt(index);
    });
    _saveData();
  }

  void _addNewLog(double amount, String title, IconData icon) {
    setState(() {
      _currentIntake += amount;
      final now = DateTime.now();
      final timeStr = "${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
      
      _activities.insert(0, {
        "title": title,
        "time": timeStr,
        "amount": "+${(amount * 1000).toInt()}ml",
        "value": amount,
        "icon": icon.codePoint,
      });
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Hydration History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD81B60)),
            onPressed: () => _showAddDialog(),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.pink[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Today:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${_currentIntake.toStringAsFixed(1)} L", 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD81B60), fontSize: 18)),
              ],
            ),
          ),
          Expanded(
            child: _activities.isEmpty
                ? const Center(child: Text("No activity logged yet today."))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _activities.length,
                    itemBuilder: (context, index) {
                      final activity = _activities[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
                            ],
                            border: Border.all(color: Colors.grey[100]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.pink[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  IconData(activity["icon"], fontFamily: 'MaterialIcons'),
                                  color: const Color(0xFFD81B60),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(activity["title"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(activity["time"], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text(
                                activity["amount"],
                                style: const TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFD81B60),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quick Add", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAddOption("Cup", 0.2, Icons.local_drink),
                _buildAddOption("Glass", 0.3, Icons.water_drop),
                _buildAddOption("Bottle", 0.5, Icons.liquor),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption(String label, double val, IconData icon) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: () {
            _addNewLog(val, label, icon);
            Navigator.pop(context);
          },
          icon: Icon(icon, color: const Color(0xFFD81B60)),
          padding: const EdgeInsets.all(16),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text("${(val * 1000).toInt()}ml", style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
