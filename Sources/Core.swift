// Mole UI — ядро: запуск mo, модели данных, живой статус и сценарий очистки.
// Темы (Apple / Neon / Cyber) только рисуют то, что здесь лежит.

import SwiftUI
import AppKit

// MARK: - Запуск mo

enum Mole {
    static var searchDirs: [String] {
        let home = NSHomeDirectory()
        return ["\(home)/.homebrew/bin", "/opt/homebrew/bin", "/usr/local/bin",
                "\(home)/.local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
    }

    static var envPath: String {
        (searchDirs + [ProcessInfo.processInfo.environment["PATH"] ?? ""]).joined(separator: ":")
    }

    nonisolated(unsafe) private static var cached: String?

    static var binary: String? {
        if let c = cached, FileManager.default.isExecutableFile(atPath: c) { return c }
        cached = locate()
        return cached
    }

    static func resetCache() { cached = nil }

    private static func locate() -> String? {
        let fm = FileManager.default
        for dir in searchDirs {
            let p = dir + "/mo"
            if fm.isExecutableFile(atPath: p) { return p }
        }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/zsh")
        p.arguments = ["-lc", "command -v mo"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        p.standardInput = FileHandle.nullDevice
        do { try p.run() } catch { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        let out = (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return out.hasPrefix("/") ? out : nil
    }

    static func makeProcess(_ args: [String]) -> Process? {
        guard let bin = binary else { return nil }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: bin)
        p.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = envPath
        env["NO_COLOR"] = "1"
        env["TERM"] = "dumb"
        p.environment = env
        p.standardInput = FileHandle.nullDevice
        return p
    }

    /// Запускает mo и возвращает stdout целиком.
    static func run(_ args: [String]) async -> Data? {
        await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let p = makeProcess(args) else { cont.resume(returning: nil); return }
                let pipe = Pipe()
                p.standardOutput = pipe
                p.standardError = FileHandle.nullDevice
                do { try p.run() } catch { cont.resume(returning: nil); return }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                p.waitUntilExit()
                cont.resume(returning: data)
            }
        }
    }

    /// Открывает команду в Терминале — для всего, что требует пароль или живой ввод.
    static func openInTerminal(_ args: [String]) {
        guard let bin = binary else { return }
        openInTerminal(command: ([bin] + args).map(shellQuote).joined(separator: " "))
    }

    static func openInTerminal(command: String) {
        let script = """
        #!/bin/zsh -l
        clear
        \(command)
        echo
        read -k1 "?\(L("Done. Press any key to close this window…"))"
        exit

        """
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mole-ui-\(UUID().uuidString.prefix(8)).command")
        do {
            try script.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
            NSWorkspace.shared.open(url)
        } catch {
            NSSound.beep()
        }
    }

    static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    static func stripANSI(_ s: String) -> String {
        s.replacingOccurrences(of: "\u{1B}\\[[0-9;?]*[ -/]*[@-~]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\u{1B}\\][^\u{07}]*\u{07}", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    static func emptyTrash() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", "tell application \"Finder\" to empty the trash"]
        try? p.run()
    }
}

// MARK: - Форматирование

/// Размер в выбранном языке интерфейса: «1.23 GB» / «1,23 ГБ». Десятичные единицы, как у Mole и Finder.
func bytes(_ v: Double?) -> String {
    guard let v, v.isFinite, v >= 0 else { return "—" }
    let (value, unit, digits): (Double, String, Int) =
        v >= 1e12 ? (v / 1e12, "TB", 2) : v >= 1e9 ? (v / 1e9, "GB", 2) :
        v >= 1e6 ? (v / 1e6, "MB", 1) : v >= 1e3 ? (v / 1e3, "KB", 0) : (v, "B", 0)
    return localizedNumber(value, digits: digits) + " " + L(unit)
}

func localizedNumber(_ v: Double, digits: Int) -> String {
    String(format: "%.\(digits)f", v).replacingOccurrences(of: ".", with: L10n.decimalSeparator)
}

func pct(_ v: Double?) -> String {
    guard let v, v.isFinite else { return "—" }
    return String(format: "%.0f%%", v)
}

/// Число и единица для крупных цифр: («8.4», «GB»). `english` — для темы Cyber: точка и латинские единицы всегда.
func sizeParts(_ b: Double, english: Bool = false) -> (String, String) {
    let v = max(0, b)
    let (num, unit): (String, String) =
        v >= 1e9 ? (String(format: "%.1f", v / 1e9), "GB") :
        v >= 1e6 ? (String(format: "%.0f", v / 1e6), "MB") :
        v >= 1e3 ? (String(format: "%.0f", v / 1e3), "KB") : ("0", "GB")
    if english { return (num, unit) }
    return (num.replacingOccurrences(of: ".", with: L10n.decimalSeparator), L(unit))
}

/// Парсит размеры в стиле Mole: 1.23GB, 456.7MB, 12KB, 0B.
func parseMoleSize(_ s: Substring) -> Double? {
    let str = String(s)
    guard let r = str.range(of: "([0-9]+(?:\\.[0-9]+)?)\\s?(TB|GB|MB|KB|B)\\b", options: .regularExpression) else { return nil }
    let token = String(str[r])
    let num = Double(token.filter { "0123456789.".contains($0) }) ?? 0
    if token.hasSuffix("TB") { return num * 1e12 }
    if token.hasSuffix("GB") { return num * 1e9 }
    if token.hasSuffix("MB") { return num * 1e6 }
    if token.hasSuffix("KB") { return num * 1e3 }
    return num
}

// MARK: - Модели JSON

struct StatusSnapshot: Decodable {
    var host: String?
    var uptime: String?
    var hardware: Hardware?
    var healthScore: Double?
    var healthScoreMsg: String?
    var cpu: CPU?
    var memory: Memory?
    var disks: [Disk]?
    var trashSize: Double?
    var network: [Net]?
    var batteries: [Battery]?
    var thermal: Thermal?
    var topProcesses: [Proc]?

