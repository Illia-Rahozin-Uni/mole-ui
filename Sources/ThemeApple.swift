// Тема 1 — Apple (Liquid Glass): стекло, плавающие обои, пружинные анимации.

import SwiftUI

struct AppleRoot: View {
    @Binding var section: AppSection
    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: Binding(get: { section }, set: { if let v = $0 { section = v } })) { s in
                Label(s.title, systemImage: s.icon).tag(s)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210)
            .safeAreaInset(edge: .bottom) { ConnectedBadge().padding(12) }
        } detail: {
            ZStack {
                AppleWallpaper()
                SectionContent(section: section, theme: .apple)
                    .id(section)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: section)
        }
    }
}

struct ConnectedBadge: View {
    @Environment(\.liveMotion) private var live
    var body: some View {
        HStack(spacing: 8) {
            TimelineView(.animation(minimumInterval: 1 / 20, paused: !live)) { ctx in
                // Пульс 0.9 → 1.25 → 0.9 за 2.4 с (как easeInOut 1.2 с туда-обратно).
                let k = 0.5 - 0.5 * cos(ctx.date.timeIntervalSinceReferenceDate * .pi / 1.2)
                Circle().fill(Color.green).frame(width: 8, height: 8)
                    .scaleEffect(0.9 + 0.35 * k)
            }
            .frame(width: 10, height: 10)
            Text(L("Mole connected")).font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }
}

/// Мягкие цветные пятна, медленно плавающие за стеклом.
struct AppleWallpaper: View {
    @Environment(\.liveMotion) private var live
    var body: some View {
        // Пятна плывут медленно (≤15 px/с) — 15 кадров хватает с запасом, а размытие 80 px
        // и стекло поверх него пересчитываются вдвое реже.
        TimelineView(.animation(minimumInterval: 1 / 15, paused: !live)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            GeometryReader { g in
                ZStack {
                    Circle().fill(Color(hex: 0x9CC3FF)).frame(width: 520, height: 520)
                        .offset(x: -g.size.width * 0.3 + 110 * sin(t / 9), y: -g.size.height * 0.3 + 60 * cos(t / 7))
                    Circle().fill(Color(hex: 0xD7B8FF)).frame(width: 480, height: 480)
                        .offset(x: g.size.width * 0.32 - 130 * sin(t / 11), y: -g.size.height * 0.05 + 50 * sin(t / 8))
                    Circle().fill(Color(hex: 0x9FF0E1)).frame(width: 520, height: 520)
                        .offset(x: 60 * cos(t / 8), y: g.size.height * 0.4 - 80 * sin(t / 10))
                }
                .frame(width: g.size.width, height: g.size.height)
                .blur(radius: 80)
                .opacity(0.75)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.55), lineWidth: 1))
    }
}

struct AppleCleanView: View {
    @EnvironmentObject var flow: CleanFlow
    @EnvironmentObject var status: StatusModel
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L("Clean")).font(.system(size: 30, weight: .bold))
                        Text(status.snapshot?.diskFree.map { L("%@ free", bytes($0)) } ?? "Mac")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    LanguagePicker(compact: true)
                    ThemePicker()
                }
                .rise(appeared, delay: 0)

                GlassCard(padding: 26) {
                    HStack(spacing: 30) {
                        AppleRing()
                        ApplePhasePanel()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .rise(appeared, delay: 0.08)

                HStack(alignment: .top, spacing: 18) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L("What we found")).font(.headline)
                            if flow.categories.isEmpty {
                                ForEach(0..<3, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.06))
                                        .frame(height: 46)
                                        .shimmer(flow.phase == .scanning || flow.phase == .idle)
                                        .opacity(1 - Double(i) * 0.2)
                                }
                            }
                            ForEach(flow.categories) { c in
                                AppleCategoryRow(cat: c)
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                            removal: .opacity))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
                    .rise(appeared, delay: 0.16)

                    VStack(spacing: 18) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack { Text(L("CPU")).foregroundStyle(.secondary); Spacer(); Text(pct(status.snapshot?.cpu?.usage)).bold().monospacedDigit() }
                                Sparkline(values: status.cpuHistory, color: .accentColor)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack { Text(L("Memory")).foregroundStyle(.secondary); Spacer(); Text(pct(status.snapshot?.memory?.usedPercent)).bold().monospacedDigit() }
                                Sparkline(values: status.memHistory, color: .purple)
                            }
                        }
                    }
                    .frame(width: 300)
                    .rise(appeared, delay: 0.24)
                }
            }
            .padding(28)
        }
        .onAppear { appeared = true }
    }
}

