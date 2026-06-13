import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';

const Color bg = Color.fromARGB(255, 50, 160, 125);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController kidneyController;

  bool showMainScreen = false;
  bool showTitle = false;

  @override
  void initState() {
    super.initState();

    kidneyController = AnimationController(vsync: this);

    kidneyController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        kidneyController.stop();

        setState(() {
          showMainScreen = true;
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              showTitle = true;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    kidneyController.dispose();
    super.dispose();
  }

  void goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(showRegisterScreen: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            height: showMainScreen ? screenHeight / 1.9 : screenHeight,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 241, 242, 244),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(showMainScreen ? 40 : 0),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showMainScreen == false)
                  Lottie.asset(
                    'assets/animations/kidney.json',
                    width: 500,
                    height: 500,
                    fit: BoxFit.contain,
                    controller: kidneyController,
                    onLoaded: (composition) {
                      kidneyController
                        ..duration = composition.duration
                        ..forward();
                    },
                  ),

                if (showMainScreen == true)
                  Image.asset(
                    'assets/images/kidneymain.png',
                    height: 220,
                    width: 220,
                  ),

                Center(
                  child: AnimatedOpacity(
                    opacity: showTitle ? 1 : 0,
                    duration: const Duration(seconds: 1),
                    child: const Text(
                      'RenalBites',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 13, 44, 21),
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (showMainScreen == true)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Take Control of Your Kidney Health',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 7, 50, 42),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      'Track nutrients, discover kidney-friendly meals, '
                      'and manage your renal diet with confidence and ease.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(
                          255,
                          7,
                          50,
                          42,
                        ).withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 50),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: goToLogin,
                        child: Container(
                          height: 85,
                          width: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_up,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
