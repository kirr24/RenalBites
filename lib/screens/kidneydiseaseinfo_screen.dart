import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class KidneyDiseaseInfoScreen extends StatefulWidget {
  const KidneyDiseaseInfoScreen({super.key});

  @override
  State<KidneyDiseaseInfoScreen> createState() =>
      _KidneyDiseaseInfoScreenState();
}

class _KidneyDiseaseInfoScreenState extends State<KidneyDiseaseInfoScreen> {
  String searchText = "";

  Future<void> openWebsite(String link) async {
    final Uri url = Uri.parse(link);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Tidak dapat membuka $link");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF7E8),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Informasi",
          style: TextStyle(
            color: Color.fromARGB(255, 251, 251, 251),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sumber maklumat berguna untuk mempelajari tentang penyakit buah pinggang",
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: Color.fromARGB(221, 6, 50, 40),
                height: 1.2,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Cari topik...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color.fromARGB(221, 10, 29, 28),
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 188, 235, 208),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(221, 9, 47, 35),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('kidneyDiseaseInfo')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Ralat Firestore:\n${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final documents = snapshot.data?.docs ?? [];

                  if (documents.isEmpty) {
                    return const Center(
                      child: Text("Tiada maklumat dijumpai."),
                    );
                  }

                  final filteredDocs = documents.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final title = data['title']?.toString().toLowerCase() ?? '';
                    final source =
                        data['source']?.toString().toLowerCase() ?? '';

                    return title.contains(searchText) ||
                        source.contains(searchText);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text("Tiada topik yang sepadan dijumpai."),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          filteredDocs[index].data() as Map<String, dynamic>;

                      final String title =
                          data['title']?.toString() ?? 'Tiada tajuk';
                      final String source =
                          data['source']?.toString() ?? 'Tiada sumber';

                      final String imageUrl =
                          data['imageUrl']?.toString() ??
                          data['imageurl']?.toString() ??
                          '';

                      final String link = data['link']?.toString() ?? '';

                      return InkWell(
                        onTap: () {
                          if (link.isNotEmpty) {
                            openWebsite(link);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 22),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 116, 157, 126),
                            border: Border.all(
                              color: const Color.fromARGB(221, 0, 99, 74),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 105,
                                height: 85,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black87),
                                  color: Colors.white,
                                ),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }

                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                              );
                                            },
                                      )
                                    : const Icon(Icons.image, size: 40),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w500,
                                        color: Color.fromARGB(255, 7, 50, 28),
                                        height: 1.1,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.copy,
                                          size: 18,
                                          color: Color.fromARGB(
                                            255,
                                            28,
                                            56,
                                            121,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            source,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color.fromARGB(
                                                255,
                                                22,
                                                54,
                                                61,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
