// Тема 2 — Neon: одна большая кнопка, радар, летящие частицы, волны.

import SwiftUI

enum NeonPal {
    static let bg = Color(hex: 0x0E1220)
    static let deep = Color(hex: 0x05070D)
    static let card = Color(hex: 0x161B2C)
    static let cardLine = Color(hex: 0x2B3350)
    static let track = Color(hex: 0x1B2135)
    static let inner = Color(hex: 0x131829)
    static let text = Color(hex: 0xEEF1F7)
    static let muted = Color(hex: 0xA3AAC0)
    static let dim = Color(hex: 0x7D86A2)
    static let mint = Color(hex: 0x3DDC97)
    static let ink = Color(hex: 0x062418)
}

struct NeonRoot: View {
    @Binding var section: AppSection
    @Namespace private var tabNS

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Spacer().frame(width: 70)
                HStack(spacing: 4) {
                    ForEach(AppSection.allCases) { s in
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { section = s }
                        } label: {
                            Text(s.title)
                                .font(.system(size: 14, weight: section == s ? .semibold : .medium))
                                .lineLimit(1).minimumScaleFactor(0.75)
                                .foregroundStyle(section == s ? NeonPal.text : NeonPal.muted)
                                .padding(.horizontal, 16).padding(.vertical, 9)
                                .background {
                                    if section == s {
                                        RoundedRectangle(cornerRadius: 9).fill(Color(hex: 0x232A40))
                                            .matchedGeometryEffect(id: "tab", in: tabNS)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 12).fill(NeonPal.card))
                Spacer()
                LanguagePicker(compact: true)
                ThemePicker()
            }
            .padding(.horizontal, 22).padding(.top, 14).padding(.bottom, 8)

            SectionContent(section: section, theme: .neon)
                .id(section)
                .transition(.opacity.combined(with: .offset(y: 10)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(NeonPal.bg.ignoresSafeArea())
        .foregroundStyle(NeonPal.text)
    }
}

struct NeonCleanView: View {
    @EnvironmentObject var flow: CleanFlow
    @EnvironmentObject var status: StatusModel

    var body: some View {
        HStack(alignment: .center, spacing: 56) {
            VStack(spacing: 18) {
                Text(step).font(.system(size: 13, weight: .bold)).tracking(1.3).foregroundStyle(NeonPal.dim)
                    .contentTransition(.opacity)
                NeonOrb()
                Text(title).font(.system(size: 28, weight: .bold)).id("t\(flow.phase)")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                Text(subtitle).font(.system(size: 15)).foregroundStyle(NeonPal.muted)
                    .multilineTextAlignment(.center).frame(minHeight: 44)
                action
            }
            .frame(width: 420)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: flow.phase)

            ScrollView {
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 10) {
                        if flow.categories.isEmpty {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 14).fill(NeonPal.card).frame(height: 72)
                                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(NeonPal.track))
                                    .opacity(0.4)
                            }
                        }
                        ForEach(Array(flow.categories.enumerated()), id: \.element.id) { i, c in
                            NeonCategoryCard(cat: c)
                                .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity).combined(with: .offset(y: 16)),
                                                        removal: .opacity))
                        }
                        HStack(spacing: 10) {
                            stat(L("CPU"), pct(status.snapshot?.cpu?.usage))
                            stat(L("Memory"), pct(status.snapshot?.memory?.usedPercent))
                            stat(L("Free"), bytes(status.snapshot?.diskFree))
                        }
                        .padding(.top, 8)
                    }
                    if flow.phase == .cleaning { FlyingDots() }
                }
                .padding(.vertical, 20)
            }
            .frame(maxWidth: 500)
        }
        .padding(.horizontal, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var step: String {
        switch flow.phase {
        case .idle: return L("STEP 1 OF 3")
        case .scanning: return L("SCANNING · %@%%", "\(Int(flow.progress * 100))")
        case .review: return L("STEP 2 OF 3")
        case .cleaning: return L("CLEANING · %@%%", "\(Int(flow.progress * 100))")
        case .done: return L("STEP 3 OF 3 · DONE")
        }
    }
    var title: String {
        switch flow.phase {
        case .idle: return L("Clean up your Mac?")
        case .scanning: return L("Looking for junk…")
        case .review: return flow.categories.isEmpty ? L("All clean!") : L("Found stuff to remove")
        case .cleaning: return L("Cleaning up…")
        case .done: return L("Clean!")
        }
    }
    var subtitle: String {
        switch flow.phase {
        case .idle: return flow.errorText ?? L("Tap the circle — we'll find junk and show how much space you'll get back.")
        case .scanning: return flow.currentSection.isEmpty ? L("Getting ready…") : L("Looking at: %@", L(flow.currentSection))
        case .review: return L("All safe: only caches and temp files. Into the Trash first.")
        case .cleaning: return L("Moving to Trash")
        case .done: return flow.failedCount > 0 ? L("Files skipped: %@ — in use or need a password.", "\(flow.failedCount)") : L("Your Mac is lighter. Empty the Trash to get the space back.")
        }
    }

    @ViewBuilder var action: some View {
        switch flow.phase {
        case .review:
            Button { flow.clean() } label: {
                Text(L("Clean %@", bytes(flow.selectedBytes)))
                    .font(.system(size: 18, weight: .heavy)).foregroundStyle(NeonPal.ink)
                    .frame(maxWidth: .infinity).frame(height: 60)
                    .background(RoundedRectangle(cornerRadius: 16).fill(NeonPal.mint))
                    .overlay(ShineSweep().clipShape(RoundedRectangle(cornerRadius: 16)))
            }
            .buttonStyle(PressableStyle(scale: 0.97))
            .disabled(flow.selectedBytes <= 0)
            .transition(.scale.combined(with: .opacity))
        case .done:
            HStack(spacing: 10) {
                neonSecondary(L("Done")) { flow.reset() }
                neonSecondary(L("Empty Trash")) { Mole.emptyTrash() }
            }
        case .scanning, .cleaning:
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(NeonPal.track)
                    Capsule().fill(NeonPal.mint).frame(width: g.size.width * flow.progress)
                        .animation(.linear(duration: 0.2), value: flow.progress)
                }
            }
            .frame(height: 8)
        case .idle:
            EmptyView()
        }
    }

    func neonSecondary(_ t: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(t).font(.system(size: 16, weight: .bold)).foregroundStyle(NeonPal.text)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(NeonPal.card))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(NeonPal.cardLine))
        }
        .buttonStyle(PressableStyle(scale: 0.97))
    }

    func stat(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(t).font(.system(size: 12)).foregroundStyle(Color(hex: 0x8F97B0))
            Text(v).font(.system(size: 20, weight: .bold)).monospacedDigit()
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x11162A)))
    }
}

