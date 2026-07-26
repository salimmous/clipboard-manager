import SwiftUI
import AppKit

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

class PopupViewState: ObservableObject {
    @Published var selectedIndex: Int? = 0
    @Published var searchText: String = ""
    @Published var selectedContentType: ClipboardItemType? = nil
    @Published var showingFilters: Bool = false
    @Published var dateFilter: ClipboardPopupView.DateFilter = .all
}

struct ClipboardPopupView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @StateObject private var viewState = PopupViewState()
    @StateObject private var appSettings = AppSettings()
    private static var settingsDelegate = SettingsWindowDelegate()
    
    enum DateFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
    }
    
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
            items = items.filter {
                $0.displayContent.localizedCaseInsensitiveContains(viewState.searchText) ||
                ($0.ocrText?.localizedCaseInsensitiveContains(viewState.searchText) ?? false)
            }
        }
        
        return items
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header
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
                            Text("⌘+X toggle • Space QuickLook • Enter Paste")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if !clipboardManager.items.isEmpty {
                            Button("Clear all") {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    clipboardManager.items.removeAll()
                                    clipboardManager.saveItems()
                                }
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
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
                                openSettingsFromPopup()
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
                
                // Search bar
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .medium))
                        
                        TextField("Search text or image OCR...", text: $viewState.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
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
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // List of items
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardPopupItemView(item: item, isSelected: viewState.selectedIndex == index)
                                .onTapGesture {
                                    viewState.selectedIndex = index
                                    if appSettings.isDirectPasteEnabled {
                                        PasteService.shared.pasteDirectly(item, manager: clipboardManager)
                                    } else {
                                        clipboardManager.copyToClipboard(item)
                                        clipboardManager.hideWindow()
                                    }
                                }
                                .onHover { hovering in
                                    if hovering { viewState.selectedIndex = index }
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
            }
            
            // Overlay Quick Look preview modal if active
            if let previewItem = clipboardManager.selectedPreviewItem {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        clipboardManager.selectedPreviewItem = nil
                    }
                
                QuickLookPreviewView(item: previewItem) {
                    clipboardManager.selectedPreviewItem = nil
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appSettings.appearanceMode.backgroundGradient)
        )
        .onAppear {
            if !filteredItems.isEmpty { viewState.selectedIndex = 0 }
        }
        .onKeyDown { event in
            handleKeyDown(event)
        }
    }
    
    private var hasActiveFilters: Bool {
        viewState.selectedContentType != nil || viewState.dateFilter != .all || !viewState.searchText.isEmpty
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        let items = filteredItems
        
        switch event.keyCode {
        case 49: // Spacebar (Quick Look)
            if let index = viewState.selectedIndex, index < items.count {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    clipboardManager.selectedPreviewItem = items[index]
                }
            }
        case 36: // Enter
            if let index = viewState.selectedIndex, index < items.count {
                let item = items[index]
                if appSettings.isDirectPasteEnabled {
                    PasteService.shared.pasteDirectly(item, manager: clipboardManager)
                } else {
                    clipboardManager.copyToClipboard(item)
                    clipboardManager.hideWindow()
                }
            }
        case 53: // Escape
            if clipboardManager.selectedPreviewItem != nil {
                clipboardManager.selectedPreviewItem = nil
            } else {
                clipboardManager.hideWindow()
            }
        case 125: // Down arrow
            if let current = viewState.selectedIndex {
                viewState.selectedIndex = min(current + 1, items.count - 1)
            } else {
                viewState.selectedIndex = 0
            }
        case 126: // Up arrow
            if let current = viewState.selectedIndex {
                viewState.selectedIndex = max(current - 1, 0)
            } else {
                viewState.selectedIndex = 0
            }
        default:
            break
        }
    }
    
    private func openSettingsFromPopup() {
        if let window = NSApp.windows.first(where: { $0.title == "Clipboard Manager Settings" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            let settings = AppSettings()
            let settingsView = SettingsView().environmentObject(settings)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 650, height: 450),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.contentView = NSHostingView(rootView: settingsView)
            window.title = "Clipboard Manager Settings"
            window.isReleasedWhenClosed = false
            window.delegate = Self.settingsDelegate
            window.makeKeyAndOrderFront(nil)
        }
    }
}

struct ClipboardPopupItemView: View {
    let item: ClipboardItem
    let isSelected: Bool
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                if item.type == .image, let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
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
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }
    
    private var iconColor: Color {
        switch item.type {
        case .text: return .blue
        case .image: return .green
        case .url: return .purple
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.timestamp, relativeTo: Date())
    }
}
