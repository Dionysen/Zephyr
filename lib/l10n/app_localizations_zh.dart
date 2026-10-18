// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Zephyr';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '保存';

  @override
  String get actionDelete => '删除';

  @override
  String get actionDone => '完成';

  @override
  String get actionRename => '重命名';

  @override
  String get actionBack => '返回';

  @override
  String get untitled => '未命名';

  @override
  String get untitledLibrary => '未命名书库';

  @override
  String get temporaryLibraryName => '临时书库';

  @override
  String get platformDefaultFont => '霞鹜文楷（默认）';

  @override
  String get searchHint => '搜索';

  @override
  String get dropdownHintSelect => '请选择';

  @override
  String get dropdownNoMatches => '无匹配项';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSubtitle => '应用界面显示语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsDesktopHeader => '设置';

  @override
  String get settingsSearchHint => '搜索设置';

  @override
  String get settingsBackTooltip => '返回';

  @override
  String get settingsCustomColorsTitle => '自定义颜色';

  @override
  String get settingsComingSoonTitle => '即将推出';

  @override
  String get settingsComingSoonSubtitle => '这里的选项还在准备中';

  @override
  String get settingsPlaceholderBody => '相关选项稍后会出现在这里';

  @override
  String get settingsSectionGeneral => '通用';

  @override
  String get settingsSectionCloud => '备份与同步';

  @override
  String get backupGroupLocalTitle => '本地备份';

  @override
  String get backupGroupCloudTitle => '云同步';

  @override
  String get cloudSyncSubtitleSignedOut => '连接坚果云 WebDAV 后即可使用云备份与同步';

  @override
  String cloudSyncSubtitleSignedIn(String name) {
    return '已登录：$name';
  }

  @override
  String get cloudBackupQuickTooltip => '云备份';

  @override
  String get cloudBackupQuickTooltipUnconfigured => '绑定坚果云以使用云备份';

  @override
  String get cloudSyncEnableTitle => '开启云备份';

  @override
  String get cloudSyncEnableSubtitle => '退出时或移动端有改动进入后台后，将本地备份上传到坚果云';

  @override
  String get cloudSyncLoginTitle => '绑定坚果云';

  @override
  String get cloudSyncLoginSubtitle => '输入坚果云账号、WebDAV 网址和应用密码';

  @override
  String get cloudSyncSettingsTitle => '坚果云设置';

  @override
  String cloudSyncSettingsSubtitle(String name) {
    return '已登录：$name';
  }

  @override
  String get cloudSyncUnbindTitle => '解除绑定';

  @override
  String get cloudSyncLogoutTitle => '断开连接';

  @override
  String get cloudSyncLogoutSubtitle => '断开后停止云备份';

  @override
  String get cloudSyncBackupNowTitle => '立即云备份';

  @override
  String get cloudSyncBackupNowSubtitle => '先在本机做一份备份，再上传到坚果云里的 Zephyr 文件夹';

  @override
  String get cloudSyncBackupNowSuccess => '云备份已完成';

  @override
  String get cloudSyncRestoreTitle => '云备份恢复';

  @override
  String get cloudSyncRestoreSubtitle => '从坚果云选择备份，可覆盖或合并';

  @override
  String get cloudSyncRestoreEmpty => '云盘中尚未找到备份';

  @override
  String get cloudSyncLatestSnapshotTitle => '最新云备份';

  @override
  String get cloudSyncLatestSnapshotSubtitle => '坚果云上的当前快照';

  @override
  String get cloudSyncRestoreSuccess => '已从云备份恢复';

  @override
  String cloudSyncFailed(String error) {
    return '云同步失败：$error';
  }

  @override
  String get cloudSyncAnotherLibrary =>
      '云端 Zephyr 目录属于另一文库。请选择原本地目录或其他 WebDAV 账号；云同步已停止。';

  @override
  String get cloudSyncMissingManifest => '云端的 Zephyr 文件夹不完整，请先整理后再同步。';

  @override
  String get cloudSyncWaitBeforeChoosingDirectory => '请等待云同步完成后再选择其他目录。';

  @override
  String get cloudSyncCredentialsTitle => '连接坚果云 WebDAV';

  @override
  String get cloudSyncCredentialsEditTitle => '坚果云设置';

  @override
  String get cloudSyncCredentialsSubtitle =>
      '请使用坚果云第三方应用密码，而非账号登录密码。凭据安全保存在本机。';

  @override
  String get cloudSyncCredentialsPasswordHint => '留空则保持当前应用密码不变';

  @override
  String get cloudSyncCredentialsSave => '连接';

  @override
  String get cloudSyncCredentialsSaveEdit => '保存';

  @override
  String get cloudSyncCredentialsSaved => '坚果云已连接';

  @override
  String get cloudSyncCredentialsUpdated => '坚果云设置已保存';

  @override
  String get cloudSyncClientIdLabel => '坚果云账号';

  @override
  String get cloudSyncServerUrlLabel => 'WebDAV 网址';

  @override
  String get cloudSyncClientSecretLabel => '应用密码';

  @override
  String get backupAutoTitle => '自动备份';

  @override
  String get backupAutoSubtitle => '内容有变更时每小时自动备份；移动端进入后台时也会备份。本地共保留最近 25 份';

  @override
  String get backupNowTitle => '立即备份';

  @override
  String get backupNowSubtitle => '立刻做一份手动备份。手动和自动备份一共保留最近 25 份';

  @override
  String get backupNowSuccess => '备份已完成';

  @override
  String backupFailed(String error) {
    return '备份失败：$error';
  }

  @override
  String saveFailed(String error) {
    return '保存失败，编辑仍在当前窗口中；退出前请重试：$error';
  }

  @override
  String get exitBackupInProgress => '正在保存…';

  @override
  String get backupRestoreTitle => '恢复备份';

  @override
  String backupRestoreSubtitle(int count) {
    return '共 $count 份备份，可覆盖或合并';
  }

  @override
  String get backupRestoreEmpty => '还没有找到备份文件';

  @override
  String get backupRestoreModeTitle => '恢复方式';

  @override
  String get backupRestoreModeMerge => '合并（保留较新的内容）';

  @override
  String get backupRestoreModeOverwrite => '覆盖（替换整个文库）';

  @override
  String get backupRestoreConfirmTitle => '确认恢复';

  @override
  String get backupRestoreConfirmMerge => '将把所选备份与当前文库合并。恢复前会先创建一份安全备份。';

  @override
  String get backupRestoreConfirmOverwrite => '将用所选备份完整替换当前文库。恢复前会先创建一份安全备份。';

  @override
  String get backupRestoreAction => '恢复';

  @override
  String get backupRestoreSuccess => '已从备份恢复';

  @override
  String get backupMergeResultTitle => '合并完成';

  @override
  String get backupMergeResultSeparator => '，';

  @override
  String get backupMergeResultNoChanges => '合并完成，章节无变化';

  @override
  String backupMergeResultAdded(int count) {
    return '新增 $count 篇';
  }

  @override
  String backupMergeResultUpdated(int count) {
    return '更新 $count 篇';
  }

  @override
  String backupMergeResultRemoved(int count) {
    return '删除 $count 篇';
  }

  @override
  String get backupKindAuto => '自动';

  @override
  String get backupKindManual => '手动';

  @override
  String get backupFooter => '请不要和纯纯写作同时打开同一书库。备份可以在纯纯写作里打开。';

  @override
  String get historyTitle => '时光机';

  @override
  String get historyEmpty => '暂无历史版本';

  @override
  String get historyEmptyRevision => '（空内容）';

  @override
  String get historyRestoreTitle => '恢复此版本？';

  @override
  String get historyRestoreBody => '当前正文将替换为所选历史版本，并记入时光机。';

  @override
  String get historyRestoreAction => '恢复';

  @override
  String get historyRestoreSuccess => '已恢复到所选版本';

  @override
  String get historyMenuLabel => '时光机';

  @override
  String get draftRecoverTitle => '发现未保存草稿';

  @override
  String get draftRecoverBody => '检测到比文库更新的草稿，是否恢复？';

  @override
  String get draftRecoverAction => '恢复';

  @override
  String get draftDismissAction => '丢弃';

  @override
  String get settingsSectionEditor => '编辑器';

  @override
  String get settingsSectionShortcuts => '快捷键';

  @override
  String get shortcutsManageTitle => '自定义快捷键';

  @override
  String get shortcutsManageSubtitle => '查看与修改按键绑定';

  @override
  String get shortcutsResetAll => '全部恢复默认';

  @override
  String get shortcutsResetAction => '恢复默认';

  @override
  String get shortcutsClearAction => '清除';

  @override
  String get shortcutsRecordTitle => '按下新的快捷键';

  @override
  String get shortcutsRecordHint => 'Esc 取消 · Backspace 清除';

  @override
  String get shortcutsUnbound => '未绑定';

  @override
  String get shortcutsConflictHint => '已覆盖冲突的快捷键';

  @override
  String get shortcutGroupClipboard => '剪贴板';

  @override
  String get shortcutGroupHistory => '历史';

  @override
  String get shortcutGroupDelete => '删除';

  @override
  String get shortcutGroupIndent => '缩进';

  @override
  String get shortcutGroupNewline => '换行';

  @override
  String get shortcutGroupNavigate => '导航';

  @override
  String get shortcutGroupSelect => '选择';

  @override
  String get shortcutGroupWorkspace => '工作区';

  @override
  String get shortcutActionCopy => '复制';

  @override
  String get shortcutActionCut => '剪切';

  @override
  String get shortcutActionPaste => '粘贴';

  @override
  String get shortcutActionSelectAll => '全选';

  @override
  String get shortcutActionUndo => '撤销';

  @override
  String get shortcutActionRedo => '重做';

  @override
  String get shortcutActionDeleteBackward => '向前删除';

  @override
  String get shortcutActionDeleteForward => '向后删除';

  @override
  String get shortcutActionDeleteWordBackward => '删除前一词';

  @override
  String get shortcutActionDeleteWordForward => '删除后一词';

  @override
  String get shortcutActionIndent => '增加缩进';

  @override
  String get shortcutActionOutdent => '减少缩进';

  @override
  String get shortcutActionNewline => '换行';

  @override
  String get shortcutActionMoveLeft => '左移';

  @override
  String get shortcutActionMoveRight => '右移';

  @override
  String get shortcutActionMoveUp => '上移';

  @override
  String get shortcutActionMoveDown => '下移';

  @override
  String get shortcutActionMoveWordLeft => '左移一词';

  @override
  String get shortcutActionMoveWordRight => '右移一词';

  @override
  String get shortcutActionMoveLineStart => '行首';

  @override
  String get shortcutActionMoveLineEnd => '行末';

  @override
  String get shortcutActionMovePageUp => '上一页';

  @override
  String get shortcutActionMovePageDown => '下一页';

  @override
  String get shortcutActionMoveDocumentStart => '文首';

  @override
  String get shortcutActionMoveDocumentEnd => '文末';

  @override
  String get shortcutActionSelectLeft => '向左选择';

  @override
  String get shortcutActionSelectRight => '向右选择';

  @override
  String get shortcutActionSelectUp => '向上选择';

  @override
  String get shortcutActionSelectDown => '向下选择';

  @override
  String get shortcutActionSelectWordLeft => '向左选一词';

  @override
  String get shortcutActionSelectWordRight => '向右选一词';

  @override
  String get shortcutActionSelectLineStart => '选至行首';

  @override
  String get shortcutActionSelectLineEnd => '选至行末';

  @override
  String get shortcutActionSelectPageUp => '向上选一页';

  @override
  String get shortcutActionSelectPageDown => '向下选一页';

  @override
  String get shortcutActionSelectDocumentStart => '选至文首';

  @override
  String get shortcutActionSelectDocumentEnd => '选至文末';

  @override
  String get shortcutActionCloseSettings => '关闭设置';

  @override
  String get shortcutActionCloudBackupNow => '立即云备份';

  @override
  String get settingsSectionTheme => '外观';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsSectionAi => 'AI';

  @override
  String get aboutSettingsListSubtitle => '版本、更新与链接';

  @override
  String aboutVersionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get aboutGitHubTitle => 'GitHub';

  @override
  String get aboutCheckUpdatesTitle => '检查更新';

  @override
  String get aboutCheckUpdatesSubtitle => '从 GitHub 获取最新版本信息';

  @override
  String get aboutCheckUpdatesComingSoon => '更新检查即将推出';

  @override
  String get aboutOpenLinkFailed => '无法打开链接';

  @override
  String get generalSectionTitle => '通用';

  @override
  String get immersiveStatusBarTitle => '沉浸式通知栏';

  @override
  String get immersiveStatusBarSubtitle => '开启后，界面会延伸到透明通知栏下面，正文可以滑进这块区域';

  @override
  String get hideStatusBarIconsTitle => '隐藏通知栏图标';

  @override
  String get hideStatusBarIconsSubtitle => '仅在沉浸式通知栏开启时生效，图标自动隐藏，边缘滑动可临时显示';

  @override
  String get mobileBehaviorSectionTitle => '移动端';

  @override
  String get mobileBehaviorSectionSubtitle => '仅影响手机和平板上的紧凑编辑界面。';

  @override
  String get scrollToHideMobileTopBarTitle => '滚动以隐藏顶栏';

  @override
  String get scrollToHideMobileTopBarSubtitle => '向下阅读时收起浮动书名栏，向上滚动时再次显示。';

  @override
  String get openSidebarAfterBookSwitchTitle => '切换书籍后打开文章列表';

  @override
  String get openSidebarAfterBookSwitchSubtitle => '选择另一本书后自动展开侧栏章节列表。';

  @override
  String get keepScreenOnTitle => '屏幕常亮';

  @override
  String get keepScreenOnSubtitle => '应用在前台时保持屏幕点亮。';

  @override
  String get doubleBackToExitTitle => '双击返回键退出应用';

  @override
  String get doubleBackToExitSubtitle => '关闭后，按一次返回就会离开应用。';

  @override
  String get openBookListOnStartupTitle => '启动时打开书籍列表';

  @override
  String get openBookListOnStartupSubtitle => '进入工作区后自动打开书籍选择面板。';

  @override
  String get openSidebarOnStartupTitle => '启动时打开文章列表';

  @override
  String get openSidebarOnStartupSubtitle => '进入工作区后自动展开侧栏章节列表。';

  @override
  String get pressBackAgainToExit => '再按一次返回键退出';

  @override
  String get aiFeaturesEnabledTitle => 'AI 助手';

  @override
  String get aiFeaturesEnabledSubtitle => '关闭后，工作区顶栏不再显示 AI 按钮，已打开的助手会回到书籍界面。';

  @override
  String get hideAiAssistantAvatarTitle => '隐藏助手头像';

  @override
  String get hideAiAssistantAvatarSubtitle => '开启后不再显示头像，气泡两边对齐。';

  @override
  String get hideQuickToolbarTitle => '隐藏快捷输入栏';

  @override
  String get hideQuickToolbarSubtitle => '开启后，键盘上方不再显示快捷工具栏';

  @override
  String get showChapterDetailsTitle => '显示章节详细信息';

  @override
  String get showChapterDetailsSubtitle => '关闭后侧边栏只显示章节名，不显示预览与时间、字数等信息';

  @override
  String get editorSectionTitle => '编辑器';

  @override
  String get editorSectionIntro => '字体与阅读栏偏好会立即生效';

  @override
  String get editorSectionFooter => '更改会立即应用到写作区';

  @override
  String get editorFontLabel => '字体';

  @override
  String get editorFontDescription => '写作时使用的字体。导入后，界面也可以选用';

  @override
  String get editorFontSizeTitle => '字体大小';

  @override
  String get editorFontSizeDescription => '写作区正文字号';

  @override
  String get editorTitleSizeTitle => '标题字号';

  @override
  String get editorTitleSizeDescription => '文章标题块字号';

  @override
  String get editorTitleCenteredTitle => '标题居中';

  @override
  String get editorTitleCenteredSubtitle => '开则居中，关则与正文左边界对齐';

  @override
  String get editorTypewriterModeTitle => '打字机模式';

  @override
  String get editorTypewriterModeSubtitle =>
      '开启后当前编辑行保持在屏幕中央；非当前段落与未聚焦的标题半透明显示';

  @override
  String get editorJumpToEndOnScrollDownTitle => '向下滚动时显示「聚焦到文末」';

  @override
  String get editorJumpToEndOnScrollDownSubtitle =>
      '开启后向下滚动时出现该按钮；滚到底部或向上滚动时隐藏';

  @override
  String get editorLineHeightTitle => '行高';

  @override
  String get editorLineHeightDescription => '段内行距倍数';

  @override
  String get editorParagraphSpacingTitle => '段间距';

  @override
  String get editorParagraphSpacingDescription => '段落之间的间距（字号倍数）';

  @override
  String get editorFirstLineIndentTitle => '首行缩进';

  @override
  String get editorFirstLineIndentDescription =>
      'Tab 插入的缩进宽度，打开章节时也会应用，回车会复制上一段缩进';

  @override
  String get editorMarginLeftTitle => '左边距';

  @override
  String get editorMarginLeftDescription => '正文左侧边距，空间不足时与右边距按比例缩小';

  @override
  String get editorMarginRightTitle => '右边距';

  @override
  String get editorMarginRightDescription => '正文右侧边距，与左边距相等时始终严格对称';

  @override
  String get editorWidthTitle => '编辑器宽度';

  @override
  String get editorWidthDescription => '正文区域的宽度，在窗口里始终居中。窗口变窄时会一起变窄';

  @override
  String get appearanceSectionTitle => '外观';

  @override
  String get appearanceSectionIntro => '选择一套配色，也可以逐项调整颜色。字体和圆角保持你单独的设置';

  @override
  String get themeModeTitle => '主题模式';

  @override
  String get themeModeSubtitle => '选择浅色、深色，或跟随系统外观';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get uiFontLabel => 'UI 字体';

  @override
  String get uiFontDescription => '界面和侧边栏使用的字体。导入后，正文也可以选用';

  @override
  String get uiFontSizeTitle => 'UI 字体大小';

  @override
  String get uiFontSizeDescription => '侧边栏、设置与界面文字大小';

  @override
  String get cornerRadiusTitle => '圆角';

  @override
  String get cornerRadiusDescription => '按钮、菜单、卡片与输入框的圆角';

  @override
  String get barCornerRadiusTitle => '栏圆角';

  @override
  String get barCornerRadiusDescription => '编辑器顶部栏和侧边栏底部栏的圆角';

  @override
  String get chatBubbleCornerRadiusTitle => '对话气泡圆角';

  @override
  String get chatBubbleCornerRadiusDescription => 'AI 对话气泡的圆角。靠外侧的上角保持直角';

  @override
  String get showBordersTitle => '显示边框';

  @override
  String get showBordersSubtitle => '关闭后按钮和卡片没有边框。开启后，卷和书库栏会显示边框';

  @override
  String get sidebarItemInsetTitle => '侧边栏条目边距';

  @override
  String get sidebarItemInsetDescription => '卷与章节左右边距（相等）';

  @override
  String get sidebarItemCornerRadiusTitle => '侧边栏卷与章节圆角';

  @override
  String get sidebarItemCornerRadiusDescription => '书库侧栏中卷标题与章节行的圆角';

  @override
  String get sidebarVolumeGapTitle => '侧边栏内容上下间距';

  @override
  String get sidebarVolumeGapDescription => '卷与卷之间的间距。章节之间只留一条分隔线';

  @override
  String get themePresetsSectionTitle => '主题颜色';

  @override
  String get actionCopy => '复制';

  @override
  String get themePackRenameTitle => '重命名主题';

  @override
  String themePackCopyName(String name) {
    return '$name 副本';
  }

  @override
  String get themePackDeleteTitle => '删除主题？';

  @override
  String themePackDeleteBody(String name) {
    return '删除「$name」后无法恢复';
  }

  @override
  String get themeCurrentCustom => '当前：自定义';

  @override
  String themeCurrentPreset(String preset) {
    return '当前：$preset';
  }

  @override
  String get themeCurrentCustomLong => '当前配色：自定义';

  @override
  String themeCurrentPresetLong(String preset) {
    return '当前配色：$preset';
  }

  @override
  String get themePresetsFooter => '配色只改变颜色。字体、圆角等保持你单独的设置';

  @override
  String get customColorsTitle => '自定义颜色';

  @override
  String get customColorsSubtitle => '调整当前外观下的各项颜色，修改后立即生效';

  @override
  String get customizeTokensButton => '自定义颜色';

  @override
  String get backToThemesButton => '返回主题';

  @override
  String get themeTokensTitle => '主题色';

  @override
  String get themeTokensIntro => '填写颜色代码，例如 #336699。修改后立即生效';

  @override
  String get restoreDefaultColors => '恢复默认';

  @override
  String get saveAsThemeColor => '保存为主题';

  @override
  String get saveThemeColorTitle => '保存为主题颜色';

  @override
  String get saveThemeColorNameLabel => '主题名称';

  @override
  String themePackNameDefault(int n) {
    return '主题$n';
  }

  @override
  String get themePresetLight => '浅色';

  @override
  String get themePresetGrey => '灰色';

  @override
  String get themePresetSlate => '石板';

  @override
  String get themePresetClaude => 'Claude Code';

  @override
  String get themePresetMint => '薄荷';

  @override
  String get themePresetPurple => '紫色';

  @override
  String get themePresetHermes => 'Hermes';

  @override
  String get themePresetOcean => '海洋';

  @override
  String get themePresetDarkModern => '深色现代';

  @override
  String get tokenEditorSurface => '写作区背景';

  @override
  String get tokenSidebarSurface => '侧边栏背景';

  @override
  String get tokenControlSurface => '按钮和输入框';

  @override
  String get tokenBorder => '边框';

  @override
  String get tokenDivider => '分割线';

  @override
  String get tokenPrimaryText => '主文字';

  @override
  String get tokenMutedText => '次要文字';

  @override
  String get tokenAccent => '强调色';

  @override
  String get tokenCursor => '光标';

  @override
  String get tokenEditorSurfaceDescription => '写作栏背景色';

  @override
  String get tokenSidebarSurfaceDescription => '侧栏与界面背景色';

  @override
  String get tokenControlSurfaceDescription => '输入框、菜单与卡片的填充色';

  @override
  String get tokenBorderDescription => '按钮和输入框的边框';

  @override
  String get tokenDividerDescription => '侧边栏章节分隔线';

  @override
  String get tokenPrimaryTextDescription => '默认标题与正文字色';

  @override
  String get tokenMutedTextDescription => '设置说明与说明文字的较淡色';

  @override
  String get tokenAccentDescription => '按钮高亮和选中状态';

  @override
  String get tokenCursorDescription => '写作区光标颜色';

  @override
  String get fontImportSuccess => '已导入到应用字体库，可在 UI 与正文字体中选用';

  @override
  String get fontImportFailure => '无法导入该字体文件';

  @override
  String get fontDeleteSuccess => '已从应用字体库删除';

  @override
  String get fontDeleteFailure => '无法删除该字体';

  @override
  String get fontImportFromFile => '从文件导入…';

  @override
  String get fontDeleteFromLibrary => '从字体库删除';

  @override
  String get fontDeleteDialogTitle => '删除字体？';

  @override
  String fontDeleteDialogBody(String family) {
    return '从应用字体库中移除“$family”以释放空间？';
  }

  @override
  String get fontDeleteDialogBodyCompact => '从应用字体库中移除以释放空间？';

  @override
  String get editorBackgroundSectionTitle => '编辑器背景图片';

  @override
  String get editorBackgroundEnabledTitle => '使用背景图片';

  @override
  String get editorBackgroundEnabledSubtitle => '关闭后暂不显示，已选图片会保留';

  @override
  String get themeColorsSectionTitle => '主题颜色';

  @override
  String get editorBackgroundLightTitle => '亮色背景';

  @override
  String get editorBackgroundDarkTitle => '暗色背景';

  @override
  String get editorBackgroundNone => '未设置';

  @override
  String get editorBackgroundCurrentBadge => '当前';

  @override
  String get editorBackgroundChoose => '选择';

  @override
  String get editorBackgroundClear => '清除';

  @override
  String get editorBackgroundSelectTitle => '选择背景图';

  @override
  String get editorBackgroundAddFromFile => '从文件添加…';

  @override
  String get editorBackgroundEmptyLibrary => '还没有图片，点上方添加';

  @override
  String get editorBackgroundNoImagePreview => '无背景图';

  @override
  String get editorBackgroundPreviewSample => '轻舟已过万重山。\n人不可有傲气，但不可无傲骨。';

  @override
  String get editorBackgroundFitTitle => '铺放方式';

  @override
  String get editorBackgroundFitCover => '覆盖';

  @override
  String get editorBackgroundFitContain => '包含';

  @override
  String get editorBackgroundFitFill => '拉伸';

  @override
  String get editorBackgroundFitTile => '平铺';

  @override
  String get editorBackgroundFitCenter => '居中';

  @override
  String get editorBackgroundOpacityTitle => '背景不透明度';

  @override
  String get editorBackgroundBlurTitle => '背景模糊';

  @override
  String get editorBackgroundBlurDescription => '只模糊背景图，文字保持清晰';

  @override
  String get editorBackgroundImportSuccess => '已添加到应用图库';

  @override
  String get editorBackgroundImportFailure => '无法导入该图片';

  @override
  String get editorBackgroundDeleteSuccess => '已从应用图库删除';

  @override
  String get editorBackgroundDeleteFailure => '无法删除该图片';

  @override
  String get editorBackgroundDeleteTitle => '删除图片？';

  @override
  String editorBackgroundDeleteBody(String name) {
    return '删除「$name」？正在使用的模式将恢复为无背景。';
  }

  @override
  String editorBackgroundSummary(String name, String fit, int opacity) {
    return '$name · $fit · $opacity%';
  }

  @override
  String editorBackgroundSummaryWithBlur(
    String name,
    String fit,
    int opacity,
    int blur,
  ) {
    return '$name · $fit · $opacity% · 模糊 $blur';
  }

  @override
  String get choiceDeleteTitle => '删除？';

  @override
  String get choiceDeleteBody => '移除此项？';

  @override
  String numberPickerDefaultLabel(String value) {
    return '默认 $value';
  }

  @override
  String numberPickerRestoreDefault(String value) {
    return '恢复默认（$value）';
  }

  @override
  String get tempLibraryBannerTitle => '当前使用临时书库';

  @override
  String get tempLibraryBannerSubtitle => '选择 PureWriter 书库目录以打开你的作品';

  @override
  String get chooseLibraryButton => '选择书库';

  @override
  String get librarySetupTitle => '欢迎使用 Zephyr';

  @override
  String get librarySetupBody => '可直接在本地临时书库开始写作，准备好后再连接纯纯写作的书库文件夹。';

  @override
  String get startTemporaryLibraryButton => '开始写作';

  @override
  String get libraryLoadFailedHint => '无法打开上次的书库。可以重新开始，或选择其他书库目录。';

  @override
  String get libraryRecoveredToTemporary =>
      '已改用临时书库。你仍可通过顶部横幅重新连接 PureWriter 书库。';

  @override
  String get chooseLibraryDirectoryButton => '选择 PureWriter 书库';

  @override
  String get editorEmptyState => '选择或创建章节以开始写作';

  @override
  String get jumpToEnd => '聚焦到文末';

  @override
  String get volumeInsertBelow => '下方插入卷';

  @override
  String get volumeAppendChapter => '在卷末尾插入章节';

  @override
  String get chapterInsertBelow => '下方插入章节';

  @override
  String get actionMoveToVolume => '移动到卷';

  @override
  String get actionMoveToBook => '移动到书';

  @override
  String get actionConvertVolumeToBook => '将此卷转化为一本书';

  @override
  String get moveToBookSheetTitle => '移动到书';

  @override
  String get moveToBookNoTargets => '没有可移动到的其他书。';

  @override
  String get renameVolumeTitle => '重命名卷';

  @override
  String get renameChapterTitle => '重命名章节';

  @override
  String get volumeNameLabel => '卷名';

  @override
  String get chapterNameLabel => '章节名';

  @override
  String get validationNameRequired => '请输入名称';

  @override
  String get deleteChapterTitle => '删除章节';

  @override
  String deleteChapterBody(String name) {
    return '将“$name”移入回收站？';
  }

  @override
  String get deleteVolumeTitle => '删除卷';

  @override
  String deleteVolumeBody(String name) {
    return '删除“$name”时，请选择如何处理卷内章节';
  }

  @override
  String get deleteVolumeOnly => '仅删除卷';

  @override
  String get deleteVolumeAndChapters => '删除卷及章节';

  @override
  String get moveToVolumeSheetTitle => '移动到卷';

  @override
  String get unfiledVolume => '未分卷';

  @override
  String get unfiledChaptersHeader => '未分卷章节';

  @override
  String get tooltipHideSidebar => '隐藏侧边栏';

  @override
  String get tooltipNewVolume => '新建卷';

  @override
  String get tooltipNewChapter => '新建章节';

  @override
  String get tooltipAdd => '添加';

  @override
  String get tooltipSearchChapters => '搜索';

  @override
  String get searchSheetTitle => '搜索';

  @override
  String get searchSheetHint => '搜索标题与正文';

  @override
  String get searchSheetEmptyQuery => '输入关键词开始搜索。';

  @override
  String get searchSheetNoResults => '没有匹配结果。';

  @override
  String get searchScopeArticle => '本章';

  @override
  String get searchScopeVolume => '本卷';

  @override
  String get searchScopeBook => '本书';

  @override
  String get searchScopeAllBooks => '全部书';

  @override
  String get tooltipLocateCurrentChapter => '定位到当前章节';

  @override
  String get tooltipCollapseAll => '全部折叠';

  @override
  String get tooltipExpandAll => '全部展开';

  @override
  String get tooltipReorder => '排序方式';

  @override
  String get tooltipDoneReordering => '完成调整顺序';

  @override
  String get chapterSortManual => '手动排序';

  @override
  String get chapterSortAdjustOrder => '调整顺序';

  @override
  String get chapterSortCreatedAsc => '创建时间 · 升序';

  @override
  String get chapterSortCreatedDesc => '创建时间 · 降序';

  @override
  String get chapterSortUpdatedAsc => '修改时间 · 升序';

  @override
  String get chapterSortUpdatedDesc => '修改时间 · 降序';

  @override
  String get chapterSortTitleAsc => '名称 · A→Z';

  @override
  String get chapterSortTitleDesc => '名称 · Z→A';

  @override
  String get tooltipAiAssistant => 'AI 助手';

  @override
  String get aiChatWelcome => '有什么想写的，直接发给我。';

  @override
  String get aiChatInputHint => '输入消息…';

  @override
  String get aiChatSend => '发送';

  @override
  String get aiChatStopGenerating => '停止生成';

  @override
  String get aiContextRemoveArticle => '从上下文中移除';

  @override
  String get llmSettingsTitle => 'AI 模型';

  @override
  String get llmSettingsSubtitle => '供应商、API Key 与模型';

  @override
  String get llmSettingsIntro => '密钥只保存在这台设备上。其他设置会随备份一起保存。';

  @override
  String get llmBehaviorSectionTitle => '对话行为';

  @override
  String get llmStreamOutputTitle => '流式输出';

  @override
  String get llmStreamOutputSubtitle => '回复会一边生成一边显示';

  @override
  String get llmAllowThinkingTitle => '允许思考';

  @override
  String get llmAllowThinkingSubtitle => '让可以深度思考的模型先想清楚再回答';

  @override
  String get llmPresetPromptTitle => '预设提示词';

  @override
  String get llmPresetPromptDescription => '每次对话都会作为系统说明发给模型，可固定体裁、文风、人称等偏好。';

  @override
  String get llmPresetPromptHint => '例如：你是写作助手，用简洁中文回答；续写时保持现有人称、时态与语气。';

  @override
  String get llmMaxInputTokensTitle => '上下文上限（输入）';

  @override
  String get llmMaxInputTokensSubtitle => '超出后会自动精简较早的对话';

  @override
  String get llmMaxOutputTokensTitle => '回复上限（输出）';

  @override
  String get llmMaxOutputTokensSubtitle => '单次回复最多写多长';

  @override
  String get llmThinkingLevelTitle => '思考程度';

  @override
  String get llmThinkingLevelSubtitle => '思考越深，回答通常越慢';

  @override
  String get llmDefaultThinkingLevelTitle => '默认思考程度';

  @override
  String get llmDefaultThinkingLevelSubtitle => '新对话一开始的思考程度，也可以在输入框旁边再改';

  @override
  String get llmThinkingDisabledInSettings => '请在 AI 模型设置中开启「允许思考」';

  @override
  String get llmThinkingOff => '关闭';

  @override
  String get llmThinkingMinimal => '极低';

  @override
  String get llmThinkingLow => '低';

  @override
  String get llmThinkingMedium => '中';

  @override
  String get llmThinkingHigh => '高';

  @override
  String get llmThinkingAuto => '自动';

  @override
  String get aiChatAiSettingsEntry => 'AI 设置';

  @override
  String get aiChatSessionOptionsTitle => '对话选项';

  @override
  String get aiChatSessionProviderTitle => '模型供应商';

  @override
  String get aiChatSessionProviderSubtitle => '选择已在 AI 设置中配置并测试通过的供应商';

  @override
  String get aiChatSessionOptionsNeedTest => '请先在 AI 模型设置中连接测试并获取模型列表。';

  @override
  String get aiChatSessionModelSubtitle => '可覆盖设置中的默认模型';

  @override
  String aiChatThinkingForModel(String model) {
    return '模型：$model';
  }

  @override
  String get aiChatSessionsTitle => '对话列表';

  @override
  String get aiChatSessionsSubtitle => '切换、归档或删除本章已保存的对话';

  @override
  String get aiChatNewSession => '新对话';

  @override
  String get aiChatShowArchivedSessions => '显示已归档';

  @override
  String get aiChatNoSessions => '还没有保存的对话。';

  @override
  String aiChatSessionUpdated(String time) {
    return '更新于 $time';
  }

  @override
  String get aiChatOpenSession => '打开';

  @override
  String get aiChatArchiveSession => '归档';

  @override
  String get aiChatUnarchiveSession => '取消归档';

  @override
  String get aiChatDeleteSession => '删除';

  @override
  String get aiChatDeleteSessionTitle => '删除对话？';

  @override
  String aiChatDeleteSessionBody(String title) {
    return '将删除「$title」及其全部消息，且无法恢复。';
  }

  @override
  String get aiChatCompressedContextHeader => '以下是较早对话的摘要：';

  @override
  String get llmProviderTitle => '模型供应商';

  @override
  String get llmProviderSubtitle => '可分别配置各供应商，切换时保留其他已保存的配置';

  @override
  String get llmApiKeyTitle => 'API Key';

  @override
  String get llmApiKeyHint => '粘贴密钥';

  @override
  String get llmBaseUrlTitle => 'API 地址';

  @override
  String get llmBaseUrlHint => '例如 https://api.example.com/v1';

  @override
  String get llmTestConnection => '连接测试';

  @override
  String llmTestSuccess(int count) {
    return '连接成功，发现 $count 个模型';
  }

  @override
  String get llmModelTitle => '对话模型';

  @override
  String get llmModelSubtitle => '连接测试后可选';

  @override
  String get llmModelNotSelected => '未选择';

  @override
  String get aiChatNotConfigured => '请先在设置中配置 API Key 并完成连接测试。';

  @override
  String get aiChatThinkingInProgress => '思考中…';

  @override
  String get aiChatThinkingProcess => '思考过程';

  @override
  String aiChatError(String error) {
    return '请求失败：$error';
  }

  @override
  String aiChatDemoReply(String message) {
    return '已收到：$message';
  }

  @override
  String get tooltipOpenLibrary => '打开书库';

  @override
  String get librarySwitcherChooseDirectory => '重新选择目录';

  @override
  String get tooltipOpenSidebar => '打开侧边栏';

  @override
  String get tooltipMore => '更多';

  @override
  String get mobileToolsDrawerReorderHint => '长按拖动可调整顺序';

  @override
  String get tooltipEditBook => '编辑书籍';

  @override
  String get tooltipSettings => '设置';

  @override
  String get selectBook => '选择书籍';

  @override
  String get booksSheetTitle => '书籍';

  @override
  String get booksSheetTagAll => '全部';

  @override
  String get newBookTitle => '新建书籍';

  @override
  String get moreSheetTitle => '快捷工具';

  @override
  String get mobileToolThemeMode => '主题模式';

  @override
  String get mobileToolSwitchTheme => '切换主题';

  @override
  String get noMobileTools => '暂无可用工具';

  @override
  String get editBookTitle => '编辑书籍';

  @override
  String get bookNameLabel => '书名';

  @override
  String get bookNameHint => '输入书名';

  @override
  String get bookNameRequired => '请输入书名';

  @override
  String get tooltipNewBook => '新增书籍';

  @override
  String get tooltipBookGridLayout => '双列列表';

  @override
  String get tooltipBookListLayout => '单列列表';

  @override
  String get tooltipDeleteBook => '删除书籍';

  @override
  String get deleteBookNotEmpty => '请先清空该书中的章节后再删除';

  @override
  String get bookTagsLabel => '标签';

  @override
  String get bookTagsHint => '例如：文学';

  @override
  String get bookDescriptionLabel => '简介';

  @override
  String get bookDescriptionHint => '简要说明这本书';

  @override
  String bookStatsMeta(int volumes, int chapters) {
    return '$volumes卷 $chapters章';
  }

  @override
  String chapterMeta(String created, String modified, int wordCount) {
    return '创建于$created - 修改于$modified - $wordCount字';
  }

  @override
  String get themeSlotLight => '亮色';

  @override
  String get themeSlotDark => '暗色';

  @override
  String get themePresetsSubtitle => '点按展开选择配色，会应用到当前亮色或暗色模式';

  @override
  String get quickToolbarToolsTooltip => '快捷工具';

  @override
  String get quickToolbarUndoTooltip => '撤回';

  @override
  String get quickToolbarPasteTooltip => '粘贴';

  @override
  String get quickToolbarIndentTooltip => '缩进';

  @override
  String get quickToolbarFormatTooltip => '一键格式化';

  @override
  String get quickToolbarSearchTooltip => '搜索';

  @override
  String get quickToolbarTimestampTooltip => '插入时间戳';

  @override
  String get quickToolbarBackupTooltip => '立即备份';

  @override
  String get quickToolbarRestoreTooltip => '恢复备份';

  @override
  String get quickToolbarEdit => '编辑工具栏';

  @override
  String get quickToolbarEditHint => '在工具栏上长按拖动可排序；也可在此页拖拽，或在固定栏与自定义栏之间移动。';

  @override
  String get quickToolbarPinnedSection => '固定栏';

  @override
  String get quickToolbarCustomSection => '自定义栏';

  @override
  String get quickToolbarAddSection => '添加工具';

  @override
  String get quickToolbarSectionEmpty => '暂无工具';

  @override
  String get quickToolbarAddPhrase => '快捷短语';

  @override
  String get quickToolbarPhraseName => '显示名称';

  @override
  String get quickToolbarPhraseContent => '插入内容';

  @override
  String get quickToolbarMoveToPinned => '移到固定栏';

  @override
  String get quickToolbarMoveToCustom => '移到自定义栏';

  @override
  String get quickToolbarDrawerEmpty => '这里还没有工具';

  @override
  String get quickToolbarFormatApplyAll => '一键排版';

  @override
  String get quickToolbarFormatKeepParagraphBlanks => '段间保留空行';

  @override
  String get quickToolbarFormatRemoveParagraphBlanks => '段间删除空行';

  @override
  String get quickToolbarFormatInsertCjkLatinSpaces => '中英文之间插入空格';

  @override
  String get quickToolbarFormatAddParagraphIndent => '段首插入缩进';

  @override
  String get quickToolbarFormatRemoveParagraphIndent => '去除段首缩进';

  @override
  String get quickToolbarFormatSimplifiedToTraditional => '简体转繁体';

  @override
  String get quickToolbarFormatTraditionalToSimplified => '繁体转简体';

  @override
  String get quickToolbarFormatHalfwidthToFullwidth => '半角符号转全角符号';
}
