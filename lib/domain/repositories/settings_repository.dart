abstract class SettingsRepository {
  Future<T?> getValue<T>(String key, {T? defaultValue});
  Future<void> setValue<T>(String key, T value);
  Future<void> remove(String key);
  Future<void> clear();
  Future<Map<String, dynamic>> exportAll();
  Future<void> importAll(Map<String, dynamic> data);
  Future<void> resetToDefaults();
}
