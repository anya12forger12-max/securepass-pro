import 'package:flutter/widgets.dart';

enum LayoutType { mobile, tablet, desktop, wide }

class LayoutBreakpoints {
  const LayoutBreakpoints({this.mobile = 600, this.tablet = 1024, this.desktop = 1440});
  final double mobile;
  final double tablet;
  final double desktop;

  LayoutType getType(double width) {
    if (width < mobile) return LayoutType.mobile;
    if (width < tablet) return LayoutType.tablet;
    if (width < desktop) return LayoutType.desktop;
    return LayoutType.wide;
  }
}

class ComponentRegistration {
  const ComponentRegistration({
    required this.id,
    required this.name,
    required this.builder,
    this.supportedLayouts = const {LayoutType.mobile, LayoutType.tablet, LayoutType.desktop, LayoutType.wide},
    this.priority = 0,
  });

  final String id;
  final String name;
  final Widget Function(BuildContext context, LayoutType layout) builder;
  final Set<LayoutType> supportedLayouts;
  final int priority;
}

class UIPlatform {
  UIPlatform._();
  static final UIPlatform instance = UIPlatform._();

  final LayoutBreakpoints _breakpoints = const LayoutBreakpoints();
  final Map<String, ComponentRegistration> _components = {};
  LayoutType _currentLayout = LayoutType.desktop;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
  }

  void registerComponent(ComponentRegistration component) {
    _components[component.id] = component;
  }

  void unregisterComponent(String componentId) {
    _components.remove(componentId);
  }

  Widget? buildComponent(String componentId, BuildContext context) {
    final component = _components[componentId];
    if (component == null) return null;
    if (!component.supportedLayouts.contains(_currentLayout)) return null;
    return component.builder(context, _currentLayout);
  }

  void updateLayout(double width) {
    _currentLayout = _breakpoints.getType(width);
  }

  LayoutType get currentLayout => _currentLayout;
  LayoutBreakpoints get breakpoints => _breakpoints;
  int get componentCount => _components.length;
  List<ComponentRegistration> getComponentsForLayout(LayoutType layout) {
    return _components.values
        .where((c) => c.supportedLayouts.contains(layout))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'currentLayout': _currentLayout.name,
      'registeredComponents': _components.length,
      'breakpoints': {
        'mobile': _breakpoints.mobile,
        'tablet': _breakpoints.tablet,
        'desktop': _breakpoints.desktop,
      },
    };
  }
}
