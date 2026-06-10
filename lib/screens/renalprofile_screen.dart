import 'package:flutter/material.dart';
import 'package:renalbites/widgets/bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RenalProfileScreen extends StatefulWidget {
  const RenalProfileScreen({super.key});

  @override
  State<RenalProfileScreen> createState() => _RenalProfileScreenState();
}

class _RenalProfileScreenState extends State<RenalProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool limitsSaved = false;

  Future<Map<String, dynamic>?> getUserData() async {
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    return doc.exists ? doc.data() : null;
  }

  Future<void> saveLimitstoFirestore({
    required String calories,
    required String protein,
    required String potassium,
    required String phosphate,
    required String water,
  }) async {
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'caloriesLimit': calories,
      'proteinLimit': protein,
      'potassiumLimit': potassium,
      'phosphateLimit': phosphate,
      'waterLimit': water,
      'limitsLastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String calculateCaloriesLimit({required double weight}) {
    final calories = weight * 30;
    return calories.toStringAsFixed(0);
  }

  String calculateProteinLimit({
    required double weight,
    required String typeOfDisease,
    required String stage,
  }) {
    stage = stage.toLowerCase();
    final disease = typeOfDisease.toLowerCase();

    if (disease.contains('hemodialysis')) {
      return (weight * 1.2).toStringAsFixed(0);
    }

    if (stage.contains('stage 1') || stage.contains('stage 2')) {
      final min = weight * 0.8;
      final max = weight * 1.0;
      return "${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)}";
    } else if (stage.contains('stage 3')) {
      final min = weight * 0.6;
      final max = weight * 0.8;
      return "${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)}";
    } else if (stage.contains('stage 4')) {
      return (weight * 0.6).toStringAsFixed(0);
    } else if (stage.contains('stage 5')) {
      return "Doctor";
    }

    return "N/A";
  }

  String calculatePotassiumLimit({
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();
    stage = stage.toLowerCase();

    if (disease.contains('hemodialysis')) {
      return "2000";
    } else if (stage.contains('stage 1') || stage.contains('stage 2')) {
      return "4700";
    } else if (stage.contains('stage 3')) {
      return "3000";
    } else if (stage.contains('stage 4')) {
      return "2500";
    } else if (stage.contains('stage 5')) {
      return "2000";
    }

    return "N/A";
  }

  String calculatePhosphateLimit({
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();
    stage = stage.toLowerCase();

    if (disease.contains('hemodialysis') || stage.contains('stage 5')) {
      return "800";
    }

    if (stage.contains('stage 1') ||
        stage.contains('stage 2') ||
        stage.contains('stage 3') ||
        stage.contains('stage 4')) {
      return "1000";
    }

    return "N/A";
  }

  String calculateWaterLimit({
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();
    final stageLower = stage.toLowerCase();

    if (disease.contains('hemodialysis') || stageLower.contains('stage 5')) {
      return "0.5-0.8";
    }

    if (stageLower.contains('stage 1') ||
        stageLower.contains('stage 2') ||
        stageLower.contains('stage 3') ||
        stageLower.contains('stage 4')) {
      return "1.2-1.5";
    }

    return "As prescribed";
  }

  String waterAdviceText({
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();
    final stageLower = stage.toLowerCase();

    if (disease.contains('hemodialysis') || stageLower.contains('stage 5')) {
      return "Recommended fluid intake is 0.5-0.8 litres per day, or as prescribed by your physician.";
    }

    return "Maintain 1.2-1.5 litres per day unless otherwise prescribed by your physician.";
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

            final data = snapshot.data!;

            final double weight =
                double.tryParse(data['weight'].toString()) ?? 0.0;

            final String stage = data['stage']?.toString() ?? "";
            final String typeOfDisease =
                data['typeOfDisease']?.toString() ?? "";

            final String caloriesLimit = calculateCaloriesLimit(weight: weight);

            final String proteinLimit = calculateProteinLimit(
              weight: weight,
              typeOfDisease: typeOfDisease,
              stage: stage,
            );

            final String potassiumLimit = calculatePotassiumLimit(
              typeOfDisease: typeOfDisease,
              stage: stage,
            );

            final String phosphateLimit = calculatePhosphateLimit(
              typeOfDisease: typeOfDisease,
              stage: stage,
            );

            final String waterLimit = calculateWaterLimit(
              typeOfDisease: typeOfDisease,
              stage: stage,
            );

            final String waterAdvice = waterAdviceText(
              typeOfDisease: typeOfDisease,
              stage: stage,
            );

            if (!limitsSaved) {
              limitsSaved = true;

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await saveLimitstoFirestore(
                  calories: caloriesLimit,
                  protein: proteinLimit,
                  potassium: potassiumLimit,
                  phosphate: phosphateLimit,
                  water: waterLimit,
                );
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),

                  Center(
                    child: Column(
                      children: const [
                        Icon(
                          Icons.health_and_safety,
                          color: Color.fromARGB(255, 34, 60, 58),
                          size: 45,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "YOUR DAILY LIMITS",
                          style: TextStyle(
                            color: Color.fromARGB(255, 34, 60, 58),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      "$typeOfDisease • $stage • ${weight.toStringAsFixed(0)} kg",
                      style: const TextStyle(
                        color: Color.fromARGB(255, 34, 60, 58),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 125,
                              child: LimitCard(
                                title: "Calories",
                                value: caloriesLimit,
                                unit: " kcal",
                                icon: Icons.local_fire_department,
                                bgColor: Color(0xFFB85C00),
                                valueColor: Color(0xFFFFC107),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 125,
                              child: LimitCard(
                                title: "Protein",
                                value: proteinLimit,
                                unit:
                                    proteinLimit == "Doctor" ||
                                        proteinLimit == "N/A"
                                    ? ""
                                    : " g",
                                icon: Icons.fitness_center,
                                bgColor: Color(0xFF225AA8),
                                valueColor: Color(0xFF2E9BFF),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 125,
                              child: LimitCard(
                                title: "Potassium",
                                value: potassiumLimit,
                                unit: potassiumLimit == "N/A" ? "" : " mg",
                                icon: Icons.flash_on,
                                bgColor: Color.fromARGB(255, 121, 51, 115),
                                valueColor: Color.fromARGB(255, 202, 131, 221),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 125,
                              child: LimitCard(
                                title: "Phosphate",
                                value: phosphateLimit,
                                unit: phosphateLimit == "N/A" ? "" : " mg",
                                icon: Icons.medication,
                                bgColor: Color(0xFF6D3BAA),
                                valueColor: Color(0xFFCE63FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101F22),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.opacity,
                          color: Color(0xFF22E6D1),
                          size: 45,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "DAILY WATER INTAKE",
                          style: TextStyle(
                            color: Color(0xFF22E6D1),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: waterLimit,
                                style: const TextStyle(
                                  color: Color(0xFF22DFFF),
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(
                                text: " L",
                                style: TextStyle(
                                  color: Color(0xFF22DFFF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          waterAdvice,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
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

class LimitCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color bgColor;
  final Color valueColor;

  const LimitCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.bgColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: value.length > 5 ? 24 : 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
