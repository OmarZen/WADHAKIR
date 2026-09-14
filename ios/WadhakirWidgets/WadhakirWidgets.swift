import WidgetKit
import SwiftUI
import UIKit

// Shared App Group — must match HomeWidget.setAppGroupId in the Flutter app and
// the App Groups capability on BOTH the Runner and this extension target.
private let appGroupId = "group.com.bloom.wadhakir"
private let brand = Color(red: 0x20 / 255.0, green: 0x49 / 255.0, blue: 0x7D / 255.0)

private func groupDefaults() -> UserDefaults? { UserDefaults(suiteName: appGroupId) }

private func gstr(_ key: String) -> String { groupDefaults()?.string(forKey: key) ?? "" }

/// home_widget's renderFlutterWidget writes a PNG into the App Group container
/// and stores its FULL PATH under `key`. Load it back for the image widgets.
private func loadWidgetImage(_ key: String) -> UIImage? {
  guard let path = groupDefaults()?.string(forKey: key), !path.isEmpty else { return nil }
  return UIImage(contentsOfFile: path)
}

private extension View {
  // containerBackground is required on iOS 17+ but unavailable before it.
  @ViewBuilder func widgetBackground(_ color: Color) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(color, for: .widget)
    } else {
      background(color)
    }
  }
}

// MARK: - Prayer data (shared by the data-based widgets)

struct PrayerData {
  var nextPrayer: String
  var timeUntilNext: String
  var location: String
  var hijriDate: String
  var nextEpochMillis: Double  // next prayer time, ms since epoch (0 = unknown)
  var times: [(label: String, time: String)]

  static func load() -> PrayerData {
    let nextArabic = gstr("nextPrayerArabic")
    return PrayerData(
      nextPrayer: nextArabic.isEmpty ? gstr("nextPrayer") : nextArabic,
      timeUntilNext: gstr("timeUntilNext"),
      location: gstr("location"),
      hijriDate: gstr("hijri_date"),
      nextEpochMillis: Double(gstr("nextPrayerEpoch")) ?? 0,
      times: [
        ("الفجر", gstr("fajr")),
        ("الظهر", gstr("dhuhr")),
        ("العصر", gstr("asr")),
        ("المغرب", gstr("maghrib")),
        ("العشاء", gstr("isha")),
      ]
    )
  }
}

struct PrayerEntry: TimelineEntry {
  let date: Date
  let data: PrayerData
}

struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry { PrayerEntry(date: Date(), data: .load()) }
  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(PrayerEntry(date: Date(), data: .load()))
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let entry = PrayerEntry(date: Date(), data: .load())
    let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }
}

// MARK: - 1. Prayer Times (next prayer + 5 times)

struct PrayerTimesView: View {
  var entry: PrayerEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
          Text("الصلاة القادمة").font(.caption2).foregroundColor(.secondary)
          Text(entry.data.nextPrayer.isEmpty ? "—" : entry.data.nextPrayer)
            .font(.headline).foregroundColor(brand)
        }
        Spacer(minLength: 4)
        if !entry.data.timeUntilNext.isEmpty {
          Text(entry.data.timeUntilNext).font(.subheadline).bold().foregroundColor(brand)
        }
      }
      if family != .systemSmall {
        Divider()
        HStack(alignment: .top) {
          ForEach(entry.data.times, id: \.label) { item in
            VStack(spacing: 2) {
              Text(item.label).font(.caption2).foregroundColor(.secondary)
              Text(item.time.isEmpty ? "—" : item.time).font(.caption).bold()
            }
            if item.label != "العشاء" { Spacer(minLength: 0) }
          }
        }
      }
      Spacer(minLength: 0)
      if !entry.data.location.isEmpty || !entry.data.hijriDate.isEmpty {
        HStack {
          if !entry.data.hijriDate.isEmpty {
            Text(entry.data.hijriDate).font(.caption2).foregroundColor(.secondary)
          }
          Spacer(minLength: 4)
          if !entry.data.location.isEmpty {
            Text(entry.data.location).font(.caption2).foregroundColor(.secondary).lineLimit(1)
          }
        }
      }
    }
    .environment(\.layoutDirection, .rightToLeft)
    .padding(14)
    .widgetBackground(Color(.systemBackground))
  }
}

