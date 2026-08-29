import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Core/Utils/app_routes.dart';
import 'Core/widgets/App_localization.dart';
import 'feature/Splash/View/splash_view.dart';
import 'firebase_options.dart';


Future<void> main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(
       MyApp()
  );
}

class MyApp extends StatelessWidget {
   MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceLocale = Get.deviceLocale ?? const Locale('ar');
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DesignLand',
      translations: AppTranslations(),
      locale: deviceLocale,
      initialRoute: SplashView.id,
      routes: appRoutes,
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}