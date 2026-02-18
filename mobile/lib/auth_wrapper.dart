import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/join_screen.dart';
import 'package:seattle_pulse_mobile/src/features/feed/screens/feed_screen.dart';
import 'package:seattle_pulse_mobile/src/main_screen.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // After the first frame, fetch current user status.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).fetchCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If authenticated, navigate to HomePage; otherwise, show LoginPage.
    if (authState.isLoggedIn) {
      return const MainScreen();
    }
    return const JoinPage();
  }
}
