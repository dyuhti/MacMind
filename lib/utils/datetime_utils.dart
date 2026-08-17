/// Utility class for handling datetime formatting with IST (Indian Standard Time) timezone support
class DateTimeUtils {
  /// IST timezone (UTC+05:30)
  static const Duration istOffset = Duration(hours: 5, minutes: 30);

  /// Parse ISO 8601 UTC timestamp and convert to IST
  ///
  /// Handles formats like:
  /// - "2024-08-17T14:42:18.123456"
  /// - "2024-08-17T14:42:18"
  ///
  /// Returns formatted IST time string in format: "17/08/2024 20:12:18"
  static String formatISTFromUTC(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) {
      return '—';
    }

    try {
      // Parse the ISO 8601 UTC timestamp
      final dateTime = DateTime.parse(isoTimestamp);
      
      // Check if the timestamp is already timezone-aware or naive
      final utcDateTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
      
      // Convert UTC to IST by adding the offset
      final istDateTime = utcDateTime.add(istOffset);
      
      // Format as DD/MM/YYYY HH:mm:ss
      return '${istDateTime.day.toString().padLeft(2, '0')}/'
             '${istDateTime.month.toString().padLeft(2, '0')}/'
             '${istDateTime.year} '
             '${istDateTime.hour.toString().padLeft(2, '0')}:'
             '${istDateTime.minute.toString().padLeft(2, '0')}:'
             '${istDateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      // If parsing fails, return the original string
      return isoTimestamp;
    }
  }

  /// Parse ISO 8601 UTC timestamp and return just the date in IST
  ///
  /// Returns format: "17/08/2024"
  static String formatISTDateOnly(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) {
      return '—';
    }

    try {
      final dateTime = DateTime.parse(isoTimestamp);
      final utcDateTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
      final istDateTime = utcDateTime.add(istOffset);
      
      return '${istDateTime.day.toString().padLeft(2, '0')}/'
             '${istDateTime.month.toString().padLeft(2, '0')}/'
             '${istDateTime.year}';
    } catch (e) {
      return isoTimestamp;
    }
  }

  /// Parse ISO 8601 UTC timestamp and return just the time in IST
  ///
  /// Returns format: "20:12:18"
  static String formatISTTimeOnly(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) {
      return '—';
    }

    try {
      final dateTime = DateTime.parse(isoTimestamp);
      final utcDateTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
      final istDateTime = utcDateTime.add(istOffset);
      
      return '${istDateTime.hour.toString().padLeft(2, '0')}:'
             '${istDateTime.minute.toString().padLeft(2, '0')}:'
             '${istDateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoTimestamp;
    }
  }

  /// Format DateTime object to IST string
  ///
  /// Returns format: "17/08/2024 20:12:18"
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '—';
    }

    try {
      final utcDateTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
      final istDateTime = utcDateTime.add(istOffset);
      
      return '${istDateTime.day.toString().padLeft(2, '0')}/'
             '${istDateTime.month.toString().padLeft(2, '0')}/'
             '${istDateTime.year} '
             '${istDateTime.hour.toString().padLeft(2, '0')}:'
             '${istDateTime.minute.toString().padLeft(2, '0')}:'
             '${istDateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return '—';
    }
  }

  /// Convert ISO string date and time separately (for backward compatibility with existing parsing)
  ///
  /// Input: "2024-08-17T14:42:18" or "2024-08-17"
  /// Returns: {"date": "17/08/2024", "time": "20:12:18"}
  static Map<String, String> parseDateTimeComponents(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) {
      return {"date": "—", "time": "—"};
    }

    try {
      final dateTime = DateTime.parse(isoTimestamp);
      final utcDateTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
      final istDateTime = utcDateTime.add(istOffset);
      
      final date = '${istDateTime.day.toString().padLeft(2, '0')}/'
                   '${istDateTime.month.toString().padLeft(2, '0')}/'
                   '${istDateTime.year}';
      final time = '${istDateTime.hour.toString().padLeft(2, '0')}:'
                   '${istDateTime.minute.toString().padLeft(2, '0')}:'
                   '${istDateTime.second.toString().padLeft(2, '0')}';
      
      return {"date": date, "time": time};
    } catch (e) {
      return {"date": isoTimestamp.split('T').first, "time": "—"};
    }
  }
}
