import 'package:flutter/material.dart';

Route<T> slideRoute<T>({
  required Widget page,
  bool forward = true,
}) {
  const curve = Curves.easeOutCubic;
  final beginOffset = forward ? const Offset(1, 0) : const Offset(-1, 0);
  final endOffset = Offset.zero;
  final tween = Tween(begin: beginOffset, end: endOffset).chain(
    CurveTween(curve: curve),
  );
  final secondaryTween = Tween(
    begin: Offset.zero,
    end: forward ? const Offset(-0.2, 0) : const Offset(0.2, 0),
  ).chain(CurveTween(curve: curve));

  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(tween),
        child: SlideTransition(
          position: secondaryAnimation.drive(secondaryTween),
          child: child,
        ),
      );
    },
  );
}

Future<T?> slideToPage<T>(
  BuildContext context,
  Widget page, {
  bool replace = false,
  bool forward = true,
}) {
  final route = slideRoute<T>(page: page, forward: forward);
  if (replace) {
    return Navigator.of(context).pushReplacement(route);
  }
  return Navigator.of(context).push(route);
}
