import AppKit

guard CommandLine.arguments.count == 5 else {
    FileHandle.standardError.write(Data("usage: RenderDMGBackground <icon.icns> <width> <height> <out.png>\n".utf8))
    exit(1)
}

let icnsPath = CommandLine.arguments[1]
let width = CGFloat(Double(CommandLine.arguments[2])!)
let height = CGFloat(Double(CommandLine.arguments[3])!)
let outPath = CommandLine.arguments[4]

guard let icon = NSImage(contentsOfFile: icnsPath), icon.size.width > 0 else {
    FileHandle.standardError.write(Data("failed to load icon\n".utf8))
    exit(1)
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    FileHandle.standardError.write(Data("failed to create bitmap\n".utf8))
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let bg = NSColor(calibratedWhite: 0.94, alpha: 1)
bg.setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

let iconMax: CGFloat = min(width, height) * 0.45
let iconSize = icon.size
let scale = min(iconMax / iconSize.width, iconMax / iconSize.height)
let w = iconSize.width * scale
let h = iconSize.height * scale
let x = (width - w) / 2
let y = (height - h) / 2

icon.draw(
    in: NSRect(x: x, y: y, width: w, height: h),
    from: NSRect(origin: .zero, size: iconSize),
    operation: .sourceOver,
    fraction: 1.0,
    respectFlipped: false,
    hints: [.interpolation: NSImageInterpolation.high]
)

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to encode png\n".utf8))
    exit(1)
}

do {
    try png.write(to: URL(fileURLWithPath: outPath))
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(1)
}
