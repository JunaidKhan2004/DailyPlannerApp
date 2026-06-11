import 'package:flutter/material.dart';

/// A chunky game-style 3D surface: a hard bottom "edge" shadow with no blur.
/// When tappable, the surface physically presses down onto its edge.
class Surface3D extends StatefulWidget {
  const Surface3D({
    super.key,
    required this.child,
    this.color,
    this.edgeColor,
    this.borderColor,
    this.gradient,
    this.depth = 5,
    this.borderRadius = 18,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final Color? color;

  /// The solid bottom edge. Defaults to a darker shade of [color].
  final Color? edgeColor;
  final Color? borderColor;
  final Gradient? gradient;
  final double depth;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  /// Darkens a color for use as the 3D edge.
  static Color darken(Color color, [double amount = 0.22]) =>
      Color.lerp(color, Colors.black, amount)!;

  @override
  State<Surface3D> createState() => _Surface3DState();
}

class _Surface3DState extends State<Surface3D> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap != null) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.surfaceContainerLow;
    final edge = widget.edgeColor ?? Surface3D.darken(color);
    final down = _pressed ? widget.depth : 0.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: Padding(
        // Reserve room for the edge so layout doesn't jump while pressing.
        padding: EdgeInsets.only(bottom: widget.depth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(0, down, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.gradient == null ? color : null,
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: edge,
                offset: Offset(0, widget.depth - down),
                blurRadius: 0,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
