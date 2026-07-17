import 'package:securepass_pro/domain/enums/notification_type.dart';
import 'package:securepass_pro/domain/enums/notification_priority.dart';

class NotificationAction {
  NotificationAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final void Function() onPressed;
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.actions = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final List<NotificationAction> actions;
  final DateTime timestamp;
}
