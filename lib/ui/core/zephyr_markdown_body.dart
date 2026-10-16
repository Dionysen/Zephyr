import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import 'zephyr_scrollbar_style.dart';

class _HorizontalCodeBlockScroll extends StatefulWidget {
  const _HorizontalCodeBlockScroll({
    required this.contentPadding,
    required this.child,
  });

  /// Insets for code text (not the horizontal scrollbar track).
  final EdgeInsetsGeometry contentPadding;
  final Widget child;

  @override
  State<_HorizontalCodeBlockScroll> createState() =>
      _HorizontalCodeBlockScrollState();
}

/// Bottom-aligned horizontal thumb (Material [Scrollbar] leaves a visible gap).
class _CodeBlockHorizontalThumb extends StatelessWidget {
  const _CodeBlockHorizontalThumb({
    required this.controller,
    required this.color,
    required this.thickness,
  });

  final ScrollController controller;
  final Color color;
  final double thickness;

  static const _minThumbLength = 24.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.hasClients) {
          return SizedBox(height: thickness);
        }
        final position = controller.positions.first;
        if (!position.hasContentDimensions) {
          return SizedBox(height: thickness);
        }
        final viewport = position.viewportDimension;
        if (position.maxScrollExtent <= 0.5 || !viewport.isFinite) {
          return SizedBox(height: thickness);
        }

        final total = position.maxScrollExtent + viewport;
        final thumbWidth = math.max(
          _minThumbLength,
          viewport * viewport / total,
        );
        final track = viewport - thumbWidth;
        final thumbLeft = track <= 0
            ? 0.0
            : (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0) *
                track;

        return SizedBox(
          height: thickness,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: thumbLeft,
                width: thumbWidth,
                bottom: 0,
                height: thickness,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(thickness),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HorizontalCodeBlockScrollState extends State<_HorizontalCodeBlockScroll> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumbColor = ZephyrScrollbarStyle.editorThumbColor(scheme);
    final thumb = ZephyrScrollbarStyle.horizontalThumbThickness;
    final contentPad = widget.contentPadding.resolve(Directionality.of(context));
    final textPad = EdgeInsets.fromLTRB(
      contentPad.left,
      contentPad.top,
      contentPad.right,
      thumb,
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Padding(
              padding: textPad,
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                child: widget.child,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: thumb,
              child: _CodeBlockHorizontalThumb(
                controller: _controller,
                color: thumbColor,
                thickness: thumb,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fenced code blocks: horizontal scroll inside vertical parents (e.g. chat list).
class _ZephyrPreBlockBuilder extends MarkdownElementBuilder {
  _ZephyrPreBlockBuilder({
    required this.styleSheet,
    required this.selectable,
  });

  final MarkdownStyleSheet styleSheet;
  final bool selectable;

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final code = text.text.replaceAll(RegExp(r'\n$'), '');
    if (code.isEmpty) return const SizedBox.shrink();

    final style = styleSheet.code ?? preferredStyle;
    final body = selectable
        ? SelectableText(code, style: style)
        : Text(code, style: style, softWrap: false);

    final sheetPad =
        styleSheet.codeblockPadding ?? const EdgeInsets.all(10);
    final contentPadding = EdgeInsets.fromLTRB(
      sheetPad.left,
      sheetPad.top,
      sheetPad.right,
      0,
    );

    return _HorizontalCodeBlockScroll(
      contentPadding: contentPadding,
      child: body,
    );
  }
}

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

    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      child: MarkdownBody(
        data: _renderedData,
        selectable: widget.selectable,
        shrinkWrap: true,
        // Stretch to the bubble width so fenced code blocks get a bounded
        // viewport and can scroll horizontally instead of overflowing.
        fitContent: false,
        extensionSet: ZephyrMarkdownBody._extensionSet,
        styleSheet: sheet,
        builders: {
          'pre': _ZephyrPreBlockBuilder(
            styleSheet: sheet,
            selectable: widget.selectable,
          ),
        },
        onTapLink: (text, href, title) {
          if (href == null) return;
          final uri = Uri.tryParse(href);
          if (uri == null) return;
          unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
        },
      ),
    );
  }
}
