// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remori_database.dart';

// ignore_for_file: type=lint
class $ReminderLogsTable extends ReminderLogs
    with TableInfo<$ReminderLogsTable, LocalReminderLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
    'reminder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> scheduledAt =
      GeneratedColumn<int>(
        'scheduled_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReminderLogsTable.$converterscheduledAt);
  @override
  late final GeneratedColumnWithTypeConverter<ReminderStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReminderStatus>($ReminderLogsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> snoozedUntil =
      GeneratedColumn<int>(
        'snoozed_until',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReminderLogsTable.$convertersnoozedUntiln);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> completedAt =
      GeneratedColumn<int>(
        'completed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReminderLogsTable.$convertercompletedAtn);
  static const VerificationMeta _confirmedViaMeta = const VerificationMeta(
    'confirmedVia',
  );
  @override
  late final GeneratedColumn<String> confirmedVia = GeneratedColumn<String>(
    'confirmed_via',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReminderLogsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    reminderId,
    scheduledAt,
    status,
    snoozedUntil,
    completedAt,
    confirmedVia,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalReminderLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
    if (data.containsKey('confirmed_via')) {
      context.handle(
        _confirmedViaMeta,
        confirmedVia.isAcceptableOrUnknown(
          data['confirmed_via']!,
          _confirmedViaMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalReminderLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReminderLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_id'],
      )!,
      scheduledAt: $ReminderLogsTable.$converterscheduledAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}scheduled_at'],
        )!,
      ),
      status: $ReminderLogsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      snoozedUntil: $ReminderLogsTable.$convertersnoozedUntiln.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}snoozed_until'],
        ),
      ),
      completedAt: $ReminderLogsTable.$convertercompletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}completed_at'],
        ),
      ),
      confirmedVia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_via'],
      ),
      updatedAt: $ReminderLogsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ReminderLogsTable createAlias(String alias) {
    return $ReminderLogsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterscheduledAt = const UtcMicros();
  static JsonTypeConverter2<ReminderStatus, String, String> $converterstatus =
      EnumNameConverter(ReminderStatus.values);
  static TypeConverter<DateTime, int> $convertersnoozedUntil =
      const UtcMicros();
  static TypeConverter<DateTime?, int?> $convertersnoozedUntiln =
      NullAwareTypeConverter.wrap($convertersnoozedUntil);
  static TypeConverter<DateTime, int> $convertercompletedAt = const UtcMicros();
  static TypeConverter<DateTime?, int?> $convertercompletedAtn =
      NullAwareTypeConverter.wrap($convertercompletedAt);
  static TypeConverter<DateTime, int> $converterupdatedAt = const UtcMicros();
}

