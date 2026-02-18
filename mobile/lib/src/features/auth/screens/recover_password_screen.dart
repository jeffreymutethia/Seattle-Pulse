import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/core/routes/names.dart';
import 'package:seattle_pulse_mobile/src/core/utils/validators.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_input_field.dart';
import 'package:seattle_pulse_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/verify_reset_otp_screen.dart';

class RecoverPasswordPage extends ConsumerStatefulWidget {
  const RecoverPasswordPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RecoverPasswordPage> createState() =>
      _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends ConsumerState<RecoverPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Helper: Show a top snack bar notification for errors
  void showTopSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: AppColor.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColor.error,
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void initState() {
    super.initState();
    // Delay clearing error and listen for changes after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).clearError();
      ref.listen(authNotifierProvider, (previous, next) {
        if (next.error != null && next.error!.isNotEmpty) {
          showTopSnackBar(context, next.error!);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
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
            height: 430,
            width: double.infinity,
            padding: EdgeInsets.all(25),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Recover Password",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: AppColor.color0C1024,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Enter your email below to recover your\npassword",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: AppColor.color707988,
                    ),
                  ),
                  SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Email",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: AppColor.color0C1024,
                        ),
                      ),
                      SizedBox(height: 8),
                      AppInputField(
                        controller: _emailController,
                        hintText: "example@email.com",
                        labelText: "example@email.com",
                        borderRadius: 24,
                        borderColor: AppColor.color838B98,
                        focusedBorderColor: AppColor.color838B98,
                        margin: EdgeInsets.zero,
                        validator: Validators.validateEmail,
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  AppButton(
                    text: "Send OTP",
                    
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await authNotifier
                            .requestPasswordReset(_emailController.text.trim());
                        // After API call, if no error, navigate to OTP screen.
                        if (ref.read(authNotifierProvider).error == null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerifyResetOtpPage(
                                email: _emailController.text.trim(),
                              ),
                            ),
                          );
                        }
                      } else {
                        showTopSnackBar(context, "Please enter a valid email.");
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
                          "Remembered your password?",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: AppColor.color0C1024,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, RoutesName.login);
                          },
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
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
}
