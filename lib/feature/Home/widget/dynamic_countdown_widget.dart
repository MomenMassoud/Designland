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
    if (_timeLeft == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child:  Text(
          "The offer has ended.".tr,
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return Row(
      children: [
        if (days > 0) ...[
          _buildTimeBox(_twoDigits(days), "day".tr),
          const Text(" : ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
        _buildTimeBox(_twoDigits(hours), "hour".tr),
        const Text(" : ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        _buildTimeBox(_twoDigits(minutes), "minute".tr),
        const Text(" : ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        _buildTimeBox(_twoDigits(seconds), "second".tr),
      ],
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
