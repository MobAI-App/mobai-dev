// Preview adapter for pointer_interceptor (iOS/web plugin, federated).
// On mobile it stops taps leaking into a platform view; the preview has no
// platform views, so it is transparent.
import 'package:flutter/widgets.dart';

class PointerInterceptor extends StatelessWidget {
  const PointerInterceptor({
    super.key,
    this.intercepting = true,
    this.debug = false,
    required this.child,
  });

  final bool intercepting;
  final bool debug;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
