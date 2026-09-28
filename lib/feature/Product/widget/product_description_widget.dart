import 'dart:convert';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/Utils/app.colors.dart';

class ProductDescriptionWidget extends StatefulWidget {
  final String description;

  const ProductDescriptionWidget({super.key, required this.description});

  @override
  State<ProductDescriptionWidget> createState() => _ProductDescriptionWidgetState();
}

class _ProductDescriptionWidgetState extends State<ProductDescriptionWidget> {
  EditorState? _editorState;
  EditorScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _parseDescription();
  }

  @override
  void didUpdateWidget(covariant ProductDescriptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description != widget.description) {
      _disposeEditor();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _parseDescription();
          setState(() {});
        }
      });
    }
  }

  void _disposeEditor() {
    _scrollController?.dispose();
    _scrollController = null;
    _editorState = null;
  }

  Map<String, dynamic>? _normalizeAppFlowyJson(dynamic value) {
    if (value is! Map) return null;
    dynamic current = value;
    int safetyCounter = 0;

    while (current is Map && safetyCounter < 20) {
      safetyCounter++;
      final map = Map<String, dynamic>.from(current);
      if (map['type'] == 'page') return {'document': map};

      if (map.containsKey('document')) {
        final nested = map['document'];
        if (nested is Map) {
          current = nested;
          continue;
        }
        if (nested is String) {
          try {
            current = jsonDecode(nested);
            continue;
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    }
    return null;
  }

  void _parseDescription() {
    final text = widget.description.trim();
    if (text.isEmpty) return;

    try {
      dynamic parsed = jsonDecode(text);
      while (parsed is String) {
        final inner = parsed.trim();
        if (inner.isEmpty) break;
        parsed = jsonDecode(inner);
      }

      final normalized = _normalizeAppFlowyJson(parsed);
      if (normalized != null) {
        final document = Document.fromJson(normalized);
        _editorState = EditorState(document: document);
        _scrollController = EditorScrollController(editorState: _editorState!);
        return;
      }
    } catch (_) {}
    _disposeEditor();
  }

  @override
  void dispose() {
    _disposeEditor();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? Colors.grey.shade300 : AppColors.textDark;
    final description = widget.description.trim();

    if (description.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "There is no additional description for the product.".tr,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : AppColors.textMuted,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (_editorState != null && _scrollController != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 10, maxHeight: 100),
          child: AppFlowyEditor(
            editorState: _editorState!,
            editorScrollController: _scrollController!,
            editable: false,
            autoFocus: false,
            shrinkWrap: true,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: SelectableText(
        widget.description,
        style: TextStyle(color: textSecondary, height: 1.5, fontSize: 14),
      ),
    );
  }
}