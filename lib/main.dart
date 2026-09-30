import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:seo/seo.dart';
import 'Core/Utils/app_routes.dart';
import 'Core/Utils/app_themes.dart';
import 'Core/server/firebase massaging server.dart';
import 'Core/services/user_presence_service.dart';
import 'Core/widgets/App_localization.dart';
import 'feature/Product/widget/product_widget.dart';
import 'feature/Splash/View/splash_view.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تفعيل مسار الروابط المباشر بدون (#) للـ Web
  usePathUrlStrategy();

  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessagingService.initialize().catchError((e) {
    debugPrint('Error initializing Firebase Messaging: $e');
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    UserPresenceService().init();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. معالجة فتح التطبيق وهو مقفول تماماً (Cold Start)
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial app link: $e');
    }

    // 2. معالجة فتح التطبيق وهو في الخلفية (Background State)
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleIncomingUri(uri);
      }
    }, onError: (err) {
      debugPrint('Error listening to app links: $err');
    });
  }

  void _handleIncomingUri(Uri uri) {
    final path = uri.path;
    if (path.startsWith('/product/')) {
      final productId = path.replaceFirst('/product/', '');
      if (productId.isNotEmpty) {
        // التأكد من رسم أول إطار للشاشة لتفادي الشاشة السوداء عند الـ Cold Start
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.to(() => ProductWidget(productDoc: productId));
        });
      }
    }
  }

  @override
  void dispose() {
    UserPresenceService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Locale deviceLocale = Get.deviceLocale ?? const Locale('en');

    return SeoController(
      enabled: kIsWeb,
      tree: WidgetTree(
        context: context,
      ),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DesignLand',
        translations: AppTranslations(),
        locale: deviceLocale,
        fallbackLocale: const Locale('en', 'US'),
      
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.system,
      
        initialRoute: SplashView.id,
        getPages: appPages,
      
        // معالجة فتح روابط المنتج المباشرة على الويب / الموبايل
        onGenerateRoute: (settings) {
          if (settings.name != null && settings.name!.startsWith('/product/')) {
            final productId = settings.name!.replaceFirst('/product/', '');
            return MaterialPageRoute(
              builder: (context) => ProductWidget(productDoc: productId),
              settings: settings,
            );
          }
          return null;
        },
      
        builder: (context, child) => child ?? const SizedBox.shrink(),
      ),
    );
  }
}