class LocalReminderLog extends DataClass
    implements Insertable<LocalReminderLog> {
  final String id;
  final String patientId;
  final String reminderId;
  final DateTime scheduledAt;
  final ReminderStatus status;
  final DateTime? snoozedUntil;
  final DateTime? completedAt;
  final String? confirmedVia;
  final DateTime updatedAt;
  const LocalReminderLog({
    required this.id,
    required this.patientId,
    required this.reminderId,
    required this.scheduledAt,
    required this.status,
    this.snoozedUntil,
    this.completedAt,
    this.confirmedVia,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['reminder_id'] = Variable<String>(reminderId);
    {
      map['scheduled_at'] = Variable<int>(
        $ReminderLogsTable.$converterscheduledAt.toSql(scheduledAt),
      );
    }
    {
      map['status'] = Variable<String>(
        $ReminderLogsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<int>(
        $ReminderLogsTable.$convertersnoozedUntiln.toSql(snoozedUntil),
      );
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(
        $ReminderLogsTable.$convertercompletedAtn.toSql(completedAt),
      );
    }
    if (!nullToAbsent || confirmedVia != null) {
      map['confirmed_via'] = Variable<String>(confirmedVia);
    }
    {
      map['updated_at'] = Variable<int>(
        $ReminderLogsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ReminderLogsCompanion toCompanion(bool nullToAbsent) {
    return ReminderLogsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      reminderId: Value(reminderId),
      scheduledAt: Value(scheduledAt),
      status: Value(status),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      confirmedVia: confirmedVia == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedVia),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalReminderLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReminderLog(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      reminderId: serializer.fromJson<String>(json['reminderId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      status: $ReminderLogsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      confirmedVia: serializer.fromJson<String?>(json['confirmedVia']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'reminderId': serializer.toJson<String>(reminderId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'status': serializer.toJson<String>(
        $ReminderLogsTable.$converterstatus.toJson(status),
      ),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'confirmedVia': serializer.toJson<String?>(confirmedVia),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalReminderLog copyWith({
    String? id,
    String? patientId,
    String? reminderId,
    DateTime? scheduledAt,
    ReminderStatus? status,
    Value<DateTime?> snoozedUntil = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> confirmedVia = const Value.absent(),
    DateTime? updatedAt,
  }) => LocalReminderLog(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    reminderId: reminderId ?? this.reminderId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    status: status ?? this.status,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    confirmedVia: confirmedVia.present ? confirmedVia.value : this.confirmedVia,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalReminderLog copyWithCompanion(ReminderLogsCompanion data) {
    return LocalReminderLog(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      status: data.status.present ? data.status.value : this.status,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      confirmedVia: data.confirmedVia.present
          ? data.confirmedVia.value
          : this.confirmedVia,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReminderLog(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('reminderId: $reminderId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('completedAt: $completedAt, ')
          ..write('confirmedVia: $confirmedVia, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    reminderId,
    scheduledAt,
    status,
    snoozedUntil,
    completedAt,
    confirmedVia,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReminderLog &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.reminderId == this.reminderId &&
          other.scheduledAt == this.scheduledAt &&
          other.status == this.status &&
          other.snoozedUntil == this.snoozedUntil &&
          other.completedAt == this.completedAt &&
          other.confirmedVia == this.confirmedVia &&
          other.updatedAt == this.updatedAt);
}

class ReminderLogsCompanion extends UpdateCompanion<LocalReminderLog> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> reminderId;
  final Value<DateTime> scheduledAt;
  final Value<ReminderStatus> status;
  final Value<DateTime?> snoozedUntil;
  final Value<DateTime?> completedAt;
  final Value<String?> confirmedVia;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReminderLogsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.status = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.confirmedVia = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderLogsCompanion.insert({
    required String id,
    required String patientId,
    required String reminderId,
    required DateTime scheduledAt,
    required ReminderStatus status,
    this.snoozedUntil = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.confirmedVia = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       reminderId = Value(reminderId),
       scheduledAt = Value(scheduledAt),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<LocalReminderLog> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? reminderId,
    Expression<int>? scheduledAt,
    Expression<String>? status,
    Expression<int>? snoozedUntil,
    Expression<int>? completedAt,
    Expression<String>? confirmedVia,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (reminderId != null) 'reminder_id': reminderId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (status != null) 'status': status,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (completedAt != null) 'completed_at': completedAt,
      if (confirmedVia != null) 'confirmed_via': confirmedVia,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? reminderId,
    Value<DateTime>? scheduledAt,
    Value<ReminderStatus>? status,
    Value<DateTime?>? snoozedUntil,
    Value<DateTime?>? completedAt,
    Value<String?>? confirmedVia,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReminderLogsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      reminderId: reminderId ?? this.reminderId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      completedAt: completedAt ?? this.completedAt,
      confirmedVia: confirmedVia ?? this.confirmedVia,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<int>(
        $ReminderLogsTable.$converterscheduledAt.toSql(scheduledAt.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ReminderLogsTable.$converterstatus.toSql(status.value),
      );
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<int>(
        $ReminderLogsTable.$convertersnoozedUntiln.toSql(snoozedUntil.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(
        $ReminderLogsTable.$convertercompletedAtn.toSql(completedAt.value),
      );
    }
    if (confirmedVia.present) {
      map['confirmed_via'] = Variable<String>(confirmedVia.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $ReminderLogsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderLogsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('reminderId: $reminderId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('completedAt: $completedAt, ')
          ..write('confirmedVia: $confirmedVia, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, PendingWrite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OutboxKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OutboxKind>($OutboxEntriesTable.$converterkind);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sequence,
    id,
    patientId,
    kind,
    recordId,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingWrite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sequence};
  @override
  PendingWrite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingWrite(
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      kind: $OutboxEntriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OutboxKind, String, String> $converterkind =
      EnumNameConverter(OutboxKind.values);
}

class PendingWrite extends DataClass implements Insertable<PendingWrite> {
  final int sequence;
  final String id;
  final String patientId;
  final OutboxKind kind;
  final String recordId;
  final String payload;
  const PendingWrite({
    required this.sequence,
    required this.id,
    required this.patientId,
    required this.kind,
    required this.recordId,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sequence'] = Variable<int>(sequence);
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    {
      map['kind'] = Variable<String>(
        $OutboxEntriesTable.$converterkind.toSql(kind),
      );
    }
    map['record_id'] = Variable<String>(recordId);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      sequence: Value(sequence),
      id: Value(id),
      patientId: Value(patientId),
      kind: Value(kind),
      recordId: Value(recordId),
      payload: Value(payload),
    );
  }

  factory PendingWrite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingWrite(
      sequence: serializer.fromJson<int>(json['sequence']),
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      kind: $OutboxEntriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      recordId: serializer.fromJson<String>(json['recordId']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sequence': serializer.toJson<int>(sequence),
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'kind': serializer.toJson<String>(
        $OutboxEntriesTable.$converterkind.toJson(kind),
      ),
      'recordId': serializer.toJson<String>(recordId),
      'payload': serializer.toJson<String>(payload),
    };
  }

  PendingWrite copyWith({
    int? sequence,
    String? id,
    String? patientId,
    OutboxKind? kind,
    String? recordId,
    String? payload,
  }) => PendingWrite(
    sequence: sequence ?? this.sequence,
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    kind: kind ?? this.kind,
    recordId: recordId ?? this.recordId,
    payload: payload ?? this.payload,
  );
  PendingWrite copyWithCompanion(OutboxEntriesCompanion data) {
    return PendingWrite(
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      kind: data.kind.present ? data.kind.value : this.kind,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingWrite(')
          ..write('sequence: $sequence, ')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('kind: $kind, ')
          ..write('recordId: $recordId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sequence, id, patientId, kind, recordId, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingWrite &&
          other.sequence == this.sequence &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.kind == this.kind &&
          other.recordId == this.recordId &&
          other.payload == this.payload);
}

class OutboxEntriesCompanion extends UpdateCompanion<PendingWrite> {
  final Value<int> sequence;
  final Value<String> id;
  final Value<String> patientId;
  final Value<OutboxKind> kind;
  final Value<String> recordId;
  final Value<String> payload;
  const OutboxEntriesCompanion({
    this.sequence = const Value.absent(),
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.kind = const Value.absent(),
    this.recordId = const Value.absent(),
    this.payload = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    this.sequence = const Value.absent(),
    required String id,
    required String patientId,
    required OutboxKind kind,
    required String recordId,
    required String payload,
  }) : id = Value(id),
       patientId = Value(patientId),
       kind = Value(kind),
       recordId = Value(recordId),
       payload = Value(payload);
  static Insertable<PendingWrite> custom({
    Expression<int>? sequence,
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? kind,
    Expression<String>? recordId,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (sequence != null) 'sequence': sequence,
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (kind != null) 'kind': kind,
      if (recordId != null) 'record_id': recordId,
      if (payload != null) 'payload': payload,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<int>? sequence,
    Value<String>? id,
    Value<String>? patientId,
    Value<OutboxKind>? kind,
    Value<String>? recordId,
    Value<String>? payload,
  }) {
    return OutboxEntriesCompanion(
      sequence: sequence ?? this.sequence,
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      kind: kind ?? this.kind,
      recordId: recordId ?? this.recordId,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $OutboxEntriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('sequence: $sequence, ')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('kind: $kind, ')
          ..write('recordId: $recordId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

abstract class _$RemoriDatabase extends GeneratedDatabase {
  _$RemoriDatabase(QueryExecutor e) : super(e);
  $RemoriDatabaseManager get managers => $RemoriDatabaseManager(this);
  late final $ReminderLogsTable reminderLogs = $ReminderLogsTable(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    reminderLogs,
    outboxEntries,
  ];
}

typedef $$ReminderLogsTableCreateCompanionBuilder =
    ReminderLogsCompanion Function({
      required String id,
      required String patientId,
      required String reminderId,
      required DateTime scheduledAt,
      required ReminderStatus status,
      Value<DateTime?> snoozedUntil,
      Value<DateTime?> completedAt,
      Value<String?> confirmedVia,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReminderLogsTableUpdateCompanionBuilder =
    ReminderLogsCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<String> reminderId,
      Value<DateTime> scheduledAt,
      Value<ReminderStatus> status,
      Value<DateTime?> snoozedUntil,
      Value<DateTime?> completedAt,
      Value<String?> confirmedVia,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ReminderLogsTableFilterComposer
    extends Composer<_$RemoriDatabase, $ReminderLogsTable> {
  $$ReminderLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get scheduledAt =>
      $composableBuilder(
        column: $table.scheduledAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ReminderStatus, ReminderStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get snoozedUntil =>
      $composableBuilder(
        column: $table.snoozedUntil,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get confirmedVia => $composableBuilder(
    column: $table.confirmedVia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ReminderLogsTableOrderingComposer
    extends Composer<_$RemoriDatabase, $ReminderLogsTable> {
  $$ReminderLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmedVia => $composableBuilder(
    column: $table.confirmedVia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReminderLogsTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $ReminderLogsTable> {
  $$ReminderLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get scheduledAt =>
      $composableBuilder(
        column: $table.scheduledAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<ReminderStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get snoozedUntil =>
      $composableBuilder(
        column: $table.snoozedUntil,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get confirmedVia => $composableBuilder(
    column: $table.confirmedVia,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReminderLogsTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $ReminderLogsTable,
          LocalReminderLog,
          $$ReminderLogsTableFilterComposer,
          $$ReminderLogsTableOrderingComposer,
          $$ReminderLogsTableAnnotationComposer,
          $$ReminderLogsTableCreateCompanionBuilder,
          $$ReminderLogsTableUpdateCompanionBuilder,
          (
            LocalReminderLog,
            BaseReferences<
              _$RemoriDatabase,
              $ReminderLogsTable,
              LocalReminderLog
            >,
          ),
          LocalReminderLog,
          PrefetchHooks Function()
        > {
  $$ReminderLogsTableTableManager(_$RemoriDatabase db, $ReminderLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> reminderId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<ReminderStatus> status = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> confirmedVia = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderLogsCompanion(
                id: id,
                patientId: patientId,
                reminderId: reminderId,
                scheduledAt: scheduledAt,
                status: status,
                snoozedUntil: snoozedUntil,
                completedAt: completedAt,
                confirmedVia: confirmedVia,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required String reminderId,
                required DateTime scheduledAt,
                required ReminderStatus status,
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> confirmedVia = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReminderLogsCompanion.insert(
                id: id,
                patientId: patientId,
                reminderId: reminderId,
                scheduledAt: scheduledAt,
                status: status,
                snoozedUntil: snoozedUntil,
                completedAt: completedAt,
                confirmedVia: confirmedVia,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReminderLogsTable, LocalReminderLog>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $ReminderLogsTable,
                    LocalReminderLog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReminderLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $ReminderLogsTable,
      LocalReminderLog,
      $$ReminderLogsTableFilterComposer,
      $$ReminderLogsTableOrderingComposer,
      $$ReminderLogsTableAnnotationComposer,
      $$ReminderLogsTableCreateCompanionBuilder,
      $$ReminderLogsTableUpdateCompanionBuilder,
      (
        LocalReminderLog,
        BaseReferences<_$RemoriDatabase, $ReminderLogsTable, LocalReminderLog>,
      ),
      LocalReminderLog,
      PrefetchHooks Function()
    >;
typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> sequence,
      required String id,
      required String patientId,
      required OutboxKind kind,
      required String recordId,
      required String payload,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<int> sequence,
      Value<String> id,
      Value<String> patientId,
      Value<OutboxKind> kind,
      Value<String> recordId,
      Value<String> payload,
    });

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$RemoriDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OutboxKind, OutboxKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OutboxKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $OutboxEntriesTable,
          PendingWrite,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (
            PendingWrite,
            BaseReferences<_$RemoriDatabase, $OutboxEntriesTable, PendingWrite>,
          ),
          PendingWrite,
          PrefetchHooks Function()
        > {
  $$OutboxEntriesTableTableManager(
    _$RemoriDatabase db,
    $OutboxEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<OutboxKind> kind = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> payload = const Value.absent(),
              }) => OutboxEntriesCompanion(
                sequence: sequence,
                id: id,
                patientId: patientId,
                kind: kind,
                recordId: recordId,
                payload: payload,
              ),
          createCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                required String id,
                required String patientId,
                required OutboxKind kind,
                required String recordId,
                required String payload,
              }) => OutboxEntriesCompanion.insert(
                sequence: sequence,
                id: id,
                patientId: patientId,
                kind: kind,
                recordId: recordId,
                payload: payload,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxEntriesTable, PendingWrite>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $OutboxEntriesTable,
                    PendingWrite
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $OutboxEntriesTable,
      PendingWrite,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (
        PendingWrite,
        BaseReferences<_$RemoriDatabase, $OutboxEntriesTable, PendingWrite>,
      ),
      PendingWrite,
      PrefetchHooks Function()
    >;

class $RemoriDatabaseManager {
  final _$RemoriDatabase _db;
  $RemoriDatabaseManager(this._db);
  $$ReminderLogsTableTableManager get reminderLogs =>
      $$ReminderLogsTableTableManager(_db, _db.reminderLogs);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
}
