import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/shared/theme.dart';

class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 120,
    this.thickness = 12,
    this.color = TeamfitColors.brand,
    this.trackColor = TeamfitColors.ink700,
    this.label,
    this.sublabel,
    this.showTenths = false,
    this.totalSeconds = 0,
  });

  final double value;
  final double size;
  final double thickness;
  final Color color;
  final Color trackColor;
  final String? label;
  final String? sublabel;
  final bool showTenths;
  final int totalSeconds;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.showTenths && widget.value > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showTenths && widget.label != oldWidget.label) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _interpolatedProgress {
    if (!widget.showTenths || widget.totalSeconds <= 0) {
      return widget.value.clamp(0.0, 1.0);
    }
    final oneSecondFraction = 1.0 / widget.totalSeconds;
    final sub = _controller.value * oneSecondFraction;
    return (widget.value - sub).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _interpolatedProgress;
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: progress,
                  thickness: widget.thickness,
                  color: widget.color,
                  trackColor: widget.trackColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.label != null) _buildLabel(context),
                  if (widget.sublabel != null)
                    Text(
                      widget.sublabel!,
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: TeamfitColors.textOnInverseMuted,
                              ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    final baseStyle = TeamfitTypo.mono(fontSize: 34);

    if (!widget.showTenths) {
      return Text(widget.label!, style: baseStyle);
    }

    final tenthsStyle = TeamfitTypo.mono(fontSize: 17);

    final digit = 9 - (_controller.value * 10).floor().clamp(0, 9);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(widget.label!, style: baseStyle),
        Text('.$digit', style: tenthsStyle),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.thickness,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final double thickness;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - thickness) / 2;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      trackColor != oldDelegate.trackColor;
}
