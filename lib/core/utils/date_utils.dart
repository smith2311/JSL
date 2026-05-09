import 'package:intl/intl.dart';

class DateUtilsHelper {
  /// Converts a raw date string like "2025-09-19" or "19/09/2025"
  /// into a human-readable format like "19 Sept 2025".
  static String formatDate(String rawDate) {
    try {
      DateTime parsed;

      if (rawDate.contains("-")) {
        // Format: yyyy-MM-dd
        parsed = DateTime.parse(rawDate);
      } else if (rawDate.contains("/")) {
        // Format: dd/MM/yyyy
        final parts = rawDate.split("/");
        parsed = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } else {
        return rawDate; // Unrecognized format, return as-is
      }

      return DateFormat("dd MMM yyyy").format(parsed);
    } catch (_) {
      return rawDate; // fallback if parsing fails
    }
  }
}