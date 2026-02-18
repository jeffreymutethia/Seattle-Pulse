import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class GoogleLoginWebView extends StatefulWidget {
  const GoogleLoginWebView({Key? key}) : super(key: key);

  @override
  State<GoogleLoginWebView> createState() => _GoogleLoginWebViewState();
}

class _GoogleLoginWebViewState extends State<GoogleLoginWebView> {
  late final WebViewController _controller;
  bool isLoading = true; // For showing the loading indicator

  @override
  void initState() {
    super.initState();

    // ✅ Set WebView implementation based on platform
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (Platform.isIOS) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }

    // ✅ Initialize WebViewController with JavaScript and DOM Storage enabled
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('Started loading: $url');
            setState(() => isLoading = true); // Show loading indicator
          },
          onPageFinished: (url) {
            debugPrint('Finished loading: $url');
            setState(() => isLoading = false); // Hide loading indicator

            // ✅ Automatically close WebView on successful authentication
            if (url.contains('/auth_social_login/callback')) {
              if (mounted) Navigator.pop(context);
            }
          },
          onNavigationRequest: (request) {
            debugPrint('Trying to load: ${request.url}');
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint("WebView error: ${error.description}");
          },
        ),
      );

    // ✅ Load the Google OAuth login URL
    _controller.loadRequest(
      Uri.parse("http://10.0.2.2:5001/api/v1/auth_social_login/login"),
    );
  }

  // ✅ Handle back button press inside WebView
  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false; // Stay in the WebView
    }
    return true; // Exit the WebView
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle WebView back navigation
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Google Sign In"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (isLoading)
              const Center(
                child:
                    CircularProgressIndicator(), 
              ),
          ],
        ),
      ),
    );
  }
}
