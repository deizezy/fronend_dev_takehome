import 'dart:async';

import 'package:flutter/material.dart';

class FlashCountdownBadge extends StatefulWidget {
  final DateTime endsAt;
  final VoidCallback? onExpired;
  final TextStyle? style;

  const FlashCountdownBadge({
    super.key,
    required this.endsAt,
    this.onExpired,
    this.style,
  });

  @override
  State<FlashCountdownBadge> createState() => _FlashCountdownBadgeState();
}

class _FlashCountdownBadgeState extends State<FlashCountdownBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCountdown();
  }

  @override
  void didUpdateWidget(covariant FlashCountdownBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) {
      _timer?.cancel();
      _initCountdown();
    }
  }

  void _initCountdown() {
    if (DateTime.now().isAfter(widget.endsAt)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onExpired?.call();
      });
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (DateTime.now().isAfter(widget.endsAt)) {
        _timer?.cancel();
        widget.onExpired?.call();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.endsAt.difference(DateTime.now());

    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;

    final text = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    if (remaining.isNegative) {
      return Text('Expired', style: widget.style);
    }
    return Text(text, style: widget.style);
  }
}
