import 'package:flutter/material.dart';

/// فلش برگشت یکسان در کل اپ — از asset
class BackArrowIcon extends StatelessWidget {
  final double size;
  final Color color;
  /// در RTL گاهی فلش راست است؛ اگر [pointLeft] true باشد افقی برعکس می‌شود (فلش چپ).
  final bool pointLeft;

  const BackArrowIcon({
    super.key,
    this.size = 24,
    this.color = const Color(0xFFE0E0E0),
    this.pointLeft = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = SizedBox(
      width: size,
      height: size,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: Image.asset(
          'assets/icons/icon_arrow_back.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.arrow_back_ios,
            size: size,
            color: color,
          ),
        ),
      ),
    );
    if (pointLeft) {
      image = Transform.scale(scaleX: -1, child: image);
    }
    return image;
  }
}
