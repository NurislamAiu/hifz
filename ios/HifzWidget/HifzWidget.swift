import SwiftUI
import WidgetKit

struct ReminderText {
    let reference: String
    let ru: String
    let kk: String
}

private let reminderTexts = [
    ReminderText(
        reference: "39:53",
        ru: "Не отчаивайтесь в милости Аллаха: Он прощает грехи полностью.",
        kk: "Алланың рақымынан үміт үзбеңіз: Ол күнәларды толық кешіреді."
    ),
    ReminderText(
        reference: "66:8",
        ru: "Обратитесь к Аллаху с искренним покаянием, и Он исправит ваши дела.",
        kk: "Аллаға шынайы тәубе етіңіз, Ол істеріңізді түзетеді."
    ),
    ReminderText(
        reference: "25:70",
        ru: "Кто покается, уверует и творит добро, тому Аллах заменит зло добром.",
        kk: "Кім тәубе етіп, иман келтіріп, ізгі амал жасаса, Алла жамандықтарын жақсылыққа ауыстырады."
    ),
    ReminderText(
        reference: "57:16",
        ru: "Не пора ли сердцам смириться перед поминанием Аллаха?",
        kk: "Жүректер Алланы еске алғанда жұмсаратын уақыт келмеді ме?"
    ),
    ReminderText(
        reference: "59:18",
        ru: "Пусть каждая душа посмотрит, что приготовила на завтра.",
        kk: "Әр жан ертеңге не дайындағанына қарасын."
    ),
    ReminderText(
        reference: "99:7-8",
        ru: "Кто сделал добро или зло весом с пылинку, увидит его.",
        kk: "Кім тозаңдай жақсылық не жамандық жасаса, оны көреді."
    )
]

struct PrayerMoment: Identifiable {
    let key: String
    let kk: String
    let ru: String
    let time: String

    var id: String { key }
}

struct PrayerDay {
    let city: String
    let date: Date
    let dateLabel: String
    let methodName: String
    let moments: [PrayerMoment]

    func nextMoment(after currentDate: Date) -> PrayerMoment {
        for moment in moments {
            if let date = momentDate(moment.time, on: currentDate), date > currentDate {
                return moment
            }
        }
        return moments.first ?? PrayerMoment(key: "fajr", kk: "Таң", ru: "Фаджр", time: "--:--")
    }

    func nextMomentDate(after currentDate: Date) -> Date {
        for moment in moments {
            if let date = momentDate(moment.time, on: currentDate), date > currentDate {
                return date
            }
        }
        if let first = moments.first,
           let date = momentDate(first.time, on: currentDate),
           let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) {
            return tomorrow
        }
        return currentDate.addingTimeInterval(3600)
    }

    func progress(for currentDate: Date) -> Double {
        guard let first = moments.first,
              let last = moments.last,
              let start = momentDate(first.time, on: currentDate),
              let end = momentDate(last.time, on: currentDate),
              end > start else {
            return 0.15
        }
        let raw = currentDate.timeIntervalSince(start) / end.timeIntervalSince(start)
        return min(max(raw, 0.06), 0.94)
    }

    private func momentDate(_ value: String, on currentDate: Date) -> Date? {
        let parts = value.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }
}

struct HifzWidgetEntry: TimelineEntry {
    let date: Date
    let reminder: ReminderText
    let prayerDay: PrayerDay?
}

final class PrayerScheduleStore {
    static let shared = PrayerScheduleStore()

