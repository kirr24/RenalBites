import 'package:flutter/material.dart';

class ViewRecipeScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const ViewRecipeScreen({super.key, required this.recipe});

  String formatNumber(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0.0;
    if (number == number.roundToDouble()) {
      return number.toStringAsFixed(0);
    }
    return number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final List ingredients = recipe['ingredients'] as List? ?? [];
    final List directions = recipe['directions'] as List? ?? [];
    final String photoUrl = recipe['photoUrl']?.toString() ?? "";
    final String recipeName =
        recipe['recipeName']?.toString() ?? "Recipe Details";

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 218, 245, 226),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          recipeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 220,
              width: double.infinity,
              color: Colors.white,
              child: photoUrl.isEmpty
                  ? const Icon(
                      Icons.restaurant_menu,
                      size: 70,
                      color: Color.fromARGB(255, 35, 63, 45),
                    )
                  : Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          size: 70,
                          color: Color.fromARGB(255, 35, 63, 45),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            recipeName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 35, 63, 45),
            ),
          ),

          const SizedBox(height: 18),

          sectionBox(
            title: "Ingredients",
            icon: Icons.shopping_basket_outlined,
            children: ingredients.isEmpty
                ? [simpleText("No ingredients added.")]
                : List.generate(
                    ingredients.length,
                    (index) =>
                        simpleText("${index + 1}. ${ingredients[index]}"),
                  ),
          ),

          const SizedBox(height: 16),

          sectionBox(
            title: "Directions",
            icon: Icons.menu_book_outlined,
            children: directions.isEmpty
                ? [simpleText("No directions added.")]
                : List.generate(
                    directions.length,
                    (index) =>
                        simpleText("Step ${index + 1}: ${directions[index]}"),
                  ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Nutritional Information",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 35, 63, 45),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              nutritionCard(
                "Calories",
                formatNumber(recipe['calories']),
                "kcal",
                Icons.local_fire_department,
              ),
              const SizedBox(width: 10),
              nutritionCard(
                "Protein",
                formatNumber(recipe['protein']),
                "g",
                Icons.fitness_center,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              nutritionCard(
                "Phosphate",
                formatNumber(recipe['phosphate']),
                "mg",
                Icons.science_outlined,
              ),
              const SizedBox(width: 10),
              nutritionCard(
                "Potassium",
                formatNumber(recipe['potassium']),
                "mg",
                Icons.bolt,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              nutritionCard(
                "Cholesterol",
                formatNumber(recipe['cholesterol']),
                "mg",
                Icons.favorite_border,
              ),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget sectionBox({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              Icon(icon, color: const Color.fromARGB(255, 35, 63, 45)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 35, 63, 45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget simpleText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.35,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget nutritionCard(String title, String value, String unit, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            Icon(icon, color: const Color.fromARGB(255, 35, 63, 45), size: 24),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
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
      ),
    );
  }
}
