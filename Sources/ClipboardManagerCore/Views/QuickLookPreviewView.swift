import SwiftUI
import AppKit

public struct QuickLookPreviewView: View {
    let item: ClipboardItem
    let onClose: () -> Void

    @State private var loadedImage: NSImage?
    @State private var isLoadingImage = false

    public init(item: ClipboardItem, onClose: @escaping () -> Void) {
        self.item = item
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: item.typeIcon)
                        .foregroundColor(.accentColor)
                    Text(item.type.rawValue.capitalized)
                        .font(.headline)
                        .bold()
                    if let appName = item.sourceAppName, !appName.isEmpty {
                        Text("from \(appName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(formattedDate(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Preview Content Body
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let swatch = item.hexColorSwatch {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(swatch)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Color Preview")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(item.content.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
                                    .font(.system(.title3, design: .monospaced).bold())
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }

                    switch item.type {
                    case .image:
                        if let nsImage = loadedImage {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 280)
                                .cornerRadius(8)
                                .shadow(radius: 3)
                        } else if isLoadingImage {
                            ProgressView("Loading image...")
                                .frame(maxWidth: .infinity, minHeight: 140)
                        } else {
                            Text("Unable to load image")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, minHeight: 80)
                        }

                        if let ocrText = item.ocrText, !ocrText.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Label("Extracted Text (OCR)", systemImage: "text.viewfinder")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Button("Copy OCR") {
                                        ClipboardManager.shared.copyPlainTextToClipboard(ocrText)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                }

                                Text(ocrText)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                    .textSelection(.enabled)
                            }
                        }

                    case .text, .url:
                        Text(item.content)
                            .font(.system(.body, design: .monospaced))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }

                    Text(item.metadataSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !item.detectedEntities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Smart Actions")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)

                            ForEach(item.detectedEntities, id: \.self) { entity in
                                HStack {
                                    Image(systemName: entity.iconName)
                                        .foregroundColor(.accentColor)
                                        .frame(width: 16)
                                    Text(entity.value)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Spacer()
                                    Button(entity.actionTitle) {
                                        SmartDetector.performAction(for: entity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(14)
            }

            Divider()

            // Footer Action Bar
            HStack {
                Button(action: {
                    PasteService.shared.pasteAsPlainText(item, manager: ClipboardManager.shared)
                    onClose()
                }) {
                    Label("Paste Plain Text", systemImage: "doc.plaintext")
                }
                .buttonStyle(.bordered)
                .disabled(item.type == .image && (item.ocrText?.isEmpty ?? true))

                Spacer()

                Button(action: {
                    PasteService.shared.pasteDirectly(item, manager: ClipboardManager.shared)
                    onClose()
                }) {
                    Label("Copy & Paste", systemImage: "doc.on.clipboard.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(maxWidth: 420, maxHeight: 460)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 12)
        .onAppear {
            loadImageIfNeeded()
        }
    }

    private func loadImageIfNeeded() {
        guard item.type == .image, let fileName = item.imageFileName else { return }
        isLoadingImage = true
        ImageStorageManager.shared.loadFullImage(fileName: fileName) { image in
            loadedImage = image
            isLoadingImage = false
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
