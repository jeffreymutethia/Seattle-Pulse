import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/features/auth/providers/auth_provider.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  final String? email;
  final int? userId;
  const VerifyEmailPage({Key? key, this.email, this.userId}) : super(key: key);

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  Timer? _timer;
  int _secondsRemaining = 90; // Changed to 90 seconds as per API documentation
  bool _isResendDisabled = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _isResendDisabled = true;
      _secondsRemaining = 90;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _isResendDisabled = false;
          timer.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _resendEmail() async {
    if (widget.userId != null) {
      // If we have a userId, use the OTP resend method
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final success = await authNotifier.resendOtp(widget.userId!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _startTimer();
      } else {
        final error = ref.read(authNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to resend OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (widget.email != null) {
      // Fall back to email verification if no userId
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.resendVerificationEmail(widget.email!);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            height: 380,
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 0),
                Text(
                  "Verify Your Email",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: AppColor.color0C1024,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "To start using our platform, confirm your email address by clicking the link we have sent you by email to:",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: AppColor.color707988,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  widget.email ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    color: AppColor.color0C1024,
                  ),
                ),
                const SizedBox(height: 30),
                AppButton(
                  text: _isResendDisabled
                      ? "Resend Email ($_secondsRemaining)"
                      : "Resend Email",
                  onPressed: _isResendDisabled ? () {} : _resendEmail,
                  isLoading: authState.isLoading,
                  isFullWidth: true,
                  borderRadius: 24,
                  width: 50,
                  fontSize: 16,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Need Help?",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: AppColor.color0C1024,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Handle contacting customer support.
                        },
                        child: Text(
                          "Contact our Customer Support",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            fontSize: 16,
                            color: AppColor.color4C68D5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
