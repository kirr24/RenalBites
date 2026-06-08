import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  bool _isNavigating = false;

  Future<void> _onItemTapped(BuildContext context, int index) async {
    if (index == widget.currentIndex || _isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/report');
        break;

      case 1:
        Navigator.pushReplacementNamed(context, '/calendar');
        break;

      case 2:
        Navigator.pushReplacementNamed(context, '/home');
        break;

      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: widget.currentIndex,
      backgroundColor: const Color.fromARGB(255, 208, 250, 229),
      color: const Color.fromARGB(255, 15, 55, 38),
      animationDuration: const Duration(milliseconds: 180),
      onTap: (index) => _onItemTapped(context, index),
      items: [
        Image.asset('lib/icons/report.png', width: 40, height: 40),

        Image.asset('lib/icons/calendar.png', width: 40, height: 40),

        Image.asset('lib/icons/home.png', width: 40, height: 40),

        Image.asset('lib/icons/profile.png', width: 40, height: 40),
      ],
    );
  }
}
