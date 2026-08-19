import 'package:flutter/material.dart';

import '../Wedgit/splash_view_body.dart';
import '../functions/delay_and_navigate.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});
  static const id = 'splashview';

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    delayAndNavigate(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const SplashViewBody();
  }

}
