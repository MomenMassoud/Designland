import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/MainScreen/view/main_screen_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/widgets/error_dailog_custom.dart';

final FirebaseAuth _auth=FirebaseAuth.instance;
final FirebaseFirestore _firestore=FirebaseFirestore.instance;

Future<bool>RegisterFunction(BuildContext context,String email,String password,String conPassword,String name)async{
  if(password!=conPassword){
    showErrorDialog(context, "Failed to create the account.".tr, "The passwords do not match.".tr);
  }
  else{
    try{
      await _auth.createUserWithEmailAndPassword(email: email, password: password).then((value){
        _firestore.collection('user').doc(_auth.currentUser!.uid).set({
          'email':email,
          'name':name,
          'role':'user',
          'uid':_auth.currentUser!.uid,
          'isBlocked':false,
        });
      });
      Get.offAll(MainScreenView(),routeName: MainScreenView.id);
      return true;
    }
    catch(e){
      showErrorDialog(context, "Failed to create the account.".tr, e.toString());
      return false;
    }
  }
  return false;
}


void SignInWithGoogle(BuildContext context)async{
  FirebaseAuth auth=FirebaseAuth.instance;
  FirebaseFirestore firestore=FirebaseFirestore.instance;
  try{
    final googleProvider = GoogleAuthProvider();
    googleProvider.setCustomParameters({
      'client_id':
      '444759864301-u38ue6s39jjnkeuhseisj7tftkfusgip.apps.googleusercontent.com',
    });
    final userCredential = await auth.signInWithPopup(googleProvider);
    final user = userCredential.user;
    if (user == null) {
      throw Exception("Google sign-in failed. No user returned.");
    }
    final String uid = userCredential.user!.uid;
    final DocumentSnapshot userDoc =
    await firestore.collection('user').doc(uid).get();
    print(userDoc.id);
    if (userDoc.exists) {
      Get.offAll(MainScreenView());
    }
    else{
     await _firestore.collection('user').doc(_auth.currentUser!.uid).set({
       'email':_auth.currentUser!.email,
       'name':_auth.currentUser!.displayName,
       'role':'user',
       'isBlocked':false,
       'uid':_auth.currentUser!.uid
     }).then((value){
       Get.offAll(MainScreenView());
     });
    }
  }
  catch(e){
    print(e);
  }
}