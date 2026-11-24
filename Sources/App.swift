// Mole UI — приложение, переключатель тем и общие экраны.

import SwiftUI
import AppKit
import Charts

// MARK: - Темы и разделы

enum AppTheme: String, CaseIterable, Identifiable {
    case apple, neon, cyber
    var id: String { rawValue }
    var title: String {
        switch self {
        case .apple: return "Apple"
        case .neon: return "Neon"
        case .cyber: return "Cyber"
        }
    }
    var accent: Color {
        switch self {
        case .apple: return Color(red: 0.04, green: 0.52, blue: 1.0)
        case .neon: return Color(hex: 0x3DDC97)
        case .cyber: return Color(hex: 0x00F0FF)
        }
    }
}

enum AppSection: String, CaseIterable, Identifiable {
    case clean, health, apps, disk, history, tools
    var id: String { rawValue }
    var title: String {
        switch self {
        case .clean: return L("Clean")
        case .health: return L("Health")
        case .apps: return L("Apps")
        case .disk: return L("Disk")
        case .history: return L("History")
        case .tools: return L("Tools")
        }
    }
    var icon: String {
        switch self {
        case .clean: return "sparkles"
        case .health: return "gauge.with.dots.needle.67percent"
        case .apps: return "square.grid.2x2"
        case .disk: return "chart.pie"
        case .history: return "clock"
        case .tools: return "wrench.and.screwdriver"
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

// MARK: - Приложение

// SNAPSHOT: tools/make_screenshots.sh собирает те же исходники со своей точкой входа.
#if !SNAPSHOT
@main
#endif
struct MoleUIApp: App {
    @StateObject private var status = StatusModel()
    @StateObject private var flow = CleanFlow()
    @AppStorage("theme") private var theme: AppTheme = .apple

    var body: some Scene {
        WindowGroup("Mole", id: "main") {
            ThemedRoot()
                .environmentObject(status)
                .environmentObject(flow)
                .preferredColorScheme(theme == .apple ? nil : .dark)
                .tint(theme.accent)
                .frame(minWidth: 1040, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1240, height: 800)

        MenuBarExtra {
            MenuBarContent()
                .environmentObject(status)
                .environmentObject(flow)
        } label: {
            Image(systemName: "hare")
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Когда анимациям можно двигаться

private struct LiveMotionKey: EnvironmentKey { static let defaultValue = true }

extension EnvironmentValues {
    /// false — все бесконечные анимации стоят: окно скрыто/свёрнуто, приложение в фоне без работы,
    /// или включено «Уменьшить движение». Читают все TimelineView тем.
    var liveMotion: Bool {
        get { self[LiveMotionKey.self] }
        set { self[LiveMotionKey.self] = newValue }
    }
}

/// Видно ли главное окно и активно ли приложение.
@MainActor
final class WindowActivity: ObservableObject {
    @Published private(set) var appActive = true
    @Published private(set) var windowVisible = true
    private var tokens: [NSObjectProtocol] = []

    init() {
        let names: [Notification.Name] = [
            NSApplication.didBecomeActiveNotification, NSApplication.didResignActiveNotification,
            NSApplication.didHideNotification, NSApplication.didUnhideNotification,
            NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification,
            NSWindow.didDeminiaturizeNotification, NSWindow.willCloseNotification,
        ]
        for name in names {
            tokens.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                // Асинхронно: на willClose окно ещё числится видимым.
                Task { @MainActor in self?.refresh() }
            })
        }
    }

    func refresh() {
        appActive = NSApp.isActive
        // Строка меню (NSStatusBarWindow) и окно MenuBarExtra (панель) не в счёт — только окна с заголовком.
        windowVisible = NSApp.windows.contains { w in
            !(w is NSPanel) && w.styleMask.contains(.titled) && w.isVisible && !w.isMiniaturized
                && w.occlusionState.contains(.visible)
        }
    }
}

struct ThemedRoot: View {
    @EnvironmentObject var status: StatusModel
    @EnvironmentObject var flow: CleanFlow
    @AppStorage("theme") private var theme: AppTheme = .apple
    @State private var section: AppSection = .clean
    @State private var moFound = Mole.binary != nil
    @StateObject private var activity = WindowActivity()
    /// Смена языка пересобирает дерево — все L(...) перечитываются.
    @AppStorage(L10n.storageKey) private var language: AppLanguage = .system
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// В фоне анимации продолжаются, только пока идёт скан/очистка — чтобы был виден прогресс.
    private var liveMotion: Bool {
        !reduceMotion && activity.windowVisible && (activity.appActive || flow.isBusy)
    }

    var body: some View {
        content
            .id(language)
            .environment(\.liveMotion, liveMotion)
            .onAppear { activity.refresh() }
    }

    private var content: some View {
        Group {
            if !moFound {
                MissingMoleView { moFound = Mole.binary != nil; if moFound { status.start() } }
            } else {
                switch theme {
                case .apple: AppleRoot(section: $section)
                case .neon: NeonRoot(section: $section)
                case .cyber: CyberRoot(section: $section)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: theme)
        .onAppear { if moFound { status.start() } }
    }
}

/// Содержимое раздела: «Очистка» у каждой темы своя, остальное — общее.
struct SectionContent: View {
    var section: AppSection
    var theme: AppTheme
    var body: some View {
        switch section {
        case .clean:
            switch theme {
            case .apple: AppleCleanView()
            case .neon: NeonCleanView()
            case .cyber: CyberCleanView()
            }
        case .health: HealthView()
        case .apps: AppsView()
        case .disk: DiskView()
        case .history: HistoryView()
        case .tools: ToolsView()
        }
    }
}

struct ThemePicker: View {
    @AppStorage("theme") private var theme: AppTheme = .apple
    var body: some View {
        Picker(L("Theme"), selection: $theme) {
            ForEach(AppTheme.allCases) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 210)
    }
}

// MARK: - Общие компоненты

extension View {
    /// Стеклянная подложка. В офскрин-рендере скриншотов (SNAPSHOT) материал не рисуется — там полупрозрачный цвет.
    @ViewBuilder func glass<S: Shape>(_ shape: S) -> some View {
        #if SNAPSHOT
        background(Color(nsColor: .windowBackgroundColor).opacity(0.72), in: shape)
        #else
        background(.regularMaterial, in: shape)
        #endif
    }
}

/// Число, которое плавно «досчитывается» при изменении.
struct CountingText: View, Animatable {
    var value: Double
    var format: (Double) -> String
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    var body: some View { Text(format(value)).monospacedDigit() }
}

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

struct Checkmark: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.2, y: r.minY + r.height * 0.52))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.42, y: r.minY + r.height * 0.72))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.8, y: r.minY + r.height * 0.3))
        return p
    }
}

