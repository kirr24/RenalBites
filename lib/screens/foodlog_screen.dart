import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:renalbites/widgets/bottom_nav_bar.dart';
import 'package:renalbites/screens/homepage_screen.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedMealType = "Sarapan";

  final List<String> mealTypes = [
    "Sarapan",
    "Makan Tengah Hari",
    "Makan Malam",
    "Snek",
  ];

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
        text.contains('n/a') ||
        text.contains('tidak berkenaan');
  }

  double normalizeCalories(dynamic value) {
    return toDouble(value);
  }

  double normalizeProtein(dynamic value) {
    return toDouble(value);
  }

  double normalizeMineralToMg(dynamic value) {
    return toDouble(value);
  }

  String getDateId(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String formatDisplayDate(DateTime date) {
    return DateFormat('d MMMM y').format(date);
  }

  String formatValue(double value, String unit) {
    if (unit == "kcal") return value.toStringAsFixed(0);
    if (unit == "g") return value.toStringAsFixed(1);
    if (unit == "mg") return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  double getMaxLimit(String limit) {
    if (limit.contains("-")) {
      final parts = limit.split("-");
      return double.tryParse(parts.last.trim()) ?? 0.0;
    }
    return double.tryParse(limit) ?? 0.0;
  }

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

  void goToFoodLogging() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(selectedDate: selectedDate),
      ),
    );
  }

  Future<void> pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
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

  Future<Map<String, dynamic>?> getSelectedMealLog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final dateId = getDateId(selectedDate);
    final mealDocId = selectedMealType.toLowerCase();

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mealLogs')
        .doc(dateId)
        .collection('meals')
        .doc(mealDocId)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  Future<Map<String, double>> getDailyTotalIntake() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {"calories": 0, "protein": 0, "potassium": 0, "phosphate": 0};
    }

    final dateId = getDateId(selectedDate);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mealLogs')
        .doc(dateId)
        .collection('meals')
        .get();

    double calories = 0;
    double protein = 0;
    double potassium = 0;
    double phosphate = 0;

    for (final doc in snapshot.docs) {
      final meal = doc.data();

      calories += normalizeCalories(meal['calories']);
      protein += normalizeProtein(meal['protein']);
      potassium += normalizeMineralToMg(meal['potassium']);
      phosphate += normalizeMineralToMg(meal['phosphate']);
    }

    return {
      "calories": calories,
      "protein": protein,
      "potassium": potassium,
      "phosphate": phosphate,
    };
  }

  Future<List<dynamic>> loadFoodLogData() async {
    return Future.wait([
      getUserLimits(),
      getSelectedMealLog(),
      getDailyTotalIntake(),
    ]);
  }

  Widget nutrientCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: " $unit",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
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
            "Pengambilan hari ini: ${formatValue(intake, unit)} $unit / ${formatValue(limit, unit)} $unit",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balance >= 0
                ? "Baki hari ini: ${formatValue(balance, unit)} $unit"
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
            "Pengambilan hari ini: ${formatValue(intake, unit)} $unit",
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

  Widget foodList(Map<String, dynamic> mealData) {
    final foods = mealData['foods'];

    if (foods == null || foods is! List || foods.isEmpty) {
      return const Text("Tiada butiran makanan tersedia.");
    }

    return Column(
      children: foods.map<Widget>((food) {
        final foodMap = Map<String, dynamic>.from(food);

        final double servingSize = toDouble(foodMap['servingSize']);
        final String servingText = servingSize > 0
            ? "${servingSize.toStringAsFixed(0)} g"
            : foodMap['serving']?.toString() ?? "";

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 240, 252, 244),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.restaurant,
                color: Color.fromARGB(255, 35, 63, 45),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${foodMap['mealName']} • $servingText",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget logFoodButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: goToFoodLogging,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          "Tambah Pengambilan Makanan",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 35, 63, 45),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeSelectedMealType = mealTypes.contains(selectedMealType)
        ? selectedMealType
        : null;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 218, 245, 226),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: const Text(
          "Kalendar Log Makanan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Color.fromARGB(255, 35, 63, 45),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formatDisplayDate(selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 35, 63, 45),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: DropdownButton<String>(
                value: safeSelectedMealType,
                hint: const Text("Pilih jenis hidangan"),
                isExpanded: true,
                underline: const SizedBox(),
                items: mealTypes.map((meal) {
                  return DropdownMenuItem<String>(
                    value: meal,
                    child: Text(meal),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedMealType = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 18),

            FutureBuilder<List<dynamic>>(
              future: loadFoodLogData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text("Log makanan tidak dapat dimuatkan."),
                  );
                }

                final userData = snapshot.data![0] as Map<String, dynamic>?;
                final mealData = snapshot.data![1] as Map<String, dynamic>?;
                final todayTotal = snapshot.data![2] as Map<String, double>;

                if (userData == null) {
                  return const Center(
                    child: Text(
                      "Had nutrien pengguna tidak dijumpai.\nSila buka Profil Renal terlebih dahulu.",
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
                    : getMaxLimit(
                        userData['potassiumLimit']?.toString() ?? "0",
                      );

                final double phosphateLimit = phosphateNoLimit
                    ? 0
                    : getMaxLimit(
                        userData['phosphateLimit']?.toString() ?? "0",
                      );

                final double totalCaloriesToday = todayTotal['calories'] ?? 0;
                final double totalProteinToday = todayTotal['protein'] ?? 0;
                final double totalPotassiumToday = todayTotal['potassium'] ?? 0;
                final double totalPhosphateToday = todayTotal['phosphate'] ?? 0;

                final double caloriesBalance =
                    caloriesLimit - totalCaloriesToday;
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
                final String potassiumStatus = getStatus(potassiumPercent);
                final String phosphateStatus = getStatus(phosphatePercent);

                if (mealData == null) {
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 44,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Tiada log $selectedMealType dijumpai untuk ${formatDisplayDate(selectedDate)}.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      logFoodButton(),
                    ],
                  );
                }

                final double mealCalories = normalizeCalories(
                  mealData['calories'],
                );
                final double mealProtein = normalizeProtein(
                  mealData['protein'],
                );
                final double mealPotassium = normalizeMineralToMg(
                  mealData['potassium'],
                );
                final double mealPhosphate = normalizeMineralToMg(
                  mealData['phosphate'],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pengambilan $selectedMealType",
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 35, 63, 45),
                      ),
                    ),

                    const SizedBox(height: 10),

                    foodList(mealData),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: nutrientCard(
                            "Kalori",
                            formatValue(mealCalories, "kcal"),
                            "kcal",
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: nutrientCard(
                            "Protein",
                            formatValue(mealProtein, "g"),
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
                            formatValue(mealPotassium, "mg"),
                            "mg",
                            Icons.bolt,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: nutrientCard(
                            "Fosfat",
                            formatValue(mealPhosphate, "mg"),
                            "mg",
                            Icons.science,
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      "Jumlah Pengambilan untuk Tarikh Dipilih",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 35, 63, 45),
                      ),
                    ),

                    const SizedBox(height: 10),

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

                    const SizedBox(height: 22),

                    const Text(
                      "Penjejak Had Harian",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 35, 63, 45),
                      ),
                    ),

                    const SizedBox(height: 10),

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

                    const SizedBox(height: 20),

                    logFoodButton(),

                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
