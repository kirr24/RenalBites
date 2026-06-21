import 'package:flutter/material.dart';
import 'package:renalbites/widgets/bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editrenalprofile_screen.dart';

class RenalProfileScreen extends StatefulWidget {
  const RenalProfileScreen({super.key});

  @override
  State<RenalProfileScreen> createState() => _RenalProfileScreenState();
}

class _RenalProfileScreenState extends State<RenalProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  final Color darkGreen = const Color(0xFF223C3A);
  final Color softGreen = const Color.fromARGB(255, 208, 250, 229);
  final Color boxGreen = const Color.fromARGB(255, 188, 218, 198);

  Future<Map<String, dynamic>?> getUserData() async {
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    return doc.exists ? doc.data() : null;
  }

  String getTextValue(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value == null || value.toString().trim().isEmpty) {
      return 'N/A';
    }

    return value.toString();
  }

  bool isNoRestriction(String value) {
    final text = value.toLowerCase();

    return text.contains('tiada sekatan') ||
        text.contains('no restriction') ||
        text.contains('n/a');
  }

  Widget infoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: boxGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: darkGreen, width: 2),
      ),
      child: Text(
        'Cadangan ini hanyalah panduan umum. Sila rujuk doktor atau pakar diet renal untuk nasihat pemakanan yang lebih sesuai dengan keadaan anda.',
        style: TextStyle(
          color: darkGreen,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget phosphateInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: boxGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: darkGreen, width: 2),
      ),
      child: Text(
        'Nota: Pengambilan fosfat perlu disesuaikan mengikut keperluan protein harian.',
        style: TextStyle(
          color: darkGreen,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget nutrientBox({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final String displayValue = unit.isEmpty ? value : '$value $unit';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 28, 39, 38),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 3, 10, 2),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool shouldShowPhosphateInfo({
    required String typeOfDisease,
    required String stage,
  }) {
    final disease = typeOfDisease.toLowerCase();
    final stageText = stage.toLowerCase();

    return disease.contains('hemodialisis') ||
        disease.contains('hemodialysis') ||
        stageText.contains('tahap 3') ||
        stageText.contains('tahap 4') ||
        stageText.contains('tahap 5') ||
        stageText.contains('stage 3') ||
        stageText.contains('stage 4') ||
        stageText.contains('stage 5');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGreen,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: darkGreen));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Tiada data pengguna dijumpai'));
            }

            final data = snapshot.data!;

            final double weight =
                double.tryParse(data['weight'].toString()) ?? 0.0;

            final String stage = getTextValue(data, 'stage');
            final String typeOfDisease = getTextValue(data, 'typeOfDisease');

            final String caloriesLimit = getTextValue(data, 'caloriesLimit');
            final String proteinLimit = getTextValue(data, 'proteinLimit');
            final String potassiumLimit = getTextValue(data, 'potassiumLimit');
            final String phosphateLimit = getTextValue(data, 'phosphateLimit');

            final bool showPhosphateInfo = shouldShowPhosphateInfo(
              typeOfDisease: typeOfDisease,
              stage: stage,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: darkGreen,
                          size: 42,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Had Nutrien Harian Anda',
                          style: TextStyle(
                            color: darkGreen,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      '$typeOfDisease • $stage • ${weight.toStringAsFixed(0)} kg',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  infoBox(),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: nutrientBox(
                          title: 'Kalori',
                          value: caloriesLimit,
                          unit: 'kcal',
                          icon: Icons.local_fire_department,
                          color: const Color.fromARGB(255, 180, 131, 59),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: nutrientBox(
                          title: 'Protein',
                          value: proteinLimit,
                          unit: 'g',
                          icon: Icons.fitness_center,
                          color: const Color(0xFF225AA8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  nutrientBox(
                    title: 'Kalium',
                    value: potassiumLimit,
                    unit: isNoRestriction(potassiumLimit) ? '' : 'mg',
                    icon: Icons.flash_on,
                    color: const Color.fromARGB(255, 121, 51, 115),
                  ),

                  const SizedBox(height: 12),

                  nutrientBox(
                    title: 'Fosfat',
                    value: phosphateLimit,
                    unit: isNoRestriction(phosphateLimit) ? '' : 'mg',
                    icon: Icons.medication,
                    color: const Color(0xFF6D3BAA),
                  ),

                  if (showPhosphateInfo) ...[
                    const SizedBox(height: 12),
                    phosphateInfoBox(),
                  ],

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EditRenalProfileScreen(),
                          ),
                        );

                        setState(() {});
                      },
                      child: const Text(
                        'Kemaskini Had',
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
