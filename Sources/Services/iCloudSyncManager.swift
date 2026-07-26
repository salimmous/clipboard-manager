import Foundation
import CloudKit

class iCloudSyncManager: ObservableObject {
    private var container: CKContainer?
    private var database: CKDatabase?
    @Published var isSyncing = false
    @Published var syncEnabled = false
    @Published var lastSyncDate: Date?
    
    private let recordType = "ClipboardItem"
    
    init() {
        loadSyncSettings()
        if syncEnabled {
            setupCloudKit()
        }
    }
    
    private func loadSyncSettings() {
        syncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        if let lastSync = UserDefaults.standard.object(forKey: "LastSyncDate") as? Date {
            lastSyncDate = lastSync
        }
    }
    
    private func setupCloudKit() {
        container = CKContainer.default()
        database = container?.privateCloudDatabase
        checkiCloudStatus()
    }
    
    func toggleSync(_ enabled: Bool) {
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
        }
    }
    
    private func checkiCloudStatus() {
        container?.accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    print("iCloud is available")
                case .noAccount, .restricted:
                    self.syncEnabled = false
                case .couldNotDetermine, .temporarilyUnavailable:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    func syncClipboardItem(_ item: ClipboardItem) {
        guard syncEnabled, let database = database else { return }
        guard item.type != .image else { return }
        
        isSyncing = true
        
        let record = CKRecord(recordType: recordType)
        record["id"] = item.id.uuidString as CKRecordValue
        record["content"] = item.content as CKRecordValue
        record["type"] = item.type.rawValue as CKRecordValue
        record["isPinned"] = item.isPinned as CKRecordValue
        record["timestamp"] = item.timestamp as CKRecordValue
        
        database.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                self.isSyncing = false
                if error == nil {
                    self.lastSyncDate = Date()
                    UserDefaults.standard.set(self.lastSyncDate, forKey: "LastSyncDate")
                }
            }
        }
    }
    
    func fetchRemoteItems(completion: @escaping ([ClipboardItem]) -> Void) {
        guard syncEnabled, let database = database else {
            completion([])
            return
        }
        
        isSyncing = true
        
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isSyncing = false
                
                guard let records = records, error == nil else {
                    completion([])
                    return
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
                        let item = ClipboardItem(content: content, isPinned: isPinned)
                        return ClipboardItem(id: id, content: content, type: type, isPinned: isPinned, timestamp: timestamp, imageFileName: nil, detectedEntities: item.detectedEntities)
                    } else if type == .url {
                        return ClipboardItem(id: id, content: content, type: type, isPinned: isPinned, timestamp: timestamp, imageFileName: nil, detectedEntities: [])
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