    private let appGroupId = "group.com.nurislam.hifz"
    private let keys = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]
    private let kkNames = ["Таң", "Күн", "Бесін", "Екінті", "Ақшам", "Құптан"]
    private let ruNames = ["Фаджр", "Восход", "Зухр", "Аср", "Магриб", "Иша"]
    private var cities: [String: [String: [String]]]?

    func day(for date: Date) -> PrayerDay? {
        if let sharedDay = sharedDay(for: date) {
            return sharedDay
        }

        ensureLoaded()
        guard let raw = cities?["almaty"]?[dateKey(date)] else {
            return nil
        }

        let moments = raw.enumerated().compactMap { index, value -> PrayerMoment? in
            guard index < keys.count else { return nil }
            return PrayerMoment(
                key: keys[index],
                kk: kkNames[index],
                ru: ruNames[index],
                time: value
            )
        }

        return PrayerDay(
            city: "Алматы",
            date: date,
            dateLabel: shortDateLabel(date),
            methodName: "ҚМДБ",
            moments: moments
        )
    }

    private func sharedDay(for date: Date) -> PrayerDay? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let payload = defaults.dictionary(forKey: "prayerTimesPayload"),
              let cityName = payload["cityName"] as? String,
              let entries = payload["entries"] as? [[String: Any]] else {
            return nil
        }

        let moments = entries.compactMap { entry -> PrayerMoment? in
            guard let key = entry["key"] as? String,
                  let time = entry["time"] as? String else {
                return nil
            }

            let index = keys.firstIndex(of: key) ?? 0
            return PrayerMoment(
                key: key,
                kk: index < kkNames.count ? kkNames[index] : key,
                ru: index < ruNames.count ? ruNames[index] : key,
                time: time
            )
        }

        guard !moments.isEmpty else { return nil }

        return PrayerDay(
            city: cityName,
            date: date,
            dateLabel: payload["dateLabel"] as? String ?? shortDateLabel(date),
            methodName: payload["methodName"] as? String ?? "Hifz",
            moments: moments
        )
    }

    private func ensureLoaded() {
        if cities != nil { return }
        guard let url = Bundle.main.url(forResource: "muftyat", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawCities = decoded["cities"] as? [String: Any] else {
            cities = [:]
            return
        }

        var parsed: [String: [String: [String]]] = [:]
        for (city, daysValue) in rawCities {
            guard let days = daysValue as? [String: Any] else { continue }
            var parsedDays: [String: [String]] = [:]
            for (day, values) in days {
                if let times = values as? [String] {
                    parsedDays[day] = times
                }
            }
            parsed[city] = parsedDays
        }
        cities = parsed
    }

    private func dateKey(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 2026,
            components.month ?? 1,
            components.day ?? 1
        )
    }

    private func shortDateLabel(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.day, .month], from: date)
        return String(format: "%02d.%02d", components.day ?? 1, components.month ?? 1)
    }
}

struct HifzWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HifzWidgetEntry {
        HifzWidgetEntry(
            date: Date(),
            reminder: reminderTexts[0],
            prayerDay: PrayerScheduleStore.shared.day(for: Date()) ?? samplePrayerDay
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HifzWidgetEntry) -> Void) {
        let now = Date()
        completion(entry(for: now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HifzWidgetEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let entries = (0..<12).compactMap { offset -> HifzWidgetEntry? in
            guard let date = calendar.date(byAdding: .minute, value: offset * 30, to: now) else {
                return nil
            }
            return entry(for: date)
        }
        let nextRefresh = calendar.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }

    private func entry(for date: Date) -> HifzWidgetEntry {
        HifzWidgetEntry(
            date: date,
            reminder: reminderFor(date),
            prayerDay: PrayerScheduleStore.shared.day(for: date) ?? samplePrayerDay
        )
    }

    private func reminderFor(_ date: Date) -> ReminderText {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
        let seed = (components.year ?? 0) + (components.month ?? 0) + (components.day ?? 0) + (components.hour ?? 0)
        return reminderTexts[abs(seed) % reminderTexts.count]
    }

    private var samplePrayerDay: PrayerDay {
        PrayerDay(
            city: "Алматы",
            date: Date(),
            dateLabel: "04.07",
            methodName: "ҚМДБ",
            moments: [
                PrayerMoment(key: "fajr", kk: "Таң", ru: "Фаджр", time: "02:31"),
                PrayerMoment(key: "sunrise", kk: "Күн", ru: "Восход", time: "04:15"),
                PrayerMoment(key: "dhuhr", kk: "Бесін", ru: "Зухр", time: "12:00"),
                PrayerMoment(key: "asr", kk: "Екінті", ru: "Аср", time: "17:18"),
                PrayerMoment(key: "maghrib", kk: "Ақшам", ru: "Магриб", time: "19:38"),
                PrayerMoment(key: "isha", kk: "Құптан", ru: "Иша", time: "21:22")
            ]
        )
    }
}

struct HifzWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    let entry: HifzWidgetEntry

    private var isKazakh: Bool {
        Locale.current.languageCode != "ru"
    }

    private var accent: Color {
        Color(red: 0.08, green: 0.60, blue: 0.65)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.06, green: 0.08, blue: 0.09)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.68) : Color(red: 0.38, green: 0.45, blue: 0.47)
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.04, green: 0.05, blue: 0.06)
            : Color(red: 0.98, green: 0.99, blue: 1.00)
    }

    var body: some View {
        ZStack {
            backgroundColor

            if #available(iOSApplicationExtension 16.0, *) {
                switch family {
                case .accessoryInline:
                    LockInlinePrayerView(entry: entry, isKazakh: isKazakh)
                case .accessoryCircular:
                    LockCircularPrayerView(entry: entry, isKazakh: isKazakh)
                case .accessoryRectangular:
                    LockRectangularPrayerView(entry: entry, isKazakh: isKazakh)
                case .systemMedium:
                    PrayerMediumView(
                        entry: entry,
                        isKazakh: isKazakh,
                        accent: accent,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        isDark: colorScheme == .dark
                    )
                case .systemLarge:
                    PrayerLargeView(
                        entry: entry,
                        isKazakh: isKazakh,
                        accent: accent,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        isDark: colorScheme == .dark
                    )
                default:
                    ReminderSmallView(
                        entry: entry,
                        isKazakh: isKazakh,
                        accent: accent,
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )
                }
            } else {
                switch family {
                case .systemMedium:
                    PrayerMediumView(
                        entry: entry,
                        isKazakh: isKazakh,
                        accent: accent,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        isDark: colorScheme == .dark
                    )
                case .systemLarge:
                    PrayerLargeView(
                        entry: entry,
                        isKazakh: isKazakh,
                        accent: accent,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        isDark: colorScheme == .dark
                    )
                default:
                    ReminderSmallView(
                        entry: entry,
                        isKazakh: isKazakh,
                        accent: accent,
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )
                }
            }
        }
    }
}