extension View {
    /// Карточки мягко всплывают при появлении.
    func rise(_ on: Bool, delay: Double) -> some View {
        modifier(Rise(on: on, delay: delay))
    }
}

/// Без движения («Уменьшить движение», фон) карточки просто на месте — без всплытия.
struct Rise: ViewModifier {
    var on: Bool
    var delay: Double
    @Environment(\.liveMotion) private var live
    func body(content: Content) -> some View {
        let shown = on || !live
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 18)
            .scaleEffect(shown ? 1 : 0.98)
            .animation(live ? .spring(response: 0.7, dampingFraction: 0.8).delay(delay) : nil, value: shown)
    }
}

struct AppleRing: View {
    @EnvironmentObject var flow: CleanFlow
    @Environment(\.liveMotion) private var live
    var body: some View {
        let done = flow.phase == .done
        let color: Color = done ? .green : .accentColor
        let parts = sizeParts(flow.headline)
        ZStack {
            Circle().stroke(Color.primary.opacity(0.08), lineWidth: 14)
            Circle().trim(from: 0, to: flow.ringFraction)
                .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.9, dampingFraction: 0.8), value: flow.ringFraction)
            if flow.phase == .scanning {
                TimelineView(.animation(minimumInterval: 1 / 60, paused: !live)) { ctx in
                    let a = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.1) / 1.1 * 360
                    Circle().trim(from: 0, to: 0.08)
                        .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(a - 90))
                }
            }
            if done { BurstView() }
            VStack(spacing: 2) {
                CountingText(value: flow.headline) { sizeParts($0).0 }
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .animation(.easeOut(duration: 0.7), value: flow.headline)
                Text(done ? L("%@ in Trash", parts.1) : parts.1).font(.callout).foregroundStyle(.secondary)
            }
        }
        .frame(width: 180, height: 180)
    }
}

struct BurstView: View {
    @State private var go = false
    private let colors: [Color] = [.green, .blue, .orange, .purple, .pink, .yellow, .mint, .cyan, .green, .purple]
    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                Circle().fill(colors[i]).frame(width: i % 2 == 0 ? 9 : 6, height: i % 2 == 0 ? 9 : 6)
                    .offset(y: go ? -125 : 0)
                    .rotationEffect(.degrees(Double(i) * 36))
                    .opacity(go ? 0 : 1)
                    .scaleEffect(go ? 0.3 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 1.1)) { go = true } }
        .allowsHitTesting(false)
    }
}

