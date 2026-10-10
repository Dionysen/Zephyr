import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_l10n.dart';
import '../view_models/library_view_model.dart';

Future<void> showArticleHistorySheet(
  BuildContext context, {
  required LibraryViewModel model,
  required String articleId,
}) async {
  final l10n = context.l10n;
  final history = await model.listHistory(articleId);
  if (!context.mounted) return;
  if (history.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.historyEmpty)),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        final theme = Theme.of(context);
        final format = DateFormat.yMMMd().add_Hm();
        return ZephyrBottomSheet.listTheme(
          context: context,
          child: Column(
            children: [
              Padding(
                padding: ZephyrBottomSheet.titlePadding,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.historyTitle,
                    style: ZephyrBottomSheet.titleStyle(theme),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: history.length,
                  separatorBuilder: (context, _) =>
                      ZephyrBottomSheet.rowDivider(context),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final preview = item.content.trim().isEmpty
                        ? l10n.historyEmptyRevision
                        : item.content;
                    return ListTile(
                      title: Text(format.format(item.createdAt)),
                      subtitle: Text(
                        preview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.historyRestoreTitle),
                            content: Text(l10n.historyRestoreBody),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.actionCancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(l10n.historyRestoreAction),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !context.mounted) return;
                        await model.restoreHistoryRevision(
                          articleId: articleId,
                          createdAt: item.createdAt,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.historyRestoreSuccess)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
