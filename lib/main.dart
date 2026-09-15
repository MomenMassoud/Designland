import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'Core/Utils/app_routes.dart';
import 'Core/widgets/App_localization.dart';
import 'feature/Splash/View/splash_view.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );
  if (kIsWeb) {
    await GoogleSignIn.instance.initialize(
      clientId: '848711152963-tiv41d0ms53d5gl72b60ik54asf5asov.apps.googleusercontent.com',
    );
  }
  runApp(
      MyApp()
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final deviceLocale = Get.deviceLocale ?? const Locale('en');
    return GetMaterialApp(
      builder: (context, child) {
        return child ?? const SizedBox();
      },
      onGenerateRoute: (setting){
        return GetPageRoute(
            routeName: SplashView.id
        );
      },
      debugShowCheckedModeBanner: false,
      title: 'DesignLand',
      translations: AppTranslations(),
      locale: deviceLocale,
      initialRoute: SplashView.id,
      routes: appRoutes,
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
    );
  }
}