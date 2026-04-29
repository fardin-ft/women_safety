import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Timer? _holdTimer;
  double _progress = 0.0;
  bool _isHolding = false;
  String? _emergencyNumber;
  String _currentAddress = "Fetching your location...";

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyNumber = prefs.getString('emergency_contact');
    });
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _currentAddress = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Location access denied";
      });
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    setState(() {
      _isHolding = true;
      _progress = 0.0;
    });
    _holdTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _progress += 0.01;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _holdTimer?.cancel();
          _triggerEmergency();
        }
      });
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    setState(() {
      _isHolding = false;
      _progress = 0.0;
    });
  }

  Future<void> _triggerEmergency() async {
    if (_emergencyNumber == null || _emergencyNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No emergency contact set!")),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      String message = "EMERGENCY! I need help. My location: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      final Uri smsLaunchUri = Uri(
        scheme: 'sms',
        path: _emergencyNumber,
        queryParameters: <String, String>{'body': message},
      );

      if (await canLaunchUrl(smsLaunchUri)) {
        await launchUrl(smsLaunchUri);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _makeCall(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text("Emergency Help", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Hold the button for 3 seconds to alert your circle",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 48),
          _buildSOSButton(),
          const SizedBox(height: 64),
          _buildLiveLocationCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildQuickAction("Emergency\nServices", "DIAL 911", Icons.phone, const Color(0xFFC62828), () => _makeCall("911"))),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickAction("Local Police", "DIRECT LINK", Icons.shield, const Color(0xFF121212), () => _makeCall("100"))),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _stopHold(),
      child: Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFD81B60),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: const Color(0xFFD81B60).withValues(alpha: 0.3), spreadRadius: 10, blurRadius: 20),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isHolding)
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                ),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sensors, color: Colors.white, size: 32),
                  SizedBox(height: 4),
                  Text("SOS", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  Text("PRESS & HOLD", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveLocationCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: 0, top: 0, bottom: 0, width: 100,
            child: Container(
              color: const Color(0xFFE1F5FE),
              child: Center(child: Icon(Icons.location_on, color: const Color(0xFFD81B60).withValues(alpha: 0.3), size: 60)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFD81B60), size: 18),
                    const SizedBox(width: 8),
                    const Text("LIVE LOCATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                      child: const Text("TRANSMITTING", style: TextStyle(color: Color(0xFFD81B60), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_currentAddress, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("Accurate to 5m", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 24),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
