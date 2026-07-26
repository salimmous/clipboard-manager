import Foundation
import AppKit
import UserNotifications

// MARK: - Scheduled Clear Manager
class ScheduledClearManager: ObservableObject {
    private var isLoading = true
    
    @Published var isEnabled: Bool = false {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var clearInterval: TimeInterval = 24 * 60 * 60 {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var clearOnlyUnpinned: Bool = true {
        didSet { if !isLoading { saveSettings() } }
    }
    
    private var clearTimer: Timer?
    private weak var clipboardManager: ClipboardManager?
    
    enum ClearInterval: String, CaseIterable {
        case oneHour = "1 Hour"
        case sixHours = "6 Hours" 
        case twelveHours = "12 Hours"
        case oneDay = "1 Day"
        case threeDays = "3 Days"
        case oneWeek = "1 Week"
        
        var timeInterval: TimeInterval {
            switch self {
            case .oneHour: return 60 * 60
            case .sixHours: return 6 * 60 * 60
            case .twelveHours: return 12 * 60 * 60
            case .oneDay: return 24 * 60 * 60
            case .threeDays: return 3 * 24 * 60 * 60
            case .oneWeek: return 7 * 24 * 60 * 60
            }
        }
    }
    
    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
        loadSettings()
        setupTimer()
        isLoading = false
    }
    
    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "ScheduledClearEnabled")
        clearInterval = UserDefaults.standard.double(forKey: "ScheduledClearInterval")
        if clearInterval == 0 { clearInterval = 24 * 60 * 60 }
        clearOnlyUnpinned = UserDefaults.standard.bool(forKey: "ScheduledClearOnlyUnpinned")
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: "ScheduledClearEnabled")
        UserDefaults.standard.set(clearInterval, forKey: "ScheduledClearInterval")
        UserDefaults.standard.set(clearOnlyUnpinned, forKey: "ScheduledClearOnlyUnpinned")
        UserDefaults.standard.synchronize()
        setupTimer()
    }
    
    private func setupTimer() {
        clearTimer?.invalidate()
        guard isEnabled else { return }
        clearTimer = Timer.scheduledTimer(withTimeInterval: clearInterval, repeats: true) { [weak self] _ in
            self?.performScheduledClear()
        }
    }
    
    private func performScheduledClear() {
        guard let clipboardManager = clipboardManager else { return }
        let cutoffDate = Date().addingTimeInterval(-clearInterval)
        
        if clearOnlyUnpinned {
            clipboardManager.items.removeAll { item in
                !item.isPinned && item.timestamp < cutoffDate
            }
        } else {
            clipboardManager.items.removeAll { item in
                item.timestamp < cutoffDate
            }
        }
        clipboardManager.saveItems()
        
        let content = UNMutableNotificationContent()
        content.title = "Clipboard Cleared"
        content.body = "Old clipboard items have been automatically cleared"
        let request = UNNotificationRequest(identifier: "ClipboardCleared", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func toggleScheduledClear(_ enabled: Bool) {
        isEnabled = enabled
        saveSettings()
    }
    
    func setClearInterval(_ interval: ClearInterval) {
        clearInterval = interval.timeInterval
        saveSettings()
    }
}

// MARK: - Integration Manager
class IntegrationManager: ObservableObject {
    private var isLoading = true
    
    @Published var slackWebhookURL: String = "" {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var discordWebhookURL: String = "" {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var defaultEmailApp: EmailApp = .mail {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var defaultNotesApp: NotesApp = .notes {
        didSet { if !isLoading { saveSettings() } }
    }
    
    enum EmailApp: String, CaseIterable {
        case mail = "Mail"
        case outlook = "Microsoft Outlook"
        case gmail = "Gmail"
        case spark = "Spark"
        
        var bundleID: String {
            switch self {
            case .mail: return "com.apple.mail"
            case .outlook: return "com.microsoft.Outlook"
            case .gmail: return "com.google.Gmail"
            case .spark: return "com.readdle.smartemail-Mac"
            }
        }
    }
    
    enum NotesApp: String, CaseIterable {
        case notes = "Notes"
        case notion = "Notion"
        case obsidian = "Obsidian"
        case bear = "Bear"
        case devonthink = "DEVONthink"
        
        var bundleID: String {
            switch self {
            case .notes: return "com.apple.Notes"
            case .notion: return "notion.id"
            case .obsidian: return "md.obsidian"
            case .bear: return "net.shinyfrog.bear"
            case .devonthink: return "com.devon-technologies.think3"
            }
        }
    }
    
    init() {
        loadSettings()
        isLoading = false
    }
    
    private func loadSettings() {
        slackWebhookURL = UserDefaults.standard.string(forKey: "SlackWebhookURL") ?? ""
        discordWebhookURL = UserDefaults.standard.string(forKey: "DiscordWebhookURL") ?? ""
        if let emailAppString = UserDefaults.standard.string(forKey: "DefaultEmailApp"),
           let emailApp = EmailApp(rawValue: emailAppString) {
            defaultEmailApp = emailApp
        }
        if let notesAppString = UserDefaults.standard.string(forKey: "DefaultNotesApp"),
           let notesApp = NotesApp(rawValue: notesAppString) {
            defaultNotesApp = notesApp
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(slackWebhookURL, forKey: "SlackWebhookURL")
        UserDefaults.standard.set(discordWebhookURL, forKey: "DiscordWebhookURL")
        UserDefaults.standard.set(defaultEmailApp.rawValue, forKey: "DefaultEmailApp")
        UserDefaults.standard.set(defaultNotesApp.rawValue, forKey: "DefaultNotesApp")
        UserDefaults.standard.synchronize()
    }
    
    func shareToSlack(_ content: String, channel: String = "#general") {
        guard !slackWebhookURL.isEmpty, let url = URL(string: slackWebhookURL) else {
            showError("Slack webhook URL not configured")
            return
        }
        
        let payload = [
            "text": content,
            "channel": channel,
            "username": "Clipboard Manager",
            "icon_emoji": ":clipboard:"
        ]
        
        sendWebhookMessage(to: url, payload: payload, service: "Slack")
    }
    
    func shareToDiscord(_ content: String) {
        guard !discordWebhookURL.isEmpty, let url = URL(string: discordWebhookURL) else {
            showError("Discord webhook URL not configured")
            return
        }
        
        let payload = [
            "content": content,
            "username": "Clipboard Manager"
        ]
        
        sendWebhookMessage(to: url, payload: payload, service: "Discord")
    }
    
    private func sendWebhookMessage(to url: URL, payload: [String: Any], service: String) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            showError("Failed to encode message for \(service)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showError("Failed to send to \(service): \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.showSuccess("Sent to \(service) successfully!")
                } else {
                    self.showError("Failed to send to \(service)")
                }
            }
        }.resume()
    }
    
    func composeEmail(with content: String, subject: String = "Shared from Clipboard") {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        switch defaultEmailApp {
        case .mail:
            let mailtoURL = "mailto:?subject=\(encodedSubject)&body=\(encodedBody)"
            if let url = URL(string: mailtoURL) {
                NSWorkspace.shared.open(url)
            }
        case .outlook, .gmail, .spark:
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: defaultEmailApp.bundleID) {
                let mailtoURL = "mailto:?subject=\(encodedSubject)&body=\(encodedBody)"
                if let url = URL(string: mailtoURL) {
                    NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
                }
            } else {
                showError("\(defaultEmailApp.rawValue) is not installed")
            }
        }
    }
    
    func saveToNotes(_ content: String, title: String = "Clipboard Item") {
        let success: Bool
        
        switch defaultNotesApp {
        case .notes:
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "notes://new?title=\(encodedTitle)&content=\(encodedContent)") {
                success = NSWorkspace.shared.open(url)
            } else {
                success = false
            }
        case .notion:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
            if let url = URL(string: "notion://new") {
                success = NSWorkspace.shared.open(url)
            } else {
                success = false
            }
        case .obsidian:
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "obsidian://new?name=\(encodedTitle)&content=\(encodedContent)") {
                success = NSWorkspace.shared.open(url)
            } else {
                success = false
            }
        case .bear:
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "bear://x-callback-url/create?title=\(encodedTitle)&text=\(encodedContent)") {
                success = NSWorkspace.shared.open(url)
            } else {
                success = false
            }
        case .devonthink:
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "x-devonthink://createText?title=\(encodedTitle)&text=\(encodedContent)") {
                success = NSWorkspace.shared.open(url)
            } else {
                success = false
            }
        }
        
        if success {
            showSuccess("Opened \(defaultNotesApp.rawValue) successfully!")
        } else {
            showError("Failed to open \(defaultNotesApp.rawValue). Make sure it's installed.")
        }
    }
    
    private func showError(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Integration Error"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showSuccess(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Success"
        content.body = message
        content.sound = nil
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
