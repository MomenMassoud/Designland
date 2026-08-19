import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../Core/widgets/error_dailog_custom.dart';
import '../view/login_view.dart'; // تأكد من المسار الخاص بك

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore=FirebaseFirestore.instance;

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
      return true;
    } else {
      if (context.mounted) {
        showErrorDialog(
          context,
          "تسجيل الدخول فشل",
          "لم نتمكن من التحقق من بيانات الحساب، برجاء المحاولة مرة أخرى.",
        );
      }
      return false;
    }
  } on FirebaseAuthException catch (e) {
    // 2. معالجة أخطاء Firebase المحددة وترجمتها
    String errorMessage = "حدث خطأ أثناء تسجيل الدخول";

    if (e.code == 'user-not-found') {
      errorMessage = "هذا البريد الإلكتروني غير مسجل لدينا.";
    } else if (e.code == 'wrong-password') {
      errorMessage = "كلمة المرور غير صحيحة، يرجى التأكد وإعادة المحاولة.";
    } else if (e.code == 'invalid-email') {
      errorMessage = "صيغة البريد الإلكتروني غير صحيحة.";
    } else if (e.code == 'user-disabled') {
      errorMessage = "تم تعطيل هذا الحساب. يرجى التواصل مع الدعم.";
    } else if (e.code == 'invalid-credential') {
      errorMessage = "البريد الإلكتروني أو كلمة المرور غير صحيحة.";
    } else if (e.code == 'too-many-requests') {
      errorMessage = "تم حظر المحاولات مؤقتاً لكثرة المحاولات الخاطئة. حاول لاحقاً.";
    }

    if (context.mounted) {
      showErrorDialog(context, "فشل تسجيل الدخول", errorMessage);
    }
    return false;
  } catch (e) {
    // 3. معالجة أي خطأ عام آخر (مثل انقطاع الإنترنت)
    if (context.mounted) {
      showErrorDialog(
        context,
        "خطأ غير متوقع",
        "تأكد من الاتصال بالإنترنت وأعد المحاولة.",
      );
    }
    return false;
  }
}
//
// Future<UserModel> GetCurrentUserData(BuildContext context)async{
//   UserModel userModel=UserModel(uid: "", email: "", Name: "", role: "");
//   try{
//     await _firestore.collection('user').doc(_auth.currentUser!.uid).get().then((value){
//       userModel.uid=_auth.currentUser!.uid;
//       userModel.role=value.get('role');
//       userModel.Name=value.get('name');
//       userModel.email=value.get('email');
//     });
//     return userModel;
//   }
//   catch(e){
//     showErrorDialog(context, "فشل جلب بيانات المستخدم", e.toString());
//     return userModel;
//   }
// }



Future<void>LogoutMethod(BuildContext context)async{
  try{
    await _auth.signOut().then((value){
      Navigator.pushReplacementNamed(context, LoginView.id);
    });
  }
  catch(e){
    showErrorDialog(context, "فشل في تسجيل الخروج", e.toString());
  }
}
