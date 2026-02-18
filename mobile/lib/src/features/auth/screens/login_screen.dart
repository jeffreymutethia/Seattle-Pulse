import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/routes/routes.dart';
import 'package:seattle_pulse_mobile/src/core/utils/validators.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_input_field.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/custom_nav_bar.dart';
import 'package:seattle_pulse_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:seattle_pulse_mobile/src/features/feed/screens/feed_screen.dart';
import '../../../core/constants/colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;

  void showTopSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: AppColor.white),
        textAlign: TextAlign.center,
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColor.colorB81616,
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
    final authState = ref.watch(authNotifierProvider);

    final isPasswordVisible = ref.watch(passwordVisibilityProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      if (next.isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomBottomNavBar()),
        );
      } else if (next.error != null && next.error!.isNotEmpty) {
        showTopSnackBar(context, next.error!);
      }
    });

    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Login – Welcome Back!",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18.0,
                            color: AppColor.color0C1024,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Email",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: AppColor.color0C1024,
                          ),
                        ),
                        const SizedBox(height: 15),
                        AppInputField(
                          controller: emailCtrl,
                          hintText: "example@email.com",
                          labelText: "example@email.com",
                          borderRadius: 24,
                          borderColor: AppColor.color838B98,
                          focusedBorderColor: AppColor.color838B98,
                          margin: EdgeInsets.zero,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Password",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: AppColor.color0C1024,
                          ),
                        ),
                        const SizedBox(height: 15),
                        AppInputField(
                          controller: passCtrl,
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
                                value: _rememberMe,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                            ),
                            Text(
                              "Remember me",
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                color: AppColor.color0C1024,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          text: "Login",
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              authNotifier.loginUser(
                                emailCtrl.text.trim(),
                                passCtrl.text.trim(),
                              );
                            } else {
                              showTopSnackBar(
                                context,
                                "Invalid email or password",
                              );
                            }
                          },
                          isLoading: authState.isLoading,
                          backgroundColor: authState.isLoading
                              ? AppColor.disabled
                              : AppColor.black,
                          isFullWidth: true,
                          borderRadius: 24,
                          borderColor: authState.error != null
                              ? AppColor.color707988
                              : AppColor.black,
                          width: 50,
                          fontSize: 16,
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, RoutesName.recoverPassword);
                            },
                            child: Text(
                              "Forgot your password?",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: AppColor.color4C68D5,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColor.colorABB0B9,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                "or",
                                style: TextStyle(
                                  color: AppColor.color0C1024,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColor.color838B98,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          text: "Login with Google",
                          onPressed: () {},
                          buttonType: ButtonType.secondary,
                          borderRadius: 24,
                          isFullWidth: true,
                          width: 50,
                          image:
                              "https://img.icons8.com/fluency/48/google-logo.png",
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don’t Have an Account?",
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: AppColor.color0C1024,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, RoutesName.signup);
                                },
                                child: Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
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
            ),
          ),
        ],
      ),
    );
  }
}
