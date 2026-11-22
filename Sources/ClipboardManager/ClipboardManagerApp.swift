import SwiftUI
import ClipboardManagerCore

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(ClipboardManager.shared)
        } label: {
            CustomClipboardIcon()
        }
    }
}