    struct Hardware: Decodable {
        var model: String?; var cpuModel: String?; var totalRam: String?
        var diskSize: String?; var osVersion: String?
    }
    struct CPU: Decodable {
        var usage: Double?; var perCore: [Double]?; var load1: Double?
        var coreCount: Double?; var pCoreCount: Double?; var eCoreCount: Double?
    }
    struct Memory: Decodable {
        var used: Double?; var total: Double?; var usedPercent: Double?
        var swapUsed: Double?; var pressure: String?
    }
    struct Disk: Decodable {
        var mount: String?; var used: Double?; var total: Double?
        var usedPercent: Double?; var external: Bool?
    }
    struct Net: Decodable { var name: String?; var rxRateMbs: Double?; var txRateMbs: Double?; var ip: String? }
    struct Battery: Decodable {
        var percent: Double?; var status: String?; var timeLeft: String?
        var health: String?; var cycleCount: Double?; var capacity: Double?
    }
    struct Thermal: Decodable { var cpuTemp: Double?; var gpuTemp: Double?; var fanSpeed: Double?; var systemPower: Double? }
    struct Proc: Decodable, Identifiable {
        var pid: Double?; var name: String?; var cpu: Double?; var memory: Double?; var memoryBytes: Double?
        var id: String { "\(Int(pid ?? 0))-\(name ?? "")" }
    }

    var mainDisk: Disk? {
        disks?.first(where: { $0.mount == "/" }) ?? disks?.first(where: { $0.external != true }) ?? disks?.first
    }
    var diskFree: Double? {
        guard let d = mainDisk, let t = d.total, let u = d.used else { return nil }
        return t - u
    }
}

struct AnalyzeResult: Decodable {
    var path: String?
    var entries: [Entry]?
    var largeFiles: [LargeFile]?
    var totalSize: Double?

    struct Entry: Decodable, Identifiable, Hashable {
        var name: String?; var path: String?; var size: Double?; var isDir: Bool?; var cleanable: Bool?
        var id: String { path ?? name ?? UUID().uuidString }
    }
    struct LargeFile: Decodable, Identifiable, Hashable {
        var name: String?; var path: String?; var size: Double?
        var id: String { path ?? name ?? UUID().uuidString }
    }
}

struct AppInfo: Decodable, Identifiable, Hashable {
    var name: String?
    var bundleId: String?
    var source: String?
    var uninstallName: String?
    var path: String?
    var size: String?
    var id: String { path ?? name ?? UUID().uuidString }
}

struct HistoryResult: Decodable {
    var sessions: [Session]?
    struct Session: Decodable, Identifiable {
        var command: String?; var runId: String?; var startedAt: String?
        var items: Double?; var size: String?
        var actions: Actions?
        var id: String { (runId ?? "") + (startedAt ?? "") + (command ?? "") }
    }
    struct Actions: Decodable { var removed: Double?; var trashed: Double? }
}

// MARK: - Живой статус (mo status --watch)

final class StatusModel: ObservableObject {
    @Published var snapshot: StatusSnapshot?
    @Published var cpuHistory: [Double] = Array(repeating: 0, count: 40)
    @Published var memHistory: [Double] = Array(repeating: 0, count: 40)
    @Published var error: String?

