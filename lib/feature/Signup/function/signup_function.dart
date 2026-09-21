import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/MainScreen/view/main_screen_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
          "createdAt":FieldValue.serverTimestamp(),
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
    GoogleSignIn sign=GoogleSignIn.instance;
    if(kIsWeb){
      UserCredential userCredential;
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({
        'client_id':
        '444759864301-u38ue6s39jjnkeuhseisj7tftkfusgip.apps.googleusercontent.com',
      });
      userCredential = await auth.signInWithPopup(googleProvider);
      await firestore.collection('user').doc(auth.currentUser!.uid).get().then((value)async{
        if(value.exists){
          Get.offAll(MainScreenView());
        }
        else{
          await firestore.collection('user').doc(_auth.currentUser!.uid).set({
            'email': _auth.currentUser!.email,
            'name': _auth.currentUser!.displayName,
            'role': 'user',
            'isBlocked': false,
            'uid': _auth.currentUser!.uid,
          });
          Get.offAll(() =>  MainScreenView());
        }
      });
    }
    else{
      sign.initialize(
        serverClientId: "848711152963-tiv41d0ms53d5gl72b60ik54asf5asov.apps.googleusercontent.com",
      );

      final googleuser=await sign.authenticate();
      final GoogleSignInAuthentication googleAuth=googleuser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      auth.signInWithCredential(credential).then((value)async{
        await firestore.collection('user').doc(auth.currentUser!.uid).get().then((value)async{
          if(value.exists){
            Get.offAll(MainScreenView());
          }
          else{
            await firestore.collection('user').doc(_auth.currentUser!.uid).set({
              'email': _auth.currentUser!.email,
              'name': _auth.currentUser!.displayName,
              'role': 'user',
              'isBlocked': false,
              'uid': _auth.currentUser!.uid,
              "createdAt":FieldValue.serverTimestamp(),
            });
            Get.offAll(() =>  MainScreenView());
          }
        });
      });
    }

  }
  catch(e){
    showErrorDialog(context, "Error", e.toString());
  }
}