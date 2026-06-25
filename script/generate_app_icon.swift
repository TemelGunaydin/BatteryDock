#!/usr/bin/env swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let iconDirectory = root
    .appendingPathComponent("BatteryDock")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")

let symbolName = "minus.plus.batteryblock.fill"

let targets: [(filename: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for target in targets {
    let image = makeIcon(size: target.size)
    let url = iconDirectory.appendingPathComponent(target.filename)
    try writePNG(image: image, to: url)
}

func makeIcon(size: Int) -> NSImage {
    let size = CGFloat(size)
    let scale = size / 1024
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else {
        return image
    }

    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)

    let tileRect = CGRect(
        x: 56 * scale,
        y: 56 * scale,
        width: 912 * scale,
        height: 912 * scale
    )
    let tilePath = CGPath(
        roundedRect: tileRect,
        cornerWidth: 214 * scale,
        cornerHeight: 214 * scale,
        transform: nil
    )

    context.saveGState()
    context.addPath(tilePath)
    context.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            NSColor(calibratedRed: 0.06, green: 0.11, blue: 0.20, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.08, alpha: 1).cgColor
        ] as CFArray,
        locations: [0, 1]
    )
    if let gradient {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: tileRect.minX, y: tileRect.maxY),
            end: CGPoint(x: tileRect.maxX, y: tileRect.minY),
            options: []
        )
    }

    drawGlow(
        context: context,
        rect: CGRect(x: -160 * scale, y: 210 * scale, width: 560 * scale, height: 560 * scale),
        color: NSColor(calibratedRed: 0.13, green: 0.84, blue: 0.50, alpha: 0.24)
    )
    drawGlow(
        context: context,
        rect: CGRect(x: 540 * scale, y: 520 * scale, width: 520 * scale, height: 520 * scale),
        color: NSColor(calibratedRed: 0.23, green: 0.56, blue: 1.00, alpha: 0.18)
    )

    context.restoreGState()

    drawRoundedStroke(
        context: context,
        rect: tileRect.insetBy(dx: 8 * scale, dy: 8 * scale),
        radius: 206 * scale,
        color: NSColor.white.withAlphaComponent(0.10),
        lineWidth: max(1, 5 * scale)
    )
    drawRoundedStroke(
        context: context,
        rect: tileRect.insetBy(dx: 20 * scale, dy: 20 * scale),
        radius: 194 * scale,
        color: NSColor.black.withAlphaComponent(0.28),
        lineWidth: max(1, 3 * scale)
    )

    if size >= 64 {
        let plateRect = CGRect(x: 206 * scale, y: 300 * scale, width: 612 * scale, height: 116 * scale)
        drawRoundedFill(
            context: context,
            rect: plateRect,
            radius: 58 * scale,
            color: NSColor.black.withAlphaComponent(0.22)
        )
    }

    drawSymbol(in: CGRect(x: 172 * scale, y: 318 * scale, width: 680 * scale, height: 360 * scale), scale: scale)

    if size >= 128 {
        drawRoundedFill(
            context: context,
            rect: CGRect(x: 344 * scale, y: 226 * scale, width: 336 * scale, height: 30 * scale),
            radius: 15 * scale,
            color: NSColor.white.withAlphaComponent(0.18)
        )
    }

    return image
}

func drawSymbol(in rect: CGRect, scale: CGFloat) {
    guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
        return
    }

    let configuration = NSImage.SymbolConfiguration(
        pointSize: 280 * scale,
        weight: .regular,
        scale: .large
    )
    let configuredSymbol = symbol.withSymbolConfiguration(configuration) ?? symbol

    let symbolImage = NSImage(size: rect.size)
    symbolImage.lockFocus()
    NSColor.white.set()
    configuredSymbol.isTemplate = true
    configuredSymbol.draw(
        in: CGRect(origin: .zero, size: rect.size),
        from: .zero,
        operation: .sourceOver,
        fraction: 1
    )
    symbolImage.unlockFocus()

    let tinted = tint(image: symbolImage, color: NSColor(calibratedRed: 0.90, green: 0.97, blue: 1.00, alpha: 1))
    tinted.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
}

func tint(image: NSImage, color: NSColor) -> NSImage {
    let tinted = NSImage(size: image.size)
    tinted.lockFocus()
    image.draw(in: CGRect(origin: .zero, size: image.size), from: .zero, operation: .sourceOver, fraction: 1)
    color.set()
    CGRect(origin: .zero, size: image.size).fill(using: .sourceAtop)
    tinted.unlockFocus()
    return tinted
}

func drawGlow(context: CGContext, rect: CGRect, color: NSColor) {
    context.saveGState()
    context.setShadow(offset: .zero, blur: rect.width * 0.18, color: color.cgColor)
    context.setFillColor(color.cgColor)
    context.fillEllipse(in: rect)
    context.restoreGState()
}

func drawRoundedFill(context: CGContext, rect: CGRect, radius: CGFloat, color: NSColor) {
    context.saveGState()
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.setFillColor(color.cgColor)
    context.fillPath()
    context.restoreGState()
}

func drawRoundedStroke(context: CGContext, rect: CGRect, radius: CGFloat, color: NSColor, lineWidth: CGFloat) {
    context.saveGState()
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.setStrokeColor(color.cgColor)
    context.setLineWidth(lineWidth)
    context.strokePath()
    context.restoreGState()
}

func writePNG(image: NSImage, to url: URL) throws {
    let pixelWidth = Int(image.size.width)
    let pixelHeight = Int(image.size.height)

    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else {
        throw IconGenerationError.pngEncodingFailed
    }

    bitmap.size = image.size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(in: CGRect(origin: .zero, size: image.size), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    guard
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw IconGenerationError.pngEncodingFailed
    }

    try pngData.write(to: url)
}

enum IconGenerationError: Error {
    case pngEncodingFailed
}
