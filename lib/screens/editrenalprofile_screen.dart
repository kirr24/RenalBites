import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renalbites/widgets/bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditRenalProfileScreen extends StatefulWidget {
  const EditRenalProfileScreen({super.key});

  @override
  State<EditRenalProfileScreen> createState() => _EditRenalProfileScreenState();
}

class _EditRenalProfileScreenState extends State<EditRenalProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  bool initialized = false;

  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final potassiumController = TextEditingController();
  final phosphateController = TextEditingController();

  @override
  void dispose() {
    caloriesController.dispose();
    proteinController.dispose();
    potassiumController.dispose();
    phosphateController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    return doc.exists ? doc.data() : null;
  }

  String calculateCaloriesLimit(double weight) {
    final calories = weight * 35;
    return calories.toStringAsFixed(0);
  }

  String calculateProteinLimit({
    required double weight,
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();
    final stageNum = stage.toLowerCase();

    if (disease.contains('hemodialysis')) {
      return (weight * 1.2).toStringAsFixed(0);
    }

    if (stageNum.contains('stage 1') || stageNum.contains('stage 2')) {
      return (weight * 0.8).toStringAsFixed(0);
    }

    if (stageNum.contains('stage 3') ||
        stageNum.contains('stage 4') ||
        stageNum.contains('stage 5')) {
      final protein = weight * 0.8;
      return protein.toStringAsFixed(0);
    }

    return "N/A";
  }

  String calculatePotassiumLimit({
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();

    if (disease.contains('hemodialysis')) {
      return "3000";
    }

    return "No restriction unless blood potassium level is elevated";
  }

  String calculatePhosphateLimit({
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();
    final stageNum = stage.toLowerCase();

    if (disease.contains('hemodialysis')) {
      return "1000";
    }

    if (stageNum.contains('stage 1') || stageNum.contains('stage 2')) {
      return "No restriction";
    }

    if (stageNum.contains('stage 3') ||
        stageNum.contains('stage 4') ||
        stageNum.contains('stage 5')) {
      return "1000";
    }

    return "N/A";
  }

  void initializeControllers(Map<String, dynamic> data) {
    if (initialized) return;

    final double weight = double.tryParse(data['weight'].toString()) ?? 0.0;

    final String stage = data['stage']?.toString() ?? "";

    final String typeOfDisease = data['typeOfDisease']?.toString() ?? "";

    caloriesController.text =
        data['caloriesLimit']?.toString() ?? calculateCaloriesLimit(weight);

    proteinController.text =
        data['proteinLimit']?.toString() ??
        calculateProteinLimit(
          weight: weight,
          typeOfDisease: typeOfDisease,
          stage: stage,
        );

    potassiumController.text =
        data['potassiumLimit']?.toString() ??
        calculatePotassiumLimit(typeOfDisease: typeOfDisease, stage: stage);

    phosphateController.text =
        data['phosphateLimit']?.toString() ??
        calculatePhosphateLimit(typeOfDisease: typeOfDisease, stage: stage);

    initialized = true;
  }

  Future<void> saveLimits() async {
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'caloriesLimit': caloriesController.text.trim(),
      'proteinLimit': proteinController.text.trim(),
      'potassiumLimit': potassiumController.text.trim(),
      'phosphateLimit': phosphateController.text.trim(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Limits saved successfully!")));

    Navigator.pop(context);
  }

  Widget infoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 188, 218, 198),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF223C3A), width: 3),
      ),
      child: const Text(
        "You may edit the recommended nutrient limits below based on advice from your doctor or renal dietitian.",
        style: TextStyle(
          color: Color(0xFF223C3A),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget nutrientBox({
    required String title,
    required String recommendedValue,
    required TextEditingController controller,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 28, 39, 38),
          width: 3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color.fromARGB(255, 3, 10, 2),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "Recommended: $recommendedValue $unit",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: "Edit if needed",
              hintStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 208, 250, 229),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No user data found"));
            }

            initializeControllers(snapshot.data!);

            final data = snapshot.data!;

            final double weight =
                double.tryParse(data['weight'].toString()) ?? 0.0;

            final String stage = data['stage']?.toString() ?? "";

            final String typeOfDisease =
                data['typeOfDisease']?.toString() ?? "";

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: Color(0xFF223C3A),
                          size: 42,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Your Daily Limits",
                          style: TextStyle(
                            color: Color(0xFF223C3A),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  infoBox(),
                  const SizedBox(height: 18),

                  nutrientBox(
                    title: "Calories",
                    recommendedValue: calculateCaloriesLimit(weight),
                    controller: caloriesController,
                    unit: "kcal",
                    icon: Icons.local_fire_department,
                    color: const Color.fromARGB(255, 180, 131, 59),
                  ),

                  const SizedBox(height: 12),

                  nutrientBox(
                    title: "Protein",
                    recommendedValue: calculateProteinLimit(
                      weight: weight,
                      typeOfDisease: typeOfDisease,
                      stage: stage,
                    ),
                    controller: proteinController,
                    unit: "g",
                    icon: Icons.fitness_center,
                    color: const Color(0xFF225AA8),
                  ),

                  const SizedBox(height: 12),

                  nutrientBox(
                    title: "Potassium",
                    recommendedValue: calculatePotassiumLimit(
                      typeOfDisease: typeOfDisease,
                      stage: stage,
                    ),
                    controller: potassiumController,
                    unit: "mg",
                    icon: Icons.flash_on,
                    color: const Color.fromARGB(255, 121, 51, 115),
                  ),

                  const SizedBox(height: 12),

                  nutrientBox(
                    title: "Phosphate",
                    recommendedValue: calculatePhosphateLimit(
                      typeOfDisease: typeOfDisease,
                      stage: stage,
                    ),
                    controller: phosphateController,
                    unit: "mg",
                    icon: Icons.medication,
                    color: const Color(0xFF6D3BAA),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF223C3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: saveLimits,
                      child: const Text(
                        "Save Limits",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
