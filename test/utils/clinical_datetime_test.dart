import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:cres_carnets_ibmcloud/utils/clinical_datetime.dart';

void main() {
  group('ClinicalDateTime', () {
    test('renders UTC strings in local clinical time', () {
      final display = ClinicalDateTime.toDisplayLocal('2026-06-16T00:57:00Z');

      expect(display, DateTime.utc(2026, 6, 16, 0, 57).toLocal());

      if (display?.timeZoneOffset == const Duration(hours: -6)) {
        expect(display?.hour, 18);
        expect(DateFormat('hh:mm a').format(display!), '06:57 PM');
      }
    });

    test('renders PRUEBA 9 Cosmos UTC time as Mexico local time', () {
      const cosmosCreatedAt = '2026-06-16T01:16:00Z';
      final display = ClinicalDateTime.toDisplayLocal(cosmosCreatedAt);

      expect(display, DateTime.utc(2026, 6, 16, 1, 16).toLocal());

      if (display?.timeZoneOffset == const Duration(hours: -6)) {
        expect(display?.year, 2026);
        expect(display?.month, 6);
        expect(display?.day, 15);
        expect(display?.hour, 19);
        expect(display?.minute, 16);
        expect(
          ClinicalDateTime.formatDisplayLocal(
            cosmosCreatedAt,
            pattern: 'hh:mm a',
          ),
          '07:16 PM',
        );
      }
    });

    test('renders PRUEBA 9 Drift UTC storage time as Mexico local time', () {
      final driftCreatedAt = DateTime(2026, 6, 16, 1, 23);
      final display = ClinicalDateTime.toDisplayLocal(
        driftCreatedAt,
        assumeUtcIfUnzonedDateTime: true,
      );

      expect(display, DateTime.utc(2026, 6, 16, 1, 23).toLocal());

      if (display?.timeZoneOffset == const Duration(hours: -6)) {
        expect(display?.year, 2026);
        expect(display?.month, 6);
        expect(display?.day, 15);
        expect(display?.hour, 19);
        expect(display?.minute, 23);
        expect(
          ClinicalDateTime.formatDisplayLocal(
            driftCreatedAt,
            pattern: 'hh:mm a',
            assumeUtcIfUnzonedDateTime: true,
          ),
          '07:23 PM',
        );
      }
    });

    test('does not subtract the Mexico offset twice for Drift values', () {
      final utcInstant = DateTime.utc(2026, 6, 16, 0, 57);
      final driftReadValue = utcInstant.toLocal();

      final display = ClinicalDateTime.toDisplayLocal(driftReadValue);
      final storage = ClinicalDateTime.toUtcForStorage(driftReadValue);

      expect(display, driftReadValue);
      expect(storage, utcInstant);

      if (display?.timeZoneOffset == const Duration(hours: -6)) {
        expect(display?.hour, 18);
        expect(DateFormat('hh:mm a').format(display!), '06:57 PM');
      }
    });
  });
}
