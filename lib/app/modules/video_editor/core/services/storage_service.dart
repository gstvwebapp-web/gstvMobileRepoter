import 'package:get_storage/get_storage.dart';
import '../config/app_config.dart';

/// Thin persistence layer over [GetStorage].
///
/// `GetStorage` boxes must be initialised (`GetStorage.init(boxName)`)
/// before use — this happens once in `main()` for each box name declared in
/// [AppConfig]. Every other part of the app talks to this service instead
/// of touching `GetStorage` directly, which keeps box names from leaking
/// across the codebase.
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  late final GetStorage _settingsBox;
  late final GetStorage _projectsBox;
  late final GetStorage _recentFilesBox;

  bool _initialized = false;

  static Future<void> initBoxes() async {
    await GetStorage.init(AppConfig.storageBoxSettings);
    await GetStorage.init(AppConfig.storageBoxProjects);
    await GetStorage.init(AppConfig.storageBoxRecentFiles);
  }

  void bindBoxes() {
    if (_initialized) return;
    _settingsBox = GetStorage(AppConfig.storageBoxSettings);
    _projectsBox = GetStorage(AppConfig.storageBoxProjects);
    _recentFilesBox = GetStorage(AppConfig.storageBoxRecentFiles);
    _initialized = true;
  }

  // ---- Settings ----
  bool get isDarkMode => _settingsBox.read<bool>('is_dark_mode') ?? false;
  set isDarkMode(bool value) => _settingsBox.write('is_dark_mode', value);

  bool get onboardingComplete =>
      _settingsBox.read<bool>('onboarding_complete') ?? false;
  set onboardingComplete(bool value) =>
      _settingsBox.write('onboarding_complete', value);

  bool get permissionsGranted =>
      _settingsBox.read<bool>('permissions_granted') ?? false;
  set permissionsGranted(bool value) =>
      _settingsBox.write('permissions_granted', value);

  // ---- Projects (raw JSON map keyed by project id) ----
  Map<String, dynamic> get allProjects =>
      Map<String, dynamic>.from(_projectsBox.getKeys().fold(
        <String, dynamic>{},
        (map, key) => map..[key] = _projectsBox.read(key),
      ));

  void saveProjectJson(String projectId, Map<String, dynamic> json) =>
      _projectsBox.write(projectId, json);

  Map<String, dynamic>? readProjectJson(String projectId) =>
      _projectsBox.read<Map<String, dynamic>>(projectId);

  void deleteProject(String projectId) => _projectsBox.remove(projectId);

  // ---- Recent imported files (list of file paths, most recent first) ----
  List<String> get recentFiles =>
      (_recentFilesBox.read<List>('paths') ?? []).cast<String>();

  void pushRecentFile(String path) {
    final current = recentFiles;
    current.remove(path);
    current.insert(0, path);
    _recentFilesBox.write('paths', current.take(20).toList());
  }
}
