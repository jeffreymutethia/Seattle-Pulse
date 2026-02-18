import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/core/routes/routes.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/features/auth/providers/auth_provider.dart';

class VerifyAccountOtpScreen extends ConsumerStatefulWidget {
  final int userId;
  final String email;

  const VerifyAccountOtpScreen({
    Key? key,
    required this.userId,
    required this.email,
  }) : super(key: key);

  @override
  ConsumerState<VerifyAccountOtpScreen> createState() =>
      _VerifyAccountOtpScreenState();
}

class _VerifyAccountOtpScreenState
    extends ConsumerState<VerifyAccountOtpScreen> {
  // Controllers for 6 digit OTP input
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  // Resend timer state
  Timer? _timer;
  int _secondsRemaining = 90; // 90 seconds cooldown as per API documentation
  bool _isResendDisabled = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Clear any previous error
    Future.microtask(() {
      ref.read(authNotifierProvider.notifier).clearError();
    });
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

  // Helper: Show a top snack bar notification
  void showTopSnackBar(BuildContext context, String message,
      {bool isSuccess = false}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isSuccess ? Colors.green : AppColor.error,
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).size.height * 0.88,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Combine the 6 digits into one OTP string
  String get _otp {
    return _otpControllers.map((controller) => controller.text.trim()).join();
  }

  // Resend OTP handler
  Future<void> _resendOtp() async {
    if (_isResendDisabled) return;

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success = await authNotifier.resendOtp(widget.userId);

    if (success) {
      showTopSnackBar(context, "OTP resent successfully", isSuccess: true);
      _startTimer(); // Restart the timer
    } else {
      final error = ref.read(authNotifierProvider).error;
      showTopSnackBar(context, error ?? "Failed to resend OTP");
    }
  }

  // Verify OTP handler
  Future<void> _verifyOtp() async {
    setState(() {
      _submitted = true;
    });

    if (_formKey.currentState!.validate() && _otp.length == 4) {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final success = await authNotifier.verifyAccountWithOtp(
        userId: widget.userId,
        otp: _otp,
      );

      if (success) {
        showTopSnackBar(context, "Account verified successfully",
            isSuccess: true);

        // Navigate to login screen after successful verification
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, RoutesName.login);
        });
      } else {
        final error = ref.read(authNotifierProvider).error;
        showTopSnackBar(context, error ?? "Verification failed");
      }
    } else {
      showTopSnackBar(context, "Please enter a valid 6-digit OTP");
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
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
            height: 420,
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Optional error widget
                  if (authState.error != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColor.error.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authState.error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  Text(
                    "Verify Your Account",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: AppColor.color0C1024,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Enter the 6-digit OTP sent to ${widget.email}",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: AppColor.color707988,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                      (index) => _buildOtpTextField(index, context),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Verify Button
                  AppButton(
                    text: "Verify OTP",
                    onPressed: authState.isLoading ? () {} : _verifyOtp,
                    isLoading: authState.isLoading,
                    isFullWidth: true,
                    backgroundColor: authState.isLoading
                        ? AppColor.disabled
                        : AppColor.black,
                    borderRadius: 24,
                    width: 50,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 20),

                  // Resend OTP button with timer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Didn't receive OTP?",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: AppColor.color0C1024,
                          ),
                        ),
                        TextButton(
                          onPressed: _isResendDisabled ? () {} : _resendOtp,
                          style: TextButton.styleFrom(
                            foregroundColor: _isResendDisabled
                                ? AppColor.color707988
                                : AppColor.color4C68D5,
                          ),
                          child: Text(
                            _isResendDisabled
                                ? "Resend OTP in $_secondsRemaining seconds"
                                : "Resend OTP",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build a single OTP digit TextField
  Widget _buildOtpTextField(int index, BuildContext context) {
    return SizedBox(
      width: 40,
      height: 60,
      child: TextFormField(
        controller: _otpControllers[index],
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: TextStyle(fontSize: 24, color: AppColor.color0C1024),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          errorStyle: const TextStyle(height: 0), // Hide error text
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "";
          }
          return null;
        },
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            // Automatically move to next field
            FocusScope.of(context).nextFocus();
          }

          // If user pastes a 6-digit code
          if (value.length > 1 && value.length <= 6) {
            final pastedValue = value.substring(0, 6);

            // Distribute the pasted digits to all controllers
            for (int i = 0; i < 6; i++) {
              if (i < pastedValue.length) {
                _otpControllers[i].text = pastedValue[i];
              }
            }

            // Move focus to the last field
            if (index < 5) {
              FocusScope.of(context).nextFocus();
            }
          }
        },
      ),
    );
  }
}
