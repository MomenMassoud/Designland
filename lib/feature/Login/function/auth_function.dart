import 'package:desginland/feature/MainScreen/view/main_screen_view.dart';
import 'package:desginland/feature/Splash/View/splash_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/widgets/error_dailog_custom.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<bool> LoginFunction(
    BuildContext context,
    String email,
    String password,
    ) async {
  try {
    // 1. انتظار نتيجة تسجيل الدخول بـ await
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (userCredential.user != null) {
      Get.offAll(MainScreenView(),routeName: MainScreenView.id);
      return true;
    } else {
      if (context.mounted) {
        showErrorDialog(
          context,
          "Login failed".tr,
          "We were unable to verify the account details; please try again.".tr,
        );
      }
      return false;
    }
  } on FirebaseAuthException catch (e) {
    // 2. معالجة أخطاء Firebase المحددة وترجمتها
    String errorMessage = "An error occurred while logging in.".tr;

    if (e.code == 'user-not-found') {
      errorMessage = "This email address is not registered with us.".tr;
    } else if (e.code == 'wrong-password') {
      errorMessage = "The password is incorrect; please check it and try again.".tr;
    } else if (e.code == 'invalid-email') {
      errorMessage = "The email format is invalid.".tr;
    } else if (e.code == 'user-disabled') {
      errorMessage = "This account has been disabled. Please contact support.".tr;
    } else if (e.code == 'invalid-credential') {
      errorMessage = "The email or password is incorrect.".tr;
    } else if (e.code == 'too-many-requests') {
      errorMessage = "Attempts have been temporarily blocked due to too many incorrect attempts. Please try again later.".tr;
    }

    if (context.mounted) {
      showErrorDialog(context, "Login failed".tr, errorMessage);
    }
    return false;
  } catch (e) {
    // 3. معالجة أي خطأ عام آخر (مثل انقطاع الإنترنت)
    if (context.mounted) {
      showErrorDialog(
        context,
        "Unexpected error".tr,
        "Make sure you are connected to the Internet and try again.".tr,
      );
    }
    return false;
  }
}

Future<void>LogoutMethod(BuildContext context)async{
  try{
    await _auth.signOut().then((value){
      Get.offAll(SplashView(),routeName: SplashView.id);
    });
  }
  catch(e){
    showErrorDialog(context, "Failed to log out".tr, e.toString());
  }
}
