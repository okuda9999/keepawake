import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: swift generate-icons.swift <Resources directory>\n", stderr)
    exit(2)
}

let resourcesURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let sourceURL = resourcesURL.appendingPathComponent("OriginalIconSource.jpg")
let iconsetURL = resourcesURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let fileManager = FileManager.default

guard
    let sourceData = try? Data(contentsOf: sourceURL),
    let sourceRep = NSBitmapImageRep(data: sourceData),
    let sourceCGImage = sourceRep.cgImage
else {
    fputs("missing or unreadable icon source: \(sourceURL.path)\n", stderr)
    exit(1)
}

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

// The supplied 1536 x 1024 JPEG contains a centered icon surrounded by a
// checkerboard baked into the pixels. This square source crop and rounded mask
// preserve the supplied icon artwork while excluding only that outer area.
let sourceCrop = CGRect(x: 430, y: 100, width: 550, height: 550)
guard let croppedCGImage = sourceCGImage.cropping(to: sourceCrop) else {
    fputs("could not crop icon source\n", stderr)
    exit(1)
}
let croppedImage = NSImage(cgImage: croppedCGImage, size: NSSize(width: 1024, height: 1024))
let frameMask = NSBezierPath(
    roundedRect: NSRect(x: 64, y: 56, width: 896, height: 958),
    xRadius: 205,
    yRadius: 205
)

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

    NSColor.clear.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
    frameMask.addClip()
    croppedImage.draw(
        in: NSRect(x: 0, y: 0, width: 1024, height: 1024),
        from: NSRect(x: 0, y: 0, width: 1024, height: 1024),
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: false,
        hints: [.interpolation: NSImageInterpolation.high]
    )

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
