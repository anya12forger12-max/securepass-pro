extension DateTimeExtensions on DateTime {
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.isNegative) {
      final absDiff = difference.abs();
      if (absDiff.inSeconds < 60) return 'just now';
      if (absDiff.inMinutes < 60) return 'in ${absDiff.inMinutes}m';
      if (absDiff.inHours < 24) return 'in ${absDiff.inHours}h';
      if (absDiff.inDays < 7) return 'in ${absDiff.inDays}d';
      if (absDiff.inDays < 30) return 'in ${absDiff.inDays ~/ 7}w';
      if (absDiff.inDays < 365) return 'in ${absDiff.inDays ~/ 30}mo';
      return 'in ${absDiff.inDays ~/ 365}y';
    }

    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${difference.inDays ~/ 7}w ago';
    if (difference.inDays < 365) return '${difference.inDays ~/ 30}mo ago';
    return '${difference.inDays ~/ 365}y ago';
  }

  String toFormattedDate() {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  String toFormattedDateTime() {
    return '$toFormattedDate ${toFormattedTime()}';
  }

  String toFormattedTime() {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  String toFormattedTime12() {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour < 12 ? 'AM' : 'PM';
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String toFriendlyDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(year, month, day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    if (diff > 1 && diff < 7) return _dayName();
    return toFormattedDate();
  }

  String _dayName() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String toMonthYear() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month - 1]} $year';
  }

  String toShortMonthDay() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[month - 1]} $day';
  }

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfWeek {
    final dayOfWeek = weekday;
    return subtract(Duration(days: dayOfWeek - 1)).startOfDay;
  }

  DateTime get endOfWeek {
    return startOfWeek.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
  }

  DateTime get startOfMonth => DateTime(year, month);

  DateTime get endOfMonth {
    if (month == 12) return DateTime(year + 1, 1).subtract(const Duration(days: 1));
    return DateTime(year, month + 1).subtract(const Duration(days: 1));
  }

  DateTime get startOfYear => DateTime(year);

  DateTime get endOfYear => DateTime(year + 1).subtract(const Duration(days: 1));

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  bool get isThisWeek {
    return isAfter(startOfWeek) && isBefore(endOfWeek);
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  bool get isThisYear {
    return year == DateTime.now().year;
  }

  bool get isPast => isBefore(DateTime.now());

  bool get isFuture => isAfter(DateTime.now());

  bool get isNow {
    final now = DateTime.now();
    return year == now.year &&
        month == now.month &&
        day == now.day &&
        hour == now.hour &&
        minute == now.minute;
  }

  DateTime copyWithYear({required int year}) => DateTime(year, month, day, hour, minute, second, millisecond, microsecond);

  DateTime copyWithMonth({required int month}) => DateTime(year, month, day, hour, minute, second, millisecond, microsecond);

  DateTime copyWithDay({required int day}) => DateTime(year, month, day, hour, minute, second, millisecond, microsecond);

  Duration get timeSince => DateTime.now().difference(this);

  Duration get timeUntil => difference(DateTime.now());
}