struct ReminderSmallView: View {
    let entry: HifzWidgetEntry
    let isKazakh: Bool
    let accent: Color
    let primaryText: Color
    let secondaryText: Color

    private var day: PrayerDay {
        entry.prayerDay ?? PrayerDay(city: "Алматы", date: entry.date, dateLabel: "04.07", methodName: "ҚМДБ", moments: [])
    }

    private var next: PrayerMoment {
        day.nextMoment(after: entry.date)
    }

    private var nextDate: Date {
        day.nextMomentDate(after: entry.date)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.63, blue: 0.68),
                    Color(red: 0.45, green: 0.83, blue: 0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 92, height: 92)
                .offset(x: 34, y: -34)

            Image(systemName: symbolName(for: next))
                .font(.system(size: 58, weight: .bold))
                .foregroundColor(.white.opacity(0.10))
                .offset(x: 23, y: 70)

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(day.city)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.white.opacity(0.90))
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)

                    Spacer()

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.78))
                }

                Text(countdownTitle(for: next))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)

                Text(nextDate, style: .timer)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(name(for: next))
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)

                    Text(next.time)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.76))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
        }
    }

    private func name(for moment: PrayerMoment) -> String {
        isKazakh ? moment.kk : moment.ru
    }

    private func countdownTitle(for moment: PrayerMoment) -> String {
        if !isKazakh {
            return "До \(moment.ru)"
        }
        return switch moment.key {
        case "fajr": "Таңға дейін"
        case "sunrise": "Күнге дейін"
        case "dhuhr": "Бесінге дейін"
        case "asr": "Екінтіге дейін"
        case "maghrib": "Ақшамға дейін"
        case "isha": "Құптанға дейін"
        default: "\(moment.kk) дейін"
        }
    }

    private func symbolName(for moment: PrayerMoment) -> String {
        switch moment.key {
        case "fajr": return "sun.horizon.fill"
        case "sunrise": return "sunrise.fill"
        case "dhuhr": return "sun.max.fill"
        case "asr": return "cloud.sun.fill"
        case "maghrib": return "sunset.fill"
        case "isha": return "moon.fill"
        default: return "circle.fill"
        }
    }
}

struct PrayerMediumView: View {
    let entry: HifzWidgetEntry
    let isKazakh: Bool
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let isDark: Bool

    private var day: PrayerDay {
        entry.prayerDay ?? PrayerDay(city: "Алматы", date: entry.date, dateLabel: "04.07", methodName: "ҚМДБ", moments: [])
    }

