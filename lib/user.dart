import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'database_helper.dart';
import 'cycle.dart';
import 'menu.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = true;
  int? _currentUserId;

  String _name = "User";
  String _email = "No email";
  String _phone = "";
  String _mascot = "https://i.pravatar.cc/150?u=sarah"; // Default mascot
  String _bloodType = "";
  String _weight = "";
  String _height = "";
  String _emergency1 = "";
  String _emergency2 = "";

  final List<String> _mascotOptions = [
    "https://i.pravatar.cc/150?u=sarah",
    "https://i.pravatar.cc/150?u=2",
    "https://i.pravatar.cc/150?u=3",
    "https://i.pravatar.cc/150?u=4",
  ];

  // Cycle summary data
  int _daysLeft = 0;
  int _cycleDay = 1;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');

      if (_currentUserId != null) {
        final userData = await _dbHelper.getUser(_currentUserId!);
        if (userData != null) {
          _name = userData['name'] ?? "User";
          _email = userData['email'] ?? "No email";
          _phone = userData['phone'] ?? "";
          if (userData['mascot'] != null && userData['mascot'].isNotEmpty) {
            _mascot = userData['mascot'];
          }
          // Update SharedPreferences for the drawer
          await prefs.setString('user_name', _name);
          await prefs.setString('user_email', _email);
          await prefs.setString('user_mascot', _mascot);
        }

        final personalInfo = await _dbHelper.getPersonalInfo(_currentUserId!);
        if (personalInfo != null) {
          _bloodType = personalInfo['blood_group'] ?? "";
          _weight = personalInfo['weight']?.toString() ?? "";
          _height = personalInfo['height']?.toString() ?? "";
          _emergency1 = personalInfo['emergency_number1'] ?? "";
          _emergency2 = personalInfo['emergency_number2'] ?? "";
        }

        // Fetch Cycle Info for Summary
        final cycleData = await _dbHelper.getCycleInfo(_currentUserId!);
        if (cycleData != null) {
          DateTime lastDate = DateTime.parse(cycleData['last_period_date']);
          int cycleLen = cycleData['cycle_length'] ?? 28;
          int diff = DateTime.now().difference(lastDate).inDays;
          _cycleDay = (diff % cycleLen) + 1;
          _daysLeft = cycleLen - (diff % cycleLen);
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePersonalInfo() async {
    if (_currentUserId == null) return;
    try {
      Map<String, dynamic> info = {
        'user_id': _currentUserId,
        'blood_group': _bloodType,
        'weight': double.tryParse(_weight) ?? 0.0,
        'height': double.tryParse(_height) ?? 0.0,
        'emergency_number1': _emergency1,
        'emergency_number2': _emergency2,
      };
      await _dbHelper.savePersonalInfo(info);
      _loadAllData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Info updated")));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUserId == null) return;
    try {
      await _dbHelper.updateProfile(_currentUserId!, _name, _email, _phone);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _name);
      await prefs.setString('user_email', _email);
      _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated")));
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFE55F81)),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (r) => false);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildProfileHeader(),
            const SizedBox(height: 30),
            _buildCycleSummaryCard(),
            const SizedBox(height: 20),
            _buildInfoSection("Health Profile", Icons.favorite, [
              _buildSimpleDetail("Blood Type", _bloodType.isEmpty ? "Not set" : _bloodType),
              _buildSimpleDetail("Weight", _weight.isEmpty ? "Not set" : "$_weight kg"),
              _buildSimpleDetail("Height", _height.isEmpty ? "Not set" : "$_height cm"),
            ], onEdit: _showEditHealthDialog),
            const SizedBox(height: 20),
            _buildInfoSection("Emergency Contacts", Icons.emergency, [
              _buildSimpleDetail("Primary", _emergency1.isEmpty ? "None" : _emergency1),
              _buildSimpleDetail("Secondary", _emergency2.isEmpty ? "None" : _emergency2),
            ], onEdit: _showEmergencyDialog),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showMascotPicker,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFE55F81), shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage(_mascot),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFD81B60), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 40),
            Text(_name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Color(0xFFD81B60)),
              onPressed: _showEditProfileDialog,
            )
          ],
        ),
        Text(_email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        if (_phone.isNotEmpty) Text(_phone, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (value) => value == null || value.isEmpty ? "Name is required" : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Email is required";
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return "Enter a valid email";
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Phone Number"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Phone number is required";
                    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) return "Enter a valid phone number";
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _name = nameController.text;
                  _email = emailController.text;
                  _phone = phoneController.text;
                });
                await _saveProfile();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showMascotPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose Your Mascot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _mascotOptions.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      if (_currentUserId != null) {
                        await _dbHelper.updateMascot(_currentUserId!, _mascotOptions[index]);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('user_mascot', _mascotOptions[index]);
                        setState(() {
                          _mascot = _mascotOptions[index];
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _mascot == _mascotOptions[index] ? const Color(0xFFD81B60) : Colors.transparent,
                          width: 3,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(_mascotOptions[index]),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCycleSummaryCard() {
    return GestureDetector(
      onTap: () {
        // Pop back to main navigation and switch to cycle tab
        Navigator.pop(context, "open_cycle");
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE55F81),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFFE55F81).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CURRENT CYCLE", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("$_daysLeft Days Left", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("Tap to view full cycle tracker", style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Text("$_cycleDay", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> details, {required VoidCallback onEdit}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(icon, color: const Color(0xFFE55F81), size: 18), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, size: 16, color: Colors.grey)),
            ],
          ),
          const Divider(height: 20),
          ...details,
        ],
      ),
    );
  }

  Widget _buildSimpleDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  void _showEditHealthDialog() {
    String? selectedBloodType = _bloodType.isEmpty ? null : _bloodType;
    const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    if (selectedBloodType != null && !bloodGroups.contains(selectedBloodType)) {
      selectedBloodType = null;
    }

    final weightController = TextEditingController(text: _weight);
    final heightController = TextEditingController(text: _height);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Health Profile"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedBloodType,
                  decoration: const InputDecoration(labelText: "Blood Type"),
                  items: bloodGroups.map((String type) {
                    return DropdownMenuItem<String>(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) => setDialogState(() => selectedBloodType = value),
                  validator: (value) => value == null ? "Required" : null,
                ),
                TextFormField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Weight (kg)"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required";
                    final n = double.tryParse(value);
                    if (n == null || n <= 0 || n > 300) return "Invalid weight";
                    return null;
                  },
                ),
                TextFormField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Height (cm)"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required";
                    final n = double.tryParse(value);
                    if (n == null || n <= 0 || n > 250) return "Invalid height";
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _bloodType = selectedBloodType ?? "";
                    _weight = weightController.text;
                    _height = heightController.text;
                  });
                  _savePersonalInfo();
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDialog() {
    final e1Controller = TextEditingController(text: _emergency1);
    final e2Controller = TextEditingController(text: _emergency2);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency Contacts"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: e1Controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Primary Contact"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Primary contact required";
                  if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) return "Invalid number";
                  return null;
                },
              ),
              TextFormField(
                controller: e2Controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Secondary Contact (Optional)"),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) return "Invalid number";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _emergency1 = e1Controller.text;
                  _emergency2 = e2Controller.text;
                });
                _savePersonalInfo();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
