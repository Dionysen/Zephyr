import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/models/app_info.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_theme.dart';

class AboutSettingsView extends StatefulWidget {
  const AboutSettingsView({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  State<AboutSettingsView> createState() => _AboutSettingsViewState();
}

class _AboutSettingsViewState extends State<AboutSettingsView> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  Future<void> _openGitHub() async {
    final uri = Uri.parse(AppInfo.githubUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.aboutOpenLinkFailed)),
      );
    }
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.aboutCheckUpdatesComingSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<PackageInfo>(
          future: _packageInfo,
          builder: (context, snapshot) {
            final info = snapshot.data;
            final version = info == null
                ? '…'
                : info.buildNumber.isEmpty
                ? info.version
                : '${info.version} (${info.buildNumber})';
            return _AboutHeader(
              appName: l10n.appTitle,
              versionLabel: l10n.aboutVersionLabel(version),
            );
          },
        ),
        const SizedBox(height: 12),
        ZephyrSettingsSection(
          children: [
            ZephyrSettingsListTile(
              title: l10n.aboutGitHubTitle,
              subtitle: AppInfo.githubDisplayHost,
              onTap: _openGitHub,
              trailing: Icon(
                Icons.open_in_new,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            ZephyrSettingsListTile(
              title: l10n.aboutCheckUpdatesTitle,
              subtitle: l10n.aboutCheckUpdatesSubtitle,
              showDivider: false,
              onTap: _checkForUpdates,
            ),
          ],
        ),
      ],
    );

    if (widget.compact) {
      return body;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      children: [
        Text(
          l10n.settingsSectionAbout,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        body,
      ],
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader({
    required this.appName,
    required this.versionLabel,
  });

  final String appName;
  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.zephyrCornerRadius;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius.clamp(12, 22)),
            child: Image.asset(
              AppInfo.iconAsset,
              width: 72,
              height: 72,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            appName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            versionLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