    private var next: PrayerMoment {
        day.nextMoment(after: entry.date)
    }

    private var nextDate: Date {
        day.nextMomentDate(after: entry.date)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.63, blue: 0.68),
                    Color(red: 0.45, green: 0.83, blue: 0.86)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 118, height: 118)
                .offset(x: 40, y: -58)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 88, height: 88)
                .offset(x: 190, y: 70)

            VStack(spacing: 17) {
                HStack(spacing: 10) {
                    HStack(spacing: 7) {
                        Text(countdownTitle(for: next))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)

                        Text(nextDate, style: .timer)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                    )

                    Spacer(minLength: 6)

                    Text(day.city)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.white.opacity(0.88))
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.16))
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.88))
                    }
                    .frame(width: 34, height: 34)
                }

                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(day.moments) { moment in
                        PolishedMediumPrayerColumn(
                            title: shortName(for: moment),
                            time: moment.time,
                            symbol: symbolName(for: moment),
                            isActive: moment.key == next.key,
                            accent: .white,
                            primaryText: .white,
                            secondaryText: .white.opacity(0.70),
                            isDark: true
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 15)
        }
    }

    private func name(for moment: PrayerMoment) -> String {
        isKazakh ? moment.kk : moment.ru
    }

    private func prayerChip(_ index: Int) -> some View {
        let moment = index < day.moments.count
            ? day.moments[index]
            : PrayerMoment(key: "\(index)", kk: "--", ru: "--", time: "--:--")
        return MediumPrayerChip(
            title: shortName(for: moment),
            time: moment.time,
            isActive: moment.key == next.key,
            accent: accent,
            primaryText: primaryText,
            secondaryText: secondaryText,
            isDark: isDark
        )
    }

    private func countdownTitle(for moment: PrayerMoment) -> String {
        if !isKazakh {
            return "До \(moment.ru)"
        }
        return switch moment.key {
        case "fajr": "Таңға дейін"
        case "sunrise": "Күнге дейін"
        case "dhuhr": "Бесінге дейін"
        case "asr": "Екінтіге дейін"
        case "maghrib": "Ақшамға дейін"
        case "isha": "Құптанға дейін"
        default: "\(moment.kk) дейін"
        }
    }

    private func shortName(for moment: PrayerMoment) -> String {
        if isKazakh {
            return switch moment.key {
            case "fajr": "Таң"
            case "sunrise": "Күн"
            case "dhuhr": "Бесін"
            case "asr": "Екінті"
            case "maghrib": "Ақшам"
            case "isha": "Құптан"
            default: moment.kk
            }
        }

        return switch moment.key {
        case "fajr": "Фаджр"
        case "sunrise": "Восх"
        case "dhuhr": "Зухр"
        case "asr": "Аср"
        case "maghrib": "Магр"
        case "isha": "Иша"
        default: moment.ru
        }
    }

    private func symbolName(for moment: PrayerMoment) -> String {
        switch moment.key {
        case "fajr": return "sun.horizon.fill"
        case "sunrise": return "sunrise.fill"
        case "dhuhr": return "sun.max.fill"
        case "asr": return "cloud.sun.fill"
        case "maghrib": return "sunset.fill"
        case "isha": return "moon.fill"
        default: return "circle.fill"
        }
    }

}

struct PolishedMediumPrayerColumn: View {
    let title: String
    let time: String
    let symbol: String
    let isActive: Bool
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let isDark: Bool

    var body: some View {
        ZStack {
            if isActive {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accent.opacity(isDark ? 0.16 : 0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accent.opacity(isDark ? 0.24 : 0.16), lineWidth: 1)
                    )
                    .frame(width: 54, height: 94)
            }

            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isActive ? accent : secondaryText.opacity(0.72))
                    .frame(height: 21)

                Text(time)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(isActive ? accent : primaryText.opacity(0.76))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Text(title)
                    .font(.system(size: 12, weight: isActive ? .heavy : .semibold))
                    .foregroundColor(isActive ? accent : secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)
            }
        }
        .frame(height: 94)
    }
}

struct PrayerLargeView: View {
    let entry: HifzWidgetEntry
    let isKazakh: Bool
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let isDark: Bool

    private var day: PrayerDay {
        entry.prayerDay ?? PrayerDay(city: "Алматы", date: entry.date, dateLabel: "04.07", methodName: "ҚМДБ", moments: [])
    }