/// Главный круг: кнопка-пульс → радар → цифра → галочка с волнами.
struct NeonOrb: View {
    @EnvironmentObject var flow: CleanFlow
    @Environment(\.liveMotion) private var live

    var body: some View {
        let parts = sizeParts(flow.headline)
        ZStack {
            if flow.phase == .idle {
                // Две волны со сдвигом 1.1 с, каждая — easeOut за 2.2 с.
                TimelineView(.animation(minimumInterval: 1 / 30, paused: !live)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    ZStack {
                        ForEach(0..<2, id: \.self) { i in
                            let p = (t + Double(i) * 1.1).truncatingRemainder(dividingBy: 2.2) / 2.2
                            let e = 1 - (1 - p) * (1 - p)
                            Circle().stroke(NeonPal.mint, lineWidth: 2)
                                .scaleEffect(0.85 + 0.45 * e)
                                .opacity(0.6 * (1 - e))
                        }
                    }
                }
            }
            if flow.phase == .done {
                WaveBurst()
            }
            Circle().stroke(NeonPal.track, lineWidth: 16)
            Circle().trim(from: 0, to: flow.ringFraction)
                .stroke(NeonPal.mint, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: NeonPal.mint.opacity(0.5), radius: 10)
                .animation(.spring(response: 0.8, dampingFraction: 0.85), value: flow.ringFraction)
            Circle().fill(NeonPal.inner).padding(42)

            if flow.phase == .scanning {
                TimelineView(.animation(minimumInterval: 1 / 60, paused: !live)) { ctx in
                    let a = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.4) / 1.4 * 360
                    ZStack {
                        Wedge(degrees: 50).fill(NeonPal.mint.opacity(0.18))
                        Rectangle().fill(NeonPal.mint).frame(width: 2, height: 106).offset(y: -53)
                    }
                    .padding(44)
                    .rotationEffect(.degrees(a))
                }
            }

            switch flow.phase {
            case .idle:
                Button { flow.scan() } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "magnifyingglass").font(.system(size: 34, weight: .bold))
                        Text(L("Scan")).font(.system(size: 22, weight: .heavy))
                    }
                    .foregroundStyle(NeonPal.ink)
                    .frame(width: 200, height: 200)
                    .background(Circle().fill(NeonPal.mint))
                }
                .buttonStyle(PressableStyle(scale: 0.93))
                .modifier(FloatBob(live: live))
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            case .done:
                VStack(spacing: 4) {
                    DrawnCheck(color: NeonPal.mint).frame(width: 96, height: 96)
                    Text(bytes(flow.freed)).font(.system(size: 22, weight: .heavy))
                }
                .transition(.scale.combined(with: .opacity))
            default:
                VStack(spacing: 4) {
                    CountingText(value: flow.headline) { sizeParts($0).0 }
                        .font(.system(size: 64, weight: .heavy))
                        .animation(.easeOut(duration: 0.6), value: flow.headline)
                    Text(flow.phase == .cleaning ? L("%@ left", parts.1) : L("%@ of junk", parts.1))
                        .font(.system(size: 18, weight: .semibold)).foregroundStyle(Color(hex: 0xC9CEDD))
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .frame(width: 300, height: 300)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: flow.phase)
    }
}

