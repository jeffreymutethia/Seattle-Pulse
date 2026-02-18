library route_pages;

import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/screens/add_story_screen.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/join_screen.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/login_screen.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/recover_password_screen.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/reset_password_screen.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/signup_screen.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/verify_email_page.dart';
import 'package:seattle_pulse_mobile/src/features/feed/screens/feed_screen.dart';
import 'package:seattle_pulse_mobile/src/features/notification/screens/notification_screen.dart';
import 'package:seattle_pulse_mobile/src/features/profile/screens/profile_screen.dart';
import 'package:seattle_pulse_mobile/src/features/setting/screens/setting_screen.dart';
import 'package:seattle_pulse_mobile/src/main_screen.dart';
import '../error/error.dart';
import 'routes.dart';

class AppRoute {
  static const initial = RoutesName.initial;

  static Route<dynamic> generate(RouteSettings? settings) {
    switch (settings?.name) {
      case RoutesName.initial:
        return MaterialPageRoute(builder: (_) => JoinPage());

      case RoutesName.login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(),
        );

      case RoutesName.signup:
        return MaterialPageRoute(
          builder: (_) => SignupPage(),
        );

      case RoutesName.recoverPassword:
        return MaterialPageRoute(
          builder: (_) => const RecoverPasswordPage(),
        );

      // case RoutesName.resetPassword:
      //   return MaterialPageRoute(
      //     builder: (_) => const ResetPasswordPage(),
      //   );

      case RoutesName.verifyEmail:
        return MaterialPageRoute(
          builder: (_) => VerifyEmailPage(),
        );

      case RoutesName.feed:
        return MaterialPageRoute(
          builder: (_) => const FeedScreen(),
        );

      // case RoutesName.profile:
      //   return MaterialPageRoute(
      //     builder: (_) => const ProfileScreen(),
      //   );

      case RoutesName.setting:
        return MaterialPageRoute(
          builder: (_) => const SettingScreen(),
        );

      case RoutesName.join:
        return MaterialPageRoute(builder: (_) => const JoinPage());

      case RoutesName.addStory:
        return MaterialPageRoute(
          builder: (_) => const AddStoryScreen(),
        );

      default:
        throw const RouteException('Route not found!');
    }
  }
}
