// ignore_for_file: equal_keys_in_map

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renalbites/screens/editprofile_screen.dart';
import 'package:renalbites/screens/kidneydiseaseinfo_screen.dart';
import 'package:renalbites/screens/recipes_screen.dart';
import 'package:renalbites/screens/splash_screen.dart';
import 'package:renalbites/widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'viewsummary_screen.dart';
import 'userprofile_screen.dart';

class FoodInput {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }
}

class HomePage extends StatefulWidget {
  final DateTime? selectedDate;
  const HomePage({super.key, this.selectedDate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<FoodInput> foodInputs = [FoodInput()];

  bool _isLoading = false;
  bool _isSaving = false;
  String? selectedMealType;

  late DateTime date;

  @override
  void initState() {
    super.initState();
    date = widget.selectedDate ?? DateTime.now();
  }

  String getFormattedDate() {
    return DateFormat('MMMM d, y').format(date);
  }

  String getTodayId() {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String normalizeFoodName(String name) {
    return name.toLowerCase().trim().replaceAll(' ', '_');
  }

  Future<Map<String, dynamic>?> getFoodFromFirebase(String foodName) async {
    final searchName = foodName.toLowerCase().trim();
    final docId = normalizeFoodName(foodName);

    final doc = await FirebaseFirestore.instance
        .collection('foods')
        .doc(docId)
        .get();

    if (doc.exists) return doc.data();

    final malayQuery = await FirebaseFirestore.instance
        .collection('foods')
        .where('malayNameLower', isEqualTo: searchName)
        .limit(1)
        .get();

    if (malayQuery.docs.isNotEmpty) {
      return malayQuery.docs.first.data();
    }

    final englishQuery = await FirebaseFirestore.instance
        .collection('foods')
        .where('englishNameLower', isEqualTo: searchName)
        .limit(1)
        .get();

    if (englishQuery.docs.isNotEmpty) {
      return englishQuery.docs.first.data();
    }

    return null;
  }

  String getDisplayFoodName(Map<String, dynamic> data, String typedName) {
    return data['malayName']?.toString() ??
        data['englishName']?.toString() ??
        data['name']?.toString() ??
        typedName;
  }

  Future<Map<String, dynamic>?> prepareMealResult() async {
    if (selectedMealType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select meal type')));
      return null;
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalPotassium = 0;
    double totalPhosphate = 0;

    List<Map<String, dynamic>> foodDetails = [];

    for (final food in foodInputs) {
      final foodName = food.nameController.text.trim();
      final quantityText = food.quantityController.text.trim();

      if (foodName.isEmpty || quantityText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all food fields')),
        );
        return null;
      }

      final double? quantity = double.tryParse(quantityText);

      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid quantity')),
        );
        return null;
      }

      final firebaseData = await getFoodFromFirebase(foodName);

      if (firebaseData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$foodName not found in database')),
        );
        return null;
      }

      final double caloriesPer100g = toDouble(firebaseData['calories']);
      final double proteinPer100g = toDouble(firebaseData['protein']);
      final double potassiumPer100g = toDouble(firebaseData['potassium']);
      final double phosphatePer100g = toDouble(firebaseData['phosphate']);

      final double calories = caloriesPer100g * quantity / 100;
      final double protein = proteinPer100g * quantity / 100;
      final double potassium = potassiumPer100g * quantity / 100;
      final double phosphate = phosphatePer100g * quantity / 100;

      totalCalories += calories;
      totalProtein += protein;
      totalPotassium += potassium;
      totalPhosphate += phosphate;

      foodDetails.add({
        "mealName": getDisplayFoodName(firebaseData, foodName),
        "quantity": quantity,
        "serving": "100g",
        "calories": calories,
        "protein": protein,
        "potassium": potassium,
        "phosphate": phosphate,
        "caloriesPer100g": caloriesPer100g,
        "proteinPer100g": proteinPer100g,
        "potassiumPer100g": potassiumPer100g,
        "phosphatePer100g": phosphatePer100g,
        "foodData": firebaseData,
      });
    }

    return {
      "mealType": selectedMealType,
      "mealName": foodDetails.map((f) => f["mealName"]).join(", "),
      "foods": foodDetails,
      "calories": totalCalories,
      "protein": totalProtein,
      "potassium": totalPotassium,
      "phosphate": totalPhosphate,
      "logDate": getTodayId(),
    };
  }

