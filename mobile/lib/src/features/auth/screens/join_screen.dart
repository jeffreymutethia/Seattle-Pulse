import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/core/constants/constants.dart';
import 'package:seattle_pulse_mobile/src/core/routes/routes.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/features/auth/screens/google_login_webview.dart';

class JoinPage extends StatelessWidget {
  const JoinPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Join Seattle Pulse",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                AppButton(
                  text: "Create an Account",
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      RoutesName.signup,
                    );
                  },
                  isFullWidth: true,
                  borderRadius: 24,
                  width: 50,
                  fontSize: 16,
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColor.colorABB0B9,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                const SizedBox(
                  height: 20,
                ),
                AppButton(
                  text: "Login with Google",
                  onPressed: () {
                    // Navigate to the WebView screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GoogleLoginWebView()),
                    ).then((_) async {
                      // This is called after the WebView closes.
                      // Optionally, confirm the user is now authenticated by calling a protected endpoint:
                      try {
                        final response = await ApiClient()
                            .get("/auth_social_login/protected");
                        if (response.statusCode == 200) {
                          // The user is successfully logged in.
                          // Move them to some "home" screen or wherever you like.
                          Navigator.pushNamed(context, RoutesName.home);
                        }
                      } catch (err) {
                        // The user is not authenticated, or something went wrong.
                      }
                    });
                  },
                  buttonType: ButtonType.secondary,
                  borderRadius: 24,
                  isFullWidth: true,
                  width: 50,
                  image: "https://img.icons8.com/fluency/48/google-logo.png",
                ),
                const SizedBox(
                  height: 15,
                ),
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
                          Navigator.pushNamed(context, RoutesName.login);

                          // Handle sign up action
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
