import 'package:flutter/material.dart';

enum CommandCategory { navigation, settings, generation, tools, help }

class CommandItem {
  const CommandItem({
    required this.id,
    required this.label,
    required this.category,
    this.description,
    this.icon,
    this.shortcut,
    this.route,
    this.onExecute,
  });

  final String id;
  final String label;
  final CommandCategory category;
  final String? description;
  final IconData? icon;
  final String? shortcut;
  final String? route;
  final void Function()? onExecute;
}