struct ApplePhasePanel: View {
    @EnvironmentObject var flow: CleanFlow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 24, weight: .bold))
            Text(subtitle).font(.system(size: 15)).foregroundStyle(.secondary)
                .shimmer(flow.isBusy)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                switch flow.phase {
                case .idle:
                    pill(L("Scan"), color: .accentColor) { flow.scan() }
                case .scanning, .cleaning:
                    ProgressView(value: flow.progress).frame(width: 220)
                    Text("\(Int(flow.progress * 100))%").monospacedDigit().foregroundStyle(.secondary)
                case .review:
                    pill(L("Clean %@", bytes(flow.selectedBytes)), color: .accentColor) { flow.clean() }
                        .disabled(flow.selectedBytes <= 0)
                    Button(L("Cancel")) { flow.reset() }.buttonStyle(.bordered).controlSize(.large)
                case .done:
                    pill(L("Great"), color: .green) { flow.reset() }
                    Button(L("Empty Trash")) { Mole.emptyTrash() }.buttonStyle(.bordered).controlSize(.large)
                }
            }
            .padding(.top, 6)
        }
        .id(flow.phase)
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: flow.phase)
    }

    var title: String {
        switch flow.phase {
        case .idle: return L("Ready to check")
        case .scanning: return L("Looking for junk…")
        case .review: return flow.categories.isEmpty ? L("All clean") : L("You can free up %@", bytes(flow.selectedBytes))
        case .cleaning: return L("Cleaning up…")
        case .done: return L("Done! %@ in the Trash", bytes(flow.freed))
        }
    }

    var subtitle: String {
        switch flow.phase {
        case .idle: return flow.errorText ?? L("Mole will look for caches, logs and old files. Nothing is deleted until you say yes.")
        case .scanning: return flow.currentSection.isEmpty ? L("Getting ready…") : L("Looking at: %@", L(flow.currentSection))
        case .review: return L("Uncheck what you want to keep. Everything goes to the Trash.")
        case .cleaning: return L("Moving to Trash — no need to wait")
        case .done:
            return flow.failedCount > 0
                ? L("Some files (%@) were skipped — they're in use or need a password.", "\(flow.failedCount)")
                : L("Space is freed once you empty the Trash.")
        }
    }

    func pill(_ text: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                .padding(.horizontal, 24).frame(height: 44)
                .background(Capsule().fill(color))
        }
        .buttonStyle(PressableStyle())
    }
}

struct AppleCategoryRow: View {
    @EnvironmentObject var flow: CleanFlow
    var cat: CleanCategory

    var body: some View {
        let cleaned = cat.state == .cleaned
        HStack(spacing: 12) {
            Button { flow.toggle(cat.id) } label: {
                ZStack {
                    Circle().strokeBorder(cat.selected ? Color.clear : Color.secondary.opacity(0.5), lineWidth: 1.5)
                        .background(Circle().fill(cat.selected ? (cleaned ? Color.green : Color.accentColor) : .clear))
                    Checkmark().trim(from: 0, to: cat.selected ? 1 : 0)
                        .stroke(.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .padding(5)
                }
                .frame(width: 24, height: 24)
            }
            .buttonStyle(PressableStyle(scale: 0.85))
            .disabled(cat.locked || flow.phase != .review)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: cat.selected)

            Image(systemName: cat.locked ? "lock.fill" : cat.symbol)
                .foregroundStyle(cat.tint)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 9).fill(cat.tint.opacity(0.15)))

            VStack(alignment: .leading, spacing: 3) {
                Text(L(cat.title)).font(.system(size: 14, weight: .semibold))
                Text(L(cat.subtitle)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.07))
                        Capsule().fill(cat.selected ? Color.accentColor : Color.secondary.opacity(0.4))
                            .frame(width: g.size.width * (cat.state == .scanning ? 1 : cat.remainingFraction))
                    }
                }
                .frame(height: 4)
                .animation(.linear(duration: 0.2), value: cat.removed)
            }
            Spacer(minLength: 8)
            if cleaned {
                Text(L("cleaned")).font(.system(size: 14, weight: .semibold)).foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else if cat.state == .scanning && cat.bytes == 0 {
                ProgressView().controlSize(.small)
            } else {
                CountingText(value: cat.remaining) { bytes($0) }
                    .font(.system(size: 14, weight: .semibold))
                    .animation(.easeOut(duration: 0.4), value: cat.remaining)
            }
        }
        .padding(.vertical, 7)
        .opacity(cat.selected || flow.phase == .scanning ? 1 : 0.5)
        .contentShape(Rectangle())
        .onTapGesture { flow.toggle(cat.id) }
    }
}