    private var process: Process?
    private var buffer = Data()
    private var stopped = false

    func start() {
        guard process == nil else { return }
        stopped = false
        guard let p = Mole.makeProcess(["status", "--watch", "--interval", "2s"]) else {
            error = L("Mole not found")
            return
        }
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        pipe.fileHandleForReading.readabilityHandler = { [weak self] h in
            let chunk = h.availableData
            if chunk.isEmpty { h.readabilityHandler = nil; return }
            self?.consume(chunk)
        }
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                guard let self, !self.stopped else { return }
                self.process = nil
                self.start()
            }
        }
        do {
            try p.run()
            process = p
        } catch {
            self.error = L("Couldn't start mo status")
        }
    }

    func stop() {
        stopped = true
        process?.terminate()
        process = nil
    }

    private func consume(_ chunk: Data) {
        buffer.append(chunk)
        while let nl = buffer.firstIndex(of: 0x0A) {
            let line = buffer.subdata(in: buffer.startIndex..<nl)
            buffer.removeSubrange(buffer.startIndex...nl)
            guard !line.isEmpty,
                  let snap = try? Mole.decoder.decode(StatusSnapshot.self, from: line) else { continue }
            DispatchQueue.main.async {
                self.snapshot = snap
                self.error = nil
                self.cpuHistory = Array((self.cpuHistory + [snap.cpu?.usage ?? 0]).suffix(40))
                self.memHistory = Array((self.memHistory + [snap.memory?.usedPercent ?? 0]).suffix(40))
            }
        }
    }
}

// MARK: - Сценарий очистки (общий для всех тем)

struct CleanItem: Hashable {
    let path: String
    let bytes: Double
}

struct CleanCategory: Identifiable {
    enum State { case scanning, found, cleaning, cleaned, partial }

    let id: String            // имя раздела у Mole, например "App caches"
    var title: String         // английский ключ локализации — темы показывают L(title)
    var subtitle: String      // тоже ключ
    var symbol: String
    var tint: Color
    var code: String          // для темы Cyber: APP_CACHE
    var items: [CleanItem] = []
    var bytes: Double = 0
    var selected = true
    var locked = false        // нужен пароль администратора — только через Терминал
    var removed: Double = 0
    var failed = 0
    var state: State = .scanning

    var remaining: Double { max(0, bytes - removed) }
    var remainingFraction: Double { bytes > 0 ? remaining / bytes : 0 }
}

@MainActor
final class CleanFlow: ObservableObject {
    enum Phase: Hashable { case idle, scanning, review, cleaning, done }

    @Published var phase: Phase = .idle
    @Published var progress: Double = 0
    @Published var categories: [CleanCategory] = []
    @Published var logLines: [String] = []
    @Published var currentSection = ""
    @Published var freed: Double = 0
    @Published var failedCount = 0
    @Published var errorText: String?

    private var process: Process?
    private var buffer = ""
    private var scanStarted = Date()
    private var tick: Timer?
    private var sectionIndex = 0

    static let sectionOrder = ["External volume", "System", "User essentials", "App caches", "Browsers",
                               "Cloud & Office", "Developer tools", "Apps & utilities", "Virtualization",
                               "Application Support", "App leftovers", "Apple Silicon updates", "Device backups & firmware",
                               "Time Machine", "Large files", "Project artifacts"]

    static let offByDefault: Set<String> = ["Large files", "Device backups & firmware", "Time Machine", "System", "External volume"]

