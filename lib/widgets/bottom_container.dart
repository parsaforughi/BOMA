import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class BottomContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDismiss;
  final double maxHeightFraction;

  const BottomContainer({
    super.key,
    required this.child,
    this.onDismiss,
    this.maxHeightFraction = 0.45,
  });

  @override
  State<BottomContainer> createState() => _BottomContainerState();
}

class _BottomContainerState extends State<BottomContainer> {
  double _dragOffset = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) {
      setState(() => _dragOffset += details.delta.dy);
    } else if (_dragOffset > 0) {
      setState(() =>
          _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 500.0));
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset > 100) {
      widget.onDismiss?.call();
    }
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        MediaQuery.of(context).size.height * widget.maxHeightFraction;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(0, _dragOffset, 0),
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.sheetBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                GestureDetector(
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.dragIndicator,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                Flexible(child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
