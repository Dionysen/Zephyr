// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Zephyr';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionSave => '保存';

  @override
  String get actionDelete => '削除';

  @override
  String get actionDone => '完了';

  @override
  String get actionRename => '名前を変更する';

  @override
  String get actionBack => '戻る';

  @override
  String get untitled => '名称未設定';

  @override
  String get untitledLibrary => '無題のライブラリ';

  @override
  String get temporaryLibraryName => '一時ライブラリ';

  @override
  String get platformDefaultFont => 'LXGW WenKai (default)';

  @override
  String get searchHint => '検索する';

  @override
  String get dropdownHintSelect => '選択';

  @override
  String get dropdownNoMatches => '該当するものがありません';

  @override
  String get languageTitle => '言語';

  @override
  String get languageSubtitle => '管理画面の言語';

  @override
  String get languageSystem => 'システムの初期設定';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsDesktopHeader => '設定';

  @override
  String get settingsSearchHint => '検索設定';

  @override
  String get settingsBackTooltip => '戻る';

  @override
  String get settingsCustomColorsTitle => 'カスタム色';

  @override
  String get settingsComingSoonTitle => '近日登場';

  @override
  String get settingsComingSoonSubtitle => 'これらのオプションはまだ準備中です。';

  @override
  String get settingsPlaceholderBody => '関連オプションは後でここに表示されます。';

  @override
  String get settingsSectionGeneral => '一般';

  @override
  String get settingsSectionCloud => 'バックアップ';

  @override
  String get backupGroupLocalTitle => 'ローカルバックアップ';

  @override
  String get backupGroupCloudTitle => 'Cloud Sync';

  @override
  String get cloudSyncSubtitleSignedOut =>
      'クラウドバックアップと同期のためにNutstore WebDAVに接続する';

  @override
  String cloudSyncSubtitleSignedIn(String name) {
    return 'ログインアカウント:';
  }

  @override
  String get cloudBackupQuickTooltip => 'クラウドバックアップ';

  @override
  String get cloudBackupQuickTooltipUnconfigured =>
      'クラウドバックアップのためにNutstoreに接続する';

  @override
  String get cloudSyncEnableTitle => 'クラウドバックアップを有効にする';

  @override
  String get cloudSyncEnableSubtitle =>
      '終了時または編集を伴うモバイルバックグラウンド後にローカルバックアップをNutstoreにアップロードする';

  @override
  String get cloudSyncLoginTitle => 'Nutstoreに接続';

  @override
  String get cloudSyncLoginSubtitle => 'アカウント、WebDAV URL、アプリのパスワードを入力してください';

  @override
  String get cloudSyncSettingsTitle => 'Nutstoreの設定';

  @override
  String cloudSyncSettingsSubtitle(String name) {
    return 'ログインアカウント:';
  }

  @override
  String get cloudSyncUnbindTitle => '接続を解除';

  @override
  String get cloudSyncLogoutTitle => 'サインアウト';

  @override
  String get cloudSyncLogoutSubtitle => 'クラウドバックアップを停止';

  @override
  String get cloudSyncBackupNowTitle => '今すぐクラウドにバックアップ';

  @override
  String get cloudSyncBackupNowSubtitle =>
      'このデバイスにバックアップを作成し、NutstoreのZephyrフォルダーにアップロードします';

  @override
  String get cloudSyncBackupNowSuccess => 'クラウドバックアップが完了しました。';

  @override
  String get cloudSyncRestoreTitle => 'クラウドから復元';

  @override
  String get cloudSyncRestoreSubtitle => 'Nutstoreからバックアップを選択—上書きまたはマージ';

  @override
  String get cloudSyncRestoreEmpty => 'クラウドバックアップが見つかりません。';

  @override
  String get cloudSyncLatestSnapshotTitle => '最新のクラウドバックアップ';

  @override
  String get cloudSyncLatestSnapshotSubtitle => 'Nutstoreの現在のスナップショット';

  @override
  String get cloudSyncRestoreSuccess => 'ライブラリはクラウドバックアップから復元されました。';

  @override
  String cloudSyncFailed(String error) {
    return 'クラウド同期に失敗しました： $error';
  }

  @override
  String get cloudSyncAnotherLibrary =>
      'このZephyrクラウドフォルダは別のライブラリに属しています。元のローカルディレクトリまたは別のWebDAVアカウントを選択します。クラウド同期は停止しました。';

  @override
  String get cloudSyncMissingManifest =>
      'クラウドのZephyrフォルダーが不完全に見えます。再度同期する前に並べ替えます。';

  @override
  String get cloudSyncWaitBeforeChoosingDirectory =>
      '別のディレクトリを選択する前に、クラウド同期が完了するまで待ちます。';

  @override
  String get cloudSyncCredentialsTitle => 'Nutstore WebDAVに接続';

  @override
  String get cloudSyncCredentialsEditTitle => 'Nutstoreの設定';

  @override
  String get cloudSyncCredentialsSubtitle =>
      'アカウントのパスワードではなく、Nutstoreアプリのパスワードを使用してください。このデバイスに安全に保管されています。';

  @override
  String get cloudSyncCredentialsPasswordHint =>
      '現在のアプリのパスワードを保持するには、空白のままにします';

  @override
  String get cloudSyncCredentialsSave => '接続';

  @override
  String get cloudSyncCredentialsSaveEdit => '保存';

  @override
  String get cloudSyncCredentialsSaved => 'Nutstoreが接続されました';

  @override
  String get cloudSyncCredentialsUpdated => 'Nutstoreの設定が保存されました';

  @override
  String get cloudSyncClientIdLabel => 'Nutstoreアカウント';

  @override
  String get cloudSyncServerUrlLabel => 'WebDAV URL';

  @override
  String get cloudSyncClientSecretLabel => 'アプリ パスワード';

  @override
  String get backupAutoTitle => '自動バックアップ';

  @override
  String get backupAutoSubtitle =>
      '編集したコンテンツを1時間ごとにバックアップし、モバイルのバックグラウンドでバックアップします。最新の25個のローカルバックアップを保持します。';

  @override
  String get backupNowTitle => '今すぐバックアップ';

  @override
  String get backupNowSubtitle =>
      '今すぐ手動バックアップを作成してください。手動バックアップと自動バックアップを組み合わせると、最新の25を保持できます。';

  @override
  String get backupNowSuccess => 'バックアップ完了。';

  @override
  String backupFailed(String error) {
    return 'バックアップに失敗しました';
  }

  @override
  String saveFailed(String error) {
    return '保存に失敗しました。編集は開いたままです。終了する前に再試行してください： $error';
  }

  @override
  String get exitBackupInProgress => '保存中…';

  @override
  String get backupRestoreTitle => 'バックアップを復元';

  @override
  String backupRestoreSubtitle(int count) {
    return '⟦0件の⟧バックアップが利用可能—上書きまたはマージ。';
  }

  @override
  String get backupRestoreEmpty => 'バックアップファイルが見つかりません。';

  @override
  String get backupRestoreModeTitle => '復元モード';

  @override
  String get backupRestoreModeMerge => '統合（新しいバージョンを維持）';

  @override
  String get backupRestoreModeOverwrite => '上書き（ライブラリ全体を置き換える）';

  @override
  String get backupRestoreConfirmTitle => 'サイト復元を確認';

  @override
  String get backupRestoreConfirmMerge =>
      '選択したバックアップを現在のライブラリにマージします。安全バックアップが最初に作成されます。';

  @override
  String get backupRestoreConfirmOverwrite =>
      '現在のライブラリを選択したバックアップに置き換えます。安全バックアップが最初に作成されます。';

  @override
  String get backupRestoreAction => 'リストア';

  @override
  String get backupRestoreSuccess => 'ライブラリがバックアップから復元されました。';

  @override
  String get backupMergeResultTitle => 'マージ完了';

  @override
  String get backupMergeResultSeparator => 'を含み、';

  @override
  String get backupMergeResultNoChanges => 'マージが完了しました。チャプターの変更はありません。';

  @override
  String backupMergeResultAdded(int count) {
    return '⟦0を追加しました⟧';
  }

  @override
  String backupMergeResultUpdated(int count) {
    return '更新情報';
  }

  @override
  String backupMergeResultRemoved(int count) {
    return '削除された';
  }

  @override
  String get backupKindAuto => '自動';

  @override
  String get backupKindManual => '手動';

  @override
  String get backupFooter =>
      'Pure Writerで同じライブラリを同時に開かないでください。バックアップファイルはPure Writerで開くことができます。';

  @override
  String get historyTitle => '歴史';

  @override
  String get historyEmpty => '履歴の改訂はまだありません。';

  @override
  String get historyEmptyRevision => '(空)';

  @override
  String get historyRestoreTitle => 'このリビジョンを復元';

  @override
  String get historyRestoreBody => '現在の章のテキストはこの改訂版に置き換えられ、履歴に記録されます。';

  @override
  String get historyRestoreAction => 'リストア';

  @override
  String get historyRestoreSuccess => '選択したリビジョンに復元されました。';

  @override
  String get historyMenuLabel => '歴史';

  @override
  String get draftRecoverTitle => '未保存の下書きが見つかりました';

  @override
  String get draftRecoverBody => 'ライブラリより新しい下書きが見つかりました。復元しますか？';

  @override
  String get draftRecoverAction => 'リストア';

  @override
  String get draftDismissAction => '破棄';

  @override
  String get settingsSectionEditor => '編集者';

  @override
  String get settingsSectionShortcuts => 'ショートカット';

  @override
  String get shortcutsManageTitle => 'すべてのショートカットをカスタマイズする';

  @override
  String get shortcutsManageSubtitle => 'キーバインディングの表示と変更';

  @override
  String get shortcutsResetAll => 'デフォルトに戻す';

  @override
  String get shortcutsResetAction => 'リセット';

  @override
  String get shortcutsClearAction => 'クリア';

  @override
  String get shortcutsRecordTitle => '新しいショートカットを押す';

  @override
  String get shortcutsRecordHint => 'Escでキャンセル· Backspaceでクリア';

  @override
  String get shortcutsUnbound => 'アンバウンド';

  @override
  String get shortcutsConflictHint => '競合するショートカットが置き換えられました';

  @override
  String get shortcutGroupClipboard => 'クリップボード';

  @override
  String get shortcutGroupHistory => '歴史';

  @override
  String get shortcutGroupDelete => '削除';

  @override
  String get shortcutGroupIndent => 'インデント';

  @override
  String get shortcutGroupNewline => '改行コード';

  @override
  String get shortcutGroupNavigate => '移動';

  @override
  String get shortcutGroupSelect => '選択';

  @override
  String get shortcutGroupWorkspace => 'ワークスペース';

  @override
  String get shortcutActionCopy => 'コピー';

  @override
  String get shortcutActionCut => '切断';

  @override
  String get shortcutActionPaste => 'ペースト';

  @override
  String get shortcutActionSelectAll => 'すべて選択';

  @override
  String get shortcutActionUndo => '取り消し';

  @override
  String get shortcutActionRedo => 'やり直し';

  @override
  String get shortcutActionDeleteBackward => '後方に削除';

  @override
  String get shortcutActionDeleteForward => '右側の 1 単語を削除@action';

  @override
  String get shortcutActionDeleteWordBackward => '単語を逆方向に削除';

  @override
  String get shortcutActionDeleteWordForward => '右側の 1 単語を削除@action';

  @override
  String get shortcutActionIndent => 'インデント';

  @override
  String get shortcutActionOutdent => 'インデント解除';

  @override
  String get shortcutActionNewline => '改行コード';

  @override
  String get shortcutActionMoveLeft => '左に移動';

  @override
  String get shortcutActionMoveRight => '右に移動';

  @override
  String get shortcutActionMoveUp => '上へ移動';

  @override
  String get shortcutActionMoveDown => '下へ移動';

  @override
  String get shortcutActionMoveWordLeft => '左側の単語の先頭に移動';

  @override
  String get shortcutActionMoveWordRight => '右側の単語の先頭に移動';

  @override
  String get shortcutActionMoveLineStart => '行頭';

  @override
  String get shortcutActionMoveLineEnd => '線の終点';

  @override
  String get shortcutActionMovePageUp => 'PageUp';

  @override
  String get shortcutActionMovePageDown => 'æ¬¡ã®ãã¼ã¸QWebPage';

  @override
  String get shortcutActionMoveDocumentStart => 'ドキュメントの開始';

  @override
  String get shortcutActionMoveDocumentEnd => 'ドキュメント末尾へ';

  @override
  String get shortcutActionSelectLeft => '左方向に選択';

  @override
  String get shortcutActionSelectRight => '右方向に選択';

  @override
  String get shortcutActionSelectUp => '上を選択';

  @override
  String get shortcutActionSelectDown => '1 画面下まで選択';

  @override
  String get shortcutActionSelectWordLeft => '左側の単語の先頭まで選択';

  @override
  String get shortcutActionSelectWordRight => '右側の単語の先頭まで選択';

  @override
  String get shortcutActionSelectLineStart => '選択して行頭へ';

  @override
  String get shortcutActionSelectLineEnd => '行末まで選択';

  @override
  String get shortcutActionSelectPageUp => '1 画面上まで選択';

  @override
  String get shortcutActionSelectPageDown => '1 画面下まで選択';

  @override
  String get shortcutActionSelectDocumentStart => '選択して文書化開始';

  @override
  String get shortcutActionSelectDocumentEnd => 'ドキュメント末尾まで選択';

  @override
  String get shortcutActionCloseSettings => '設定を閉じる';

  @override
  String get shortcutActionCloudBackupNow => '今すぐクラウドにバックアップ';

  @override
  String get settingsSectionTheme => 'テーマ';

  @override
  String get settingsSectionAbout => '詳細';

  @override
  String get settingsSectionAi => 'エーアイ';

  @override
  String get aboutSettingsListSubtitle => 'バージョン、更新、およびリンク';

  @override
  String aboutVersionLabel(String version) {
    return 'バージョン 0';
  }

  @override
  String get aboutGitHubTitle => 'GitHub';

  @override
  String get aboutCheckUpdatesTitle => 'アップデートを確認';

  @override
  String get aboutCheckUpdatesSubtitle => 'GitHubから最新のリリース情報を取得します。';

  @override
  String get aboutCheckUpdatesComingSoon => 'アップデートの確認がまもなく行われます。';

  @override
  String get aboutOpenLinkFailed => 'リンクを開けませんでした。';

  @override
  String get generalSectionTitle => '一般';

  @override
  String get immersiveStatusBarTitle => '没入型ステータスバー';

  @override
  String get immersiveStatusBarSubtitle =>
      'アプリは透明なステータスバーの下に拡張され、テキストはその領域にスクロールできます。';

  @override
  String get hideStatusBarIconsTitle => 'ステータスバーアイコンを非表示にする';

  @override
  String get hideStatusBarIconsSubtitle =>
      '没入型ステータスバーがオンになっている間のみ。アイコンは自動的に非表示になります。エッジからスワイプすると簡単に表示されます。';

  @override
  String get mobileBehaviorSectionTitle => 'モバイル版';

  @override
  String get mobileBehaviorSectionSubtitle => 'スマートフォンやタブレットに適用されます。';

  @override
  String get scrollToHideMobileTopBarTitle => 'スクロール中はトップバーを非表示にする';

  @override
  String get scrollToHideMobileTopBarSubtitle =>
      '下にスクロールするとフローティングブックバーが折りたたまれ、上にスクロールすると表示されます。';

  @override
  String get openSidebarAfterBookSwitchTitle => '本を切り替えた後に章リストを開く';

  @override
  String get openSidebarAfterBookSwitchSubtitle => '別の本を選んだ後、章リストを表示します。';

  @override
  String get keepScreenOnTitle => '画面をONのままにする';

  @override
  String get keepScreenOnSubtitle => 'アプリが開いている間、ディスプレイがスリープ状態にならないようにします。';

  @override
  String get doubleBackToExitTitle => '[戻る]を2回押して終了します';

  @override
  String get doubleBackToExitSubtitle => 'オフの場合、1回のバックプレスでアプリを終了します。';

  @override
  String get openBookListOnStartupTitle => '立ち上げ時に本のリストを開く';

  @override
  String get openBookListOnStartupSubtitle => 'ワークスペースが開いたら、ブックピッカーを表示します。';

  @override
  String get openSidebarOnStartupTitle => '起動時にチャプターリストを開く';

  @override
  String get openSidebarOnStartupSubtitle => 'ワークスペースが開いたら、チャプターリストを表示します。';

  @override
  String get desktopBehaviorSectionTitle => 'デスクトップワークスペース';

  @override
  String get desktopBehaviorSectionSubtitle => 'デスクトップのライティングレイアウトに適用されます。';

  @override
  String get desktopFloatingSidebarTitle => 'ホバー時のフローティングサイドバー';

  @override
  String get desktopFloatingSidebarSubtitle =>
      'ポインタを画面の左端に移動すると、エディタの上にチャプターリストが表示されます。ポインタが離れると非表示になります。';

  @override
  String get desktopFloatingAiPanelTitle => 'フローティングAIパネル';

  @override
  String get desktopFloatingAiPanelSubtitle =>
      'ライティングカラムのサイズを変更する代わりに、右側のエディターにAIチャットを表示します。';

  @override
  String get pressBackAgainToExit => 'もう一度戻るを押して終了します';

  @override
  String get aiFeaturesEnabledTitle => 'WP 人工知能アシスタント';

  @override
  String get aiFeaturesEnabledSubtitle =>
      'オフの場合、AIボタンはワークスペースに隠され、開いているアシスタントはブックに戻ります。';

  @override
  String get hideAiAssistantAvatarTitle => 'アシスタントのアバターを非表示にする';

  @override
  String get hideAiAssistantAvatarSubtitle => 'チャットバブルが両側に並ぶようにアバターを非表示にします。';

  @override
  String get hideQuickToolbarTitle => 'クイック入力バーを非表示にする';

  @override
  String get hideQuickToolbarSubtitle =>
      'オンにすると、キーボードの上にあるアクセサリツールバーが非表示になります。';

  @override
  String get showChapterDetailsTitle => 'チャプターの詳細を表示';

  @override
  String get showChapterDetailsSubtitle => 'オフの場合、サイドバーには章のタイトルのみが表示されます。';

  @override
  String get editorSectionTitle => '編集者';

  @override
  String get editorSectionIntro => 'フォントとレイアウトの設定がすぐに適用されます。';

  @override
  String get editorSectionFooter => '変更はすぐに書き込み領域に適用されます。';

  @override
  String get editorFontLabel => 'フォント';

  @override
  String get editorFontDescription =>
      '書き込み中に使用されたフォント。インポートされたフォントは、インターフェースでも使用できます。';

  @override
  String get editorFontSizeTitle => 'フォントサイズ';

  @override
  String get editorFontSizeDescription => '書き込み列の本文テキストのサイズ。';

  @override
  String get editorTitleSizeTitle => 'タイトルサイズ';

  @override
  String get editorTitleSizeDescription => '本文の上の章タイトルのフォントサイズ。';

  @override
  String get editorTitleCenteredTitle => '中央のタイトル';

  @override
  String get editorTitleCenteredSubtitle =>
      'オンの場合は、タイトルを読み取り列の中央に配置します。オフの場合は、タイトルを本文の左端に揃えます。';

  @override
  String get editorTypewriterModeTitle => 'タイプライターモード';

  @override
  String get editorTypewriterModeSubtitle =>
      '編集行を中央に保ち、他の段落とフォーカスされていないタイトルを暗くします。';

  @override
  String get editorJumpToEndOnScrollDownTitle => 'スクロール中のフォーカスエンド';

  @override
  String get editorJumpToEndOnScrollDownSubtitle =>
      'オンにすると、下にスクロールしながらフォーカスエンドボタンが表示されます。下部または上にスクロールすると非表示になります。';

  @override
  String get editorLineHeightTitle => '線の高さ';

  @override
  String get editorLineHeightDescription => '段落内の均一行高乗数。';

  @override
  String get editorParagraphSpacingTitle => '段落の間隔';

  @override
  String get editorParagraphSpacingDescription => 'フォントサイズの乗数として、段落間のギャップ。';

  @override
  String get editorFirstLineIndentTitle => '本文インデント';

  @override
  String get editorFirstLineIndentDescription =>
      'タブによって挿入され、チャプターを開くときに適用される幅。前の段落のインデントをコピーします。';

  @override
  String get editorMarginLeftTitle => '左から';

  @override
  String get editorMarginLeftDescription =>
      '読み取り列の左挿入。スペースが狭いと、両方のマージンが比例して縮小します。';

  @override
  String get editorMarginRightTitle => '右マージン';

  @override
  String get editorMarginRightDescription => '読み取り列の右挿入。等しい値は厳密に対称的なままです。';

  @override
  String get editorWidthTitle => 'エディター幅';

  @override
  String get editorWidthDescription => '常に中央に配置されたテキスト列の幅。窓が小さすぎると狭くなります。';

  @override
  String get appearanceSectionTitle => '外観';

  @override
  String get appearanceSectionIntro =>
      'パレットを選択するか、個々の色を調整します。設定したフォントと角の半径はそのままにしておきます。';

  @override
  String get themeModeTitle => 'Theme mode';

  @override
  String get themeModeSubtitle =>
      'Choose light, dark, or follow the system appearance.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get uiFontLabel => 'UI font';

  @override
  String get uiFontDescription =>
      'Font used for the sidebar, settings, and other interface text. Imported fonts can also be used while writing.';

  @override
  String get uiFontSizeTitle => 'UI font size';

  @override
  String get uiFontSizeDescription =>
      'Size of text in the sidebar, settings, and the rest of the interface.';

  @override
  String get cornerRadiusTitle => 'Corner radius';

  @override
  String get cornerRadiusDescription =>
      'Shared roundness for buttons, menus, cards, and fields.';

  @override
  String get barCornerRadiusTitle => 'Bar corner radius';

  @override
  String get barCornerRadiusDescription =>
      'Roundness of the editor top bar and the bar at the bottom of the sidebar.';

  @override
  String get chatBubbleCornerRadiusTitle => 'Chat bubble corners';

  @override
  String get chatBubbleCornerRadiusDescription =>
      'Roundness of AI chat bubbles. The outer top corner stays square.';

  @override
  String get showBordersTitle => 'Show borders';

  @override
  String get showBordersSubtitle =>
      'When off, buttons and cards have no outline. When on, volumes and the library bar show a border.';

  @override
  String get sidebarItemInsetTitle => 'Sidebar item inset';

  @override
  String get sidebarItemInsetDescription =>
      'Equal left/right padding for volumes and chapters.';

  @override
  String get sidebarItemCornerRadiusTitle => 'Sidebar volume & chapter corners';

  @override
  String get sidebarItemCornerRadiusDescription =>
      'Corner radius for volume headers and chapter rows in the library sidebar.';

  @override
  String get sidebarVolumeGapTitle => 'Sidebar volume spacing';

  @override
  String get sidebarVolumeGapDescription =>
      'Space between volumes. Chapters stay close, separated by a line.';

  @override
  String get themePresetsSectionTitle => 'Theme colors';

  @override
  String get actionCopy => 'Copy';

  @override
  String get themePackRenameTitle => 'Rename theme';

  @override
  String themePackCopyName(String name) {
    return '$name copy';
  }

  @override
  String get themePackDeleteTitle => 'Delete theme?';

  @override
  String themePackDeleteBody(String name) {
    return '“$name” will be removed permanently.';
  }

  @override
  String get themeCurrentCustom => 'Current: Custom';

  @override
  String themeCurrentPreset(String preset) {
    return 'Current: $preset';
  }

  @override
  String get themeCurrentCustomLong => 'Current palette: Custom';

  @override
  String themeCurrentPresetLong(String preset) {
    return 'Current palette: $preset';
  }

  @override
  String get themePresetsFooter =>
      'Palettes only change colors. Fonts, corners, and other layout stay as you set them.';

  @override
  String get customColorsTitle => 'Custom colors';

  @override
  String get customColorsSubtitle =>
      'Adjust colors for the current appearance. Changes apply right away.';

  @override
  String get customizeTokensButton => 'Customize colors';

  @override
  String get backToThemesButton => 'Back to themes';

  @override
  String get themeTokensTitle => 'Theme colors';

  @override
  String get themeTokensIntro =>
      'Enter a color code such as #336699. Changes apply right away.';

  @override
  String get restoreDefaultColors => 'Restore defaults';

  @override
  String get saveAsThemeColor => 'Save as theme';

  @override
  String get saveThemeColorTitle => 'Save as theme color';

  @override
  String get saveThemeColorNameLabel => 'Theme name';

  @override
  String themePackNameDefault(int n) {
    return 'Theme $n';
  }

  @override
  String get themePresetLight => 'Light';

  @override
  String get themePresetGrey => 'Grey';

  @override
  String get themePresetSlate => 'Slate';

  @override
  String get themePresetClaude => 'Claude Code';

  @override
  String get themePresetMint => 'Mint';

  @override
  String get themePresetPurple => 'Purple';

  @override
  String get themePresetHermes => 'Hermes';

  @override
  String get themePresetOcean => 'Ocean';

  @override
  String get themePresetDarkModern => 'Dark Modern';

  @override
  String get tokenEditorSurface => 'Writing background';

  @override
  String get tokenSidebarSurface => 'Sidebar background';

  @override
  String get tokenControlSurface => 'Buttons and fields';

  @override
  String get tokenBorder => 'Border';

  @override
  String get tokenDivider => 'Divider';

  @override
  String get tokenPrimaryText => 'Primary text';

  @override
  String get tokenMutedText => 'Muted text';

  @override
  String get tokenAccent => 'Accent';

  @override
  String get tokenCursor => 'Cursor';

  @override
  String get tokenEditorSurfaceDescription =>
      'Background of the writing column.';

  @override
  String get tokenSidebarSurfaceDescription =>
      'Background of the sidebar and surrounding panels.';

  @override
  String get tokenControlSurfaceDescription =>
      'Fill color for fields, menus, and cards.';

  @override
  String get tokenBorderDescription => 'Outlines around buttons and fields.';

  @override
  String get tokenDividerDescription => 'Sidebar chapter separators.';

  @override
  String get tokenPrimaryTextDescription =>
      'Default title and body copy color.';

  @override
  String get tokenMutedTextDescription =>
      'Softer color for hints and captions.';

  @override
  String get tokenAccentDescription => 'Highlights and selected items.';

  @override
  String get tokenCursorDescription => 'Caret color in the writing editor.';

  @override
  String get fontImportSuccess => 'Font imported into the app library.';

  @override
  String get fontImportFailure => 'Could not import that font file.';

  @override
  String get fontDeleteSuccess => 'Removed from the app font library.';

  @override
  String get fontDeleteFailure => 'Could not delete that font.';

  @override
  String get fontImportFromFile => 'Choose font file…';

  @override
  String get fontDeleteFromLibrary => 'Delete from library';

  @override
  String get fontDeleteDialogTitle => 'Delete font?';

  @override
  String fontDeleteDialogBody(String family) {
    return 'Remove “$family” from the app font library to free space?';
  }

  @override
  String get fontDeleteDialogBodyCompact =>
      'Remove it from the app font library to free space?';

  @override
  String get editorBackgroundSectionTitle => 'Editor background image';

  @override
  String get editorBackgroundEnabledTitle => 'Use background image';

  @override
  String get editorBackgroundEnabledSubtitle =>
      'Turn off to hide without clearing your picks';

  @override
  String get themeColorsSectionTitle => 'Theme colors';

  @override
  String get editorBackgroundLightTitle => 'Light background';

  @override
  String get editorBackgroundDarkTitle => 'Dark background';

  @override
  String get editorBackgroundNone => 'None';

  @override
  String get editorBackgroundCurrentBadge => 'Current';

  @override
  String get editorBackgroundChoose => 'Choose';

  @override
  String get editorBackgroundClear => 'Clear';

  @override
  String get editorBackgroundSelectTitle => 'Choose background';

  @override
  String get editorBackgroundAddFromFile => 'Add from file…';

  @override
  String get editorBackgroundEmptyLibrary =>
      'No images yet. Tap above to add one.';

  @override
  String get editorBackgroundNoImagePreview => 'No background image';

  @override
  String get editorBackgroundPreviewSample =>
      'The quick brown fox jumps over the lazy dog.\nWriting stays sharp above a soft backdrop.';

  @override
  String get editorBackgroundFitTitle => 'Image fit';

  @override
  String get editorBackgroundFitCover => 'Cover';

  @override
  String get editorBackgroundFitContain => 'Contain';

  @override
  String get editorBackgroundFitFill => 'Stretch';

  @override
  String get editorBackgroundFitTile => 'Tile';

  @override
  String get editorBackgroundFitCenter => 'Center';

  @override
  String get editorBackgroundOpacityTitle => 'Background opacity';

  @override
  String get editorBackgroundBlurTitle => 'Background blur';

  @override
  String get editorBackgroundBlurDescription =>
      'Softens the image only. Text stays sharp.';

  @override
  String get editorBackgroundImportSuccess => 'Image added to the app library.';

  @override
  String get editorBackgroundImportFailure => 'Could not import that image.';

  @override
  String get editorBackgroundDeleteSuccess => 'Removed from the app library.';

  @override
  String get editorBackgroundDeleteFailure => 'Could not delete that image.';

  @override
  String get editorBackgroundDeleteTitle => 'Delete image?';

  @override
  String editorBackgroundDeleteBody(String name) {
    return 'Delete “$name”? Modes using it will reset to no background.';
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
    return '$name · $fit · $opacity% · blur $blur';
  }

  @override
  String get choiceDeleteTitle => 'Delete?';

  @override
  String get choiceDeleteBody => 'Remove this item?';

  @override
  String numberPickerDefaultLabel(String value) {
    return 'Default $value';
  }

  @override
  String numberPickerRestoreDefault(String value) {
    return 'Restore default ($value)';
  }

  @override
  String get tempLibraryBannerTitle => 'Using a temporary library';

  @override
  String get tempLibraryBannerSubtitle =>
      'Choose a PureWriter library folder to open your work';

  @override
  String get chooseLibraryButton => 'Choose library';

  @override
  String get librarySetupTitle => 'Welcome to Zephyr';

  @override
  String get librarySetupBody =>
      'Start writing in a local temporary library, or connect an existing PureWriter folder when you are ready.';

  @override
  String get startTemporaryLibraryButton => 'Start writing';

  @override
  String get libraryLoadFailedHint =>
      'Could not open the last library. Start fresh or choose another folder.';

  @override
  String get libraryRecoveredToTemporary =>
      'Opened the temporary library instead. You can reconnect your PureWriter folder from the banner.';

  @override
  String get chooseLibraryDirectoryButton => 'Choose PureWriter folder';

  @override
  String get editorEmptyState => 'Choose or create a chapter to begin writing.';

  @override
  String get jumpToEnd => 'Focus end';

  @override
  String get volumeInsertBelow => 'Insert volume below';

  @override
  String get volumeAppendChapter => 'Insert chapter at end of volume';

  @override
  String get chapterInsertBelow => 'Insert chapter below';

  @override
  String get actionMoveToVolume => 'Move to volume';

  @override
  String get actionMoveToBook => 'Move to book';

  @override
  String get actionConvertVolumeToBook => 'Convert this volume to a book';

  @override
  String get moveToBookSheetTitle => 'Move to book';

  @override
  String get moveToBookNoTargets => 'There are no other books to move into.';

  @override
  String get renameVolumeTitle => 'Rename volume';

  @override
  String get renameChapterTitle => 'Rename chapter';

  @override
  String get volumeNameLabel => 'Volume name';

  @override
  String get chapterNameLabel => 'Chapter name';

  @override
  String get validationNameRequired => 'Please enter a name';

  @override
  String get deleteChapterTitle => 'Delete chapter';

  @override
  String deleteChapterBody(String name) {
    return 'Move “$name” to the trash?';
  }

  @override
  String get deleteVolumeTitle => 'Delete volume';

  @override
  String deleteVolumeBody(String name) {
    return 'When deleting “$name”, choose what to do with its chapters.';
  }

  @override
  String get deleteVolumeOnly => 'Delete volume only';

  @override
  String get deleteVolumeAndChapters => 'Delete volume and chapters';

  @override
  String get moveToVolumeSheetTitle => 'Move to volume';

  @override
  String get unfiledVolume => 'Unfiled';

  @override
  String get unfiledChaptersHeader => 'Unfiled chapters';

  @override
  String get tooltipHideSidebar => 'Hide sidebar';

  @override
  String get tooltipNewVolume => 'New volume';

  @override
  String get tooltipNewChapter => 'New chapter';

  @override
  String get tooltipAdd => 'Add';

  @override
  String get tooltipSearchChapters => 'Search';

  @override
  String get searchSheetTitle => 'Search';

  @override
  String get searchSheetHint => 'Search titles and content';

  @override
  String get searchSheetEmptyQuery => 'Enter a keyword to search.';

  @override
  String get searchSheetNoResults => 'No matching results.';

  @override
  String get searchScopeArticle => 'Chapter';

  @override
  String get searchScopeVolume => 'Volume';

  @override
  String get searchScopeBook => 'Book';

  @override
  String get searchScopeAllBooks => 'All books';

  @override
  String get tooltipLocateCurrentChapter => 'Locate current chapter';

  @override
  String get tooltipCollapseAll => 'Collapse all';

  @override
  String get tooltipExpandAll => 'Expand all';

  @override
  String get tooltipReorder => 'Sort order';

  @override
  String get tooltipDoneReordering => 'Done adjusting order';

  @override
  String get chapterSortManual => 'Manual order';

  @override
  String get chapterSortAdjustOrder => 'Adjust order';

  @override
  String get chapterSortCreatedAsc => 'Created · Oldest first';

  @override
  String get chapterSortCreatedDesc => 'Created · Newest first';

  @override
  String get chapterSortUpdatedAsc => 'Modified · Oldest first';

  @override
  String get chapterSortUpdatedDesc => 'Modified · Newest first';

  @override
  String get chapterSortTitleAsc => 'Name · A→Z';

  @override
  String get chapterSortTitleDesc => 'Name · Z→A';

  @override
  String get tooltipAiAssistant => 'AI assistant';

  @override
  String get aiChatWelcome => 'Tell me what you\'re working on.';

  @override
  String get aiChatInputHint => 'Type a message…';

  @override
  String get aiChatSend => 'Send';

  @override
  String get aiChatStopGenerating => 'Stop generating';

  @override
  String get aiContextRemoveArticle => 'Remove from context';

  @override
  String get llmSettingsTitle => 'AI models';

  @override
  String get llmSettingsSubtitle => 'Provider, API key, and model';

  @override
  String get llmSettingsIntro =>
      'Your key stays on this device. Other settings are included in backups.';

  @override
  String get llmBehaviorSectionTitle => 'Chat behavior';

  @override
  String get llmStreamOutputTitle => 'Streaming output';

  @override
  String get llmStreamOutputSubtitle => 'Show the reply as it is written';

  @override
  String get llmAllowThinkingTitle => 'Allow thinking';

  @override
  String get llmAllowThinkingSubtitle =>
      'Let models that can reason think before they answer';

  @override
  String get llmPresetPromptTitle => 'Preset prompt';

  @override
  String get llmPresetPromptDescription =>
      'Sent as system instructions on every chat—use it for genre, tone, POV, and other standing preferences.';

  @override
  String get llmPresetPromptHint =>
      'e.g. You are a writing assistant. Reply concisely; when continuing prose, match POV, tense, and voice.';

  @override
  String get llmMaxInputTokensTitle => 'Context limit (input)';

  @override
  String get llmMaxInputTokensSubtitle =>
      'Older messages are shortened once this limit is reached';

  @override
  String get llmMaxOutputTokensTitle => 'Reply limit (output)';

  @override
  String get llmMaxOutputTokensSubtitle => 'How long a single reply can be';

  @override
  String get llmThinkingLevelTitle => 'Thinking intensity';

  @override
  String get llmThinkingLevelSubtitle => 'Deeper thinking usually takes longer';

  @override
  String get llmDefaultThinkingLevelTitle => 'Default thinking intensity';

  @override
  String get llmDefaultThinkingLevelSubtitle =>
      'Starting level for new chats. You can change it beside the message box.';

  @override
  String get llmThinkingDisabledInSettings =>
      'Turn on “Allow thinking” in AI model settings first';

  @override
  String get llmThinkingOff => 'Off';

  @override
  String get llmThinkingMinimal => 'Minimal';

  @override
  String get llmThinkingLow => 'Low';

  @override
  String get llmThinkingMedium => 'Medium';

  @override
  String get llmThinkingHigh => 'High';

  @override
  String get llmThinkingAuto => 'Auto';

  @override
  String get aiChatAiSettingsEntry => 'AI settings';

  @override
  String get aiChatSessionOptionsTitle => 'Chat options';

  @override
  String get aiChatSessionProviderTitle => 'Provider';

  @override
  String get aiChatSessionProviderSubtitle =>
      'Use a vendor you configured in AI settings';

  @override
  String get aiChatSessionOptionsNeedTest =>
      'Run a connection test in AI model settings first.';

  @override
  String get aiChatSessionModelSubtitle =>
      'Override the default model from settings';

  @override
  String aiChatThinkingForModel(String model) {
    return 'Model: $model';
  }

  @override
  String get aiChatSessionsTitle => 'Conversations';

  @override
  String get aiChatSessionsSubtitle =>
      'Switch, archive, or delete saved chats for this chapter';

  @override
  String get aiChatNewSession => 'New chat';

  @override
  String get aiChatShowArchivedSessions => 'Show archived';

  @override
  String get aiChatNoSessions => 'No saved conversations yet.';

  @override
  String aiChatSessionUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get aiChatOpenSession => 'Open';

  @override
  String get aiChatArchiveSession => 'Archive';

  @override
  String get aiChatUnarchiveSession => 'Restore from archive';

  @override
  String get aiChatDeleteSession => 'Delete';

  @override
  String get aiChatDeleteSessionTitle => 'Delete conversation?';

  @override
  String aiChatDeleteSessionBody(String title) {
    return 'Delete “$title” and all messages in it? This cannot be undone.';
  }

  @override
  String get aiChatCompressedContextHeader =>
      'Summary of the earlier conversation:';

  @override
  String get llmProviderTitle => 'Provider';

  @override
  String get llmProviderSubtitle =>
      'Configure each vendor; switch without losing other profiles';

  @override
  String get llmApiKeyTitle => 'API key';

  @override
  String get llmApiKeyHint => 'Paste your key';

  @override
  String get llmBaseUrlTitle => 'API base URL';

  @override
  String get llmBaseUrlHint => 'e.g. https://api.example.com/v1';

  @override
  String get llmTestConnection => 'Test connection';

  @override
  String llmTestSuccess(int count) {
    return 'Connected — $count models available';
  }

  @override
  String get llmModelTitle => 'Chat model';

  @override
  String get llmModelSubtitle => 'Available after a successful test';

  @override
  String get llmModelNotSelected => 'Not selected';

  @override
  String get aiChatNotConfigured =>
      'Set up your API key and run a connection test in Settings first.';

  @override
  String get aiChatThinkingInProgress => 'Thinking…';

  @override
  String get aiChatThinkingProcess => 'Thinking process';

  @override
  String aiChatError(String error) {
    return 'Request failed: $error';
  }

  @override
  String aiChatDemoReply(String message) {
    return 'Received: $message';
  }

  @override
  String get tooltipOpenLibrary => 'Open library';

  @override
  String get librarySwitcherChooseDirectory => 'Choose another directory';

  @override
  String get tooltipOpenSidebar => 'Open sidebar';

  @override
  String get tooltipMore => 'More';

  @override
  String get mobileToolsDrawerReorderHint => 'Long-press and drag to reorder.';

  @override
  String get tooltipEditBook => 'Edit book';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get selectBook => 'Select a book';

  @override
  String get booksSheetTitle => 'Books';

  @override
  String get booksSheetTagAll => 'All';

  @override
  String get newBookTitle => 'New book';

  @override
  String get moreSheetTitle => 'Quick tools';

  @override
  String get mobileToolThemeMode => 'Theme mode';

  @override
  String get mobileToolSwitchTheme => 'Switch theme';

  @override
  String get noMobileTools => 'No tools available';

  @override
  String get editBookTitle => 'Edit book';

  @override
  String get bookNameLabel => 'Book title';

  @override
  String get bookNameHint => 'Enter a book title';

  @override
  String get bookNameRequired => 'Please enter a book title';

  @override
  String get tooltipNewBook => 'New book';

  @override
  String get tooltipBookGridLayout => 'Two-column layout';

  @override
  String get tooltipBookListLayout => 'Single-column list';

  @override
  String get tooltipDeleteBook => 'Delete book';

  @override
  String get deleteBookNotEmpty =>
      'Clear all chapters in this book before deleting it.';

  @override
  String get bookTagsLabel => 'Tags';

  @override
  String get bookTagsHint => 'e.g. Literature';

  @override
  String get bookDescriptionLabel => 'Description';

  @override
  String get bookDescriptionHint => 'Briefly describe this book';

  @override
  String bookStatsMeta(int volumes, int chapters) {
    return '$volumes volumes · $chapters chapters';
  }

  @override
  String chapterMeta(String created, String modified, int wordCount) {
    return 'Created $created · Edited $modified · $wordCount words';
  }

  @override
  String get themeSlotLight => 'Light';

  @override
  String get themeSlotDark => 'Dark';

  @override
  String get themePresetsSubtitle =>
      'Tap to apply a palette to the current light or dark mode.';

  @override
  String get quickToolbarToolsTooltip => 'Tools';

  @override
  String get quickToolbarUndoTooltip => 'Undo';

  @override
  String get quickToolbarPasteTooltip => 'Paste';

  @override
  String get quickToolbarIndentTooltip => 'Indent';

  @override
  String get quickToolbarFormatTooltip => 'Format';

  @override
  String get quickToolbarSearchTooltip => 'Search';

  @override
  String get quickToolbarTimestampTooltip => 'Insert timestamp';

  @override
  String get quickToolbarBackupTooltip => 'Back up now';

  @override
  String get quickToolbarRestoreTooltip => 'Restore backup';

  @override
  String get quickToolbarEdit => 'Edit toolbar';

  @override
  String get quickToolbarEditHint =>
      'Long-press and drag on the toolbar to reorder. You can also drag here, or move tools between the fixed and custom zones.';

  @override
  String get quickToolbarPinnedSection => 'Fixed bar';

  @override
  String get quickToolbarCustomSection => 'Custom bar';

  @override
  String get quickToolbarAddSection => 'Add tool';

  @override
  String get quickToolbarSectionEmpty => 'No tools yet';

  @override
  String get quickToolbarAddPhrase => 'Quick phrase';

  @override
  String get quickToolbarPhraseName => 'Display name';

  @override
  String get quickToolbarPhraseContent => 'Inserted text';

  @override
  String get quickToolbarMoveToPinned => 'Move to fixed bar';

  @override
  String get quickToolbarMoveToCustom => 'Move to custom bar';

  @override
  String get quickToolbarDrawerEmpty => 'Nothing here yet';

  @override
  String get quickToolbarFormatApplyAll => 'Format document';

  @override
  String get quickToolbarFormatKeepParagraphBlanks =>
      'Keep blank lines between paragraphs';

  @override
  String get quickToolbarFormatRemoveParagraphBlanks =>
      'Remove blank lines between paragraphs';

  @override
  String get quickToolbarFormatInsertCjkLatinSpaces =>
      'Space between Chinese and English';

  @override
  String get quickToolbarFormatAddParagraphIndent => 'Indent paragraph starts';

  @override
  String get quickToolbarFormatRemoveParagraphIndent =>
      'Remove paragraph indents';

  @override
  String get quickToolbarFormatSimplifiedToTraditional =>
      'Simplified to Traditional Chinese';

  @override
  String get quickToolbarFormatTraditionalToSimplified =>
      'Traditional to Simplified Chinese';

  @override
  String get quickToolbarFormatHalfwidthToFullwidth =>
      'Halfwidth to fullwidth symbols';
}
