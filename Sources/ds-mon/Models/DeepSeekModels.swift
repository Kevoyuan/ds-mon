import Foundation

struct BalanceResponse: Codable {
    let isAvailable: Bool?
    let balanceInfos: [BalanceInfoRaw]?

    enum CodingKeys: String, CodingKey {
        case isAvailable = "is_available"
        case balanceInfos = "balance_infos"
    }
}

struct BalanceInfoRaw: Codable {
    let currency: String?
    let totalBalance: String?
    let grantedBalance: String?
    let toppedUpBalance: String?

    enum CodingKeys: String, CodingKey {
        case currency
        case totalBalance = "total_balance"
        case grantedBalance = "granted_balance"
        case toppedUpBalance = "topped_up_balance"
    }
}

struct BalanceInfo: Codable {
    let currency: String?
    let totalBalance: Double
    let grantedBalance: Double
    let toppedUpBalance: Double

    init(raw: BalanceInfoRaw) {
        currency = raw.currency
        totalBalance = Double(raw.totalBalance ?? "0") ?? 0
        grantedBalance = Double(raw.grantedBalance ?? "0") ?? 0
        toppedUpBalance = Double(raw.toppedUpBalance ?? "0") ?? 0
    }
}

struct StoredAPIKey: Codable, Identifiable, Equatable {
    let id: UUID
    let label: String
    let key: String

    var maskedKey: String {
        guard key.count > 10 else {
            return String(repeating: "*", count: min(key.count, 8))
        }
        return String(key.prefix(5)) + "****" + String(key.suffix(4))
    }

    init(id: UUID = UUID(), label: String, key: String) {
        self.id = id
        self.label = label
        self.key = key
    }
}
