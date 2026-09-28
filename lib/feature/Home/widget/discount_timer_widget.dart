import 'dart:async';
import 'package:flutter/material.dart';

class DiscountTimerWidget extends StatefulWidget {
  final Duration duration;
  const DiscountTimerWidget({super.key, required this.duration});

  @override
  State<DiscountTimerWidget> createState() => _DiscountTimerWidgetState();
}

class _DiscountTimerWidgetState extends State<DiscountTimerWidget> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0 && mounted) {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4757).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4757).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFFF4757)),
          const SizedBox(width: 4),
          Text(
            "$hours:$minutes:$seconds",
            style: const TextStyle(
              color: Color(0xFFFF4757),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}