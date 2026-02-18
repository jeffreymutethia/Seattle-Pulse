/// unfollow_dialog.dart
import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/constants/constants.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';

Future<bool?> showDeleteAccountDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Delete Account",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xff2D323A),
          ),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "Select Reason",
                  style: TextStyle(
                    color: AppColor.color4B5669,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.2, // Adjust the scale factor as needed
                        child: Radio(
                          value: 0,
                          groupValue: 0,
                          onChanged: (value) {},
                          activeColor: AppColor.black,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "I don’t want to use Seattle Pulse",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColor.color4B5669,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.2, // Adjust the scale factor as needed
                        child: Radio(
                          value: 1,
                          groupValue: 0,
                          onChanged: (value) {},
                        ),
                      ),
                      Expanded(
                        child: Text(
                          overflow: TextOverflow.ellipsis,
                          "I have another account",
                          style: TextStyle(color: AppColor.color4B5669),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.2, // Adjust the scale factor as needed
                        child: Radio(
                          value: 2,
                          groupValue: 0,
                          onChanged: (value) {},
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "This website has some problems",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColor.color4B5669,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.2, // Adjust the scale factor as needed
                        child: Radio(
                          value: 3,
                          groupValue: 0,
                          onChanged: (value) {},
                        ),
                      ),
                      Text(
                        "Other",
                        style: TextStyle(color: AppColor.color4B5669),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Anything else you want to add",
                  style: TextStyle(
                    color: AppColor.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColor.colorABB0B9,
                    ),
                  ),
                  child: TextField(
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Write/suggest something to improve our app",
                      hintStyle: TextStyle(
                        color: AppColor.color707988,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "*All your data will be deleted permanently from our server. This action is irreversible.",
                  style: TextStyle(
                    color: AppColor.colorB81616,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppButton(
                backgroundColor: const Color(0xffB81616),
                borderRadius: 32,
                isFullWidth: true,
                text: "Delete my Account",
                onPressed: () {},
              ),
              const SizedBox(height: 10),
              AppButton(
                isFullWidth: true,
                borderRadius: 32,
                buttonType: ButtonType.secondary,
                text: "Cancel",
                onPressed: () {
                  Navigator.pop(context, true);
                },
              )
            ],
          )
        ],
      );
    },
  );
}
