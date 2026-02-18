import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/custom_nav_bar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CustomBottomNavBar(),
    );
  }
}
