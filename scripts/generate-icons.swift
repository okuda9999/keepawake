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

    let sunColor = NSColor(calibratedRed: 1.0, green: 0.73, blue: 0.12, alpha: 1)
    sunColor.setStroke()
    sunColor.setFill()
    NSBezierPath(ovalIn: NSRect(x: 352, y: 410, width: 320, height: 320)).fill()

    let rays = NSBezierPath()
    rays.lineWidth = 42
    rays.lineCapStyle = .round
    let center = NSPoint(x: 512, y: 570)
    for degrees in stride(from: 0.0, to: 360.0, by: 45.0) {
        let radians = degrees * .pi / 180
        let start = NSPoint(x: center.x + cos(radians) * 205, y: center.y + sin(radians) * 205)
        let end = NSPoint(x: center.x + cos(radians) * 265, y: center.y + sin(radians) * 265)
        rays.move(to: start)
        rays.line(to: end)
    }
    rays.stroke()

    let outlineColor = NSColor(calibratedRed: 0.12, green: 0.17, blue: 0.22, alpha: 1)
    outlineColor.setStroke()
    let display = NSBezierPath(roundedRect: NSRect(x: 174, y: 250, width: 676, height: 476), xRadius: 58, yRadius: 58)
    display.lineWidth = 52
    display.stroke()

    let stand = NSBezierPath()
    stand.lineWidth = 52
    stand.lineCapStyle = .round
    stand.move(to: NSPoint(x: 512, y: 250))
    stand.line(to: NSPoint(x: 512, y: 166))
    stand.move(to: NSPoint(x: 390, y: 150))
    stand.line(to: NSPoint(x: 634, y: 150))
    stand.stroke()

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
