import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class RecentPatientActivity {
  final String matricula;
  final String nombreCompleto;
  final String areaResponsable;
  final String accion;
  final DateTime occurredAt;

  const RecentPatientActivity({
    required this.matricula,
    required this.nombreCompleto,
    required this.areaResponsable,
    required this.accion,
    required this.occurredAt,
  });

  factory RecentPatientActivity.fromJson(Map<String, dynamic> json) {
    return RecentPatientActivity(
      matricula: (json['matricula'] ?? '').toString(),
      nombreCompleto: (json['nombreCompleto'] ?? '').toString(),
      areaResponsable: (json['areaResponsable'] ?? '').toString(),
      accion: (json['accion'] ?? '').toString(),
      occurredAt: DateTime.tryParse((json['occurredAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'matricula': matricula,
        'nombreCompleto': nombreCompleto,
        'areaResponsable': areaResponsable,
        'accion': accion,
        'occurredAt': occurredAt.toIso8601String(),
      };
}

class RecentNoteActivity {
  final String noteId;
  final String matricula;
  final String nombreEstudiante;
  final String departamento;
  final String diagnosticoResumen;
  final bool synced;
  final DateTime occurredAt;

  const RecentNoteActivity({
    required this.noteId,
    required this.matricula,
    required this.nombreEstudiante,
    required this.departamento,
    required this.diagnosticoResumen,
    required this.synced,
    required this.occurredAt,
  });

  factory RecentNoteActivity.fromJson(Map<String, dynamic> json) {
    return RecentNoteActivity(
      noteId: (json['noteId'] ?? '').toString(),
      matricula: (json['matricula'] ?? '').toString(),
      nombreEstudiante: (json['nombreEstudiante'] ?? '').toString(),
      departamento: (json['departamento'] ?? '').toString(),
      diagnosticoResumen: (json['diagnosticoResumen'] ?? '').toString(),
      synced: json['synced'] == true,
      occurredAt: DateTime.tryParse((json['occurredAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'noteId': noteId,
        'matricula': matricula,
        'nombreEstudiante': nombreEstudiante,
        'departamento': departamento,
        'diagnosticoResumen': diagnosticoResumen,
        'synced': synced,
        'occurredAt': occurredAt.toIso8601String(),
      };
}

class RecentActivityService {
  static const int _maxStoredItems = 20;
  static const int maxVisibleItems = 5;

  static Future<void> recordPatientActivity({
    required AuthUser user,
    required String matricula,
    required String nombreCompleto,
    required String areaResponsable,
    required String accion,
  }) async {
    try {
      final cleanMatricula = matricula.trim();
      if (cleanMatricula.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final key = _patientsKey(user);
      final items = await _getAllRecentPatients(user);

      final updated = <RecentPatientActivity>[
        RecentPatientActivity(
          matricula: cleanMatricula,
          nombreCompleto: _fallback(nombreCompleto, 'Sin nombre'),
          areaResponsable: _fallback(areaResponsable, 'SASU'),
          accion: _fallback(accion, 'attended'),
          occurredAt: DateTime.now(),
        ),
        ...items.where((item) => item.matricula.trim() != cleanMatricula),
      ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

      await prefs.setString(
        key,
        jsonEncode(
          updated.take(_maxStoredItems).map((item) => item.toJson()).toList(),
        ),
      );
    } catch (e, st) {
      debugPrint('RecentActivityService.recordPatientActivity failed: $e\n$st');
    }
  }

  static Future<void> recordNoteActivity({
    required AuthUser user,
    required String noteId,
    required String matricula,
    required String nombreEstudiante,
    required String departamento,
    required String diagnosticoResumen,
    required bool synced,
  }) async {
    try {
      final cleanMatricula = matricula.trim();
      if (cleanMatricula.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final key = _notesKey(user);
      final items = await _getAllRecentNotes(user);
      final cleanNoteId =
          _fallback(noteId, 'local_${DateTime.now().toIso8601String()}');
      RecentNoteActivity? previousItem;
      for (final item in items) {
        if (item.noteId.trim() == cleanNoteId) {
          previousItem = item;
          break;
        }
      }

      final updated = <RecentNoteActivity>[
        RecentNoteActivity(
          noteId: cleanNoteId,
          matricula: cleanMatricula,
          nombreEstudiante: _fallback(nombreEstudiante, 'Sin nombre'),
          departamento: _fallback(departamento, 'Atención'),
          diagnosticoResumen: _fallback(diagnosticoResumen, 'Sin diagnóstico'),
          synced: synced,
          occurredAt: previousItem?.occurredAt ?? DateTime.now(),
        ),
        ...items.where((item) => item.noteId.trim() != cleanNoteId),
      ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

      await prefs.setString(
        key,
        jsonEncode(
          updated.take(_maxStoredItems).map((item) => item.toJson()).toList(),
        ),
      );
    } catch (e, st) {
      debugPrint('RecentActivityService.recordNoteActivity failed: $e\n$st');
    }
  }

  static Future<List<RecentPatientActivity>> getRecentPatients(
    AuthUser user,
  ) async {
    try {
      return (await _getAllRecentPatients(user)).take(maxVisibleItems).toList();
    } catch (e, st) {
      debugPrint('RecentActivityService.getRecentPatients failed: $e\n$st');
      return const [];
    }
  }

  static Future<List<RecentNoteActivity>> getRecentNotes(AuthUser user) async {
    try {
      return (await _getAllRecentNotes(user)).take(maxVisibleItems).toList();
    } catch (e, st) {
      debugPrint('RecentActivityService.getRecentNotes failed: $e\n$st');
      return const [];
    }
  }

  static Future<List<RecentPatientActivity>> _getAllRecentPatients(
    AuthUser user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(
      prefs.getString(_patientsKey(user)),
      RecentPatientActivity.fromJson,
    ).take(_maxStoredItems).toList();
  }

  static Future<List<RecentNoteActivity>> _getAllRecentNotes(
    AuthUser user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeList(
      prefs.getString(_notesKey(user)),
      RecentNoteActivity.fromJson,
    ).take(_maxStoredItems).toList();
  }

  static List<T> _decodeList<T>(
    String? encoded,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (encoded == null || encoded.trim().isEmpty) return const [];
    final decoded = jsonDecode(encoded);
    if (decoded is! List) return const [];

    final items = decoded
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) {
        final aDate = _dateOf(a);
        final bDate = _dateOf(b);
        return bDate.compareTo(aDate);
      });
    return items;
  }

  static DateTime _dateOf(Object? item) {
    if (item is RecentPatientActivity) return item.occurredAt;
    if (item is RecentNoteActivity) return item.occurredAt;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _patientsKey(AuthUser user) {
    return 'recent_patients_v1_${_userKeyPart(user)}_${user.campus}';
  }

  static String _notesKey(AuthUser user) {
    return 'recent_notes_v1_${_userKeyPart(user)}_${user.campus}';
  }

  static String _userKeyPart(AuthUser user) {
    final id = user.id.trim();
    if (id.isNotEmpty) return id;
    final username = user.username.trim();
    return username.isEmpty ? 'unknown_user' : username;
  }

  static String _fallback(String value, String fallback) {
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }
}
