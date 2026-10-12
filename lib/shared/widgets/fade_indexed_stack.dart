import 'package:flutter/material.dart';

/// IndexedStack (keeps tab state) with a soft cross-fade on tab change.
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const FadeIndexedStack({super.key, required this.index, required this.children});
  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 240), value: 1);

  @override
  void didUpdateWidget(covariant FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _c.forward(from: 0.3);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
        child: IndexedStack(index: widget.index, children: widget.children),
      );
}
