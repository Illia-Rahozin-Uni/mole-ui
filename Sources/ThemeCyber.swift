// Тема 3 — Cyberpunk + терминал: неон, сканлайны, глитч, живые ядра, журнал.

import SwiftUI

enum CyberPal {
    static let bg = Color(hex: 0x030108)
    static let panel = Color(hex: 0x0A0716)
    static let panel2 = Color(hex: 0x0D0920)
    static let line = Color(hex: 0x2A1F48)
    static let tab = Color(hex: 0x160F2A)
    static let text = Color(hex: 0xCFC8E8)
    static let muted = Color(hex: 0x6F6694)
    static let dim = Color(hex: 0x3E3566)
    static let cyan = Color(hex: 0x00F0FF)
    static let magenta = Color(hex: 0xFF2BD6)
    static let yellow = Color(hex: 0xF5FF3B)
    static let ink = Color(hex: 0x05030C)
}

/// Параллелограмм для кнопок и вкладок.
struct Slanted: Shape {
    var cut: CGFloat = 10
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + cut, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - cut, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Прямоугольник со срезанными углами.
struct Chamfer: Shape {
    var cut: CGFloat = 22
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - cut, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + cut))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + cut, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - cut))
        p.closeSubpath()
        return p
    }
}

struct Hexagon: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let rad = min(r.width, r.height) / 2
        for i in 0..<6 {
            let a = Double(i) * .pi / 3 - .pi / 2
            let pt = CGPoint(x: c.x + rad * cos(a), y: c.y + rad * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

func asciiBar(_ pct: Double, _ n: Int) -> String {
    let f = max(0, min(n, Int((pct / 100 * Double(n)).rounded())))
    return String(repeating: "█", count: f) + String(repeating: "░", count: n - f)
}

func noise(_ n: Double) -> Double {
    let x = sin(n * 12.9898) * 43758.5453
    return x - floor(x)
}

struct CyberRoot: View {
    @Binding var section: AppSection
    @EnvironmentObject var status: StatusModel

    var body: some View {
        ZStack {
            CyberPal.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 18) {
                    Spacer().frame(width: 62)
                    GlitchText(text: "MOLE//NET", size: 22)
                    HStack(spacing: 6) {
                        ForEach(AppSection.allCases) { s in
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) { section = s }
                            } label: {
                                Text(s.title.uppercased())
                                    .font(.system(size: 12, weight: section == s ? .heavy : .regular, design: .monospaced))
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                    .foregroundStyle(section == s ? CyberPal.ink : Color(hex: 0x9C93C0))
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Slanted(cut: 8).fill(section == s ? CyberPal.cyan : CyberPal.tab))
                            }
                            .buttonStyle(PressableStyle(scale: 0.95))
                        }
                    }
                    Spacer()
                    LanguagePicker(compact: true)
                    ThemePicker()
                    Text("uptime ").foregroundStyle(CyberPal.muted) + Text(status.snapshot?.uptime ?? "--").foregroundStyle(.white)
                }
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 22).padding(.vertical, 12)
                .overlay(alignment: .bottom) { Rectangle().fill(CyberPal.line).frame(height: 1) }

                SectionContent(section: section, theme: .cyber)
                    .fontDesign(.monospaced)
                    .id(section)
                    .transition(.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(CyberPal.panel)
            .clipShape(Chamfer(cut: 26))
            .overlay(Chamfer(cut: 26).stroke(CyberPal.line, lineWidth: 1))
            .padding(10)

            Scanlines()
            ScanBeam()
        }
        .foregroundStyle(CyberPal.text)
        .modifier(CRTFlicker())
    }
}