    private var next: PrayerMoment {
        day.nextMoment(after: entry.date)
    }

    private var title: String {
        isKazakh ? "Намаз уақыты" : "Время намаза"
    }

    private var nextTitle: String {
        isKazakh ? "Қазір жақындап келе жатқан" : "Сейчас приближается"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accent.opacity(isDark ? 0.14 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accent.opacity(isDark ? 0.22 : 0.14), lineWidth: 1)
                    )

                Circle()
                    .stroke(accent.opacity(isDark ? 0.22 : 0.12), lineWidth: 16)
                    .frame(width: 118, height: 118)
                    .offset(x: 44, y: -46)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 7) {
                                Circle()
                                    .fill(accent)
                                    .frame(width: 8, height: 8)
                                Text(title)
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(primaryText)
                            }
                            Text("\(day.city) · \(shortMethodName(day.methodName))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }

                        Spacer()

                        Text(day.dateLabel)
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(accent)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(nextTitle)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(secondaryText)
                            Text(name(for: next))
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.76)
                        }

                        Spacer()

                        Text(next.time)
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundColor(accent)
                    }
                }
                .padding(16)
            }
            .frame(height: 124)

            HStack(spacing: 10) {
                ProgressBar(progress: day.progress(for: entry.date), accent: accent, isDark: isDark)
                    .frame(height: 8)

                Text("Hifz")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(accent)
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    prayerTile(0)
                    prayerTile(1)
                    prayerTile(2)
                }
                HStack(spacing: 8) {
                    prayerTile(3)
                    prayerTile(4)
                    prayerTile(5)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(17)
    }

    private func prayerTile(_ index: Int) -> some View {
        let moment = index < day.moments.count ? day.moments[index] : PrayerMoment(key: "\(index)", kk: "--", ru: "--", time: "--:--")
        return PrayerTimeTile(
            title: name(for: moment),
            time: moment.time,
            isActive: moment.key == next.key,
            accent: accent,
            primaryText: primaryText,
            secondaryText: secondaryText,
            isDark: isDark
        )
    }

    private func name(for moment: PrayerMoment) -> String {
        isKazakh ? moment.kk : moment.ru
    }

    private func shortMethodName(_ value: String) -> String {
        if value.contains("muftyat") || value.contains("ҚМДБ") {
            return "ҚМДБ"
        }
        return value
    }

    private func dateLabel(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.day, .month], from: date)
        return String(format: "%02d.%02d", components.day ?? 1, components.month ?? 1)
    }
}

struct MediumPrayerChip: View {
    let title: String
    let time: String
    let isActive: Bool
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let isDark: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(isActive ? accent : secondaryText.opacity(0.34))
                    .frame(width: 4, height: 4)

                Text(title)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(isActive ? accent : secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Text(time)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(isActive ? accent : primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? accent.opacity(isDark ? 0.20 : 0.12) : primaryText.opacity(isDark ? 0.06 : 0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? accent.opacity(0.22) : Color.clear, lineWidth: 1)
        )
    }
}

