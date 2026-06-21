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
        'Makanan Tidak Diketahui';
  }

  String getCategory(Map<String, dynamic> food) {
    return food['category']?.toString() ?? '';
  }

  double getCalories(Map<String, dynamic> food) {
    return toDouble(food['calories']);
  }

  double getProtein(Map<String, dynamic> food) {
    return toDouble(food['protein']);
  }

  double getPotassium(Map<String, dynamic> food) {
    return toDouble(food['potassium']);
  }

  double getPhosphorus(Map<String, dynamic> food) {
    return toDouble(food['phosphate']);
  }

  bool isStatusHigh(String status) {
    final text = status.toLowerCase();
    return text.contains('exceeded') ||
        text.contains('excessive') ||
        text.contains('melebihi');
  }

  bool isStatusLow(String status) {
    final text = status.toLowerCase();
    return text.contains('deficient') ||
        text.contains('kurang') ||
        text.contains('rendah');
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

    if (isStatusHigh(potassiumStatus)) {
      advice.add('Kurangkan makanan yang tinggi kalium dalam hidangan ini.');
      advice.add(
        'Pilih buah yang lebih rendah kalium seperti epal, anggur, nanas, betik atau tembikai.',
      );
      advice.add(
        'Rebus sayur terlebih dahulu dan buang air rebusan sebelum dimasak.',
      );
      advice.add(
        'Elakkan minum sup atau kuah rebusan sayur kerana kalium boleh larut ke dalam air rebusan.',
      );
    }

    if (isStatusHigh(phosphorusStatus)) {
      advice.add(
        'Kurangkan makanan tinggi fosforus seperti organ dalaman, daging proses, kekacang dan hidangan daging dalam jumlah besar.',
      );
      advice.add(
        'Pilih makanan segar berbanding makanan proses atau makanan berbungkus.',
      );
      advice.add(
        'Hadkan keju proses, minuman berkola dan makanan yang mengandungi bahan tambahan fosfat.',
      );
      advice.add(
        'Ikuti nasihat doktor atau pakar diet tentang penggunaan ubat pengikat fosfat.',
      );
    }

    if (isStatusHigh(proteinStatus)) {
      advice.add(
        'Kurangkan saiz hidangan daging, ayam, ikan, telur atau makanan laut.',
      );
      advice.add(
        'Elakkan mengambil terlalu banyak sumber protein dalam satu hidangan.',
      );
      advice.add(
        'Gantikan sebahagian protein dengan nasi atau sayur rendah kalium yang sesuai.',
      );
    }

    if (isStatusLow(proteinStatus)) {
      advice.add(
        'Ambil sumber protein berkualiti seperti ayam, ikan atau telur dalam jumlah yang sesuai.',
      );
      advice.add(
        'Bahagikan pengambilan protein secara seimbang sepanjang hari.',
      );
      advice.add(
        'Pilih sumber protein yang disarankan oleh doktor atau pakar diet anda.',
      );
    }

    for (final food in loggedFoods) {
      final category = getCategory(food);

      if (category == 'Hidangan Ayam') {
        advice.add(
          'Untuk hidangan ayam, buang kulit yang kelihatan dan kurangkan salutan goreng.',
        );
        advice.add(
          'Pilih ayam panggang, kukus atau rebus berbanding ayam goreng.',
        );
        advice.add('Kurangkan kuah pekat, kari atau sos berlemak.');
      }

      if (category == 'Hidangan Daging' ||
          category == 'Hidangan Daging Merah') {
        advice.add(
          'Untuk hidangan daging merah, kurangkan saiz hidangan dan pilih bahagian daging yang kurang lemak.',
        );
        advice.add(
          'Elakkan mengambil daging merah dalam jumlah besar dengan kerap.',
        );
        advice.add('Hadkan kuah kari pekat, rendang atau sos yang masin.');
      }

      if (category == 'Ikan dan Makanan Laut') {
        advice.add(
          'Pilih ikan atau makanan laut segar berbanding makanan laut masin atau proses.',
        );
        advice.add('Hadkan makanan masin seperti ikan masin dan budu.');
        advice.add(
          'Kawal saiz hidangan makanan laut untuk mengurus pengambilan protein dan fosforus.',
        );
      }

      if (category == 'Sayur-sayuran') {
        advice.add(
          'Rebus sayur terlebih dahulu dan buang air rebusan sebelum dimasak.',
        );
        advice.add(
          'Elakkan menggunakan air rebusan sayur dalam sup atau kuah.',
        );
        advice.add(
          'Pilih sayur yang lebih rendah kalium jika pengambilan kalium anda tinggi.',
        );
      }

      if (category == 'Buah-buahan') {
        advice.add('Kawal saiz hidangan buah-buahan.');
        advice.add(
          'Pilih buah yang lebih rendah kalium jika tahap kalium anda tinggi.',
        );
        advice.add('Hadkan buah tinggi kalium seperti pisang.');
      }

      if (category == 'Mi dan Pasta') {
        advice.add('Kurangkan pengambilan kuah sup atau kuah kari.');
        advice.add(
          'Hadkan bahan proses seperti bebola ikan, sosej atau daging proses.',
        );
        advice.add(
          'Pilih saiz hidangan mi yang lebih kecil dan seimbangkan dengan sayur yang sesuai.',
        );
      }

      if (category == 'Hidangan Nasi') {
        advice.add('Kawal saiz hidangan nasi mengikut pelan pemakanan anda.');
        advice.add(
          'Kurangkan lauk yang terlalu masin atau berminyak bersama nasi.',
        );
        advice.add(
          'Pilih nasi putih berbanding nasi berminyak dengan lebih kerap.',
        );
      }

      if (category == 'Snek dan Makanan Bergoreng') {
        advice.add(
          'Hadkan snek bergoreng kerana biasanya tinggi kalori dan lemak.',
        );
        advice.add('Pilih pilihan kukus, rebus atau bakar dengan lebih kerap.');
        advice.add('Ambil makanan bergoreng dalam saiz hidangan yang kecil.');
      }

      if (category == 'Kekacang dan Legum') {
        advice.add(
          'Hadkan kekacang seperti dhal, lentil, kacang kuda dan kacang jika kalium atau fosforus tinggi.',
        );
        advice.add(
          'Ambil kekacang dalam jumlah kecil dan seimbangkan dengan makanan rendah kalium.',
        );
      }

      if (category == 'Minuman dan Bahan Minuman') {
        advice.add(
          'Hadkan serbuk minuman segera dan minuman yang terlalu diproses.',
        );
        advice.add('Pilih air kosong mengikut had cecair yang disarankan.');
      }
    }

    if (advice.isEmpty) {
      advice.add('Pilih makanan segar dan masakan di rumah jika boleh.');
      advice.add('Kawal saiz hidangan dan elakkan makan secara berlebihan.');
      advice.add('Hadkan makanan proses, masin dan bergoreng.');
      advice.add(
        'Ikuti nasihat pemakanan yang diberikan oleh pakar diet anda.',
      );
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

    if (isStatusLow(proteinStatus)) {
      if (protein > 0 && protein <= proteinTarget) {
        score += 4;
      } else if (protein > proteinTarget) {
        score += 1;
      }
    } else if (isStatusHigh(proteinStatus)) {
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
          'Cadangan Makanan',
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
                'Ralat semasa memuatkan data:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Tiada data dijumpai.'));
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
                'Cadangan Penambahbaikan Hidangan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 35, 63, 45),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Cadangan ini dijana berdasarkan keadaan hidangan semasa dan kategori makanan yang dipilih.',
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
                'Cadangan Makanan yang Lebih Sesuai',
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
                      'Tiada makanan yang sesuai dijumpai berdasarkan keadaan hidangan anda.',
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
            'Nasihat Umum untuk Hidangan Ini',
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
    final double servingSize = toDouble(food['servingSize']);
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
                  'Saiz hidangan: ${servingSize.toStringAsFixed(0)}g',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color.fromARGB(255, 21, 43, 36),
                  ),
                ),

                Text(
                  'Kalori: ${calories.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color.fromARGB(255, 21, 43, 36),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Protein: ${protein.toStringAsFixed(1)}g',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color.fromARGB(255, 21, 43, 36),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Kalium: ${potassium.toStringAsFixed(0)}mg',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color.fromARGB(255, 21, 43, 36),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Fosfat: ${phosphorus.toStringAsFixed(0)}mg',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color.fromARGB(255, 21, 43, 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
