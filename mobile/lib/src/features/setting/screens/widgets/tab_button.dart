import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';

class TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;

  const TabButton({required this.title, required this.isSelected, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : AppColor.colorECF0F5,
        borderRadius: BorderRadius.circular(46),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