struct Scanlines: View {
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.white.opacity(0.035)))
                y += 3
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct ScanBeam: View {
    @Environment(\.liveMotion) private var live
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: !live)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6) / 6
            GeometryReader { g in
                LinearGradient(colors: [.clear, CyberPal.cyan.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                    .offset(y: -120 + (g.size.height + 120) * t)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// Короткое CRT-мерцание раз в 5 с. Раньше TimelineView оборачивал всё окно и 10 раз в секунду
/// перестраивал всё дерево; теперь тикает только тонкий оверлей и только у моментов вспышки.
struct CRTFlicker: ViewModifier {
    @Environment(\.liveMotion) private var live
    func body(content: Content) -> some View {
        content.overlay {
            TimelineView(CRTSchedule(paused: !live)) { ctx in
                let k = Int(ctx.date.timeIntervalSinceReferenceDate * 10 + 0.001) % 50
                CyberPal.bg.opacity(k == 46 ? 0.14 : (k == 48 ? 0.07 : 0))
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

/// Тики только на 4.6, 4.7, 4.8 и 4.9 с каждого 5-секундного цикла (вспышка, гашение, вспышка, гашение).
struct CRTSchedule: TimelineSchedule {
    var paused: Bool
    func entries(from start: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var cur = start
        var first = true
        return AnyIterator {
            if first { first = false; return start }
            if paused { return nil }
            let t = cur.timeIntervalSinceReferenceDate
            let base = t - t.truncatingRemainder(dividingBy: 5)
            let marks = [4.6, 4.7, 4.8, 4.9, 9.6].map { base + $0 }
            let next = marks.first { $0 > t + 0.001 }!
            cur = Date(timeIntervalSinceReferenceDate: next)
            return cur
        }
    }
}

/// Глитч горит 0.45 с из каждых 3.2 с: в это время 14 кадров/с, в остальное — ни одного.
struct GlitchSchedule: TimelineSchedule {
    var paused: Bool
    func entries(from start: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var cur = start
        var first = true
        return AnyIterator {
            if first { first = false; return start }
            if paused { return nil }
            let t = cur.timeIntervalSinceReferenceDate
            let cycle = t.truncatingRemainder(dividingBy: 3.2)
            let step = cycle >= 2.75 ? min(0.07, 3.2 - cycle + 0.001) : 2.75 - cycle + 0.001
            cur = cur.addingTimeInterval(step)
            return cur
        }
    }
}

struct GlitchText: View {
    var text: String
    var size: CGFloat
    @Environment(\.liveMotion) private var live
    var body: some View {
        TimelineView(GlitchSchedule(paused: !live)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let cycle = t.truncatingRemainder(dividingBy: 3.2)
            let on = cycle > 2.75
            let seed = floor(t * 14)
            ZStack(alignment: .leading) {
                label(.white)
                if on {
                    label(CyberPal.magenta)
                        .offset(x: -4 + 8 * noise(seed))
                        .mask(Rectangle().frame(height: size * 0.4).offset(y: size * (noise(seed + 1) - 0.5)))
                    label(CyberPal.cyan)
                        .offset(x: 4 - 8 * noise(seed + 2))
                        .mask(Rectangle().frame(height: size * 0.35).offset(y: size * (noise(seed + 3) - 0.5)))
                }
            }
        }
    }
    func label(_ c: Color) -> some View {
        Text(text).font(.system(size: size, weight: .black, design: .monospaced)).tracking(3).foregroundStyle(c)
    }
}

// MARK: - Экран очистки

struct CyberCleanView: View {
    @EnvironmentObject var flow: CleanFlow
    @EnvironmentObject var status: StatusModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 1) {
                CyberCorePanel().frame(width: 270)
                CyberReactor().frame(maxWidth: .infinity)
                CyberTargets().frame(width: 330)
            }
            .background(CyberPal.line)
            Rectangle().fill(CyberPal.line).frame(height: 1)
            CyberLog().frame(height: 132)
        }
        .font(.system(size: 13, design: .monospaced))
    }
}

struct CyberCorePanel: View {
    @EnvironmentObject var status: StatusModel
    @EnvironmentObject var flow: CleanFlow
    @Environment(\.liveMotion) private var live

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.25, paused: !live)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let real = status.snapshot?.cpu?.perCore ?? []
            let cores: [Double] = (0..<max(real.count, 8)).map { i in
                let base = i < real.count ? real[i] : 15 + 20 * abs(sin(t / Double(6 + i) + Double(i)))
                let boost: Double = flow.isBusy && i < 6 ? 30 : 0
                return min(99, max(1, base + boost + (noise(floor(t * 5) + Double(i) * 7) - 0.5) * 8))
            }
            let mem = status.snapshot?.memory?.usedPercent ?? 0
            let disk = status.snapshot?.mainDisk?.usedPercent ?? 0
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    header("// CORE_MATRIX", pct(status.snapshot?.cpu?.usage))
                    ForEach(Array(cores.prefix(12).enumerated()), id: \.offset) { i, v in
                        HStack(spacing: 8) {
                            Text(i < 6 ? "P\(i + 1)" : "E\(i - 5)").foregroundStyle(CyberPal.muted).frame(width: 26, alignment: .leading)
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    Rectangle().fill(CyberPal.tab)
                                    Rectangle().fill(color(v)).frame(width: g.size.width * v / 100)
                                        .shadow(color: color(v), radius: 4)
                                }
                            }
                            .frame(height: 7)
                            Text("\(Int(v))%").foregroundStyle(.white).frame(width: 36, alignment: .trailing)
                        }
                        .frame(height: 16)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    header("// MEM", pct(mem))
                    Text(asciiBar(mem, 18)).foregroundStyle(CyberPal.cyan)
                    header("// DISK", pct(disk)).padding(.top, 6)
                    Text(asciiBar(disk, 18)).foregroundStyle(CyberPal.yellow)
                }
                Text((0..<8).map { r in
                    (0..<4).map { c in String(format: "%04X", Int(noise(floor(t * 6) * 31 + Double(r * 11 + c)) * 65535)) }.joined(separator: " ")
                }.joined(separator: "\n"))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(CyberPal.dim)
                .lineSpacing(2)
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(CyberPal.panel)
        }
    }

    func color(_ v: Double) -> Color { v > 70 ? CyberPal.magenta : (v > 45 ? CyberPal.yellow : CyberPal.cyan) }

    func header(_ t: String, _ v: String) -> some View {
        (Text(t + " ").foregroundStyle(CyberPal.magenta).bold() + Text(v).foregroundStyle(.white))
            .tracking(1)
    }
}

