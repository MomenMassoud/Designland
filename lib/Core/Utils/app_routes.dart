import 'package:flutter/material.dart';
import '../../feature/Basket/view/basket_view.dart';
import '../../feature/Login/view/login_view.dart';
import '../../feature/MainScreen/view/main_screen_view.dart';
import '../../feature/Splash/View/splash_view.dart';

Map<String, Widget Function(BuildContext)> appRoutes = {
  SplashView.id: (context) => const SplashView(),
  LoginView.id: (context) =>  LoginView(),
  MainScreenView.id: (context) =>  MainScreenView(),
  BasketView.id: (context) =>  BasketView(),
};