struct WadhakirPrayerWidget: Widget {
  let kind = "PrayerTimesWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerProvider()) { PrayerTimesView(entry: $0) }
      .configurationDisplayName("أوقات الصلاة")
      .description("مواقيت الصلاة والصلاة القادمة")
      .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - 2. Prayer Times List (vertical list, highlights next prayer)

struct PrayerListView: View {
  var entry: PrayerEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text("مواقيت الصلاة").font(.subheadline).bold().foregroundColor(brand)
        Spacer()
        if !entry.data.location.isEmpty {
          Text(entry.data.location).font(.caption2).foregroundColor(.secondary).lineLimit(1)
        }
      }
      Divider()
      ForEach(entry.data.times, id: \.label) { item in
        let isNext = !entry.data.nextPrayer.isEmpty && item.label == entry.data.nextPrayer
        HStack {
          Text(item.label).font(.subheadline).fontWeight(isNext ? .bold : .regular)
            .foregroundColor(isNext ? brand : .primary)
          Spacer()
          Text(item.time.isEmpty ? "—" : item.time).font(.subheadline)
            .fontWeight(isNext ? .bold : .regular).foregroundColor(isNext ? brand : .secondary)
        }
      }
    }
    .environment(\.layoutDirection, .rightToLeft)
    .padding(14)
    .widgetBackground(Color(.systemBackground))
  }
}

struct WadhakirPrayerListWidget: Widget {
  let kind = "PrayerTimesListWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerProvider()) { PrayerListView(entry: $0) }
      .configurationDisplayName("قائمة المواقيت")
      .description("قائمة مواقيت الصلوات الخمس")
      .supportedFamilies([.systemMedium, .systemLarge])
  }
}

// MARK: - 3 & 4. Glass image widgets (Flutter-rendered PNGs)

struct ImageEntry: TimelineEntry { let date: Date; let image: UIImage? }

struct ImageProvider: TimelineProvider {
  let key: String
  func placeholder(in context: Context) -> ImageEntry { ImageEntry(date: Date(), image: loadWidgetImage(key)) }
  func getSnapshot(in context: Context, completion: @escaping (ImageEntry) -> Void) {
    completion(ImageEntry(date: Date(), image: loadWidgetImage(key)))
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<ImageEntry>) -> Void) {
    let entry = ImageEntry(date: Date(), image: loadWidgetImage(key))
    let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }
}

struct GlassImageView: View {
  let image: UIImage?
  var body: some View {
    Group {
      if let img = image {
        Image(uiImage: img).resizable().scaledToFill()
      } else {
        VStack(spacing: 6) {
          Image(systemName: "moon.stars.fill").font(.title2).foregroundColor(brand)
          Text("افتح التطبيق لتحديث الودجت").font(.caption2).foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
      }
    }
    .widgetBackground(Color(.systemBackground))
  }
}

struct WadhakirGlassNextWidget: Widget {
  let kind = "GlassPrayerNextWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ImageProvider(key: "glass_prayer_next_image")) {
      GlassImageView(image: $0.image)
    }
    .configurationDisplayName("الصلاة القادمة (زجاجي)")
    .description("بطاقة زجاجية للصلاة القادمة")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct WadhakirGlassDetailWidget: Widget {
  let kind = "GlassPrayerDetailWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ImageProvider(key: "glass_prayer_detail_image")) {
      GlassImageView(image: $0.image)
    }
    .configurationDisplayName("تفاصيل الصلاة (زجاجي)")
    .description("بطاقة زجاجية بتفاصيل المواقيت")
    .supportedFamilies([.systemMedium])
  }
}

// MARK: - 5. Clock (live minute clock + next prayer countdown)

