import SwiftUI
@preconcurrency import AppKit

struct SettingsView: View {
    @Environment(DashboardViewModel.self) private var vm
    var onDismiss: () -> Void = {}

    @State private var keyLabel: String = ""
    @State private var keyValue: String = ""
    @State private var showKey = false
    @State private var isTesting = false
    @State private var testResult: Bool?
    @State private var savedFeedback = false
    @State private var testError: String?
    @State private var selectedTab: SettingsTab = .apiKey
    @State private var customRefreshSecondsText = ""
    @AppStorage("menuBarShowsIcon") private var menuBarShowsIcon = true
    @AppStorage("menuBarShowsText") private var menuBarShowsText = true
    @AppStorage("menuBarIconColorHex") private var menuBarIconColorHex = "#FFFFFF"
    @AppStorage("menuBarTextColorHex") private var menuBarTextColorHex = "#FFFFFF"
    @AppStorage("menuBarIconOpacity") private var menuBarIconOpacity = 1.0
    @AppStorage("menuBarTextOpacity") private var menuBarTextOpacity = 1.0
    @AppStorage("menuBarIconSize") private var menuBarIconSize = 20.0
    @AppStorage("menuBarTextSize") private var menuBarTextSize = 14.0
    @AppStorage("menuBarTextWeight") private var menuBarTextWeight = MenuBarFontWeight.semibold.rawValue
    @AppStorage("balanceRefreshIntervalSeconds") private var balanceRefreshIntervalSeconds = 60.0

    private let apiClient = DeepSeekAPIClient()
    private static let previewWhaleImage: NSImage = {
        guard let url = Bundle.module.url(
            forResource: "deepseek-whale-menubar-pixel",
            withExtension: "png"
        ), let image = NSImage(contentsOf: url) else {
            return NSImage()
        }

        image.isTemplate = true
        image.size = NSSize(width: 14, height: 14)
        return image
    }()

