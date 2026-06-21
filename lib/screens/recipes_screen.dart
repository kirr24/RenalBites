import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'editrecipe_screen.dart';
import 'viewrecipe_screen.dart';
import 'addrecipes_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchText = "";

  void goToAddRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );
  }

  Future<void> deleteRecipe(String recipeId) async {
    await FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .delete();
  }

  Widget smallButton({required String text, required VoidCallback onTap}) {
    return Expanded(
      child: SizedBox(
        height: 28,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 35, 63, 45),
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget recipeCard({
    required String recipeId,
    required Map<String, dynamic> recipe,
  }) {
    final recipeName = recipe['recipeName']?.toString() ?? 'Resipi Tanpa Tajuk';
    final photoUrl = recipe['photoUrl']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 90,
              height: 90,
              color: const Color.fromARGB(255, 218, 245, 226),
              child: photoUrl.isEmpty
                  ? const Icon(
                      Icons.restaurant_menu,
                      size: 40,
                      color: Color.fromARGB(255, 35, 63, 45),
                    )
                  : Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: Color.fromARGB(255, 35, 63, 45),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 35, 63, 45),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    smallButton(
                      text: "Lihat",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ViewRecipeScreen(recipe: recipe),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    smallButton(
                      text: "Edit",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditRecipeScreen(
                              recipeId: recipeId,
                              recipe: recipe,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    smallButton(
                      text: "Padam",
                      onTap: () {
                        deleteRecipe(recipeId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterRecipes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (searchText.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data();
      final name = data['recipeName']?.toString().toLowerCase() ?? '';
      return name.contains(searchText.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 218, 245, 226),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Resipi",
          style: TextStyle(
            color: Color.fromARGB(255, 251, 251, 251),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: goToAddRecipe,
        backgroundColor: const Color.fromARGB(255, 35, 63, 45),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Resipi lazat untuk membantu anda mendapatkan idea hidangan!",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: "Cari resipi...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.green.shade100),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.green.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 35, 63, 45),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Resipi tidak dapat dimuatkan."),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 50,
                          color: Color.fromARGB(255, 35, 63, 45),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Tiada resipi lagi.\nTekan + untuk tambah resipi pertama anda.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final recipes = filterRecipes(snapshot.data!.docs);

                if (recipes.isEmpty) {
                  return const Center(
                    child: Text("Tiada resipi yang sepadan dijumpai."),
                  );
                }

                return Column(
                  children: recipes.map((doc) {
                    return recipeCard(recipeId: doc.id, recipe: doc.data());
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