struct ClockProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry { PrayerEntry(date: Date(), data: .load()) }
  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(PrayerEntry(date: Date(), data: .load()))
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    // One entry per minute for the next hour so the clock stays current.
    let data = PrayerData.load()
    let cal = Calendar.current
    // Truncate to the START of the current minute (dateComponents drops the
    // seconds); date(bySetting:) would instead roll forward to the NEXT minute.
    let startMinute = cal.date(
      from: cal.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
    ) ?? Date()
    var entries: [PrayerEntry] = []
    for m in 0..<60 {
      if let d = cal.date(byAdding: .minute, value: m, to: startMinute) {
        entries.append(PrayerEntry(date: d, data: data))
      }
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

struct ClockView: View {
  var entry: PrayerEntry
  var body: some View {
    VStack(spacing: 6) {
      Text(entry.date, style: .time).font(.system(size: 34, weight: .bold, design: .rounded))
        .foregroundColor(brand).minimumScaleFactor(0.6).lineLimit(1)
      countdown
    }
    .environment(\.layoutDirection, .rightToLeft)
    .padding(12)
    .widgetBackground(Color(.systemBackground))
  }

  @ViewBuilder private var countdown: some View {
    let nextDate = Date(timeIntervalSince1970: entry.data.nextEpochMillis / 1000.0)
    if entry.data.nextEpochMillis > 0 && nextDate > entry.date {
      // LIVE countdown (auto-updates every second in the widget) — not the
      // frozen timeUntilNext snapshot, which would stay fixed for the hour.
      HStack(spacing: 4) {
        if !entry.data.nextPrayer.isEmpty {
          Text(entry.data.nextPrayer).font(.caption).foregroundColor(.secondary)
        }
        Text(nextDate, style: .timer)
          .font(.caption).bold().foregroundColor(brand)
          .monospacedDigit().environment(\.layoutDirection, .leftToRight)
      }.lineLimit(1).minimumScaleFactor(0.7)
    } else if !entry.data.nextPrayer.isEmpty {
      Text(entry.data.nextPrayer).font(.caption).foregroundColor(.secondary)
        .lineLimit(1).minimumScaleFactor(0.7)
    }
  }
}

struct WadhakirClockWidget: Widget {
  let kind = "GlassClockWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ClockProvider()) { ClockView(entry: $0) }
      .configurationDisplayName("ساعة الصلاة")
      .description("الساعة والصلاة القادمة")
      .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - 6. Hijri date

struct HijriEntry: TimelineEntry {
  let date: Date
  let hijri: String
  let monthYear: String
  let gregorian: String
}

struct HijriProvider: TimelineProvider {
  private func load() -> HijriEntry {
    HijriEntry(date: Date(), hijri: gstr("hijri_date_display"),
               monthYear: gstr("hijri_month_year"), gregorian: gstr("gregorian_date_display"))
  }
  func placeholder(in context: Context) -> HijriEntry { load() }
  func getSnapshot(in context: Context, completion: @escaping (HijriEntry) -> Void) { completion(load()) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<HijriEntry>) -> Void) {
    // Refresh at the next midnight so the date rolls over.
    let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
    completion(Timeline(entries: [load()], policy: .after(tomorrow)))
  }
}

struct HijriView: View {
  var entry: HijriEntry
  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: "moon.stars.fill").font(.title3).foregroundColor(brand)
      Text(entry.hijri.isEmpty ? "—" : entry.hijri)
        .font(.title3).bold().foregroundColor(brand).multilineTextAlignment(.center)
      if !entry.monthYear.isEmpty {
        Text(entry.monthYear).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
      }
      if !entry.gregorian.isEmpty {
        Text(entry.gregorian).font(.caption2).foregroundColor(.secondary)
      }
    }
    .environment(\.layoutDirection, .rightToLeft)
    .padding(12)
    .widgetBackground(Color(.systemBackground))
  }
}

struct WadhakirHijriWidget: Widget {
  let kind = "HijriCalendarWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: HijriProvider()) { HijriView(entry: $0) }
      .configurationDisplayName("التاريخ الهجري")
      .description("التاريخ الهجري والميلادي لليوم")
      .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - Bundle

@main
struct WadhakirWidgetsBundle: WidgetBundle {
  var body: some Widget {
    WadhakirPrayerWidget()
    WadhakirPrayerListWidget()
    WadhakirGlassNextWidget()
    WadhakirGlassDetailWidget()
    WadhakirClockWidget()
    WadhakirHijriWidget()
  }
}
