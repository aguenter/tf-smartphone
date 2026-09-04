import 'package:flutter/material.dart';

import '../../app/shared/theme.dart';

/// A horizontal, drag-controlled carousel of number chips.
///
/// Numbers scroll horizontally; the chip snapped to the center is highlighted
/// in the coral brand color and reported as the selected value. Dragging left
/// or right shifts the chips and snaps the nearest number to the center.
class NumberCarousel extends StatefulWidget {
  const NumberCarousel({
    super.key,
    required this.onChanged,
    this.min = 0,
    this.max = 499,
    this.initial = 10,
    this.height = 96,
    this.viewportFraction = 0.24,
  });

  /// Called whenever a new number snaps to the center.
  final ValueChanged<int> onChanged;

  /// First selectable number (inclusive).
  final int min;

  /// Last selectable number (inclusive).
  final int max;

  /// Number that starts selected in the center.
  final int initial;

  /// Fixed height of the carousel track.
  final double height;

  /// Fraction of the viewport each chip occupies. Smaller values reveal more
  /// neighbouring chips on either side of the center.
  final double viewportFraction;

  @override
  State<NumberCarousel> createState() => NumberCarouselState();
}

class NumberCarouselState extends State<NumberCarousel> {
  late final PageController _controller;
  late int _centerIndex;

  int get _count => widget.max - widget.min + 1;

  int _clampToRange(int value) => value.clamp(widget.min, widget.max);

  @override
  void initState() {
    super.initState();
    _centerIndex = _clampToRange(widget.initial) - widget.min;
    _controller = PageController(
      initialPage: _centerIndex,
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Animate back to a specific value (e.g. to reset when the exercise
  /// changes). Called by the parent view via a [GlobalKey].
  void reset(int value) {
    final target = _clampToRange(value) - widget.min;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int page) {
    setState(() => _centerIndex = page);
    widget.onChanged(page + widget.min);
  }

  void _tapToCenter(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const PageScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemCount: _count,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // Distance of this chip from the exact center of the
                  // viewport, in units of pages (0 == perfectly centered).
                  final double page = _controller.hasClients &&
                          _controller.position.haveDimensions
                      ? (_controller.page ?? _centerIndex.toDouble())
                      : _centerIndex.toDouble();
                  final distance = (index - page).abs().clamp(0.0, 2.0);
                  final t = 1.0 - (distance / 2.0);

                  final scale = 0.6 + 0.4 * t;
                  final isCenter = distance < 0.5;
                  final color = Color.lerp(
                    TeamfitColors.textOnInverseMuted,
                    TeamfitColors.coral500,
                    isCenter ? (1.0 - distance * 2.0).clamp(0.0, 1.0) : 0.0,
                  )!;
                  final opacity = (0.35 + 0.65 * t).clamp(0.0, 1.0);

                  return Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _tapToCenter(index),
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Text(
                            '${index + widget.min}',
                            style: TeamfitTypo.mono(
                              fontSize: 44,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
      ),
    );
  }
}
