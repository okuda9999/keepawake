import AppKit
import KeepAwakeCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var onTerminate: (() -> Void)?

    func applicationWillTerminate(_ notification: Notification) {
        onTerminate?()
    }
}

@main
struct KeepAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = KeepAwakeModel()

    var body: some Scene {
        MenuBarExtra {
            KeepAwakeMenu(model: model)
                .onAppear { appDelegate.onTerminate = { model.stop() } }
        } label: {
            Image(systemName: model.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                .accessibilityLabel(model.isActive ? "KeepAwake オン" : "KeepAwake オフ")
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct KeepAwakeMenu: View {
    @ObservedObject var model: KeepAwakeModel

    var body: some View {
        if model.isActive {
            Text("状態: オン")
            if let remaining = model.remainingText { Text(remaining) }
            Button("停止") { model.stop() }
        } else {
            Text("状態: オフ")
            Button("1時間開始") { model.start(.oneHour) }
            Button("手動で停止するまで開始") { model.start(.untilStopped) }
        }

        if let error = model.lastError {
            Divider()
            Text(error)
        }

        Divider()
        Text("オン中はバッテリー消費が増える場合があります")
        Divider()
        Button("KeepAwake を終了") {
            model.stop()
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