struct PrayerMiniRow: View {
    let title: String
    let time: String
    let isActive: Bool
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let isDark: Bool

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(isActive ? accent : secondaryText.opacity(0.34))
                .frame(width: 5, height: 5)

            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isActive ? primaryText : secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 2)

            Text(time)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(isActive ? accent : primaryText)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(isActive ? accent.opacity(isDark ? 0.18 : 0.10) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PrayerTimeTile: View {
    let title: String
    let time: String
    let isActive: Bool
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let isDark: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Circle()
                    .fill(isActive ? accent : secondaryText.opacity(0.36))
                    .frame(width: 5, height: 5)

                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isActive ? accent : secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text(time)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(isActive ? accent.opacity(isDark ? 0.18 : 0.10) : primaryText.opacity(isDark ? 0.06 : 0.035))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ProgressBar: View {
    let progress: Double
    let accent: Color
    let isDark: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(accent.opacity(isDark ? 0.20 : 0.13))
                Capsule()
                    .fill(accent)
                    .frame(width: max(10, proxy.size.width * CGFloat(progress)))
            }
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct LockInlinePrayerView: View {
    let entry: HifzWidgetEntry
    let isKazakh: Bool

    private var day: PrayerDay {
        entry.prayerDay ?? PrayerDay(city: "Алматы", date: entry.date, dateLabel: "04.07", methodName: "ҚМДБ", moments: [])
    }

    private var next: PrayerMoment {
        day.nextMoment(after: entry.date)
    }

    var body: some View {
        Text("\(isKazakh ? next.kk : next.ru) \(next.time)")
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .widgetAccentable()
    }
}

@available(iOSApplicationExtension 16.0, *)
struct LockCircularPrayerView: View {
    let entry: HifzWidgetEntry
    let isKazakh: Bool

    private var day: PrayerDay {
        entry.prayerDay ?? PrayerDay(city: "Алматы", date: entry.date, dateLabel: "04.07", methodName: "ҚМДБ", moments: [])
    }

    private var next: PrayerMoment {
        day.nextMoment(after: entry.date)
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                Text(shortName(for: next))
                    .font(.system(size: 11, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .widgetAccentable()

                Text(next.time)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                ProgressView(value: day.progress(for: entry.date))
                    .progressViewStyle(.circular)
                    .frame(width: 18, height: 18)
                    .widgetAccentable()
            }
            .padding(4)
        }
    }

    private func shortName(for moment: PrayerMoment) -> String {
        if isKazakh {
            return switch moment.key {
            case "fajr": "Таң"
            case "sunrise": "Күн"
            case "dhuhr": "Бес"
            case "asr": "Ек"
            case "maghrib": "Ақ"
            case "isha": "Құп"
            default: moment.kk
            }
        }

        return switch moment.key {
        case "fajr": "Фад"
        case "sunrise": "Вос"
        case "dhuhr": "Зух"
        case "asr": "Аср"
        case "maghrib": "Маг"
        case "isha": "Иша"
        default: moment.ru
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct LockRectangularPrayerView: View {
    let entry: HifzWidgetEntry
    let isKazakh: Bool

    private var day: PrayerDay {
        entry.prayerDay ?? PrayerDay(city: "Алматы", date: entry.date, dateLabel: "04.07", methodName: "ҚМДБ", moments: [])
    }

    private var next: PrayerMoment {
        day.nextMoment(after: entry.date)
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isKazakh ? "Келесі намаз" : "Следующий намаз")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text(isKazakh ? next.kk : next.ru)
                        .font(.system(size: 17, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                        .widgetAccentable()

                    Text(day.city)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 2)

                Text(next.time)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .padding(.horizontal, 8)
        }
    }
}

struct HifzReminderWidget: Widget {
    let kind = "HifzReminderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HifzWidgetProvider()) { entry in
            HifzWidgetView(entry: entry)
        }
        .configurationDisplayName("Hifz")
        .description("Намаз уақыты және тәубе туралы аяттар")
        .supportedFamilies(supportedFamilies)
        .contentMarginsDisabled()
    }

    private var supportedFamilies: [WidgetFamily] {
        if #available(iOSApplicationExtension 16.0, *) {
            return [
                .systemSmall,
                .systemMedium,
                .accessoryInline,
                .accessoryCircular,
                .accessoryRectangular
            ]
        }
        return [.systemSmall, .systemMedium]
    }
}

struct HifzAyahLargeWidgetView: View {
    let entry: HifzWidgetEntry

    private var isKazakh: Bool {
        Locale.current.languageCode != "ru"
    }

    private var title: String {
        isKazakh ? "Тәубе туралы аят" : "Аят о покаянии"
    }

    private var text: String {
        isKazakh ? entry.reminder.kk : entry.reminder.ru
    }

    private var action: String {
        isKazakh ? "Бүгін жүректі жұмсарт" : "Смягчи сердце сегодня"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.50, blue: 0.56),
                    Color(red: 0.10, green: 0.68, blue: 0.72),
                    Color(red: 0.60, green: 0.88, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 210, height: 210)
                .offset(x: 206, y: -102)

            Circle()
                .stroke(Color.white.opacity(0.13), lineWidth: 18)
                .frame(width: 160, height: 160)
                .offset(x: -76, y: 226)

            Text("۝")
                .font(.system(size: 92, weight: .bold))
                .foregroundColor(.white.opacity(0.10))
                .offset(x: 248, y: 204)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(action)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.72))
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(entry.reminder.reference)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.17)))
                }

                Spacer(minLength: 0)

                Text(text)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(6)
                    .minimumScaleFactor(0.66)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.white.opacity(0.86))
                        .frame(width: 7, height: 7)

                    Text("Hifz")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.white.opacity(0.84))

                    Spacer()

                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.72))
                }
            }
            .padding(22)
        }
    }
}

