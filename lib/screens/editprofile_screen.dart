import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:renalbites/utils.dart';

class EditprofileScreen extends StatefulWidget {
  const EditprofileScreen({super.key});

  @override
  State<EditprofileScreen> createState() => _EditprofileScreenState();
}

class _EditprofileScreenState extends State<EditprofileScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  Uint8List? _profileImage;
  String _oldUserId = "";
  String _photoUrl = "";

  bool _isLoading = true;
  bool _isSaving = false;

  String? _selectedGender;
  String? _selectedDisease;
  String? _selectedStage;

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
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      setState(() {
        _userIdController.text = data['userId']?.toString() ?? "";
        _fullNameController.text = data['fullName']?.toString() ?? "";

        _oldUserId = data['userId']?.toString() ?? "";
        _photoUrl = data['photoUrl']?.toString() ?? "";

        _age = double.tryParse(data['age'].toString()) ?? 25;
        _height = double.tryParse(data['height'].toString()) ?? 160;
        _weight = double.tryParse(data['weight'].toString()) ?? 60;

        _selectedGender = data['gender']?.toString();
        _selectedDisease = data['typeOfDisease']?.toString();
        _selectedStage = data['stage']?.toString();

        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
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

  Future<void> updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No logged-in user found')));
      return;
    }

    final String newUserId = _userIdController.text.trim();
    final String fullName = _fullNameController.text.trim();

    if (newUserId.isEmpty ||
        fullName.isEmpty ||
        _selectedGender == null ||
        _selectedDisease == null ||
        _selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (newUserId.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID must be at least 4 characters')),
      );
      return;
    }

    if (newUserId.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID cannot contain spaces')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (newUserId.toLowerCase() != _oldUserId.toLowerCase()) {
        final available = await isUserIdAvailable(newUserId);

        if (!available) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID already taken')),
          );

          setState(() {
            _isSaving = false;
          });
          return;
        }

        if (_oldUserId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('usernames')
              .doc(_oldUserId.toLowerCase())
              .delete();
        }

        await FirebaseFirestore.instance
            .collection('usernames')
            .doc(newUserId.toLowerCase())
            .set({'uid': user.uid});
      }

      String finalPhotoUrl = _photoUrl;

      if (_profileImage != null) {
        finalPhotoUrl = await uploadImageToStorage(user.uid);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'fullName': fullName,
            'userId': newUserId,
            'age': _age.round(),
            'gender': _selectedGender,
            'height': _height,
            'weight': _weight,
            'typeOfDisease': _selectedDisease,
            'stage': _selectedStage,
            'photoUrl': finalPhotoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Profile Updated"),
            content: const Text(
              "Your information has been updated successfully.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
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

    ImageProvider profileProvider;

    if (_profileImage != null) {
      profileProvider = MemoryImage(_profileImage!);
    } else if (_photoUrl.isNotEmpty) {
      profileProvider = NetworkImage(_photoUrl);
    } else {
      profileProvider = const NetworkImage(
        'https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg?semt=ais_hybrid&w=740&q=80',
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 224, 247, 233),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Color.fromARGB(255, 251, 251, 251),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
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
                              backgroundImage: profileProvider,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Update your personal health profile',
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
                          decoration: customInputDecoration(
                            'User ID',
                            Icons.person,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _fullNameController,
                          decoration: customInputDecoration(
                            'Full Name',
                            Icons.badge,
                          ),
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
                            });
                          },
                        ),
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
                    ),
                  ),

                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Update Profile',
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
