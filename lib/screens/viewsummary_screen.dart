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

  bool hasNoLimit(dynamic limit) {
    if (limit == null) return true;

    final text = limit.toString().toLowerCase();

    return text.contains('tiada sekatan') ||
        text.contains('no restriction') ||
        text.contains('n/a');
  }

  double getMaxLimit(String limit) {
    if (limit.contains("-")) {
      final parts = limit.split("-");
      return double.tryParse(parts.last.trim()) ?? 0.0;
    }
    return double.tryParse(limit) ?? 0.0;
  }

  double normalizeCalories(dynamic value) => toDouble(value);
  double normalizeProtein(dynamic value) => toDouble(value);
  double normalizeMineral(dynamic value) => toDouble(value);

  double calculateDailyPercentage({
    required double intake,
    required double dailyLimit,
  }) {
    if (dailyLimit <= 0) return 0.0;
    return (intake / dailyLimit) * 100;
  }

  String getStatus(double percentage) {
    if (percentage < 70) return "Dalam Had";
    if (percentage <= 100) return "Hampir Had";
    return "Melebihi Had";
  }

  Color getStatusColor(String status) {
    if (status == "Dalam Had") return Colors.green;
    if (status == "Hampir Had") return Colors.orange;
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
          "Ringkasan Harian",
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
              return const Center(
                child: Text("Tidak dapat memuatkan ringkasan."),
              );
            }

            final userData = snapshot.data![0] as Map<String, dynamic>?;
            final todayTotal = snapshot.data![1] as Map<String, double>;

            if (userData == null) {
              return const Center(
                child: Text(
                  "Tiada had pengguna dijumpai.\nSila buka Profil Renal terlebih dahulu.",
                  textAlign: TextAlign.center,
                ),
              );
            }

            final bool potassiumNoLimit = hasNoLimit(
              userData['potassiumLimit'],
            );
            final bool phosphateNoLimit = hasNoLimit(
              userData['phosphateLimit'],
            );

            final double caloriesLimit = getMaxLimit(
              userData['caloriesLimit']?.toString() ?? "0",
            );

            final double proteinLimit = getMaxLimit(
              userData['proteinLimit']?.toString() ?? "0",
            );

            final double potassiumLimit = potassiumNoLimit
                ? 0
                : getMaxLimit(userData['potassiumLimit']?.toString() ?? "0");

            final double phosphateLimit = phosphateNoLimit
                ? 0
                : getMaxLimit(userData['phosphateLimit']?.toString() ?? "0");

            final double totalCaloriesToday = todayTotal['calories'] ?? 0;
            final double totalProteinToday = todayTotal['protein'] ?? 0;
            final double totalPotassiumToday = todayTotal['potassium'] ?? 0;
            final double totalPhosphateToday = todayTotal['phosphate'] ?? 0;

            final double caloriesBalance = caloriesLimit - totalCaloriesToday;
            final double proteinBalance = proteinLimit - totalProteinToday;

            final double potassiumBalance = potassiumNoLimit
                ? 999999
                : potassiumLimit - totalPotassiumToday;

            final double phosphateBalance = phosphateNoLimit
                ? 999999
                : phosphateLimit - totalPhosphateToday;

            final double caloriesPercent = calculateDailyPercentage(
              intake: totalCaloriesToday,
              dailyLimit: caloriesLimit,
            );

            final double proteinPercent = calculateDailyPercentage(
              intake: totalProteinToday,
              dailyLimit: proteinLimit,
            );

            final double potassiumPercent = potassiumNoLimit
                ? 0
                : calculateDailyPercentage(
                    intake: totalPotassiumToday,
                    dailyLimit: potassiumLimit,
                  );

            final double phosphatePercent = phosphateNoLimit
                ? 0
                : calculateDailyPercentage(
                    intake: totalPhosphateToday,
                    dailyLimit: phosphateLimit,
                  );

            final String caloriesStatus = getStatus(caloriesPercent);
            final String proteinStatus = getStatus(proteinPercent);
            final String potassiumStatus = potassiumNoLimit
                ? "Tiada Had"
                : getStatus(potassiumPercent);
            final String phosphateStatus = phosphateNoLimit
                ? "Tiada Had"
                : getStatus(phosphatePercent);

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
                              "Ringkasan $mealType",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 35, 63, 45),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$todayDisplay • Semak sebelum simpan",
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
                  "Pengambilan Hidangan Ini",
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
                        "Kalori",
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
                        "Kalium",
                        formatValue(currentPotassium, "mg"),
                        "mg",
                        Icons.bolt,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: nutrientCard(
                        "Fosfat",
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
                          "Untuk memasukkan hidangan ini dalam rekod harian anda, sila kembali dan simpan hidangan terlebih dahulu. Selepas disimpan, Jumlah Pengambilan Hari Ini dan Penjejak Had Harian akan dikemas kini secara automatik.",
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
                  "Jumlah Pengambilan Hari Ini",
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
                        "Kalori",
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
                        "Kalium",
                        formatValue(totalPotassiumToday, "mg"),
                        "mg",
                        Icons.bolt,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: nutrientCard(
                        "Fosfat",
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
                  "Penjejak Had Harian",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 35, 63, 45),
                  ),
                ),

                const SizedBox(height: 8),

                progressTile(
                  nutrient: "Kalori",
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

                potassiumNoLimit
                    ? noLimitTile(
                        nutrient: "Kalium",
                        intake: totalPotassiumToday,
                        unit: "mg",
                      )
                    : progressTile(
                        nutrient: "Kalium",
                        intake: totalPotassiumToday,
                        limit: potassiumLimit,
                        balance: potassiumBalance,
                        percentage: potassiumPercent,
                        status: potassiumStatus,
                        unit: "mg",
                      ),

                phosphateNoLimit
                    ? noLimitTile(
                        nutrient: "Fosfat",
                        intake: totalPhosphateToday,
                        unit: "mg",
                      )
                    : progressTile(
                        nutrient: "Fosfat",
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
                            mealPotassiumLimit: potassiumNoLimit
                                ? 999999
                                : potassiumLimit,
                            mealPhosphorusLimit: phosphateNoLimit
                                ? 999999
                                : phosphateLimit,
                            remainingProtein: proteinBalance < 0
                                ? 0
                                : proteinBalance,
                            remainingPotassium: potassiumNoLimit
                                ? 999999
                                : potassiumBalance < 0
                                ? 0
                                : potassiumBalance,
                            remainingPhosphorus: phosphateNoLimit
                                ? 999999
                                : phosphateBalance < 0
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
                          "Lihat Pilihan Makanan Alternatif",
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
            "Diambil Harini: ${formatValue(intake, unit)} $unit / ${formatValue(limit, unit)} $unit",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balance >= 0
                ? "Baki yang tinggal hari ini: ${formatValue(balance, unit)} $unit"
                : "Melebihi had sebanyak: ${formatValue(balance.abs(), unit)} $unit",
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

  Widget noLimitTile({
    required String nutrient,
    required double intake,
    required String unit,
  }) {
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
          Text(
            nutrient,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 35, 63, 45),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Diambil Harini: ${formatValue(intake, unit)} $unit",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              "Tiada sekatan khusus",
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
