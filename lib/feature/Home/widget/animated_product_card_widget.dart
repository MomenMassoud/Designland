import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/server/analytics_service.dart';
import '../../Product/widget/product_widget.dart';

class AnimatedProductCard extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String imageUrl;
  final String productId;
   AnimatedProductCard({
    super.key,
    required this.productData,
    required this.imageUrl,
    required this.productId,
  });

  @override
  State<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard> {
  List<String> _favProduct=[];
  bool _isHovered = false;
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;
  final FirebaseAuth _auth=FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    _GetFavProduct();
  }
  void _GetFavProduct()async{
    try{
      _favProduct=[];
      if(_auth.currentUser!=null){
        await for(var snap in _firestore.collection('user').doc(_auth.currentUser!.uid).collection('fav').snapshots()){
          for(int i=0;i<snap.size;i++){
            _favProduct.add(snap.docs[i].get('product'));
          }
        }
        setState(() {
          _favProduct;
        });
      }
    }
    catch(e){
      print(e);
    }
  }
  @override
  Widget build(BuildContext context) {
    final num originalPrice = widget.productData['price'] ?? 0;
    final num discountPercentage = widget.productData['discountPercentage'] ?? 0;
    final Timestamp? discountUntil = widget.productData['discountUntil'] as Timestamp?;
    final bool isExpired = discountUntil != null && discountUntil.toDate().isBefore(DateTime.now());
    final bool hasDiscount = discountPercentage > 0 && !isExpired;
    bool fav=_favProduct.contains(widget.productId);
    final num finalPrice = hasDiscount
        ? (originalPrice * (1 - (discountPercentage / 100))).round()
        : originalPrice;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: () {
        AnalyticsService.logProductOpen(
          productId: widget.productId,
          productTitle: widget.productData['title'],
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductWidget(productDoc: widget.productId),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isHovered ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 14 : 8,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: widget.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl:  widget.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      height: 130,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7675),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7675).withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "-$discountPercentage%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child:  IconButton(
                        icon: Icon(
                          fav?Icons.favorite: Icons.favorite_border_rounded,
                          size: 16,
                          color:fav?Colors.red: Color(0xFF6C5CE7),
                        ),
                        onPressed: ()async{
                          if(_auth.currentUser!=null){
                            _GetFavProduct();
                            if(fav){
                              String ref="";
                              await _firestore.collection('user').doc(_auth.currentUser!.uid).collection('fav').where('product',isEqualTo: widget.productId).get().then((value){
                                ref=value.docs[0].id;
                              }).then((value)async{
                                await _firestore.collection('user').doc(_auth.currentUser!.uid).collection('fav').doc(ref).delete();
                                fav=false;
                                _favProduct.remove(widget.productId);
                                setState(() {
                                 _favProduct;
                                  fav;
                                });
                              });
                            }
                            else{
                              await _firestore.collection('user').doc(_auth.currentUser!.uid).collection('fav').doc().set({
                                'product':widget.productId
                              });
                              fav=true;
                              _favProduct.add(widget.productId);
                              setState(() {
                                _favProduct;
                                fav;
                              });
                            }

                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productData['title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$finalPrice${"EGP".tr}",
                              style: const TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            if (hasDiscount)
                              Text(
                                "$originalPrice${"EGP".tr}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}