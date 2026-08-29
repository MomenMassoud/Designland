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
    showErrorDialog(context, "فشل في انشاء الحساب", "كلمتا السر غير متطابقتين");
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
      showErrorDialog(context, "فشل في انشاء الحساب", e.toString());
      return false;
    }
  }
  return false;
}