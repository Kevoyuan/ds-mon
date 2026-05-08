import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let viewModel = DashboardViewModel()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let statusView = StatusBarItemView()
    private let popover = NSPopover()
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        viewModel.onMenuBarNeedsUpdate = { [weak self] in
            self?.updateStatusItem()
        }

        setupPopover()
        setupStatusItem()
        observeDefaults()
        updateStatusItem()

        Task {
            await viewModel.onAppear()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        viewModel.onDisappear()
    }

    private func setupPopover() {
        popover.behavior = .transient
        popover.delegate = self
        popover.contentSize = NSSize(width: 380, height: 460)
        popover.contentViewController = NSHostingController(
            rootView: DashboardView()
                .frame(
                    minWidth: 360, idealWidth: 380, maxWidth: 440,
                    minHeight: 400, idealHeight: 460, maxHeight: 560
                )
                .environment(viewModel)
        )
    }

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Quit DeepSeek Monitor",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))

        statusView.onClick = { [weak self] in
            self?.togglePopover()
        }
        statusView.menu = menu
        button.addSubview(statusView)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func observeDefaults() {
        let defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItem()
            }
        }
        observers.append(defaultsObserver)

        let appearanceObserver = NotificationCenter.default.addObserver(
            forName: .menuBarAppearanceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItem()
            }
        }
        observers.append(appearanceObserver)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(button)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        let defaults = UserDefaults.standard
        let showsIcon = defaults.object(forKey: "menuBarShowsIcon") as? Bool ?? true
        let showsText = defaults.object(forKey: "menuBarShowsText") as? Bool ?? true
        let iconColor = NSColor(Color(hex: defaults.string(forKey: "menuBarIconColorHex") ?? "#FFFFFF"))
            .withAlphaComponent(defaults.object(forKey: "menuBarIconOpacity") as? Double ?? 1)
        let textColor = NSColor(Color(hex: defaults.string(forKey: "menuBarTextColorHex") ?? "#FFFFFF"))
            .withAlphaComponent(defaults.object(forKey: "menuBarTextOpacity") as? Double ?? 1)
        let iconSize = defaults.object(forKey: "menuBarIconSize") as? Double ?? 14
        let textSize = defaults.object(forKey: "menuBarTextSize") as? Double ?? 9
        let textWeight = MenuBarFontWeight(rawValue: defaults.string(forKey: "menuBarTextWeight") ?? "")
            ?? .semibold

        let text = showsText ? viewModel.balanceBadgeText : (showsIcon ? "" : "DS")
        statusView.configuration = StatusBarItemView.Configuration(
            text: text,
            showsIcon: showsIcon,
            iconColor: iconColor,
            textColor: textColor,
            iconSize: iconSize,
            textSize: textSize,
            textWeight: textWeight.nsWeight,
            image: Self.whaleImage()
        )
        statusItem.length = statusView.fittingWidth
        statusView.frame.size = NSSize(width: statusView.fittingWidth, height: NSStatusBar.system.thickness)
    }

    private static func whaleImage() -> NSImage? {
        guard let url = Bundle.module.url(
            forResource: "deepseek-whale-menubar-pixel",
            withExtension: "png"
        ), let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.isTemplate = false
        return image
    }
}

extension Notification.Name {
    static let menuBarAppearanceDidChange = Notification.Name("menuBarAppearanceDidChange")
}

private final class StatusBarItemView: NSView {
    struct Configuration {
        var text: String = "--"
        var showsIcon = true
        var iconColor = NSColor.white
        var textColor = NSColor.white
        var iconSize = 14.0
        var textSize = 9.0
        var textWeight = NSFont.Weight.semibold
        var image: NSImage?
    }

    var onClick: (() -> Void)?
    var configuration = Configuration() {
        didSet {
            if oldValue.text != configuration.text {
                startTextFlip(from: oldValue.text, to: configuration.text)
            }
            needsDisplay = true
        }
    }
    private var previousText: String?
    private var animationStart: CFTimeInterval?
    private let animationDuration: CFTimeInterval = 0.36