struct Shimmer: ViewModifier {
    var active: Bool = true
    @Environment(\.liveMotion) private var live
    func body(content: Content) -> some View {
        content
            .overlay {
                // Блик идёт по времени, а не repeatForever: тот крутится на частоте дисплея и не умеет вставать на паузу.
                if active && live {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { ctx in
                        let x = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.6) / 1.6 * 2 - 1
                        GeometryReader { g in
                            LinearGradient(colors: [.clear, .white.opacity(0.75), .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: g.size.width * 0.35)
                                .offset(x: x * g.size.width * 1.35)
                        }
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
    }
}

extension View {
    func shimmer(_ active: Bool = true) -> some View { modifier(Shimmer(active: active)) }
}

struct Sparkline: View {
    var values: [Double]
    var color: Color
    var height: CGFloat = 54
    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { item in
            AreaMark(x: .value("t", item.offset), y: .value("v", item.element))
                .foregroundStyle(color.opacity(0.15))
                .interpolationMethod(.catmullRom)
            LineMark(x: .value("t", item.offset), y: .value("v", item.element))
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...100)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
        .animation(.easeInOut(duration: 0.6), value: values)
    }
}

struct PageHeader: View {
    var title: String
    var subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.weight(.bold))
            Text(subtitle).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Card<Content: View>: View {
    var title: String
    var icon: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.07)))
    }
}

