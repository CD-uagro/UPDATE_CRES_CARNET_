// ignore_for_file: invalid_null_aware_operator, dead_null_aware_expression, unnecessary_null_comparison, unnecessary_non_null_assertion

import 'package:flutter/material.dart';
import '../data/db.dart';
import 'package:cres_carnets_ibmcloud/ui/uagro_widgets.dart';
import '../ui/responsive.dart';

class ListScreen extends StatefulWidget {
  final AppDatabase db;
  const ListScreen({super.key, required this.db});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HealthRecord> _filterRecords(List<HealthRecord> records) {
    if (_searchText.isEmpty) return records;

    final searchLower = _searchText.toLowerCase();
    return records.where((r) {
      final matriculaMatch = r.matricula.toLowerCase().contains(searchLower);
      final nombreMatch = r.nombreCompleto.toLowerCase().contains(searchLower);
      return matriculaMatch || nombreMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Scaffold(
      appBar: uagroAppBar(
          'CRES Carnets', 'Listado de expedientes', null, context, widget.db),
      body: Padding(
        padding: EdgeInsets.fromLTRB(mobile ? 8 : 16, mobile ? 8 : 16,
            mobile ? 8 : 16, mobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ocultar BrandHeader en móvil para ahorrar espacio
            if (!mobile)
              const BrandHeader(
                title: 'CRES Carnets',
                subtitle: 'Expediente de salud universitario',
              ),
            if (!mobile) const SizedBox(height: 16),

            // Campo de búsqueda
            Padding(
              padding: EdgeInsets.only(bottom: mobile ? 8 : 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por matrícula o nombre',
                  hintText: 'Ej: 2021001 o Juan Pérez',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchText = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              ),
            ),

            Expanded(
              child: SectionCard(
                icon: Icons.list_alt_outlined,
                title: 'Expedientes',
                child: StreamBuilder<List<HealthRecord>>(
                  stream: widget.db.select(widget.db.healthRecords).watch(),
                  builder: (context, snap) {
                    final allData = snap.data ?? [];
                    final data = _filterRecords(allData);

                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (data.isEmpty) {
                      return _EmptyState();
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      itemCount: data.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final r = data[i];
                        final cs = Theme.of(context).colorScheme;

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                (r.synced ? cs.primary : cs.secondary)
                                    .withOpacity(.12),
                            child: Icon(
                              r.synced ? Icons.cloud_done : Icons.cloud_off,
                              color: r.synced ? cs.primary : cs.secondary,
                            ),
                          ),
                          title: Text(
                              r.nombreCompleto?.trim().isEmpty == true
                                  ? '—'
                                  : (r.nombreCompleto ?? '—'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'Matrícula: ${r.matricula?.trim().isEmpty == true ? "—" : (r.matricula ?? "—")} · ${r.programa?.trim().isEmpty == true ? "—" : (r.programa ?? "—")}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if ((r.tipoSangre ?? '').isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: cs.primary.withOpacity(.08),
                                    border: Border.all(
                                        color: cs.primary.withOpacity(.22)),
                                  ),
                                  child: Text(
                                    r.tipoSangre!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _RecordDetailSheet(record: r),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío elegante
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: cs.primary.withOpacity(.5)),
          const SizedBox(height: 12),
          Text('No hay registros aún.',
              style: TextStyle(
                  color: cs.onSurface.withOpacity(.7),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Captura tu primer expediente desde la pantalla de formulario.',
            style: TextStyle(color: cs.onSurface.withOpacity(.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Hoja inferior con detalle del registro, usando estilo UAGro
class _RecordDetailSheet extends StatelessWidget {
  final HealthRecord record;
  const _RecordDetailSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),

                // Tarjeta de encabezado con nombre + estado de nube
                SectionCard(
                  icon: Icons.badge_outlined,
                  title: 'Resumen',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                (record.synced ? cs.primary : cs.secondary)
                                    .withOpacity(.12),
                            child: Icon(
                              record.synced
                                  ? Icons.cloud_done
                                  : Icons.cloud_off,
                              color: record.synced ? cs.primary : cs.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (record.nombreCompleto == null ||
                                          record.nombreCompleto!.trim().isEmpty)
                                      ? '—'
                                      : record.nombreCompleto!,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Matrícula: ${record.matricula ?? "—"} · ${record.programa ?? "—"}',
                                  style: TextStyle(
                                      color: cs.onSurface.withOpacity(.7)),
                                ),
                              ],
                            ),
                          ),
                          if ((record.tipoSangre ?? '').isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: cs.primary.withOpacity(.08),
                                border: Border.all(
                                    color: cs.primary.withOpacity(.22)),
                              ),
                              child: Text(
                                record.tipoSangre!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tarjeta con datos generales
                SectionCard(
                  icon: Icons.assignment_ind_outlined,
                  title: 'Datos generales',
                  child: _KVGroup(rows: [
                    _KVP('Matrícula', record.matricula),
                    _KVP('Correo', record.correo),
                    _KVP('Edad', record.edad?.toString()),
                    _KVP('Sexo', record.sexo),
                    _KVP('Categoría', record.categoria),
                    _KVP('Programa', record.programa),
                  ]),
                ),

                const SizedBox(height: 12),

                // Tarjeta con salud y cobertura
                SectionCard(
                  icon: Icons.healing_outlined,
                  title: 'Salud y cobertura',
                  child: _KVGroup(rows: [
                    _KVP('Discapacidad', record.discapacidad),
                    _KVP('Tipo discapacidad', record.tipoDiscapacidad),
                    _KVP('Alergias', record.alergias),
                    _KVP('Tipo de sangre', record.tipoSangre),
                    _KVP('Enfermedad crónica', record.enfermedadCronica),
                    _KVP('Unidad médica', record.unidadMedica),
                    _KVP('N° Afiliación', record.numeroAfiliacion),
                    _KVP('Seguro universitario', record.usoSeguroUniversitario),
                    _KVP('Donante', record.donante),
                  ]),
                ),

                const SizedBox(height: 12),

                // Tarjeta con contacto
                SectionCard(
                  icon: Icons.contact_phone_outlined,
                  title: 'Contacto de emergencia',
                  child: _KVGroup(rows: [
                    _KVP('Teléfono de urgencia', record.emergenciaTelefono),
                    _KVP('Nombre/parentesco/domicilio',
                        record.emergenciaContacto),
                  ]),
                ),

                const SizedBox(height: 12),

                // Tarjeta con notas
                SectionCard(
                  icon: Icons.note_alt_outlined,
                  title: 'Expediente — notas',
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      (record.expedienteNotas == null ||
                              record.expedienteNotas!.trim().isEmpty)
                          ? '—'
                          : record.expedienteNotas!,
                      style: const TextStyle(height: 1.3),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper: grupo llave-valor en columnas alineadas
class _KVGroup extends StatelessWidget {
  final List<_KVP> rows;
  const _KVGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(color: Colors.black.withOpacity(.6));
    return Column(
      children: rows.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 200, child: Text(e.k, style: labelStyle)),
              const SizedBox(width: 8),
              Expanded(child: Text(e.v ?? '—')),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _KVP {
  final String k;
  final String? v;
  _KVP(this.k, this.v);
}
