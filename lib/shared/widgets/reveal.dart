import 'package:flutter/material.dart';

Duration stagger(int i, [int ms = 60]) => Duration(milliseconds: ms * i.clamp(0, 8));

/// One-time entrance (fade + small rise).
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const Reveal({super.key, required this.child, this.delay = Duration.zero});
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    final total = widget.delay.inMilliseconds + 420;
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: total))..forward();
    _a = CurvedAnimation(parent: _c, curve: Interval(widget.delay.inMilliseconds / total, 1, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(_a),
        child: widget.child,
      ),
    );
  }
}
