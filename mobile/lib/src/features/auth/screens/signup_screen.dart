import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/core/routes/routes.dart';
import 'package:seattle_pulse_mobile/src/core/utils/validators.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_input_field.dart';
import 'package:seattle_pulse_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/verify_account_otp_screen.dart';
import 'verify_email_page.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptedTerms = false;
  bool _submitted = false; // Controls when to show field validation errors
  final _formKey = GlobalKey<FormState>();

  void showTopSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: AppColor.white),
        textAlign: TextAlign.center,
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColor.error,
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authNotifierProvider.notifier).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final authState = ref.watch(authNotifierProvider);

    final isPasswordVisible = ref.watch(passwordVisibilityProvider);
    final isConfirmPasswordVisible =
        ref.watch(confirmPasswordVisibilityProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        showTopSnackBar(context, next.error!);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Image.asset('assets/images/logo.png'),
              ),
            ),
          ),
          // Form Container
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    // Show validators only after submit has been attempted
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: AppColor.color0C1024,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                "Sign Up – We're excited to \nhave you!",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18.0,
                                  color: AppColor.color0C1024,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // First & Last Name
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 155,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "First Name",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                      color: AppColor.color0C1024,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AppInputField(
                                    controller: _firstNameController,
                                    hintText: "John",
                                    labelText: "John",
                                    borderRadius: 24,
                                    borderColor: AppColor.color838B98,
                                    focusedBorderColor: AppColor.color838B98,
                                    margin: EdgeInsets.zero,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "First Name is required";
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 155,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Last Name",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                      color: AppColor.color0C1024,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AppInputField(
                                    controller: _lastNameController,
                                    hintText: "Doe",
                                    labelText: "Doe",
                                    borderRadius: 24,
                                    borderColor: AppColor.color838B98,
                                    focusedBorderColor: AppColor.color838B98,
                                    margin: EdgeInsets.zero,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "Last Name is required";
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Username
                        Text(
                          "Username",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: AppColor.color0C1024,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppInputField(
                          controller: _usernameController,
                          hintText: "@johndoeaccount",
                          labelText: "@johndoeaccount",
                          borderRadius: 24,
                          borderColor: AppColor.color838B98,
                          focusedBorderColor: AppColor.color838B98,
                          margin: EdgeInsets.zero,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Username is required";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Email
                        Text(
                          "Email",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: AppColor.color0C1024,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 15),

                        // Create Password
                        Text(
                          "Create Password",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: AppColor.color0C1024,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppInputField(
                          controller: _passwordController,
                          hintText: "",
                          labelText: "",
                          isPasswordField: true,
                          obscureText: isPasswordVisible,
                          onSuffix: () {
                            ref
                                .read(passwordVisibilityProvider.notifier)
                                .state = !isPasswordVisible;
                          },
                          suffixIcon: const Icon(Icons.remove_red_eye),
                          borderRadius: 24,
                          borderColor: AppColor.color838B98,
                          focusedBorderColor: AppColor.color838B98,
                          margin: EdgeInsets.zero,
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 15),

                        // Confirm Password
                        Text(
                          "Confirm Password",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: AppColor.color0C1024,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppInputField(
                          controller: _confirmPasswordController,
                          hintText: "",
                          labelText: "",
                          isPasswordField: true,
                          obscureText: isConfirmPasswordVisible,
                          onSuffix: () {
                            ref
                                .read(
                                    confirmPasswordVisibilityProvider.notifier)
                                .state = !isConfirmPasswordVisible;
                          },
                          suffixIcon: const Icon(Icons.remove_red_eye),
                          borderRadius: 24,
                          borderColor: AppColor.color838B98,
                          focusedBorderColor: AppColor.color838B98,
                          margin: EdgeInsets.zero,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please confirm your password";
                            } else if (value != _passwordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Terms Checkbox
                        Row(
                          children: [
                            Transform.scale(
                              scale: 1.6,
                              child: Checkbox(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                  side: BorderSide(
                                    width: 1,
                                    color: AppColor.color838B98,
                                  ),
                                ),
                                value: _acceptedTerms,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _acceptedTerms = value ?? false;
                                  });
                                },
                              ),
                            ),
                            Flexible(
                              child: Text(
                                "I agree to the Terms and Privacy Policy.",
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: AppColor.color0C1024,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Create Account Button
                        AppButton(
                          text: "Create Account",
                          onPressed: () async {
                            setState(() {
                              _submitted = true;
                            });
                            if (_formKey.currentState!.validate()) {
                              if (!_acceptedTerms) {
                                showTopSnackBar(context,
                                    "You must accept the Terms and Privacy Policy.");
                                return;
                              }

                              // Attempt registration
                              await authNotifier.registerUser(
                                firstName: _firstNameController.text.trim(),
                                lastName: _lastNameController.text.trim(),
                                username: _usernameController.text.trim(),
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim(),
                                acceptedTerms: _acceptedTerms,
                              );

                              // If registration succeeds (error == null), proceed to VerifyAccountOtpScreen
                              if (ref.read(authNotifierProvider).error ==
                                  null) {
                                // Get user ID from the registration response (assuming it's stored in state)
                                // For demo purposes, we'll use a placeholder user ID
                                final registerResponse =
                                    ref.read(authNotifierProvider);
                                final userId =
                                    registerResponse.user?.userId ?? 1;

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VerifyAccountOtpScreen(
                                      userId: userId,
                                      email: _emailController.text.trim(),
                                    ),
                                  ),
                                );
                              }
                            } else {
                              showTopSnackBar(
                                  context, "Please check your details.");
                            }
                          },
                          isLoading: authState.isLoading,
                          isFullWidth: true,
                          borderRadius: 24,
                          backgroundColor: authState.isLoading
                              ? AppColor.disabled
                              : AppColor.black,
                          width: 50,
                          fontSize: 16,
                        ),
                        const SizedBox(height: 10),

                        // Already Have an Account -> Login
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already Have an Account?",
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: AppColor.color0C1024,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                      context, RoutesName.login);
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
          ),
        ],
      ),
    );
  }
}
