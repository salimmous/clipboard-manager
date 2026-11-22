import SwiftUI
import AppKit

// MARK: - Async Thumbnail View (Zero main-thread disk I/O, original .fit framing)
struct AsyncClipboardThumbnail: View {
    let fileName: String
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.green.opacity(0.1))
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onAppear {
            if let cached = ImageStorageManager.shared.cachedThumbnail(fileName: fileName) {
                image = cached
            } else {
                ImageStorageManager.shared.loadThumbnail(fileName: fileName) { loaded in
                    image = loaded
                }
            }
        }
        .onChange(of: fileName) { newFileName in
            if let cached = ImageStorageManager.shared.cachedThumbnail(fileName: newFileName) {
                image = cached
            } else {
                image = nil
                ImageStorageManager.shared.loadThumbnail(fileName: newFileName) { loaded in
                    image = loaded
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.blue : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

final class PopupViewState: ObservableObject {
    @Published var selectedIndex: Int? = 0
    @Published var keyboardScrollToken: Int = 0
    @Published var searchText: String = ""
    @Published var selectedContentType: ClipboardItemType? = nil
    @Published var showingFilters: Bool = false
    @Published var dateFilter: ClipboardPopupView.DateFilter = .all
}

final class PopupKeyboardMonitor: ObservableObject {
    private var monitor: Any?

    func start(handler: @escaping (NSEvent) -> NSEvent?) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: handler)
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        stop()
    }
}

public struct ClipboardPopupView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var viewState = PopupViewState()
    @StateObject private var keyMonitor = PopupKeyboardMonitor()
    @FocusState private var isSearchFocused: Bool

    public enum DateFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
    }

    public init() {}

    var filteredItems: [ClipboardItem] {
        var items = clipboardManager.items

        if let contentType = viewState.selectedContentType {
            items = items.filter { $0.type == contentType }
        }

        switch viewState.dateFilter {
        case .all:
            break
        case .today:
            items = items.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .yesterday:
            items = items.filter { Calendar.current.isDateInYesterday($0.timestamp) }
        case .thisWeek:
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            items = items.filter { $0.timestamp >= weekStart }
        case .thisMonth:
            let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
            items = items.filter { $0.timestamp >= monthStart }
        }

        if !viewState.searchText.isEmpty {
            let query = viewState.searchText
            items = items.filter {
                $0.displayContent.localizedCaseInsensitiveContains(query)
                    || ($0.ocrText?.localizedCaseInsensitiveContains(query) ?? false)
                    || ($0.sourceAppName?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }

        return items
    }

    public var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header (original v1.3.2 style)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Clipboard")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)

                            if !filteredItems.isEmpty {
                                Text("\(filteredItems.count)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            }
                        }

                        if !clipboardManager.items.isEmpty {
                            Text("\(appSettings.globalHotkey) toggle • Space QuickLook • Enter Paste")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        if !clipboardManager.items.isEmpty {
                            Button("Clear all") {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    clipboardManager.deleteAllItems(includePinned: !appSettings.preservePinnedOnClear)
                                }
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
                            .help(appSettings.preservePinnedOnClear ? "Clear unpinned items" : "Clear all items")
                        }

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewState.showingFilters.toggle()
                            }
                        }) {
                            Image(systemName: viewState.showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(hasActiveFilters ? .blue : .secondary)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            clipboardManager.hideWindow()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                SettingsWindowController.shared.show()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                clipboardManager.hideWindow()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                .background(DragAreaView())

                // Paused banner (only shown when explicitly paused)
                if clipboardManager.isPaused {
                    HStack(spacing: 8) {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.orange)
                        Text(pauseStatusText)
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                        Button("Resume") {
                            clipboardManager.resumeMonitoring()
                        }
                        .font(.caption.bold())
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }

                // Search bar (original v1.3.2 style)
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .medium))

                        TextField("Search text or image OCR...", text: $viewState.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .focused($isSearchFocused)
                            .onSubmit {
                                if !filteredItems.isEmpty {
                                    viewState.selectedIndex = 0
                                }
                            }

                        if !viewState.searchText.isEmpty {
                            Button(action: { viewState.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.textBackgroundColor))
                    )

                    if viewState.showingFilters {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Type:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 8) {
                                    FilterChip(title: "All", isSelected: viewState.selectedContentType == nil) { viewState.selectedContentType = nil }
                                    FilterChip(title: "Text", isSelected: viewState.selectedContentType == .text) { viewState.selectedContentType = .text }
                                    FilterChip(title: "Images", isSelected: viewState.selectedContentType == .image) { viewState.selectedContentType = .image }
                                    FilterChip(title: "URLs", isSelected: viewState.selectedContentType == .url) { viewState.selectedContentType = .url }
                                }
                                Spacer()
                            }

                            HStack {
                                Text("Date:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(DateFilter.allCases, id: \.self) { filter in
                                            FilterChip(title: filter.rawValue, isSelected: viewState.dateFilter == filter) {
                                                viewState.dateFilter = filter
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // List of items (smooth ScrollView, zero hover-scroll bounce)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                ClipboardPopupItemView(item: item, isSelected: viewState.selectedIndex == index)
                                    .id(item.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        viewState.selectedIndex = index
                                        activateItem(item, plainText: NSEvent.modifierFlags.contains(.shift))
                                    }
                            }

                            if filteredItems.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("No items found")
                                        .font(.headline)
                                }
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .onChange(of: viewState.keyboardScrollToken) { _ in
                        guard let idx = viewState.selectedIndex, idx >= 0, idx < filteredItems.count else { return }
                        proxy.scrollTo(filteredItems[idx].id)
                    }
                }
            }

            // Overlay Quick Look preview modal if active
            if let previewItem = clipboardManager.selectedPreviewItem {
                Color.black.opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        clipboardManager.selectedPreviewItem = nil
                    }

                QuickLookPreviewView(item: previewItem) {
                    clipboardManager.selectedPreviewItem = nil
                }
                .padding(14)
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appSettings.appearanceMode.backgroundGradient)
        )
        .onAppear {
            onWindowShown()
        }
        .onDisappear {
            keyMonitor.stop()
        }
        .onChange(of: clipboardManager.isWindowVisible) { visible in
            if visible {
                onWindowShown()
            } else {
                keyMonitor.stop()
                isSearchFocused = false
            }
        }
        .onChange(of: viewState.searchText) { _ in
            clampSelection()
        }
        .onChange(of: viewState.selectedContentType) { _ in
            clampSelection()
        }
        .onChange(of: viewState.dateFilter) { _ in
            clampSelection()
        }
    }

    private var pauseStatusText: String {
        if let until = clipboardManager.pauseUntil {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Monitoring paused until \(formatter.string(from: until))"
        }
        return "Monitoring paused (Incognito mode)"
    }

    private var hasActiveFilters: Bool {
        viewState.selectedContentType != nil || viewState.dateFilter != .all || !viewState.searchText.isEmpty
    }

    private func onWindowShown() {
        clampSelection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isSearchFocused = true
        }
        keyMonitor.start { event in
            handleKeyEvent(event)
        }
    }

    private func clampSelection() {
        let count = filteredItems.count
        if count == 0 {
            viewState.selectedIndex = nil
        } else if let current = viewState.selectedIndex {
            viewState.selectedIndex = min(max(current, 0), count - 1)
        } else {
            viewState.selectedIndex = 0
        }
    }

    private func activateItem(_ item: ClipboardItem, plainText: Bool) {
        if plainText {
            PasteService.shared.pasteAsPlainText(item, manager: clipboardManager)
        } else if appSettings.isDirectPasteEnabled {
            PasteService.shared.pasteDirectly(item, manager: clipboardManager)
        } else {
            clipboardManager.copyToClipboard(item)
            clipboardManager.hideWindow()
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard clipboardManager.isWindowVisible else { return event }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let items = filteredItems

        if flags == .command {
            let numberKeyCodes: [UInt16: Int] = [
                18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8
            ]
            if let targetIndex = numberKeyCodes[event.keyCode], targetIndex < items.count {
                activateItem(items[targetIndex], plainText: false)
                return nil
            }

            if event.keyCode == 16 { // ⌘Y QuickLook
                toggleQuickLook(items: items)
                return nil
            }

            if event.keyCode == 35, let index = viewState.selectedIndex, index < items.count { // ⌘P Pin
                clipboardManager.togglePin(for: items[index])
                return nil
            }

            if event.keyCode == 51, let index = viewState.selectedIndex, index < items.count { // ⌘⌫ Delete
                clipboardManager.removeItem(items[index])
                clampSelection()
                return nil
            }
        }

        switch event.keyCode {
        case 53: // Escape
            if clipboardManager.selectedPreviewItem != nil {
                clipboardManager.selectedPreviewItem = nil
            } else if !viewState.searchText.isEmpty {
                viewState.searchText = ""
            } else {
                clipboardManager.hideWindow()
            }
            return nil

        case 125: // Down arrow
            guard !items.isEmpty else { return nil }
            let current = viewState.selectedIndex ?? -1
            viewState.selectedIndex = min(current + 1, items.count - 1)
            viewState.keyboardScrollToken &+= 1
            return nil

        case 126: // Up arrow
            guard !items.isEmpty else { return nil }
            let current = viewState.selectedIndex ?? 0
            viewState.selectedIndex = max(current - 1, 0)
            viewState.keyboardScrollToken &+= 1
            return nil

        case 36, 76: // Enter
            if let index = viewState.selectedIndex, index < items.count {
                activateItem(items[index], plainText: flags.contains(.shift))
                return nil
            }
            return event

        case 49: // Spacebar
            if flags.isEmpty {
                if clipboardManager.selectedPreviewItem != nil {
                    clipboardManager.selectedPreviewItem = nil
                    return nil
                }
                if viewState.searchText.isEmpty {
                    toggleQuickLook(items: items)
                    return nil
                }
            }
            return event

        default:
            return event
        }
    }

    private func toggleQuickLook(items: [ClipboardItem]) {
        if clipboardManager.selectedPreviewItem != nil {
            clipboardManager.selectedPreviewItem = nil
            return
        }
        guard let index = viewState.selectedIndex, index < items.count else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            clipboardManager.selectedPreviewItem = items[index]
        }
    }
}

