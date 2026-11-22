import Foundation
import CloudKit
import Security

public final class iCloudSyncManager: ObservableObject {
    private var container: CKContainer?
    private var database: CKDatabase?

    @Published public var isSyncing = false
    @Published public var syncEnabled = false
    @Published public var lastSyncDate: Date?
    @Published public private(set) var isEntitlementAvailable = false
    @Published public private(set) var statusMessage: String = ""

    private let recordType = "ClipboardItem"

    public init() {
        isEntitlementAvailable = Self.hasCloudKitEntitlement()
        loadSyncSettings()
        if syncEnabled && isEntitlementAvailable {
            setupCloudKit()
        } else if !isEntitlementAvailable {
            syncEnabled = false
            statusMessage = "Requires an Apple Developer signed build with iCloud entitlement."
        }
    }

    private static func hasCloudKitEntitlement() -> Bool {
        guard let task = SecTaskCreateFromSelf(nil) else { return false }
        guard let value = SecTaskCopyValueForEntitlement(
            task,
            "com.apple.developer.icloud-container-identifiers" as CFString,
            nil
        ) else {
            return false
        }
        if let containers = value as? [String] {
            return !containers.isEmpty
        }
        return false
    }

    private func loadSyncSettings() {
        syncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        if let lastSync = UserDefaults.standard.object(forKey: "LastSyncDate") as? Date {
            lastSyncDate = lastSync
        }
    }

    private func setupCloudKit() {
        guard isEntitlementAvailable else { return }
        container = CKContainer.default()
        database = container?.privateCloudDatabase
        checkiCloudStatus()
    }

    public func toggleSync(_ enabled: Bool) {
        guard isEntitlementAvailable else {
            syncEnabled = false
            statusMessage = "Requires an Apple Developer signed build with iCloud entitlement."
            return
        }

        syncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "iCloudSyncEnabled")

        if enabled {
            setupCloudKit()
            fetchRemoteItems { items in
                DispatchQueue.main.async {
                    ClipboardManager.shared.mergeRemoteItems(items)
                }
            }
        } else {
            container = nil
            database = nil
            statusMessage = "Disabled"
        }
    }

    private func checkiCloudStatus() {
        container?.accountStatus { [weak self] status, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                switch status {
                case .available:
                    self.statusMessage = "Connected to iCloud"
                case .noAccount, .restricted:
                    self.syncEnabled = false
                    self.statusMessage = "Sign in to iCloud in System Settings"
                case .couldNotDetermine, .temporarilyUnavailable:
                    self.statusMessage = "iCloud temporarily unavailable"
                @unknown default:
                    break
                }
            }
        }
    }

    public func syncClipboardItem(_ item: ClipboardItem) {
        guard syncEnabled, isEntitlementAvailable, let database else { return }
        guard item.type != .image else { return }

        isSyncing = true

        let record = CKRecord(recordType: recordType)
        record["id"] = item.id.uuidString as CKRecordValue
        record["content"] = item.content as CKRecordValue
        record["type"] = item.type.rawValue as CKRecordValue
        record["isPinned"] = item.isPinned as CKRecordValue
        record["timestamp"] = item.timestamp as CKRecordValue

        database.save(record) { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSyncing = false
                if error == nil {
                    self.lastSyncDate = Date()
                    UserDefaults.standard.set(self.lastSyncDate, forKey: "LastSyncDate")
                }
            }
        }
    }

    public func fetchRemoteItems(completion: @escaping ([ClipboardItem]) -> Void) {
        guard syncEnabled, isEntitlementAvailable, let database else {
            completion([])
            return
        }

        isSyncing = true

        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 100) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSyncing = false

                guard case .success(let payload) = result else {
                    completion([])
                    return
                }

                let records = payload.matchResults.compactMap { _, recordResult -> CKRecord? in
                    try? recordResult.get()
                }

                let items = records.compactMap { record -> ClipboardItem? in
                    guard let idString = record["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let content = record["content"] as? String,
                          let typeString = record["type"] as? String,
                          let type = ClipboardItemType(rawValue: typeString),
                          let isPinned = record["isPinned"] as? Bool,
                          let timestamp = record["timestamp"] as? Date else {
                        return nil
                    }

                    if type == .text {
                        let entities = SmartDetector.detectEntities(in: content)
                        return ClipboardItem(
                            id: id,
                            content: content,
                            type: type,
                            isPinned: isPinned,
                            timestamp: timestamp,
                            imageFileName: nil,
                            detectedEntities: entities
                        )
                    } else if type == .url {
                        return ClipboardItem(
                            id: id,
                            content: content,
                            type: type,
                            isPinned: isPinned,
                            timestamp: timestamp,
                            imageFileName: nil,
                            detectedEntities: []
                        )
                    }

                    return nil
                }

                self.lastSyncDate = Date()
                UserDefaults.standard.set(self.lastSyncDate, forKey: "LastSyncDate")
                completion(items)
            }
        }
    }
}
