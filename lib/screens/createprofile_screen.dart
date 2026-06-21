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

  final Color darkGreen = const Color.fromARGB(255, 35, 63, 45);
  final Color softGreen = const Color.fromARGB(255, 224, 247, 233);

  List<String> genderList = ['Lelaki', 'Perempuan'];
  List<String> diseaseList = ['Hemodialisis', 'Penyakit Buah Pinggang Kronik'];
  List<String> stageList = [
    'Tahap 1',
    'Tahap 2',
    'Tahap 3',
    'Tahap 4',
    'Tahap 5',
  ];

  bool get needsStage {
    return selectedDisease != null && selectedDisease != 'Hemodialisis';
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

  Future<void> selectImage(ImageSource source) async {
    Uint8List? image = await pickImage(source);

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

    return await snapshot.ref.getDownloadURL();
  }

  Future<bool> checkUserID(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(userId.toLowerCase())
        .get();

    return !doc.exists;
  }

  String calculateCaloriesLimit(double weight) {
    return (weight * 35).toStringAsFixed(0);
  }

  String calculateProteinLimit({
    required double weight,
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();
    final stageText = stage.toLowerCase();

    if (disease.contains('hemodialisis')) {
      return (weight * 1.2).toStringAsFixed(0);
    }

    if (stageText.contains('tahap 1') || stageText.contains('tahap 2')) {
      return (weight * 0.8).toStringAsFixed(0);
    }

    if (stageText.contains('tahap 3') ||
        stageText.contains('tahap 4') ||
        stageText.contains('tahap 5')) {
      return (weight * 0.8).toStringAsFixed(0);
    }

    return 'N/A';
  }

  String calculatePotassiumLimit({
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();

    if (disease.contains('hemodialisis')) {
      return '3000';
    }

    return 'Tiada sekatan kecuali tahap kalium darah tinggi';
  }

  String calculatePhosphateLimit({
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();
    final stageText = stage.toLowerCase();

    if (disease.contains('hemodialisis')) {
      return '1000';
    }

    if (stageText.contains('tahap 1') || stageText.contains('tahap 2')) {
      return 'Tiada sekatan';
    }

    if (stageText.contains('tahap 3') ||
        stageText.contains('tahap 4') ||
        stageText.contains('tahap 5')) {
      return '1000';
    }

    return 'N/A';
  }

  Future<void> saveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiada pengguna yang sedang log masuk')),
      );
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
        const SnackBar(
          content: Text('Sila lengkapkan semua maklumat yang diperlukan'),
        ),
      );
      return;
    }

    int? age = int.tryParse(ageText);
    double? height = double.tryParse(heightText);
    double? weight = double.tryParse(weightText);

    if (age == null || height == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila masukkan nombor yang sah')),
      );
      return;
    }

    if (userId.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID pengguna mestilah sekurang-kurangnya 4 aksara'),
        ),
      );
      return;
    }

    if (userId.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID pengguna tidak boleh mengandungi ruang'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool available = await checkUserID(userId);

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID pengguna ini telah digunakan')),
        );

        setState(() {
          _isLoading = false;
        });

        return;
      }

      String photoUrl = '';

      if (profileImage != null) {
        photoUrl = await uploadProfilePic(user.uid);
      }

      String stage = selectedDisease == 'Hemodialisis'
          ? 'Tidak berkaitan'
          : selectedStage!;

      String caloriesLimit = calculateCaloriesLimit(weight);

      String proteinLimit = calculateProteinLimit(
        weight: weight,
        typeOfDisease: selectedDisease!,
        stage: stage,
      );

      String potassiumLimit = calculatePotassiumLimit(
        typeOfDisease: selectedDisease!,
        stage: stage,
      );

      String phosphateLimit = calculatePhosphateLimit(
        typeOfDisease: selectedDisease!,
        stage: stage,
      );

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

        'caloriesLimit': caloriesLimit,
        'proteinLimit': proteinLimit,
        'potassiumLimit': potassiumLimit,
        'phosphateLimit': phosphateLimit,
        'limitsSaved': true,

        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('usernames')
          .doc(userId.toLowerCase())
          .set({'uid': user.uid});

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Profil Berjaya Disimpan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Profil anda telah berjaya dicipta. Anda boleh mula menggunakan RenalBites sekarang.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: const Text(
                  'Teruskan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Berlaku ralat: $e')));
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
        prefixIcon: Icon(icon, color: darkGreen),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkGreen, width: 2),
        ),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: darkGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget dropdownInput({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkGreen, width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: softGreen,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: darkGreen,
        title: const Text(
          'Cipta Profil',
          style: TextStyle(
            color: Color.fromARGB(255, 251, 251, 251),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 192, 222, 187),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(
                                    Icons.camera_alt,
                                    color: darkGreen,
                                  ),
                                  title: const Text('Ambil gambar'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    selectImage(ImageSource.camera);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.photo_library,
                                    color: darkGreen,
                                  ),
                                  title: const Text('Pilih dari galeri'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    selectImage(ImageSource.gallery);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 58,
                          backgroundColor: softGreen,
                          backgroundImage: profileImage != null
                              ? MemoryImage(profileImage!)
                              : const NetworkImage(
                                      'https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg?semt=ais_hybrid&w=740&q=80',
                                    )
                                    as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: darkGreen,
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Foto Profil',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 26, 58, 39),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Tekan gambar untuk ambil foto atau pilih dari galeri',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color.fromARGB(255, 26, 58, 39),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'Tiada e-mel',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 26, 58, 39),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            sectionCard(
              title: 'Maklumat Peribadi',
              icon: Icons.person,
              child: Column(
                children: [
                  textInput(
                    controller: userIdController,
                    label: 'ID Pengguna',
                    icon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 14),
                  textInput(
                    controller: fullNameController,
                    label: 'Nama Penuh',
                    icon: Icons.badge,
                  ),
                  const SizedBox(height: 14),
                  textInput(
                    controller: ageController,
                    label: 'Umur',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            sectionCard(
              title: 'Maklumat Fizikal',
              icon: Icons.monitor_weight,
              child: Column(
                children: [
                  textInput(
                    controller: heightController,
                    label: 'Tinggi (cm)',
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  textInput(
                    controller: weightController,
                    label: 'Berat (kg)',
                    icon: Icons.monitor_weight,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            sectionCard(
              title: 'Maklumat Kesihatan',
              icon: Icons.health_and_safety,
              child: Column(
                children: [
                  dropdownInput(
                    label: 'Jantina',
                    value: selectedGender,
                    items: genderList,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  dropdownInput(
                    label: 'Jenis Penyakit',
                    value: selectedDisease,
                    items: diseaseList,
                    onChanged: (value) {
                      setState(() {
                        selectedDisease = value;

                        if (value == 'Hemodialisis') {
                          selectedStage = null;
                        }
                      });
                    },
                  ),
                  if (needsStage) ...[
                    const SizedBox(height: 14),
                    dropdownInput(
                      label: 'Tahap Penyakit Buah Pinggang',
                      value: selectedStage,
                      items: stageList,
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
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 25),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan Profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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
