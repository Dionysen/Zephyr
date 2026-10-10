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
  String get platformDefaultFont => '系统默认';

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
  String get settingsComingSoonSubtitle => '此分组的设置项稍后加入';

  @override
  String get settingsPlaceholderBody => '此设置分组将用于对应功能的选项';

  @override
  String get settingsSectionGeneral => '通用';

  @override
  String get settingsSectionCloud => '备份';

  @override
  String get backupAutoTitle => '自动备份';

  @override
  String get backupAutoSubtitle => '内容有变更且离开应用时写入 Backups/Auto，保留最近 25 份';

  @override
  String get backupNowTitle => '立即备份';

  @override
  String get backupNowSubtitle => '在 Backups 目录创建一份手动备份（不会被自动清理）';

  @override
  String get backupNowSuccess => '备份已完成';

  @override
  String backupFailed(String error) {
    return '备份失败：$error';
  }

  @override
  String get backupRestoreTitle => '恢复备份';

  @override
  String backupRestoreSubtitle(int count) {
    return '共 $count 份备份，可覆盖或合并';
  }

  @override
  String get backupRestoreEmpty => '尚未找到 .pwb 备份';

  @override
  String get backupRestoreModeTitle => '恢复方式';

  @override
  String get backupRestoreModeMerge => '合并（按更新时间取较新）';

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
  String get backupKindAuto => '自动';

  @override
  String get backupKindManual => '手动';

  @override
  String get backupFooter => '请勿与纯纯写作同时打开同一文库。备份为 PureWriter 兼容的 .pwb。';

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
  String get settingsSectionTheme => '外观';

  @override
  String get settingsSectionAbout => '关于';

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
  String get immersiveStatusBarSubtitle => '开启后应用延伸到透明通知栏下（控件仍留白），正文可上滑进入该区域';

  @override
  String get hideStatusBarIconsTitle => '隐藏通知栏图标';

  @override
  String get hideStatusBarIconsSubtitle => '仅在沉浸式通知栏开启时生效，图标自动隐藏，边缘滑动可临时显示';

  @override
  String get hideQuickToolbarTitle => '隐藏快捷输入栏';

  @override
  String get hideQuickToolbarSubtitle => '开启后，键盘上方不再显示快捷工具栏';

  @override
  String get editorSectionTitle => '编辑器';

  @override
  String get editorSectionIntro => '字体与阅读栏偏好会立即生效';

  @override
  String get editorSectionFooter => '更改会立即应用到写作区';

  @override
  String get editorFontLabel => '字体';

  @override
  String get editorFontDescription => '写作区正文字体，导入后与 UI 字体共用应用字体库';

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
  String get appearanceSectionTitle => '外观';

  @override
  String get appearanceSectionIntro => '选择配色，需要时可自定义语义色；字体、圆角等单独设置，不随主题切换';

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
  String get uiFontDescription => '用于界面与侧边栏的字体，导入后与正文字体共用应用字体库';

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
  String get barCornerRadiusDescription => '编辑器顶栏与侧边栏底栏的圆角';

  @override
  String get showBordersTitle => '显示边框';

  @override
  String get showBordersSubtitle => '关闭后控件无描边，开启时卷与书库栏显示边框';

  @override
  String get sidebarItemInsetTitle => '侧边栏条目边距';

  @override
  String get sidebarItemInsetDescription => '卷与章节左右边距（相等）';

  @override
  String get sidebarVolumeGapTitle => '侧边栏内容上下间距';

  @override
  String get sidebarVolumeGapDescription => '卷与卷之间的间距，章节之间无间距，仅 1px 分隔线';

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
  String get themePresetsFooter => '颜色预设只影响界面配色，字体、圆角等单独设置';

  @override
  String get customColorsTitle => '自定义颜色';

  @override
  String get customColorsSubtitle => '调整当前模式的语义色，修改后立即生效';

  @override
  String get customizeTokensButton => '自定义颜色';

  @override
  String get backToThemesButton => '返回主题';

  @override
  String get themeTokensTitle => '主题色';

  @override
  String get themeTokensIntro => '使用六位十六进制颜色，修改后立即生效';

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
  String get tokenControlSurface => '控件背景';

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
  String get tokenBorderDescription => '控件描边';

  @override
  String get tokenDividerDescription => '侧边栏章节分隔线';

  @override
  String get tokenPrimaryTextDescription => '默认标题与正文字色';

  @override
  String get tokenMutedTextDescription => '设置说明与说明文字的较淡色';

  @override
  String get tokenAccentDescription => '交互高亮与选中状态';

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
  String get editorBackgroundSectionTitle => '编辑器背景图';

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
  String get editorBackgroundBlurDescription => '对背景图做高斯模糊，不影响文字';

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
  String get librarySetupTitle => '选择 PureWriter 书库';

  @override
  String get librarySetupBody =>
      'Zephyr 需要打开包含 App/Room.db 的书库目录，也可以先使用临时书库开始写作，稍后再切换';

  @override
  String get chooseLibraryDirectoryButton => '选择书库目录';

  @override
  String get editorEmptyState => '选择或创建章节以开始写作';

  @override
  String get jumpToEnd => '聚焦到文末';

  @override
  String get volumeInsertBelow => '下方插入卷';

  @override
  String get chapterInsertBelow => '下方插入章节';

  @override
  String get actionMoveToVolume => '移动到卷';

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
  String get tooltipCollapseAll => '全部折叠';

  @override
  String get tooltipExpandAll => '全部展开';

  @override
  String get tooltipReorder => '排序';

  @override
  String get tooltipDoneReordering => '完成排序';

  @override
  String get tooltipOpenLibrary => '打开书库';

  @override
  String get tooltipOpenSidebar => '打开侧边栏';

  @override
  String get tooltipMore => '更多';

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
  String get moreSheetTitle => '更多';

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
  String get quickToolbarEdit => '编辑工具栏';

  @override
  String get quickToolbarEditHint => '拖拽排序，或在固定栏与自定义栏之间移动工具。';

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
  String get quickToolbarDrawerEmpty => '工具面板内容将稍后加入';
}
