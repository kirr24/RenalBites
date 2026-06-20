import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:renalbites/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'homepage_screen.dart';

class CreateprofileScreen extends StatefulWidget {
  final VoidCallback showRegisterScreen;

  const CreateprofileScreen({super.key, required this.showRegisterScreen});

  @override
  State<CreateprofileScreen> createState() => _CreateprofileScreenState();
}

class _CreateprofileScreenState extends State<CreateprofileScreen> {
  final userIdController = TextEditingController();
  final fullNameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  Uint8List? profileImage;
  bool _isLoading = false;

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
  void dispose() {
    userIdController.dispose();
    fullNameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
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
    final doc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(userId.toLowerCase())
        .get();

    return !doc.exists;
  }

  Future<void> saveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No logged-in user found')));
      return;
    }

    String userId = userIdController.text.trim();
    String fullName = fullNameController.text.trim();
    String ageText = ageController.text.trim();
    String heightText = heightController.text.trim();
    String weightText = weightController.text.trim();

    if (userId.isEmpty ||
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
      bool available = await checkUserID(userId);

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

      if (profileImage != null) {
        photoUrl = await uploadProfilePic(user.uid);
      }

      String stage = selectedDisease == 'Hemodialysis' ? 'N/A' : selectedStage!;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'fullName': fullName,
        'userId': userId,
        'age': age,
        'gender': selectedGender,
        'height': height,
        'weight': weight,
        'typeOfDisease': selectedDisease,
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
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
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
        fillColor: Colors.white,
      ),
    );
  }

  Widget cardBox({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 224, 247, 233),
      appBar: AppBar(
        title: const Text('Create Profile'),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            GestureDetector(
              onTap: selectImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey,
                backgroundImage: profileImage != null
                    ? MemoryImage(profileImage!)
                    : const NetworkImage(
                            'https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg?semt=ais_hybrid&w=740&q=80',
                          )
                          as ImageProvider,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Tap image to select profile picture',
              style: TextStyle(
                fontSize: 12,
                color: Color.fromARGB(255, 17, 41, 12),
                fontWeight: FontWeight.bold,
              ),
            ),

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
                  onPressed: _isLoading ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 35, 63, 45),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