    var fittingWidth: CGFloat {
        let font = NSFont.monospacedDigitSystemFont(
            ofSize: configuration.textSize,
            weight: configuration.textWeight
        )
        let textWidth = configuration.text.isEmpty
            ? 0
            : (configuration.text as NSString).size(withAttributes: [.font: font]).width
        let iconWidth = configuration.showsIcon ? configuration.iconSize : 0
        let gap = configuration.showsIcon && !configuration.text.isEmpty ? 3.0 : 0
        return max(24, ceil(8 + iconWidth + gap + textWidth + 8))
    }

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 56, height: NSStatusBar.system.thickness))
        toolTip = "DeepSeek Monitor"
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let menu else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let font = NSFont.monospacedDigitSystemFont(
            ofSize: configuration.textSize,
            weight: configuration.textWeight
        )
        let textSize = (configuration.text as NSString).size(withAttributes: [.font: font])
        let iconWidth = configuration.showsIcon ? configuration.iconSize : 0
        let gap = configuration.showsIcon && !configuration.text.isEmpty ? 3.0 : 0
        let contentWidth = iconWidth + gap + textSize.width
        var x = floor((bounds.width - contentWidth) / 2)
        let centerY = bounds.midY

        if configuration.showsIcon, let image = configuration.image {
            let iconRect = NSRect(
                x: x,
                y: floor(centerY - configuration.iconSize / 2),
                width: configuration.iconSize,
                height: configuration.iconSize
            )
            Self.tintedImage(image, color: configuration.iconColor).draw(in: iconRect)
            x += configuration.iconSize + gap
        }

        let textRect = NSRect(
            x: x,
            y: floor(centerY - textSize.height / 2),
            width: textSize.width,
            height: textSize.height
        )
        drawAnimatedText(in: textRect, font: font)
    }

    private func startTextFlip(from oldText: String, to newText: String) {
        guard !oldText.isEmpty, !newText.isEmpty, oldText != "--", newText != "--" else {
            previousText = nil
            animationStart = nil
            return
        }

        previousText = oldText
        animationStart = CACurrentMediaTime()
        needsDisplay = true
    }

    private func drawAnimatedText(in rect: NSRect, font: NSFont) {
        guard let previousText, let animationStart else {
            (configuration.text as NSString).draw(in: rect, withAttributes: textAttributes(font: font))
            return
        }

        let elapsed = CACurrentMediaTime() - animationStart
        let rawProgress = min(max(elapsed / animationDuration, 0), 1)
        let progress = 1 - pow(1 - rawProgress, 3)
        let travel = rect.height * 0.72

        let oldChars = Array(previousText)
        let newChars = Array(configuration.text)
        let maxCount = max(oldChars.count, newChars.count)

        NSGraphicsContext.saveGraphicsState()
        rect.insetBy(dx: -2, dy: -3).clip()

        var xOffset = rect.minX
        for i in 0..<maxCount {
            let oldChar = i < oldChars.count ? String(oldChars[i]) : ""
            let newChar = i < newChars.count ? String(newChars[i]) : ""
            let sample = newChar.isEmpty ? oldChar : newChar
            let charWidth = (sample as NSString).size(withAttributes: textAttributes(font: font)).width
            let charRect = NSRect(x: xOffset, y: rect.minY, width: charWidth, height: rect.height)

            if oldChar == newChar {
                drawText(newChar, in: charRect, font: font, alpha: 1.0)
            } else {
                if !oldChar.isEmpty {
                    drawText(oldChar, in: charRect.offsetBy(dx: 0, dy: travel * CGFloat(progress)),
                             font: font, alpha: 1 - progress)
                }
                if !newChar.isEmpty {
                    drawText(newChar, in: charRect.offsetBy(dx: 0, dy: -travel * CGFloat(1 - progress)),
                             font: font, alpha: progress)
                }
            }
            xOffset += charWidth
        }

        NSGraphicsContext.restoreGraphicsState()

        if rawProgress < 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1 / 60) { [weak self] in
                self?.needsDisplay = true
            }
        } else {
            self.previousText = nil
            self.animationStart = nil
        }
    }

    private func textAttributes(font: NSFont) -> [NSAttributedString.Key: Any] {
        [.font: font, .foregroundColor: configuration.textColor]
    }

    private func drawText(_ text: String, in rect: NSRect, font: NSFont, alpha: Double) {
        let color = configuration.textColor.withAlphaComponent(configuration.textColor.alphaComponent * alpha)
        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color
            ]
        )
    }

    private static func tintedImage(_ image: NSImage, color: NSColor) -> NSImage {
        let tinted = NSImage(size: image.size)
        tinted.lockFocus()
        let rect = NSRect(origin: .zero, size: image.size)
        color.setFill()
        rect.fill()
        image.draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1)
        tinted.unlockFocus()
        tinted.isTemplate = false
        return tinted
    }
}

@main
struct ds_monApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
