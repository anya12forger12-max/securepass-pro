import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class PluginMetadata {
  const PluginMetadata({
    required this.id,
    required this.name,
    required this.version,
    this.description = '',
    this.author = '',
    this.isEnabled = false,
    this.permissions = const [],
  });

  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final bool isEnabled;
  final List<String> permissions;
}

class PluginService {
  PluginService._();
  static final PluginService _instance = PluginService._();
  static PluginService get instance => _instance;

  bool _initialized = false;
  final Map<String, PluginMetadata> _plugins = {};

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    AppLogger.instance.info('Plugin service initialized', category: 'PLUGIN');
  }

  void registerPlugin(PluginMetadata plugin) {
    _plugins[plugin.id] = plugin;
    AppLogger.instance.info('Plugin registered: ${plugin.name} v${plugin.version}', category: 'PLUGIN');
  }

  void unregisterPlugin(String id) {
    _plugins.remove(id);
    AppLogger.instance.info('Plugin unregistered: $id', category: 'PLUGIN');
  }

  List<PluginMetadata> getPlugins() => List.unmodifiable(_plugins.values);

  List<PluginMetadata> getEnabledPlugins() {
    return _plugins.values.where((p) => p.isEnabled).toList();
  }

  bool validatePlugin(String id) {
    final plugin = _plugins[id];
    if (plugin == null) return false;
    if (plugin.id.isEmpty || plugin.name.isEmpty || plugin.version.isEmpty) return false;
    return true;
  }

  Map<String, dynamic> getPluginDiagnostics() {
    final total = _plugins.length;
    final enabled = _plugins.values.where((p) => p.isEnabled).length;
    final disabled = total - enabled;
    final valid = _plugins.keys.where(validatePlugin).length;

    return {
      'totalPlugins': total,
      'enabledPlugins': enabled,
      'disabledPlugins': disabled,
      'validPlugins': valid,
      'invalidPlugins': total - valid,
      'pluginNames': _plugins.values.map((p) => '${p.name} v${p.version}').toList(),
    };
  }

  void enablePlugin(String id) {
    final plugin = _plugins[id];
    if (plugin == null) {
      AppLogger.instance.warning('Plugin not found: $id', category: 'PLUGIN');
      return;
    }
    _plugins[id] = PluginMetadata(
      id: plugin.id,
      name: plugin.name,
      version: plugin.version,
      description: plugin.description,
      author: plugin.author,
      isEnabled: true,
      permissions: plugin.permissions,
    );
    AppLogger.instance.info('Plugin enabled: ${plugin.name}', category: 'PLUGIN');
  }

  void disablePlugin(String id) {
    final plugin = _plugins[id];
    if (plugin == null) {
      AppLogger.instance.warning('Plugin not found: $id', category: 'PLUGIN');
      return;
    }
    _plugins[id] = PluginMetadata(
      id: plugin.id,
      name: plugin.name,
      version: plugin.version,
      description: plugin.description,
      author: plugin.author,
      isEnabled: false,
      permissions: plugin.permissions,
    );
    AppLogger.instance.info('Plugin disabled: ${plugin.name}', category: 'PLUGIN');
  }

  PluginMetadata? getPlugin(String id) => _plugins[id];
}
