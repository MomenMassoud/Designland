import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ==================== DYNAMIC COUNTDOWN WIDGET ====================
class DynamicCountdownWidget extends StatefulWidget {
  final Timestamp? untilTimestamp;
  final VoidCallback? onTimerExpired;

  const DynamicCountdownWidget({
    super.key,
    required this.untilTimestamp,
    this.onTimerExpired,
  });

  @override
  State<DynamicCountdownWidget> createState() => _DynamicCountdownWidgetState();
}

class _DynamicCountdownWidgetState extends State<DynamicCountdownWidget> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTimeLeft());
  }

  void _calculateTimeLeft() {
    if (widget.untilTimestamp == null) return;
    final targetDate = widget.untilTimestamp!.toDate();
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (difference.isNegative || difference == Duration.zero) {
      _timer?.cancel();
      if (mounted) {
        setState(() => _timeLeft = Duration.zero);
      }
      widget.onTimerExpired?.call();
    } else {
      if (mounted) {
        setState(() => _timeLeft = difference);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_timeLeft == Duration.zero) {
      final errorColor = theme.colorScheme.error;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: errorColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: errorColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_off_outlined, size: 14, color: errorColor),
            const SizedBox(width: 5),
            Text(
              "The offer has ended.".tr,
              style: TextStyle(
                color: errorColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    final separatorColor = isDarkMode ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (days > 0) ...[
          _buildTimeBox(context, _twoDigits(days), "day".tr),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(" : ", style: TextStyle(color: separatorColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
        _buildTimeBox(context, _twoDigits(hours), "hour".tr),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(" : ", style: TextStyle(color: separatorColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        _buildTimeBox(context, _twoDigits(minutes), "minute".tr),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(" : ", style: TextStyle(color: separatorColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        _buildTimeBox(context, _twoDigits(seconds), "second".tr),
      ],
    );
  }

  Widget _buildTimeBox(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final boxBackgroundColor = isDarkMode
        ? theme.primaryColor.withOpacity(0.15)
        : theme.primaryColor.withOpacity(0.08);

    final borderColor = isDarkMode
        ? theme.primaryColor.withOpacity(0.3)
        : theme.primaryColor.withOpacity(0.2);

    final valueTextColor = theme.primaryColor;
    final labelTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: boxBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: labelTextColor,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}