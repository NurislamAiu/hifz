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

struct HifzReminderEntry: TimelineEntry {
    let date: Date
    let reminder: ReminderText
}

struct HifzReminderProvider: TimelineProvider {
    func placeholder(in context: Context) -> HifzReminderEntry {
        HifzReminderEntry(date: Date(), reminder: reminderTexts[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (HifzReminderEntry) -> Void) {
        completion(HifzReminderEntry(date: Date(), reminder: reminderFor(Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HifzReminderEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let entries = (0..<6).compactMap { offset -> HifzReminderEntry? in
            guard let date = calendar.date(byAdding: .hour, value: offset * 2, to: now) else {
                return nil
            }
            return HifzReminderEntry(date: date, reminder: reminderFor(date))
        }
        let nextRefresh = calendar.date(byAdding: .hour, value: 2, to: now) ?? now.addingTimeInterval(7200)
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }

    private func reminderFor(_ date: Date) -> ReminderText {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
        let seed = (components.year ?? 0) + (components.month ?? 0) + (components.day ?? 0) + (components.hour ?? 0)
        return reminderTexts[abs(seed) % reminderTexts.count]
    }
}

struct HifzReminderWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme

    let entry: HifzReminderEntry

    private var isKazakh: Bool {
        Locale.current.languageCode != "ru"
    }

    private var title: String {
        isKazakh ? "Тәубе" : "Покаяние"
    }

    private var text: String {
        isKazakh ? entry.reminder.kk : entry.reminder.ru
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
        ZStack(alignment: .topLeading) {
            backgroundColor

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(accent)
                        .frame(width: 7, height: 7)

                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accent)
                    Spacer()
                    Text(entry.reminder.reference)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(secondaryText)
                }

                Text(text)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryText)
                    .lineLimit(5)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)

                Text("Hifz")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(accent)
            }
            .padding(14)
        }
    }
}

struct HifzReminderWidget: Widget {
    let kind = "HifzReminderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HifzReminderProvider()) { entry in
            HifzReminderWidgetView(entry: entry)
        }
        .configurationDisplayName("Hifz")
        .description("Аяты о покаянии / Тәубе туралы аяттар")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct HifzWidgetBundle: WidgetBundle {
    var body: some Widget {
        HifzReminderWidget()
    }
}
