import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/constants.dart';
import 'package:seattle_pulse_mobile/src/core/routes/names.dart';
import 'package:seattle_pulse_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:seattle_pulse_mobile/src/features/messaging/screens/chat_screen.dart';
import 'package:seattle_pulse_mobile/src/features/messaging/screens/inbox_screen.dart';
import 'package:seattle_pulse_mobile/src/features/setting/screens/setting_screen.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showNotificationIcon;
  final VoidCallback? onNotificationPressed;
  final bool showMenuIcon;
  final List<PopupMenuEntry<String>> menuItems;
  final ValueChanged<String>? onMenuItemSelected;

  const CustomAppBar({
    Key? key,
    this.title = "Feed",
    this.showBackButton = true,
    this.showNotificationIcon = true,
    this.onNotificationPressed,
    this.showMenuIcon = true,
    this.menuItems = const [],
    this.onMenuItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return AppBar(
      elevation: 0,
      leading: showBackButton && Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: AppColor.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (showNotificationIcon)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InboxScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColor.colorE2E8F0, width: 2),
              ),
              child: Image.asset(
                'assets/icons/message.png',
                width: 24,
                height: 24,
              ),
            ),
          ),
        const SizedBox(width: 15),
        if (showMenuIcon)
          PopupMenuButton<String>(
            elevation: 0,
            menuPadding: const EdgeInsets.all(16),
            offset: const Offset(0, 5),
            popUpAnimationStyle: AnimationStyle(
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 300),
            ),
            position: PopupMenuPosition.under,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: AppColor.colorE2E8F0,
                  width: 1,
                )),
            onSelected: onMenuItemSelected ??
                (value) async {
                  if (value == "settings") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingScreen()),
                    );
                  } else if (value == "logout") {
                    try {
                      await authNotifier.logoutUser();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RoutesName.login,
                        (route) => false,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Logout failed: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "settings",
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icons/setting.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Settings",
                      style: TextStyle(
                        color: Color(0xFF0C1024),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "logout",
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icons/logout.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB81616),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColor.colorE2E8F0, width: 2),
              ),
              child: Image.asset(
                'assets/icons/menu.png',
                width: 24,
                height: 24,
              ),
            ),
          ),
        const SizedBox(width: 20),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
