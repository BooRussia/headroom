#!/usr/bin/env swift
import AppKit
import Foundation

let outDir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.211

    let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: size * 0.0625, dy: size * 0.0625), xRadius: radius, yRadius: radius)
    let bgGradient = NSGradient(colors: [
        NSColor(red: 0.357, green: 0.388, blue: 0.961, alpha: 1),
        NSColor(red: 0.094, green: 0.773, blue: 0.549, alpha: 1),
    ])!
    bgGradient.draw(in: bgPath, angle: 135)

    let inset = size * 0.18
    let inner = bounds.insetBy(dx: inset, dy: inset)

    // Limit line — empty space above is the "headroom"
    let lineY = inner.maxY - inner.height * 0.42
    let lineWidth = inner.width * 0.62
    let lineX = inner.midX - lineWidth / 2
    NSColor(white: 1, alpha: 0.55).setFill()
    NSBezierPath(roundedRect: NSRect(x: lineX, y: lineY, width: lineWidth, height: max(2, size * 0.008)), xRadius: 2, yRadius: 2).fill()

    // Usage track
    let trackWidth = inner.width * 0.78
    let trackHeight = max(12, size * 0.086)
    let trackX = inner.midX - trackWidth / 2
    let trackY = inner.minY + inner.height * 0.18
    NSColor(white: 1, alpha: 0.18).setFill()
    NSBezierPath(roundedRect: NSRect(x: trackX, y: trackY, width: trackWidth, height: trackHeight), xRadius: trackHeight / 2, yRadius: trackHeight / 2).fill()

    // Fill ~58% — approaching limit, still has headroom above
    let fillWidth = trackWidth * 0.58
    let fillPath = NSBezierPath(roundedRect: NSRect(x: trackX, y: trackY, width: fillWidth, height: trackHeight), xRadius: trackHeight / 2, yRadius: trackHeight / 2)
    let fillGradient = NSGradient(colors: [
        NSColor(white: 1, alpha: 0.98),
        NSColor(red: 1, green: 0.827, blue: 0.416, alpha: 1),
    ])!
    fillGradient.draw(in: fillPath, angle: 0)

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "HeadroomBrand", code: 1)
    }
    try png.write(to: url)
}

let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
for size in sizes {
    let image = renderIcon(size: CGFloat(size))
    let url = outDir.appendingPathComponent("icon-\(size).png")
    try savePNG(image, to: url)
    print("Wrote \(url.path)")
}

// Convenience copies
for name in ["logo.png", "icon.png", "favicon.png"] {
    let src = outDir.appendingPathComponent("icon-512.png")
    let dst = outDir.appendingPathComponent(name)
    try FileManager.default.copyItem(at: src, to: dst)
    print("Wrote \(dst.path)")
}
