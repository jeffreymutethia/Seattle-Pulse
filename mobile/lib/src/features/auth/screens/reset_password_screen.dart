import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_input_field.dart';
import 'package:seattle_pulse_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:seattle_pulse_mobile/src/core/routes/routes.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordPage({Key? key, required this.token}) : super(key: key);

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  // Helper: Show a top snack bar notification for errors
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

  @override
  void initState() {
    super.initState();
    // Clear any previous error after the widget is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).clearError();
    });
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
            height: 530,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Text(
                    "Reset your password",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: AppColor.color0C1024,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Create a new password to be able to\nlogin",
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
                        "Create New Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: AppColor.color0C1024,
                        ),
                      ),
                      SizedBox(height: 8),
                      AppInputField(
                        controller: _newPasswordController,
                        hintText: "",
                        labelText: "",
                        isPasswordField: true,
                        obscureText: true,
                        suffixIcon: Icon(Icons.remove_red_eye),
                        borderRadius: 24,
                        borderColor: AppColor.color838B98,
                        focusedBorderColor: AppColor.color838B98,
                        margin: EdgeInsets.zero,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "New password is required";
                          }
                          if (value.trim().length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Confirm Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: AppColor.color0C1024,
                        ),
                      ),
                      SizedBox(height: 8),
                      AppInputField(
                        controller: _confirmPasswordController,
                        hintText: "",
                        labelText: "",
                        isPasswordField: true,
                        obscureText: true,
                        suffixIcon: Icon(Icons.remove_red_eye),
                        borderRadius: 24,
                        borderColor: AppColor.color838B98,
                        focusedBorderColor: AppColor.color838B98,
                        margin: EdgeInsets.zero,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please confirm your password";
                          } else if (value.trim() !=
                              _newPasswordController.text.trim()) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  AppButton(
                    text: "Reset",
                    onPressed: () async {
                      setState(() {
                        _submitted = true;
                      });
                      if (_formKey.currentState!.validate()) {
                        await authNotifier.resetPassword(
                          token: widget.token,
                          password: _newPasswordController.text.trim(),
                          confirmPassword:
                              _confirmPasswordController.text.trim(),
                        );
                        if (ref.read(authNotifierProvider).error == null) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, RoutesName.login, (route) => false);
                        } else {
                          showTopSnackBar(
                              context, authState.error ?? "Reset failed");
                        }
                      } else {
                        showTopSnackBar(
                            context, "Please fix the errors in the form.");
                      }
                    },
                    isLoading: authState.isLoading,
                    backgroundColor: authState.isLoading
                        ? AppColor.disabled
                        : AppColor.black,
                    isFullWidth: true,
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
