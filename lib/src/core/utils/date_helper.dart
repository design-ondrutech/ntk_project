class DateHelper {
  static DateTime parseUtcToLocal(String dt) {
    try {
      final epoch = int.tryParse(dt);
      if (epoch != null) {
        return epoch > 9999999999
            ? DateTime.fromMillisecondsSinceEpoch(epoch).toLocal()
            : DateTime.fromMillisecondsSinceEpoch(epoch * 1000).toLocal();
      }
      
      String cleanDt = dt.trim();
      if (!cleanDt.endsWith('Z') && !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(cleanDt)) {
        if (cleanDt.contains(' ')) {
          cleanDt = cleanDt.replaceFirst(' ', 'T');
        }
        cleanDt = '${cleanDt}Z';
      }
      return DateTime.parse(cleanDt).toLocal();
    } catch (_) {
      try {
        return DateTime.parse(dt).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  static String formatDateTime(String? dt) {
    if (dt == null || dt.isEmpty) return '—';
    try {
      final date = parseUtcToLocal(dt);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final ampm = date.hour < 12 ? 'AM' : 'PM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $ampm';
    } catch (_) {
      return dt;
    }
  }
}