struct CyberReactor: View {
    @EnvironmentObject var flow: CleanFlow
    @Environment(\.liveMotion) private var live

    var ringColor: Color {
        switch flow.phase {
        case .done: return CyberPal.yellow
        case .review, .cleaning: return CyberPal.magenta
        default: return CyberPal.cyan
        }
    }
    var label: String {
        switch flow.phase {
        case .idle: return "STANDBY"
        case .scanning: return L("SCANNING")
        case .review: return flow.categories.isEmpty ? L("CLEAN") : L("TARGETS FOUND")
        case .cleaning: return L("WIPING")
        case .done: return L("SYSTEM CLEAN")
        }
    }

    var body: some View {
        let parts = sizeParts(flow.headline, english: true)
        VStack(spacing: 14) {
            Text(label).font(.system(size: 12, weight: .heavy, design: .monospaced)).tracking(4).foregroundStyle(ringColor)
            TimelineView(.animation(minimumInterval: 1 / 30, paused: !live)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                ZStack {
                    Circle().stroke(CyberPal.magenta.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [4, 10]))
                        .rotationEffect(.degrees(t * 26))
                    Circle().stroke(CyberPal.cyan.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [60, 18, 6, 18]))
                        .padding(12).rotationEffect(.degrees(-t * 40))
                    Circle().stroke(Color(hex: 0x1C1435), lineWidth: 12).padding(28)
                    Circle().trim(from: 0, to: flow.ringFraction)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 12, lineCap: .butt))
                        .rotationEffect(.degrees(-90)).padding(28)
                        .shadow(color: ringColor, radius: 8)
                        .animation(.easeInOut(duration: 0.5), value: flow.ringFraction)
                    if flow.isBusy {
                        Image(systemName: "arrowtriangle.down.fill").font(.system(size: 14)).foregroundStyle(CyberPal.yellow)
                            .offset(y: -132).rotationEffect(.degrees(t * 300))
                    }
                    Hexagon().fill(CyberPal.panel2).overlay(Hexagon().stroke(CyberPal.line)).padding(62)
                    VStack(spacing: 6) {
                        CountingText(value: flow.headline) { sizeParts($0, english: true).0 }
                            .font(.system(size: 52, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .shadow(color: ringColor, radius: 10 + 6 * sin(t * 3))
                            .animation(.easeOut(duration: 0.5), value: flow.headline)
                        Text(caption(parts.1)).font(.system(size: 13, weight: .bold, design: .monospaced)).tracking(3).foregroundStyle(ringColor)
                    }
                }
            }
            .frame(width: 320, height: 320)

