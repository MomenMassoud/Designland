import 'package:desginland/feature/Product/widget/product_widget.dart';
import 'package:flutter/material.dart';



class ProductView extends StatelessWidget{
  String _ProductDoc;
  ProductView({required this._ProductDoc});
  @override
  Widget build(BuildContext context) {
    return ProductWidget(productDoc: _ProductDoc,);
  }
}