import 'package:flutter/material.dart';

import '../../../core/zephyr_l10n.dart';
import 'quick_toolbar_bar.dart';

/// Placeholder panel that occupies the soft-keyboard region while tools are open.
class QuickToolbarDrawer extends StatelessWidget {
  const QuickToolbarDrawer({
    super.key,
    required this.height,
    required this.foreground,
    required this.onEditToolbar,
  });

  final double height;
  final Color foreground;
  final VoidCallback onEditToolbar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: quickToolbarBackground,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onEditToolbar,
                icon: Icon(Icons.edit_outlined, size: 18, color: foreground),
                label: Text(
                  context.l10n.quickToolbarEdit,
                  style: TextStyle(color: foreground),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: foreground,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  context.l10n.quickToolbarDrawerEmpty,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
