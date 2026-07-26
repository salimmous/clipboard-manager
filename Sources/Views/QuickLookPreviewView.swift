import SwiftUI
import AppKit

struct QuickLookPreviewView: View {
    let item: ClipboardItem
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: item.typeIcon)
                        .foregroundColor(.blue)
                    Text(item.type.rawValue.capitalized)
                        .font(.headline)
                        .bold()
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
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Preview Content Body
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch item.type {
                    case .image:
                        if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 350)
                                .cornerRadius(8)
                                .shadow(radius: 4)
                        } else {
                            Text("Unable to load image")
                                .foregroundColor(.red)
                        }
                        
                        if let ocrText = item.ocrText, !ocrText.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Extracted Text (OCR)", systemImage: "text.viewfinder")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Text(ocrText)
                                    .font(.system(.body, design: .monospaced))
                                    .padding()
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                    .textSelection(.enabled)
                            }
                        }
                        
                    case .text, .url:
                        Text(item.content)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    
                    if !item.detectedEntities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Smart Actions")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            ForEach(item.detectedEntities, id: \.self) { entity in
                                HStack {
                                    Text(entity.value)
                                        .font(.subheadline)
                                    Spacer()
                                    Button("Action") {
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
                .padding()
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
                
                Spacer()
                
                Button(action: {
                    PasteService.shared.pasteDirectly(item, manager: ClipboardManager.shared)
                    onClose()
                }) {
                    Label("Copy & Paste", systemImage: "doc.on.clipboard.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 480, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 10)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
