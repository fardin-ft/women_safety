import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  DateTime _lastPeriodDate = DateTime.now().subtract(const Duration(days: 22));
  int _cycleLength = 28;
  int _periodLength = 5;
  
  @override
  void initState() {
    super.initState();
    _loadCycleData();
  }

  Future<void> _loadCycleData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? dateStr = prefs.getString('last_period_date');
      if (dateStr != null) {
        _lastPeriodDate = DateTime.parse(dateStr);
      }
      _cycleLength = prefs.getInt('cycle_length') ?? 28;
      _periodLength = prefs.getInt('period_length') ?? 5;
    });
  }

  Future<void> _savePeriodDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_period_date', date.toIso8601String());
    setState(() {
      _lastPeriodDate = date;
    });
  }

  int get _currentDay {
    final difference = DateTime.now().difference(_lastPeriodDate).inDays;
    return (difference % _cycleLength) + 1;
  }

  int get _daysUntilNextPeriod {
    int days = _cycleLength - _currentDay;
    return days < 0 ? 0 : days;
  }

  String get _currentPhase {
    int day = _currentDay;
    if (day <= _periodLength) return "Menstrual Phase";
    if (day <= 13) return "Follicular Phase";
    if (day <= 15) return "Ovulatory Phase";
    return "Luteal Phase";
  }

  Color get _phaseColor {
    int day = _currentDay;
    if (day <= _periodLength) return const Color(0xFFD81B60);
    if (day <= 15) return const Color(0xFF9C27B0);
    return const Color(0xFFCE93D8);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildCalendarCard(),
            const SizedBox(height: 20),
            _buildDailyLogs(),
            const SizedBox(height: 20),
            _buildCycleAnalysis(),
            const SizedBox(height: 20),
            _buildDailyInsight(),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CURRENT STATUS",
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
              children: [
                TextSpan(text: _daysUntilNextPeriod == 0 ? "Period " : "Period in "),
                TextSpan(
                  text: _daysUntilNextPeriod == 0 ? "Today" : "$_daysUntilNextPeriod\ndays", 
                  style: const TextStyle(color: Color(0xFFD81B60))
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              children: [
                const TextSpan(text: "Your cycle is regular. Phase: "),
                TextSpan(text: _currentPhase, style: TextStyle(color: _phaseColor, fontWeight: FontWeight.bold)),
                const TextSpan(text: ". Drink plenty of water and rest."),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showLogPeriodDialog(),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text("Log Period Start"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD81B60),
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: _currentDay / _cycleLength,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(_phaseColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    const Text("Day", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text(
                      "$_currentDay",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogPeriodDialog() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFD81B60)),
          ),
          child: child!,
        );
      },
    ).then((date) {
      if (date != null) _savePeriodDate(date);
    });
  }

  Widget _buildCalendarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Cycle Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.info_outline, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          _buildCalendarGrid(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(const Color(0xFFFFEBEE), "Period"),
              const SizedBox(width: 20),
              _buildLegend(const Color(0xFFF3E5F5), "Ovulation"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        DateTime date = DateTime.now().add(Duration(days: index - 3));
        int dayOfCycle = (date.difference(_lastPeriodDate).inDays % _cycleLength) + 1;
        bool isPeriod = dayOfCycle <= _periodLength;
        bool isToday = index == 3;

        return Column(
          children: [
            Text(
              ["M", "T", "W", "T", "F", "S", "S"][date.weekday - 1],
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isToday 
                    ? const Color(0xFFD81B60) 
                    : isPeriod ? const Color(0xFFFFEBEE) : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday ? null : Border.all(color: Colors.grey[200]!),
              ),
              alignment: Alignment.center,
              child: Text(
                "${date.day}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDailyLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12),
          child: Text("Daily Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildLogItem(Icons.sentiment_satisfied_alt, "MOOD", const Color(0xFFFCE4EC), const Color(0xFFD81B60)),
            _buildLogItem(Icons.medical_services, "SYMPTOMS", const Color(0xFFF5F5F5), const Color(0xFFC2185B)),
            _buildLogItem(Icons.water_drop, "FLOW", const Color(0xFFFCE4EC), const Color(0xFFD81B60)),
            _buildLogItem(Icons.favorite, "SEXUAL\nACTIVITY", const Color(0xFFF5F5F5), const Color(0xFFC2185B)),
          ],
        ),
      ],
    );
  }

  Widget _buildLogItem(IconData icon, String label, Color bgColor, Color iconColor) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logged $label for today"), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleAnalysis() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Cycle Analysis", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _currentDay > 14 
                ? "Your follicular window has passed. Logged activities optimized."
                : "Your fertile window starts in ${max(0, 14 - _currentDay)} days.",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CycleReportScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(50),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("View Detailed Report", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyInsight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.lightbulb, color: Color(0xFFD81B60), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Daily Insight", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
                Text(
                  _currentPhase == "Menstrual Phase" 
                    ? "Magnesium-rich foods can help ease the cramps you might feel today."
                    : "Staying active during the $_currentPhase boosts your energy levels.",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CycleReportScreen extends StatelessWidget {
  const CycleReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Cycle Analysis Report", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Summary",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Based on your last 3 months of data",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildStatRow("Average Cycle Length", "28 Days"),
            _buildStatRow("Average Period Length", "5 Days"),
            _buildStatRow("Cycle Regularity", "94%"),
            const SizedBox(height: 40),
            const Text(
              "Phase Breakdown",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPhaseBar("Menstrual", 0.18, const Color(0xFFD81B60)),
            _buildPhaseBar("Follicular", 0.32, const Color(0xFF9C27B0)),
            _buildPhaseBar("Ovulatory", 0.10, const Color(0xFFBA68C8)),
            _buildPhaseBar("Luteal", 0.40, const Color(0xFFCE93D8)),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Health Insights",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD81B60), fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "• Your cycle is extremely consistent.\n• Mood swings are most common during the Luteal phase.\n• Hydration levels have been 15% higher this month compared to last.",
                    style: TextStyle(color: Colors.black87, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPhaseBar(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text("${(percentage * 100).toInt()}%", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            color: color,
            backgroundColor: color.withOpacity(0.1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
