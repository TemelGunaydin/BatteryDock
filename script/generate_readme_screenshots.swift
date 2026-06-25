import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDirectory = root.appendingPathComponent("docs/screenshots", isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

private let scale: CGFloat = 2

private func save(_ image: NSImage, name: String) throws {
    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let png = rep.representation(using: .png, properties: [:])
    else {
        throw CocoaError(.fileWriteUnknown)
    }

    try png.write(to: outputDirectory.appendingPathComponent(name))
}

private func makeImage(width: CGFloat, height: CGFloat, draw: (CGFloat, CGFloat) -> Void) -> NSImage {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    draw(width, height)
    image.unlockFocus()
    return image
}

private func y(_ top: CGFloat, _ height: CGFloat, in total: CGFloat) -> CGFloat {
    total - top - height
}

private func roundedRect(x: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, radius: CGFloat, totalHeight: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(
        roundedRect: NSRect(x: x, y: y(top, height, in: totalHeight), width: width, height: height),
        xRadius: radius,
        yRadius: radius
    ).fill()
}

private func line(x: CGFloat, top: CGFloat, width: CGFloat, totalHeight: CGFloat, color: NSColor) {
    color.setStroke()
    let path = NSBezierPath()
    let yy = y(top, 1, in: totalHeight)
    path.move(to: NSPoint(x: x, y: yy))
    path.line(to: NSPoint(x: x + width, y: yy))
    path.lineWidth = 1
    path.stroke()
}

private func text(_ string: String, x: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = .labelColor, alignment: NSTextAlignment = .left) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byTruncatingTail

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]

    string.draw(
        in: NSRect(x: x, y: y(top, height, in: currentHeight), width: width, height: height),
        withAttributes: attributes
    )
}

private var currentHeight: CGFloat = 0

private func symbol(_ name: String, x: CGFloat, top: CGFloat, size: CGFloat, color: NSColor = .secondaryLabelColor, weight: NSFont.Weight = .medium) {
    let configuration = NSImage.SymbolConfiguration(pointSize: size, weight: weight)
    guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(configuration) else {
        return
    }

    let tinted = NSImage(size: NSSize(width: size, height: size))
    tinted.lockFocus()
    color.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    image.draw(
        in: NSRect(x: 0, y: 0, width: size, height: size),
        from: .zero,
        operation: .destinationIn,
        fraction: 1
    )
    tinted.unlockFocus()

    tinted.draw(
        in: NSRect(x: x, y: y(top, size, in: currentHeight), width: size, height: size),
        from: .zero,
        operation: .sourceOver,
        fraction: 1
    )
}

private func meter(x: CGFloat, top: CGFloat, width: CGFloat, percent: Int) {
    roundedRect(x: x, top: top, width: width, height: 8, radius: 4, totalHeight: currentHeight, color: NSColor.secondaryLabelColor.withAlphaComponent(0.18))
    let fillWidth = max(4, width * CGFloat(percent) / 100)
    let fillColor: NSColor
    switch percent {
    case 0...20:
        fillColor = .systemRed
    case 21...50:
        fillColor = .systemOrange
    default:
        fillColor = .systemGreen
    }
    roundedRect(x: x, top: top, width: fillWidth, height: 8, radius: 4, totalHeight: currentHeight, color: fillColor)
}

private func popoverScreenshot() throws {
    let width: CGFloat = 920 * scale
    let height: CGFloat = 650 * scale
    let image = makeImage(width: width, height: height) { w, h in
        currentHeight = h
        NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.15, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: w, height: h).fill()

        roundedRect(x: 160 * scale, top: 70 * scale, width: 600 * scale, height: 500 * scale, radius: 22 * scale, totalHeight: h, color: NSColor.windowBackgroundColor.withAlphaComponent(0.94))

        symbol("minus.plus.batteryblock.fill", x: 188 * scale, top: 100 * scale, size: 24 * scale, color: .labelColor, weight: .semibold)
        text("BatteryDock", x: 226 * scale, top: 96 * scale, width: 220 * scale, height: 28 * scale, size: 18 * scale, weight: .semibold)
        text("3 connected devices", x: 226 * scale, top: 126 * scale, width: 220 * scale, height: 20 * scale, size: 13 * scale, color: .secondaryLabelColor)
        symbol("arrow.clockwise", x: 714 * scale, top: 108 * scale, size: 18 * scale)
        line(x: 160 * scale, top: 166 * scale, width: 600 * scale, totalHeight: h, color: NSColor.separatorColor)

        deviceRow(icon: "headphones", name: "AirPods Pro", rows: [("Left", 80), ("Right", 80), ("Case", 19)], top: 186 * scale)
        line(x: 230 * scale, top: 316 * scale, width: 500 * scale, totalHeight: h, color: NSColor.separatorColor)
        deviceRow(icon: "keyboard", name: "Magic Keyboard", rows: [("Battery", 86)], top: 336 * scale)
        line(x: 230 * scale, top: 418 * scale, width: 500 * scale, totalHeight: h, color: NSColor.separatorColor)
        deviceRow(icon: "rectangle.and.hand.point.up.left", name: "Magic Trackpad", rows: [("Battery", 24)], top: 438 * scale)

        line(x: 160 * scale, top: 520 * scale, width: 600 * scale, totalHeight: h, color: NSColor.separatorColor)
        text("Last updated: 17:30 - Option+B", x: 188 * scale, top: 538 * scale, width: 300 * scale, height: 20 * scale, size: 12 * scale, color: .secondaryLabelColor)
        symbol("gearshape", x: 690 * scale, top: 538 * scale, size: 18 * scale)
        symbol("power", x: 724 * scale, top: 538 * scale, size: 18 * scale)
    }
    try save(image, name: "popover.png")
}

