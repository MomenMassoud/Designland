import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

Future<void> showOrderDetailsBottomSheet({
  required BuildContext context,
  required String uid,
  required String productId,
  required Map<String, dynamic> productData,
  required double finalPrice,
}) async {
  final notesController = TextEditingController();
  final List<dynamic> customFieldsRaw =
      productData['fields'] ?? productData['customFields'] ?? [];
  final List<Map<String, dynamic>> customFields = customFieldsRaw
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  final Map<String, TextEditingController> customControllers = {
    for (var field in customFields)
      (field['name'] ?? 'field_${customFields.indexOf(field)}').toString():
      TextEditingController()
  };

  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order and Design Details".tr,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (customFields.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    "Required Product Specifications".tr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...customFields.map((field) {
                    final String fieldName = field['name'] ?? '';
                    final String fieldType = field['type'] ?? 'text';
                    final bool isRequired = field['isRequired'] ?? false;
                    final bool isDrive = fieldType == 'drive_link';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextFormField(
                        controller: customControllers[fieldName],
                        keyboardType:
                        isDrive ? TextInputType.url : TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "$fieldName${isRequired ? ' *' : ''}",
                          hintText: isDrive
                              ? "https://drive.google.com/..."
                              : null,
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                              isDrive ? Icons.add_link : Icons.edit_note),
                        ),
                        validator: (value) {
                          final textVal = value?.trim() ?? '';
                          if (isRequired && textVal.isEmpty) {
                            return "${"Please enter".tr} $fieldName";
                          }
                          if (isDrive && textVal.isNotEmpty) {
                            if (!textVal.startsWith('http://') &&
                                !textVal.startsWith('https://')) {
                              return "Please enter a valid link (e.g. https://...)"
                                  .tr;
                            }
                          }
                          return null;
                        },
                      ),
                    );
                  }),
                  const Divider(height: 24),
                ],
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "${"Additional notes on the request".tr} *",
                    hintText:
                    "Write down any specific details or modifications you would like to be implemented..."
                        .tr,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter the required notes for the order.".tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final Map<String, String> collectedCustomFields = {};
                      customControllers.forEach((key, controller) {
                        collectedCustomFields[key] = controller.text.trim();
                      });

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('cart')
                          .add({
                        'productId': productId,
                        'title': productData['title'] ?? '',
                        'price': finalPrice,
                        'originalPrice':
                        (productData['price'] ?? 0.0).toDouble(),
                        'image':
                        (productData['images'] as List?)?.firstOrNull ?? '',
                        'notes': notesController.text.trim(),
                        'customFieldsData': collectedCustomFields,
                        'selectedAddress': "",
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "The product has been successfully added to your cart! 🎉"
                                .tr,
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    label: Text(
                      "Confirm addition to cart".tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}