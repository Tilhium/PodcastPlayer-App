import 'package:flutter/material.dart';
import 'package:podcastplayer/theme/app_theme.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool expand;
  final Widget? leading;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.leading,
    this.textColor,
    this.padding,
    this.textStyle,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _updateHover(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  void _updatePressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.textColor ?? Colors.white;
    final borderRadius = BorderRadius.circular(18);
    final scale = _isPressed
        ? 0.97
        : _isHovered
            ? 1.02
            : 1.0;

    final lightenAmount = _isPressed
        ? 0.28
        : _isHovered
            ? 0.16
            : 0.0;

    final gradientColors = WhistilGradients.button.colors
        .map((baseColor) => Color.lerp(baseColor, Colors.white, lightenAmount)!)
        .toList(growable: false);

    final boxShadow = lightenAmount > 0
        ? [
            BoxShadow(
              color: WhistilPalette.primary.withOpacity(lightenAmount),
              blurRadius: _isPressed ? 30 : 24,
              offset: const Offset(0, 14),
            ),
          ]
        : null;

    final baseTextStyle = widget.textStyle ??
        Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final effectiveTextStyle = baseTextStyle?.copyWith(
      color: widget.textStyle?.color ?? color,
    );

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 12),
        ],
        Text(
          widget.label,
          style: effectiveTextStyle,
        ),
      ],
    );

    final button = MouseRegion(
      onEnter: (_) => _updateHover(true),
      onExit: (_) => _updateHover(false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: borderRadius,
            onHighlightChanged: _updatePressed,
            splashColor: Colors.white.withOpacity(0.18),
            highlightColor: Colors.white.withOpacity(0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: WhistilGradients.button.begin,
                  end: WhistilGradients.button.end,
                ),
                borderRadius: borderRadius,
                boxShadow: boxShadow,
              ),
              padding:
                  widget.padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (widget.expand) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
