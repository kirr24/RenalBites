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
  final userIdController = TextEditingController();
  final fullNameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  Uint8List? profileImage;

  String oldUserId = "";
  String photoUrl = "";

  bool isLoading = true;
  bool isSaving = false;

  String? selectedGender;
  String? selectedDisease;
  String? selectedStage;

  List<String> genderList = ['Male', 'Female'];
  List<String> diseaseList = ['Hemodialysis', 'Chronic Kidney Disease'];
  List<String> stageList = [
    'Stage 1',
    'Stage 2',
    'Stage 3',
    'Stage 4',
    'Stage 5',
  ];

  bool get needsStage {
    return selectedDisease != null && selectedDisease != 'Hemodialysis';
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    userIdController.dispose();
    fullNameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        userIdController.text = data['userId']?.toString() ?? '';
        fullNameController.text = data['fullName']?.toString() ?? '';
        ageController.text = data['age']?.toString() ?? '';
        heightController.text = data['height']?.toString() ?? '';
        weightController.text = data['weight']?.toString() ?? '';

        oldUserId = data['userId']?.toString() ?? '';
        photoUrl = data['photoUrl']?.toString() ?? '';

        selectedGender = data['gender']?.toString();
        selectedDisease = data['typeOfDisease']?.toString();

        String savedStage = data['stage']?.toString() ?? '';

        if (selectedDisease == 'Hemodialysis') {
          selectedStage = null;
        } else if (stageList.contains(savedStage)) {
          selectedStage = savedStage;
        }

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> selectImage() async {
    Uint8List? image = await pickImage(ImageSource.gallery);

    if (image != null) {
      setState(() {
        profileImage = image;
      });
    }
  }

  Future<String> uploadProfilePic(String uid) async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('profilePics')
        .child('$uid.jpg');

    UploadTask uploadTask = ref.putData(profileImage!);
    TaskSnapshot snapshot = await uploadTask;

    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<bool> checkUserID(String userId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(userId.toLowerCase())
        .get();

    return !doc.exists;
  }

  Future<void> updateProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No logged-in user found')));
      return;
    }

    String newUserId = userIdController.text.trim();
    String fullName = fullNameController.text.trim();
    String ageText = ageController.text.trim();
    String heightText = heightController.text.trim();
    String weightText = weightController.text.trim();

    if (newUserId.isEmpty ||
        fullName.isEmpty ||
        ageText.isEmpty ||
        heightText.isEmpty ||
        weightText.isEmpty ||
        selectedGender == null ||
        selectedDisease == null ||
        (needsStage && selectedStage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    int? age = int.tryParse(ageText);
    double? height = double.tryParse(heightText);
    double? weight = double.tryParse(weightText);

    if (age == null || height == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
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
      isSaving = true;
    });

    try {
      if (newUserId.toLowerCase() != oldUserId.toLowerCase()) {
        bool available = await checkUserID(newUserId);

        if (!available) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID already taken')),
          );

          setState(() {
            isSaving = false;
          });

          return;
        }

        if (oldUserId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('usernames')
              .doc(oldUserId.toLowerCase())
              .delete();
        }

        await FirebaseFirestore.instance
            .collection('usernames')
            .doc(newUserId.toLowerCase())
            .set({'uid': user.uid});
      }

      String finalPhotoUrl = photoUrl;

      if (profileImage != null) {
        finalPhotoUrl = await uploadProfilePic(user.uid);
      }

      String stage = selectedDisease == 'Hemodialysis' ? 'N/A' : selectedStage!;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'fullName': fullName,
            'userId': newUserId,
            'age': age,
            'gender': selectedGender,
            'height': height,
            'weight': weight,
            'typeOfDisease': selectedDisease,
            'stage': stage,
            'photoUrl': finalPhotoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Profile Updated'),
            content: const Text('Your profile has been updated successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  Widget textInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: const Color.fromARGB(255, 246, 246, 246),
      ),
    );
  }

  Widget cardBox({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 246, 246, 246),
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    ImageProvider profileProvider;

    if (profileImage != null) {
      profileProvider = MemoryImage(profileImage!);
    } else if (photoUrl.isNotEmpty) {
      profileProvider = NetworkImage(photoUrl);
    } else {
      profileProvider = const NetworkImage(
        'https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg?semt=ais_hybrid&w=740&q=80',
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 224, 247, 233),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: selectImage,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey,
                      backgroundImage: profileProvider,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text('Tap image to change profile picture'),

                  const SizedBox(height: 5),

                  Text(user?.email ?? 'No email'),

                  cardBox(
                    child: Column(
                      children: [
                        textInput(
                          controller: userIdController,
                          label: 'User ID',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 15),
                        textInput(
                          controller: fullNameController,
                          label: 'Full Name',
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 15),
                        textInput(
                          controller: ageController,
                          label: 'Age',
                          icon: Icons.cake,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 15),
                        textInput(
                          controller: heightController,
                          label: 'Height (cm)',
                          icon: Icons.height,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 15),
                        textInput(
                          controller: weightController,
                          label: 'Weight (kg)',
                          icon: Icons.monitor_weight,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),

                  cardBox(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: genderList.map((gender) {
                            return DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value;
                            });
                          },
                        ),

                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          value: selectedDisease,
                          decoration: const InputDecoration(
                            labelText: 'Type of Disease',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: diseaseList.map((disease) {
                            return DropdownMenuItem(
                              value: disease,
                              child: Text(disease),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDisease = value;

                              if (value == 'Hemodialysis') {
                                selectedStage = null;
                              }
                            });
                          },
                        ),

                        if (needsStage) ...[
                          const SizedBox(height: 15),
                          DropdownButtonFormField<String>(
                            value: selectedStage,
                            decoration: const InputDecoration(
                              labelText: 'Stage of Disease',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: stageList.map((stage) {
                              return DropdownMenuItem(
                                value: stage,
                                child: Text(stage),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStage = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Update Profile',
                                style: TextStyle(color: Colors.white),
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
