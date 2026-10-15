# Changelog

## Unreleased

- Show a horizontal selection menu on Android and iOS with Cut, Copy, Paste, Share, and Select all; hide Select all when the entire chapter is selected.
- Fix the Android profile build type configuration so Gradle can compile the app with the current Kotlin DSL.

- Android debug / profile 使用独立包名与桌面名（`Zephyr Debug` / `Zephyr Profile`），与正式版 `Zephyr` 可并存；仅重新安装 release 才会覆盖日常使用包。

## 1.0.0

- 首个正式版。
- 移动端离开（返回 / Home / 进程结束）统一经 WorkManager 后台备份；仅显示「正在备份」，完成后不再弹成功通知。
- 主清单声明 `INTERNET` / 前台服务权限；WorkManager 启用 `dataSync` 前台服务。
- 云设置按平台分轨（`settings-desktop.json` / `settings-mobile.json`）；移动端抽屉改回固定宽度，不再跟随桌面侧栏宽度。
- 新机空目录可认领坚果云书库并恢复章节；云备份同时上传/恢复主题、编辑器、快捷键等本地设置（不含 WebDAV 凭据）。
- 桌面标题栏在最小化按钮左侧增加「更多」按钮；主题模式 / 更换主题为二级菜单，其余项与移动顶栏共用。
- 列表式底部抽屉在桌面端改为居中模态窗口（移动端仍为底部抽屉），经 `showZephyrModalSheet` 统一入口。
- 桌面左下角与移动顶栏增加云备份快捷按钮（未绑定时为斜杠云朵）；菜单支持立即备份、恢复与自动同步开关；自动同步后提示章节增删改数量。
- 云同步设置增加「开启云备份」开关与坚果云设置入口；自动同步改为打开时拉取合并最新快照；退出时先打本地备份再上传同一文件。
- 本地自动备份增加每小时检查；桌面端退出后由独立进程完成后台备份并用系统通知报告结果；本地和云端历史备份各保留最近 25 份。
- 移除阿里云盘开放平台和扫码登录，改用坚果云 WebDAV 账号、网址和应用密码；云备份与自动同步存放在根目录的 Zephyr 下。
- 暂时改为单文库目录；文库菜单可重新选择目录，云端书库 ID 不匹配时阻止同步与备份。
- Keep each volume header pinned while its chapters scroll, then release it at the end of that volume.
- Use a closed-book icon for books in the dropdown.
- Center the chapter toolbar buttons beneath the book picker with consistent spacing.
- Show the trash in the book dropdown with a red trash icon and label, and list all trashed chapters regardless of their former volume.
- Restored full-item book selection in the dropdown, with the edit button layered above the selection area.
- Replaced the desktop-only settings child window with a shared in-app settings route so appearance stays live against the writing workspace on every platform.
- Pair the editor settings scrollbar with its list scroll controller, and keep native window backdrop color in sync with the active theme.
- Load system fonts only when the editor settings page opens, and skip unused font registration until a writing session needs it.
- Fixed editor startup notifications during widget construction and made history snapshots conditional on the compatible `History` table being present.

## 0.1.0

- Created the cross-platform Zephyr foundation with a PureWriter v27-compatible `App/Room.db` library, article list and autosaving editor shell.
- Reworked the desktop editor shell into an immersive sidebar workspace with animated sidebar visibility, book selection, volume and chapter navigation, and a floating library-directory switcher.
- Applied Vellum-aligned dark shell tokens for quiet editor surfaces, compact typography, subtle outlines, and layered sidebar navigation.
- Fixed a desktop shell assertion caused by assigning duplicate corner-shape configuration to navigation surfaces.
- Added persistent, user-editable writing-shell theme tokens and a settings dialog opened from the library dock.
- Expanded settings into a desktop-style settings center with navigation, a selectable theme gallery, and a dedicated token editor.
- Added persisted editor typography controls, desktop system-font selection, content-width control, and plain-text ideographic first-line indentation.
