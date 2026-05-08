import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    var apiKey: StoredAPIKey?
    var apiKeyLabel: String = "Default"
    var onboardingKey: String = ""
    var isLoading = false
    var isFirstLoad = true
    var sectionErrors: [String: String] = [:]
    var lastUpdated: Date?
    var balance: BalanceInfo?
    var onMenuBarNeedsUpdate: (() -> Void)?

    private let apiClient = DeepSeekAPIClient()
    private var refreshTask: Task<Void, Never>?

    var hasAPIKey: Bool {
        apiKey != nil
    }

    var balanceBadgeText: String {
        guard let balance else { return "--" }
        return formatBalance(balance.totalBalance, currency: balance.currency)
    }

    var refreshIntervalText: String {
        Self.formatRefreshInterval(refreshIntervalSeconds)
    }

    func onAppear() async {
        do {
            let keys = try KeychainManager.load()
            apiKey = keys.first
            if let key = keys.first {
                apiKeyLabel = key.label
            }
        } catch {
            sectionErrors["_global"] = error.localizedDescription
        }

        isFirstLoad = false
        onMenuBarNeedsUpdate?()
        startAutoRefresh()

        if apiKey != nil {
            await refresh()
        }
    }

    func onDisappear() {
        stopAutoRefresh()
    }

    func connectOnboarding() async {
        let trimmed = onboardingKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        sectionErrors["_global"] = nil

        do {
            let ok = try await apiClient.testKey(apiKey: trimmed)
            if ok {
                let newKey = StoredAPIKey(label: "Default", key: trimmed)
                apiKey = newKey
                apiKeyLabel = "Default"
                onboardingKey = ""
                try? KeychainManager.save([newKey])
                onMenuBarNeedsUpdate?()
                await refresh()
            } else {
                sectionErrors["_global"] = "API key invalid or expired."
            }
        } catch {
            sectionErrors["_global"] = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        guard let key = apiKey?.key else {
            sectionErrors["_global"] = "Add an API key in Settings to get started."
            return
        }

        isLoading = true
        sectionErrors["_global"] = nil

        do {
            balance = try await apiClient.fetchBalance(apiKey: key)
            lastUpdated = Date()
        } catch let error as APIError {
            sectionErrors["_global"] = error.localizedDescription
        } catch {
            sectionErrors["_global"] = "Network error: \(error.localizedDescription)"
        }

        isLoading = false
        onMenuBarNeedsUpdate?()
    }

    func saveAPIKey(label: String, key: String) {
        let newKey = StoredAPIKey(label: label, key: key)
        apiKey = newKey
        apiKeyLabel = label
        do {
            try KeychainManager.save([newKey])
        } catch {
            sectionErrors["_global"] = error.localizedDescription
        }
        onMenuBarNeedsUpdate?()
    }

    func removeAPIKey() {
        apiKey = nil
        balance = nil
        KeychainManager.deleteAll()
        onMenuBarNeedsUpdate?()
    }

    func restartAutoRefresh() {
        startAutoRefresh()
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(refreshIntervalSeconds))
                guard !Task.isCancelled else { break }
                await self.refresh()
            }
        }
    }

    private func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func formatBalance(_ value: Double, currency: String?) -> String {
        switch currency?.uppercased() {
        case "USD":
            return String(format: "$%.2f", value)
        case "CNY":
            return String(format: "¥%.2f", value)
        default:
            return String(format: "%.2f", value)
        }
    }

    private var refreshIntervalSeconds: TimeInterval {
        let stored = UserDefaults.standard.double(forKey: "balanceRefreshIntervalSeconds")
        return stored > 0 ? stored : 60
    }

    static func formatRefreshInterval(_ seconds: TimeInterval) -> String {
        let rounded = Int(seconds.rounded())
        if rounded < 60 {
            return "\(rounded) seconds"
        }
        if rounded < 3600 {
            let minutes = rounded / 60
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        }

        let hours = rounded / 3600
        return hours == 1 ? "1 hour" : "\(hours) hours"
    }
}
