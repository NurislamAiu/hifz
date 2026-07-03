import 'package:path_provider/path_provider.dart';

/// Resolves the app's documents directory once at startup and caches it as a
/// plain string, so code that needs a file path synchronously (e.g. the
/// download-status checks feeding the surah list UI) doesn't need to await
/// `path_provider` on every call.
abstract final class AppPaths {
  static late final String documentsPath;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    documentsPath = dir.path;
  }
}
