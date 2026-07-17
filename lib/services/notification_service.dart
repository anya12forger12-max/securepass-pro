import 'package:securepass_pro/domain/entities/notification_item.dart';
import 'package:securepass_pro/domain/enums/notification_priority.dart';
import 'package:securepass_pro/domain/enums/notification_type.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  bool _initialized = false;
  final List<NotificationItem> _notifications = [];
  final Set<String> _readIds = {};

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    AppLogger.instance.info('Notification service initialized', category: 'NOTIFICATION');
  }

  void show(NotificationItem notification) {
    _notifications.insert(0, notification);
    AppLogger.instance.debug('Notification shown: ${notification.title}', category: 'NOTIFICATION');
  }

  void dismiss(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _readIds.remove(id);
    AppLogger.instance.debug('Notification dismissed: $id', category: 'NOTIFICATION');
  }

  void clear() {
    _notifications.clear();
    _readIds.clear();
    AppLogger.instance.info('All notifications cleared', category: 'NOTIFICATION');
  }

  List<NotificationItem> getNotifications() => List.unmodifiable(_notifications);

  int getUnreadCount() {
    return _notifications.where((n) => !_readIds.contains(n.id)).length;
  }

  void markAsRead(String id) {
    _readIds.add(id);
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      _readIds.add(n.id);
    }
    AppLogger.instance.debug('All notifications marked as read', category: 'NOTIFICATION');
  }

  List<NotificationItem> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  List<NotificationItem> getNotificationsByPriority(NotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  bool isRead(String id) => _readIds.contains(id);

  int get totalCount => _notifications.length;
}
