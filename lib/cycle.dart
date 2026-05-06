import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'menu.dart';

class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int? _userId;
  DateTime _lastPeriodDate = DateTime.now().subtract(const Duration(days: 22));
  int _cycleLength = 28;
  int _periodLength = 5;
  List<Map<String, dynamic>> _pastPeriods = [];
  bool _isLoading = true;

  late TextEditingController _cycleController;
  late TextEditingController _periodController;

  @override
  void initState() {
    super.initState();
    _cycleController = TextEditingController(text: _cycleLength.toString());
    _periodController = TextEditingController(text: _periodLength.toString());
    _loadAllData();
  }

  @override
  void dispose() {
    _cycleController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');

    if (_userId != null) {
      final data = await _dbHelper.getCycleInfo(_userId!);
      if (data != null) {
        _lastPeriodDate = DateTime.parse(data['last_period_date']);
        _cycleLength = data['cycle_length'] ?? 28;
        _periodLength = data['period_length'] ?? 5;
        _cycleController.text = _cycleLength.toString();
        _periodController.text = _periodLength.toString();
      }
      _pastPeriods = await _dbHelper.getPeriods(_userId!);
    }
    setState(() => _isLoading = false);
  }

  int get _currentDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(_lastPeriodDate.year, _lastPeriodDate.month, _lastPeriodDate.day);
    final difference = today.difference(last).inDays;
    return (difference % _cycleLength) + 1;
  }

  int get _daysUntilNextPeriod {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(_lastPeriodDate.year, _lastPeriodDate.month, _lastPeriodDate.day);
    int diff = today.difference(last).inDays;
    int dayOfCycle = (diff % _cycleLength + _cycleLength) % _cycleLength;
    if (dayOfCycle < _periodLength) return 0;
    return _cycleLength - dayOfCycle;
  }

  DateTime get _nextPeriodDate => _lastPeriodDate.add(Duration(days: _cycleLength));
  DateTime get _nextFertileDate => _lastPeriodDate.add(Duration(days: _cycleLength - 14));

  double get _avgPeriod {
    if (_pastPeriods.isEmpty) return _periodLength.toDouble();
    double sum = 0;
    for (var p in _pastPeriods) {
      final start = DateTime.parse(p['start_date']);
      final end = DateTime.parse(p['end_date']);
      sum += end.difference(start).inDays + 1;
    }
    return sum / _pastPeriods.length;
  }

  double get _avgCycle {
    if (_pastPeriods.length < 2) return _cycleLength.toDouble();
    double sum = 0;
    for (int i = 0; i < _pastPeriods.length - 1; i++) {
      final current = DateTime.parse(_pastPeriods[i]['start_date']);
      final previous = DateTime.parse(_pastPeriods[i + 1]['start_date']);
      sum += current.difference(previous).inDays;
    }
    return sum / (_pastPeriods.length - 1);
  }

  bool _isOverlapping(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    for (var period in _pastPeriods) {
      final existingStart = DateTime.parse(period['start_date']);
      final existingEnd = DateTime.parse(period['end_date']);
      final es = DateTime(existingStart.year, existingStart.month, existingStart.day);
      final ee = DateTime(existingEnd.year, existingEnd.month, existingEnd.day);
      if (!s.isAfter(ee) && !e.isBefore(es)) return true;
    }
    return false;
  }

  void _showOverlapError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Period dates overlap with an existing entry!"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}";
  }

  String _formatRange(DateTime start, DateTime end) {
    return "${_formatDate(start)} - ${_formatDate(end)}";
  }

  Future<void> _saveSettings() async {
    if (_userId != null) {
      await _dbHelper.saveCycleInfo({
        'user_id': _userId,
        'last_period_date': _lastPeriodDate.toIso8601String(),
        'cycle_length': _cycleLength,
        'period_length': _periodLength,
      });
      setState(() {});
    }
  }

  Future<void> _addPeriod() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFE55F81)),
        ),
        child: child!,
      ),
    );

    if (picked != null && _userId != null) {
      final start = DateTime(picked.start.year, picked.start.month, picked.start.day);
      final end = DateTime(picked.end.year, picked.end.month, picked.end.day);

      if (_isOverlapping(start, end)) {
        _showOverlapError();
        return;
      }

      await _dbHelper.savePeriod({
        'user_id': _userId,
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      });
      if (start.isAfter(_lastPeriodDate) || start.isAtSameMomentAs(_lastPeriodDate)) {
        await _dbHelper.saveCycleInfo({
          'user_id': _userId,
          'last_period_date': start.toIso8601String(),
          'cycle_length': _cycleLength,
          'period_length': (end.difference(start).inDays + 1),
        });
      }
      _loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Container(
      color: const Color(0xFFFFF9FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text("PERIOD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            Text(
              _daysUntilNextPeriod == 0 ? "STARTS TODAY" : "$_daysUntilNextPeriod DAYS LEFT",
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.black),
            ),
            Text("${_formatDate(_nextPeriodDate)} - Next Period", style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSettingInput("CYCLE LENGTH", _cycleController, (val) {
                  int? newVal = int.tryParse(val);
                  if (newVal != null && newVal > 0) {
                    _cycleLength = newVal;
                    _saveSettings();
                  }
                }),
                _buildSettingInput("PERIOD LENGTH", _periodController, (val) {
                  int? newVal = int.tryParse(val);
                  if (newVal != null && newVal > 0) {
                    _periodLength = newVal;
                    _saveSettings();
                  }
                }),
              ],
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: Color(0xFFE55F81)),
                    ),
                    child: child!,
                  ),
                );

                if (picked != null && _userId != null) {
                  final start = DateTime(picked.year, picked.month, picked.day);
                  final end = start.add(Duration(days: _periodLength - 1));

                  if (_isOverlapping(start, end)) {
                    _showOverlapError();
                    return;
                  }

                  await _dbHelper.savePeriod({
                    'user_id': _userId,
                    'start_date': start.toIso8601String(),
                    'end_date': end.toIso8601String(),
                  });
                  if (start.isAfter(_lastPeriodDate) || start.isAtSameMomentAs(_lastPeriodDate)) {
                    await _dbHelper.saveCycleInfo({
                      'user_id': _userId,
                      'last_period_date': start.toIso8601String(),
                      'cycle_length': _cycleLength,
                      'period_length': _periodLength,
                    });
                  }
                  _loadAllData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE55F81),
                minimumSize: const Size(220, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                shadowColor: const Color(0xFFE55F81).withOpacity(0.4),
              ),
              child: const Text("Period Starts", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 35),
            Row(
              children: [
                Expanded(child: _buildCycleDayCard()),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    children: [
                      _buildSmallCard("NEXT PERIOD", _formatDate(_nextPeriodDate), const Color(0xFFFFF0F3), const Color(0xFFE55F81)),
                      const SizedBox(height: 15),
                      _buildSmallCard("NEXT FERTILE", _formatDate(_nextFertileDate), const Color(0xFFFFF5EC), const Color(0xFFF4A261)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildMyCyclesCard(),
            const SizedBox(height: 30),
            _buildHistorySection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleDayCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CYCLE\nDAY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Spacer(),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: _currentDay / _cycleLength,
                    strokeWidth: 9,
                    backgroundColor: Colors.grey[100],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB0003A)),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text("$_currentDay", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSmallCard(String title, String date, Color bgColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.8))),
          const SizedBox(height: 8),
          Text(date, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSettingInput(String label, TextEditingController controller, Function(String) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        Container(
          width: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMyCyclesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("My cycles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("${_pastPeriods.length} cycles logged", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildAverageCard(Icons.water_drop, "${_avgPeriod.toStringAsFixed(0)} Days", "AVERAGE PERIOD", const Color(0xFFFFF0F3), const Color(0xFFE55F81))),
              const SizedBox(width: 15),
              Expanded(child: _buildAverageCard(Icons.refresh, "${_avgCycle.toStringAsFixed(0)} Days", "AVERAGE CYCLE", const Color(0xFFFFF5EC), const Color(0xFFF4A261))),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addPeriod,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Period", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE55F81),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageCard(IconData icon, String value, String label, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: iconColor)),
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Text("Prediction", style: TextStyle(color: Colors.grey)),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),
        Align(alignment: Alignment.centerLeft, child: Text("${DateTime.now().year}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
        const SizedBox(height: 15),
        if (_pastPeriods.isEmpty) const Text("No history found.", style: TextStyle(color: Colors.grey)),
        ..._pastPeriods.map((p) => _buildHistoryItem(p)).toList(),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> period) {
    final start = DateTime.parse(period['start_date']);
    final end = DateTime.parse(period['end_date']);
    final periodDuration = end.difference(start).inDays + 1;
    
    int cycleDays = 28;
    int index = _pastPeriods.indexOf(period);
    if (index < _pastPeriods.length - 1) {
      final prevStart = DateTime.parse(_pastPeriods[index+1]['start_date']);
      cycleDays = start.difference(prevStart).inDays;
    }
    if (cycleDays <= 0) cycleDays = 28;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatRange(start, end), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(height: 16, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFFFF0F3), borderRadius: BorderRadius.circular(8))),
                    Container(
                      height: 16, 
                      width: (periodDuration / cycleDays) * 200, 
                      decoration: BoxDecoration(color: const Color(0xFFE55F81), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text("$periodDuration", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                    ),
                    Positioned(
                      left: (14 / cycleDays) * 200, 
                      child: Container(
                        height: 14,
                        width: 14,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Center(child: Container(height: 8, width: 8, decoration: const BoxDecoration(color: Color(0xFFF4A261), shape: BoxShape.circle))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Column(
            children: [
              Text("$cycleDays", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("DAYS", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