func levelColor(_ v: Double) -> Color { v < 60 ? .green : (v < 85 ? .orange : .red) }

struct UsageBar: View {
    var value: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule().fill(levelColor(value))
                    .frame(width: max(4, g.size.width * min(max(value, 0), 100) / 100))
            }
        }
        .frame(height: 8)
        .animation(.easeInOut(duration: 0.6), value: value)
    }
}

// MARK: - Здоровье

struct HealthView: View {
    @EnvironmentObject var status: StatusModel
    private let cols = [GridItem(.adaptive(minimum: 230), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                let s = status.snapshot
                PageHeader(title: L("Health"),
                           subtitle: [s?.hardware?.model, s?.hardware?.osVersion, s?.uptime.map { L("up %@", $0) }]
                            .compactMap { $0 }.joined(separator: " · "))
                if let s {
                    HStack(spacing: 24) {
                        ZStack {
                            Circle().stroke(Color.primary.opacity(0.08), lineWidth: 12)
                            Circle().trim(from: 0, to: (s.healthScore ?? 0) / 100)
                                .stroke(levelColor(100 - (s.healthScore ?? 0)), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: s.healthScore)
                            CountingText(value: s.healthScore ?? 0) { "\(Int($0))" }
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                        }
                        .frame(width: 120, height: 120)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("System health")).font(.title2.weight(.semibold))
                            Text(s.healthScoreMsg ?? "").foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(18)
                    .glass(RoundedRectangle(cornerRadius: 16))

                    LazyVGrid(columns: cols, spacing: 14) {
                        Card(title: L("CPU"), icon: "cpu") {
                            Text(pct(s.cpu?.usage)).font(.system(size: 28, weight: .semibold, design: .rounded))
                            Sparkline(values: status.cpuHistory, color: .accentColor)
                        }
                        Card(title: L("Memory"), icon: "memorychip") {
                            Text(pct(s.memory?.usedPercent)).font(.system(size: 28, weight: .semibold, design: .rounded))
                            Sparkline(values: status.memHistory, color: .purple)
                            Text(L("%@ of %@", bytes(s.memory?.used), bytes(s.memory?.total))).font(.caption).foregroundStyle(.secondary)
                        }
                        if let d = s.mainDisk {
                            Card(title: L("Disk"), icon: "internaldrive") {
                                Text(pct(d.usedPercent)).font(.system(size: 28, weight: .semibold, design: .rounded))
                                UsageBar(value: d.usedPercent ?? 0)
                                Text(L("%@ free of %@", bytes(s.diskFree), bytes(d.total))).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        if let b = s.batteries?.first {
                            Card(title: L("Battery"), icon: "battery.75percent") {
                                Text(pct(b.percent)).font(.system(size: 28, weight: .semibold, design: .rounded))
                                Text([b.status, b.timeLeft, b.capacity.map { L("capacity %@%%", "\(Int($0))") }]
                                        .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if let procs = s.topProcesses, !procs.isEmpty {
                        Card(title: L("Top processes"), icon: "list.number") {
                            ForEach(procs.prefix(8)) { p in
                                HStack {
                                    Text(p.name ?? "?").lineLimit(1)
                                    Spacer()
                                    Text(pct(p.cpu)).monospacedDigit().frame(width: 60, alignment: .trailing)
                                    Text(p.memoryBytes.map { bytes($0) } ?? pct(p.memory))
                                        .monospacedDigit().foregroundStyle(.secondary).frame(width: 90, alignment: .trailing)
                                }
                                .font(.callout)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(status.error ?? L("Collecting system data…")).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                }
            }
            .padding(28)
        }
    }
}

// MARK: - Приложения

struct AppsView: View {
    @State private var apps: [AppInfo] = []
    @State private var loading = false
    @State private var query = ""
    @State private var confirm: AppInfo?

    var filtered: [AppInfo] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        let list = q.isEmpty ? apps : apps.filter { ($0.name ?? "").lowercased().contains(q) }
        return list.sorted { (parseMoleSize(Substring($0.size ?? "")) ?? 0) > (parseMoleSize(Substring($1.size ?? "")) ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                PageHeader(title: L("Apps"), subtitle: L("Uninstall apps together with their settings and caches. Everything goes to the Trash by default."))
                Button { Task { await load() } } label: { Label(L("Refresh"), systemImage: "arrow.clockwise") }
            }
            TextField(L("Search by name"), text: $query).textFieldStyle(.roundedBorder).frame(maxWidth: 320)
            if loading && apps.isEmpty {
                VStack(spacing: 10) { ProgressView(); Text(L("Scanning apps…")).foregroundStyle(.secondary) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filtered) { app in
                    HStack(spacing: 12) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.path ?? "/Applications"))
                            .resizable().frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name ?? "?").font(.body.weight(.medium))
                            Text(app.bundleId ?? "").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(app.size ?? "").monospacedDigit().foregroundStyle(.secondary).frame(width: 80, alignment: .trailing)
                        Button(L("Uninstall…")) { confirm = app }.controlSize(.small)
                    }
                    .padding(.vertical, 3)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .padding(28)
        .task { if apps.isEmpty { await load() } }
        .confirmationDialog(confirm.map { L("Uninstall “%@”?", $0.name ?? "") } ?? "",
                            isPresented: Binding(get: { confirm != nil }, set: { if !$0 { confirm = nil } }),
                            presenting: confirm) { app in
            Button(L("Uninstall with Mole (to Trash)"), role: .destructive) {
                Mole.openInTerminal(["uninstall", app.uninstallName ?? app.name ?? ""])
            }
            Button(L("Cancel"), role: .cancel) {}
        } message: { _ in
            Text(L("Terminal will open: Mole will show what it finds and ask you to confirm."))
        }
    }

    func load() async {
        loading = true
        defer { loading = false }
        guard let data = await Mole.run(["uninstall", "--list"]) else { return }
        if let list = try? Mole.decoder.decode([AppInfo].self, from: data) { apps = list }
    }
}

// MARK: - Диск

struct DiskView: View {
    @State private var stack: [String] = [NSHomeDirectory()]
    @State private var result: AnalyzeResult?
    @State private var loading = false
    @State private var trashConfirm: AnalyzeResult.Entry?

    var current: String { stack.last ?? NSHomeDirectory() }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                PageHeader(title: L("Disk"), subtitle: L("What's taking up space. Click a folder to open it."))
                Button(L("Choose folder…")) { pick() }
                Button(L("Open in Terminal")) { Mole.openInTerminal(["analyze", current]) }
            }
            HStack(spacing: 8) {
                Button { stack.removeLast(); Task { await scan() } } label: { Image(systemName: "chevron.left") }
                    .disabled(stack.count < 2)
                Text(current.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.callout.monospaced()).lineLimit(1).truncationMode(.middle)
                Spacer()
                if let t = result?.totalSize { Text(L("Total: %@", bytes(t))).foregroundStyle(.secondary) }
            }
            if loading {
                VStack(spacing: 10) {
                    ProgressView()
                    Text(L("Scanning… a large folder can take a minute")).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let r = result {
                let entries = (r.entries ?? []).sorted { ($0.size ?? 0) > ($1.size ?? 0) }
                let maxSize = max(entries.first?.size ?? 1, 1)
                List {
                    ForEach(entries) { e in
                        HStack(spacing: 10) {
                            Image(systemName: e.isDir == true ? "folder.fill" : "doc")
                                .foregroundStyle(e.isDir == true ? Color.accentColor : Color.secondary)
                                .frame(width: 20)
                            Text(e.name ?? "?").lineLimit(1)
                            Spacer()
                            Capsule().fill(Color.accentColor.opacity(0.55))
                                .frame(width: max(3, 140 * (e.size ?? 0) / maxSize), height: 6)
                                .frame(width: 140, alignment: .leading)
                            Text(bytes(e.size)).monospacedDigit().frame(width: 80, alignment: .trailing)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if e.isDir == true, let p = e.path { stack.append(p); Task { await scan() } }
                        }
                        .contextMenu {
                            Button(L("Show in Finder")) {
                                if let p = e.path { NSWorkspace.shared.selectFile(p, inFileViewerRootedAtPath: "") }
                            }
                            Button(L("Move to Trash…"), role: .destructive) { trashConfirm = e }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            } else {
                Text(L("Couldn't scan this folder.")).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(28)
        .task { if result == nil { await scan() } }
        .confirmationDialog(trashConfirm.map { L("Move “%@” to the Trash?", $0.name ?? "") } ?? "",
                            isPresented: Binding(get: { trashConfirm != nil }, set: { if !$0 { trashConfirm = nil } }),
                            presenting: trashConfirm) { e in
            Button(L("Move to Trash"), role: .destructive) {
                guard let p = e.path else { return }
                NSWorkspace.shared.recycle([URL(fileURLWithPath: p)]) { _, _ in
                    Task { @MainActor in await scan() }
                }
            }
            Button(L("Cancel"), role: .cancel) {}
        } message: { e in
            Text(L("%@. You can restore it from the Trash.", bytes(e.size)))
        }
    }

    func scan() async {
        loading = true
        defer { loading = false }
        guard let data = await Mole.run(["analyze", "--json", current]) else { result = nil; return }
        result = try? Mole.decoder.decode(AnalyzeResult.self, from: data)
    }

    func pick() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = L("Analyze")
        if panel.runModal() == .OK, let url = panel.url {
            stack = [url.path]
            Task { await scan() }
        }
    }
}

// MARK: - История

struct HistoryView: View {
    @State private var sessions: [HistoryResult.Session] = []
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                PageHeader(title: L("History"), subtitle: L("What Mole did and when"))
                Button { Task { await load() } } label: { Label(L("Refresh"), systemImage: "arrow.clockwise") }
            }
            if !loaded {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if sessions.isEmpty {
                Text(L("Nothing here yet.")).foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(sessions) { s in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("mo \(s.command ?? "?")").font(.body.weight(.medium))
                            Text(s.startedAt ?? "").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let a = s.actions {
                            Text(L("removed %@ · trashed %@", "\(Int(a.removed ?? 0))", "\(Int(a.trashed ?? 0))"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text(s.size ?? "").monospacedDigit().frame(width: 80, alignment: .trailing)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .padding(28)
        .task { if !loaded { await load() } }
    }

    func load() async {
        defer { loaded = true }
        guard let data = await Mole.run(["history", "--json"]),
              let r = try? Mole.decoder.decode(HistoryResult.self, from: data) else { return }
        sessions = r.sessions ?? []
    }
}

// MARK: - Инструменты

struct ToolsView: View {
    @State private var version = ""
    struct Tool: Identifiable {
        var id: String { title }
        var title: String; var subtitle: String; var icon: String; var args: [String]
    }
    var tools: [Tool] { [
        .init(title: L("Full clean with Mole"), subtitle: L("Including system caches (asks for password)"), icon: "terminal", args: ["clean"]),
        .init(title: L("Optimize"), subtitle: L("DNS, Spotlight, Finder services"), icon: "bolt", args: ["optimize"]),
        .init(title: L("Old installers"), subtitle: L("Find and remove .dmg/.pkg"), icon: "shippingbox", args: ["installer"]),
        .init(title: L("Touch ID for sudo"), subtitle: L("Admin password with your finger"), icon: "touchid", args: ["touchid"]),
        .init(title: L("Update Mole"), subtitle: L("Download the latest version"), icon: "arrow.down.circle", args: ["update"]),
        .init(title: L("Protect caches"), subtitle: L("Cleanup whitelist"), icon: "lock.shield", args: ["clean", "--whitelist"]),
        .init(title: L("Project folders"), subtitle: L("Where to look for node_modules"), icon: "folder.badge.gearshape", args: ["purge", "--paths"]),
        .init(title: L("Classic Mole"), subtitle: L("Native menu in Terminal"), icon: "hare", args: []),
    ] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(title: L("Tools"), subtitle: version.isEmpty ? L("Mole settings") : version)
                VStack(spacing: 12) {
                    HStack { Text(L("Appearance")); Spacer(); ThemePicker() }
                    Divider()
                    HStack { Text(L("Language")); Spacer(); LanguagePicker() }
                }
                .padding(14).glass(RoundedRectangle(cornerRadius: 12))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                    ForEach(tools) { t in
                        Button { Mole.openInTerminal(t.args) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: t.icon).font(.title2).frame(width: 36).foregroundStyle(Color.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.title).font(.headline).foregroundStyle(.primary)
                                    Text(t.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.forward.app").foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .glass(RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableStyle(scale: 0.97))
                    }
                }
                Button(L("Open Mole operations log")) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/Library/Logs/mole/operations.log"))
                }
            }
            .padding(28)
        }
        .task {
            if let d = await Mole.run(["--version"]) {
                version = Mole.stripANSI(String(decoding: d, as: UTF8.self)).split(separator: "\n").first.map(String.init) ?? ""
            }
        }
    }
}

// MARK: - Mole не установлен

struct MissingMoleView: View {
    var recheck: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hare").font(.system(size: 56)).foregroundStyle(.secondary)
            Text(L("Mole not found")).font(.title.weight(.semibold))
            Text(L("This app is a front end for the mo command. Install it and click “Check again”."))
                .foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 420)
            HStack {
                Button(L("Install with Homebrew")) { Mole.openInTerminal(command: "brew install mole") }
                    .buttonStyle(.borderedProminent)
                Button(L("Check again")) { Mole.resetCache(); recheck() }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Строка меню

struct MenuBarContent: View {
    @EnvironmentObject var status: StatusModel
    @EnvironmentObject var flow: CleanFlow
    @Environment(\.openWindow) private var openWindow
    @AppStorage(L10n.storageKey) private var language: AppLanguage = .system

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let s = status.snapshot {
                HStack {
                    Text(L("Health")).font(.headline)
                    Spacer()
                    Text("\(Int(s.healthScore ?? 0))/100").font(.headline.monospacedDigit())
                }
                row(L("CPU"), s.cpu?.usage)
                row(L("Memory"), s.memory?.usedPercent)
                row(L("Disk"), s.mainDisk?.usedPercent)
            } else {
                Text(status.error ?? L("Collecting data…")).foregroundStyle(.secondary)
            }
            Divider()
            Button(L("Find junk")) { open(); flow.scan() }
            Button(L("Open Mole")) { open() }
            Button(L("Quit")) { NSApp.terminate(nil) }
        }
        .buttonStyle(.borderless)
        .padding(14)
        .frame(width: 260)
        .onAppear { status.start() }
    }

    func open() {
        NSApp.activate(ignoringOtherApps: true)
        if let w = NSApp.windows.first(where: { $0.canBecomeMain }) { w.makeKeyAndOrderFront(nil) } else { openWindow(id: "main") }
    }

    func row(_ title: String, _ v: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack { Text(title); Spacer(); Text(pct(v)).monospacedDigit() }.font(.callout)
            UsageBar(value: v ?? 0)
        }
    }
}
