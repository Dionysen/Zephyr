import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// GitHub-flavored Markdown for in-app surfaces (no raw HTML blocks).
class ZephyrMarkdownBody extends StatefulWidget {
  const ZephyrMarkdownBody({
    super.key,
    required this.data,
    required this.foreground,
    this.baseStyle,
    this.dense = false,
    this.selectable = true,
    /// Throttle re-parses while [data] changes rapidly (e.g. LLM streaming).
    this.liveStream = false,
  });

  final String data;
  final Color foreground;
  final TextStyle? baseStyle;
  final bool dense;
  final bool selectable;
  final bool liveStream;

  static final _extensionSet = md.ExtensionSet.gitHubFlavored;

  @override
  State<ZephyrMarkdownBody> createState() => _ZephyrMarkdownBodyState();
}

class _ZephyrMarkdownBodyState extends State<ZephyrMarkdownBody> {
  static const _streamThrottle = Duration(milliseconds: 90);

  MarkdownStyleSheet? _styleSheet;
  String _renderedData = '';
  Timer? _streamTimer;

  @override
  void initState() {
    super.initState();
    _renderedData = widget.data;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildStyleSheet();
  }

  @override
  void didUpdateWidget(covariant ZephyrMarkdownBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.foreground != widget.foreground ||
        oldWidget.baseStyle != widget.baseStyle ||
        oldWidget.dense != widget.dense) {
      _rebuildStyleSheet();
    }
    if (oldWidget.data == widget.data &&
        oldWidget.liveStream == widget.liveStream) {
      return;
    }
    if (!widget.liveStream) {
      _streamTimer?.cancel();
      setState(() => _renderedData = widget.data);
      return;
    }
    _streamTimer?.cancel();
    _streamTimer = Timer(_streamThrottle, () {
      if (!mounted) return;
      setState(() => _renderedData = widget.data);
    });
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  void _rebuildStyleSheet() {
    final theme = Theme.of(context);
    final base =
        widget.baseStyle ??
        (widget.dense
                ? theme.textTheme.bodySmall
                : theme.textTheme.bodyMedium)!
            .copyWith(
              color: widget.foreground,
              height: widget.dense ? 1.4 : 1.45,
            );
    _styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: base,
      pPadding: EdgeInsets.zero,
      h1: base.copyWith(
        fontSize: base.fontSize! * 1.35,
        fontWeight: FontWeight.w600,
      ),
      h2: base.copyWith(
        fontSize: base.fontSize! * 1.22,
        fontWeight: FontWeight.w600,
      ),
      h3: base.copyWith(
        fontSize: base.fontSize! * 1.1,
        fontWeight: FontWeight.w600,
      ),
      h4: base.copyWith(fontWeight: FontWeight.w600),
      h5: base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: base.fontSize! * 0.95,
      ),
      h6: base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: base.fontSize! * 0.9,
      ),
      h1Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h2Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h3Padding: const EdgeInsets.only(top: 6, bottom: 2),
      listBullet: base,
      listIndent: 20,
      blockquote: base.copyWith(
        color: widget.foreground.withValues(alpha: 0.85),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.45),
            width: 3,
          ),
        ),
      ),
      code: base.copyWith(
        fontFamily: 'monospace',
        fontSize: (base.fontSize ?? 14) * 0.92,
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.7,
        ),
      ),
      codeblockPadding: const EdgeInsets.all(10),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      a: base.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary.withValues(alpha: 0.5),
      ),
      tableHead: base.copyWith(fontWeight: FontWeight.w600),
      tableBody: base,
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      tableBorder: TableBorder.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _styleSheet;
    if (sheet == null) return const SizedBox.shrink();

    final markdown = MarkdownBody(
      data: _renderedData,
      selectable: false,
      shrinkWrap: true,
      fitContent: true,
      extensionSet: ZephyrMarkdownBody._extensionSet,
      styleSheet: sheet,
      onTapLink: (text, href, title) {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
      },
    );

    if (!widget.selectable) return markdown;

    final theme = Theme.of(context);
    final base =
        widget.baseStyle ??
        (widget.dense
                ? theme.textTheme.bodySmall
                : theme.textTheme.bodyMedium)!
            .copyWith(
              color: widget.foreground,
              height: widget.dense ? 1.4 : 1.45,
            );

    // One [SelectableText] holds the full source so drag / Ctrl+A spans the
    // whole bubble; rendered markdown is painted on top for display only.
    return SelectionArea(
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          SelectableText(
            _renderedData,
            style: base.copyWith(color: Colors.transparent),
          ),
          IgnorePointer(child: markdown),
        ],
      ),
    );
  }
}
