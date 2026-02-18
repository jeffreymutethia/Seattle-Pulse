import 'package:seattle_pulse_mobile/auth_wrapper.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';

import 'src/core/config/config.dart';
import 'package:flutter/material.dart';
import 'src/core/routes/routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, ch) => DismissKeyboard(
        child: MaterialApp(
          theme: ThemeData(
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: AppColor.colorFAFBFF,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColor.colorFAFBFF,
              elevation: 0,
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
          onGenerateRoute: AppRoute.generate,
        ),
      ),
    );
  }
}