struct HifzAyahLargeWidget: Widget {
    let kind = "HifzAyahLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HifzWidgetProvider()) { entry in
            HifzAyahLargeWidgetView(entry: entry)
        }
        .configurationDisplayName("Hifz Ayah")
        .description("Тәубе туралы үлкен аят-еске салғыш")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}

struct HifzAyahMediumWidgetView: View {
    let entry: HifzWidgetEntry

    private var isKazakh: Bool {
        Locale.current.languageCode != "ru"
    }

    private var title: String {
        isKazakh ? "Күннің еске салуы" : "Напоминание дня"
    }

    private var text: String {
        isKazakh ? entry.reminder.kk : entry.reminder.ru
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.63, blue: 0.68),
                    Color(red: 0.45, green: 0.83, blue: 0.86)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 118, height: 118)
                .offset(x: 276, y: -62)

            Text("۝")
                .font(.system(size: 70, weight: .bold))
                .foregroundColor(.white.opacity(0.10))
                .offset(x: 320, y: 104)

            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text("Hifz")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.70))
                    }

                    Spacer()

                    Text(entry.reminder.reference)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.white.opacity(0.18)))
                }

                Text(text)
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.70)

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.76))
                    Text(isKazakh ? "Жүректі жұмсарт" : "Смягчи сердце")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.78))
                        .lineLimit(1)
                    Spacer()
                }
            }
            .padding(18)
        }
    }
}

struct HifzAyahMediumWidget: Widget {
    let kind = "HifzAyahMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HifzWidgetProvider()) { entry in
            HifzAyahWidgetView(entry: entry)
        }
        .configurationDisplayName("Hifz Ayah Medium")
        .description("Тәубе туралы орташа аят-еске салғыш")
        .supportedFamilies([
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
        .contentMarginsDisabled()
    }
}

struct HifzAyahWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: HifzWidgetEntry

    var body: some View {
        switch family {
        case .systemMedium:
            HifzAyahMediumWidgetView(entry: entry)
        case .accessoryInline:
            HifzAyahLockInlineView(entry: entry)
        case .accessoryCircular:
            HifzAyahLockCircularView(entry: entry)
        case .accessoryRectangular:
            HifzAyahLockRectangularView(entry: entry)
        default:
            HifzAyahMediumWidgetView(entry: entry)
        }
    }
}

struct HifzAyahLockInlineView: View {
    let entry: HifzWidgetEntry

    private var isKazakh: Bool {
        Locale.current.languageCode != "ru"
    }

    var body: some View {
        Text("\(entry.reminder.reference) · \(isKazakh ? "Алланың рақымынан үміт үзбе" : "Не отчаивайся в милости Аллаха")")
            .font(.system(size: 14, weight: .semibold))
            .lineLimit(1)
            .widgetAccentable()
    }
}

struct HifzAyahLockCircularView: View {
    let entry: HifzWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Text("۝")
                    .font(.system(size: 22, weight: .heavy))
                    .widgetAccentable()

                Text(entry.reminder.reference)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }
            .padding(4)
        }
    }
}

struct HifzAyahLockRectangularView: View {
    let entry: HifzWidgetEntry

    private var isKazakh: Bool {
        Locale.current.languageCode != "ru"
    }

    private var title: String {
        isKazakh ? "Күннің аяты" : "Аят дня"
    }

    private var text: String {
        isKazakh ? entry.reminder.kk : entry.reminder.ru
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            HStack(spacing: 9) {
                Text("۝")
                    .font(.system(size: 24, weight: .heavy))
                    .widgetAccentable()

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(title)
                            .font(.system(size: 11, weight: .heavy))
                            .lineLimit(1)

                        Text(entry.reminder.reference)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Text(text)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
        }
    }
}

@main
struct HifzWidgetBundle: WidgetBundle {
    var body: some Widget {
        HifzReminderWidget()
        HifzAyahLargeWidget()
        HifzAyahMediumWidget()
    }
}
