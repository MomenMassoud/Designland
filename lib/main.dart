import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'Core/Utils/app_routes.dart';
import 'Core/widgets/App_localization.dart';
import 'feature/Splash/View/splash_view.dart';
import 'firebase_options.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main()async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // خلفية شفافة
      statusBarIconBrightness: Brightness.dark, // أيقونات داكنة (استخدم Brightness.light إذا كانت الخلفية داكنة)
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
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
            statusBarColor: Colors.transparent, // جعل الشريط شفافًا
            statusBarIconBrightness: Brightness.dark, // أيقونات داكنة على Android
            statusBarBrightness: Brightness.light, // أيقونات داكنة على iOS
          ),
        ),
      ),
    );
  }
}