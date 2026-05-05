import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _biometricEnabled = true;
  
  // Profile Data
  String _name = "Sarah";
  String _email = "sarah.j@example.com";
  String _phone = "+1 (555) 012-3456";
  
  // Health Data
  String _bloodType = "O+";
  String _allergies = "Peanuts";
  String _meds = "None";
  String _weight = "64 kg";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? "Sarah";
      _email = prefs.getString('user_email') ?? "sarah.j@example.com";
      _phone = prefs.getString('user_phone') ?? "+1 (555) 012-3456";
      _bloodType = prefs.getString('user_blood_type') ?? "O+";
      _allergies = prefs.getString('user_allergies') ?? "Peanuts";
      _meds = prefs.getString('user_meds') ?? "None";
      _weight = prefs.getString('user_weight') ?? "64 kg";
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? true;
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_email', _email);
    await prefs.setString('user_phone', _phone);
    await prefs.setString('user_blood_type', _bloodType);
    await prefs.setString('user_allergies', _allergies);
    await prefs.setString('user_meds', _meds);
    await prefs.setString('user_weight', _weight);
    await prefs.setBool('biometric_enabled', _biometricEnabled);
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email Address")),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60), foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _name = nameController.text;
                _email = emailController.text;
                _phone = phoneController.text;
              });
              _saveUserData();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showEditHealthDialog() {
    final bloodController = TextEditingController(text: _bloodType);
    final allergiesController = TextEditingController(text: _allergies);
    final medsController = TextEditingController(text: _meds);
    final weightController = TextEditingController(text: _weight);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Health Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: bloodController, decoration: const InputDecoration(labelText: "Blood Type")),
              TextField(controller: allergiesController, decoration: const InputDecoration(labelText: "Allergies")),
              TextField(controller: medsController, decoration: const InputDecoration(labelText: "Medications")),
              TextField(controller: weightController, decoration: const InputDecoration(labelText: "Weight")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60), foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _bloodType = bloodController.text;
                _allergies = allergiesController.text;
                _meds = medsController.text;
                _weight = weightController.text;
              });
              _saveUserData();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'GuardianCare',
          style: TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFFD81B60)),
            onPressed: () {
              setState(() {
                _name = "New User";
                _email = "";
                _phone = "";
              });
              _showEditProfileDialog();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildPersonalDetails(),
            const SizedBox(height: 16),
            _buildEmergencyContactInfo(),
            const SizedBox(height: 16),
            _buildHealthProfile(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
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
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.red.withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=sarah'),
              ),
            ),
            GestureDetector(
              onTap: _showEditProfileDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFD81B60),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Text(
          "Premium Member since 2026",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPersonalDetails() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: Color(0xFFD81B60), size: 20),
                  SizedBox(width: 12),
                  Text(
                    "Personal Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(onPressed: _showEditProfileDialog, icon: const Icon(Icons.edit, size: 18, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailField("EMAIL ADDRESS", _email),
          const SizedBox(height: 12),
          _buildDetailField("PHONE NUMBER", _phone),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactInfo() {
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
          const Row(
            children: [
              Icon(Icons.emergency, color: Color(0xFF9C27B0), size: 20),
              SizedBox(width: 12),
              Text(
                "Emergency Contact Info",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContactCard("Marcus Johnson", "Partner • +1 (555) 098-7654", const Color(0xFFFFF1F8), const Color(0xFF9C27B0)),
          const SizedBox(height: 12),
          _buildContactCard("Elena Smith", "Mother • +1 (555) 234-5678", const Color(0xFFF8F9FA), Colors.grey),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: Colors.grey[200]!, style: BorderStyle.solid),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("+ Add New Contact", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String name, String details, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(details, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Icon(Icons.phone, color: iconColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildHealthProfile() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite, color: Color(0xFFD81B60), size: 20),
                  SizedBox(width: 12),
                  Text(
                    "Health Profile",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showEditHealthDialog,
                child: const Text("Edit Details", style: TextStyle(color: Color(0xFFD81B60), fontSize: 12, fontWeight: FontWeight.bold)),
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
              _buildHealthItem(Icons.water_drop, "BLOOD TYPE", _bloodType, const Color(0xFFFCE4EC)),
              _buildHealthItem(Icons.warning, "ALLERGIES", _allergies, const Color(0xFFF8F9FA)),
              _buildHealthItem(Icons.medication, "MEDS", _meds, const Color(0xFFF8F9FA)),
              _buildHealthItem(Icons.height, "WEIGHT", _weight, const Color(0xFFF8F9FA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(IconData icon, String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFD81B60), size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String? subtitle, Color iconBgColor, {Widget? trailing, Color? textColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFD81B60), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor ?? Colors.black,
                ),
              ),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}