private func deviceRow(icon: String, name: String, rows: [(String, Int)], top: CGFloat) {
    symbol(icon, x: 188 * scale, top: top + 4 * scale, size: 24 * scale)
    text(name, x: 230 * scale, top: top, width: 360 * scale, height: 24 * scale, size: 15 * scale, weight: .medium)

    for (index, row) in rows.enumerated() {
        let rowTop = top + 36 * scale + CGFloat(index) * 24 * scale
        text(row.0, x: 230 * scale, top: rowTop - 5 * scale, width: 70 * scale, height: 20 * scale, size: 12 * scale, color: .secondaryLabelColor)
        meter(x: 304 * scale, top: rowTop, width: 280 * scale, percent: row.1)
        text("\(row.1)%", x: 612 * scale, top: rowTop - 8 * scale, width: 70 * scale, height: 22 * scale, size: 13 * scale, weight: .medium, alignment: .right)
    }
}

private func settingsScreenshot() throws {
    let width: CGFloat = 920 * scale
    let height: CGFloat = 760 * scale
    let image = makeImage(width: width, height: height) { w, h in
        currentHeight = h
        NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.15, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: w, height: h).fill()

        roundedRect(x: 170 * scale, top: 58 * scale, width: 580 * scale, height: 640 * scale, radius: 22 * scale, totalHeight: h, color: NSColor.windowBackgroundColor.withAlphaComponent(0.94))
        symbol("chevron.left", x: 196 * scale, top: 88 * scale, size: 18 * scale, color: .labelColor, weight: .semibold)
        text("BatteryDock", x: 230 * scale, top: 78 * scale, width: 230 * scale, height: 24 * scale, size: 17 * scale, weight: .semibold)
        text("Settings", x: 230 * scale, top: 104 * scale, width: 230 * scale, height: 18 * scale, size: 12 * scale, color: .secondaryLabelColor)
        line(x: 170 * scale, top: 145 * scale, width: 580 * scale, totalHeight: h, color: NSColor.separatorColor)

        section("Shortcut", top: 172 * scale)
        roundedRect(x: 206 * scale, top: 214 * scale, width: 508 * scale, height: 58 * scale, radius: 10 * scale, totalHeight: h, color: NSColor.secondaryLabelColor.withAlphaComponent(0.10))
        text("Option+B", x: 226 * scale, top: 228 * scale, width: 210 * scale, height: 30 * scale, size: 22 * scale, weight: .semibold)
        symbol("keyboard.badge.ellipsis", x: 674 * scale, top: 230 * scale, size: 22 * scale)

        section("General", top: 306 * scale)
        row(icon: "power", title: "Launch at login", value: "On", top: 346 * scale)
        row(icon: "arrow.clockwise", title: "Refresh", value: "1 min", top: 396 * scale)
        row(icon: "globe", title: "Language", value: "English", top: 446 * scale)

        section("Notifications", top: 508 * scale)
        row(icon: "bell", title: "Low battery alerts", value: "On", top: 548 * scale)
        row(icon: "battery.25", title: "Threshold", value: "20%", top: 598 * scale)

        text("All battery data stays on this Mac. No backend, no tracking.", x: 206 * scale, top: 660 * scale, width: 508 * scale, height: 28 * scale, size: 12 * scale, color: .secondaryLabelColor)
    }
    try save(image, name: "settings.png")
}

private func section(_ title: String, top: CGFloat) {
    text(title.uppercased(), x: 206 * scale, top: top, width: 200 * scale, height: 18 * scale, size: 11 * scale, weight: .semibold, color: .secondaryLabelColor)
}

private func row(icon: String, title: String, value: String, top: CGFloat) {
    symbol(icon, x: 206 * scale, top: top + 1 * scale, size: 18 * scale)
    text(title, x: 238 * scale, top: top - 1 * scale, width: 260 * scale, height: 24 * scale, size: 14 * scale)
    text(value, x: 570 * scale, top: top - 1 * scale, width: 144 * scale, height: 24 * scale, size: 14 * scale, color: .secondaryLabelColor, alignment: .right)
    line(x: 238 * scale, top: top + 35 * scale, width: 476 * scale, totalHeight: currentHeight, color: NSColor.separatorColor.withAlphaComponent(0.6))
}

try popoverScreenshot()
try settingsScreenshot()
