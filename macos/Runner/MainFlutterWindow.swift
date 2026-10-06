import Cocoa
import CoreText
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var accessedFolderUrls: [URL] = []

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.styleMask.insert(.fullSizeContentView)
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.isMovableByWindowBackground = false
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerFolderBookmarkChannel(flutterViewController)
    registerWindowChromeChannel(flutterViewController)
    registerSystemFontsChannel(flutterViewController)

    super.awakeFromNib()
  }

  private func registerWindowChromeChannel(
    _ controller: FlutterViewController
  ) {
    let channel = FlutterMethodChannel(
      name: "zephyr/window_chrome",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "unavailable",
            message: "Window was released.",
            details: nil
          )
        )
        return
      }
      switch call.method {
      case "metrics":
        result(self.chromeMetrics())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Distances from the Flutter content view origin so toolbar controls can
  /// share a vertical center with the native traffic lights.
  private func chromeMetrics() -> [String: Double] {
    contentView?.layoutSubtreeIfNeeded()
    guard
      let closeButton = standardWindowButton(.closeButton),
      let zoomButton = standardWindowButton(.zoomButton),
      let contentView
    else {
      return ["centerY": 14, "leading": 80]
    }
    let closeInWindow = closeButton.convert(closeButton.bounds, to: nil)
    let zoomInWindow = zoomButton.convert(zoomButton.bounds, to: nil)
    let contentInWindow = contentView.convert(contentView.bounds, to: nil)
    let centerY = contentInWindow.maxY - closeInWindow.midY
    let leading = zoomInWindow.maxX - contentInWindow.minX + 8
    return [
      "centerY": Double(centerY),
      "leading": Double(leading),
    ]
  }

  private func registerSystemFontsChannel(
    _ controller: FlutterViewController
  ) {
    let channel = FlutterMethodChannel(
      name: "zephyr/system_fonts",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "unavailable",
            message: "Window was released.",
            details: nil
          )
        )
        return
      }
      switch call.method {
      case "listFonts":
        DispatchQueue.global(qos: .userInitiated).async {
          let fonts = self.listSystemFonts()
          DispatchQueue.main.async { result(fonts) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Families from the macOS font registry, including .ttc collections and
  /// user fonts, with a file path Flutter can register.
  private func listSystemFonts() -> [[String: String]] {
    let manager = NSFontManager.shared
    var fonts: [[String: String]] = []
    var seen = Set<String>()
    for family in manager.availableFontFamilies.sorted() {
      if family.hasPrefix(".") || !seen.insert(family.lowercased()).inserted {
        continue
      }
      guard let font = representativeFont(in: family),
            let url = CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL
      else {
        continue
      }
      let path = url.path
      guard !path.isEmpty, FileManager.default.isReadableFile(atPath: path)
      else {
        continue
      }
      fonts.append(["family": family, "path": path])
    }
    return fonts
  }

  private func representativeFont(in family: String) -> CTFont? {
    let manager = NSFontManager.shared
    if let font = manager.font(
      withFamily: family,
      traits: [],
      weight: 5,
      size: 12
    ) {
      return font as CTFont
    }
    guard let members = manager.availableMembers(ofFontFamily: family),
          let first = members.first,
          let postScript = first.first as? String,
          let font = NSFont(name: postScript, size: 12)
    else {
      return nil
    }
    return font as CTFont
  }

  private func registerFolderBookmarkChannel(
    _ controller: FlutterViewController
  ) {
    let channel = FlutterMethodChannel(
      name: "zephyr/folder_bookmark",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "unavailable",
            message: "Window was released.",
            details: nil
          )
        )
        return
      }
      switch call.method {
      case "pickDirectory":
        self.pickDirectory(result)
      case "resolve":
        guard let bookmark = call.arguments as? String else {
          result(
            FlutterError(
              code: "invalid-argument",
              message: "Expected a bookmark string.",
              details: nil
            )
          )
          return
        }
        self.resolveBookmark(bookmark, result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func pickDirectory(_ result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true
    panel.prompt = "Open"
    guard panel.runModal() == .OK, let url = panel.url else {
      result(nil)
      return
    }
    _ = url.startAccessingSecurityScopedResource()
    accessedFolderUrls.append(url)
    do {
      let bookmark = try url.bookmarkData(
        options: [.withSecurityScope],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      result([
        "path": url.path,
        "bookmark": bookmark.base64EncodedString(),
      ])
    } catch {
      result([
        "path": url.path,
        "bookmark": "",
      ])
    }
  }

  private func resolveBookmark(_ value: String, _ result: @escaping FlutterResult) {
    guard let data = Data(base64Encoded: value) else {
      result(
        FlutterError(
          code: "invalid-bookmark",
          message: "Bookmark data was not valid Base64.",
          details: nil
        )
      )
      return
    }
    do {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: data,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      _ = url.startAccessingSecurityScopedResource()
      accessedFolderUrls.append(url)
      result(url.path)
    } catch {
      result(
        FlutterError(
          code: "resolve-failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }
}
