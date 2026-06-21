import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  Uint8List? recipeImage;
  final ImagePicker picker = ImagePicker();

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

  Future<String> uploadRecipeImage() async {
    if (recipeImage == null) return "";

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = FirebaseStorage.instance
        .ref()
        .child("recipe_images")
        .child("$fileName.jpg");

    await ref.putData(recipeImage!);

    return await ref.getDownloadURL();
  }

  Future<void> pickRecipeImage(ImageSource source) async {
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    setState(() {
      recipeImage = bytes;
    });
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
          content: Text(
            "Sila isi nama resipi, bahan-bahan dan cara penyediaan",
          ),
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
        "photoUrl": await uploadRecipeImage(),
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      await recipeRef.set(recipeData);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Resipi berjaya disimpan")));

      Navigator.pop(context, recipeData);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ralat: $e")));
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
          "Tambah Resipi",
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
            labelText("Nama Resipi"),
            inputField(
              controller: recipeNameController,
              hint: "Masukkan nama resipi",
            ),

            const SizedBox(height: 16),

            numberedInputList(
              title: "Bahan-bahan",
              controllers: ingredientControllers,
              hint: "Tambah bahan",
              buttonText: "Tambah Bahan",
            ),

            const SizedBox(height: 8),

            numberedInputList(
              title: "Cara Penyediaan",
              controllers: directionControllers,
              hint: "Tambah langkah",
              buttonText: "Tambah Langkah",
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                nutrientInput("Kalori (kcal)", caloriesController),
                const SizedBox(width: 12),
                nutrientInput("Protein (g)", proteinController),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                nutrientInput("Fosfat (mg)", phosphateController),
                const SizedBox(width: 12),
                nutrientInput("Kalium (mg)", potassiumController),
              ],
            ),

            const SizedBox(height: 16),

            labelText("Gambar Resipi"),

            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: recipeImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(recipeImage!, fit: BoxFit.cover),
                    )
                  : const Center(child: Text("Tiada gambar dipilih")),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      pickRecipeImage(ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Kamera"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      pickRecipeImage(ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Galeri"),
                  ),
                ),
              ],
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
                        "Simpan Resipi",
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
