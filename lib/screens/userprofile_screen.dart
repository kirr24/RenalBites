import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserprofileScreen extends StatefulWidget {
  const UserprofileScreen({super.key});

  @override
  State<UserprofileScreen> createState() => _UserprofileScreenState();
}

class _UserprofileScreenState extends State<UserprofileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>?> getUserData() async {
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) return doc.data();

    return null;
  }

  Widget buildSectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget infoRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[800]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 224, 247, 233),

      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Color.fromARGB(255, 251, 251, 251),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),

      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No data found"));
          }

          final data = snapshot.data!;
          final photoUrl = data['photoUrl'] ?? "";

          return SingleChildScrollView(
            child: Column(
              children: [
                // ===== HEADER =====
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 13, 89, 86),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: photoUrl != ""
                            ? NetworkImage(photoUrl)
                            : const NetworkImage(
                                'https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg',
                              ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.email ?? "No Email",
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "@${data['userId'] ?? 'N/A'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== BASIC INFO =====
                buildSectionCard(
                  child: Column(
                    children: [
                      infoRow(
                        "Full Name",
                        data['fullName'] ?? "N/A",
                        Icons.person,
                      ),
                      const Divider(),

                      infoRow(
                        "Age",
                        "${data['age'] ?? "N/A"} years",
                        Icons.cake,
                      ),
                      const Divider(),

                      infoRow("Gender", data['gender'] ?? "N/A", Icons.wc),
                    ],
                  ),
                ),

                // ===== BODY INFO =====
                buildSectionCard(
                  child: Column(
                    children: [
                      infoRow(
                        "Height",
                        "${data['height'] ?? "N/A"} cm",
                        Icons.height,
                      ),
                      const Divider(),

                      infoRow(
                        "Weight",
                        "${data['weight'] ?? "N/A"} kg",
                        Icons.monitor_weight,
                      ),
                    ],
                  ),
                ),

                // ===== MEDICAL INFO =====
                buildSectionCard(
                  child: Column(
                    children: [
                      infoRow(
                        "Disease",
                        data['typeOfDisease'] ?? "N/A",
                        Icons.medical_services,
                      ),
                      const Divider(),

                      infoRow(
                        "Stage",
                        data['stage'] ?? "N/A",
                        Icons.local_hospital,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
