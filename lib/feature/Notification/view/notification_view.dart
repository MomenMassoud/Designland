import 'package:desginland/Core/widgets/auth_not_found.dart';
import 'package:desginland/feature/Notification/widget/notification_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



class NotificationView extends StatelessWidget{
  final FirebaseAuth _auth=FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return _auth.currentUser!=null? NotificationWidget():AuthNotLoginWidget();
  }
}