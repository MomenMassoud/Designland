import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../feature/Basket/view/basket_view.dart';
import '../../feature/Login/view/login_view.dart';
import '../../feature/MainScreen/view/main_screen_view.dart';
import '../../feature/Product/widget/product_widget.dart';
import '../../feature/Splash/View/splash_view.dart';

List<GetPage> appPages = [
  GetPage(
    name: SplashView.id,
    page: () => const SplashView(),
  ),
  GetPage(
    name: LoginView.id,
    page: () => LoginView(),
  ),
  GetPage(
    name: MainScreenView.id,
    page: () => MainScreenView(),
  ),
  GetPage(
    name: BasketView.id,
    page: () => BasketView(),
  ),
  // 🔗 مسار المنتج الديناميكي لدعم الـ URL
  GetPage(
    name: '/product/:id',
    page: () =>  ProductWidget(),
  ),
];