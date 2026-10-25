import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: swift generate-icons.swift <Resources directory>\n", stderr)
    exit(2)
}

let resourcesURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let iconsetURL = resourcesURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let fileManager = FileManager.default
try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

func drawIcon(pixelSize: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { throw CocoaError(.fileWriteUnknown) }

    bitmap.size = NSSize(width: 1024, height: 1024)
    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw CocoaError(.fileWriteUnknown)
    }
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    NSColor(calibratedRed: 1.0, green: 0.969, blue: 0.91, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 40, y: 40, width: 944, height: 944), xRadius: 210, yRadius: 210).fill()

    let outlineColor = NSColor(calibratedRed: 0.12, green: 0.17, blue: 0.22, alpha: 1)
    let coffeeColor = NSColor(calibratedRed: 1.0, green: 0.73, blue: 0.12, alpha: 1)
    outlineColor.setStroke()
    let display = NSBezierPath(roundedRect: NSRect(x: 122, y: 310, width: 780, height: 500), xRadius: 62, yRadius: 62)
    display.lineWidth = 52
    display.stroke()

    let stand = NSBezierPath()
    stand.lineWidth = 52
    stand.lineCapStyle = .round
    stand.move(to: NSPoint(x: 470, y: 310))
    stand.line(to: NSPoint(x: 470, y: 208))
    stand.move(to: NSPoint(x: 330, y: 190))
    stand.line(to: NSPoint(x: 610, y: 190))
    stand.stroke()

    // Keep the complete cup inside the display's inner area. The handle is
    // drawn first so the body hides its inner edge cleanly at small sizes.
    let handle = NSBezierPath(ovalIn: NSRect(x: 606, y: 408, width: 142, height: 126))
    handle.lineWidth = 46
    coffeeColor.setStroke()
    handle.stroke()

    let cup = NSBezierPath()
    cup.move(to: NSPoint(x: 394, y: 570))
    cup.curve(
        to: NSPoint(x: 640, y: 570),
        controlPoint1: NSPoint(x: 394, y: 586),
        controlPoint2: NSPoint(x: 640, y: 586)
    )
    cup.line(to: NSPoint(x: 626, y: 438))
    cup.curve(
        to: NSPoint(x: 568, y: 358),
        controlPoint1: NSPoint(x: 622, y: 390),
        controlPoint2: NSPoint(x: 598, y: 358)
    )
    cup.line(to: NSPoint(x: 466, y: 358))
    cup.curve(
        to: NSPoint(x: 408, y: 438),
        controlPoint1: NSPoint(x: 436, y: 358),
        controlPoint2: NSPoint(x: 412, y: 390)
    )
    cup.close()
    coffeeColor.setFill()
    cup.fill()
    outlineColor.setStroke()
    cup.lineWidth = 42
    cup.stroke()

    let rim = NSBezierPath(ovalIn: NSRect(x: 394, y: 536, width: 246, height: 76))
    coffeeColor.setFill()
    rim.fill()
    outlineColor.setStroke()
    rim.lineWidth = 36
    rim.stroke()

    let coffeeSurface = NSBezierPath(ovalIn: NSRect(x: 426, y: 553, width: 182, height: 38))
    outlineColor.setFill()
    coffeeSurface.fill()

    let steam = NSBezierPath()
    steam.lineWidth = 32
    steam.lineCapStyle = .round
    for x in [454.0, 517.0, 580.0] {
        steam.move(to: NSPoint(x: x, y: 632))
        steam.curve(
            to: NSPoint(x: x + 8, y: 732),
            controlPoint1: NSPoint(x: x - 30, y: 664),
            controlPoint2: NSPoint(x: x + 36, y: 700)
        )
    }
    steam.stroke()

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

let variants: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]

for (name, size) in variants {
    try drawIcon(pixelSize: size).write(to: iconsetURL.appendingPathComponent(name), options: .atomic)
}
try drawIcon(pixelSize: 1024).write(to: resourcesURL.appendingPathComponent("IconPreview.png"), options: .atomic)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["--convert", "icns", "--output", resourcesURL.appendingPathComponent("AppIcon.icns").path, iconsetURL.path]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else { exit(process.terminationStatus) }
try fileManager.removeItem(at: iconsetURL)