    var body: some View {
        ZStack {
            Color.whaleSurface.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 9) {
                    DeepSeekWhaleMark(compact: true)
                        .frame(width: 26, height: 26)
                    Text("Settings")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Button("Done") { onDismiss() }
                        .buttonStyle(.borderless)
                        .font(.subheadline)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Picker("Settings section", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, 14)
                .padding(.top, 12)

                switch selectedTab {
                case .apiKey:
                    ScrollView {
                        apiKeySection
                            .padding(14)
                    }
                case .menuBar:
                    VStack(spacing: 10) {
                        stickyMenuBarPreview
                            .padding(.horizontal, 14)
                            .padding(.top, 12)

                        ScrollView {
                            menuBarSection
                                .padding(.horizontal, 14)
                                .padding(.bottom, 14)
                        }
                    }
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if let existing = vm.apiKey {
                keyLabel = existing.label
            }
            customRefreshSecondsText = String(Int(customRefreshIntervalSeconds))
        }
        .onChange(of: balanceRefreshIntervalSeconds) {
            vm.restartAutoRefresh()
            customRefreshSecondsText = String(Int(customRefreshIntervalSeconds))
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let existing = vm.apiKey {
                AppSectionCard(title: "API Key") {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(existing.label)
                                .font(.system(size: 12, weight: .bold))
                            Text(existing.maskedKey)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .monospaced()
                        }
                        Spacer()

                        if isTesting {
                            ProgressView().scaleEffect(0.7)
                        } else if let result = testResult {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result ? .green : .red)
                                .help(testError ?? (result ? "Valid" : "Invalid"))
                        }

                        Button("Test") {
                            Task { await testKey(existing.key) }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Remove") {
                            vm.removeAPIKey()
                            keyLabel = ""
                            keyValue = ""
                            testResult = nil
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
            } else {
                AppSectionCard(title: "API Key") {
                    HStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .foregroundColor(.secondary)
                        Text("No API key configured")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }

            AppSectionCard(title: vm.apiKey != nil ? "Update Key" : "Save Key") {
                VStack(spacing: 8) {
                    TextField("Label (e.g. Work Account)", text: $keyLabel)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        if showKey {
                            TextField("sk-...", text: $keyValue)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("API Key (sk-...)", text: $keyValue)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button(action: { showKey.toggle() }) {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack {
                        Spacer()
                        Button(vm.apiKey != nil ? "Update" : "Save") {
                            let trimmedLabel = keyLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                            let trimmedKey = keyValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            vm.saveAPIKey(
                                label: trimmedLabel.isEmpty ? "Default" : trimmedLabel,
                                key: trimmedKey
                            )
                            keyValue = ""
                            Task { await vm.refresh() }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(keyValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }

            balanceRefreshSection
        }
    }

    private var balanceRefreshSection: some View {
        AppSectionCard(title: "Balance Refresh") {
            HStack {
                Text("Auto refresh")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Picker("Auto refresh", selection: refreshPresetBinding) {
                    Text("Every 15 seconds").tag(15.0)
                    Text("Every 30 seconds").tag(30.0)
                    Text("Every minute").tag(60.0)
                    Text("Every 5 minutes").tag(300.0)
                    Text("Every 15 minutes").tag(900.0)
                    Text("Custom…").tag(-1.0)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 170)
            }

            if isCustomRefreshInterval {
                HStack(spacing: 8) {
                    TextField("Seconds", text: $customRefreshSecondsText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 88)
                        .multilineTextAlignment(.trailing)
                        .onSubmit { applyCustomRefreshSeconds() }

                    Stepper("",
                        value: customRefreshBinding,
                        in: 1...86_400,
                        step: customRefreshStep
                    )
                    .labelsHidden()

                    Text("sec")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if savedFeedback {
                        Text("Saved!")
                            .font(.caption)
                            .foregroundColor(.green)
                            .transition(.opacity)
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    private var refreshPresetBinding: Binding<Double> {
        Binding(
            get: {
                isCustomRefreshInterval ? -1 : balanceRefreshIntervalSeconds
            },
            set: { value in
                if value < 0 {
                    balanceRefreshIntervalSeconds = customRefreshIntervalSeconds
                    customRefreshSecondsText = String(Int(customRefreshIntervalSeconds))
                } else {
                    balanceRefreshIntervalSeconds = value
                    customRefreshSecondsText = String(Int(value))
                }
            }
        )
    }

    private var customRefreshBinding: Binding<Double> {
        Binding(
            get: { customRefreshIntervalSeconds },
            set: { value in
                let clamped = clampedRefreshSeconds(value)
                balanceRefreshIntervalSeconds = clamped
                customRefreshSecondsText = String(Int(clamped))
                withAnimation(.easeOut(duration: 0.15)) {
                    savedFeedback = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    withAnimation(.easeIn(duration: 0.25)) {
                        savedFeedback = false
                    }
                }
            }
        )
    }

    private var isCustomRefreshInterval: Bool {
        ![15.0, 30.0, 60.0, 300.0, 900.0].contains(balanceRefreshIntervalSeconds)
    }

    private var customRefreshIntervalSeconds: Double {
        isCustomRefreshInterval ? balanceRefreshIntervalSeconds : 120
    }

    private var customRefreshStep: Double {
        customRefreshIntervalSeconds < 60 ? 5 : 30
    }

    private func applyCustomRefreshSeconds() {
        guard let value = Double(customRefreshSecondsText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }
        let clamped = clampedRefreshSeconds(value)
        if balanceRefreshIntervalSeconds != clamped {
            balanceRefreshIntervalSeconds = clamped
        }
        let normalized = String(Int(clamped))
        if customRefreshSecondsText != normalized {
            customRefreshSecondsText = normalized
        }
        withAnimation(.easeOut(duration: 0.15)) {
            savedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeIn(duration: 0.25)) {
                savedFeedback = false
            }
        }
    }

    private func clampedRefreshSeconds(_ value: Double) -> Double {
        min(max(value.rounded(), 1), 86_400)
    }

    private var canApplyCustomRefreshSeconds: Bool {
        guard let value = Double(customRefreshSecondsText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return false
        }
        return clampedRefreshSeconds(value) != balanceRefreshIntervalSeconds
    }

    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionCard(title: "Appearance") {
                HStack {
                    Toggle("Show icon", isOn: $menuBarShowsIcon)
                    Spacer()
                    Toggle("Show balance", isOn: $menuBarShowsText)
                }

                colorControlRow(
                    title: "Icon color",
                    hex: $menuBarIconColorHex,
                    fallback: "Hidden",
                    isEnabled: menuBarShowsIcon
                )

                colorControlRow(
                    title: "Text color",
                    hex: $menuBarTextColorHex,
                    fallback: "Hidden",
                    isEnabled: menuBarShowsText
                )

                labeledSlider("Icon opacity", value: $menuBarIconOpacity, range: 0.15...1, suffix: "%", scale: 100)
                labeledSlider("Text opacity", value: $menuBarTextOpacity, range: 0.15...1, suffix: "%", scale: 100)
                labeledSlider("Icon size", value: $menuBarIconSize, range: 10...20, suffix: "pt")
                labeledSlider("Text size", value: $menuBarTextSize, range: 7...14, suffix: "pt")

                VStack(alignment: .leading, spacing: 5) {
                    Text("Text weight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Text weight", selection: $menuBarTextWeight) {
                        ForEach(MenuBarFontWeight.allCases) { weight in
                            Text(weight.rawValue).tag(weight.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }

            Button("Reset Menu Bar Appearance") {
                resetMenuBarAppearance()
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var stickyMenuBarPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Live Preview")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Updates instantly")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            menuBarPreview
        }
        .padding(12)
        .background(Color.whalePanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.whaleStroke)
        )
    }

    private var menuBarPreview: some View {
        HStack {
            Spacer()
            HStack(spacing: menuBarShowsIcon && menuBarShowsText ? 3 : 0) {
                if menuBarShowsIcon {
                    Image(nsImage: Self.previewWhaleImage)
                        .resizable()
                        .renderingMode(.template)
                        .interpolation(.none)
                        .antialiased(false)
                        .foregroundStyle(Color(hex: menuBarIconColorHex).opacity(menuBarIconOpacity))
                        .frame(width: menuBarIconSize, height: menuBarIconSize)
                }

                if menuBarShowsText {
                    Text(vm.balanceBadgeText)
                        .font(.system(
                            size: menuBarTextSize,
                            weight: (MenuBarFontWeight(rawValue: menuBarTextWeight) ?? .semibold).weight
                        ))
                        .foregroundStyle(Color(hex: menuBarTextColorHex).opacity(menuBarTextOpacity))
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.black.opacity(0.74), in: Capsule())
            Spacer()
        }
    }

    private func colorControlRow(
        title: String,
        hex: Binding<String>,
        fallback: String,
        isEnabled: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(isEnabled ? hex.wrappedValue.uppercased() : fallback)
                .font(.caption)
                .monospaced()
                .foregroundColor(.secondary)

            NativeColorWell(colorHex: hex)
                .frame(width: 44, height: 24)
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1 : 0.45)
        }
        .frame(minHeight: 26)
    }

    private func labeledSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String,
        scale: Double = 1
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(value.wrappedValue * scale))\(suffix)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
            Slider(value: value, in: range)
        }
    }

    private func colorBinding(for hex: Binding<String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: hex.wrappedValue) },
            set: { hex.wrappedValue = $0.hexString }
        )
    }

    private func resetMenuBarAppearance() {
        menuBarShowsIcon = true
        menuBarShowsText = true
        menuBarIconColorHex = "#FFFFFF"
        menuBarTextColorHex = "#FFFFFF"
        menuBarIconOpacity = 1
        menuBarTextOpacity = 1
        menuBarIconSize = 20
        menuBarTextSize = 14
        menuBarTextWeight = MenuBarFontWeight.semibold.rawValue
    }

    private func testKey(_ key: String) async {
        isTesting = true
        testResult = nil
        testError = nil

        do {
            let ok = try await apiClient.testKey(apiKey: key)
            testResult = ok
            if !ok {
                testError = "Invalid key"
            }
        } catch {
            testResult = false
            testError = error.localizedDescription
        }

        isTesting = false
    }
}

private struct NativeColorWell: NSViewRepresentable {
    @Binding var colorHex: String

    func makeCoordinator() -> Coordinator {
        Coordinator(colorHex: $colorHex)
    }

    func makeNSView(context: Context) -> NSColorWell {
        let colorWell = ActivatingColorWell(frame: .zero)
        colorWell.color = NSColor(Color(hex: colorHex)).usingColorSpace(.deviceRGB) ?? .white
        colorWell.target = context.coordinator
        colorWell.action = #selector(Coordinator.colorChanged(_:))
        colorWell.isContinuous = true
        colorWell.isBordered = true
        colorWell.onActivate = { [weak coordinator = context.coordinator] in
            coordinator?.beginEditing()
        }
        context.coordinator.colorWell = colorWell
        context.coordinator.startObservingColorPanel()
        return colorWell
    }

    func updateNSView(_ colorWell: NSColorWell, context: Context) {
        let nextColor = NSColor(Color(hex: colorHex)).usingColorSpace(.deviceRGB) ?? .white
        if Color(nsColor: colorWell.color).hexString != Color(nsColor: nextColor).hexString {
            colorWell.color = nextColor
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        private static weak var activeCoordinator: Coordinator?

        @Binding private var colorHex: String
        weak var colorWell: NSColorWell?
        private var colorPanelObserver: NSObjectProtocol?

        init(colorHex: Binding<String>) {
            _colorHex = colorHex
        }

        func startObservingColorPanel() {
            guard colorPanelObserver == nil else { return }

            colorPanelObserver = NotificationCenter.default.addObserver(
                forName: NSColorPanel.colorDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.syncActiveColorWell()
                }
            }
        }

        func beginEditing() {
            Self.activeCoordinator = self
            if let colorWell {
                NSColorPanel.shared.color = colorWell.color
            }
        }

        @MainActor @objc func colorChanged(_ sender: NSColorWell) {
            Self.activeCoordinator = self
            setColor(sender.color)
        }

        @MainActor private func syncActiveColorWell() {
            guard Self.activeCoordinator === self else { return }
            setColor(NSColorPanel.shared.color)
        }

        @MainActor private func setColor(_ nsColor: NSColor) {
            colorHex = Color(nsColor: nsColor).hexString
            NotificationCenter.default.post(name: .menuBarAppearanceDidChange, object: nil)
        }
    }
}

private final class ActivatingColorWell: NSColorWell {
    var onActivate: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        NSApp.activate(ignoringOtherApps: true)
        onActivate?()
        activate(true)
        super.mouseDown(with: event)
    }
}

private enum SettingsTab: String, CaseIterable, Identifiable {
    case apiKey
    case menuBar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apiKey:
            return "API Key"
        case .menuBar:
            return "Menu Bar"
        }
    }
}
