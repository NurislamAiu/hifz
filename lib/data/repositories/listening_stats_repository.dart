import '../hive/hive_boxes.dart';

/// Tracks real listening time per day (accumulated while the player is
/// actively playing) to power the home screen's streak/goal dashboard.
/// Everything is local — no analytics, no backend.
class ListeningStatsRepository {
  String _key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _mondayOf(DateTime d) {
    final day = _dateOnly(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  Future<void> addSeconds(int seconds) async {
    final key = _key(DateTime.now());
    final current = HiveBoxes.stats.get(key) ?? 0;
    await HiveBoxes.stats.put(key, current + seconds);
  }

  int secondsFor(DateTime date) => HiveBoxes.stats.get(_key(date)) ?? 0;

  int get todaySeconds => secondsFor(DateTime.now());

  bool goalMet(DateTime date, {required int goalSeconds}) =>
      secondsFor(date) >= goalSeconds;

  int weekSeconds([DateTime? anyDayInWeek]) {
    final monday = _mondayOf(anyDayInWeek ?? DateTime.now());
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += secondsFor(monday.add(Duration(days: i)));
    }
    return total;
  }

  /// Consecutive days (ending today, or yesterday if today's goal isn't met
  /// yet) where the daily goal was reached.
  int currentStreak({required int goalSeconds}) {
    var streak = 0;
    var day = _dateOnly(DateTime.now());
    if (goalMet(day, goalSeconds: goalSeconds)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    } else {
      day = day.subtract(const Duration(days: 1));
    }
    while (goalMet(day, goalSeconds: goalSeconds)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest streak ever recorded, scanning from the earliest logged day.
  int recordStreak({required int goalSeconds}) {
    final keys = HiveBoxes.stats.keys.cast<String>().toList();
    if (keys.isEmpty) return 0;
    final dates = keys.map(DateTime.parse).toList()..sort();

    var longest = 0;
    var running = 0;
    var day = dates.first;
    final today = _dateOnly(DateTime.now());
    while (!day.isAfter(today)) {
      if (goalMet(day, goalSeconds: goalSeconds)) {
        running++;
        if (running > longest) longest = running;
      } else {
        running = 0;
      }
      day = day.add(const Duration(days: 1));
    }
    return longest;
  }

  /// Goal status for Mon..Sun of the current week.
  /// `true` = goal met, `false` = day passed without meeting goal,
  /// `null` = today still in progress, or a future day.
  List<bool?> weekStatus({required int goalSeconds}) {
    final monday = _mondayOf(DateTime.now());
    final today = _dateOnly(DateTime.now());
    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      if (d.isAtSameMomentAs(today)) {
        return goalMet(d, goalSeconds: goalSeconds) ? true : null;
      }
      if (d.isAfter(today)) return null;
      return goalMet(d, goalSeconds: goalSeconds);
    });
  }

  /// Seconds listened per day for the last [count] days, ending today
  /// (oldest first) — powers the "year overview" heatmap.
  List<int> recentDays(int count) {
    final today = _dateOnly(DateTime.now());
    return List.generate(
      count,
      (i) => secondsFor(today.subtract(Duration(days: count - 1 - i))),
    );
  }

  /// Total number of distinct days with any recorded listening time.
  int get totalDaysListened =>
      HiveBoxes.stats.values.where((seconds) => seconds > 0).length;
}
