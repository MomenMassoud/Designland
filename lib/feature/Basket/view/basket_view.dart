import 'package:desginland/Core/widgets/auth_not_found.dart';
import 'package:desginland/feature/Basket/widget/basket_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class BasketView extends StatelessWidget{
  static const id = 'basket_screen';
  final FirebaseAuth _auth=FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return _auth.currentUser!=null? BasketWidget():AuthNotLoginWidget();
  }
}