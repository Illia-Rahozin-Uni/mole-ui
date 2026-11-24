// Localization: English / Українська / Русский, switchable at runtime.
//
// Keys are the English strings themselves, so `L("Scan")` reads naturally and falls back
// to English if a translation is missing. Arguments are always passed as strings (`%@`).

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, uk, ru
    var id: String { rawValue }

    /// Name shown in the picker — each language in its own name.
    var title: String {
        switch self {
        case .system: return L("System")
        case .en: return "English"
        case .uk: return "Українська"
        case .ru: return "Русский"
        }
    }

    var short: String {
        switch self {
        case .system: return "Auto"
        case .en: return "EN"
        case .uk: return "UA"
        case .ru: return "RU"
        }
    }
}

enum Lang { case en, uk, ru }

enum L10n {
    static let storageKey = "language"

    /// The language strings are rendered in right now.
    static var current: Lang {
        let picked = AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .system
        switch picked {
        case .en: return .en
        case .uk: return .uk
        case .ru: return .ru
        case .system:
            for id in Locale.preferredLanguages {
                switch id.prefix(2) {
                case "uk": return .uk
                case "ru": return .ru
                case "en": return .en
                default: continue
                }
            }
            return .en
        }
    }

    static var decimalSeparator: String { current == .en ? "." : "," }