            Text(bar).foregroundStyle(.white)

            Group {
                switch flow.phase {
                case .idle:
                    neonButton(L("[ SCAN ]"), CyberPal.cyan) { flow.scan() }
                case .review:
                    HStack(spacing: 10) {
                        neonButton(L("[ WIPE %@ ]", bytes(flow.selectedBytes)), CyberPal.magenta) { flow.clean() }
                            .disabled(flow.selectedBytes <= 0)
                        Button("ESC") { flow.reset() }
                            .buttonStyle(PressableStyle())
                            .padding(.horizontal, 20).frame(height: 50)
                            .overlay(Rectangle().stroke(CyberPal.line))
                            .keyboardShortcut(.cancelAction)
                    }
                case .done:
                    HStack(spacing: 10) {
                        neonButton("[ OK ]", CyberPal.yellow) { flow.reset() }
                        neonButton("[ EMPTY TRASH ]", CyberPal.cyan) { Mole.emptyTrash() }
                    }
                default:
                    Text(flow.phase == .scanning ? "> \(L(flow.currentSection))" : "> wiping…").foregroundStyle(CyberPal.muted)
                        .frame(height: 50)
                }
            }
            .transition(.opacity)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CyberPal.panel)
        .animation(.easeOut(duration: 0.2), value: flow.phase)
    }

    func caption(_ unit: String) -> String {
        switch flow.phase {
        case .done: return "\(unit) → TRASH"
        case .cleaning: return "\(unit) LEFT"
        default: return "\(unit) JUNK"
        }
    }

    var bar: String {
        let p = flow.phase == .done ? 100 : (flow.isBusy ? flow.progress * 100 : 0)
        return "[\(asciiBar(p, 20))] \(String(format: "%3d", Int(p)))%"
    }

    func neonButton(_ title: String, _ c: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .monospaced)).tracking(2)
                .foregroundStyle(CyberPal.ink)
                .padding(.horizontal, 32).frame(height: 50)
                .background(Slanted(cut: 14).fill(c))
                .shadow(color: c.opacity(0.7), radius: 14)
        }
        .buttonStyle(PressableStyle(scale: 0.96))
        .keyboardShortcut(.defaultAction)
    }
}

