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

  Future<List<Map<String, dynamic>>> getMealModifications() async {
    final loggedFoodNames = getLoggedFoodNames();

    final snapshot = await FirebaseFirestore.instance
        .collection('meal_modifications')
        .get();

    final List<Map<String, dynamic>> matchedModifications = [];

    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());

      final String foodName =
          data['foodName']?.toString().toLowerCase().trim() ?? '';

      final List keywords = data['keywords'] is List ? data['keywords'] : [];

      final bool matchFoodName = loggedFoodNames.contains(foodName);

      final bool matchKeyword = keywords.any((keyword) {
        final key = keyword.toString().toLowerCase().trim();
        return loggedFoodNames.contains(key);
      });

      if (matchFoodName || matchKeyword) {
        data['docId'] = doc.id;
        matchedModifications.add(data);
      }
    }

    return matchedModifications;
  }

  Future<Map<String, dynamic>> loadData() async {
    final foods = await getFoodsFromFirestore();
    final modifications = await getMealModifications();

    return {'foods': foods, 'modifications': modifications};
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

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 218, 245, 226),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Meal Suggestions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadData(),
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

          final List<Map<String, dynamic>> foods =
              List<Map<String, dynamic>>.from(snapshot.data!['foods']);

          final List<Map<String, dynamic>> modifications =
              List<Map<String, dynamic>>.from(snapshot.data!['modifications']);

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
                'These suggestions show how you can modify your current meal instead of fully avoiding it.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              if (modifications.isEmpty)
                simpleCard(
                  child: const Text(
                    'No meal modification advice found for this food.',
                  ),
                )
              else
                ...modifications.map((modification) {
                  return mealModificationCard(modification);
                }),

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

  Widget mealModificationCard(Map<String, dynamic> data) {
    final String foodName = data['foodName']?.toString() ?? 'Meal';
    final String generalAdvice = data['generalAdvice']?.toString() ?? '';
    final String betterVersion = data['betterVersion']?.toString() ?? '';

    final List modifications = data['modifications'] is List
        ? data['modifications']
        : [];

    return simpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            foodName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 35, 63, 45),
            ),
          ),

          if (generalAdvice.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              generalAdvice,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ],

          const SizedBox(height: 12),

          ...modifications.map((item) {
            final map = Map<String, dynamic>.from(item as Map);

            final String ingredient =
                map['ingredient']?.toString() ?? 'Ingredient';
            final String action = map['action']?.toString() ?? '';
            final String reason = map['reason']?.toString() ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    size: 20,
                    color: Color.fromARGB(255, 35, 63, 45),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$action $ingredient\nReason: $reason',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (betterVersion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Better version:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Text(betterVersion, style: const TextStyle(fontSize: 13)),
          ],
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