    /// [English: (Українська, Русский)]
    static let table: [String: (String, String)] = [
        // Sections, theme, language
        "Clean": ("Очищення", "Очистка"),
        "Health": ("Здоров’я", "Здоровье"),
        "Apps": ("Програми", "Приложения"),
        "Disk": ("Диск", "Диск"),
        "History": ("Історія", "История"),
        "Tools": ("Інструменти", "Инструменты"),
        "Theme": ("Тема", "Тема"),
        "Language": ("Мова", "Язык"),
        "System": ("Системна", "Системный"),
        "Appearance": ("Оформлення", "Тема оформления"),

        // Units
        "B": ("Б", "Б"), "KB": ("КБ", "КБ"), "MB": ("МБ", "МБ"), "GB": ("ГБ", "ГБ"), "TB": ("ТБ", "ТБ"),

        // Health
        "up %@": ("працює %@", "работает %@"),
        "System health": ("Стан системи", "Здоровье системы"),
        "CPU": ("Процесор", "Процессор"),
        "Memory": ("Пам’ять", "Память"),
        "%@ of %@": ("%@ з %@", "%@ из %@"),
        "%@ free of %@": ("Вільно %@ з %@", "Свободно %@ из %@"),
        "Battery": ("Батарея", "Батарея"),
        "capacity %@%%": ("ємність %@%%", "ёмкость %@%%"),
        "Top processes": ("Хто найбільше навантажує", "Кто больше всех грузит"),
        "Collecting system data…": ("Збираю дані про систему…", "Собираю данные о системе…"),
        "Mole not found": ("Mole не знайдено", "Mole не найден"),
        "Couldn't start mo status": ("Не вдалося запустити mo status", "Не удалось запустить mo status"),
        "Couldn't start mo clean": ("Не вдалося запустити mo clean", "Не удалось запустить mo clean"),

        // Apps
        "Uninstall apps together with their settings and caches. Everything goes to the Trash by default.":
            ("Видалення разом із налаштуваннями та кешами. За замовчуванням — у Кошик.",
             "Удаление вместе с настройками и кэшами. По умолчанию — в Корзину."),
        "Refresh": ("Оновити", "Обновить"),
        "Search by name": ("Пошук за назвою", "Поиск по названию"),
        "Scanning apps…": ("Сканую програми…", "Сканирую приложения…"),
        "Uninstall…": ("Видалити…", "Удалить…"),
        "Uninstall “%@”?": ("Видалити «%@»?", "Удалить «%@»?"),
        "Uninstall with Mole (to Trash)": ("Видалити через Mole (у Кошик)", "Удалить через Mole (в Корзину)"),
        "Cancel": ("Скасувати", "Отмена"),
        "Terminal will open: Mole will show what it finds and ask you to confirm.":
            ("Відкриється Термінал: Mole покаже, що знайде, і попросить підтвердити.",
             "Откроется Терминал: Mole покажет, что найдёт, и попросит подтвердить."),

        // Disk
        "What's taking up space. Click a folder to open it.":
            ("Що займає місце. Натисни на папку, щоб зайти всередину.",
             "Что занимает место. Нажми на папку, чтобы зайти внутрь."),
        "Choose folder…": ("Вибрати папку…", "Выбрать папку…"),
        "Open in Terminal": ("У Терміналі", "В Терминале"),
        "Total: %@": ("Усього: %@", "Всего: %@"),
        "Scanning… a large folder can take a minute":
            ("Сканую… велика папка може зайняти хвилину", "Сканирую… большая папка может занять минуту"),
        "Show in Finder": ("Показати у Finder", "Показать в Finder"),
        "Move to Trash…": ("Перемістити в Кошик…", "Переместить в Корзину…"),
        "Couldn't scan this folder.": ("Не вдалося просканувати цю папку.", "Не удалось просканировать эту папку."),
        "Move “%@” to the Trash?": ("Перемістити «%@» у Кошик?", "Переместить «%@» в Корзину?"),
        "Move to Trash": ("У Кошик", "В Корзину"),
        "%@. You can restore it from the Trash.": ("%@. З Кошика можна відновити.", "%@. Из Корзины можно вернуть."),
        "Analyze": ("Аналізувати", "Анализировать"),

        // History
        "What Mole did and when": ("Що і коли робив Mole", "Что и когда делал Mole"),
        "Nothing here yet.": ("Поки порожньо.", "Пока пусто."),
        "removed %@ · trashed %@": ("видалено %@ · у кошик %@", "удалено %@ · в корзину %@"),

        // Tools
        "Mole settings": ("Налаштування Mole", "Настройки Mole"),
        "Full clean with Mole": ("Повне очищення через Mole", "Полная очистка через Mole"),
        "Including system caches (asks for password)":
            ("Разом із системними кешами (попросить пароль)", "Включая системные кэши (спросит пароль)"),
        "Optimize": ("Оптимізація", "Оптимизация"),
        "DNS, Spotlight, Finder services": ("DNS, Spotlight, служби Finder", "DNS, Spotlight, службы Finder"),
        "Old installers": ("Старі інсталятори", "Старые установщики"),
        "Find and remove .dmg/.pkg": ("Знайти й видалити .dmg/.pkg", "Найти и удалить .dmg/.pkg"),
        "Touch ID for sudo": ("Touch ID для sudo", "Touch ID для sudo"),
        "Admin password with your finger": ("Пароль адміністратора — пальцем", "Пароль администратора — пальцем"),
        "Update Mole": ("Оновити Mole", "Обновить Mole"),
        "Download the latest version": ("Завантажити свіжу версію", "Скачать свежую версию"),
        "Protect caches": ("Захистити кеші", "Защитить кэши"),
        "Cleanup whitelist": ("Білий список для очищення", "Белый список для очистки"),
        "Project folders": ("Папки з проєктами", "Папки с проектами"),
        "Where to look for node_modules": ("Де шукати node_modules", "Где искать node_modules"),
        "Classic Mole": ("Класичний Mole", "Классический Mole"),
        "Native menu in Terminal": ("Рідне меню в Терміналі", "Родное меню в Терминале"),
        "Open Mole operations log": ("Відкрити журнал операцій Mole", "Открыть журнал операций Mole"),

        // Mole missing
        "This app is a front end for the mo command. Install it and click “Check again”.":
            ("Застосунок — оболонка над командою mo. Встанови її та натисни «Перевірити знову».",
             "Приложение — оболочка над командой mo. Установи её и нажми «Проверить снова»."),
        "Install with Homebrew": ("Встановити через Homebrew", "Установить через Homebrew"),
        "Check again": ("Перевірити знову", "Проверить снова"),

        // Menu bar
        "Collecting data…": ("Збираю дані…", "Собираю данные…"),
        "Find junk": ("Знайти сміття", "Найти мусор"),
        "Open Mole": ("Відкрити Mole", "Открыть Mole"),
        "Quit": ("Вийти", "Выйти"),
        "Done. Press any key to close this window…":
            ("Готово. Натисни будь-яку клавішу, щоб закрити вікно…", "Готово. Нажми любую клавишу, чтобы закрыть окно…"),

        // Cleanup categories (keys = what Core.meta returns)
        "Logs & temp files": ("Логи й тимчасові файли", "Логи и временные файлы"),
        "Session trash, logs, temp": ("Сміття сесій, логи, temp", "Корзина сессий, логи, temp"),
        "App caches": ("Кеші програм", "Кэши приложений"),
        "Spotify, Slack, Telegram and more": ("Spotify, Slack, Telegram та інші", "Spotify, Slack, Telegram и др."),
        "Browsers": ("Браузери", "Браузеры"),
        "Chrome, Safari, Arc caches…": ("Кеші Chrome, Safari, Arc…", "Кэши Chrome, Safari, Arc…"),
        "Cloud & Office": ("Хмара та Office", "Облако и Office"),
        "Developer tools": ("Інструменти розробника", "Инструменты разработчика"),
        "Apps & utilities": ("Програми й утиліти", "Программы и утилиты"),
        "Third-party app caches": ("Кеші сторонніх програм", "Кэши сторонних программ"),
        "Virtualization": ("Віртуалізація", "Виртуализация"),
        "Docker, OrbStack, VMs": ("Docker, OrbStack, віртуальні машини", "Docker, OrbStack, виртуальные машины"),
        "App data": ("Дані програм", "Данные приложений"),
        "Leftovers in Application Support": ("Зайве в Application Support", "Лишнее в Application Support"),
        "Uninstalled app leftovers": ("Залишки видалених програм", "Хвосты удалённых программ"),
        "From apps already removed": ("Від того, що вже видалено", "От того, что уже удалено"),
        "Apple Silicon updates": ("Оновлення Apple Silicon", "Обновления Apple Silicon"),
        "Downloaded updates & firmware": ("Завантажені оновлення та прошивки", "Скачанные обновления и прошивки"),
        "Backups & firmware": ("Бекапи та прошивки", "Бэкапы и прошивки"),
        "iPhone/iPad, updates": ("iPhone/iPad, оновлення", "iPhone/iPad, обновления"),
        "Local snapshots": ("Локальні знімки", "Локальные снимки"),
        "Large files": ("Великі файли", "Большие файлы"),
        "Review before deleting": ("Перевір перед видаленням", "Проверь перед удалением"),
        "Developer junk": ("Сміття розробника", "Мусор разработчика"),
        "System caches": ("Системні кеші", "Системные кэши"),
        "Needs password — use Terminal": ("Потрібен пароль — через Термінал", "Нужен пароль — через Терминал"),
        "External drive": ("Зовнішній диск", "Внешний диск"),
        "Service files": ("Службові файли", "Служебные файлы"),
        "Needs password — “Full clean with Mole”":
            ("Потрібен пароль — «Повне очищення через Mole»", "Нужен пароль — «Полная очистка через Mole»"),

        // Scan / clean log
        "Nothing found — your Mac is already clean":
            ("Нічого не знайдено — Mac і так чистий", "Ничего не нашлось — Mac и так чистый"),
        "Skipped paths outside your home folder: %@ — only mo clean can clean them":
            ("Пропущено шляхів поза домашньою папкою: %@ — їх чистить лише mo clean",
             "Пропущено путей вне домашней папки: %@ — их чистит только mo clean"),
        "Scan didn't finish (code %@) — try again or run mo clean in Terminal":
            ("Сканування не завершилося (код %@) — спробуй ще раз або запусти mo clean у Терміналі",
             "Скан не завершился (код %@) — попробуй ещё раз или запусти mo clean в Терминале"),
        "[FAIL] mo clean --dry-run, code %@": ("[FAIL] mo clean --dry-run, код %@", "[FAIL] mo clean --dry-run, код %@"),
        "$ moving selected items to Trash": ("$ переміщую вибране в Кошик", "$ перемещаю выбранное в Корзину"),
        "[WARN] %@: skipped %@": ("[WARN] %@: пропущено %@", "[WARN] %@: пропущено %@"),
        "[DONE] %@ in Trash": ("[DONE] у Кошику %@", "[DONE] в Корзине %@"),

        // Clean screen — shared
        "%@ free": ("Вільно %@", "Свободно %@"),
        "Free": ("Вільно", "Свободно"),
        "Scan": ("Сканувати", "Сканировать"),
        "Clean %@": ("Очистити %@", "Очистить %@"),
        "Empty Trash": ("Очистити Кошик", "Очистить Корзину"),
        "cleaned": ("прибрано", "убрано"),
        "Getting ready…": ("Готуюся…", "Готовлюсь…"),
        "Looking at: %@": ("Дивлюся: %@", "Смотрю: %@"),
        "Looking for junk…": ("Шукаю сміття…", "Ищу мусор…"),
        "Cleaning up…": ("Прибираю…", "Убираю…"),

        // Apple theme
        "Mole connected": ("Mole під’єднано", "Mole подключён"),
        "What we found": ("Що знайшлося", "Что нашлось"),
        "%@ in Trash": ("%@ у Кошику", "%@ в Корзине"),
        "Great": ("Чудово", "Отлично"),
        "Ready to check": ("Готовий до перевірки", "Готов к проверке"),
        "All clean": ("Усе чисто", "Всё чисто"),
        "You can free up %@": ("Можна звільнити %@", "Можно освободить %@"),
        "Done! %@ in the Trash": ("Готово! %@ у Кошику", "Готово! %@ в Корзине"),
        "Mole will look for caches, logs and old files. Nothing is deleted until you say yes.":
            ("Mole пошукає кеші, логи та старі файли. Нічого не видалить, доки ти не скажеш «так».",
             "Mole поищет кэши, логи и старые файлы. Ничего не удалит, пока ты не скажешь «да»."),
        "Uncheck what you want to keep. Everything goes to the Trash.":
            ("Зніми позначки з того, що хочеш залишити. Усе піде в Кошик.",
             "Сними галочки с того, что хочешь оставить. Всё уйдёт в Корзину."),
        "Moving to Trash — no need to wait": ("Переміщую в Кошик, можна не чекати", "Перемещаю в Корзину, можно не ждать"),
        "Some files (%@) were skipped — they're in use or need a password.":
            ("Частину файлів (%@) пропущено — вони зайняті або потрібен пароль.",
             "Часть файлов (%@) пропущена — они заняты или нужен пароль."),
        "Space is freed once you empty the Trash.":
            ("Місце звільниться, коли очистиш Кошик.", "Место освободится, когда очистишь Корзину."),

        // Neon theme
        "STEP 1 OF 3": ("КРОК 1 ІЗ 3", "ШАГ 1 ИЗ 3"),
        "STEP 2 OF 3": ("КРОК 2 ІЗ 3", "ШАГ 2 ИЗ 3"),
        "STEP 3 OF 3 · DONE": ("КРОК 3 ІЗ 3 · ГОТОВО", "ШАГ 3 ИЗ 3 · ГОТОВО"),
        "SCANNING · %@%%": ("СКАНУЮ · %@%%", "СКАНИРУЮ · %@%%"),
        "CLEANING · %@%%": ("ЧИЩУ · %@%%", "ЧИЩУ · %@%%"),
        "Clean up your Mac?": ("Почистити Mac?", "Mac можно почистить?"),
        "All clean!": ("Усе чисто!", "Всё чисто!"),
        "Found stuff to remove": ("Знайшли, що прибрати", "Нашли, что убрать"),
        "Clean!": ("Чисто!", "Чисто!"),
        "Tap the circle — we'll find junk and show how much space you'll get back.":
            ("Натисни на кружечок — знайдемо сміття й покажемо, скільки місця повернемо.",
             "Нажми на кружок — найдём мусор и покажем, сколько места вернём."),
        "All safe: only caches and temp files. Into the Trash first.":
            ("Усе безпечно: лише кеші й тимчасові файли. Спершу — у Кошик.",
             "Всё безопасно: только кэши и временные файлы. Сначала — в Корзину."),
        "Moving to Trash": ("Переміщую в Кошик", "Перемещаю в Корзину"),
        "Files skipped: %@ — in use or need a password.":
            ("Пропущено файлів: %@ — зайняті або потрібен пароль.",
             "Пропущено файлов: %@ — заняты или нужен пароль."),
        "Your Mac is lighter. Empty the Trash to get the space back.":
            ("Mac став легшим. Очисти Кошик, щоб повернути місце.",
             "Mac стал легче. Очисти Корзину, чтобы вернуть место."),
        "Done": ("Готово", "Готово"),
        "%@ left": ("%@ лишилося", "%@ осталось"),
        "%@ of junk": ("%@ сміття", "%@ мусора"),

        // Cyber theme
        "SCANNING": ("СКАНУВАННЯ", "СКАНИРОВАНИЕ"),
        "CLEAN": ("ЧИСТО", "ЧИСТО"),
        "TARGETS FOUND": ("ЦІЛІ ЗНАЙДЕНО", "ЦЕЛИ НАЙДЕНЫ"),
        "WIPING": ("СТИРАННЯ", "СТИРАНИЕ"),
        "SYSTEM CLEAN": ("СИСТЕМА ЧИСТА", "СИСТЕМА ЧИСТА"),
        "[ SCAN ]": ("[ СКАН ]", "[ СКАН ]"),
        "[ WIPE %@ ]": ("[ СТЕРТИ %@ ]", "[ СТЕРЕТЬ %@ ]"),
        "awaiting scan": ("очікування скану", "ожидание скана"),
        "PROCESSES ": ("ПРОЦЕСИ ", "ПРОЦЕССЫ "),
        "NETWORK ": ("МЕРЕЖА ", "СЕТЬ "),
        "> press [ SCAN ] to find junk": ("> тисни [ СКАН ] — знайду сміття", "> жми [ СКАН ] — найду мусор"),
        "> nothing is deleted without confirmation":
            ("> нічого не видалю без підтвердження", "> ничего не удалю без подтверждения"),
    ]
}

/// Localized string for an English key.
func L(_ key: String) -> String {
    switch L10n.current {
    case .en: return key
    case .uk: return L10n.table[key]?.0 ?? key
    case .ru: return L10n.table[key]?.1 ?? key
    }
}

/// Localized format string with `%@` arguments.
func L(_ key: String, _ args: String...) -> String {
    String(format: L(key), arguments: args)
}

// MARK: - Picker

struct LanguagePicker: View {
    @AppStorage(L10n.storageKey) private var language: AppLanguage = .system
    var compact = false

    var body: some View {
        if compact {
            Menu {
                Picker(L("Language"), selection: $language) {
                    ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
            } label: {
                Label(language == .system ? L10n.current.short : language.short, systemImage: "globe")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        } else {
            Picker(L("Language"), selection: $language) {
                ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 360)
        }
    }
}

extension Lang {
    var short: String {
        switch self {
        case .en: return "EN"
        case .uk: return "UA"
        case .ru: return "RU"
        }
    }
}
