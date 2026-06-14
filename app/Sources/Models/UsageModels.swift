import Foundation

struct UsageWindow: Equatable {
    let utilization: Double
    let resetsAt: Date

    var percent: Double {
        let value = utilization <= 1 ? utilization * 100 : utilization
        return min(max(value, 0), 100)
    }
}

struct UsageSnapshot: Equatable {
    let session: UsageWindow
    let weekly: UsageWindow
    let weeklySonnet: UsageWindow?
    let weeklyOpus: UsageWindow?
    let lastUpdated: Date
}

enum UsageServiceError: LocalizedError {
    case missingCookie
    case invalidURL
    case unauthorized
    case serverError(Int)
    case invalidResponse
    case organizationNotFound

    var errorDescription: String? {
        switch self {
        case .missingCookie:
            return "No session cookie saved. Open Settings to add your claude.ai session."
        case .invalidURL:
            return "Invalid API URL."
        case .unauthorized:
            return "Session expired. Paste a fresh sessionKey from claude.ai."
        case .serverError(let code):
            return "Claude API returned status \(code)."
        case .invalidResponse:
            return "Could not parse usage response."
        case .organizationNotFound:
            return "Could not find your Claude organization."
        }
    }
}
