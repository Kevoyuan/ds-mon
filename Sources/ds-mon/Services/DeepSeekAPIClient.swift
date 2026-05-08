import Foundation

actor DeepSeekAPIClient {
    private let session: URLSession
    private let baseURL = "https://api.deepseek.com"
    private let decoder: JSONDecoder

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    func fetchBalance(apiKey: String) async throws -> BalanceInfo? {
        guard let url = URL(string: "\(baseURL)/user/balance") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        let envelope = try decoder.decode(BalanceResponse.self, from: data)
        // Pick CNY first, fall back to first entry or USD
        let raw = envelope.balanceInfos?.first { $0.currency == "CNY" }
            ?? envelope.balanceInfos?.first
        guard let raw else { return nil }
        return BalanceInfo(raw: raw)
    }

    func testKey(apiKey: String) async throws -> Bool {
        do {
            _ = try await fetchBalance(apiKey: apiKey)
            return true
        } catch let error as APIError where error == .unauthorized {
            return false
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        switch http.statusCode {
        case 200...299: return
        case 401, 403: throw APIError.unauthorized
        case 429: throw APIError.rateLimited
        case 500...599: throw APIError.serverError(http.statusCode)
        default:
            if let body = String(data: data, encoding: .utf8) {
                throw APIError.unexpected(http.statusCode, body)
            }
            throw APIError.unexpected(http.statusCode, nil)
        }
    }
}

enum APIError: Error, Equatable, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError(Int)
    case unexpected(Int, String?)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "API key invalid or expired"
        case .rateLimited: return "Too many requests. Try again later."
        case .serverError(let code): return "Server error (HTTP \(code))"
        case .networkError(let msg): return "Network error: \(msg)"
        case .unexpected(let code, _): return "Unexpected response (HTTP \(code))"
        case .invalidURL, .invalidResponse: return "Internal error"
        }
    }
}
