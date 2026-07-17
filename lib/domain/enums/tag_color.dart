import 'package:flutter/material.dart';

enum TagColor {
  red('Red', Colors.red),
  orange('Orange', Colors.orange),
  yellow('Yellow', Colors.yellow),
  green('Green', Colors.green),
  blue('Blue', Colors.blue),
  purple('Purple', Colors.purple),
  pink('Pink', Colors.pink),
  teal('Teal', Colors.teal),
  gray('Gray', Colors.grey),
  brown('Brown', Colors.brown);

  const TagColor(this.label, this.color);
  final String label;
  final Color color;
}