struct CyberTargets: View {
    @EnvironmentObject var flow: CleanFlow
    @EnvironmentObject var status: StatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("// TARGETS").foregroundStyle(CyberPal.magenta).bold().tracking(1)
            ScrollView {
                VStack(spacing: 8) {
                    if flow.categories.isEmpty {
                        ForEach(["APP_CACHE", "BROWSER_CACHE", "DEV_ARTIFACTS", "SYS_LOGS"], id: \.self) { code in
                            row(mark: "[ ]", code: code, name: L("awaiting scan"), size: "?.? GB", tag: "WAIT",
                                tagColor: CyberPal.dim, border: CyberPal.line, strike: false)
                                .opacity(0.3)
                        }
                    }
                    ForEach(flow.categories) { c in
                        Button { flow.toggle(c.id) } label: {
                            row(mark: c.locked ? "[#]" : (c.selected ? "[x]" : "[ ]"),
                                code: c.code, name: L(c.title),
                                size: c.state == .cleaned ? "0 B" : bytes(c.remaining),
                                tag: tag(c), tagColor: tagColor(c),
                                border: c.state == .cleaned ? CyberPal.yellow : (c.selected ? CyberPal.magenta : CyberPal.line),
                                strike: c.state == .cleaned)
                        }
                        .buttonStyle(PressableStyle(scale: 0.98))
                        .opacity(c.selected || flow.phase == .scanning ? 1 : 0.5)
                        .transition(.asymmetric(insertion: .offset(x: 14).combined(with: .opacity), removal: .opacity))
                    }
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                let procs = (status.snapshot?.topProcesses ?? []).prefix(3)
                    .map { "\($0.name ?? "?") \(Int($0.cpu ?? 0))%" }.joined(separator: " · ")
                (Text(L("PROCESSES ")).foregroundStyle(CyberPal.muted) + Text(procs).foregroundStyle(.white)).lineLimit(1)
                if let n = status.snapshot?.network?.first {
                    (Text(L("NETWORK ")).foregroundStyle(CyberPal.muted)
                     + Text(String(format: "↓ %.2f ↑ %.2f MB/s", n.rxRateMbs ?? 0, n.txRateMbs ?? 0)).foregroundStyle(.white))
                }
            }
            .font(.system(size: 12, design: .monospaced))
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CyberPal.panel)
    }

    func tag(_ c: CleanCategory) -> String {
        if c.locked { return "ROOT" }
        switch c.state {
        case .scanning: return "SCAN"
        case .cleaning: return "WIPING"
        case .cleaned: return "PURGED"
        case .partial: return "PARTIAL"
        case .found: return c.selected ? "FOUND" : "KEEP"
        }
    }

    func tagColor(_ c: CleanCategory) -> Color {
        if c.locked { return CyberPal.muted }
        switch c.state {
        case .cleaned: return CyberPal.yellow
        case .cleaning: return CyberPal.magenta
        case .partial: return .orange
        default: return c.selected ? CyberPal.cyan : CyberPal.muted
        }
    }

    func row(mark: String, code: String, name: String, size: String, tag: String, tagColor: Color, border: Color, strike: Bool) -> some View {
        HStack(spacing: 10) {
            Text(mark).bold().foregroundStyle(mark == "[x]" ? CyberPal.magenta : CyberPal.muted)
            VStack(alignment: .leading, spacing: 2) {
                Text(code).bold().foregroundStyle(.white).strikethrough(strike, color: CyberPal.yellow)
                Text(name).font(.system(size: 11, design: .monospaced)).foregroundStyle(CyberPal.muted).lineLimit(1)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 3) {
                Text(size).foregroundStyle(.white).monospacedDigit()
                Text(tag).font(.system(size: 10, weight: .heavy, design: .monospaced)).tracking(1)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .foregroundStyle(CyberPal.ink).background(tagColor)
            }
        }
        .padding(11)
        .background(CyberPal.panel2)
        .overlay(Rectangle().stroke(border, lineWidth: 1))
        .animation(.easeOut(duration: 0.2), value: tag)
    }
}

struct CyberLog: View {
    @EnvironmentObject var flow: CleanFlow
    @Environment(\.liveMotion) private var live

    var lines: [String] {
        if flow.logLines.isEmpty {
            return ["> mole daemon online", L("> press [ SCAN ] to find junk"), L("> nothing is deleted without confirmation")]
        }
        return Array(flow.logLines.suffix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(lines.enumerated()), id: \.offset) { i, l in
                (Text(stamp(i)).foregroundStyle(CyberPal.muted) + Text(" " + l).foregroundStyle(color(l)))
                    .lineLimit(1)
                    .id(l + "\(i)")
                    .transition(.offset(x: 10).combined(with: .opacity))
            }
            HStack(spacing: 6) {
                Text("mole@mac:~$").foregroundStyle(CyberPal.cyan)
                // Курсор мигает раз в 0.5 с — два кадра в секунду вместо repeatForever на частоте дисплея.
                TimelineView(.animation(minimumInterval: 0.5, paused: !live)) { ctx in
                    let on = Int(ctx.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
                    Rectangle().fill(CyberPal.cyan).frame(width: 9, height: 16).opacity(on ? 1 : 0)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: 0x06040E))
        .animation(.easeOut(duration: 0.15), value: flow.logLines.count)
    }

    func stamp(_ i: Int) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return "[\(f.string(from: Date()))]"
    }

    func color(_ l: String) -> Color {
        if l.hasPrefix("$") || l.hasPrefix(">") { return .white }
        if l.contains("[ OK ]") || l.contains("[DONE]") { return CyberPal.yellow }
        if l.contains("[WARN]") { return .orange }
        if l.contains("[ .. ]") { return CyberPal.magenta }
        if l.hasPrefix("➤") { return CyberPal.cyan }
        return Color(hex: 0xA8B2A4)
    }
}
