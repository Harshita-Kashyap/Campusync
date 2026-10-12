import 'package:flutter/material.dart';

/// Standard scrolling page: same padding everywhere, centred and width-capped on tablets.
class PageBody extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  const PageBody({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32)});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: ListView(padding: padding, children: children),
        ),
      );
}
