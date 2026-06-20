import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlternativeFoodScreen extends StatelessWidget {
  final Map<String, dynamic> currentFood;

  final double mealProteinLimit;
  final double mealPotassiumLimit;
  final double mealPhosphorusLimit;

  final double remainingProtein;
  final double remainingPotassium;
  final double remainingPhosphorus;

  final String proteinStatus;
  final String potassiumStatus;
  final String phosphorusStatus;

  const AlternativeFoodScreen({
    super.key,
    required this.currentFood,
    required this.mealProteinLimit,
    required this.mealPotassiumLimit,
    required this.mealPhosphorusLimit,
    required this.remainingProtein,
    required this.remainingPotassium,
    required this.remainingPhosphorus,
    required this.proteinStatus,
    required this.potassiumStatus,
    required this.phosphorusStatus,
  });

  double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String getDisplayName(Map<String, dynamic> food) {
    return food['malayName']?.toString() ??
        food['malayname']?.toString() ??
        food['mealName']?.toString() ??
        food['name']?.toString() ??
        'Unknown Food';
  }

  String getCategory(Map<String, dynamic> food) {
    return food['category']?.toString() ?? '';
  }

  double getCalories(Map<String, dynamic> food) {
    return toDouble(food['caloriesPer100g'] ?? food['calories']);
  }

  double getProtein(Map<String, dynamic> food) {
    return toDouble(food['proteinPer100g'] ?? food['protein']);
  }

  double getPotassium(Map<String, dynamic> food) {
    return toDouble(food['potassiumPer100g'] ?? food['potassium']);
  }

  double getPhosphorus(Map<String, dynamic> food) {
    return toDouble(
      food['phosphatePer100g'] ??
          food['phosphorusPer100g'] ??
          food['phosphate'] ??
          food['phosphorus'],
    );
  }

  Set<String> getLoggedFoodNames() {
    final foods = currentFood['foods'];

    if (foods == null || foods is! List || foods.isEmpty) {
      return {getDisplayName(currentFood).toLowerCase().trim()};
    }

    return foods.map((e) {
      final food = Map<String, dynamic>.from(e as Map);
      return getDisplayName(food).toLowerCase().trim();
    }).toSet();
  }

  Future<List<Map<String, dynamic>>> getFoodsFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('foods').get();

    final List<Map<String, dynamic>> foods = [];

    for (final doc in snapshot.docs) {
      final food = Map<String, dynamic>.from(doc.data());

      food['foodId'] = doc.id;
      food['calories'] = getCalories(food);
      food['protein'] = getProtein(food);
      food['potassium'] = getPotassium(food);
      food['phosphorus'] = getPhosphorus(food);

      foods.add(food);
    }

    return foods;
  }

  List<Map<String, dynamic>> getLoggedFoods() {
    final foods = currentFood['foods'];

    if (foods == null || foods is! List || foods.isEmpty) {
      return [currentFood];
    }

    return foods.map((e) {
      return Map<String, dynamic>.from(e as Map);
    }).toList();
  }

  List<String> getAutomaticMealAdvice() {
    final Set<String> advice = {};

    final loggedFoods = getLoggedFoods();

    if (potassiumStatus == 'Excessive') {
      advice.add('Reduce high-potassium foods in this meal.');
      advice.add(
        'Choose lower-potassium fruits such as apple, grapes, pineapple, papaya or watermelon.',
      );
      advice.add(
        'Boil vegetables before cooking and discard the boiling water.',
      );
      advice.add(
        'Avoid drinking vegetable soup or broth because potassium may leach into the liquid.',
      );
    }

    if (phosphorusStatus == 'Excessive') {
      advice.add(
        'Reduce foods high in phosphorus such as organ meats, processed meats, legumes and large meat portions.',
      );
      advice.add(
        'Choose fresh foods instead of processed or packaged foods whenever possible.',
      );
      advice.add(
        'Limit processed cheese, cola drinks and foods with phosphate additives.',
      );
      advice.add(
        'Follow your dietitian’s advice regarding phosphate binder usage.',
      );
    }

    if (proteinStatus == 'Excessive') {
      advice.add(
        'Reduce the portion size of meat, chicken, fish, egg or seafood.',
      );
      advice.add('Avoid taking multiple high-protein foods in the same meal.');
      advice.add(
        'Replace part of the protein portion with rice or suitable lower-potassium vegetables.',
      );
    }

    if (proteinStatus == 'Deficient') {
      advice.add(
        'Include a suitable portion of high-quality protein such as chicken, fish or egg.',
      );
      advice.add('Spread protein intake evenly throughout the day.');
      advice.add('Choose protein sources recommended by your healthcare team.');
    }

    for (final food in loggedFoods) {
      final category = getCategory(food);

      if (category == 'Hidangan Ayam') {
        advice.add(
          'For chicken dishes, remove visible skin and reduce fried coating.',
        );
        advice.add(
          'Choose grilled, steamed or boiled chicken more often than fried chicken.',
        );
        advice.add('Reduce thick gravy or curry sauce.');
      }

      if (category == 'Hidangan Daging' ||
          category == 'Hidangan Daging Merah') {
        advice.add(
          'For red meat dishes, reduce portion size and choose lean cuts.',
        );
        advice.add('Avoid eating large portions of red meat frequently.');
        advice.add('Limit thick curry, rendang or salty sauces.');
      }

      if (category == 'Ikan dan Makanan Laut') {
        advice.add(
          'Choose fresh fish or seafood instead of salted or processed seafood.',
        );
        advice.add('Limit salty items such as ikan asin and budu.');
        advice.add(
          'Control seafood portion size to manage protein and phosphorus intake.',
        );
      }

      if (category == 'Sayur-sayuran') {
        advice.add(
          'Boil vegetables first and throw away the water before cooking.',
        );
        advice.add('Avoid using vegetable broth in soups or gravies.');
        advice.add(
          'Choose lower-potassium vegetables when potassium intake is high.',
        );
      }

      if (category == 'Buah-buahan') {
        advice.add('Control fruit portion size.');
        advice.add(
          'Choose lower-potassium fruits when potassium level is high.',
        );
        advice.add('Limit high-potassium fruits such as banana.');
      }

      if (category == 'Mi dan Pasta') {
        advice.add('Reduce soup or curry broth intake.');
        advice.add(
          'Limit processed toppings such as fish balls, sausages or processed meat.',
        );
        advice.add(
          'Choose smaller noodle portions and balance with suitable vegetables.',
        );
      }

      if (category == 'Hidangan Nasi') {
        advice.add('Control rice portion size according to your meal plan.');
        advice.add('Reduce salty or oily side dishes served with rice.');
        advice.add('Choose plain rice more often than oily rice dishes.');
      }

      if (category == 'Snek dan Makanan Bergoreng') {
        advice.add(
          'Limit fried snacks because they are usually high in calories and fat.',
        );
        advice.add('Choose steamed, boiled or baked options more often.');
        advice.add('Take smaller portions of fried foods.');
      }

      if (category == 'Kekacang dan Legum') {
        advice.add(
          'Limit legumes such as dhal, lentils, chickpeas and beans if potassium or phosphorus is high.',
        );
        advice.add(
          'Take smaller portions of legumes and balance with lower-potassium foods.',
        );
      }

      if (category == 'Minuman dan Bahan Minuman') {
        advice.add('Limit instant drink powders and highly processed drinks.');
        advice.add('Choose plain water based on your fluid allowance.');
      }
    }

    if (advice.isEmpty) {
      advice.add('Choose fresh home-cooked meals whenever possible.');
      advice.add('Control portion size and avoid oversized meals.');
      advice.add('Limit processed, salty and fried foods.');
      advice.add('Follow your dietitian’s personalized dietary advice.');
    }

    return advice.toList();
  }

  int calculateFoodScore(Map<String, dynamic> food) {
    final double protein = getProtein(food);
    final double potassium = getPotassium(food);
    final double phosphorus = getPhosphorus(food);

    int score = 0;

    final double proteinTarget = remainingProtein > 0
        ? remainingProtein
        : mealProteinLimit;

    final double potassiumTarget = remainingPotassium > 0
        ? remainingPotassium
        : mealPotassiumLimit * 0.3;

    final double phosphorusTarget = remainingPhosphorus > 0
        ? remainingPhosphorus
        : mealPhosphorusLimit * 0.3;

    if (potassium <= potassiumTarget) {
      score += 5;
    } else {
      return 0;
    }

    if (phosphorus <= phosphorusTarget) {
      score += 5;
    } else {
      return 0;
    }

    if (proteinStatus == 'Deficient') {
      if (protein > 0 && protein <= proteinTarget) {
        score += 4;
      } else if (protein > proteinTarget) {
        score += 1;
      }
    } else if (proteinStatus == 'Excessive') {
      if (protein <= proteinTarget) {
        score += 4;
      } else {
        return 0;
      }
    } else {
      if (protein <= mealProteinLimit) {
        score += 2;
      }
    }

    return score;
  }

  bool isSuitableFood(Map<String, dynamic> food) {
    return calculateFoodScore(food) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final loggedFoodNames = getLoggedFoodNames();
    final automaticAdvice = getAutomaticMealAdvice();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 218, 245, 226),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Meal Suggestions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getFoodsFromFirestore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading data:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data found.'));
          }

          final foods = snapshot.data!;

          final allFoods = foods.where((food) {
            final name = getDisplayName(food).toLowerCase().trim();
            return !loggedFoodNames.contains(name);
          }).toList();

          final suitableFoods = allFoods.where(isSuitableFood).toList();

          suitableFoods.sort((a, b) {
            return calculateFoodScore(b).compareTo(calculateFoodScore(a));
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Meal Modification Suggestions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 35, 63, 45),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'These suggestions are generated based on your current meal condition and food category.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              automaticAdviceCard(automaticAdvice),

              const SizedBox(height: 22),

              const Text(
                'Better Food Suggestions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 35, 63, 45),
                ),
              ),

              const SizedBox(height: 12),

              if (suitableFoods.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: Text(
                      'No suitable food found based on your meal condition.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...suitableFoods.take(5).map((food) {
                  return alternativeFoodCard(food);
                }),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget simpleCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 242, 255, 236),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade800),
      ),
      child: child,
    );
  }

  Widget automaticAdviceCard(List<String> adviceList) {
    return simpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General Advice for This Meal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 35, 63, 45),
            ),
          ),

          const SizedBox(height: 10),

          ...adviceList.map((advice) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 19,
                    color: Color.fromARGB(255, 35, 63, 45),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(advice, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget alternativeFoodCard(Map<String, dynamic> food) {
    final String name = getDisplayName(food);
    final double calories = getCalories(food);
    final double protein = getProtein(food);
    final double potassium = getPotassium(food);
    final double phosphorus = getPhosphorus(food);

    return simpleCard(
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 210, 235, 202),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant,
              size: 36,
              color: Color.fromARGB(255, 35, 63, 45),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 35, 63, 45),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${calories.toStringAsFixed(0)} kcal',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 3),

                Text(
                  'Protein: ${protein.toStringAsFixed(1)}g',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 3),

                Text(
                  'Potassium: ${potassium.toStringAsFixed(0)}mg',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 3),

                Text(
                  'Phosphorus: ${phosphorus.toStringAsFixed(0)}mg',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
