// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $HealthRecordsTable extends HealthRecords
    with TableInfo<$HealthRecordsTable, HealthRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _matriculaMeta =
      const VerificationMeta('matricula');
  @override
  late final GeneratedColumn<String> matricula = GeneratedColumn<String>(
      'matricula', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nombreCompletoMeta =
      const VerificationMeta('nombreCompleto');
  @override
  late final GeneratedColumn<String> nombreCompleto = GeneratedColumn<String>(
      'nombre_completo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _correoMeta = const VerificationMeta('correo');
  @override
  late final GeneratedColumn<String> correo = GeneratedColumn<String>(
      'correo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _edadMeta = const VerificationMeta('edad');
  @override
  late final GeneratedColumn<int> edad = GeneratedColumn<int>(
      'edad', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sexoMeta = const VerificationMeta('sexo');
  @override
  late final GeneratedColumn<String> sexo = GeneratedColumn<String>(
      'sexo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoriaMeta =
      const VerificationMeta('categoria');
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
      'categoria', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _programaMeta =
      const VerificationMeta('programa');
  @override
  late final GeneratedColumn<String> programa = GeneratedColumn<String>(
      'programa', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _escuelaUnidadAcademicaMeta =
      const VerificationMeta('escuelaUnidadAcademica');
  @override
  late final GeneratedColumn<String> escuelaUnidadAcademica =
      GeneratedColumn<String>('escuela_unidad_academica', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('No especificada'));
  static const VerificationMeta _grupoMeta = const VerificationMeta('grupo');
  @override
  late final GeneratedColumn<String> grupo = GeneratedColumn<String>(
      'grupo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _discapacidadMeta =
      const VerificationMeta('discapacidad');
  @override
  late final GeneratedColumn<String> discapacidad = GeneratedColumn<String>(
      'discapacidad', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tipoDiscapacidadMeta =
      const VerificationMeta('tipoDiscapacidad');
  @override
  late final GeneratedColumn<String> tipoDiscapacidad = GeneratedColumn<String>(
      'tipo_discapacidad', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _alergiasMeta =
      const VerificationMeta('alergias');
  @override
  late final GeneratedColumn<String> alergias = GeneratedColumn<String>(
      'alergias', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tipoSangreMeta =
      const VerificationMeta('tipoSangre');
  @override
  late final GeneratedColumn<String> tipoSangre = GeneratedColumn<String>(
      'tipo_sangre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _enfermedadCronicaMeta =
      const VerificationMeta('enfermedadCronica');
  @override
  late final GeneratedColumn<String> enfermedadCronica =
      GeneratedColumn<String>('enfermedad_cronica', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unidadMedicaMeta =
      const VerificationMeta('unidadMedica');
  @override
  late final GeneratedColumn<String> unidadMedica = GeneratedColumn<String>(
      'unidad_medica', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _numeroAfiliacionMeta =
      const VerificationMeta('numeroAfiliacion');
  @override
  late final GeneratedColumn<String> numeroAfiliacion = GeneratedColumn<String>(
      'numero_afiliacion', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _usoSeguroUniversitarioMeta =
      const VerificationMeta('usoSeguroUniversitario');
  @override
  late final GeneratedColumn<String> usoSeguroUniversitario =
      GeneratedColumn<String>('uso_seguro_universitario', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _donanteMeta =
      const VerificationMeta('donante');
  @override
  late final GeneratedColumn<String> donante = GeneratedColumn<String>(
      'donante', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emergenciaTelefonoMeta =
      const VerificationMeta('emergenciaTelefono');
  @override
  late final GeneratedColumn<String> emergenciaTelefono =
      GeneratedColumn<String>('emergencia_telefono', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emergenciaContactoMeta =
      const VerificationMeta('emergenciaContacto');
  @override
  late final GeneratedColumn<String> emergenciaContacto =
      GeneratedColumn<String>('emergencia_contacto', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expedienteNotasMeta =
      const VerificationMeta('expedienteNotas');
  @override
  late final GeneratedColumn<String> expedienteNotas = GeneratedColumn<String>(
      'expediente_notas', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expedienteAdjuntosMeta =
      const VerificationMeta('expedienteAdjuntos');
  @override
  late final GeneratedColumn<String> expedienteAdjuntos =
      GeneratedColumn<String>('expediente_adjuntos', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        timestamp,
        matricula,
        nombreCompleto,
        correo,
        edad,
        sexo,
        categoria,
        programa,
        escuelaUnidadAcademica,
        grupo,
        discapacidad,
        tipoDiscapacidad,
        alergias,
        tipoSangre,
        enfermedadCronica,
        unidadMedica,
        numeroAfiliacion,
        usoSeguroUniversitario,
        donante,
        emergenciaTelefono,
        emergenciaContacto,
        expedienteNotas,
        expedienteAdjuntos,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_records';
  @override
  VerificationContext validateIntegrity(Insertable<HealthRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('matricula')) {
      context.handle(_matriculaMeta,
          matricula.isAcceptableOrUnknown(data['matricula']!, _matriculaMeta));
    } else if (isInserting) {
      context.missing(_matriculaMeta);
    }
    if (data.containsKey('nombre_completo')) {
      context.handle(
          _nombreCompletoMeta,
          nombreCompleto.isAcceptableOrUnknown(
              data['nombre_completo']!, _nombreCompletoMeta));
    } else if (isInserting) {
      context.missing(_nombreCompletoMeta);
    }
    if (data.containsKey('correo')) {
      context.handle(_correoMeta,
          correo.isAcceptableOrUnknown(data['correo']!, _correoMeta));
    } else if (isInserting) {
      context.missing(_correoMeta);
    }
    if (data.containsKey('edad')) {
      context.handle(
          _edadMeta, edad.isAcceptableOrUnknown(data['edad']!, _edadMeta));
    }
    if (data.containsKey('sexo')) {
      context.handle(
          _sexoMeta, sexo.isAcceptableOrUnknown(data['sexo']!, _sexoMeta));
    }
    if (data.containsKey('categoria')) {
      context.handle(_categoriaMeta,
          categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta));
    }
    if (data.containsKey('programa')) {
      context.handle(_programaMeta,
          programa.isAcceptableOrUnknown(data['programa']!, _programaMeta));
    }
    if (data.containsKey('escuela_unidad_academica')) {
      context.handle(
          _escuelaUnidadAcademicaMeta,
          escuelaUnidadAcademica.isAcceptableOrUnknown(
              data['escuela_unidad_academica']!, _escuelaUnidadAcademicaMeta));
    }
    if (data.containsKey('grupo')) {
      context.handle(
          _grupoMeta, grupo.isAcceptableOrUnknown(data['grupo']!, _grupoMeta));
    }
    if (data.containsKey('discapacidad')) {
      context.handle(
          _discapacidadMeta,
          discapacidad.isAcceptableOrUnknown(
              data['discapacidad']!, _discapacidadMeta));
    }
    if (data.containsKey('tipo_discapacidad')) {
      context.handle(
          _tipoDiscapacidadMeta,
          tipoDiscapacidad.isAcceptableOrUnknown(
              data['tipo_discapacidad']!, _tipoDiscapacidadMeta));
    }
    if (data.containsKey('alergias')) {
      context.handle(_alergiasMeta,
          alergias.isAcceptableOrUnknown(data['alergias']!, _alergiasMeta));
    }
    if (data.containsKey('tipo_sangre')) {
      context.handle(
          _tipoSangreMeta,
          tipoSangre.isAcceptableOrUnknown(
              data['tipo_sangre']!, _tipoSangreMeta));
    }
    if (data.containsKey('enfermedad_cronica')) {
      context.handle(
          _enfermedadCronicaMeta,
          enfermedadCronica.isAcceptableOrUnknown(
              data['enfermedad_cronica']!, _enfermedadCronicaMeta));
    }
    if (data.containsKey('unidad_medica')) {
      context.handle(
          _unidadMedicaMeta,
          unidadMedica.isAcceptableOrUnknown(
              data['unidad_medica']!, _unidadMedicaMeta));
    }
    if (data.containsKey('numero_afiliacion')) {
      context.handle(
          _numeroAfiliacionMeta,
          numeroAfiliacion.isAcceptableOrUnknown(
              data['numero_afiliacion']!, _numeroAfiliacionMeta));
    }
    if (data.containsKey('uso_seguro_universitario')) {
      context.handle(
          _usoSeguroUniversitarioMeta,
          usoSeguroUniversitario.isAcceptableOrUnknown(
              data['uso_seguro_universitario']!, _usoSeguroUniversitarioMeta));
    }
    if (data.containsKey('donante')) {
      context.handle(_donanteMeta,
          donante.isAcceptableOrUnknown(data['donante']!, _donanteMeta));
    }
    if (data.containsKey('emergencia_telefono')) {
      context.handle(
          _emergenciaTelefonoMeta,
          emergenciaTelefono.isAcceptableOrUnknown(
              data['emergencia_telefono']!, _emergenciaTelefonoMeta));
    }
    if (data.containsKey('emergencia_contacto')) {
      context.handle(
          _emergenciaContactoMeta,
          emergenciaContacto.isAcceptableOrUnknown(
              data['emergencia_contacto']!, _emergenciaContactoMeta));
    }
    if (data.containsKey('expediente_notas')) {
      context.handle(
          _expedienteNotasMeta,
          expedienteNotas.isAcceptableOrUnknown(
              data['expediente_notas']!, _expedienteNotasMeta));
    }
    if (data.containsKey('expediente_adjuntos')) {
      context.handle(
          _expedienteAdjuntosMeta,
          expedienteAdjuntos.isAcceptableOrUnknown(
              data['expediente_adjuntos']!, _expedienteAdjuntosMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp']),
      matricula: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matricula'])!,
      nombreCompleto: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}nombre_completo'])!,
      correo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}correo'])!,
      edad: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}edad']),
      sexo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sexo']),
      categoria: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categoria']),
      programa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}programa']),
      escuelaUnidadAcademica: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}escuela_unidad_academica'])!,
      grupo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}grupo'])!,
      discapacidad: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}discapacidad']),
      tipoDiscapacidad: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}tipo_discapacidad']),
      alergias: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}alergias']),
      tipoSangre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo_sangre']),
      enfermedadCronica: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}enfermedad_cronica']),
      unidadMedica: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unidad_medica']),
      numeroAfiliacion: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}numero_afiliacion']),
      usoSeguroUniversitario: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}uso_seguro_universitario']),
      donante: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}donante']),
      emergenciaTelefono: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}emergencia_telefono']),
      emergenciaContacto: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}emergencia_contacto']),
      expedienteNotas: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}expediente_notas']),
      expedienteAdjuntos: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}expediente_adjuntos']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $HealthRecordsTable createAlias(String alias) {
    return $HealthRecordsTable(attachedDatabase, alias);
  }
}

class HealthRecord extends DataClass implements Insertable<HealthRecord> {
  final int id;
  final DateTime? timestamp;
  final String matricula;
  final String nombreCompleto;
  final String correo;
  final int? edad;
  final String? sexo;
  final String? categoria;
  final String? programa;
  final String escuelaUnidadAcademica;
  final String grupo;
  final String? discapacidad;
  final String? tipoDiscapacidad;
  final String? alergias;
  final String? tipoSangre;
  final String? enfermedadCronica;
  final String? unidadMedica;
  final String? numeroAfiliacion;
  final String? usoSeguroUniversitario;
  final String? donante;
  final String? emergenciaTelefono;
  final String? emergenciaContacto;
  final String? expedienteNotas;
  final String? expedienteAdjuntos;
  final bool synced;
  const HealthRecord(
      {required this.id,
      this.timestamp,
      required this.matricula,
      required this.nombreCompleto,
      required this.correo,
      this.edad,
      this.sexo,
      this.categoria,
      this.programa,
      required this.escuelaUnidadAcademica,
      required this.grupo,
      this.discapacidad,
      this.tipoDiscapacidad,
      this.alergias,
      this.tipoSangre,
      this.enfermedadCronica,
      this.unidadMedica,
      this.numeroAfiliacion,
      this.usoSeguroUniversitario,
      this.donante,
      this.emergenciaTelefono,
      this.emergenciaContacto,
      this.expedienteNotas,
      this.expedienteAdjuntos,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || timestamp != null) {
      map['timestamp'] = Variable<DateTime>(timestamp);
    }
    map['matricula'] = Variable<String>(matricula);
    map['nombre_completo'] = Variable<String>(nombreCompleto);
    map['correo'] = Variable<String>(correo);
    if (!nullToAbsent || edad != null) {
      map['edad'] = Variable<int>(edad);
    }
    if (!nullToAbsent || sexo != null) {
      map['sexo'] = Variable<String>(sexo);
    }
    if (!nullToAbsent || categoria != null) {
      map['categoria'] = Variable<String>(categoria);
    }
    if (!nullToAbsent || programa != null) {
      map['programa'] = Variable<String>(programa);
    }
    map['escuela_unidad_academica'] = Variable<String>(escuelaUnidadAcademica);
    map['grupo'] = Variable<String>(grupo);
    if (!nullToAbsent || discapacidad != null) {
      map['discapacidad'] = Variable<String>(discapacidad);
    }
    if (!nullToAbsent || tipoDiscapacidad != null) {
      map['tipo_discapacidad'] = Variable<String>(tipoDiscapacidad);
    }
    if (!nullToAbsent || alergias != null) {
      map['alergias'] = Variable<String>(alergias);
    }
    if (!nullToAbsent || tipoSangre != null) {
      map['tipo_sangre'] = Variable<String>(tipoSangre);
    }
    if (!nullToAbsent || enfermedadCronica != null) {
      map['enfermedad_cronica'] = Variable<String>(enfermedadCronica);
    }
    if (!nullToAbsent || unidadMedica != null) {
      map['unidad_medica'] = Variable<String>(unidadMedica);
    }
    if (!nullToAbsent || numeroAfiliacion != null) {
      map['numero_afiliacion'] = Variable<String>(numeroAfiliacion);
    }
    if (!nullToAbsent || usoSeguroUniversitario != null) {
      map['uso_seguro_universitario'] =
          Variable<String>(usoSeguroUniversitario);
    }
    if (!nullToAbsent || donante != null) {
      map['donante'] = Variable<String>(donante);
    }
    if (!nullToAbsent || emergenciaTelefono != null) {
      map['emergencia_telefono'] = Variable<String>(emergenciaTelefono);
    }
    if (!nullToAbsent || emergenciaContacto != null) {
      map['emergencia_contacto'] = Variable<String>(emergenciaContacto);
    }
    if (!nullToAbsent || expedienteNotas != null) {
      map['expediente_notas'] = Variable<String>(expedienteNotas);
    }
    if (!nullToAbsent || expedienteAdjuntos != null) {
      map['expediente_adjuntos'] = Variable<String>(expedienteAdjuntos);
    }
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  HealthRecordsCompanion toCompanion(bool nullToAbsent) {
    return HealthRecordsCompanion(
      id: Value(id),
      timestamp: timestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(timestamp),
      matricula: Value(matricula),
      nombreCompleto: Value(nombreCompleto),
      correo: Value(correo),
      edad: edad == null && nullToAbsent ? const Value.absent() : Value(edad),
      sexo: sexo == null && nullToAbsent ? const Value.absent() : Value(sexo),
      categoria: categoria == null && nullToAbsent
          ? const Value.absent()
          : Value(categoria),
      programa: programa == null && nullToAbsent
          ? const Value.absent()
          : Value(programa),
      escuelaUnidadAcademica: Value(escuelaUnidadAcademica),
      grupo: Value(grupo),
      discapacidad: discapacidad == null && nullToAbsent
          ? const Value.absent()
          : Value(discapacidad),
      tipoDiscapacidad: tipoDiscapacidad == null && nullToAbsent
          ? const Value.absent()
          : Value(tipoDiscapacidad),
      alergias: alergias == null && nullToAbsent
          ? const Value.absent()
          : Value(alergias),
      tipoSangre: tipoSangre == null && nullToAbsent
          ? const Value.absent()
          : Value(tipoSangre),
      enfermedadCronica: enfermedadCronica == null && nullToAbsent
          ? const Value.absent()
          : Value(enfermedadCronica),
      unidadMedica: unidadMedica == null && nullToAbsent
          ? const Value.absent()
          : Value(unidadMedica),
      numeroAfiliacion: numeroAfiliacion == null && nullToAbsent
          ? const Value.absent()
          : Value(numeroAfiliacion),
      usoSeguroUniversitario: usoSeguroUniversitario == null && nullToAbsent
          ? const Value.absent()
          : Value(usoSeguroUniversitario),
      donante: donante == null && nullToAbsent
          ? const Value.absent()
          : Value(donante),
      emergenciaTelefono: emergenciaTelefono == null && nullToAbsent
          ? const Value.absent()
          : Value(emergenciaTelefono),
      emergenciaContacto: emergenciaContacto == null && nullToAbsent
          ? const Value.absent()
          : Value(emergenciaContacto),
      expedienteNotas: expedienteNotas == null && nullToAbsent
          ? const Value.absent()
          : Value(expedienteNotas),
      expedienteAdjuntos: expedienteAdjuntos == null && nullToAbsent
          ? const Value.absent()
          : Value(expedienteAdjuntos),
      synced: Value(synced),
    );
  }

  factory HealthRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthRecord(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime?>(json['timestamp']),
      matricula: serializer.fromJson<String>(json['matricula']),
      nombreCompleto: serializer.fromJson<String>(json['nombreCompleto']),
      correo: serializer.fromJson<String>(json['correo']),
      edad: serializer.fromJson<int?>(json['edad']),
      sexo: serializer.fromJson<String?>(json['sexo']),
      categoria: serializer.fromJson<String?>(json['categoria']),
      programa: serializer.fromJson<String?>(json['programa']),
      escuelaUnidadAcademica:
          serializer.fromJson<String>(json['escuelaUnidadAcademica']),
      grupo: serializer.fromJson<String>(json['grupo']),
      discapacidad: serializer.fromJson<String?>(json['discapacidad']),
      tipoDiscapacidad: serializer.fromJson<String?>(json['tipoDiscapacidad']),
      alergias: serializer.fromJson<String?>(json['alergias']),
      tipoSangre: serializer.fromJson<String?>(json['tipoSangre']),
      enfermedadCronica:
          serializer.fromJson<String?>(json['enfermedadCronica']),
      unidadMedica: serializer.fromJson<String?>(json['unidadMedica']),
      numeroAfiliacion: serializer.fromJson<String?>(json['numeroAfiliacion']),
      usoSeguroUniversitario:
          serializer.fromJson<String?>(json['usoSeguroUniversitario']),
      donante: serializer.fromJson<String?>(json['donante']),
      emergenciaTelefono:
          serializer.fromJson<String?>(json['emergenciaTelefono']),
      emergenciaContacto:
          serializer.fromJson<String?>(json['emergenciaContacto']),
      expedienteNotas: serializer.fromJson<String?>(json['expedienteNotas']),
      expedienteAdjuntos:
          serializer.fromJson<String?>(json['expedienteAdjuntos']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime?>(timestamp),
      'matricula': serializer.toJson<String>(matricula),
      'nombreCompleto': serializer.toJson<String>(nombreCompleto),
      'correo': serializer.toJson<String>(correo),
      'edad': serializer.toJson<int?>(edad),
      'sexo': serializer.toJson<String?>(sexo),
      'categoria': serializer.toJson<String?>(categoria),
      'programa': serializer.toJson<String?>(programa),
      'escuelaUnidadAcademica':
          serializer.toJson<String>(escuelaUnidadAcademica),
      'grupo': serializer.toJson<String>(grupo),
      'discapacidad': serializer.toJson<String?>(discapacidad),
      'tipoDiscapacidad': serializer.toJson<String?>(tipoDiscapacidad),
      'alergias': serializer.toJson<String?>(alergias),
      'tipoSangre': serializer.toJson<String?>(tipoSangre),
      'enfermedadCronica': serializer.toJson<String?>(enfermedadCronica),
      'unidadMedica': serializer.toJson<String?>(unidadMedica),
      'numeroAfiliacion': serializer.toJson<String?>(numeroAfiliacion),
      'usoSeguroUniversitario':
          serializer.toJson<String?>(usoSeguroUniversitario),
      'donante': serializer.toJson<String?>(donante),
      'emergenciaTelefono': serializer.toJson<String?>(emergenciaTelefono),
      'emergenciaContacto': serializer.toJson<String?>(emergenciaContacto),
      'expedienteNotas': serializer.toJson<String?>(expedienteNotas),
      'expedienteAdjuntos': serializer.toJson<String?>(expedienteAdjuntos),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  HealthRecord copyWith(
          {int? id,
          Value<DateTime?> timestamp = const Value.absent(),
          String? matricula,
          String? nombreCompleto,
          String? correo,
          Value<int?> edad = const Value.absent(),
          Value<String?> sexo = const Value.absent(),
          Value<String?> categoria = const Value.absent(),
          Value<String?> programa = const Value.absent(),
          String? escuelaUnidadAcademica,
          String? grupo,
          Value<String?> discapacidad = const Value.absent(),
          Value<String?> tipoDiscapacidad = const Value.absent(),
          Value<String?> alergias = const Value.absent(),
          Value<String?> tipoSangre = const Value.absent(),
          Value<String?> enfermedadCronica = const Value.absent(),
          Value<String?> unidadMedica = const Value.absent(),
          Value<String?> numeroAfiliacion = const Value.absent(),
          Value<String?> usoSeguroUniversitario = const Value.absent(),
          Value<String?> donante = const Value.absent(),
          Value<String?> emergenciaTelefono = const Value.absent(),
          Value<String?> emergenciaContacto = const Value.absent(),
          Value<String?> expedienteNotas = const Value.absent(),
          Value<String?> expedienteAdjuntos = const Value.absent(),
          bool? synced}) =>
      HealthRecord(
        id: id ?? this.id,
        timestamp: timestamp.present ? timestamp.value : this.timestamp,
        matricula: matricula ?? this.matricula,
        nombreCompleto: nombreCompleto ?? this.nombreCompleto,
        correo: correo ?? this.correo,
        edad: edad.present ? edad.value : this.edad,
        sexo: sexo.present ? sexo.value : this.sexo,
        categoria: categoria.present ? categoria.value : this.categoria,
        programa: programa.present ? programa.value : this.programa,
        escuelaUnidadAcademica:
            escuelaUnidadAcademica ?? this.escuelaUnidadAcademica,
        grupo: grupo ?? this.grupo,
        discapacidad:
            discapacidad.present ? discapacidad.value : this.discapacidad,
        tipoDiscapacidad: tipoDiscapacidad.present
            ? tipoDiscapacidad.value
            : this.tipoDiscapacidad,
        alergias: alergias.present ? alergias.value : this.alergias,
        tipoSangre: tipoSangre.present ? tipoSangre.value : this.tipoSangre,
        enfermedadCronica: enfermedadCronica.present
            ? enfermedadCronica.value
            : this.enfermedadCronica,
        unidadMedica:
            unidadMedica.present ? unidadMedica.value : this.unidadMedica,
        numeroAfiliacion: numeroAfiliacion.present
            ? numeroAfiliacion.value
            : this.numeroAfiliacion,
        usoSeguroUniversitario: usoSeguroUniversitario.present
            ? usoSeguroUniversitario.value
            : this.usoSeguroUniversitario,
        donante: donante.present ? donante.value : this.donante,
        emergenciaTelefono: emergenciaTelefono.present
            ? emergenciaTelefono.value
            : this.emergenciaTelefono,
        emergenciaContacto: emergenciaContacto.present
            ? emergenciaContacto.value
            : this.emergenciaContacto,
        expedienteNotas: expedienteNotas.present
            ? expedienteNotas.value
            : this.expedienteNotas,
        expedienteAdjuntos: expedienteAdjuntos.present
            ? expedienteAdjuntos.value
            : this.expedienteAdjuntos,
        synced: synced ?? this.synced,
      );
  HealthRecord copyWithCompanion(HealthRecordsCompanion data) {
    return HealthRecord(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      matricula: data.matricula.present ? data.matricula.value : this.matricula,
      nombreCompleto: data.nombreCompleto.present
          ? data.nombreCompleto.value
          : this.nombreCompleto,
      correo: data.correo.present ? data.correo.value : this.correo,
      edad: data.edad.present ? data.edad.value : this.edad,
      sexo: data.sexo.present ? data.sexo.value : this.sexo,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      programa: data.programa.present ? data.programa.value : this.programa,
      escuelaUnidadAcademica: data.escuelaUnidadAcademica.present
          ? data.escuelaUnidadAcademica.value
          : this.escuelaUnidadAcademica,
      grupo: data.grupo.present ? data.grupo.value : this.grupo,
      discapacidad: data.discapacidad.present
          ? data.discapacidad.value
          : this.discapacidad,
      tipoDiscapacidad: data.tipoDiscapacidad.present
          ? data.tipoDiscapacidad.value
          : this.tipoDiscapacidad,
      alergias: data.alergias.present ? data.alergias.value : this.alergias,
      tipoSangre:
          data.tipoSangre.present ? data.tipoSangre.value : this.tipoSangre,
      enfermedadCronica: data.enfermedadCronica.present
          ? data.enfermedadCronica.value
          : this.enfermedadCronica,
      unidadMedica: data.unidadMedica.present
          ? data.unidadMedica.value
          : this.unidadMedica,
      numeroAfiliacion: data.numeroAfiliacion.present
          ? data.numeroAfiliacion.value
          : this.numeroAfiliacion,
      usoSeguroUniversitario: data.usoSeguroUniversitario.present
          ? data.usoSeguroUniversitario.value
          : this.usoSeguroUniversitario,
      donante: data.donante.present ? data.donante.value : this.donante,
      emergenciaTelefono: data.emergenciaTelefono.present
          ? data.emergenciaTelefono.value
          : this.emergenciaTelefono,
      emergenciaContacto: data.emergenciaContacto.present
          ? data.emergenciaContacto.value
          : this.emergenciaContacto,
      expedienteNotas: data.expedienteNotas.present
          ? data.expedienteNotas.value
          : this.expedienteNotas,
      expedienteAdjuntos: data.expedienteAdjuntos.present
          ? data.expedienteAdjuntos.value
          : this.expedienteAdjuntos,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthRecord(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('matricula: $matricula, ')
          ..write('nombreCompleto: $nombreCompleto, ')
          ..write('correo: $correo, ')
          ..write('edad: $edad, ')
          ..write('sexo: $sexo, ')
          ..write('categoria: $categoria, ')
          ..write('programa: $programa, ')
          ..write('escuelaUnidadAcademica: $escuelaUnidadAcademica, ')
          ..write('grupo: $grupo, ')
          ..write('discapacidad: $discapacidad, ')
          ..write('tipoDiscapacidad: $tipoDiscapacidad, ')
          ..write('alergias: $alergias, ')
          ..write('tipoSangre: $tipoSangre, ')
          ..write('enfermedadCronica: $enfermedadCronica, ')
          ..write('unidadMedica: $unidadMedica, ')
          ..write('numeroAfiliacion: $numeroAfiliacion, ')
          ..write('usoSeguroUniversitario: $usoSeguroUniversitario, ')
          ..write('donante: $donante, ')
          ..write('emergenciaTelefono: $emergenciaTelefono, ')
          ..write('emergenciaContacto: $emergenciaContacto, ')
          ..write('expedienteNotas: $expedienteNotas, ')
          ..write('expedienteAdjuntos: $expedienteAdjuntos, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        timestamp,
        matricula,
        nombreCompleto,
        correo,
        edad,
        sexo,
        categoria,
        programa,
        escuelaUnidadAcademica,
        grupo,
        discapacidad,
        tipoDiscapacidad,
        alergias,
        tipoSangre,
        enfermedadCronica,
        unidadMedica,
        numeroAfiliacion,
        usoSeguroUniversitario,
        donante,
        emergenciaTelefono,
        emergenciaContacto,
        expedienteNotas,
        expedienteAdjuntos,
        synced
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthRecord &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.matricula == this.matricula &&
          other.nombreCompleto == this.nombreCompleto &&
          other.correo == this.correo &&
          other.edad == this.edad &&
          other.sexo == this.sexo &&
          other.categoria == this.categoria &&
          other.programa == this.programa &&
          other.escuelaUnidadAcademica == this.escuelaUnidadAcademica &&
          other.grupo == this.grupo &&
          other.discapacidad == this.discapacidad &&
          other.tipoDiscapacidad == this.tipoDiscapacidad &&
          other.alergias == this.alergias &&
          other.tipoSangre == this.tipoSangre &&
          other.enfermedadCronica == this.enfermedadCronica &&
          other.unidadMedica == this.unidadMedica &&
          other.numeroAfiliacion == this.numeroAfiliacion &&
          other.usoSeguroUniversitario == this.usoSeguroUniversitario &&
          other.donante == this.donante &&
          other.emergenciaTelefono == this.emergenciaTelefono &&
          other.emergenciaContacto == this.emergenciaContacto &&
          other.expedienteNotas == this.expedienteNotas &&
          other.expedienteAdjuntos == this.expedienteAdjuntos &&
          other.synced == this.synced);
}

class HealthRecordsCompanion extends UpdateCompanion<HealthRecord> {
  final Value<int> id;
  final Value<DateTime?> timestamp;
  final Value<String> matricula;
  final Value<String> nombreCompleto;
  final Value<String> correo;
  final Value<int?> edad;
  final Value<String?> sexo;
  final Value<String?> categoria;
  final Value<String?> programa;
  final Value<String> escuelaUnidadAcademica;
  final Value<String> grupo;
  final Value<String?> discapacidad;
  final Value<String?> tipoDiscapacidad;
  final Value<String?> alergias;
  final Value<String?> tipoSangre;
  final Value<String?> enfermedadCronica;
  final Value<String?> unidadMedica;
  final Value<String?> numeroAfiliacion;
  final Value<String?> usoSeguroUniversitario;
  final Value<String?> donante;
  final Value<String?> emergenciaTelefono;
  final Value<String?> emergenciaContacto;
  final Value<String?> expedienteNotas;
  final Value<String?> expedienteAdjuntos;
  final Value<bool> synced;
  const HealthRecordsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.matricula = const Value.absent(),
    this.nombreCompleto = const Value.absent(),
    this.correo = const Value.absent(),
    this.edad = const Value.absent(),
    this.sexo = const Value.absent(),
    this.categoria = const Value.absent(),
    this.programa = const Value.absent(),
    this.escuelaUnidadAcademica = const Value.absent(),
    this.grupo = const Value.absent(),
    this.discapacidad = const Value.absent(),
    this.tipoDiscapacidad = const Value.absent(),
    this.alergias = const Value.absent(),
    this.tipoSangre = const Value.absent(),
    this.enfermedadCronica = const Value.absent(),
    this.unidadMedica = const Value.absent(),
    this.numeroAfiliacion = const Value.absent(),
    this.usoSeguroUniversitario = const Value.absent(),
    this.donante = const Value.absent(),
    this.emergenciaTelefono = const Value.absent(),
    this.emergenciaContacto = const Value.absent(),
    this.expedienteNotas = const Value.absent(),
    this.expedienteAdjuntos = const Value.absent(),
    this.synced = const Value.absent(),
  });
  HealthRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    required String matricula,
    required String nombreCompleto,
    required String correo,
    this.edad = const Value.absent(),
    this.sexo = const Value.absent(),
    this.categoria = const Value.absent(),
    this.programa = const Value.absent(),
    this.escuelaUnidadAcademica = const Value.absent(),
    this.grupo = const Value.absent(),
    this.discapacidad = const Value.absent(),
    this.tipoDiscapacidad = const Value.absent(),
    this.alergias = const Value.absent(),
    this.tipoSangre = const Value.absent(),
    this.enfermedadCronica = const Value.absent(),
    this.unidadMedica = const Value.absent(),
    this.numeroAfiliacion = const Value.absent(),
    this.usoSeguroUniversitario = const Value.absent(),
    this.donante = const Value.absent(),
    this.emergenciaTelefono = const Value.absent(),
    this.emergenciaContacto = const Value.absent(),
    this.expedienteNotas = const Value.absent(),
    this.expedienteAdjuntos = const Value.absent(),
    this.synced = const Value.absent(),
  })  : matricula = Value(matricula),
        nombreCompleto = Value(nombreCompleto),
        correo = Value(correo);
  static Insertable<HealthRecord> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? matricula,
    Expression<String>? nombreCompleto,
    Expression<String>? correo,
    Expression<int>? edad,
    Expression<String>? sexo,
    Expression<String>? categoria,
    Expression<String>? programa,
    Expression<String>? escuelaUnidadAcademica,
    Expression<String>? grupo,
    Expression<String>? discapacidad,
    Expression<String>? tipoDiscapacidad,
    Expression<String>? alergias,
    Expression<String>? tipoSangre,
    Expression<String>? enfermedadCronica,
    Expression<String>? unidadMedica,
    Expression<String>? numeroAfiliacion,
    Expression<String>? usoSeguroUniversitario,
    Expression<String>? donante,
    Expression<String>? emergenciaTelefono,
    Expression<String>? emergenciaContacto,
    Expression<String>? expedienteNotas,
    Expression<String>? expedienteAdjuntos,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (matricula != null) 'matricula': matricula,
      if (nombreCompleto != null) 'nombre_completo': nombreCompleto,
      if (correo != null) 'correo': correo,
      if (edad != null) 'edad': edad,
      if (sexo != null) 'sexo': sexo,
      if (categoria != null) 'categoria': categoria,
      if (programa != null) 'programa': programa,
      if (escuelaUnidadAcademica != null)
        'escuela_unidad_academica': escuelaUnidadAcademica,
      if (grupo != null) 'grupo': grupo,
      if (discapacidad != null) 'discapacidad': discapacidad,
      if (tipoDiscapacidad != null) 'tipo_discapacidad': tipoDiscapacidad,
      if (alergias != null) 'alergias': alergias,
      if (tipoSangre != null) 'tipo_sangre': tipoSangre,
      if (enfermedadCronica != null) 'enfermedad_cronica': enfermedadCronica,
      if (unidadMedica != null) 'unidad_medica': unidadMedica,
      if (numeroAfiliacion != null) 'numero_afiliacion': numeroAfiliacion,
      if (usoSeguroUniversitario != null)
        'uso_seguro_universitario': usoSeguroUniversitario,
      if (donante != null) 'donante': donante,
      if (emergenciaTelefono != null) 'emergencia_telefono': emergenciaTelefono,
      if (emergenciaContacto != null) 'emergencia_contacto': emergenciaContacto,
      if (expedienteNotas != null) 'expediente_notas': expedienteNotas,
      if (expedienteAdjuntos != null) 'expediente_adjuntos': expedienteAdjuntos,
      if (synced != null) 'synced': synced,
    });
  }

  HealthRecordsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime?>? timestamp,
      Value<String>? matricula,
      Value<String>? nombreCompleto,
      Value<String>? correo,
      Value<int?>? edad,
      Value<String?>? sexo,
      Value<String?>? categoria,
      Value<String?>? programa,
      Value<String>? escuelaUnidadAcademica,
      Value<String>? grupo,
      Value<String?>? discapacidad,
      Value<String?>? tipoDiscapacidad,
      Value<String?>? alergias,
      Value<String?>? tipoSangre,
      Value<String?>? enfermedadCronica,
      Value<String?>? unidadMedica,
      Value<String?>? numeroAfiliacion,
      Value<String?>? usoSeguroUniversitario,
      Value<String?>? donante,
      Value<String?>? emergenciaTelefono,
      Value<String?>? emergenciaContacto,
      Value<String?>? expedienteNotas,
      Value<String?>? expedienteAdjuntos,
      Value<bool>? synced}) {
    return HealthRecordsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      matricula: matricula ?? this.matricula,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correo: correo ?? this.correo,
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      categoria: categoria ?? this.categoria,
      programa: programa ?? this.programa,
      escuelaUnidadAcademica:
          escuelaUnidadAcademica ?? this.escuelaUnidadAcademica,
      grupo: grupo ?? this.grupo,
      discapacidad: discapacidad ?? this.discapacidad,
      tipoDiscapacidad: tipoDiscapacidad ?? this.tipoDiscapacidad,
      alergias: alergias ?? this.alergias,
      tipoSangre: tipoSangre ?? this.tipoSangre,
      enfermedadCronica: enfermedadCronica ?? this.enfermedadCronica,
      unidadMedica: unidadMedica ?? this.unidadMedica,
      numeroAfiliacion: numeroAfiliacion ?? this.numeroAfiliacion,
      usoSeguroUniversitario:
          usoSeguroUniversitario ?? this.usoSeguroUniversitario,
      donante: donante ?? this.donante,
      emergenciaTelefono: emergenciaTelefono ?? this.emergenciaTelefono,
      emergenciaContacto: emergenciaContacto ?? this.emergenciaContacto,
      expedienteNotas: expedienteNotas ?? this.expedienteNotas,
      expedienteAdjuntos: expedienteAdjuntos ?? this.expedienteAdjuntos,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (matricula.present) {
      map['matricula'] = Variable<String>(matricula.value);
    }
    if (nombreCompleto.present) {
      map['nombre_completo'] = Variable<String>(nombreCompleto.value);
    }
    if (correo.present) {
      map['correo'] = Variable<String>(correo.value);
    }
    if (edad.present) {
      map['edad'] = Variable<int>(edad.value);
    }
    if (sexo.present) {
      map['sexo'] = Variable<String>(sexo.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (programa.present) {
      map['programa'] = Variable<String>(programa.value);
    }
    if (escuelaUnidadAcademica.present) {
      map['escuela_unidad_academica'] =
          Variable<String>(escuelaUnidadAcademica.value);
    }
    if (grupo.present) {
      map['grupo'] = Variable<String>(grupo.value);
    }
    if (discapacidad.present) {
      map['discapacidad'] = Variable<String>(discapacidad.value);
    }
    if (tipoDiscapacidad.present) {
      map['tipo_discapacidad'] = Variable<String>(tipoDiscapacidad.value);
    }
    if (alergias.present) {
      map['alergias'] = Variable<String>(alergias.value);
    }
    if (tipoSangre.present) {
      map['tipo_sangre'] = Variable<String>(tipoSangre.value);
    }
    if (enfermedadCronica.present) {
      map['enfermedad_cronica'] = Variable<String>(enfermedadCronica.value);
    }
    if (unidadMedica.present) {
      map['unidad_medica'] = Variable<String>(unidadMedica.value);
    }
    if (numeroAfiliacion.present) {
      map['numero_afiliacion'] = Variable<String>(numeroAfiliacion.value);
    }
    if (usoSeguroUniversitario.present) {
      map['uso_seguro_universitario'] =
          Variable<String>(usoSeguroUniversitario.value);
    }
    if (donante.present) {
      map['donante'] = Variable<String>(donante.value);
    }
    if (emergenciaTelefono.present) {
      map['emergencia_telefono'] = Variable<String>(emergenciaTelefono.value);
    }
    if (emergenciaContacto.present) {
      map['emergencia_contacto'] = Variable<String>(emergenciaContacto.value);
    }
    if (expedienteNotas.present) {
      map['expediente_notas'] = Variable<String>(expedienteNotas.value);
    }
    if (expedienteAdjuntos.present) {
      map['expediente_adjuntos'] = Variable<String>(expedienteAdjuntos.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthRecordsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('matricula: $matricula, ')
          ..write('nombreCompleto: $nombreCompleto, ')
          ..write('correo: $correo, ')
          ..write('edad: $edad, ')
          ..write('sexo: $sexo, ')
          ..write('categoria: $categoria, ')
          ..write('programa: $programa, ')
          ..write('escuelaUnidadAcademica: $escuelaUnidadAcademica, ')
          ..write('grupo: $grupo, ')
          ..write('discapacidad: $discapacidad, ')
          ..write('tipoDiscapacidad: $tipoDiscapacidad, ')
          ..write('alergias: $alergias, ')
          ..write('tipoSangre: $tipoSangre, ')
          ..write('enfermedadCronica: $enfermedadCronica, ')
          ..write('unidadMedica: $unidadMedica, ')
          ..write('numeroAfiliacion: $numeroAfiliacion, ')
          ..write('usoSeguroUniversitario: $usoSeguroUniversitario, ')
          ..write('donante: $donante, ')
          ..write('emergenciaTelefono: $emergenciaTelefono, ')
          ..write('emergenciaContacto: $emergenciaContacto, ')
          ..write('expedienteNotas: $expedienteNotas, ')
          ..write('expedienteAdjuntos: $expedienteAdjuntos, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _matriculaMeta =
      const VerificationMeta('matricula');
  @override
  late final GeneratedColumn<String> matricula = GeneratedColumn<String>(
      'matricula', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _departamentoMeta =
      const VerificationMeta('departamento');
  @override
  late final GeneratedColumn<String> departamento = GeneratedColumn<String>(
      'departamento', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tratanteMeta =
      const VerificationMeta('tratante');
  @override
  late final GeneratedColumn<String> tratante = GeneratedColumn<String>(
      'tratante', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cuerpoMeta = const VerificationMeta('cuerpo');
  @override
  late final GeneratedColumn<String> cuerpo = GeneratedColumn<String>(
      'cuerpo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, matricula, departamento, tratante, cuerpo, createdAt, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<Note> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('matricula')) {
      context.handle(_matriculaMeta,
          matricula.isAcceptableOrUnknown(data['matricula']!, _matriculaMeta));
    } else if (isInserting) {
      context.missing(_matriculaMeta);
    }
    if (data.containsKey('departamento')) {
      context.handle(
          _departamentoMeta,
          departamento.isAcceptableOrUnknown(
              data['departamento']!, _departamentoMeta));
    } else if (isInserting) {
      context.missing(_departamentoMeta);
    }
    if (data.containsKey('tratante')) {
      context.handle(_tratanteMeta,
          tratante.isAcceptableOrUnknown(data['tratante']!, _tratanteMeta));
    }
    if (data.containsKey('cuerpo')) {
      context.handle(_cuerpoMeta,
          cuerpo.isAcceptableOrUnknown(data['cuerpo']!, _cuerpoMeta));
    } else if (isInserting) {
      context.missing(_cuerpoMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      matricula: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matricula'])!,
      departamento: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}departamento'])!,
      tratante: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tratante']),
      cuerpo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cuerpo'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final String matricula;
  final String departamento;
  final String? tratante;
  final String cuerpo;
  final DateTime? createdAt;
  final bool synced;
  const Note(
      {required this.id,
      required this.matricula,
      required this.departamento,
      this.tratante,
      required this.cuerpo,
      this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['matricula'] = Variable<String>(matricula);
    map['departamento'] = Variable<String>(departamento);
    if (!nullToAbsent || tratante != null) {
      map['tratante'] = Variable<String>(tratante);
    }
    map['cuerpo'] = Variable<String>(cuerpo);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      matricula: Value(matricula),
      departamento: Value(departamento),
      tratante: tratante == null && nullToAbsent
          ? const Value.absent()
          : Value(tratante),
      cuerpo: Value(cuerpo),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      synced: Value(synced),
    );
  }

  factory Note.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      matricula: serializer.fromJson<String>(json['matricula']),
      departamento: serializer.fromJson<String>(json['departamento']),
      tratante: serializer.fromJson<String?>(json['tratante']),
      cuerpo: serializer.fromJson<String>(json['cuerpo']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matricula': serializer.toJson<String>(matricula),
      'departamento': serializer.toJson<String>(departamento),
      'tratante': serializer.toJson<String?>(tratante),
      'cuerpo': serializer.toJson<String>(cuerpo),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  Note copyWith(
          {int? id,
          String? matricula,
          String? departamento,
          Value<String?> tratante = const Value.absent(),
          String? cuerpo,
          Value<DateTime?> createdAt = const Value.absent(),
          bool? synced}) =>
      Note(
        id: id ?? this.id,
        matricula: matricula ?? this.matricula,
        departamento: departamento ?? this.departamento,
        tratante: tratante.present ? tratante.value : this.tratante,
        cuerpo: cuerpo ?? this.cuerpo,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        synced: synced ?? this.synced,
      );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      matricula: data.matricula.present ? data.matricula.value : this.matricula,
      departamento: data.departamento.present
          ? data.departamento.value
          : this.departamento,
      tratante: data.tratante.present ? data.tratante.value : this.tratante,
      cuerpo: data.cuerpo.present ? data.cuerpo.value : this.cuerpo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('matricula: $matricula, ')
          ..write('departamento: $departamento, ')
          ..write('tratante: $tratante, ')
          ..write('cuerpo: $cuerpo, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, matricula, departamento, tratante, cuerpo, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.matricula == this.matricula &&
          other.departamento == this.departamento &&
          other.tratante == this.tratante &&
          other.cuerpo == this.cuerpo &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> matricula;
  final Value<String> departamento;
  final Value<String?> tratante;
  final Value<String> cuerpo;
  final Value<DateTime?> createdAt;
  final Value<bool> synced;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.matricula = const Value.absent(),
    this.departamento = const Value.absent(),
    this.tratante = const Value.absent(),
    this.cuerpo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String matricula,
    required String departamento,
    this.tratante = const Value.absent(),
    required String cuerpo,
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  })  : matricula = Value(matricula),
        departamento = Value(departamento),
        cuerpo = Value(cuerpo);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? matricula,
    Expression<String>? departamento,
    Expression<String>? tratante,
    Expression<String>? cuerpo,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matricula != null) 'matricula': matricula,
      if (departamento != null) 'departamento': departamento,
      if (tratante != null) 'tratante': tratante,
      if (cuerpo != null) 'cuerpo': cuerpo,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  NotesCompanion copyWith(
      {Value<int>? id,
      Value<String>? matricula,
      Value<String>? departamento,
      Value<String?>? tratante,
      Value<String>? cuerpo,
      Value<DateTime?>? createdAt,
      Value<bool>? synced}) {
    return NotesCompanion(
      id: id ?? this.id,
      matricula: matricula ?? this.matricula,
      departamento: departamento ?? this.departamento,
      tratante: tratante ?? this.tratante,
      cuerpo: cuerpo ?? this.cuerpo,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matricula.present) {
      map['matricula'] = Variable<String>(matricula.value);
    }
    if (departamento.present) {
      map['departamento'] = Variable<String>(departamento.value);
    }
    if (tratante.present) {
      map['tratante'] = Variable<String>(tratante.value);
    }
    if (cuerpo.present) {
      map['cuerpo'] = Variable<String>(cuerpo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('matricula: $matricula, ')
          ..write('departamento: $departamento, ')
          ..write('tratante: $tratante, ')
          ..write('cuerpo: $cuerpo, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $CitasTable extends Citas with TableInfo<$CitasTable, Cita> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CitasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _matriculaMeta =
      const VerificationMeta('matricula');
  @override
  late final GeneratedColumn<String> matricula = GeneratedColumn<String>(
      'matricula', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inicioMeta = const VerificationMeta('inicio');
  @override
  late final GeneratedColumn<DateTime> inicio = GeneratedColumn<DateTime>(
      'inicio', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _finMeta = const VerificationMeta('fin');
  @override
  late final GeneratedColumn<DateTime> fin = GeneratedColumn<DateTime>(
      'fin', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _motivoMeta = const VerificationMeta('motivo');
  @override
  late final GeneratedColumn<String> motivo = GeneratedColumn<String>(
      'motivo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _departamentoMeta =
      const VerificationMeta('departamento');
  @override
  late final GeneratedColumn<String> departamento = GeneratedColumn<String>(
      'departamento', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
      'estado', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('programada'));
  static const VerificationMeta _googleEventIdMeta =
      const VerificationMeta('googleEventId');
  @override
  late final GeneratedColumn<String> googleEventId = GeneratedColumn<String>(
      'google_event_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _htmlLinkMeta =
      const VerificationMeta('htmlLink');
  @override
  late final GeneratedColumn<String> htmlLink = GeneratedColumn<String>(
      'html_link', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        matricula,
        inicio,
        fin,
        motivo,
        departamento,
        estado,
        googleEventId,
        htmlLink,
        createdAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'citas';
  @override
  VerificationContext validateIntegrity(Insertable<Cita> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('matricula')) {
      context.handle(_matriculaMeta,
          matricula.isAcceptableOrUnknown(data['matricula']!, _matriculaMeta));
    } else if (isInserting) {
      context.missing(_matriculaMeta);
    }
    if (data.containsKey('inicio')) {
      context.handle(_inicioMeta,
          inicio.isAcceptableOrUnknown(data['inicio']!, _inicioMeta));
    } else if (isInserting) {
      context.missing(_inicioMeta);
    }
    if (data.containsKey('fin')) {
      context.handle(
          _finMeta, fin.isAcceptableOrUnknown(data['fin']!, _finMeta));
    } else if (isInserting) {
      context.missing(_finMeta);
    }
    if (data.containsKey('motivo')) {
      context.handle(_motivoMeta,
          motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta));
    } else if (isInserting) {
      context.missing(_motivoMeta);
    }
    if (data.containsKey('departamento')) {
      context.handle(
          _departamentoMeta,
          departamento.isAcceptableOrUnknown(
              data['departamento']!, _departamentoMeta));
    }
    if (data.containsKey('estado')) {
      context.handle(_estadoMeta,
          estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta));
    }
    if (data.containsKey('google_event_id')) {
      context.handle(
          _googleEventIdMeta,
          googleEventId.isAcceptableOrUnknown(
              data['google_event_id']!, _googleEventIdMeta));
    }
    if (data.containsKey('html_link')) {
      context.handle(_htmlLinkMeta,
          htmlLink.isAcceptableOrUnknown(data['html_link']!, _htmlLinkMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cita map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cita(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      matricula: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matricula'])!,
      inicio: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}inicio'])!,
      fin: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fin'])!,
      motivo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motivo'])!,
      departamento: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}departamento']),
      estado: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}estado'])!,
      googleEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}google_event_id']),
      htmlLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}html_link']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $CitasTable createAlias(String alias) {
    return $CitasTable(attachedDatabase, alias);
  }
}

class Cita extends DataClass implements Insertable<Cita> {
  final int id;
  final String matricula;
  final DateTime inicio;
  final DateTime fin;
  final String motivo;
  final String? departamento;
  final String estado;
  final String? googleEventId;
  final String? htmlLink;
  final DateTime? createdAt;
  final bool synced;
  const Cita(
      {required this.id,
      required this.matricula,
      required this.inicio,
      required this.fin,
      required this.motivo,
      this.departamento,
      required this.estado,
      this.googleEventId,
      this.htmlLink,
      this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['matricula'] = Variable<String>(matricula);
    map['inicio'] = Variable<DateTime>(inicio);
    map['fin'] = Variable<DateTime>(fin);
    map['motivo'] = Variable<String>(motivo);
    if (!nullToAbsent || departamento != null) {
      map['departamento'] = Variable<String>(departamento);
    }
    map['estado'] = Variable<String>(estado);
    if (!nullToAbsent || googleEventId != null) {
      map['google_event_id'] = Variable<String>(googleEventId);
    }
    if (!nullToAbsent || htmlLink != null) {
      map['html_link'] = Variable<String>(htmlLink);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  CitasCompanion toCompanion(bool nullToAbsent) {
    return CitasCompanion(
      id: Value(id),
      matricula: Value(matricula),
      inicio: Value(inicio),
      fin: Value(fin),
      motivo: Value(motivo),
      departamento: departamento == null && nullToAbsent
          ? const Value.absent()
          : Value(departamento),
      estado: Value(estado),
      googleEventId: googleEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(googleEventId),
      htmlLink: htmlLink == null && nullToAbsent
          ? const Value.absent()
          : Value(htmlLink),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      synced: Value(synced),
    );
  }

  factory Cita.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cita(
      id: serializer.fromJson<int>(json['id']),
      matricula: serializer.fromJson<String>(json['matricula']),
      inicio: serializer.fromJson<DateTime>(json['inicio']),
      fin: serializer.fromJson<DateTime>(json['fin']),
      motivo: serializer.fromJson<String>(json['motivo']),
      departamento: serializer.fromJson<String?>(json['departamento']),
      estado: serializer.fromJson<String>(json['estado']),
      googleEventId: serializer.fromJson<String?>(json['googleEventId']),
      htmlLink: serializer.fromJson<String?>(json['htmlLink']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matricula': serializer.toJson<String>(matricula),
      'inicio': serializer.toJson<DateTime>(inicio),
      'fin': serializer.toJson<DateTime>(fin),
      'motivo': serializer.toJson<String>(motivo),
      'departamento': serializer.toJson<String?>(departamento),
      'estado': serializer.toJson<String>(estado),
      'googleEventId': serializer.toJson<String?>(googleEventId),
      'htmlLink': serializer.toJson<String?>(htmlLink),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  Cita copyWith(
          {int? id,
          String? matricula,
          DateTime? inicio,
          DateTime? fin,
          String? motivo,
          Value<String?> departamento = const Value.absent(),
          String? estado,
          Value<String?> googleEventId = const Value.absent(),
          Value<String?> htmlLink = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent(),
          bool? synced}) =>
      Cita(
        id: id ?? this.id,
        matricula: matricula ?? this.matricula,
        inicio: inicio ?? this.inicio,
        fin: fin ?? this.fin,
        motivo: motivo ?? this.motivo,
        departamento:
            departamento.present ? departamento.value : this.departamento,
        estado: estado ?? this.estado,
        googleEventId:
            googleEventId.present ? googleEventId.value : this.googleEventId,
        htmlLink: htmlLink.present ? htmlLink.value : this.htmlLink,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        synced: synced ?? this.synced,
      );
  Cita copyWithCompanion(CitasCompanion data) {
    return Cita(
      id: data.id.present ? data.id.value : this.id,
      matricula: data.matricula.present ? data.matricula.value : this.matricula,
      inicio: data.inicio.present ? data.inicio.value : this.inicio,
      fin: data.fin.present ? data.fin.value : this.fin,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      departamento: data.departamento.present
          ? data.departamento.value
          : this.departamento,
      estado: data.estado.present ? data.estado.value : this.estado,
      googleEventId: data.googleEventId.present
          ? data.googleEventId.value
          : this.googleEventId,
      htmlLink: data.htmlLink.present ? data.htmlLink.value : this.htmlLink,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cita(')
          ..write('id: $id, ')
          ..write('matricula: $matricula, ')
          ..write('inicio: $inicio, ')
          ..write('fin: $fin, ')
          ..write('motivo: $motivo, ')
          ..write('departamento: $departamento, ')
          ..write('estado: $estado, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('htmlLink: $htmlLink, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, matricula, inicio, fin, motivo,
      departamento, estado, googleEventId, htmlLink, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cita &&
          other.id == this.id &&
          other.matricula == this.matricula &&
          other.inicio == this.inicio &&
          other.fin == this.fin &&
          other.motivo == this.motivo &&
          other.departamento == this.departamento &&
          other.estado == this.estado &&
          other.googleEventId == this.googleEventId &&
          other.htmlLink == this.htmlLink &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class CitasCompanion extends UpdateCompanion<Cita> {
  final Value<int> id;
  final Value<String> matricula;
  final Value<DateTime> inicio;
  final Value<DateTime> fin;
  final Value<String> motivo;
  final Value<String?> departamento;
  final Value<String> estado;
  final Value<String?> googleEventId;
  final Value<String?> htmlLink;
  final Value<DateTime?> createdAt;
  final Value<bool> synced;
  const CitasCompanion({
    this.id = const Value.absent(),
    this.matricula = const Value.absent(),
    this.inicio = const Value.absent(),
    this.fin = const Value.absent(),
    this.motivo = const Value.absent(),
    this.departamento = const Value.absent(),
    this.estado = const Value.absent(),
    this.googleEventId = const Value.absent(),
    this.htmlLink = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  CitasCompanion.insert({
    this.id = const Value.absent(),
    required String matricula,
    required DateTime inicio,
    required DateTime fin,
    required String motivo,
    this.departamento = const Value.absent(),
    this.estado = const Value.absent(),
    this.googleEventId = const Value.absent(),
    this.htmlLink = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  })  : matricula = Value(matricula),
        inicio = Value(inicio),
        fin = Value(fin),
        motivo = Value(motivo);
  static Insertable<Cita> custom({
    Expression<int>? id,
    Expression<String>? matricula,
    Expression<DateTime>? inicio,
    Expression<DateTime>? fin,
    Expression<String>? motivo,
    Expression<String>? departamento,
    Expression<String>? estado,
    Expression<String>? googleEventId,
    Expression<String>? htmlLink,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matricula != null) 'matricula': matricula,
      if (inicio != null) 'inicio': inicio,
      if (fin != null) 'fin': fin,
      if (motivo != null) 'motivo': motivo,
      if (departamento != null) 'departamento': departamento,
      if (estado != null) 'estado': estado,
      if (googleEventId != null) 'google_event_id': googleEventId,
      if (htmlLink != null) 'html_link': htmlLink,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  CitasCompanion copyWith(
      {Value<int>? id,
      Value<String>? matricula,
      Value<DateTime>? inicio,
      Value<DateTime>? fin,
      Value<String>? motivo,
      Value<String?>? departamento,
      Value<String>? estado,
      Value<String?>? googleEventId,
      Value<String?>? htmlLink,
      Value<DateTime?>? createdAt,
      Value<bool>? synced}) {
    return CitasCompanion(
      id: id ?? this.id,
      matricula: matricula ?? this.matricula,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      motivo: motivo ?? this.motivo,
      departamento: departamento ?? this.departamento,
      estado: estado ?? this.estado,
      googleEventId: googleEventId ?? this.googleEventId,
      htmlLink: htmlLink ?? this.htmlLink,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matricula.present) {
      map['matricula'] = Variable<String>(matricula.value);
    }
    if (inicio.present) {
      map['inicio'] = Variable<DateTime>(inicio.value);
    }
    if (fin.present) {
      map['fin'] = Variable<DateTime>(fin.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    if (departamento.present) {
      map['departamento'] = Variable<String>(departamento.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (googleEventId.present) {
      map['google_event_id'] = Variable<String>(googleEventId.value);
    }
    if (htmlLink.present) {
      map['html_link'] = Variable<String>(htmlLink.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CitasCompanion(')
          ..write('id: $id, ')
          ..write('matricula: $matricula, ')
          ..write('inicio: $inicio, ')
          ..write('fin: $fin, ')
          ..write('motivo: $motivo, ')
          ..write('departamento: $departamento, ')
          ..write('estado: $estado, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('htmlLink: $htmlLink, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $VacunacionesPendientesTable extends VacunacionesPendientes
    with TableInfo<$VacunacionesPendientesTable, VacunacionesPendiente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VacunacionesPendientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _matriculaMeta =
      const VerificationMeta('matricula');
  @override
  late final GeneratedColumn<String> matricula = GeneratedColumn<String>(
      'matricula', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nombreEstudianteMeta =
      const VerificationMeta('nombreEstudiante');
  @override
  late final GeneratedColumn<String> nombreEstudiante = GeneratedColumn<String>(
      'nombre_estudiante', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _campanaMeta =
      const VerificationMeta('campana');
  @override
  late final GeneratedColumn<String> campana = GeneratedColumn<String>(
      'campana', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vacunaMeta = const VerificationMeta('vacuna');
  @override
  late final GeneratedColumn<String> vacuna = GeneratedColumn<String>(
      'vacuna', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dosisMeta = const VerificationMeta('dosis');
  @override
  late final GeneratedColumn<int> dosis = GeneratedColumn<int>(
      'dosis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _loteMeta = const VerificationMeta('lote');
  @override
  late final GeneratedColumn<String> lote = GeneratedColumn<String>(
      'lote', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _aplicadoPorMeta =
      const VerificationMeta('aplicadoPor');
  @override
  late final GeneratedColumn<String> aplicadoPor = GeneratedColumn<String>(
      'aplicado_por', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fechaAplicacionMeta =
      const VerificationMeta('fechaAplicacion');
  @override
  late final GeneratedColumn<String> fechaAplicacion = GeneratedColumn<String>(
      'fecha_aplicacion', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _observacionesMeta =
      const VerificationMeta('observaciones');
  @override
  late final GeneratedColumn<String> observaciones = GeneratedColumn<String>(
      'observaciones', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        matricula,
        nombreEstudiante,
        campana,
        vacuna,
        dosis,
        lote,
        aplicadoPor,
        fechaAplicacion,
        observaciones,
        createdAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vacunaciones_pendientes';
  @override
  VerificationContext validateIntegrity(
      Insertable<VacunacionesPendiente> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('matricula')) {
      context.handle(_matriculaMeta,
          matricula.isAcceptableOrUnknown(data['matricula']!, _matriculaMeta));
    } else if (isInserting) {
      context.missing(_matriculaMeta);
    }
    if (data.containsKey('nombre_estudiante')) {
      context.handle(
          _nombreEstudianteMeta,
          nombreEstudiante.isAcceptableOrUnknown(
              data['nombre_estudiante']!, _nombreEstudianteMeta));
    }
    if (data.containsKey('campana')) {
      context.handle(_campanaMeta,
          campana.isAcceptableOrUnknown(data['campana']!, _campanaMeta));
    } else if (isInserting) {
      context.missing(_campanaMeta);
    }
    if (data.containsKey('vacuna')) {
      context.handle(_vacunaMeta,
          vacuna.isAcceptableOrUnknown(data['vacuna']!, _vacunaMeta));
    } else if (isInserting) {
      context.missing(_vacunaMeta);
    }
    if (data.containsKey('dosis')) {
      context.handle(
          _dosisMeta, dosis.isAcceptableOrUnknown(data['dosis']!, _dosisMeta));
    } else if (isInserting) {
      context.missing(_dosisMeta);
    }
    if (data.containsKey('lote')) {
      context.handle(
          _loteMeta, lote.isAcceptableOrUnknown(data['lote']!, _loteMeta));
    }
    if (data.containsKey('aplicado_por')) {
      context.handle(
          _aplicadoPorMeta,
          aplicadoPor.isAcceptableOrUnknown(
              data['aplicado_por']!, _aplicadoPorMeta));
    }
    if (data.containsKey('fecha_aplicacion')) {
      context.handle(
          _fechaAplicacionMeta,
          fechaAplicacion.isAcceptableOrUnknown(
              data['fecha_aplicacion']!, _fechaAplicacionMeta));
    } else if (isInserting) {
      context.missing(_fechaAplicacionMeta);
    }
    if (data.containsKey('observaciones')) {
      context.handle(
          _observacionesMeta,
          observaciones.isAcceptableOrUnknown(
              data['observaciones']!, _observacionesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VacunacionesPendiente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VacunacionesPendiente(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      matricula: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matricula'])!,
      nombreEstudiante: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}nombre_estudiante']),
      campana: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}campana'])!,
      vacuna: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vacuna'])!,
      dosis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dosis'])!,
      lote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lote']),
      aplicadoPor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}aplicado_por']),
      fechaAplicacion: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}fecha_aplicacion'])!,
      observaciones: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observaciones']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $VacunacionesPendientesTable createAlias(String alias) {
    return $VacunacionesPendientesTable(attachedDatabase, alias);
  }
}

class VacunacionesPendiente extends DataClass
    implements Insertable<VacunacionesPendiente> {
  final int id;
  final String matricula;
  final String? nombreEstudiante;
  final String campana;
  final String vacuna;
  final int dosis;
  final String? lote;
  final String? aplicadoPor;
  final String fechaAplicacion;
  final String? observaciones;
  final DateTime createdAt;
  final bool synced;
  const VacunacionesPendiente(
      {required this.id,
      required this.matricula,
      this.nombreEstudiante,
      required this.campana,
      required this.vacuna,
      required this.dosis,
      this.lote,
      this.aplicadoPor,
      required this.fechaAplicacion,
      this.observaciones,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['matricula'] = Variable<String>(matricula);
    if (!nullToAbsent || nombreEstudiante != null) {
      map['nombre_estudiante'] = Variable<String>(nombreEstudiante);
    }
    map['campana'] = Variable<String>(campana);
    map['vacuna'] = Variable<String>(vacuna);
    map['dosis'] = Variable<int>(dosis);
    if (!nullToAbsent || lote != null) {
      map['lote'] = Variable<String>(lote);
    }
    if (!nullToAbsent || aplicadoPor != null) {
      map['aplicado_por'] = Variable<String>(aplicadoPor);
    }
    map['fecha_aplicacion'] = Variable<String>(fechaAplicacion);
    if (!nullToAbsent || observaciones != null) {
      map['observaciones'] = Variable<String>(observaciones);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  VacunacionesPendientesCompanion toCompanion(bool nullToAbsent) {
    return VacunacionesPendientesCompanion(
      id: Value(id),
      matricula: Value(matricula),
      nombreEstudiante: nombreEstudiante == null && nullToAbsent
          ? const Value.absent()
          : Value(nombreEstudiante),
      campana: Value(campana),
      vacuna: Value(vacuna),
      dosis: Value(dosis),
      lote: lote == null && nullToAbsent ? const Value.absent() : Value(lote),
      aplicadoPor: aplicadoPor == null && nullToAbsent
          ? const Value.absent()
          : Value(aplicadoPor),
      fechaAplicacion: Value(fechaAplicacion),
      observaciones: observaciones == null && nullToAbsent
          ? const Value.absent()
          : Value(observaciones),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory VacunacionesPendiente.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VacunacionesPendiente(
      id: serializer.fromJson<int>(json['id']),
      matricula: serializer.fromJson<String>(json['matricula']),
      nombreEstudiante: serializer.fromJson<String?>(json['nombreEstudiante']),
      campana: serializer.fromJson<String>(json['campana']),
      vacuna: serializer.fromJson<String>(json['vacuna']),
      dosis: serializer.fromJson<int>(json['dosis']),
      lote: serializer.fromJson<String?>(json['lote']),
      aplicadoPor: serializer.fromJson<String?>(json['aplicadoPor']),
      fechaAplicacion: serializer.fromJson<String>(json['fechaAplicacion']),
      observaciones: serializer.fromJson<String?>(json['observaciones']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matricula': serializer.toJson<String>(matricula),
      'nombreEstudiante': serializer.toJson<String?>(nombreEstudiante),
      'campana': serializer.toJson<String>(campana),
      'vacuna': serializer.toJson<String>(vacuna),
      'dosis': serializer.toJson<int>(dosis),
      'lote': serializer.toJson<String?>(lote),
      'aplicadoPor': serializer.toJson<String?>(aplicadoPor),
      'fechaAplicacion': serializer.toJson<String>(fechaAplicacion),
      'observaciones': serializer.toJson<String?>(observaciones),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  VacunacionesPendiente copyWith(
          {int? id,
          String? matricula,
          Value<String?> nombreEstudiante = const Value.absent(),
          String? campana,
          String? vacuna,
          int? dosis,
          Value<String?> lote = const Value.absent(),
          Value<String?> aplicadoPor = const Value.absent(),
          String? fechaAplicacion,
          Value<String?> observaciones = const Value.absent(),
          DateTime? createdAt,
          bool? synced}) =>
      VacunacionesPendiente(
        id: id ?? this.id,
        matricula: matricula ?? this.matricula,
        nombreEstudiante: nombreEstudiante.present
            ? nombreEstudiante.value
            : this.nombreEstudiante,
        campana: campana ?? this.campana,
        vacuna: vacuna ?? this.vacuna,
        dosis: dosis ?? this.dosis,
        lote: lote.present ? lote.value : this.lote,
        aplicadoPor: aplicadoPor.present ? aplicadoPor.value : this.aplicadoPor,
        fechaAplicacion: fechaAplicacion ?? this.fechaAplicacion,
        observaciones:
            observaciones.present ? observaciones.value : this.observaciones,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  VacunacionesPendiente copyWithCompanion(
      VacunacionesPendientesCompanion data) {
    return VacunacionesPendiente(
      id: data.id.present ? data.id.value : this.id,
      matricula: data.matricula.present ? data.matricula.value : this.matricula,
      nombreEstudiante: data.nombreEstudiante.present
          ? data.nombreEstudiante.value
          : this.nombreEstudiante,
      campana: data.campana.present ? data.campana.value : this.campana,
      vacuna: data.vacuna.present ? data.vacuna.value : this.vacuna,
      dosis: data.dosis.present ? data.dosis.value : this.dosis,
      lote: data.lote.present ? data.lote.value : this.lote,
      aplicadoPor:
          data.aplicadoPor.present ? data.aplicadoPor.value : this.aplicadoPor,
      fechaAplicacion: data.fechaAplicacion.present
          ? data.fechaAplicacion.value
          : this.fechaAplicacion,
      observaciones: data.observaciones.present
          ? data.observaciones.value
          : this.observaciones,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VacunacionesPendiente(')
          ..write('id: $id, ')
          ..write('matricula: $matricula, ')
          ..write('nombreEstudiante: $nombreEstudiante, ')
          ..write('campana: $campana, ')
          ..write('vacuna: $vacuna, ')
          ..write('dosis: $dosis, ')
          ..write('lote: $lote, ')
          ..write('aplicadoPor: $aplicadoPor, ')
          ..write('fechaAplicacion: $fechaAplicacion, ')
          ..write('observaciones: $observaciones, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      matricula,
      nombreEstudiante,
      campana,
      vacuna,
      dosis,
      lote,
      aplicadoPor,
      fechaAplicacion,
      observaciones,
      createdAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VacunacionesPendiente &&
          other.id == this.id &&
          other.matricula == this.matricula &&
          other.nombreEstudiante == this.nombreEstudiante &&
          other.campana == this.campana &&
          other.vacuna == this.vacuna &&
          other.dosis == this.dosis &&
          other.lote == this.lote &&
          other.aplicadoPor == this.aplicadoPor &&
          other.fechaAplicacion == this.fechaAplicacion &&
          other.observaciones == this.observaciones &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class VacunacionesPendientesCompanion
    extends UpdateCompanion<VacunacionesPendiente> {
  final Value<int> id;
  final Value<String> matricula;
  final Value<String?> nombreEstudiante;
  final Value<String> campana;
  final Value<String> vacuna;
  final Value<int> dosis;
  final Value<String?> lote;
  final Value<String?> aplicadoPor;
  final Value<String> fechaAplicacion;
  final Value<String?> observaciones;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  const VacunacionesPendientesCompanion({
    this.id = const Value.absent(),
    this.matricula = const Value.absent(),
    this.nombreEstudiante = const Value.absent(),
    this.campana = const Value.absent(),
    this.vacuna = const Value.absent(),
    this.dosis = const Value.absent(),
    this.lote = const Value.absent(),
    this.aplicadoPor = const Value.absent(),
    this.fechaAplicacion = const Value.absent(),
    this.observaciones = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  VacunacionesPendientesCompanion.insert({
    this.id = const Value.absent(),
    required String matricula,
    this.nombreEstudiante = const Value.absent(),
    required String campana,
    required String vacuna,
    required int dosis,
    this.lote = const Value.absent(),
    this.aplicadoPor = const Value.absent(),
    required String fechaAplicacion,
    this.observaciones = const Value.absent(),
    required DateTime createdAt,
    this.synced = const Value.absent(),
  })  : matricula = Value(matricula),
        campana = Value(campana),
        vacuna = Value(vacuna),
        dosis = Value(dosis),
        fechaAplicacion = Value(fechaAplicacion),
        createdAt = Value(createdAt);
  static Insertable<VacunacionesPendiente> custom({
    Expression<int>? id,
    Expression<String>? matricula,
    Expression<String>? nombreEstudiante,
    Expression<String>? campana,
    Expression<String>? vacuna,
    Expression<int>? dosis,
    Expression<String>? lote,
    Expression<String>? aplicadoPor,
    Expression<String>? fechaAplicacion,
    Expression<String>? observaciones,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matricula != null) 'matricula': matricula,
      if (nombreEstudiante != null) 'nombre_estudiante': nombreEstudiante,
      if (campana != null) 'campana': campana,
      if (vacuna != null) 'vacuna': vacuna,
      if (dosis != null) 'dosis': dosis,
      if (lote != null) 'lote': lote,
      if (aplicadoPor != null) 'aplicado_por': aplicadoPor,
      if (fechaAplicacion != null) 'fecha_aplicacion': fechaAplicacion,
      if (observaciones != null) 'observaciones': observaciones,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  VacunacionesPendientesCompanion copyWith(
      {Value<int>? id,
      Value<String>? matricula,
      Value<String?>? nombreEstudiante,
      Value<String>? campana,
      Value<String>? vacuna,
      Value<int>? dosis,
      Value<String?>? lote,
      Value<String?>? aplicadoPor,
      Value<String>? fechaAplicacion,
      Value<String?>? observaciones,
      Value<DateTime>? createdAt,
      Value<bool>? synced}) {
    return VacunacionesPendientesCompanion(
      id: id ?? this.id,
      matricula: matricula ?? this.matricula,
      nombreEstudiante: nombreEstudiante ?? this.nombreEstudiante,
      campana: campana ?? this.campana,
      vacuna: vacuna ?? this.vacuna,
      dosis: dosis ?? this.dosis,
      lote: lote ?? this.lote,
      aplicadoPor: aplicadoPor ?? this.aplicadoPor,
      fechaAplicacion: fechaAplicacion ?? this.fechaAplicacion,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matricula.present) {
      map['matricula'] = Variable<String>(matricula.value);
    }
    if (nombreEstudiante.present) {
      map['nombre_estudiante'] = Variable<String>(nombreEstudiante.value);
    }
    if (campana.present) {
      map['campana'] = Variable<String>(campana.value);
    }
    if (vacuna.present) {
      map['vacuna'] = Variable<String>(vacuna.value);
    }
    if (dosis.present) {
      map['dosis'] = Variable<int>(dosis.value);
    }
    if (lote.present) {
      map['lote'] = Variable<String>(lote.value);
    }
    if (aplicadoPor.present) {
      map['aplicado_por'] = Variable<String>(aplicadoPor.value);
    }
    if (fechaAplicacion.present) {
      map['fecha_aplicacion'] = Variable<String>(fechaAplicacion.value);
    }
    if (observaciones.present) {
      map['observaciones'] = Variable<String>(observaciones.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VacunacionesPendientesCompanion(')
          ..write('id: $id, ')
          ..write('matricula: $matricula, ')
          ..write('nombreEstudiante: $nombreEstudiante, ')
          ..write('campana: $campana, ')
          ..write('vacuna: $vacuna, ')
          ..write('dosis: $dosis, ')
          ..write('lote: $lote, ')
          ..write('aplicadoPor: $aplicadoPor, ')
          ..write('fechaAplicacion: $fechaAplicacion, ')
          ..write('observaciones: $observaciones, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HealthRecordsTable healthRecords = $HealthRecordsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $CitasTable citas = $CitasTable(this);
  late final $VacunacionesPendientesTable vacunacionesPendientes =
      $VacunacionesPendientesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [healthRecords, notes, citas, vacunacionesPendientes];
}

typedef $$HealthRecordsTableCreateCompanionBuilder = HealthRecordsCompanion
    Function({
  Value<int> id,
  Value<DateTime?> timestamp,
  required String matricula,
  required String nombreCompleto,
  required String correo,
  Value<int?> edad,
  Value<String?> sexo,
  Value<String?> categoria,
  Value<String?> programa,
  Value<String> escuelaUnidadAcademica,
  Value<String> grupo,
  Value<String?> discapacidad,
  Value<String?> tipoDiscapacidad,
  Value<String?> alergias,
  Value<String?> tipoSangre,
  Value<String?> enfermedadCronica,
  Value<String?> unidadMedica,
  Value<String?> numeroAfiliacion,
  Value<String?> usoSeguroUniversitario,
  Value<String?> donante,
  Value<String?> emergenciaTelefono,
  Value<String?> emergenciaContacto,
  Value<String?> expedienteNotas,
  Value<String?> expedienteAdjuntos,
  Value<bool> synced,
});
typedef $$HealthRecordsTableUpdateCompanionBuilder = HealthRecordsCompanion
    Function({
  Value<int> id,
  Value<DateTime?> timestamp,
  Value<String> matricula,
  Value<String> nombreCompleto,
  Value<String> correo,
  Value<int?> edad,
  Value<String?> sexo,
  Value<String?> categoria,
  Value<String?> programa,
  Value<String> escuelaUnidadAcademica,
  Value<String> grupo,
  Value<String?> discapacidad,
  Value<String?> tipoDiscapacidad,
  Value<String?> alergias,
  Value<String?> tipoSangre,
  Value<String?> enfermedadCronica,
  Value<String?> unidadMedica,
  Value<String?> numeroAfiliacion,
  Value<String?> usoSeguroUniversitario,
  Value<String?> donante,
  Value<String?> emergenciaTelefono,
  Value<String?> emergenciaContacto,
  Value<String?> expedienteNotas,
  Value<String?> expedienteAdjuntos,
  Value<bool> synced,
});

class $$HealthRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matricula => $composableBuilder(
      column: $table.matricula, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombreCompleto => $composableBuilder(
      column: $table.nombreCompleto,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correo => $composableBuilder(
      column: $table.correo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get edad => $composableBuilder(
      column: $table.edad, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sexo => $composableBuilder(
      column: $table.sexo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoria => $composableBuilder(
      column: $table.categoria, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get programa => $composableBuilder(
      column: $table.programa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get escuelaUnidadAcademica => $composableBuilder(
      column: $table.escuelaUnidadAcademica,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get grupo => $composableBuilder(
      column: $table.grupo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get discapacidad => $composableBuilder(
      column: $table.discapacidad, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoDiscapacidad => $composableBuilder(
      column: $table.tipoDiscapacidad,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get alergias => $composableBuilder(
      column: $table.alergias, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoSangre => $composableBuilder(
      column: $table.tipoSangre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enfermedadCronica => $composableBuilder(
      column: $table.enfermedadCronica,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unidadMedica => $composableBuilder(
      column: $table.unidadMedica, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get numeroAfiliacion => $composableBuilder(
      column: $table.numeroAfiliacion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get usoSeguroUniversitario => $composableBuilder(
      column: $table.usoSeguroUniversitario,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get donante => $composableBuilder(
      column: $table.donante, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emergenciaTelefono => $composableBuilder(
      column: $table.emergenciaTelefono,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emergenciaContacto => $composableBuilder(
      column: $table.emergenciaContacto,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get expedienteNotas => $composableBuilder(
      column: $table.expedienteNotas,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get expedienteAdjuntos => $composableBuilder(
      column: $table.expedienteAdjuntos,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$HealthRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matricula => $composableBuilder(
      column: $table.matricula, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombreCompleto => $composableBuilder(
      column: $table.nombreCompleto,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correo => $composableBuilder(
      column: $table.correo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get edad => $composableBuilder(
      column: $table.edad, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sexo => $composableBuilder(
      column: $table.sexo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoria => $composableBuilder(
      column: $table.categoria, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get programa => $composableBuilder(
      column: $table.programa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get escuelaUnidadAcademica => $composableBuilder(
      column: $table.escuelaUnidadAcademica,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grupo => $composableBuilder(
      column: $table.grupo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get discapacidad => $composableBuilder(
      column: $table.discapacidad,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoDiscapacidad => $composableBuilder(
      column: $table.tipoDiscapacidad,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alergias => $composableBuilder(
      column: $table.alergias, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoSangre => $composableBuilder(
      column: $table.tipoSangre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enfermedadCronica => $composableBuilder(
      column: $table.enfermedadCronica,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unidadMedica => $composableBuilder(
      column: $table.unidadMedica,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get numeroAfiliacion => $composableBuilder(
      column: $table.numeroAfiliacion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get usoSeguroUniversitario => $composableBuilder(
      column: $table.usoSeguroUniversitario,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get donante => $composableBuilder(
      column: $table.donante, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emergenciaTelefono => $composableBuilder(
      column: $table.emergenciaTelefono,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emergenciaContacto => $composableBuilder(
      column: $table.emergenciaContacto,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expedienteNotas => $composableBuilder(
      column: $table.expedienteNotas,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expedienteAdjuntos => $composableBuilder(
      column: $table.expedienteAdjuntos,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$HealthRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get matricula =>
      $composableBuilder(column: $table.matricula, builder: (column) => column);

  GeneratedColumn<String> get nombreCompleto => $composableBuilder(
      column: $table.nombreCompleto, builder: (column) => column);

  GeneratedColumn<String> get correo =>
      $composableBuilder(column: $table.correo, builder: (column) => column);

  GeneratedColumn<int> get edad =>
      $composableBuilder(column: $table.edad, builder: (column) => column);

  GeneratedColumn<String> get sexo =>
      $composableBuilder(column: $table.sexo, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<String> get programa =>
      $composableBuilder(column: $table.programa, builder: (column) => column);

  GeneratedColumn<String> get escuelaUnidadAcademica => $composableBuilder(
      column: $table.escuelaUnidadAcademica, builder: (column) => column);

  GeneratedColumn<String> get grupo =>
      $composableBuilder(column: $table.grupo, builder: (column) => column);

  GeneratedColumn<String> get discapacidad => $composableBuilder(
      column: $table.discapacidad, builder: (column) => column);

  GeneratedColumn<String> get tipoDiscapacidad => $composableBuilder(
      column: $table.tipoDiscapacidad, builder: (column) => column);

  GeneratedColumn<String> get alergias =>
      $composableBuilder(column: $table.alergias, builder: (column) => column);

  GeneratedColumn<String> get tipoSangre => $composableBuilder(
      column: $table.tipoSangre, builder: (column) => column);

  GeneratedColumn<String> get enfermedadCronica => $composableBuilder(
      column: $table.enfermedadCronica, builder: (column) => column);

  GeneratedColumn<String> get unidadMedica => $composableBuilder(
      column: $table.unidadMedica, builder: (column) => column);

  GeneratedColumn<String> get numeroAfiliacion => $composableBuilder(
      column: $table.numeroAfiliacion, builder: (column) => column);

  GeneratedColumn<String> get usoSeguroUniversitario => $composableBuilder(
      column: $table.usoSeguroUniversitario, builder: (column) => column);

  GeneratedColumn<String> get donante =>
      $composableBuilder(column: $table.donante, builder: (column) => column);

  GeneratedColumn<String> get emergenciaTelefono => $composableBuilder(
      column: $table.emergenciaTelefono, builder: (column) => column);

  GeneratedColumn<String> get emergenciaContacto => $composableBuilder(
      column: $table.emergenciaContacto, builder: (column) => column);

  GeneratedColumn<String> get expedienteNotas => $composableBuilder(
      column: $table.expedienteNotas, builder: (column) => column);

  GeneratedColumn<String> get expedienteAdjuntos => $composableBuilder(
      column: $table.expedienteAdjuntos, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$HealthRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HealthRecordsTable,
    HealthRecord,
    $$HealthRecordsTableFilterComposer,
    $$HealthRecordsTableOrderingComposer,
    $$HealthRecordsTableAnnotationComposer,
    $$HealthRecordsTableCreateCompanionBuilder,
    $$HealthRecordsTableUpdateCompanionBuilder,
    (
      HealthRecord,
      BaseReferences<_$AppDatabase, $HealthRecordsTable, HealthRecord>
    ),
    HealthRecord,
    PrefetchHooks Function()> {
  $$HealthRecordsTableTableManager(_$AppDatabase db, $HealthRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> timestamp = const Value.absent(),
            Value<String> matricula = const Value.absent(),
            Value<String> nombreCompleto = const Value.absent(),
            Value<String> correo = const Value.absent(),
            Value<int?> edad = const Value.absent(),
            Value<String?> sexo = const Value.absent(),
            Value<String?> categoria = const Value.absent(),
            Value<String?> programa = const Value.absent(),
            Value<String> escuelaUnidadAcademica = const Value.absent(),
            Value<String> grupo = const Value.absent(),
            Value<String?> discapacidad = const Value.absent(),
            Value<String?> tipoDiscapacidad = const Value.absent(),
            Value<String?> alergias = const Value.absent(),
            Value<String?> tipoSangre = const Value.absent(),
            Value<String?> enfermedadCronica = const Value.absent(),
            Value<String?> unidadMedica = const Value.absent(),
            Value<String?> numeroAfiliacion = const Value.absent(),
            Value<String?> usoSeguroUniversitario = const Value.absent(),
            Value<String?> donante = const Value.absent(),
            Value<String?> emergenciaTelefono = const Value.absent(),
            Value<String?> emergenciaContacto = const Value.absent(),
            Value<String?> expedienteNotas = const Value.absent(),
            Value<String?> expedienteAdjuntos = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              HealthRecordsCompanion(
            id: id,
            timestamp: timestamp,
            matricula: matricula,
            nombreCompleto: nombreCompleto,
            correo: correo,
            edad: edad,
            sexo: sexo,
            categoria: categoria,
            programa: programa,
            escuelaUnidadAcademica: escuelaUnidadAcademica,
            grupo: grupo,
            discapacidad: discapacidad,
            tipoDiscapacidad: tipoDiscapacidad,
            alergias: alergias,
            tipoSangre: tipoSangre,
            enfermedadCronica: enfermedadCronica,
            unidadMedica: unidadMedica,
            numeroAfiliacion: numeroAfiliacion,
            usoSeguroUniversitario: usoSeguroUniversitario,
            donante: donante,
            emergenciaTelefono: emergenciaTelefono,
            emergenciaContacto: emergenciaContacto,
            expedienteNotas: expedienteNotas,
            expedienteAdjuntos: expedienteAdjuntos,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> timestamp = const Value.absent(),
            required String matricula,
            required String nombreCompleto,
            required String correo,
            Value<int?> edad = const Value.absent(),
            Value<String?> sexo = const Value.absent(),
            Value<String?> categoria = const Value.absent(),
            Value<String?> programa = const Value.absent(),
            Value<String> escuelaUnidadAcademica = const Value.absent(),
            Value<String> grupo = const Value.absent(),
            Value<String?> discapacidad = const Value.absent(),
            Value<String?> tipoDiscapacidad = const Value.absent(),
            Value<String?> alergias = const Value.absent(),
            Value<String?> tipoSangre = const Value.absent(),
            Value<String?> enfermedadCronica = const Value.absent(),
            Value<String?> unidadMedica = const Value.absent(),
            Value<String?> numeroAfiliacion = const Value.absent(),
            Value<String?> usoSeguroUniversitario = const Value.absent(),
            Value<String?> donante = const Value.absent(),
            Value<String?> emergenciaTelefono = const Value.absent(),
            Value<String?> emergenciaContacto = const Value.absent(),
            Value<String?> expedienteNotas = const Value.absent(),
            Value<String?> expedienteAdjuntos = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              HealthRecordsCompanion.insert(
            id: id,
            timestamp: timestamp,
            matricula: matricula,
            nombreCompleto: nombreCompleto,
            correo: correo,
            edad: edad,
            sexo: sexo,
            categoria: categoria,
            programa: programa,
            escuelaUnidadAcademica: escuelaUnidadAcademica,
            grupo: grupo,
            discapacidad: discapacidad,
            tipoDiscapacidad: tipoDiscapacidad,
            alergias: alergias,
            tipoSangre: tipoSangre,
            enfermedadCronica: enfermedadCronica,
            unidadMedica: unidadMedica,
            numeroAfiliacion: numeroAfiliacion,
            usoSeguroUniversitario: usoSeguroUniversitario,
            donante: donante,
            emergenciaTelefono: emergenciaTelefono,
            emergenciaContacto: emergenciaContacto,
            expedienteNotas: expedienteNotas,
            expedienteAdjuntos: expedienteAdjuntos,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HealthRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HealthRecordsTable,
    HealthRecord,
    $$HealthRecordsTableFilterComposer,
    $$HealthRecordsTableOrderingComposer,
    $$HealthRecordsTableAnnotationComposer,
    $$HealthRecordsTableCreateCompanionBuilder,
    $$HealthRecordsTableUpdateCompanionBuilder,
    (
      HealthRecord,
      BaseReferences<_$AppDatabase, $HealthRecordsTable, HealthRecord>
    ),
    HealthRecord,
    PrefetchHooks Function()>;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  required String matricula,
  required String departamento,
  Value<String?> tratante,
  required String cuerpo,
  Value<DateTime?> createdAt,
  Value<bool> synced,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String> matricula,
  Value<String> departamento,
  Value<String?> tratante,
  Value<String> cuerpo,
  Value<DateTime?> createdAt,
  Value<bool> synced,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matricula => $composableBuilder(
      column: $table.matricula, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get departamento => $composableBuilder(
      column: $table.departamento, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tratante => $composableBuilder(
      column: $table.tratante, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cuerpo => $composableBuilder(
      column: $table.cuerpo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matricula => $composableBuilder(
      column: $table.matricula, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get departamento => $composableBuilder(
      column: $table.departamento,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tratante => $composableBuilder(
      column: $table.tratante, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cuerpo => $composableBuilder(
      column: $table.cuerpo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get matricula =>
      $composableBuilder(column: $table.matricula, builder: (column) => column);

  GeneratedColumn<String> get departamento => $composableBuilder(
      column: $table.departamento, builder: (column) => column);

  GeneratedColumn<String> get tratante =>
      $composableBuilder(column: $table.tratante, builder: (column) => column);

  GeneratedColumn<String> get cuerpo =>
      $composableBuilder(column: $table.cuerpo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$NotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
    Note,
    PrefetchHooks Function()> {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> matricula = const Value.absent(),
            Value<String> departamento = const Value.absent(),
            Value<String?> tratante = const Value.absent(),
            Value<String> cuerpo = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              NotesCompanion(
            id: id,
            matricula: matricula,
            departamento: departamento,
            tratante: tratante,
            cuerpo: cuerpo,
            createdAt: createdAt,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String matricula,
            required String departamento,
            Value<String?> tratante = const Value.absent(),
            required String cuerpo,
            Value<DateTime?> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              NotesCompanion.insert(
            id: id,
            matricula: matricula,
            departamento: departamento,
            tratante: tratante,
            cuerpo: cuerpo,
            createdAt: createdAt,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
    Note,
    PrefetchHooks Function()>;
typedef $$CitasTableCreateCompanionBuilder = CitasCompanion Function({
  Value<int> id,
  required String matricula,
  required DateTime inicio,
  required DateTime fin,
  required String motivo,
  Value<String?> departamento,
  Value<String> estado,
  Value<String?> googleEventId,
  Value<String?> htmlLink,
  Value<DateTime?> createdAt,
  Value<bool> synced,
});
typedef $$CitasTableUpdateCompanionBuilder = CitasCompanion Function({
  Value<int> id,
  Value<String> matricula,
  Value<DateTime> inicio,
  Value<DateTime> fin,
  Value<String> motivo,
  Value<String?> departamento,
  Value<String> estado,
  Value<String?> googleEventId,
  Value<String?> htmlLink,
  Value<DateTime?> createdAt,
  Value<bool> synced,
});

class $$CitasTableFilterComposer extends Composer<_$AppDatabase, $CitasTable> {
  $$CitasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matricula => $composableBuilder(
      column: $table.matricula, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get inicio => $composableBuilder(
      column: $table.inicio, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fin => $composableBuilder(
      column: $table.fin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motivo => $composableBuilder(
      column: $table.motivo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get departamento => $composableBuilder(
      column: $table.departamento, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get estado => $composableBuilder(
      column: $table.estado, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get googleEventId => $composableBuilder(
      column: $table.googleEventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get htmlLink => $composableBuilder(
      column: $table.htmlLink, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$CitasTableOrderingComposer
    extends Composer<_$AppDatabase, $CitasTable> {
  $$CitasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matricula => $composableBuilder(
      column: $table.matricula, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get inicio => $composableBuilder(
      column: $table.inicio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fin => $composableBuilder(
      column: $table.fin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motivo => $composableBuilder(
      column: $table.motivo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get departamento => $composableBuilder(
      column: $table.departamento,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get estado => $composableBuilder(
      column: $table.estado, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get googleEventId => $composableBuilder(
      column: $table.googleEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get htmlLink => $composableBuilder(
      column: $table.htmlLink, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$CitasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CitasTable> {
  $$CitasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get matricula =>
      $composableBuilder(column: $table.matricula, builder: (column) => column);

  GeneratedColumn<DateTime> get inicio =>
      $composableBuilder(column: $table.inicio, builder: (column) => column);

  GeneratedColumn<DateTime> get fin =>
      $composableBuilder(column: $table.fin, builder: (column) => column);

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  GeneratedColumn<String> get departamento => $composableBuilder(
      column: $table.departamento, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get googleEventId => $composableBuilder(
      column: $table.googleEventId, builder: (column) => column);

  GeneratedColumn<String> get htmlLink =>
      $composableBuilder(column: $table.htmlLink, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$CitasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CitasTable,
    Cita,
    $$CitasTableFilterComposer,
    $$CitasTableOrderingComposer,
    $$CitasTableAnnotationComposer,
    $$CitasTableCreateCompanionBuilder,
    $$CitasTableUpdateCompanionBuilder,
    (Cita, BaseReferences<_$AppDatabase, $CitasTable, Cita>),
    Cita,
    PrefetchHooks Function()> {
  $$CitasTableTableManager(_$AppDatabase db, $CitasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CitasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CitasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CitasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> matricula = const Value.absent(),
            Value<DateTime> inicio = const Value.absent(),
            Value<DateTime> fin = const Value.absent(),
            Value<String> motivo = const Value.absent(),
            Value<String?> departamento = const Value.absent(),
            Value<String> estado = const Value.absent(),
            Value<String?> googleEventId = const Value.absent(),
            Value<String?> htmlLink = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              CitasCompanion(
            id: id,
            matricula: matricula,
            inicio: inicio,
            fin: fin,
            motivo: motivo,
            departamento: departamento,
            estado: estado,
            googleEventId: googleEventId,
            htmlLink: htmlLink,
            createdAt: createdAt,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String matricula,
            required DateTime inicio,
            required DateTime fin,
            required String motivo,
            Value<String?> departamento = const Value.absent(),
            Value<String> estado = const Value.absent(),
            Value<String?> googleEventId = const Value.absent(),
            Value<String?> htmlLink = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              CitasCompanion.insert(
            id: id,
            matricula: matricula,
            inicio: inicio,
            fin: fin,
            motivo: motivo,
            departamento: departamento,
            estado: estado,
            googleEventId: googleEventId,
            htmlLink: htmlLink,
            createdAt: createdAt,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CitasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CitasTable,
    Cita,
    $$CitasTableFilterComposer,
    $$CitasTableOrderingComposer,
    $$CitasTableAnnotationComposer,
    $$CitasTableCreateCompanionBuilder,
    $$CitasTableUpdateCompanionBuilder,
    (Cita, BaseReferences<_$AppDatabase, $CitasTable, Cita>),
    Cita,
    PrefetchHooks Function()>;
typedef $$VacunacionesPendientesTableCreateCompanionBuilder
    = VacunacionesPendientesCompanion Function({
  Value<int> id,
  required String matricula,
  Value<String?> nombreEstudiante,
  required String campana,
  required String vacuna,
  required int dosis,
  Value<String?> lote,
  Value<String?> aplicadoPor,
  required String fechaAplicacion,
  Value<String?> observaciones,
  required DateTime createdAt,
  Value<bool> synced,
});
typedef $$VacunacionesPendientesTableUpdateCompanionBuilder
    = VacunacionesPendientesCompanion Function({
  Value<int> id,
  Value<String> matricula,
  Value<String?> nombreEstudiante,
  Value<String> campana,
  Value<String> vacuna,
  Value<int> dosis,
  Value<String?> lote,
  Value<String?> aplicadoPor,
  Value<String> fechaAplicacion,
  Value<String?> observaciones,
  Value<DateTime> createdAt,
  Value<bool> synced,
});

class $$VacunacionesPendientesTableFilterComposer
    extends Composer<_$AppDatabase, $VacunacionesPendientesTable> {
  $$VacunacionesPendientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matricula => $composableBuilder(
      column: $table.matricula, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nombreEstudiante => $composableBuilder(
      column: $table.nombreEstudiante,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get campana => $composableBuilder(
      column: $table.campana, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vacuna => $composableBuilder(
      column: $table.vacuna, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dosis => $composableBuilder(
      column: $table.dosis, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lote => $composableBuilder(
      column: $table.lote, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aplicadoPor => $composableBuilder(
      column: $table.aplicadoPor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fechaAplicacion => $composableBuilder(
      column: $table.fechaAplicacion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observaciones => $composableBuilder(
      column: $table.observaciones, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$VacunacionesPendientesTableOrderingComposer
    extends Composer<_$AppDatabase, $VacunacionesPendientesTable> {
  $$VacunacionesPendientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matricula => $composableBuilder(
      column: $table.matricula, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nombreEstudiante => $composableBuilder(
      column: $table.nombreEstudiante,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get campana => $composableBuilder(
      column: $table.campana, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vacuna => $composableBuilder(
      column: $table.vacuna, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dosis => $composableBuilder(
      column: $table.dosis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lote => $composableBuilder(
      column: $table.lote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aplicadoPor => $composableBuilder(
      column: $table.aplicadoPor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fechaAplicacion => $composableBuilder(
      column: $table.fechaAplicacion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observaciones => $composableBuilder(
      column: $table.observaciones,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$VacunacionesPendientesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VacunacionesPendientesTable> {
  $$VacunacionesPendientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get matricula =>
      $composableBuilder(column: $table.matricula, builder: (column) => column);

  GeneratedColumn<String> get nombreEstudiante => $composableBuilder(
      column: $table.nombreEstudiante, builder: (column) => column);

  GeneratedColumn<String> get campana =>
      $composableBuilder(column: $table.campana, builder: (column) => column);

  GeneratedColumn<String> get vacuna =>
      $composableBuilder(column: $table.vacuna, builder: (column) => column);

  GeneratedColumn<int> get dosis =>
      $composableBuilder(column: $table.dosis, builder: (column) => column);

  GeneratedColumn<String> get lote =>
      $composableBuilder(column: $table.lote, builder: (column) => column);

  GeneratedColumn<String> get aplicadoPor => $composableBuilder(
      column: $table.aplicadoPor, builder: (column) => column);

  GeneratedColumn<String> get fechaAplicacion => $composableBuilder(
      column: $table.fechaAplicacion, builder: (column) => column);

  GeneratedColumn<String> get observaciones => $composableBuilder(
      column: $table.observaciones, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$VacunacionesPendientesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VacunacionesPendientesTable,
    VacunacionesPendiente,
    $$VacunacionesPendientesTableFilterComposer,
    $$VacunacionesPendientesTableOrderingComposer,
    $$VacunacionesPendientesTableAnnotationComposer,
    $$VacunacionesPendientesTableCreateCompanionBuilder,
    $$VacunacionesPendientesTableUpdateCompanionBuilder,
    (
      VacunacionesPendiente,
      BaseReferences<_$AppDatabase, $VacunacionesPendientesTable,
          VacunacionesPendiente>
    ),
    VacunacionesPendiente,
    PrefetchHooks Function()> {
  $$VacunacionesPendientesTableTableManager(
      _$AppDatabase db, $VacunacionesPendientesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VacunacionesPendientesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$VacunacionesPendientesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VacunacionesPendientesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> matricula = const Value.absent(),
            Value<String?> nombreEstudiante = const Value.absent(),
            Value<String> campana = const Value.absent(),
            Value<String> vacuna = const Value.absent(),
            Value<int> dosis = const Value.absent(),
            Value<String?> lote = const Value.absent(),
            Value<String?> aplicadoPor = const Value.absent(),
            Value<String> fechaAplicacion = const Value.absent(),
            Value<String?> observaciones = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              VacunacionesPendientesCompanion(
            id: id,
            matricula: matricula,
            nombreEstudiante: nombreEstudiante,
            campana: campana,
            vacuna: vacuna,
            dosis: dosis,
            lote: lote,
            aplicadoPor: aplicadoPor,
            fechaAplicacion: fechaAplicacion,
            observaciones: observaciones,
            createdAt: createdAt,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String matricula,
            Value<String?> nombreEstudiante = const Value.absent(),
            required String campana,
            required String vacuna,
            required int dosis,
            Value<String?> lote = const Value.absent(),
            Value<String?> aplicadoPor = const Value.absent(),
            required String fechaAplicacion,
            Value<String?> observaciones = const Value.absent(),
            required DateTime createdAt,
            Value<bool> synced = const Value.absent(),
          }) =>
              VacunacionesPendientesCompanion.insert(
            id: id,
            matricula: matricula,
            nombreEstudiante: nombreEstudiante,
            campana: campana,
            vacuna: vacuna,
            dosis: dosis,
            lote: lote,
            aplicadoPor: aplicadoPor,
            fechaAplicacion: fechaAplicacion,
            observaciones: observaciones,
            createdAt: createdAt,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VacunacionesPendientesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $VacunacionesPendientesTable,
        VacunacionesPendiente,
        $$VacunacionesPendientesTableFilterComposer,
        $$VacunacionesPendientesTableOrderingComposer,
        $$VacunacionesPendientesTableAnnotationComposer,
        $$VacunacionesPendientesTableCreateCompanionBuilder,
        $$VacunacionesPendientesTableUpdateCompanionBuilder,
        (
          VacunacionesPendiente,
          BaseReferences<_$AppDatabase, $VacunacionesPendientesTable,
              VacunacionesPendiente>
        ),
        VacunacionesPendiente,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HealthRecordsTableTableManager get healthRecords =>
      $$HealthRecordsTableTableManager(_db, _db.healthRecords);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$CitasTableTableManager get citas =>
      $$CitasTableTableManager(_db, _db.citas);
  $$VacunacionesPendientesTableTableManager get vacunacionesPendientes =>
      $$VacunacionesPendientesTableTableManager(
          _db, _db.vacunacionesPendientes);
}
