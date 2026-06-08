import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';

const Color renalGreen = Color.fromARGB(255, 50, 160, 125);

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _kidneyController;

  bool kidneyAnimated = false;
  bool animateRenalText = false;

  @override
  void initState() {
    super.initState();

    _kidneyController = AnimationController(vsync: this);

    _kidneyController.addListener(() {
      if (_kidneyController.value == 1.0) {
        _kidneyController.stop();

        kidneyAnimated = true;
        setState(() {});

        Future.delayed(const Duration(seconds: 1), () {
          animateRenalText = true;
          setState(() {});
        });
      }
    });
  }

  @override
  void dispose() {
    _kidneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: renalGreen,

      body: Stack(
        children: [
          // TOP WHITE CONTAINER
          AnimatedContainer(
            duration: const Duration(seconds: 1),

            height: kidneyAnimated ? screenHeight / 1.9 : screenHeight,

            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 241, 242, 244),

              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(kidneyAnimated ? 40.0 : 0.0),
              ),
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                // LOTTIE KIDNEY ANIMATION
                Visibility(
                  visible: !kidneyAnimated,

                  child: Lottie.asset(
                    'assets/animations/kidney.json',

                    width: 500,
                    height: 500,
                    fit: BoxFit.contain,

                    controller: _kidneyController,

                    onLoaded: (composition) {
                      _kidneyController
                        ..duration = composition.duration
                        ..forward();
                    },
                  ),
                ),

                // STATIC KIDNEY IMAGE
                Visibility(
                  visible: kidneyAnimated,

                  child: Image.asset(
                    'assets/images/kidneymain.png',

                    height: 220,
                    width: 220,
                  ),
                ),

                // RENALBITES TEXT
                Center(
                  child: AnimatedOpacity(
                    opacity: animateRenalText ? 1 : 0,

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

          // BOTTOM PART
          Visibility(visible: kidneyAnimated, child: const _BottomPart()),
        ],
      ),
    );
  }
}

class _BottomPart extends StatelessWidget {
  const _BottomPart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Take Control of Your Kidney Health',

              textAlign: TextAlign.left,

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

              textAlign: TextAlign.left,

              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 7, 50, 42).withOpacity(0.8),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 50),

            Align(
              alignment: Alignment.centerRight,

              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) =>
                          LoginScreen(showRegisterScreen: () {}),
                    ),
                  );
                },

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
    );
  }
}
