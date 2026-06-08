import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:renalbites/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'homepage_screen.dart'; // Adjust the path to where HomePageScreen is defined

class CreateprofileScreen extends StatefulWidget {
  final VoidCallback showRegisterScreen;

  const CreateprofileScreen({super.key, required this.showRegisterScreen});

  @override
  State<CreateprofileScreen> createState() => _CreateprofileScreenState();
}

class _CreateprofileScreenState extends State<CreateprofileScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  Uint8List? _profileImage;
  bool _isLoading = false;

  String? _selectedGender;
  String? _selectedDisease;
  String? _selectedStage;

  bool get _needsStage => _selectedDisease != 'Hemodialysis';

  double _age = 25;
  double _height = 160;
  double _weight = 60;

  final List<String> _genderOptions = ['Male', 'Female'];

  final List<String> _diseaseOptions = [
    'Hemodialysis',
    'Chronic Kidney Disease',
  ];

  final List<String> _stageOptions = [
    'Stage 1',
    'Stage 2',
    'Stage 3',
    'Stage 4',
    'Stage 5',
  ];

  @override
  void dispose() {
    _userIdController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> selectImage() async {
    Uint8List? img = await pickImage(ImageSource.gallery);

    if (img != null) {
      setState(() {
        _profileImage = img;
      });
    }
  }

  Future<String> uploadImageToStorage(String uid) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profilePics')
        .child('$uid.jpg');

    UploadTask uploadTask = storageRef.putData(_profileImage!);
    TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  Future<bool> isUserIdAvailable(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(userId.toLowerCase())
        .get();

    return !doc.exists;
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No logged-in user found')));
      return;
    }

    final String userId = _userIdController.text.trim();
    final String fullName = _fullNameController.text.trim();
    final int age = _age.round();
    final String? gender = _selectedGender;
    final double height = _height;
    final double weight = _weight;
    final String? typeOfDisease = _selectedDisease;
    final String? stage = typeOfDisease == 'Hemodialysis'
        ? 'Not Applicable'
        : _selectedStage;

    if (userId.isEmpty ||
        fullName.isEmpty ||
        gender == null ||
        typeOfDisease == null ||
        (_needsStage && _selectedStage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (userId.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID must be at least 4 characters')),
      );
      return;
    }

    if (userId.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID cannot contain spaces')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bool available = await isUserIdAvailable(userId);

      if (!available) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User ID already taken')));

        setState(() {
          _isLoading = false;
        });
        return;
      }

      String photoUrl = '';

      if (_profileImage != null) {
        photoUrl = await uploadImageToStorage(user.uid);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'fullName': fullName,
        'userId': userId,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'typeOfDisease': typeOfDisease,
        'stage': stage,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('usernames')
          .doc(userId.toLowerCase())
          .set({'uid': user.uid});

      if (!mounted) return;

      showDialog(
        context: context,

        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            title: const Text(
              'Profile Saved',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            content: const Text('Your profile has been created successfully.'),

            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                ),

                onPressed: () {
                  Navigator.pop(context);

                  Navigator.pushReplacement(
                    context,

                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },

                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: Colors.green[900]),
      prefixIcon: Icon(icon, color: Colors.green[900]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.green.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
    );
  }

  Widget buildSectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildSliderField({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required Function(double) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green[800]),
            const SizedBox(width: 8),
            Text(
              '$title: ${value.round()} $unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: '${value.round()} $unit',
          onChanged: (newValue) {
            setState(() {
              onChanged(newValue);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 224, 247, 233),
      appBar: AppBar(
        title: const Text(
          'Create Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 13, 89, 86),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImage != null
                            ? MemoryImage(_profileImage!)
                            : const NetworkImage(
                                'https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg?semt=ais_hybrid&w=740&q=80',
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: selectImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_a_photo,
                              color: Colors.green[800],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.email ?? 'No Email',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Set up your personal health profile',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            buildSectionCard(
              child: Column(
                children: [
                  TextField(
                    controller: _userIdController,
                    decoration: customInputDecoration('User ID', Icons.person),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _fullNameController,
                    decoration: customInputDecoration('Full Name', Icons.badge),
                  ),
                ],
              ),
            ),

            buildSectionCard(
              child: Column(
                children: [
                  buildSliderField(
                    title: 'Age',
                    value: _age,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    unit: 'years',
                    icon: Icons.cake,
                    onChanged: (value) => _age = value,
                  ),
                  const SizedBox(height: 10),
                  buildSliderField(
                    title: 'Height',
                    value: _height,
                    min: 100,
                    max: 220,
                    divisions: 120,
                    unit: 'cm',
                    icon: Icons.height,
                    onChanged: (value) => _height = value,
                  ),
                  const SizedBox(height: 10),
                  buildSliderField(
                    title: 'Weight',
                    value: _weight,
                    min: 20,
                    max: 200,
                    divisions: 180,
                    unit: 'kg',
                    icon: Icons.monitor_weight,
                    onChanged: (value) => _weight = value,
                  ),
                ],
              ),
            ),

            buildSectionCard(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: customInputDecoration('Gender', Icons.wc),
                    items: _genderOptions.map((gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: _selectedDisease,
                    decoration: customInputDecoration(
                      'Type of Disease',
                      Icons.medical_services,
                    ),
                    items: _diseaseOptions.map((disease) {
                      return DropdownMenuItem<String>(
                        value: disease,
                        child: Text(disease),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDisease = value;

                        if (value == 'Hemodialysis') {
                          _selectedStage = null;
                        }
                      });
                    },
                  ),

                  if (_needsStage) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedStage,
                      decoration: customInputDecoration(
                        'Stage of Disease',
                        Icons.medical_services,
                      ),
                      items: _stageOptions.map((stage) {
                        return DropdownMenuItem<String>(
                          value: stage,
                          child: Text(stage),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStage = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
