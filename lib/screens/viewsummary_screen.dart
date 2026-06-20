import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alternativefood_screen.dart';

class ViewSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ViewSummaryScreen({super.key, required this.data});

  double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  double getMaxLimit(String limit) {
    if (limit.contains("-")) {
      final parts = limit.split("-");
      return double.tryParse(parts.last.trim()) ?? 0.0;
    }
    return double.tryParse(limit) ?? 0.0;
  }

  double normalizeCalories(dynamic value) {
    return toDouble(value);
  }

  double normalizeProtein(dynamic value) {
    return toDouble(value);
  }

  double normalizeMineral(dynamic value) {
    return toDouble(value);
  }

  double calculateDailyPercentage({
    required double intake,
    required double dailyLimit,
  }) {
    if (dailyLimit <= 0) return 0.0;
    return (intake / dailyLimit) * 100;
  }

  String getStatus(double percentage) {
    if (percentage < 70) return "Within Limit";
    if (percentage <= 100) return "Near Limit";
    return "Exceeded";
  }

  Color getStatusColor(String status) {
    if (status == "Within Limit") return Colors.green;
    if (status == "Near Limit") return Colors.orange;
    return Colors.red;
  }

  String getTodayId() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String formatValue(double value, String unit) {
    if (unit == "kcal") return value.toStringAsFixed(0);
    if (unit == "g") return value.toStringAsFixed(1);
    if (unit == "mg") return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  Future<Map<String, dynamic>?> getUserLimits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  Future<Map<String, double>> getTodayTotalIntake(String dateId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {"calories": 0, "protein": 0, "potassium": 0, "phosphate": 0};
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mealLogs')
        .doc(dateId)
        .collection('meals')
        .get();

    double totalCalories = 0;
    double totalProtein = 0;
    double totalPotassium = 0;
    double totalPhosphate = 0;

    for (final doc in snapshot.docs) {
      final meal = doc.data();

      totalCalories += normalizeCalories(meal['calories']);
      totalProtein += normalizeProtein(meal['protein']);
      totalPotassium += normalizeMineral(meal['potassium']);
      totalPhosphate += normalizeMineral(meal['phosphate']);
    }

    return {
      "calories": totalCalories,
      "protein": totalProtein,
      "potassium": totalPotassium,
      "phosphate": totalPhosphate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final String todayDisplay = DateFormat('dd/MM').format(DateTime.now());
    final String dateId = data['logDate']?.toString() ?? getTodayId();
    final String mealType = data['mealType']?.toString() ?? "Meal";

    final double currentCalories = normalizeCalories(data['calories']);
    final double currentProtein = normalizeProtein(data['protein']);
    final double currentPotassium = normalizeMineral(data['potassium']);
    final double currentPhosphate = normalizeMineral(data['phosphate']);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 218, 245, 226),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Summary",
          style: TextStyle(
            color: Color.fromARGB(255, 251, 251, 251),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([getUserLimits(), getTodayTotalIntake(dateId)]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("Unable to load summary."));
            }

            final userData = snapshot.data![0] as Map<String, dynamic>?;
            final todayTotal = snapshot.data![1] as Map<String, double>;

            if (userData == null) {
              return const Center(
                child: Text(
                  "No user limit found.\nPlease open Renal Profile first.",
                  textAlign: TextAlign.center,
                ),
              );
            }

            final double caloriesLimit = getMaxLimit(
              userData['caloriesLimit']?.toString() ?? "0",
            );

            final double proteinLimit = getMaxLimit(
              userData['proteinLimit']?.toString() ?? "0",
            );

            final double potassiumLimit = getMaxLimit(
              userData['potassiumLimit']?.toString() ?? "0",
            );

            final double phosphateLimit = getMaxLimit(
              userData['phosphateLimit']?.toString() ?? "0",
            );

            final double totalCaloriesToday = todayTotal['calories'] ?? 0;
            final double totalProteinToday = todayTotal['protein'] ?? 0;
            final double totalPotassiumToday = todayTotal['potassium'] ?? 0;
            final double totalPhosphateToday = todayTotal['phosphate'] ?? 0;

            final double caloriesBalance = caloriesLimit - totalCaloriesToday;
            final double proteinBalance = proteinLimit - totalProteinToday;
            final double potassiumBalance =
                potassiumLimit - totalPotassiumToday;
            final double phosphateBalance =
                phosphateLimit - totalPhosphateToday;

            final double caloriesPercent = calculateDailyPercentage(
              intake: totalCaloriesToday,
              dailyLimit: caloriesLimit,
            );

            final double proteinPercent = calculateDailyPercentage(
              intake: totalProteinToday,
              dailyLimit: proteinLimit,
            );

            final double potassiumPercent = calculateDailyPercentage(
              intake: totalPotassiumToday,
              dailyLimit: potassiumLimit,
            );

            final double phosphatePercent = calculateDailyPercentage(
              intake: totalPhosphateToday,
              dailyLimit: phosphateLimit,
            );

            final String caloriesStatus = getStatus(caloriesPercent);
            final String proteinStatus = getStatus(proteinPercent);
            final String potassiumStatus = getStatus(potassiumPercent);
            final String phosphateStatus = getStatus(phosphatePercent);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 218, 245, 226),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Color.fromARGB(255, 35, 63, 45),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$mealType Summary",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 35, 63, 45),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$todayDisplay • Review before saving",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 15, 46, 23),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Current Meal Intake",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 35, 63, 45),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: nutrientCard(
                        "Calories",
                        formatValue(currentCalories, "kcal"),
                        "kcal",
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: nutrientCard(
                        "Protein",
                        formatValue(currentProtein, "g"),
                        "g",
                        Icons.fitness_center,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: nutrientCard(
                        "Potassium",
                        formatValue(currentPotassium, "mg"),
                        "mg",
                        Icons.bolt,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: nutrientCard(
                        "Phosphorus",
                        formatValue(currentPhosphate, "mg"),
                        "mg",
                        Icons.science,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 250, 230),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1.3,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color.fromARGB(255, 180, 110, 20),
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "To include this meal in your daily record, please go back and save it first. Once saved, your Total Intake Today and Daily Limit Tracker will be updated automatically.",
                          style: TextStyle(
                            color: Color.fromARGB(255, 95, 65, 20),
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Total Intake Today",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 35, 63, 45),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: nutrientCard(
                        "Calories",
                        formatValue(totalCaloriesToday, "kcal"),
                        "kcal",
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: nutrientCard(
                        "Protein",
                        formatValue(totalProteinToday, "g"),
                        "g",
                        Icons.fitness_center,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: nutrientCard(
                        "Potassium",
                        formatValue(totalPotassiumToday, "mg"),
                        "mg",
                        Icons.bolt,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: nutrientCard(
                        "Phosphorus",
                        formatValue(totalPhosphateToday, "mg"),
                        "mg",
                        Icons.science,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  "Daily Limit Tracker",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 35, 63, 45),
                  ),
                ),

                const SizedBox(height: 8),

                progressTile(
                  nutrient: "Calories",
                  intake: totalCaloriesToday,
                  limit: caloriesLimit,
                  balance: caloriesBalance,
                  percentage: caloriesPercent,
                  status: caloriesStatus,
                  unit: "kcal",
                ),

                progressTile(
                  nutrient: "Protein",
                  intake: totalProteinToday,
                  limit: proteinLimit,
                  balance: proteinBalance,
                  percentage: proteinPercent,
                  status: proteinStatus,
                  unit: "g",
                ),

                progressTile(
                  nutrient: "Potassium",
                  intake: totalPotassiumToday,
                  limit: potassiumLimit,
                  balance: potassiumBalance,
                  percentage: potassiumPercent,
                  status: potassiumStatus,
                  unit: "mg",
                ),

                progressTile(
                  nutrient: "Phosphorus",
                  intake: totalPhosphateToday,
                  limit: phosphateLimit,
                  balance: phosphateBalance,
                  percentage: phosphatePercent,
                  status: phosphateStatus,
                  unit: "mg",
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlternativeFoodScreen(
                            currentFood: data,
                            mealProteinLimit: proteinLimit,
                            mealPotassiumLimit: potassiumLimit,
                            mealPhosphorusLimit: phosphateLimit,
                            remainingProtein: proteinBalance < 0
                                ? 0
                                : proteinBalance,
                            remainingPotassium: potassiumBalance < 0
                                ? 0
                                : potassiumBalance,
                            remainingPhosphorus: phosphateBalance < 0
                                ? 0
                                : phosphateBalance,
                            proteinStatus: proteinStatus,
                            potassiumStatus: potassiumStatus,
                            phosphorusStatus: phosphateStatus,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 35, 63, 45),
                      elevation: 3,
                      shadowColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          "View Alternative Food Choices",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget nutrientCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: " $unit",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget progressTile({
    required String nutrient,
    required double intake,
    required double limit,
    required double balance,
    required double percentage,
    required String status,
    required String unit,
  }) {
    final double value = (percentage / 100).clamp(0.0, 1.0);
    final Color statusColor = getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                nutrient,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 35, 63, 45),
                ),
              ),
              const Spacer(),
              Text(
                "${percentage.toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 14,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Used today: ${formatValue(intake, unit)} $unit / ${formatValue(limit, unit)} $unit",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balance >= 0
                ? "Balance left today: ${formatValue(balance, unit)} $unit"
                : "Exceeded by: ${formatValue(balance.abs(), unit)} $unit",
            style: TextStyle(
              color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
