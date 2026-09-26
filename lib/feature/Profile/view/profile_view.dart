import 'package:desginland/feature/Profile/view/visitor_profile_view.dart';
import 'package:desginland/feature/Profile/widget/profile_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



class ProfileView extends StatelessWidget{
  final FirebaseAuth _auth=FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return _auth.currentUser!=null?ProfileWidget():VisitorProfileView();
  }
}