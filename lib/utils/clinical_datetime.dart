import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ClinicalDateTime {
  static DateTime nowUtc() => DateTime.now().toUtc();

  static DateTime toUtc(DateTime value) => value.toUtc();

  static String toUtcIsoString(DateTime value) =>
      toUtc(value).toIso8601String();

  static DateTime? toDisplayLocal(
    dynamic value, {
    bool assumeUtcIfUnzonedDateTime = false,
  }) {
    final instant = _parseClinicalInstant(
      value,
      assumeUtcIfUnzonedDateTime: assumeUtcIfUnzonedDateTime,
    );
    return instant?.toLocal();
  }

  static DateTime? toUtcForStorage(
    dynamic value, {
    bool assumeUtcIfUnzonedDateTime = false,
  }) {
    final instant = _parseClinicalInstant(
      value,
      assumeUtcIfUnzonedDateTime: assumeUtcIfUnzonedDateTime,
    );
    return instant?.toUtc();
  }

  static DateTime? _parseClinicalInstant(
    dynamic value, {
    bool assumeUtcIfUnzonedDateTime = false,
  }) {
    if (value == null) return null;
    if (value is DateTime) {
      if (value.isUtc) return value;
      if (!assumeUtcIfUnzonedDateTime) return value.toLocal();
      return DateTime.utc(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second,
        value.millisecond,
        value.microsecond,
      );
    }

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    try {
      final normalized = _hasExplicitTimeZone(text) ? text : '${text}Z';
      return DateTime.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  static DateTime utcFromStoredUtc(DateTime value) {
    return value.toUtc();
  }

  static DateTime? localFromStoredUtc(DateTime? value) {
    return toDisplayLocal(value);
  }

  static String storedUtcIsoString(DateTime value) =>
      toUtcIsoStringWithZone(value);

  static String toUtcIsoStringWithZone(DateTime value) =>
      toUtcForStorage(value)?.toIso8601String() ??
      value.toUtc().toIso8601String();

  static bool isStableClientNoteId(String? clientId) =>
      (clientId ?? '').trim().startsWith('nota:');

  static DateTime? localForStoredClinicalNote(
    DateTime? value, {
    String? clientId,
  }) {
    return toDisplayLocal(value, assumeUtcIfUnzonedDateTime: true);
  }

  static DateTime? utcForStoredClinicalNote(
    DateTime? value, {
    String? clientId,
  }) {
    return toUtcForStorage(value, assumeUtcIfUnzonedDateTime: true);
  }

  static void debugLog(String message) {
    if (kDebugMode) debugPrint(message);
  }

  static bool isSameClinicalMoment(
    DateTime a,
    DateTime b, {
    int toleranceSeconds = 90,
  }) {
    final diffSeconds = a.toUtc().difference(b.toUtc()).inSeconds.abs();
    if (diffSeconds <= toleranceSeconds) return true;

    final offsetSeconds = DateTime.now().timeZoneOffset.inSeconds.abs();
    if (offsetSeconds == 0) return false;

    return (diffSeconds - offsetSeconds).abs() <= toleranceSeconds;
  }

  static DateTime? parseServerValue(dynamic value) {
    return toDisplayLocal(value);
  }

  static bool _hasExplicitTimeZone(String value) {
    return RegExp(r'(Z|z|[+-]\d{2}:?\d{2})$').hasMatch(value.trim());
  }

  static String formatLocal(
    DateTime? value, {
    String pattern = 'yyyy-MM-dd HH:mm',
  }) {
    return formatDisplayLocal(value, pattern: pattern);
  }

  static String formatDisplayLocal(
    dynamic value, {
    String pattern = 'yyyy-MM-dd HH:mm',
    bool assumeUtcIfUnzonedDateTime = false,
  }) {
    final parsed = toDisplayLocal(
      value,
      assumeUtcIfUnzonedDateTime: assumeUtcIfUnzonedDateTime,
    );
    if (parsed == null) return value?.toString() ?? '-';
    return DateFormat(pattern).format(parsed);
  }

  static String formatServerValue(
    dynamic value, {
    String pattern = 'yyyy-MM-dd HH:mm',
  }) {
    return formatDisplayLocal(value, pattern: pattern);
  }
}