  Future<void> saveMealLogToFirebase(Map<String, dynamic> result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String dateId = getTodayId();
    final String mealDocId = result['mealType'].toString().toLowerCase().trim();

    final dayRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mealLogs')
        .doc(dateId);

    final mealRef = dayRef.collection('meals').doc(mealDocId);

    await mealRef.set({
      "mealType": result["mealType"],
      "mealName": result["mealName"],
      "foods": result["foods"],
      "calories": result["calories"],
      "protein": result["protein"],
      "potassium": result["potassium"],
      "phosphate": result["phosphate"],
      "date": dateId,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await dayRef.set({
      "date": dateId,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> viewSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await prepareMealResult();

      if (result == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewSummaryScreen(data: result),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveMeal() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final result = await prepareMealResult();

      if (result == null) {
        setState(() {
          _isSaving = false;
        });
        return;
      }

      await saveMealLogToFirebase(result);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Meal saved successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void resetForm() {
    setState(() {
      selectedMealType = null;

      date = DateTime.now();

      for (final food in foodInputs) {
        food.dispose();
      }

      foodInputs.clear();
      foodInputs.add(FoodInput());
    });
  }

  @override
  void dispose() {
    for (final food in foodInputs) {
      food.dispose();
    }
    super.dispose();
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 35, 63, 45),
        ),
      ),
    );
  }

  Widget actionButton({
    required String text,
    required IconData icon,
    required VoidCallback? onTap,
    required bool loading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 35, 63, 45),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget outlineActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color.fromARGB(255, 35, 63, 45),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color.fromARGB(255, 35, 63, 45), size: 22),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Color.fromARGB(255, 35, 63, 45),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 218, 245, 226),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Food Logging",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      drawer: Drawer(
        child: Container(
          color: const Color.fromARGB(255, 218, 245, 226),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const DrawerHeader(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 35, 63, 45),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};

                  final String username =
                      userData['username']?.toString() ??
                      userData['userId']?.toString() ??
                      "User";

                  final String photoUrl =
                      userData['photoUrl']?.toString() ?? "";

                  return DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 35, 63, 45),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color.fromARGB(255, 35, 63, 45),
                                )
                              : null,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('User Profile'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UserprofileScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditprofileScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: const Text('Recipes'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RecipesScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: const Text('Kidney Disease Info'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const KidneyDiseaseInfoScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 35, 63, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      if (!mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SplashScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 218, 245, 226),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Color.fromARGB(255, 35, 63, 45),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      getFormattedDate(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 35, 63, 45),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            sectionTitle("Meal Type"),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
              child: DropdownButton<String>(
                value: selectedMealType,
                hint: const Text('Select Meal Type'),
                isExpanded: true,
                underline: const SizedBox(),
                items: <String>['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedMealType = newValue;
                  });
                },
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(child: sectionTitle("Foods")),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      foodInputs.add(FoodInput());
                    });
                  },
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color.fromARGB(255, 35, 63, 45),
                  ),
                  label: const Text(
                    "Add Food",
                    style: TextStyle(
                      color: Color.fromARGB(255, 35, 63, 45),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: foodInputs.length,
              itemBuilder: (context, index) {
                final food = foodInputs[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant,
                            color: Color.fromARGB(255, 35, 63, 45),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: food.nameController,
                              decoration: InputDecoration(
                                hintText: 'Food ${index + 1}, e.g. nasi putih',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Divider(color: Colors.grey.shade300),

                      Row(
                        children: [
                          const Icon(
                            Icons.scale,
                            color: Color.fromARGB(255, 35, 63, 45),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: food.quantityController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*$'),
                                ),
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                hintText: 'Quantity',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const Text(
                            'grams',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color.fromARGB(255, 35, 63, 45),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      if (foodInputs.length > 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                food.dispose();
                                foodInputs.removeAt(index);
                              });
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            actionButton(
              text: 'View Summary',
              icon: Icons.summarize,
              onTap: viewSummary,
              loading: _isLoading,
            ),

            const SizedBox(height: 10),

            actionButton(
              text: 'Save Meal',
              icon: Icons.save,
              onTap: saveMeal,
              loading: _isSaving,
            ),

            const SizedBox(height: 10),

            outlineActionButton(
              text: 'Reset',
              icon: Icons.refresh,
              onTap: resetForm,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
