// Renders README screenshots from the real SwiftUI views using demo data.
// Built by tools/make_screenshots.sh together with Sources/*.swift (with -D SNAPSHOT).
// Nothing here talks to `mo`, so screenshots never contain your own processes or paths.

import SwiftUI
import AppKit

@main
struct Snapshots {
    static let size = NSSize(width: 1240, height: 800)

    @MainActor
    static func main() {
        let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs/screenshots"
        try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let shots: [(String, AppTheme, AppLanguage, AppSection, CleanFlow.Phase)] = [
            ("apple-clean", .apple, .en, .clean, .review),
            ("neon-clean", .neon, .en, .clean, .review),
            ("cyber-clean", .cyber, .en, .clean, .review),
            ("apple-health", .apple, .en, .health, .review),
            ("neon-done", .neon, .en, .clean, .done),
            ("apple-clean-uk", .apple, .uk, .clean, .review),
            ("cyber-clean-ru", .cyber, .ru, .clean, .review),
            ("neon-clean-uk", .neon, .uk, .clean, .review),
        ]
        for (name, theme, lang, section, phase) in shots {
            UserDefaults.standard.set(theme.rawValue, forKey: "theme")
            UserDefaults.standard.set(lang.rawValue, forKey: L10n.storageKey)
            render(name: name, theme: theme, section: section, phase: phase, to: out)
            print("✓ \(out)/\(name).png")
        }
    }

    @MainActor
    static func render(name: String, theme: AppTheme, section: AppSection, phase: CleanFlow.Phase, to dir: String) {
        let status = StatusModel()
        status.snapshot = try? Mole.decoder.decode(StatusSnapshot.self, from: Data(demoStatus.utf8))
        status.cpuHistory = (0..<40).map { (i: Int) -> Double in
            let x = Double(i)
            return 22.0 + 14.0 * sin(x / 4.0) + Double(i % 3) * 3.0
        }
        status.memHistory = (0..<40).map { (i: Int) -> Double in 61.0 + 4.0 * sin(Double(i) / 6.0) }
        let flow = demoFlow(phase)

        let root = Group {
            switch theme {
            // NavigationSplitView (AppKit) вне экрана не рисуется — для скриншота собираем ту же раскладку из SwiftUI:
            // простой сайдбар + настоящий контент темы.
            case .apple: SnapshotAppleRoot(section: section)
            case .neon: NeonRoot(section: .constant(section))
            case .cyber: CyberRoot(section: .constant(section))
            }
        }
        .environmentObject(status)
        .environmentObject(flow)
        .environment(\.liveMotion, false)
        .tint(theme.accent)
        .frame(width: size.width, height: size.height)

        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                              // fullSizeContentView ломает офскрин-рендер платформенного ScrollView (тема Apple).
                              styleMask: theme == .apple ? [.titled] : [.titled, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.appearance = NSAppearance(named: theme == .apple ? .aqua : .darkAqua)
        let host = NSHostingView(rootView: root)
        host.frame = NSRect(origin: .zero, size: size)
        window.contentView = host
        window.setFrameOrigin(NSPoint(x: -20000, y: -20000))
        window.orderFrontRegardless()

        // Let entrance springs and counters settle.
        RunLoop.main.run(until: Date().addingTimeInterval(2.5))

        guard let view = window.contentView,
              let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        if let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        }
        window.orderOut(nil)
    }

    @MainActor
    static func demoFlow(_ phase: CleanFlow.Phase) -> CleanFlow {
        let flow = CleanFlow()
        let demo: [(String, Double, Bool)] = [
            ("Developer tools", 5.05e9, true), ("Apps & utilities", 2.84e9, true),
            ("User essentials", 2.76e9, true), ("Browsers", 0.35e9, true),
            ("App caches", 0.25e9, true), ("Large files", 18.0e9, false),
        ]
        flow.categories = demo.map { id, size, selected in
            let m = CleanFlow.meta(id)
            var c = CleanCategory(id: id, title: m.0, subtitle: m.1, symbol: m.2, tint: m.3, code: m.4)
            c.bytes = size
            c.selected = selected
            c.state = .found
            if phase == .done && selected { c.removed = size; c.state = .cleaned }
            return c
        }
        flow.progress = 1
        flow.phase = phase
        if phase == .done { flow.freed = flow.categories.filter(\.selected).reduce(0) { $0 + $1.bytes } }
        flow.logLines = ["$ mo clean --dry-run", "➤ Developer tools", "➤ Apps & utilities", "Potential space: 11.25GB"]
        return flow
    }

    static let demoStatus = """
    {"host":"demo","uptime":"3d 4h","hardware":{"model":"MacBook Pro","os_version":"macOS 26.3"},
     "health_score":86,"health_score_msg":"Good: Plenty of free space",
     "cpu":{"usage":23.4,"per_core":[41,35,28,22,18,15,12,11,9,8,7,6]},
     "memory":{"used":20400000000,"total":34359738368,"used_percent":59.4},
     "disks":[{"mount":"/","used":352000000000,"total":494384795648,"used_percent":71.2,"external":false}],
     "network":[{"name":"en0","rx_rate_mbs":1.24,"tx_rate_mbs":0.18}],
     "batteries":[{"percent":87,"status":"charging","time_left":"0:48","capacity":94}],
     "top_processes":[{"pid":1,"name":"Safari","cpu":18.2,"memory_bytes":1900000000},
                      {"pid":2,"name":"Xcode","cpu":12.5,"memory_bytes":3100000000},
                      {"pid":3,"name":"WindowServer","cpu":8.1,"memory_bytes":640000000},
                      {"pid":4,"name":"Music","cpu":3.3,"memory_bytes":410000000}]}
    """
}

/// Стенд-ин для NavigationSplitView только для скриншотов: те же разделы, иконки и бейдж, что в AppleRoot.
struct SnapshotAppleRoot: View {
    var section: AppSection
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(AppSection.allCases) { s in
                    Label(s.title, systemImage: s.icon)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 6).fill(s == section ? Color.primary.opacity(0.1) : .clear))
                }
                Spacer()
                ConnectedBadge().padding(.horizontal, 4)
            }
            .padding(.top, 44).padding(.horizontal, 10).padding(.bottom, 12)
            .frame(width: 210)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.92))
            Divider()
            // Плавающие обои (AppleWallpaper) в офскрин-рендер не попадают вместе со ScrollView — снимок без них.
            SectionContent(section: section, theme: .apple)
        }
    }
}
