#!/usr/bin/env swift
import AppKit
import Foundation

let outDir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let apps: [(String, String)] = [
    ("finder", "/System/Library/CoreServices/Finder.app"),
    ("safari", "/Applications/Safari.app"),
    ("messages", "/System/Applications/Messages.app"),
    ("mail", "/System/Applications/Mail.app"),
    ("maps", "/System/Applications/Maps.app"),
    ("photos", "/System/Applications/Photos.app"),
    ("facetime", "/System/Applications/FaceTime.app"),
    ("calendar", "/System/Applications/Calendar.app"),
    ("contacts", "/System/Applications/Contacts.app"),
    ("reminders", "/System/Applications/Reminders.app"),
    ("notes", "/System/Applications/Notes.app"),
    ("tv", "/System/Applications/TV.app"),
    ("music", "/System/Applications/Music.app"),
    ("podcasts", "/System/Applications/Podcasts.app"),
    ("appstore", "/System/Applications/App Store.app"),
    ("settings", "/System/Applications/System Settings.app"),
]

func saveTrashIcon(name: String, size: CGFloat) throws {
    guard let icon = NSImage(named: NSImage.trashEmptyName) else { return }
    icon.size = NSSize(width: size, height: size)
    guard let tiff = icon.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return }
    let url = outDir.appendingPathComponent("\(name).png")
    try png.write(to: url)
    print("Wrote \(url.path)")
}

func saveIcon(for path: String, name: String, size: CGFloat) throws {
    let icon = NSWorkspace.shared.icon(forFile: path)
    icon.size = NSSize(width: size, height: size)

    guard let tiff = icon.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fputs("Failed to render \(name)\n", stderr)
        return
    }

    let url = outDir.appendingPathComponent("\(name).png")
    try png.write(to: url)
    print("Wrote \(url.path)")
}

for (name, path) in apps {
    try saveIcon(for: path, name: name, size: 256)
}

try saveTrashIcon(name: "trash", size: 256)

// Headroom brand icon
let brandIcon = outDir.deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("brand/output/icon-256.png")
if FileManager.default.fileExists(atPath: brandIcon.path) {
    let dst = outDir.appendingPathComponent("headroom.png")
    try FileManager.default.copyItem(at: brandIcon, to: dst)
    print("Wrote \(dst.path)")
}