/// «Парение» кнопки: 0 → −6 pt → 0 за 3.2 с (как easeInOut 1.6 с туда-обратно).
struct FloatBob: ViewModifier {
    var live: Bool
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !live)) { ctx in
            let k = 0.5 - 0.5 * cos(ctx.date.timeIntervalSinceReferenceDate * .pi / 1.6)
            content.offset(y: -6 * k)
        }
    }
}

struct Wedge: Shape {
    var degrees: Double
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        p.move(to: c)
        p.addArc(center: c, radius: min(r.width, r.height) / 2,
                 startAngle: .degrees(-90), endAngle: .degrees(-90 + degrees), clockwise: false)
        p.closeSubpath()
        return p
    }
}

struct DrawnCheck: View {
    var color: Color
    @State private var t: CGFloat = 0
    var body: some View {
        Checkmark().trim(from: 0, to: t)
            .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
            .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15)) { t = 1 } }
    }
}

struct WaveBurst: View {
    @State private var go = false
    var body: some View {
        ZStack {
            Circle().stroke(NeonPal.mint, lineWidth: 3).scaleEffect(go ? 1.6 : 0.6).opacity(go ? 0 : 0.9)
            Circle().stroke(Color(hex: 0x7C9CFF), lineWidth: 2).scaleEffect(go ? 1.6 : 0.6).opacity(go ? 0 : 0.9)
                .animation(.easeOut(duration: 1.2).delay(0.25), value: go)
        }
        .animation(.easeOut(duration: 1.2), value: go)
        .onAppear { go = true }
        .allowsHitTesting(false)
    }
}

struct ShineSweep: View {
    @Environment(\.liveMotion) private var live
    var body: some View {
        // Цикл 2 с: 0.4 с пауза за левым краем, затем easeInOut проход за 1.6 с.
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !live)) { ctx in
            let c = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.0)
            let p = max(0, c - 0.4) / 1.6
            let x = -1 + 2 * (p < 0.5 ? 2 * p * p : 1 - 2 * (1 - p) * (1 - p))
            GeometryReader { g in
                Rectangle().fill(.white.opacity(0.45))
                    .frame(width: g.size.width * 0.28)
                    .rotationEffect(.degrees(20))
                    .offset(x: x * g.size.width * 1.6)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Цветные точки улетают из списка влево — в главный круг.
struct FlyingDots: View {
    @Environment(\.liveMotion) private var live
    private let colors: [Color] = [Color(hex: 0xB9A7FF), Color(hex: 0x7CC8FF), Color(hex: 0xFFC46B), NeonPal.mint]
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: !live)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .topLeading) {
                ForEach(0..<4, id: \.self) { i in
                    let ph = ((t / 1.2) + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
                    let ease = ph * ph
                    Circle().fill(colors[i]).frame(width: 10, height: 10)
                        .scaleEffect(1 - 0.7 * ph)
                        .opacity(ph < 0.15 ? ph / 0.15 : 1 - ph)
                        .offset(x: 30 - 330 * ease, y: 40 + Double(i) * 82 - Double(i) * 50 * ease)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct NeonCategoryCard: View {
    @EnvironmentObject var flow: CleanFlow
    var cat: CleanCategory
    var body: some View {
        let cleaned = cat.state == .cleaned
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(cat.selected ? Color.clear : Color(hex: 0x3A4260), lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(cat.selected ? NeonPal.mint : .clear))
                Checkmark().trim(from: 0, to: cat.selected ? 1 : 0)
                    .stroke(NeonPal.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)).padding(5)
            }
            .frame(width: 24, height: 24)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: cat.selected)

            Image(systemName: cat.locked ? "lock.fill" : cat.symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(cat.tint)
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 10).fill(cat.tint.opacity(0.18)))
            VStack(alignment: .leading, spacing: 2) {
                Text(L(cat.title)).font(.system(size: 15, weight: .semibold)).strikethrough(cleaned, color: NeonPal.mint)
                Text(L(cat.subtitle)).font(.system(size: 13)).foregroundStyle(Color(hex: 0x8F97B0)).lineLimit(1)
            }
            Spacer(minLength: 8)
            Group {
                if cleaned {
                    Text(L("cleaned")).foregroundStyle(NeonPal.mint)
                } else if cat.state == .scanning && cat.bytes == 0 {
                    Text("…").foregroundStyle(NeonPal.dim)
                } else {
                    CountingText(value: cat.remaining) { bytes($0) }
                        .animation(.easeOut(duration: 0.4), value: cat.remaining)
                }
            }
            .font(.system(size: 15, weight: .bold))
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 14).fill(cleaned ? Color(hex: 0x10261F) : NeonPal.card))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(cleaned ? NeonPal.mint : NeonPal.cardLine))
        .opacity(cat.selected || flow.phase == .scanning ? 1 : 0.5)
        .scaleEffect(cat.state == .cleaning ? 1.02 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: cat.state == .cleaning)
        .contentShape(Rectangle())
        .onTapGesture { flow.toggle(cat.id) }
    }
}
