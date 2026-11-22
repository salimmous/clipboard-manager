import Foundation
import AppKit
import UserNotifications

// MARK: - Scheduled Clear Manager
public final class ScheduledClearManager: ObservableObject {
    private var isLoading = true
    private let defaults: UserDefaults

    @Published public var isEnabled: Bool = false {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published public var clearInterval: TimeInterval = 24 * 60 * 60 {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published public var clearOnlyUnpinned: Bool = true {
        didSet { if !isLoading { saveSettings() } }
    }

    private var clearTimer: Timer?
    private weak var clipboardManager: ClipboardManager?

    public enum ClearInterval: String, CaseIterable, Identifiable {
        case oneHour = "1 Hour"
        case sixHours = "6 Hours"
        case twelveHours = "12 Hours"
        case oneDay = "1 Day"
        case threeDays = "3 Days"
        case oneWeek = "1 Week"

        public var id: String { rawValue }

        public var timeInterval: TimeInterval {
            switch self {
            case .oneHour: return 60 * 60
            case .sixHours: return 6 * 60 * 60
            case .twelveHours: return 12 * 60 * 60
            case .oneDay: return 24 * 60 * 60
            case .threeDays: return 3 * 24 * 60 * 60
            case .oneWeek: return 7 * 24 * 60 * 60
            }
        }

        public static func matching(_ interval: TimeInterval) -> ClearInterval {
            allCases.first(where: { abs($0.timeInterval - interval) < 1 }) ?? .oneDay
        }
    }

    public init(clipboardManager: ClipboardManager, defaults: UserDefaults = .standard) {
        self.clipboardManager = clipboardManager
        self.defaults = defaults
        loadSettings()
        setupTimer()
        isLoading = false
    }

    private func loadSettings() {
        isEnabled = defaults.bool(forKey: "ScheduledClearEnabled")
        let savedInterval = defaults.double(forKey: "ScheduledClearInterval")
        clearInterval = savedInterval > 0 ? savedInterval : 24 * 60 * 60
        clearOnlyUnpinned = defaults.object(forKey: "ScheduledClearOnlyUnpinned") != nil
            ? defaults.bool(forKey: "ScheduledClearOnlyUnpinned")
            : true
    }

    public func saveSettings() {
        defaults.set(isEnabled, forKey: "ScheduledClearEnabled")
        defaults.set(clearInterval, forKey: "ScheduledClearInterval")
        defaults.set(clearOnlyUnpinned, forKey: "ScheduledClearOnlyUnpinned")
        setupTimer()
    }

    private func setupTimer() {
        clearTimer?.invalidate()
        clearTimer = nil
        guard isEnabled else { return }

        // Check periodically (at least every 15 minutes) rather than waiting an entire week for the first tick.
        let checkCadence = min(clearInterval, 15 * 60)
        clearTimer = Timer.scheduledTimer(withTimeInterval: checkCadence, repeats: true) { [weak self] _ in
            self?.performScheduledClear()
        }
    }

    @discardableResult
    public func performScheduledClear() -> Int {
        guard let clipboardManager else { return 0 }
        let cutoffDate = Date().addingTimeInterval(-clearInterval)
        let removedCount = clipboardManager.removeItems(olderThan: cutoffDate, preservePinned: clearOnlyUnpinned)

        if removedCount > 0 {
            let content = UNMutableNotificationContent()
            content.title = "Clipboard Auto-Cleared"
            content.body = "Removed \(removedCount) old clipboard item\(removedCount == 1 ? "" : "s")."
            let request = UNNotificationRequest(identifier: "ClipboardCleared", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
        return removedCount
    }

    public func setClearInterval(_ interval: ClearInterval) {
        clearInterval = interval.timeInterval
    }
}

// MARK: - Integration Manager
public final class IntegrationManager: ObservableObject {
    private var isLoading = true
    private let defaults: UserDefaults

    @Published public var slackWebhookURL: String = "" {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published public var discordWebhookURL: String = "" {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published public var defaultEmailApp: EmailApp = .mail {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published public var defaultNotesApp: NotesApp = .notes {
        didSet { if !isLoading { saveSettings() } }
    }

    public var isSlackConfigured: Bool {
        validWebhookURL(from: slackWebhookURL) != nil
    }

    public var isDiscordConfigured: Bool {
        validWebhookURL(from: discordWebhookURL) != nil
    }

    public enum EmailApp: String, CaseIterable {
        case mail = "Mail"
        case outlook = "Microsoft Outlook"
        case gmail = "Gmail"
        case spark = "Spark"

        public var bundleID: String {
            switch self {
            case .mail: return "com.apple.mail"
            case .outlook: return "com.microsoft.Outlook"
            case .gmail: return "com.google.Gmail"
            case .spark: return "com.readdle.smartemail-Mac"
            }
        }
    }

    public enum NotesApp: String, CaseIterable {
        case notes = "Notes"
        case notion = "Notion"
        case obsidian = "Obsidian"
        case bear = "Bear"
        case devonthink = "DEVONthink"

        public var bundleID: String {
            switch self {
            case .notes: return "com.apple.Notes"
            case .notion: return "notion.id"
            case .obsidian: return "md.obsidian"
            case .bear: return "net.shinyfrog.bear"
            case .devonthink: return "com.devon-technologies.think3"
            }
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadSettings()
        isLoading = false
    }

    private func loadSettings() {
        slackWebhookURL = defaults.string(forKey: "SlackWebhookURL") ?? ""
        discordWebhookURL = defaults.string(forKey: "DiscordWebhookURL") ?? ""
        if let emailAppString = defaults.string(forKey: "DefaultEmailApp"),
           let emailApp = EmailApp(rawValue: emailAppString) {
            defaultEmailApp = emailApp
        }
        if let notesAppString = defaults.string(forKey: "DefaultNotesApp"),
           let notesApp = NotesApp(rawValue: notesAppString) {
            defaultNotesApp = notesApp
        }
    }

    public func saveSettings() {
        defaults.set(slackWebhookURL, forKey: "SlackWebhookURL")
        defaults.set(discordWebhookURL, forKey: "DiscordWebhookURL")
        defaults.set(defaultEmailApp.rawValue, forKey: "DefaultEmailApp")
        defaults.set(defaultNotesApp.rawValue, forKey: "DefaultNotesApp")
    }

    private func validWebhookURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              url.scheme?.lowercased() == "https",
              url.host != nil else {
            return nil
        }
        return url
    }

    public func shareToSlack(_ content: String) {
        guard let url = validWebhookURL(from: slackWebhookURL) else {
            showError("Slack webhook URL must be a valid https:// URL")
            return
        }

        let payload: [String: Any] = [
            "text": content,
            "username": "Clipboard Manager",
            "icon_emoji": ":clipboard:"
        ]

        sendWebhookMessage(to: url, payload: payload, service: "Slack")
    }

    public func shareToDiscord(_ content: String) {
        guard let url = validWebhookURL(from: discordWebhookURL) else {
            showError("Discord webhook URL must be a valid https:// URL")
            return
        }

        let payload: [String: Any] = [
            "content": String(content.prefix(2000)),
            "username": "Clipboard Manager"
        ]

        sendWebhookMessage(to: url, payload: payload, service: "Discord")
    }

    private func sendWebhookMessage(to url: URL, payload: [String: Any], service: String) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            showError("Failed to encode message for \(service)")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.showError("Failed to send to \(service): \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) {
                    self.showSuccess("Sent to \(service)!")
                } else {
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    self.showError("Failed to send to \(service) (HTTP \(status))")
                }
            }
        }.resume()
    }

    public func composeEmail(with content: String, subject: String = "Shared from Clipboard") {
        var components = URLComponents()
        components.scheme = "mailto"
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: content)
        ]
        guard let url = components.url else { return }

        switch defaultEmailApp {
        case .mail:
            NSWorkspace.shared.open(url)
        case .outlook, .gmail, .spark:
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: defaultEmailApp.bundleID) {
                NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
            } else {
                showError("\(defaultEmailApp.rawValue) is not installed")
            }
        }
    }

    public func saveToNotes(_ content: String, title: String = "Clipboard Item") {
        let success: Bool

        switch defaultNotesApp {
        case .notes:
            var components = URLComponents()
            components.scheme = "notes"
            components.host = "new"
            components.queryItems = [
                URLQueryItem(name: "title", value: title),
                URLQueryItem(name: "content", value: content)
            ]
            success = components.url.map { NSWorkspace.shared.open($0) } ?? false
        case .notion:
            ClipboardManager.shared.copyPlainTextToClipboard(content)
            success = URL(string: "notion://new").map { NSWorkspace.shared.open($0) } ?? false
        case .obsidian:
            var components = URLComponents()
            components.scheme = "obsidian"
            components.host = "new"
            components.queryItems = [
                URLQueryItem(name: "name", value: title),
                URLQueryItem(name: "content", value: content)
            ]
            success = components.url.map { NSWorkspace.shared.open($0) } ?? false
        case .bear:
            var components = URLComponents()
            components.scheme = "bear"
            components.host = "x-callback-url"
            components.path = "/create"
            components.queryItems = [
                URLQueryItem(name: "title", value: title),
                URLQueryItem(name: "text", value: content)
            ]
            success = components.url.map { NSWorkspace.shared.open($0) } ?? false
        case .devonthink:
            var components = URLComponents()
            components.scheme = "x-devonthink"
            components.host = "createText"
            components.queryItems = [
                URLQueryItem(name: "title", value: title),
                URLQueryItem(name: "text", value: content)
            ]
            success = components.url.map { NSWorkspace.shared.open($0) } ?? false
        }

        if success {
            showSuccess("Opened \(defaultNotesApp.rawValue)!")
        } else {
            showError("Failed to open \(defaultNotesApp.rawValue). Make sure it is installed.")
        }
    }

    private func showError(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Integration Error"
        content.body = message
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }

    private func showSuccess(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Shared"
        content.body = message
        content.sound = nil
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }
}
