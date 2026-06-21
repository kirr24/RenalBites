import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:renalbites/widgets/bottom_nav_bar.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedTab = "Harian";
  DateTime selectedDate = DateTime.now();

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

  double getMaxLimit(String limit) {
    if (limit.contains("-")) {
      final parts = limit.split("-");
      return double.tryParse(parts.last.trim()) ?? 0.0;
    }
    return double.tryParse(limit) ?? 0.0;
  }

  String getDateId(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String formatValue(double value, String unit) {
    if (unit == "kcal") return value.toStringAsFixed(0);
    if (unit == "g") return value.toStringAsFixed(1);
    if (unit == "mg") return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
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

  List<DateTime> getSelectedDates() {
    if (selectedTab == "Harian") return [selectedDate];

    if (selectedTab == "Mingguan") {
      final monday = selectedDate.subtract(
        Duration(days: selectedDate.weekday - 1),
      );
      return List.generate(7, (index) => monday.add(Duration(days: index)));
    }

    final totalDays = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;

    return List.generate(
      totalDays,
      (index) => DateTime(selectedDate.year, selectedDate.month, index + 1),
    );
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

  Future<Map<String, double>> getTotalIntake() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {"calories": 0, "protein": 0, "potassium": 0, "phosphate": 0};
    }

    double calories = 0;
    double protein = 0;
    double potassium = 0;
    double phosphate = 0;

    for (final date in getSelectedDates()) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mealLogs')
          .doc(getDateId(date))
          .collection('meals')
          .get();

      for (final doc in snapshot.docs) {
        final meal = doc.data();

        calories += normalizeCalories(meal['calories']);
        protein += normalizeProtein(meal['protein']);
        potassium += normalizeMineralToMg(meal['potassium']);
        phosphate += normalizeMineralToMg(meal['phosphate']);
      }
    }

    return {
      "calories": calories,
      "protein": protein,
      "potassium": potassium,
      "phosphate": phosphate,
    };
  }

  Future<List<dynamic>> loadReportData() {
    return Future.wait([getUserLimits(), getTotalIntake()]);
  }

  String getReportDateText() {
    if (selectedTab == "Harian") {
      return DateFormat('d MMMM yyyy').format(selectedDate);
    }

    if (selectedTab == "Mingguan") {
      final monday = selectedDate.subtract(
        Duration(days: selectedDate.weekday - 1),
      );
      final sunday = monday.add(const Duration(days: 6));
      return "${DateFormat('d MMM').format(monday)} - ${DateFormat('d MMM yyyy').format(sunday)}";
    }

    return DateFormat('MMMM yyyy').format(selectedDate);
  }

  double getPeriodMultiplier() {
    if (selectedTab == "Harian") return 1;
    if (selectedTab == "Mingguan") return 7;

    return DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day.toDouble();
  }

  double getPercentage(double intake, double limit) {
    if (limit <= 0) return 0.0;
    return (intake / limit) * 100;
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

  Widget tabButton(String text) {
    final selected = selectedTab == text;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = text;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? const Color.fromARGB(255, 35, 63, 45)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : const Color.fromARGB(255, 35, 63, 45),
              fontWeight: FontWeight.bold,
            ),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

  Widget nutrientBarChart({
    required double calories,
    required double caloriesLimit,
    required double protein,
    required double proteinLimit,
    required double potassium,
    required double potassiumLimit,
    required double phosphate,
    required double phosphateLimit,
    required bool potassiumNoLimit,
    required bool phosphateNoLimit,
  }) {
    final List<Map<String, dynamic>> chartItems = [
      {
        "name": "Kalori",
        "intake": calories,
        "limit": caloriesLimit,
        "unit": "kcal",
        "percent": getPercentage(calories, caloriesLimit),
      },
      {
        "name": "Protein",
        "intake": protein,
        "limit": proteinLimit,
        "unit": "g",
        "percent": getPercentage(protein, proteinLimit),
      },
    ];

    if (!potassiumNoLimit) {
      chartItems.add({
        "name": "Kalium",
        "intake": potassium,
        "limit": potassiumLimit,
        "unit": "mg",
        "percent": getPercentage(potassium, potassiumLimit),
      });
    }

    if (!phosphateNoLimit) {
      chartItems.add({
        "name": "Fosfat",
        "intake": phosphate,
        "limit": phosphateLimit,
        "unit": "mg",
        "percent": getPercentage(phosphate, phosphateLimit),
      });
    }

    final maxPercent = chartItems
        .map((item) => item["percent"] as double)
        .reduce((a, b) => a > b ? a : b);

    final maxY = (maxPercent > 100 ? maxPercent : 100.0) + 20.0;

    Color barColor(double percent) {
      final status = getStatus(percent);
      return getStatusColor(status);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.green.shade100),
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
          const Text(
            "Carta Bar Had Nutrien",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 35, 63, 45),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "100% bermaksud anda telah mencapai had nutrien yang disyorkan.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (potassiumNoLimit || phosphateNoLimit) ...[
            const SizedBox(height: 6),
            Text(
              "Nutrien tanpa had khusus tidak dipaparkan dalam carta.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 22),

          SizedBox(
            height: 270,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = chartItems[group.x];
                      final name = item["name"].toString();
                      final intake = item["intake"] as double;
                      final limit = item["limit"] as double;
                      final unit = item["unit"].toString();

                      final detail =
                          "${formatValue(intake, unit)} $unit / ${formatValue(limit, unit)} $unit";

                      return BarTooltipItem(
                        "$name\n${rod.toY.toStringAsFixed(0)}%\n$detail",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}%",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= chartItems.length) {
                          return const SizedBox();
                        }

                        final text = chartItems[index]["name"].toString();

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 35, 63, 45),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(chartItems.length, (index) {
                  final percent = chartItems[index]["percent"] as double;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: percent,
                        width: 28,
                        borderRadius: BorderRadius.circular(8),
                        color: barColor(percent),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 14),

          chartLegend("Dalam Had", Colors.green),
          chartLegend("Hampir Had", Colors.orange),
          chartLegend("Melebihi Had", Colors.red),
        ],
      ),
    );
  }

  Widget chartLegend(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget nutrientDetailTile({
    required String nutrient,
    required double intake,
    required double limit,
    required String unit,
  }) {
    final percentage = getPercentage(intake, limit);
    final status = getStatus(percentage);
    final statusColor = getStatusColor(status);
    final balance = limit - intake;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 45,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  "Pengambilan: ${formatValue(intake, unit)} $unit / ${formatValue(limit, unit)} $unit",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  balance >= 0
                      ? "Baki: ${formatValue(balance, unit)} $unit"
                      : "Melebihi had sebanyak: ${formatValue(balance.abs(), unit)} $unit",
                  style: TextStyle(
                    fontSize: 12,
                    color: balance >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Text(
            "${percentage.toStringAsFixed(0)}%",
            style: TextStyle(
              fontSize: 18,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget noLimitDetailTile({
    required String nutrient,
    required double intake,
    required String unit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  "Pengambilan: ${formatValue(intake, unit)} $unit",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Tiada sekatan khusus",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 218, 245, 226),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "Laporan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Laporan Pemakanan",
              style: TextStyle(
                fontSize: 26,
                color: Color.fromARGB(255, 35, 63, 45),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "Pantau jumlah pengambilan nutrien anda",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  tabButton("Harian"),
                  tabButton("Mingguan"),
                  tabButton("Bulanan"),
                ],
              ),
            ),

            const SizedBox(height: 14),

            GestureDetector(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                        getReportDateText(),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color.fromARGB(255, 35, 63, 45),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            FutureBuilder<List<dynamic>>(
              future: loadReportData(),
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
                    child: Text("Laporan tidak dapat dimuatkan."),
                  );
                }

                final userData = snapshot.data![0] as Map<String, dynamic>?;
                final totalData = snapshot.data![1] as Map<String, double>;

                if (userData == null) {
                  return const Center(
                    child: Text(
                      "Had nutrien pengguna tidak dijumpai.\nSila buka Profil Renal terlebih dahulu.",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final multiplier = getPeriodMultiplier();

                final bool potassiumNoLimit = hasNoLimit(
                  userData['potassiumLimit'],
                );
                final bool phosphateNoLimit = hasNoLimit(
                  userData['phosphateLimit'],
                );

                final caloriesLimit =
                    getMaxLimit(userData['caloriesLimit']?.toString() ?? "0") *
                    multiplier;

                final proteinLimit =
                    getMaxLimit(userData['proteinLimit']?.toString() ?? "0") *
                    multiplier;

                final potassiumLimit = potassiumNoLimit
                    ? 0.0
                    : getMaxLimit(
                            userData['potassiumLimit']?.toString() ?? "0",
                          ) *
                          multiplier;

                final phosphateLimit = phosphateNoLimit
                    ? 0.0
                    : getMaxLimit(
                            userData['phosphateLimit']?.toString() ?? "0",
                          ) *
                          multiplier;

                final calories = totalData['calories'] ?? 0;
                final protein = totalData['protein'] ?? 0;
                final potassium = totalData['potassium'] ?? 0;
                final phosphate = totalData['phosphate'] ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Jumlah Pengambilan",
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
                            formatValue(calories, "kcal"),
                            "kcal",
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: nutrientCard(
                            "Protein",
                            formatValue(protein, "g"),
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
                            formatValue(potassium, "mg"),
                            "mg",
                            Icons.bolt,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: nutrientCard(
                            "Fosfat",
                            formatValue(phosphate, "mg"),
                            "mg",
                            Icons.science,
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    nutrientBarChart(
                      calories: calories,
                      caloriesLimit: caloriesLimit,
                      protein: protein,
                      proteinLimit: proteinLimit,
                      potassium: potassium,
                      potassiumLimit: potassiumLimit,
                      phosphate: phosphate,
                      phosphateLimit: phosphateLimit,
                      potassiumNoLimit: potassiumNoLimit,
                      phosphateNoLimit: phosphateNoLimit,
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Butiran Nutrien",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 35, 63, 45),
                      ),
                    ),

                    const SizedBox(height: 8),

                    nutrientDetailTile(
                      nutrient: "Kalori",
                      intake: calories,
                      limit: caloriesLimit,
                      unit: "kcal",
                    ),
                    nutrientDetailTile(
                      nutrient: "Protein",
                      intake: protein,
                      limit: proteinLimit,
                      unit: "g",
                    ),

                    potassiumNoLimit
                        ? noLimitDetailTile(
                            nutrient: "Kalium",
                            intake: potassium,
                            unit: "mg",
                          )
                        : nutrientDetailTile(
                            nutrient: "Kalium",
                            intake: potassium,
                            limit: potassiumLimit,
                            unit: "mg",
                          ),

                    phosphateNoLimit
                        ? noLimitDetailTile(
                            nutrient: "Fosfat",
                            intake: phosphate,
                            unit: "mg",
                          )
                        : nutrientDetailTile(
                            nutrient: "Fosfat",
                            intake: phosphate,
                            limit: phosphateLimit,
                            unit: "mg",
                          ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
