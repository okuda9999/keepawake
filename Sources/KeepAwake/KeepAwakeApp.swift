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
            Image(nsImage: StatusIcon.image(isActive: model.isActive))
                .accessibilityLabel(model.isActive ? "KeepAwake オン" : "KeepAwake オフ")
        }
        .menuBarExtraStyle(.menu)
    }
}

private enum StatusIcon {
    static func image(isActive: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { bounds in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            let screen = NSBezierPath(roundedRect: NSRect(x: 0.8, y: 3.3, width: 16.4, height: 13.7), xRadius: 2, yRadius: 2)
            screen.lineWidth = 1.5
            screen.stroke()

            let stand = NSBezierPath()
            stand.lineWidth = 1.4
            stand.lineCapStyle = .round
            stand.move(to: NSPoint(x: 6.2, y: 1.3))
            stand.line(to: NSPoint(x: 11.8, y: 1.3))
            stand.move(to: NSPoint(x: 9, y: 1.3))
            stand.line(to: NSPoint(x: 9, y: 3.3))
            stand.stroke()

            let handle = NSBezierPath(ovalIn: NSRect(x: 11, y: 6.2, width: 3.6, height: 3.6))
            handle.lineWidth = 1.2
            handle.stroke()

            let cup = NSBezierPath()
            cup.move(to: NSPoint(x: 6.2, y: 10.2))
            cup.curve(
                to: NSPoint(x: 12.2, y: 10.2),
                controlPoint1: NSPoint(x: 6.2, y: 10.55),
                controlPoint2: NSPoint(x: 12.2, y: 10.55)
            )
            cup.line(to: NSPoint(x: 11.9, y: 6.7))
            cup.curve(
                to: NSPoint(x: 10.5, y: 4.6),
                controlPoint1: NSPoint(x: 11.8, y: 5.3),
                controlPoint2: NSPoint(x: 11.3, y: 4.6)
            )
            cup.line(to: NSPoint(x: 7.9, y: 4.6))
            cup.curve(
                to: NSPoint(x: 6.5, y: 6.7),
                controlPoint1: NSPoint(x: 7.1, y: 4.6),
                controlPoint2: NSPoint(x: 6.6, y: 5.3)
            )
            cup.close()
            cup.lineWidth = 1.2
            if isActive { cup.fill() } else { cup.stroke() }

            let rim = NSBezierPath(ovalIn: NSRect(x: 6.2, y: 9.3, width: 6, height: 2))
            rim.lineWidth = 1.15
            if isActive { rim.fill() } else { rim.stroke() }

            let coffeeSurface = NSBezierPath(ovalIn: NSRect(x: 7.2, y: 9.75, width: 4, height: 0.8))
            if isActive {
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current?.compositingOperation = .clear
                coffeeSurface.fill()
                NSGraphicsContext.restoreGraphicsState()
            } else {
                coffeeSurface.fill()
            }

            if isActive {
                let steam = NSBezierPath()
                steam.lineWidth = 1.2
                steam.lineCapStyle = .round
                steam.move(to: NSPoint(x: 7.9, y: 12))
                steam.curve(
                    to: NSPoint(x: 8.2, y: 14.7),
                    controlPoint1: NSPoint(x: 7, y: 12.8),
                    controlPoint2: NSPoint(x: 8.9, y: 13.7)
                )
                steam.move(to: NSPoint(x: 10.4, y: 12))
                steam.curve(
                    to: NSPoint(x: 10.7, y: 14.7),
                    controlPoint1: NSPoint(x: 9.5, y: 12.8),
                    controlPoint2: NSPoint(x: 11.4, y: 13.7)
                )
                steam.stroke()
            }
            return true
        }
        image.isTemplate = true
        return image
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
