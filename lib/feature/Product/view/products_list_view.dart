import 'package:desginland/feature/Product/widget/product_list_widget.dart';
import 'package:flutter/material.dart';


class ProductsListView extends StatelessWidget{
  String CategoryDoc;
  ProductsListView({required this.CategoryDoc});
  @override
  Widget build(BuildContext context) {
    return ProductListWidget(categoryDoc: CategoryDoc);
  }
}