    static func meta(_ id: String) -> (String, String, String, Color, String) {
        switch id {
        case "User essentials": return ("Logs & temp files", "Session trash, logs, temp", "doc.text", .orange, "SYS_LOGS")
        case "App caches": return ("App caches", "Spotify, Slack, Telegram and more", "square.stack.3d.up", .blue, "APP_CACHE")
        case "Browsers": return ("Browsers", "Chrome, Safari, Arc caches…", "globe", .cyan, "BROWSER_CACHE")
        case "Cloud & Office": return ("Cloud & Office", "Dropbox, Google Drive, Office", "icloud", .teal, "CLOUD_OFFICE")
        case "Developer tools": return ("Developer tools", "Xcode, npm, pip, Homebrew", "hammer", .purple, "DEV_TOOLS")
        case "Apps & utilities": return ("Apps & utilities", "Third-party app caches", "app.badge", .indigo, "APP_UTILS")
        case "Virtualization": return ("Virtualization", "Docker, OrbStack, VMs", "shippingbox", .mint, "VIRT")
        case "Application Support": return ("App data", "Leftovers in Application Support", "folder", .brown, "APP_SUPPORT")
        case "App leftovers": return ("Uninstalled app leftovers", "From apps already removed", "trash", .pink, "LEFTOVERS")
        case "Apple Silicon updates": return ("Apple Silicon updates", "Downloaded updates & firmware", "cpu", .gray, "AS_UPDATES")
        case "Device backups & firmware": return ("Backups & firmware", "iPhone/iPad, updates", "iphone", .gray, "BACKUPS")
        case "Time Machine": return ("Time Machine", "Local snapshots", "clock.arrow.circlepath", .gray, "TIMEMACHINE")
        case "Large files": return ("Large files", "Review before deleting", "doc.zipper", .red, "LARGE_FILES")
        case "Project artifacts": return ("Developer junk", "node_modules, build, dist", "curlybraces", .purple, "DEV_ARTIFACTS")
        case "System": return ("System caches", "Needs password — use Terminal", "lock", .gray, "SYSTEM")
        case "External volume": return ("External drive", "Service files", "externaldrive", .gray, "EXT_VOLUME")
        default: return (id, "", "sparkles", .gray, id.uppercased().replacingOccurrences(of: " ", with: "_"))
        }
    }

    var selectedBytes: Double { categories.filter { $0.selected }.reduce(0) { $0 + $1.bytes } }
    var foundBytes: Double { categories.reduce(0) { $0 + $1.bytes } }
    var remainingSelected: Double { categories.filter { $0.selected }.reduce(0) { $0 + $1.remaining } }

    /// Главная цифра на кольце в каждой фазе.
    var headline: Double {
        switch phase {
        case .idle: return 0
        case .scanning: return foundBytes
        case .review: return selectedBytes
        case .cleaning: return remainingSelected
        case .done: return freed
        }
    }

    /// Насколько заполнено кольцо (0…1).
    var ringFraction: Double {
        switch phase {
        case .idle: return 0
        case .scanning: return progress
        case .review, .done: return 1
        case .cleaning: return 1 - progress
        }
    }

    var isBusy: Bool { phase == .scanning || phase == .cleaning }

    // MARK: Скан

