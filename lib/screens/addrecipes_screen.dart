import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final recipeNameController = TextEditingController();
  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final phosphateController = TextEditingController();
  final potassiumController = TextEditingController();
  final cholesterolController = TextEditingController();
  final photoUrlController = TextEditingController();

  final List<TextEditingController> ingredientControllers = [
    TextEditingController(),
  ];

  final List<TextEditingController> directionControllers = [
    TextEditingController(),
  ];

  bool isSaving = false;

  @override
  void dispose() {
    recipeNameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    phosphateController.dispose();
    potassiumController.dispose();
    cholesterolController.dispose();
    photoUrlController.dispose();

    for (final controller in ingredientControllers) {
      controller.dispose();
    }

    for (final controller in directionControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  double toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0.0;
  }

  Future<void> saveRecipe() async {
    final recipeName = recipeNameController.text.trim();

    final ingredients = ingredientControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final directions = directionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (recipeName.isEmpty || ingredients.isEmpty || directions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill recipe name, ingredients and directions"),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final recipeRef = FirebaseFirestore.instance.collection('recipes').doc();

      final recipeData = {
        "recipeId": recipeRef.id,
        "recipeName": recipeName,
        "ingredients": ingredients,
        "directions": directions,
        "calories": toDouble(caloriesController.text),
        "protein": toDouble(proteinController.text),
        "phosphate": toDouble(phosphateController.text),
        "potassium": toDouble(potassiumController.text),
        "cholesterol": toDouble(cholesterolController.text),
        "photoUrl": photoUrlController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      await recipeRef.set(recipeData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe saved successfully")),
      );

      Navigator.pop(context, recipeData);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  Widget labelText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 35, 63, 45),
        ),
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.text
          ? []
          : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 35, 63, 45),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget numberedInputList({
    required String title,
    required List<TextEditingController> controllers,
    required String hint,
    required String buttonText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelText(title),

        ...controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Text(
                    "${index + 1}.",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 35, 63, 45),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: inputField(
                    controller: controller,
                    hint: hint,
                    maxLines: maxLines,
                  ),
                ),

                if (controllers.length > 1)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        controller.dispose();
                        controllers.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
              ],
            ),
          );
        }),

        TextButton.icon(
          onPressed: () {
            setState(() {
              controllers.add(TextEditingController());
            });
          },
          icon: const Icon(Icons.add, color: Color.fromARGB(255, 35, 63, 45)),
          label: Text(
            buttonText,
            style: const TextStyle(
              color: Color.fromARGB(255, 35, 63, 45),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget nutrientInput(String label, TextEditingController controller) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labelText(label),
          inputField(
            controller: controller,
            hint: "0.00",
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          "Add Recipe",
          style: TextStyle(
            color: Color.fromARGB(255, 251, 251, 251),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            labelText("Recipe Name"),
            inputField(controller: recipeNameController, hint: "Recipe name"),

            const SizedBox(height: 16),

            numberedInputList(
              title: "Ingredients",
              controllers: ingredientControllers,
              hint: "Add ingredient",
              buttonText: "Add Ingredient",
            ),

            const SizedBox(height: 8),

            numberedInputList(
              title: "Directions",
              controllers: directionControllers,
              hint: "Add step",
              buttonText: "Add Step",
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                nutrientInput("Calories (kcal)", caloriesController),
                const SizedBox(width: 12),
                nutrientInput("Protein (g)", proteinController),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                nutrientInput("Phosphate (mg)", phosphateController),
                const SizedBox(width: 12),
                nutrientInput("Potassium (mg)", potassiumController),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                nutrientInput("Cholesterol (mg)", cholesterolController),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),

            const SizedBox(height: 16),

            labelText("Photo URL"),
            inputField(
              controller: photoUrlController,
              hint: "Insert picture URL of food here",
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 35, 63, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Recipe",
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
      ),
    );
  }
}
