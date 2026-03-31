#!/usr/bin/env swift
// Run: swift scripts/generate_icon.swift
// Uses NSBitmapImageRep to produce exact pixel sizes (Retina-safe)
import AppKit
import CoreGraphics

func drawIcon(pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    draw(ctx: ctx, s: CGFloat(pixels))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func draw(ctx: CGContext, s: CGFloat) {
    // ── Background ────────────────────────────────────────────────
    let corner = s * 0.22
    let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                        cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    // Light gradient: top-left pale-blue-white → bottom-right white
    let bgColors = [CGColor(red: 0.94, green: 0.95, blue: 1.00, alpha: 1),
                    CGColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1)] as CFArray
    let bgGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                             colors: bgColors, locations: [0, 1])!
    ctx.drawLinearGradient(bgGrad,
                           start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0),
                           options: [])

    // ── Equalizer bars ────────────────────────────────────────────
    let barCount = 7
    let maxBarH  = s * 0.58
    let barW     = s * 0.075
    let gap      = s * 0.042
    let totalW   = CGFloat(barCount) * barW + CGFloat(barCount - 1) * gap
    let originX  = (s - totalW) / 2
    let baseline = s * 0.72

    let heights: [CGFloat] = [0.42, 0.65, 0.83, 1.00, 0.83, 0.65, 0.42]
    let barColors: [CGColor] = [
        CGColor(red: 0.00, green: 0.82, blue: 0.95, alpha: 1),   // cyan
        CGColor(red: 0.10, green: 0.55, blue: 1.00, alpha: 1),   // sky blue
        CGColor(red: 0.50, green: 0.22, blue: 0.98, alpha: 1),   // violet
        CGColor(red: 0.88, green: 0.10, blue: 0.95, alpha: 1),   // magenta
        CGColor(red: 1.00, green: 0.18, blue: 0.50, alpha: 1),   // hot pink
        CGColor(red: 1.00, green: 0.50, blue: 0.08, alpha: 1),   // orange
        CGColor(red: 1.00, green: 0.78, blue: 0.00, alpha: 1),   // yellow
    ]

    for i in 0 ..< barCount {
        let h  = heights[i] * maxBarH
        let x  = originX + CGFloat(i) * (barW + gap)
        let y  = baseline - h
        let r  = barW / 2
        let c  = barColors[i]

        // Soft glow (lighter on white background)
        let gw = barW * 2.4
        let gx = x - (gw - barW) / 2
        let glowPath = CGPath(roundedRect: CGRect(x: gx, y: y - r, width: gw, height: h + r * 2),
                              cornerWidth: gw / 2, cornerHeight: gw / 2, transform: nil)
        ctx.setFillColor(c.copy(alpha: 0.18)!)
        ctx.addPath(glowPath); ctx.fillPath()

        // Bar body with vertical gradient (opaque top, slightly faded bottom)
        let barPath = CGPath(roundedRect: CGRect(x: x, y: y, width: barW, height: h),
                             cornerWidth: r, cornerHeight: r, transform: nil)
        ctx.saveGState()
        ctx.addPath(barPath); ctx.clip()
        let barGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [c, c.copy(alpha: 0.65)!] as CFArray,
                                  locations: [0, 1])!
        ctx.drawLinearGradient(barGrad,
                               start: CGPoint(x: x, y: y),
                               end:   CGPoint(x: x, y: y + h), options: [])
        ctx.restoreGState()

        // Top cap highlight (white sheen)
        let capH = min(barW * 0.55, h * 0.14)
        let capPath = CGPath(roundedRect: CGRect(x: x, y: y, width: barW, height: capH),
                             cornerWidth: r, cornerHeight: r, transform: nil)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.55))
        ctx.addPath(capPath); ctx.fillPath()
    }

    // Baseline
    ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.10))
    ctx.setLineWidth(max(1, s * 0.008))
    ctx.move(to: CGPoint(x: originX - s * 0.02, y: baseline))
    ctx.addLine(to: CGPoint(x: originX + totalW + s * 0.02, y: baseline))
    ctx.strokePath()
}

func savePNG(_ rep: NSBitmapImageRep, to path: String) {
    guard let png = rep.representation(using: .png, properties: [:]) else {
        print("❌ encode failed: \(path)"); return
    }
    do { try png.write(to: URL(fileURLWithPath: path)); print("✅ \(path)") }
    catch { print("❌ \(path): \(error)") }
}

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent().path
let outDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "\(scriptDir)/../Rhythm/Assets.xcassets/AppIcon.appiconset"

print("Generating icons → \(outDir)\n")
for px in [16, 32, 64, 128, 256, 512, 1024] {
    savePNG(drawIcon(pixels: px), to: "\(outDir)/icon_\(px).png")
}
print("\nDone!")
