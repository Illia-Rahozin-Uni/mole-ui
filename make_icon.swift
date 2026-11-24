// Draws the app icon into an .iconset folder (used by install.sh)
import AppKit

@main
struct MakeIcon {
    static func main() {
        let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
        try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
        let sizes: [(String, Int)] = [
            ("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64),
            ("128x128", 128), ("128x128@2x", 256), ("256x256", 256), ("256x256@2x", 512),
            ("512x512", 512), ("512x512@2x", 1024),
        ]
        for (name, px) in sizes {
            guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                             isPlanar: false, colorSpaceName: .deviceRGB,
                                             bytesPerRow: 0, bitsPerPixel: 0) else { continue }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
            let s = CGFloat(px)
            let inset = s * 0.1
            let rect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
            let path = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.width * 0.225)
            NSGradient(starting: NSColor(calibratedRed: 0.36, green: 0.30, blue: 0.85, alpha: 1),
                       ending: NSColor(calibratedRed: 0.10, green: 0.62, blue: 0.55, alpha: 1))?
                .draw(in: path, angle: -60)
            let cfg = NSImage.SymbolConfiguration(pointSize: s * 0.42, weight: .semibold)
                .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
            if let sym = NSImage(systemSymbolName: "hare.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(cfg) {
                let sz = sym.size
                sym.draw(in: NSRect(x: (s - sz.width) / 2, y: (s - sz.height) / 2, width: sz.width, height: sz.height))
            }
            NSGraphicsContext.restoreGraphicsState()
            if let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: URL(fileURLWithPath: "\(out)/icon_\(name).png"))
            }
        }
    }
}
