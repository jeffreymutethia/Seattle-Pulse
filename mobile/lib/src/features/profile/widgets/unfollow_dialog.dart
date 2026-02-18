/// unfollow_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/constants.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';

// Function to show unfollow confirmation dialog
Future<bool?> showUnfollowDialog(BuildContext context, String userName) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return UnfollowDialog(userName: userName);
    },
  );
}

// Stateful widget to handle loading state
class UnfollowDialog extends StatefulWidget {
  final String userName;

  const UnfollowDialog({Key? key, required this.userName}) : super(key: key);

  @override
  State<UnfollowDialog> createState() => _UnfollowDialogState();
}

class _UnfollowDialogState extends State<UnfollowDialog> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        "Unfollow ${widget.userName}?",
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xff2D323A),
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          "Are you sure you want to unfollow ${widget.userName}?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColor.color0C1024,
          ),
        ),
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : AppButton(
                    backgroundColor: const Color(0xffB81616),
                    borderRadius: 32,
                    isFullWidth: true,
                    text: "Unfollow",
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                      });
                      // Return true and close dialog after a small delay for better UX
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Navigator.pop(context, true);
                      });
                    },
                  ),
            const SizedBox(height: 10),
            if (!isLoading)
              AppButton(
                  isFullWidth: true,
                  borderRadius: 32,
                  buttonType: ButtonType.secondary,
                  text: "Cancel",
                  onPressed: () {
                    Navigator.pop(context, false);
                  }),
          ],
        ),
      ],
    );
  }
}
