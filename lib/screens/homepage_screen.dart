import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  String? selectedFoodName;

  void dispose() {}
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
  String? selectedCategory;

  final List<String> category = [
    'Buah-buahan',
    'Sayur-sayuran',
    'Hidangan Nasi',
    'Mi dan Pasta',
    'Roti, Sandwic dan Bun',
    'Makanan India',
    'Hidangan Ayam',
    'Hidangan Daging Merah',
    'Ikan dan Makanan Laut',
    'Kekacang dan Legum',
    'Hidangan Bubur',
    'Snek dan Makanan Bergoreng',
    'Kuih-muih',
    'Minuman dan Bahan Minuman',
  ];

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

  Future<Map<String, dynamic>?> getFoodFromFirebase(String foodName) async {
    final searchName = foodName.toLowerCase().trim();

    final query = await FirebaseFirestore.instance
        .collection('foods')
        .where('name', isEqualTo: searchName)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    }

    return null;
  }

  Future<Map<String, dynamic>?> prepareMealResult() async {
    if (selectedMealType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila pilih jenis hidangan')),
      );
      return null;
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalPotassium = 0;
    double totalPhosphate = 0;

    List<Map<String, dynamic>> foodDetails = [];

    for (final food in foodInputs) {
      final foodName = food.selectedFoodName;

      if (foodName == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sila pilih makanan')));
        return null;
      }

      final firebaseData = await getFoodFromFirebase(foodName);

      if (firebaseData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$foodName tidak dijumpai dalam pangkalan data'),
          ),
        );
        return null;
      }

      final double calories = toDouble(firebaseData['calories']);
      final double protein = toDouble(firebaseData['protein']);
      final double potassium = toDouble(firebaseData['potassium']);
      final double phosphate = toDouble(firebaseData['phosphate']);
      final double servingSize = toDouble(firebaseData['servingSize']);

      totalCalories += calories;
      totalProtein += protein;
      totalPotassium += potassium;
      totalPhosphate += phosphate;

      foodDetails.add({
        "mealName": foodName,
        "serving": "${servingSize.toStringAsFixed(0)} g",
        "calories": calories,
        "protein": protein,
        "potassium": potassium,
        "phosphate": phosphate,
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
      ).showSnackBar(SnackBar(content: Text('Berlaku ralat: $e')));
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hidangan berjaya disimpan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Berlaku ralat: $e')));
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
      selectedCategory = null;
      date = DateTime.now();

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

  Widget noteBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 249, 220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nota: Aplikasi ini menggunakan saiz hidangan standard yang disimpan dalam sistem bagi setiap makanan.',
              style: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 80, 70, 40),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
            Icon(icon, color: Color.fromARGB(255, 35, 63, 45), size: 22),
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

  Widget foodDropdown(FoodInput food) {
    if (selectedCategory == null) {
      return const Text(
        'Sila pilih kategori makanan terlebih dahulu',
        style: TextStyle(color: Colors.grey),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foods')
          .where('category', isEqualTo: selectedCategory)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Ralat: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Tiada makanan dijumpai');
        }

        final docs = snapshot.data!.docs;

        return DropdownButton<String>(
          value: food.selectedFoodName,
          hint: const Text('Pilih Makanan'),
          isExpanded: true,
          underline: const SizedBox(),
          items: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final foodName = data['name'].toString();

            return DropdownMenuItem<String>(
              value: foodName,
              child: Text(foodName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              food.selectedFoodName = value;
            });
          },
        );
      },
    );
  }

  Widget foodInputCard(int index) {
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
              Expanded(child: foodDropdown(food)),
            ],
          ),

          Divider(color: Colors.grey.shade300),

          if (foodInputs.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    foodInputs.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Buang', style: TextStyle(color: Colors.red)),
              ),
            ),
        ],
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
          "Log Makanan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      drawer: Drawer(
        child: Container(
          color: const Color.fromARGB(255, 218, 245, 226),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
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
                      "Pengguna";

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
                          child: ClipOval(
                            child: photoUrl.isNotEmpty
                                ? Image.network(
                                    photoUrl,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Color.fromARGB(255, 35, 63, 45),
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color.fromARGB(255, 35, 63, 45),
                                  ),
                          ),
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
                title: const Text('Profil Pengguna'),
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
                title: const Text('Kemaskini Profil'),
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
                title: const Text('Resipi'),
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
                title: const Text('Maklumat Penyakit Buah Pinggang'),
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
                      'Log Keluar',
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
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Color.fromARGB(255, 35, 63, 45),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    getFormattedDate(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 35, 63, 45),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            noteBox(),

            const SizedBox(height: 18),

            sectionTitle("Jenis Hidangan"),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: DropdownButton<String>(
                value: selectedMealType,
                hint: const Text('Pilih Jenis Hidangan'),
                isExpanded: true,
                underline: const SizedBox(),
                items:
                    <String>[
                      'Sarapan',
                      'Makan Tengah Hari',
                      'Makan Malam',
                      'Snek',
                    ].map((String value) {
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

            sectionTitle("Kategori Makanan"),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: DropdownButton<String>(
                value: selectedCategory,
                hint: const Text('Pilih Kategori Makanan'),
                isExpanded: true,
                underline: const SizedBox(),
                items: category.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue;

                    for (final food in foodInputs) {
                      food.selectedFoodName = null;
                    }
                  });
                },
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(child: sectionTitle("Makanan")),
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
                    "Tambah Makanan",
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
                return foodInputCard(index);
              },
            ),

            const SizedBox(height: 10),

            actionButton(
              text: 'Lihat Ringkasan',
              icon: Icons.summarize,
              onTap: viewSummary,
              loading: _isLoading,
            ),

            const SizedBox(height: 10),

            actionButton(
              text: 'Simpan Hidangan',
              icon: Icons.save,
              onTap: saveMeal,
              loading: _isSaving,
            ),

            const SizedBox(height: 10),

            outlineActionButton(
              text: 'Tetapkan Semula',
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
