import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/reset_password_screen.dart';

class VerifyResetOtpPage extends ConsumerStatefulWidget {
  final String email;
  const VerifyResetOtpPage({Key? key, required this.email}) : super(key: key);

  @override
  ConsumerState<VerifyResetOtpPage> createState() => _VerifyResetOtpPageState();
}

class _VerifyResetOtpPageState extends ConsumerState<VerifyResetOtpPage> {
  // Controllers for 4 digit input
  final _otpController1 = TextEditingController();
  final _otpController2 = TextEditingController();
  final _otpController3 = TextEditingController();
  final _otpController4 = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  // Helper: Show a top snack bar notification
  void showTopSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: AppColor.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColor.error,
      margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Combine the 4 digits into one OTP string.
  String get _otp {
    return _otpController1.text.trim() +
        _otpController2.text.trim() +
        _otpController3.text.trim() +
        _otpController4.text.trim();
  }

  @override
  void initState() {
    super.initState();
    // Clear any previous error after build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _otpController1.dispose();
    _otpController2.dispose();
    _otpController3.dispose();
    _otpController4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            height: 420,
            width: double.infinity,
            padding: EdgeInsets.all(25),
            margin: EdgeInsets.symmetric(horizontal: 20),
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
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColor.error.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authState.error!,
                        style: TextStyle(color: AppColor.white),
                      ),
                    ),
                  Text(
                    "Verify OTP",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: AppColor.color0C1024,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Enter the 4-digit OTP sent to ${widget.email}",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: AppColor.color707988,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOtpTextField(_otpController1, context),
                      _buildOtpTextField(_otpController2, context),
                      _buildOtpTextField(_otpController3, context),
                      _buildOtpTextField(_otpController4, context),
                    ],
                  ),
                  SizedBox(height: 20),
                  AppButton(
                    text: "Verify OTP",
                    onPressed: () async {
                      setState(() {
                        _submitted = true;
                      });
                      if (_formKey.currentState!.validate() &&
                          _otp.length == 4) {
                        final token = await authNotifier.verifyResetPasswordOtp(
                            widget.email, _otp);
                        if (token != null) {
                          // Navigate to Reset Password page, passing the token.
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ResetPasswordPage(token: token),
                            ),
                          );
                        } else {
                          showTopSnackBar(context,
                              authState.error ?? "OTP verification failed");
                        }
                      } else {
                        showTopSnackBar(
                            context, "Please enter a valid 4-digit OTP.");
                      }
                    },
                    isLoading: authState.isLoading,
                    isFullWidth: true,
                    backgroundColor: authState.isLoading
                        ? AppColor.disabled
                        : AppColor.black,
                    borderRadius: 24,
                    width: 50,
                    fontSize: 16,
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          onPressed: () {
                            // Optionally implement a resend mechanism here.
                          },
                          child: Text(
                            "Resend OTP",
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build a single OTP digit TextField.
  Widget _buildOtpTextField(
      TextEditingController controller, BuildContext context) {
    return SizedBox(
      width: 50,
      height: 80,
      child: TextFormField(
        controller: controller,
        autofocus: false,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: TextStyle(fontSize: 24, color: AppColor.color0C1024),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "";
          }
          return null;
        },
        onChanged: (value) {
          if (value.length == 1) {
            // Automatically move to next field if exists.
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }
}
