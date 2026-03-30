#!/usr/bin/env swift
// Run: swift scripts/generate_icon.swift
// Generates all AppIcon PNG sizes for Rhythm

import AppKit
import CoreGraphics

func drawRhythmIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus(); return image
    }

    // --- Background: rounded rect with deep indigo→purple gradient ---
    let radius = s * 0.22
    let bgPath = CGPath(
        roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
        cornerWidth: radius, cornerHeight: radius, transform: nil
    )
    ctx.addPath(bgPath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradColors = [
        CGColor(red: 0.07, green: 0.06, blue: 0.22, alpha: 1.0),   // deep navy
        CGColor(red: 0.18, green: 0.08, blue: 0.38, alpha: 1.0),   // indigo
        CGColor(red: 0.32, green: 0.10, blue: 0.52, alpha: 1.0),   // purple
    ] as CFArray
    let locations: [CGFloat] = [0, 0.5, 1.0]
    let gradient = CGGradient(colorsSpace: colorSpace, colors: gradColors, locations: locations)!

    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: s),
        end: CGPoint(x: s, y: 0),
        options: []
    )

    // --- Waveform: stylised sine wave ---
    // Draw a smooth waveform across the icon center
    let midY = s * 0.5
    let amplitude = s * 0.18
    let waveWidth = s * 0.80
    let waveStartX = s * 0.10
    let steps = 200

    ctx.setStrokeColor(CGColor(red: 0.45, green: 0.88, blue: 1.0, alpha: 0.95))
    ctx.setLineWidth(s * 0.045)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    let path = CGMutablePath()
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let x = waveStartX + t * waveWidth
        // Composite wave: main + harmonic for rhythm feel
        let angle = t * CGFloat.pi * 4
        let y = midY - amplitude * sin(angle) - (amplitude * 0.35) * sin(angle * 2.5)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
        else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    ctx.addPath(path)
    ctx.strokePath()

    // --- Subtle glow dots at peaks ---
    let dotRadius = s * 0.025
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6))
    for peak in [0.125, 0.375, 0.625, 0.875] as [CGFloat] {
        let t = peak
        let x = waveStartX + t * waveWidth
        let angle = t * CGFloat.pi * 4
        let y = midY - amplitude * sin(angle) - (amplitude * 0.35) * sin(angle * 2.5)
        ctx.fillEllipse(in: CGRect(
            x: x - dotRadius, y: y - dotRadius,
            width: dotRadius * 2, height: dotRadius * 2
        ))
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("❌ Failed to encode \(path)")
        return
    }
    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("✅ \(path)")
    } catch {
        print("❌ \(path): \(error)")
    }
}

// Determine output directory
let outputDir: String
if CommandLine.arguments.count > 1 {
    outputDir = CommandLine.arguments[1]
} else {
    // Default: relative to script location → project AppIcon.appiconset
    let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent().path
    outputDir = scriptDir + "/../Rhythm/Assets.xcassets/AppIcon.appiconset"
}

let sizes = [16, 32, 64, 128, 256, 512, 1024]
print("Generating Rhythm icons in: \(outputDir)\n")

for size in sizes {
    let img = drawRhythmIcon(size: size)
    savePNG(img, to: "\(outputDir)/icon_\(size).png")
}

print("\nDone! Open Rhythm.xcodeproj in Xcode to verify icons.")
