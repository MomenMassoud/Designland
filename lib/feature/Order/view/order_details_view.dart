import 'package:desginland/feature/Order/widget/order_details_widget.dart';
import 'package:flutter/material.dart';



class OrderDetailsView extends StatelessWidget{
  String _orderID;
  OrderDetailsView({required this._orderID});
  @override
  Widget build(BuildContext context) {
    return OrderDetailsWidget(orderID: _orderID);
  }
}