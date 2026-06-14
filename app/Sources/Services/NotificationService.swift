import AppKit
import Foundation
import UserNotifications

enum LimitKind: String, CaseIterable {
    case session = "five_hour"
    case weekly = "seven_day"

    var title: String {
        switch self {
        case .session: return "5-hour limit"
        case .weekly: return "Weekly limit"
        }
    }

    var notificationPrefix: String {
        switch self {
        case .session: return "session"
        case .weekly: return "weekly"
        }
    }
}

@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private var lastThresholdNotified: [String: Int] = [:]
    private var pendingResetAlerts: Set<String> = []

    private let warningThresholds = [75, 85, 90, 95]

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if !granted {
                print("Notification permission denied.")
            }
        }
    }

    func handle(snapshot: UsageSnapshot?, previous: UsageSnapshot?) {
        guard let snapshot else { return }

        evaluate(window: snapshot.session, kind: .session, previous: previous?.session)
        evaluate(window: snapshot.weekly, kind: .weekly, previous: previous?.weekly)

        scheduleExactResetNotification(for: snapshot.session, kind: .session)
        scheduleExactResetNotification(for: snapshot.weekly, kind: .weekly)
    }

    private func evaluate(window: UsageWindow, kind: LimitKind, previous: UsageWindow?) {
        let percent = Int(window.percent.rounded())
        let key = kind.rawValue

        for threshold in warningThresholds where percent >= threshold {
            let thresholdKey = "\(key)-warn-\(threshold)"
            if lastThresholdNotified[key, default: 0] < threshold {
                lastThresholdNotified[key] = threshold
                deliver(
                    identifier: thresholdKey,
                    title: "\(kind.title) at \(threshold)%",
                    body: "You are at \(percent)% with \(ResetTimeFormatter.countdown(to: window.resetsAt)) until reset at \(ResetTimeFormatter.exact(window.resetsAt)).",
                    interruption: .timeSensitive
                )
            }
        }

        if percent < 60 {
            lastThresholdNotified[key] = 0
        }

        guard let previous, didWindowReset(current: window, previous: previous, kind: kind) else {
            return
        }

        let alertID = "\(kind.notificationPrefix)-reset-\(Int(window.resetsAt.timeIntervalSince1970))"
        guard !pendingResetAlerts.contains(alertID) else { return }

        pendingResetAlerts.insert(alertID)
        deliverResetAlert(kind: kind, resetsAt: window.resetsAt, identifier: alertID)
    }

    /// Only treat a window as reset when *that* window's usage dropped sharply and its
    /// reset clock jumped forward — avoids false positives from rolling weekly timestamps.
    private func didWindowReset(current: UsageWindow, previous: UsageWindow, kind: LimitKind) -> Bool {
        let usageDropped = previous.percent - current.percent >= 20
        let usageCleared = current.percent <= 30
        let wasHigh = previous.percent >= 45

        let minimumAdvance: TimeInterval = kind == .session ? 45 * 60 : 12 * 3600
        let resetAdvanced = current.resetsAt.timeIntervalSince(previous.resetsAt) >= minimumAdvance

        return wasHigh && usageCleared && usageDropped && resetAdvanced
    }

    private func deliverResetAlert(kind: LimitKind, resetsAt: Date, identifier: String) {
        deliver(
            identifier: identifier,
            title: "\(kind.title) has reset",
            body: "Your \(kind.title.lowercased()) is available again. Next reset: \(ResetTimeFormatter.exact(resetsAt)).",
            interruption: .timeSensitive,
            sound: true
        )
        showPersistentAlert(
            title: "\(kind.title) has reset",
            message: "Your \(kind.title.lowercased()) is available again.\n\nNext reset: \(ResetTimeFormatter.exact(resetsAt))"
        )
    }

    private func scheduleExactResetNotification(for window: UsageWindow, kind: LimitKind) {
        let identifier = "\(kind.notificationPrefix)-scheduled-reset"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let interval = window.resetsAt.timeIntervalSinceNow
        guard interval > 5 else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(kind.title) has reset"
        content.body = "Your \(kind.title.lowercased()) just reset. You are good to go."
        content.sound = .default
        if #available(macOS 12.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    private func deliver(
        identifier: String,
        title: String,
        body: String,
        interruption: UNNotificationInterruptionLevel = .active,
        sound: Bool = true
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if sound {
            content.sound = .default
        }
        if #available(macOS 12.0, *) {
            content.interruptionLevel = interruption
        }

        let request = UNNotificationRequest(
            identifier: "\(identifier)-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    private func showPersistentAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
