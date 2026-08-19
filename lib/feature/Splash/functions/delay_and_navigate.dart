import 'package:flutter/material.dart';

void delayAndNavigate(BuildContext context) {
  Future.delayed(const Duration(seconds: 4)).then((value) {

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) =>  PayView()),
    // );

  });
}