    func scan() {
        guard !isBusy else { return }
        guard let p = Mole.makeProcess(["clean", "--dry-run"]) else {
            errorText = L("Mole not found")
            return
        }
        categories = []
        logLines = ["$ mo clean --dry-run"]
        progress = 0
        freed = 0
        failedCount = 0
        errorText = nil
        sectionIndex = 0
        currentSection = ""
        buffer = ""
        scanStarted = Date()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { phase = .scanning }

        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { [weak self] h in
            let d = h.availableData
            if d.isEmpty { h.readabilityHandler = nil; return }
            let s = Mole.stripANSI(String(decoding: d, as: UTF8.self))
            Task { @MainActor in self?.consume(s) }
        }
        p.terminationHandler = { [weak self] proc in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                // После «Отмена» + нового скана сюда может прийти завершение старого процесса.
                guard let self, self.process === proc else { return }
                self.finishScan(exitCode: proc.terminationStatus)
            }
        }
        do {
            try p.run()
            process = p
        } catch {
            errorText = L("Couldn't start mo clean")
            phase = .idle
            return
        }
        tick?.invalidate()
        tick = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.advanceTimeProgress() }
        }
    }

    func cancel() {
        process?.terminate()
        process = nil
        tick?.invalidate()
        withAnimation(.spring) { phase = .idle; progress = 0; categories = [] }
    }

    private func advanceTimeProgress() {
        guard phase == .scanning else { return }
        let t = Date().timeIntervalSince(scanStarted)
        let byTime = 0.9 * (1 - exp(-t / 35))
        let bySection = Double(sectionIndex) / Double(Self.sectionOrder.count) * 0.95
        let target = max(byTime, bySection)
        if target > progress { progress = min(0.97, target) }
    }

    private func consume(_ chunk: String) {
        buffer += chunk
        while let nl = buffer.firstIndex(of: "\n") {
            let line = String(buffer[..<nl]).trimmingCharacters(in: .whitespaces)
            buffer.removeSubrange(...nl)
            guard !line.isEmpty else { continue }
            logLines.append(line)
            if logLines.count > 300 { logLines.removeFirst(logLines.count - 300) }

            if let sec = Self.sectionOrder.first(where: { line == $0 || line.hasSuffix(" " + $0) }) {
                currentSection = Self.meta(sec).0
                if let i = Self.sectionOrder.firstIndex(of: sec) { sectionIndex = max(sectionIndex, i + 1) }
                if !categories.contains(where: { $0.id == sec }) {
                    let m = Self.meta(sec)
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        categories.append(CleanCategory(id: sec, title: m.0, subtitle: m.1, symbol: m.2, tint: m.3, code: m.4,
                                                        selected: !Self.offByDefault.contains(sec)))
                    }
                }
            } else if line.hasPrefix("○"), let size = parseMoleSize(Substring(line)), size > 0,
                      let idx = categories.indices.last {
                // Предварительная сумма по ходу скана — точные цифры придут из clean-list.txt.
                // Считаем только строки «○ … would clean»: «⊙» — ручная проверка (Large files, OrbStack),
                // «◎» — пропущено, вложенные пути — детализация уже посчитанной строки.
                withAnimation(.easeOut(duration: 0.4)) { categories[idx].bytes += size }
            }
        }
    }

    private func finishScan(exitCode: Int32) {
        tick?.invalidate()
        process = nil
        guard phase == .scanning else { return }
        // clean-list.txt переживает запуски: если этот скан его не переписал (mo упал),
        // в нём список из прошлого раза — по нему чистить нельзя.
        let listDate = (try? FileManager.default.attributesOfItem(atPath: Self.cleanListPath)[.modificationDate]) as? Date
        guard exitCode == 0, let listDate, listDate >= scanStarted.addingTimeInterval(-1) else {
            errorText = L("Scan didn't finish (code %@) — try again or run mo clean in Terminal", "\(exitCode)")
            logLines.append(L("[FAIL] mo clean --dry-run, code %@", "\(exitCode)"))
            withAnimation(.spring) { categories = []; progress = 0; phase = .idle }
            return
        }
        let parsed = Self.parseCleanList()
        var result: [CleanCategory] = []
        var skippedUnsafe = 0
        for (sec, allItems) in parsed {
            let m = Self.meta(sec)
            guard !allItems.isEmpty else { continue }
            let safeItems = allItems.filter { Self.isSafeToTrash($0.path) }
            var c = CleanCategory(id: sec, title: m.0, subtitle: m.1, symbol: m.2, tint: m.3, code: m.4)
            if safeItems.isEmpty {
                // Целиком вне $HOME — показываем, но выбрать нельзя.
                c.items = allItems
                c.locked = true
                c.subtitle = "Needs password — “Full clean with Mole”"
            } else {
                // Пути вне $HOME (например, старые версии Chrome в /Applications) сами не трогаем —
                // и не считаем их в размер, чтобы обещанное совпадало с тем, что уйдёт в Корзину.
                c.items = safeItems
                skippedUnsafe += allItems.count - safeItems.count
            }
            c.bytes = c.items.reduce(0) { $0 + $1.bytes }
            c.selected = !c.locked && !Self.offByDefault.contains(sec)
            c.state = .found
            result.append(c)
        }
        if skippedUnsafe > 0 {
            logLines.append(L("Skipped paths outside your home folder: %@ — only mo clean can clean them", "\(skippedUnsafe)"))
        }
        result.sort { $0.bytes > $1.bytes }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            categories = result
            progress = 1
            phase = .review
        }
        if result.isEmpty {
            logLines.append(L("Nothing found — your Mac is already clean"))
        }
    }

    /// Читает ~/.config/mole/clean-list.txt, который mo clean --dry-run оставляет после себя.
    static let cleanListPath = NSHomeDirectory() + "/.config/mole/clean-list.txt"

    static func parseCleanList() -> [(String, [CleanItem])] {
        guard let text = try? String(contentsOfFile: cleanListPath, encoding: .utf8) else { return [] }
        var out: [(String, [CleanItem])] = []
        var current: String?
        var items: [CleanItem] = []
        func flush() { if let c = current { out.append((c, items)) } }
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("=== ") && line.hasSuffix(" ===") {
                flush()
                current = String(line.dropFirst(4).dropLast(4))
                items = []
                continue
            }
            guard current != nil, !line.isEmpty, !line.hasPrefix("#"),
                  let hashRange = line.range(of: "  # ") else { continue }
            let p = String(line[..<hashRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let meta = line[hashRange.upperBound...]
            if meta.contains("counted under") { continue }
            let size = parseMoleSize(meta) ?? 0
            items.append(CleanItem(path: p, bytes: size))
        }
        flush()
        // Один и тот же раздел может встретиться дважды — склеиваем.
        var merged: [String: [CleanItem]] = [:]
        var order: [String] = []
        for (s, its) in out {
            if merged[s] == nil { order.append(s); merged[s] = [] }
            merged[s]! += its
        }
        return order.map { ($0, merged[$0] ?? []) }
    }

    // MARK: Выбор

    func toggle(_ id: String) {
        guard phase == .review, let i = categories.firstIndex(where: { $0.id == id }), !categories[i].locked else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { categories[i].selected.toggle() }
    }

    // MARK: Очистка — выбранное уходит в Корзину

    nonisolated static func isSafeToTrash(_ path: String) -> Bool {
        let home = NSHomeDirectory()
        guard path.hasPrefix(home + "/"), !path.contains("*") else { return false }
        let rel = path.dropFirst(home.count + 1).split(separator: "/")
        // «..» и «.» в любом месте (в т.ч. в конце: ~/Documents/.. = вся домашняя папка) — отказ.
        guard !rel.contains(where: { $0 == ".." || $0 == "." }) else { return false }
        return rel.count >= 2 && !(rel.count == 2 && rel[0] == "Library")
    }

    func clean() {
        guard phase == .review, selectedBytes > 0 || categories.contains(where: { $0.selected }) else { return }
        freed = 0
        failedCount = 0
        progress = 0
        logLines.append(L("$ moving selected items to Trash"))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { phase = .cleaning }

        Task { @MainActor in
            let total = max(1, selectedBytes)
            let totalItems = max(1, categories.filter { $0.selected }.reduce(0) { $0 + $1.items.count })
            var doneBytes = 0.0
            var doneItems = 0
            for idx in categories.indices where categories[idx].selected {
                withAnimation(.easeInOut(duration: 0.25)) { categories[idx].state = .cleaning }
                logLines.append("[ .. ] \(categories[idx].code)")
                let items = categories[idx].items
                let pace: UInt64 = items.count <= 60 ? 25_000_000 : 0
                for item in items {
                    let ok = await Self.recycle(item.path)
                    doneBytes += item.bytes
                    doneItems += 1
                    withAnimation(.linear(duration: 0.15)) {
                        if ok {
                            categories[idx].removed += item.bytes
                            freed += item.bytes
                        } else {
                            categories[idx].failed += 1
                            failedCount += 1
                        }
                        progress = min(1, max(doneBytes / total, Double(doneItems) / Double(totalItems)))
                    }
                    if pace > 0 { try? await Task.sleep(nanoseconds: pace) }
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    let c = categories[idx]
                    categories[idx].state = c.failed > 0 ? .partial : .cleaned
                    if c.failed == 0 { categories[idx].removed = c.bytes }
                }
                logLines.append(categories[idx].failed > 0
                                ? L("[WARN] %@: skipped %@", categories[idx].code, "\(categories[idx].failed)")
                                : "[ OK ] \(categories[idx].code) \(bytes(categories[idx].bytes))")
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            logLines.append(L("[DONE] %@ in Trash", bytes(freed)))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                progress = 1
                phase = .done
            }
        }
    }

    static func recycle(_ path: String) async -> Bool {
        guard isSafeToTrash(path) else { return false }
        guard FileManager.default.fileExists(atPath: path) else { return true }
        return await withCheckedContinuation { cont in
            NSWorkspace.shared.recycle([URL(fileURLWithPath: path)]) { _, err in
                cont.resume(returning: err == nil)
            }
        }
    }

    func reset() {
        // Кнопки «Отмена/ESC/Готово» зовут reset(); если скан ещё идёт — гасим процесс, а не бросаем его в фоне.
        if phase == .scanning { cancel(); return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            phase = .idle
            progress = 0
            categories = []
            freed = 0
        }
    }
}
