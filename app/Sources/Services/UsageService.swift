import Foundation
import Combine

@MainActor
final class UsageService: ObservableObject {
    @Published var snapshot: UsageSnapshot?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasCookie = false

    private var organizationID: String?
    private var refreshTimer: Timer?
    private var resetTimers: [Timer] = []
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }()

    var refreshInterval: TimeInterval {
        let stored = UserDefaults.standard.double(forKey: "refreshIntervalSeconds")
        return stored > 0 ? stored : 60
    }

    init() {
        hasCookie = KeychainService.shared.getCookie() != nil
        if hasCookie {
            startAutoRefresh()
            Task { await refresh() }
        }
    }

    func saveCookie(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let cookie: String
        if trimmed.contains("sessionKey=") {
            cookie = trimmed
        } else {
            cookie = "sessionKey=\(trimmed)"
        }

        guard KeychainService.shared.saveCookie(cookie) else {
            errorMessage = "Failed to save cookie to Keychain."
            return
        }

        organizationID = nil
        hasCookie = true
        startAutoRefresh()
        Task { await refresh() }
    }

    func clearCookie() {
        KeychainService.shared.deleteCookie()
        hasCookie = false
        snapshot = nil
        organizationID = nil
        errorMessage = nil
        stopAutoRefresh()
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        let timer = Timer(timeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func updateRefreshInterval(seconds: TimeInterval) {
        UserDefaults.standard.set(seconds, forKey: "refreshIntervalSeconds")
        if hasCookie {
            startAutoRefresh()
        }
    }

    func refresh() async {
        guard let cookie = KeychainService.shared.getCookie() else {
            hasCookie = false
            errorMessage = UsageServiceError.missingCookie.localizedDescription
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if organizationID == nil {
                organizationID = try await fetchOrganizationID(cookie: cookie)
            }
            guard let organizationID else {
                throw UsageServiceError.organizationNotFound
            }
            let usage = try await fetchUsage(cookie: cookie, organizationID: organizationID)
            snapshot = usage
            errorMessage = nil
            scheduleResetRefreshes(for: usage)
        } catch let error as UsageServiceError {
            errorMessage = error.localizedDescription
            if case .unauthorized = error {
                organizationID = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchOrganizationID(cookie: String) async throws -> String {
        guard let url = URL(string: "https://claude.ai/api/organizations") else {
            throw UsageServiceError.invalidURL
        }

        let (data, response) = try await session.data(for: makeRequest(url: url, cookie: cookie))
        try validate(response: response, data: data)

        guard let organizations = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let first = organizations.first,
              let uuid = first["uuid"] as? String else {
            throw UsageServiceError.organizationNotFound
        }
        return uuid
    }

    private func fetchUsage(cookie: String, organizationID: String) async throws -> UsageSnapshot {
        guard let url = URL(string: "https://claude.ai/api/organizations/\(organizationID)/usage") else {
            throw UsageServiceError.invalidURL
        }

        let (data, response) = try await session.data(for: makeRequest(url: url, cookie: cookie))
        try validate(response: response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw UsageServiceError.invalidResponse
        }

        guard let sessionWindow = parseWindow(json["five_hour"]),
              let weeklyWindow = parseWindow(json["seven_day"]) else {
            throw UsageServiceError.invalidResponse
        }

        return UsageSnapshot(
            session: sessionWindow,
            weekly: weeklyWindow,
            weeklySonnet: parseWindow(json["seven_day_sonnet"]),
            weeklyOpus: parseWindow(json["seven_day_opus"]),
            lastUpdated: Date()
        )
    }

    private func scheduleResetRefreshes(for usage: UsageSnapshot) {
        resetTimers.forEach { $0.invalidate() }
        resetTimers.removeAll()

        let windows: [(String, UsageWindow)] = [
            ("session", usage.session),
            ("weekly", usage.weekly)
        ]

        for (_, window) in windows {
            let secondsUntilReset = window.resetsAt.timeIntervalSinceNow
            guard secondsUntilReset > 0 else {
                Task { await refresh() }
                continue
            }

            // Poll aggressively right before and exactly when a window resets.
            let leadUp = max(0, secondsUntilReset - 30)
            let timer = Timer(timeInterval: leadUp, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.refresh()
                    self?.startBurstPolling()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            resetTimers.append(timer)
        }
    }

    private func startBurstPolling() {
        var polls = 0
        let burst = Timer(timeInterval: 5, repeats: true) { [weak self] timer in
            polls += 1
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
            if polls >= 12 {
                timer.invalidate()
            }
        }
        RunLoop.main.add(burst, forMode: .common)
        resetTimers.append(burst)
    }

    private func makeRequest(url: URL, cookie: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "GET"
        request.setValue(cookie, forHTTPHeaderField: "Cookie")
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("https://claude.ai", forHTTPHeaderField: "Origin")
        request.setValue("https://claude.ai/settings/usage", forHTTPHeaderField: "Referer")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw UsageServiceError.invalidResponse
        }
        switch http.statusCode {
        case 200:
            return
        case 401, 403:
            throw UsageServiceError.unauthorized
        default:
            if let body = String(data: data, encoding: .utf8) {
                print("Claude API error \(http.statusCode): \(body.prefix(200))")
            }
            throw UsageServiceError.serverError(http.statusCode)
        }
    }

    private func parseWindow(_ value: Any?) -> UsageWindow? {
        guard let dict = value as? [String: Any],
              let utilization = parseUtilization(dict["utilization"]),
              let resetString = dict["resets_at"] as? String,
              let resetsAt = parseISO8601(resetString) else {
            return nil
        }
        return UsageWindow(utilization: utilization, resetsAt: resetsAt)
    }

    private func parseUtilization(_ value: Any?) -> Double? {
        switch value {
        case let number as Double:
            return number
        case let number as Int:
            return Double(number)
        case let number as NSNumber:
            return number.doubleValue
        default:
            return nil
        }
    }

    private func parseISO8601(_ string: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: string) {
            return date
        }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }
}