struct ClipboardPopupItemView: View {
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    let item: ClipboardItem
    let isSelected: Bool
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                if let swatch = item.hexColorSwatch {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(swatch)
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                } else if item.type == .image, let fileName = item.imageFileName {
                    AsyncClipboardThumbnail(fileName: fileName)
                } else {
                    Image(systemName: item.typeIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .background(iconColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.displayContent)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(item.type == .image ? 1 : 2)
                        .multilineTextAlignment(.leading)

                    if item.type == .url {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }

                HStack(spacing: 6) {
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if item.type == .image && item.ocrText != nil {
                        Text("• OCR")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }

                    Spacer()

                    Text(item.type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(iconColor.opacity(0.15))
                        .foregroundColor(iconColor)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Menu {
                    Section("Actions") {
                        Button("Paste Direct") {
                            PasteService.shared.pasteDirectly(item, manager: clipboardManager)
                        }
                        Button("Paste Plain Text") {
                            PasteService.shared.pasteAsPlainText(item, manager: clipboardManager)
                        }
                        Button("Quick Look (Space)") {
                            clipboardManager.selectedPreviewItem = item
                        }
                        if item.type == .url, let url = URL(string: item.content) {
                            Button("Open in Browser") {
                                NSWorkspace.shared.open(url)
                                clipboardManager.hideWindow()
                            }
                        }
                        if let ocr = item.ocrText, !ocr.isEmpty {
                            Button("Copy Extracted OCR Text") {
                                clipboardManager.copyPlainTextToClipboard(ocr)
                            }
                        }
                    }

                    if item.type != .image || (item.ocrText != nil && !(item.ocrText?.isEmpty ?? true)) {
                        let shareableText = item.type == .image ? (item.ocrText ?? "") : item.content
                        Menu("Share") {
                            Button("Send to Slack") {
                                clipboardManager.integrations.shareToSlack(shareableText)
                            }
                            .disabled(!clipboardManager.integrations.isSlackConfigured)

                            Button("Send to Discord") {
                                clipboardManager.integrations.shareToDiscord(shareableText)
                            }
                            .disabled(!clipboardManager.integrations.isDiscordConfigured)

                            Button("Compose Email") {
                                clipboardManager.integrations.composeEmail(with: shareableText)
                            }

                            Button("Save to \(clipboardManager.integrations.defaultNotesApp.rawValue)") {
                                clipboardManager.integrations.saveToNotes(shareableText)
                            }
                        }
                    }

                    if !item.detectedEntities.isEmpty {
                        Menu("Smart Actions") {
                            ForEach(item.detectedEntities, id: \.self) { entity in
                                Button("\(entity.actionTitle): \(entity.value)") {
                                    SmartDetector.performAction(for: entity)
                                }
                            }
                        }
                    }

                    Section("Clipboard") {
                        Button("Copy") {
                            clipboardManager.copyToClipboard(item)
                        }
                        Button("Delete") {
                            clipboardManager.removeItem(item)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button(action: {
                    clipboardManager.togglePin(for: item)
                }) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(item.isPinned ? .orange : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isSelected
                        ? Color.accentColor.opacity(0.15)
                        : (isHovered ? Color.accentColor.opacity(0.06) : Color(NSColor.controlBackgroundColor))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .text: return .blue
        case .image: return .green
        case .url: return .purple
        }
    }

    private var timeAgo: String {
        Self.relativeDateFormatter.localizedString(for: item.timestamp, relativeTo: Date())
    }
}
