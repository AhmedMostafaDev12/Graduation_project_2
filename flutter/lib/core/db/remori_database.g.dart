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

class $DashboardPatientsTable extends DashboardPatients
    with TableInfo<$DashboardPatientsTable, DashboardPatient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardPatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredLanguageMeta = const VerificationMeta(
    'preferredLanguage',
  );
  @override
  late final GeneratedColumn<String> preferredLanguage =
      GeneratedColumn<String>(
        'preferred_language',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memoryCaptureEnabledMeta =
      const VerificationMeta('memoryCaptureEnabled');
  @override
  late final GeneratedColumn<bool> memoryCaptureEnabled = GeneratedColumn<bool>(
    'memory_capture_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("memory_capture_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _permissionMeta = const VerificationMeta(
    'permission',
  );
  @override
  late final GeneratedColumn<String> permission = GeneratedColumn<String>(
    'permission',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    id,
    fullName,
    preferredLanguage,
    timezone,
    memoryCaptureEnabled,
    permission,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboard_patients';
  @override
  VerificationContext validateIntegrity(
    Insertable<DashboardPatient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('preferred_language')) {
      context.handle(
        _preferredLanguageMeta,
        preferredLanguage.isAcceptableOrUnknown(
          data['preferred_language']!,
          _preferredLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_preferredLanguageMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('memory_capture_enabled')) {
      context.handle(
        _memoryCaptureEnabledMeta,
        memoryCaptureEnabled.isAcceptableOrUnknown(
          data['memory_capture_enabled']!,
          _memoryCaptureEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_memoryCaptureEnabledMeta);
    }
    if (data.containsKey('permission')) {
      context.handle(
        _permissionMeta,
        permission.isAcceptableOrUnknown(data['permission']!, _permissionMeta),
      );
    } else if (isInserting) {
      context.missing(_permissionMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, id};
  @override
  DashboardPatient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DashboardPatient(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      preferredLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_language'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      memoryCaptureEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}memory_capture_enabled'],
      )!,
      permission: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permission'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $DashboardPatientsTable createAlias(String alias) {
    return $DashboardPatientsTable(attachedDatabase, alias);
  }
}

class DashboardPatient extends DataClass
    implements Insertable<DashboardPatient> {
  final String caregiverId;
  final String id;
  final String fullName;
  final String preferredLanguage;
  final String timezone;
  final bool memoryCaptureEnabled;
  final String permission;
  final int position;
  const DashboardPatient({
    required this.caregiverId,
    required this.id,
    required this.fullName,
    required this.preferredLanguage,
    required this.timezone,
    required this.memoryCaptureEnabled,
    required this.permission,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    map['preferred_language'] = Variable<String>(preferredLanguage);
    map['timezone'] = Variable<String>(timezone);
    map['memory_capture_enabled'] = Variable<bool>(memoryCaptureEnabled);
    map['permission'] = Variable<String>(permission);
    map['position'] = Variable<int>(position);
    return map;
  }

  DashboardPatientsCompanion toCompanion(bool nullToAbsent) {
    return DashboardPatientsCompanion(
      caregiverId: Value(caregiverId),
      id: Value(id),
      fullName: Value(fullName),
      preferredLanguage: Value(preferredLanguage),
      timezone: Value(timezone),
      memoryCaptureEnabled: Value(memoryCaptureEnabled),
      permission: Value(permission),
      position: Value(position),
    );
  }

  factory DashboardPatient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DashboardPatient(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      preferredLanguage: serializer.fromJson<String>(json['preferredLanguage']),
      timezone: serializer.fromJson<String>(json['timezone']),
      memoryCaptureEnabled: serializer.fromJson<bool>(
        json['memoryCaptureEnabled'],
      ),
      permission: serializer.fromJson<String>(json['permission']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'preferredLanguage': serializer.toJson<String>(preferredLanguage),
      'timezone': serializer.toJson<String>(timezone),
      'memoryCaptureEnabled': serializer.toJson<bool>(memoryCaptureEnabled),
      'permission': serializer.toJson<String>(permission),
      'position': serializer.toJson<int>(position),
    };
  }

  DashboardPatient copyWith({
    String? caregiverId,
    String? id,
    String? fullName,
    String? preferredLanguage,
    String? timezone,
    bool? memoryCaptureEnabled,
    String? permission,
    int? position,
  }) => DashboardPatient(
    caregiverId: caregiverId ?? this.caregiverId,
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    timezone: timezone ?? this.timezone,
    memoryCaptureEnabled: memoryCaptureEnabled ?? this.memoryCaptureEnabled,
    permission: permission ?? this.permission,
    position: position ?? this.position,
  );
  DashboardPatient copyWithCompanion(DashboardPatientsCompanion data) {
    return DashboardPatient(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      preferredLanguage: data.preferredLanguage.present
          ? data.preferredLanguage.value
          : this.preferredLanguage,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      memoryCaptureEnabled: data.memoryCaptureEnabled.present
          ? data.memoryCaptureEnabled.value
          : this.memoryCaptureEnabled,
      permission: data.permission.present
          ? data.permission.value
          : this.permission,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DashboardPatient(')
          ..write('caregiverId: $caregiverId, ')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('preferredLanguage: $preferredLanguage, ')
          ..write('timezone: $timezone, ')
          ..write('memoryCaptureEnabled: $memoryCaptureEnabled, ')
          ..write('permission: $permission, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    id,
    fullName,
    preferredLanguage,
    timezone,
    memoryCaptureEnabled,
    permission,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardPatient &&
          other.caregiverId == this.caregiverId &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.preferredLanguage == this.preferredLanguage &&
          other.timezone == this.timezone &&
          other.memoryCaptureEnabled == this.memoryCaptureEnabled &&
          other.permission == this.permission &&
          other.position == this.position);
}

class DashboardPatientsCompanion extends UpdateCompanion<DashboardPatient> {
  final Value<String> caregiverId;
  final Value<String> id;
  final Value<String> fullName;
  final Value<String> preferredLanguage;
  final Value<String> timezone;
  final Value<bool> memoryCaptureEnabled;
  final Value<String> permission;
  final Value<int> position;
  final Value<int> rowid;
  const DashboardPatientsCompanion({
    this.caregiverId = const Value.absent(),
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.preferredLanguage = const Value.absent(),
    this.timezone = const Value.absent(),
    this.memoryCaptureEnabled = const Value.absent(),
    this.permission = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DashboardPatientsCompanion.insert({
    required String caregiverId,
    required String id,
    required String fullName,
    required String preferredLanguage,
    required String timezone,
    required bool memoryCaptureEnabled,
    required String permission,
    required int position,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       id = Value(id),
       fullName = Value(fullName),
       preferredLanguage = Value(preferredLanguage),
       timezone = Value(timezone),
       memoryCaptureEnabled = Value(memoryCaptureEnabled),
       permission = Value(permission),
       position = Value(position);
  static Insertable<DashboardPatient> custom({
    Expression<String>? caregiverId,
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? preferredLanguage,
    Expression<String>? timezone,
    Expression<bool>? memoryCaptureEnabled,
    Expression<String>? permission,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (preferredLanguage != null) 'preferred_language': preferredLanguage,
      if (timezone != null) 'timezone': timezone,
      if (memoryCaptureEnabled != null)
        'memory_capture_enabled': memoryCaptureEnabled,
      if (permission != null) 'permission': permission,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DashboardPatientsCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? id,
    Value<String>? fullName,
    Value<String>? preferredLanguage,
    Value<String>? timezone,
    Value<bool>? memoryCaptureEnabled,
    Value<String>? permission,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return DashboardPatientsCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timezone: timezone ?? this.timezone,
      memoryCaptureEnabled: memoryCaptureEnabled ?? this.memoryCaptureEnabled,
      permission: permission ?? this.permission,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (preferredLanguage.present) {
      map['preferred_language'] = Variable<String>(preferredLanguage.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (memoryCaptureEnabled.present) {
      map['memory_capture_enabled'] = Variable<bool>(
        memoryCaptureEnabled.value,
      );
    }
    if (permission.present) {
      map['permission'] = Variable<String>(permission.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DashboardPatientsCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('preferredLanguage: $preferredLanguage, ')
          ..write('timezone: $timezone, ')
          ..write('memoryCaptureEnabled: $memoryCaptureEnabled, ')
          ..write('permission: $permission, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DashboardDevicesTable extends DashboardDevices
    with TableInfo<$DashboardDevicesTable, DashboardDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serialMeta = const VerificationMeta('serial');
  @override
  late final GeneratedColumn<String> serial = GeneratedColumn<String>(
    'serial',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firmwareVersionMeta = const VerificationMeta(
    'firmwareVersion',
  );
  @override
  late final GeneratedColumn<String> firmwareVersion = GeneratedColumn<String>(
    'firmware_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> pairedAt =
      GeneratedColumn<int>(
        'paired_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($DashboardDevicesTable.$converterpairedAtn);
  static const VerificationMeta _onlineMeta = const VerificationMeta('online');
  @override
  late final GeneratedColumn<bool> online = GeneratedColumn<bool>(
    'online',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("online" IN (0, 1))',
    ),
  );
  static const VerificationMeta _batteryPctMeta = const VerificationMeta(
    'batteryPct',
  );
  @override
  late final GeneratedColumn<int> batteryPct = GeneratedColumn<int>(
    'battery_pct',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastSeenAt =
      GeneratedColumn<int>(
        'last_seen_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($DashboardDevicesTable.$converterlastSeenAtn);
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    id,
    serial,
    firmwareVersion,
    pairedAt,
    online,
    batteryPct,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboard_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<DashboardDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('serial')) {
      context.handle(
        _serialMeta,
        serial.isAcceptableOrUnknown(data['serial']!, _serialMeta),
      );
    } else if (isInserting) {
      context.missing(_serialMeta);
    }
    if (data.containsKey('firmware_version')) {
      context.handle(
        _firmwareVersionMeta,
        firmwareVersion.isAcceptableOrUnknown(
          data['firmware_version']!,
          _firmwareVersionMeta,
        ),
      );
    }
    if (data.containsKey('online')) {
      context.handle(
        _onlineMeta,
        online.isAcceptableOrUnknown(data['online']!, _onlineMeta),
      );
    } else if (isInserting) {
      context.missing(_onlineMeta);
    }
    if (data.containsKey('battery_pct')) {
      context.handle(
        _batteryPctMeta,
        batteryPct.isAcceptableOrUnknown(data['battery_pct']!, _batteryPctMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, id};
  @override
  DashboardDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DashboardDevice(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial'],
      )!,
      firmwareVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firmware_version'],
      ),
      pairedAt: $DashboardDevicesTable.$converterpairedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}paired_at'],
        ),
      ),
      online: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}online'],
      )!,
      batteryPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery_pct'],
      ),
      lastSeenAt: $DashboardDevicesTable.$converterlastSeenAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_seen_at'],
        ),
      ),
    );
  }

  @override
  $DashboardDevicesTable createAlias(String alias) {
    return $DashboardDevicesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterpairedAt = const UtcMicros();
  static TypeConverter<DateTime?, int?> $converterpairedAtn =
      NullAwareTypeConverter.wrap($converterpairedAt);
  static TypeConverter<DateTime, int> $converterlastSeenAt = const UtcMicros();
  static TypeConverter<DateTime?, int?> $converterlastSeenAtn =
      NullAwareTypeConverter.wrap($converterlastSeenAt);
}

class DashboardDevice extends DataClass implements Insertable<DashboardDevice> {
  final String caregiverId;
  final String patientId;
  final String id;
  final String serial;
  final String? firmwareVersion;
  final DateTime? pairedAt;
  final bool online;
  final int? batteryPct;
  final DateTime? lastSeenAt;
  const DashboardDevice({
    required this.caregiverId,
    required this.patientId,
    required this.id,
    required this.serial,
    this.firmwareVersion,
    this.pairedAt,
    required this.online,
    this.batteryPct,
    this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['id'] = Variable<String>(id);
    map['serial'] = Variable<String>(serial);
    if (!nullToAbsent || firmwareVersion != null) {
      map['firmware_version'] = Variable<String>(firmwareVersion);
    }
    if (!nullToAbsent || pairedAt != null) {
      map['paired_at'] = Variable<int>(
        $DashboardDevicesTable.$converterpairedAtn.toSql(pairedAt),
      );
    }
    map['online'] = Variable<bool>(online);
    if (!nullToAbsent || batteryPct != null) {
      map['battery_pct'] = Variable<int>(batteryPct);
    }
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<int>(
        $DashboardDevicesTable.$converterlastSeenAtn.toSql(lastSeenAt),
      );
    }
    return map;
  }

  DashboardDevicesCompanion toCompanion(bool nullToAbsent) {
    return DashboardDevicesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      id: Value(id),
      serial: Value(serial),
      firmwareVersion: firmwareVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(firmwareVersion),
      pairedAt: pairedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pairedAt),
      online: Value(online),
      batteryPct: batteryPct == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryPct),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
    );
  }

  factory DashboardDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DashboardDevice(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      serial: serializer.fromJson<String>(json['serial']),
      firmwareVersion: serializer.fromJson<String?>(json['firmwareVersion']),
      pairedAt: serializer.fromJson<DateTime?>(json['pairedAt']),
      online: serializer.fromJson<bool>(json['online']),
      batteryPct: serializer.fromJson<int?>(json['batteryPct']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'serial': serializer.toJson<String>(serial),
      'firmwareVersion': serializer.toJson<String?>(firmwareVersion),
      'pairedAt': serializer.toJson<DateTime?>(pairedAt),
      'online': serializer.toJson<bool>(online),
      'batteryPct': serializer.toJson<int?>(batteryPct),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
    };
  }

  DashboardDevice copyWith({
    String? caregiverId,
    String? patientId,
    String? id,
    String? serial,
    Value<String?> firmwareVersion = const Value.absent(),
    Value<DateTime?> pairedAt = const Value.absent(),
    bool? online,
    Value<int?> batteryPct = const Value.absent(),
    Value<DateTime?> lastSeenAt = const Value.absent(),
  }) => DashboardDevice(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    serial: serial ?? this.serial,
    firmwareVersion: firmwareVersion.present
        ? firmwareVersion.value
        : this.firmwareVersion,
    pairedAt: pairedAt.present ? pairedAt.value : this.pairedAt,
    online: online ?? this.online,
    batteryPct: batteryPct.present ? batteryPct.value : this.batteryPct,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
  );
  DashboardDevice copyWithCompanion(DashboardDevicesCompanion data) {
    return DashboardDevice(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      serial: data.serial.present ? data.serial.value : this.serial,
      firmwareVersion: data.firmwareVersion.present
          ? data.firmwareVersion.value
          : this.firmwareVersion,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
      online: data.online.present ? data.online.value : this.online,
      batteryPct: data.batteryPct.present
          ? data.batteryPct.value
          : this.batteryPct,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DashboardDevice(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('serial: $serial, ')
          ..write('firmwareVersion: $firmwareVersion, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('online: $online, ')
          ..write('batteryPct: $batteryPct, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    id,
    serial,
    firmwareVersion,
    pairedAt,
    online,
    batteryPct,
    lastSeenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardDevice &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.serial == this.serial &&
          other.firmwareVersion == this.firmwareVersion &&
          other.pairedAt == this.pairedAt &&
          other.online == this.online &&
          other.batteryPct == this.batteryPct &&
          other.lastSeenAt == this.lastSeenAt);
}

class DashboardDevicesCompanion extends UpdateCompanion<DashboardDevice> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> id;
  final Value<String> serial;
  final Value<String?> firmwareVersion;
  final Value<DateTime?> pairedAt;
  final Value<bool> online;
  final Value<int?> batteryPct;
  final Value<DateTime?> lastSeenAt;
  final Value<int> rowid;
  const DashboardDevicesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.id = const Value.absent(),
    this.serial = const Value.absent(),
    this.firmwareVersion = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.online = const Value.absent(),
    this.batteryPct = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DashboardDevicesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String id,
    required String serial,
    this.firmwareVersion = const Value.absent(),
    this.pairedAt = const Value.absent(),
    required bool online,
    this.batteryPct = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       id = Value(id),
       serial = Value(serial),
       online = Value(online);
  static Insertable<DashboardDevice> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? id,
    Expression<String>? serial,
    Expression<String>? firmwareVersion,
    Expression<int>? pairedAt,
    Expression<bool>? online,
    Expression<int>? batteryPct,
    Expression<int>? lastSeenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (serial != null) 'serial': serial,
      if (firmwareVersion != null) 'firmware_version': firmwareVersion,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (online != null) 'online': online,
      if (batteryPct != null) 'battery_pct': batteryPct,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DashboardDevicesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? id,
    Value<String>? serial,
    Value<String?>? firmwareVersion,
    Value<DateTime?>? pairedAt,
    Value<bool>? online,
    Value<int?>? batteryPct,
    Value<DateTime?>? lastSeenAt,
    Value<int>? rowid,
  }) {
    return DashboardDevicesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      serial: serial ?? this.serial,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      pairedAt: pairedAt ?? this.pairedAt,
      online: online ?? this.online,
      batteryPct: batteryPct ?? this.batteryPct,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serial.present) {
      map['serial'] = Variable<String>(serial.value);
    }
    if (firmwareVersion.present) {
      map['firmware_version'] = Variable<String>(firmwareVersion.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<int>(
        $DashboardDevicesTable.$converterpairedAtn.toSql(pairedAt.value),
      );
    }
    if (online.present) {
      map['online'] = Variable<bool>(online.value);
    }
    if (batteryPct.present) {
      map['battery_pct'] = Variable<int>(batteryPct.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(
        $DashboardDevicesTable.$converterlastSeenAtn.toSql(lastSeenAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DashboardDevicesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('serial: $serial, ')
          ..write('firmwareVersion: $firmwareVersion, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('online: $online, ')
          ..write('batteryPct: $batteryPct, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DashboardAlertsTable extends DashboardAlerts
    with TableInfo<$DashboardAlertsTable, DashboardAlert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardAlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _alertTypeMeta = const VerificationMeta(
    'alertType',
  );
  @override
  late final GeneratedColumn<String> alertType = GeneratedColumn<String>(
    'alert_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($DashboardAlertsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> readAt =
      GeneratedColumn<int>(
        'read_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($DashboardAlertsTable.$converterreadAtn);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    id,
    patientId,
    alertType,
    message,
    createdAt,
    readAt,
    entityType,
    entityId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboard_alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DashboardAlert> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
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
    if (data.containsKey('alert_type')) {
      context.handle(
        _alertTypeMeta,
        alertType.isAcceptableOrUnknown(data['alert_type']!, _alertTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_alertTypeMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, id};
  @override
  DashboardAlert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DashboardAlert(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      alertType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alert_type'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      createdAt: $DashboardAlertsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      readAt: $DashboardAlertsTable.$converterreadAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}read_at'],
        ),
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      ),
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
    );
  }

  @override
  $DashboardAlertsTable createAlias(String alias) {
    return $DashboardAlertsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt = const UtcMicros();
  static TypeConverter<DateTime, int> $converterreadAt = const UtcMicros();
  static TypeConverter<DateTime?, int?> $converterreadAtn =
      NullAwareTypeConverter.wrap($converterreadAt);
}

class DashboardAlert extends DataClass implements Insertable<DashboardAlert> {
  final String caregiverId;
  final String id;
  final String patientId;
  final String alertType;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? entityType;
  final String? entityId;
  const DashboardAlert({
    required this.caregiverId,
    required this.id,
    required this.patientId,
    required this.alertType,
    required this.message,
    required this.createdAt,
    this.readAt,
    this.entityType,
    this.entityId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['alert_type'] = Variable<String>(alertType);
    map['message'] = Variable<String>(message);
    {
      map['created_at'] = Variable<int>(
        $DashboardAlertsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<int>(
        $DashboardAlertsTable.$converterreadAtn.toSql(readAt),
      );
    }
    if (!nullToAbsent || entityType != null) {
      map['entity_type'] = Variable<String>(entityType);
    }
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    return map;
  }

  DashboardAlertsCompanion toCompanion(bool nullToAbsent) {
    return DashboardAlertsCompanion(
      caregiverId: Value(caregiverId),
      id: Value(id),
      patientId: Value(patientId),
      alertType: Value(alertType),
      message: Value(message),
      createdAt: Value(createdAt),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      entityType: entityType == null && nullToAbsent
          ? const Value.absent()
          : Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
    );
  }

  factory DashboardAlert.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DashboardAlert(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      alertType: serializer.fromJson<String>(json['alertType']),
      message: serializer.fromJson<String>(json['message']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      entityType: serializer.fromJson<String?>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'alertType': serializer.toJson<String>(alertType),
      'message': serializer.toJson<String>(message),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'entityType': serializer.toJson<String?>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
    };
  }

  DashboardAlert copyWith({
    String? caregiverId,
    String? id,
    String? patientId,
    String? alertType,
    String? message,
    DateTime? createdAt,
    Value<DateTime?> readAt = const Value.absent(),
    Value<String?> entityType = const Value.absent(),
    Value<String?> entityId = const Value.absent(),
  }) => DashboardAlert(
    caregiverId: caregiverId ?? this.caregiverId,
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    alertType: alertType ?? this.alertType,
    message: message ?? this.message,
    createdAt: createdAt ?? this.createdAt,
    readAt: readAt.present ? readAt.value : this.readAt,
    entityType: entityType.present ? entityType.value : this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
  );
  DashboardAlert copyWithCompanion(DashboardAlertsCompanion data) {
    return DashboardAlert(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      alertType: data.alertType.present ? data.alertType.value : this.alertType,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DashboardAlert(')
          ..write('caregiverId: $caregiverId, ')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('alertType: $alertType, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    id,
    patientId,
    alertType,
    message,
    createdAt,
    readAt,
    entityType,
    entityId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardAlert &&
          other.caregiverId == this.caregiverId &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.alertType == this.alertType &&
          other.message == this.message &&
          other.createdAt == this.createdAt &&
          other.readAt == this.readAt &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId);
}

class DashboardAlertsCompanion extends UpdateCompanion<DashboardAlert> {
  final Value<String> caregiverId;
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> alertType;
  final Value<String> message;
  final Value<DateTime> createdAt;
  final Value<DateTime?> readAt;
  final Value<String?> entityType;
  final Value<String?> entityId;
  final Value<int> rowid;
  const DashboardAlertsCompanion({
    this.caregiverId = const Value.absent(),
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.alertType = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DashboardAlertsCompanion.insert({
    required String caregiverId,
    required String id,
    required String patientId,
    required String alertType,
    required String message,
    required DateTime createdAt,
    this.readAt = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       id = Value(id),
       patientId = Value(patientId),
       alertType = Value(alertType),
       message = Value(message),
       createdAt = Value(createdAt);
  static Insertable<DashboardAlert> custom({
    Expression<String>? caregiverId,
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? alertType,
    Expression<String>? message,
    Expression<int>? createdAt,
    Expression<int>? readAt,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (alertType != null) 'alert_type': alertType,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
      if (readAt != null) 'read_at': readAt,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DashboardAlertsCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? alertType,
    Value<String>? message,
    Value<DateTime>? createdAt,
    Value<DateTime?>? readAt,
    Value<String?>? entityType,
    Value<String?>? entityId,
    Value<int>? rowid,
  }) {
    return DashboardAlertsCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      alertType: alertType ?? this.alertType,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (alertType.present) {
      map['alert_type'] = Variable<String>(alertType.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $DashboardAlertsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (readAt.present) {
      map['read_at'] = Variable<int>(
        $DashboardAlertsTable.$converterreadAtn.toSql(readAt.value),
      );
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DashboardAlertsCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('alertType: $alertType, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DashboardDaysTable extends DashboardDays
    with TableInfo<$DashboardDaysTable, DashboardDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peopleMetMeta = const VerificationMeta(
    'peopleMet',
  );
  @override
  late final GeneratedColumn<int> peopleMet = GeneratedColumn<int>(
    'people_met',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remindersDoneMeta = const VerificationMeta(
    'remindersDone',
  );
  @override
  late final GeneratedColumn<int> remindersDone = GeneratedColumn<int>(
    'reminders_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remindersTotalMeta = const VerificationMeta(
    'remindersTotal',
  );
  @override
  late final GeneratedColumn<int> remindersTotal = GeneratedColumn<int>(
    'reminders_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snoozedMeta = const VerificationMeta(
    'snoozed',
  );
  @override
  late final GeneratedColumn<int> snoozed = GeneratedColumn<int>(
    'snoozed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($DashboardDaysTable.$converterrefreshedAt);
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    day,
    peopleMet,
    remindersDone,
    remindersTotal,
    snoozed,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboard_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<DashboardDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('people_met')) {
      context.handle(
        _peopleMetMeta,
        peopleMet.isAcceptableOrUnknown(data['people_met']!, _peopleMetMeta),
      );
    } else if (isInserting) {
      context.missing(_peopleMetMeta);
    }
    if (data.containsKey('reminders_done')) {
      context.handle(
        _remindersDoneMeta,
        remindersDone.isAcceptableOrUnknown(
          data['reminders_done']!,
          _remindersDoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remindersDoneMeta);
    }
    if (data.containsKey('reminders_total')) {
      context.handle(
        _remindersTotalMeta,
        remindersTotal.isAcceptableOrUnknown(
          data['reminders_total']!,
          _remindersTotalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remindersTotalMeta);
    }
    if (data.containsKey('snoozed')) {
      context.handle(
        _snoozedMeta,
        snoozed.isAcceptableOrUnknown(data['snoozed']!, _snoozedMeta),
      );
    } else if (isInserting) {
      context.missing(_snoozedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, day};
  @override
  DashboardDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DashboardDay(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      peopleMet: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}people_met'],
      )!,
      remindersDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminders_done'],
      )!,
      remindersTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminders_total'],
      )!,
      snoozed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snoozed'],
      )!,
      refreshedAt: $DashboardDaysTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $DashboardDaysTable createAlias(String alias) {
    return $DashboardDaysTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class DashboardDay extends DataClass implements Insertable<DashboardDay> {
  final String caregiverId;
  final String patientId;
  final String day;
  final int peopleMet;
  final int remindersDone;
  final int remindersTotal;
  final int snoozed;
  final DateTime refreshedAt;
  const DashboardDay({
    required this.caregiverId,
    required this.patientId,
    required this.day,
    required this.peopleMet,
    required this.remindersDone,
    required this.remindersTotal,
    required this.snoozed,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['day'] = Variable<String>(day);
    map['people_met'] = Variable<int>(peopleMet);
    map['reminders_done'] = Variable<int>(remindersDone);
    map['reminders_total'] = Variable<int>(remindersTotal);
    map['snoozed'] = Variable<int>(snoozed);
    {
      map['refreshed_at'] = Variable<int>(
        $DashboardDaysTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  DashboardDaysCompanion toCompanion(bool nullToAbsent) {
    return DashboardDaysCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      day: Value(day),
      peopleMet: Value(peopleMet),
      remindersDone: Value(remindersDone),
      remindersTotal: Value(remindersTotal),
      snoozed: Value(snoozed),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory DashboardDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DashboardDay(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      day: serializer.fromJson<String>(json['day']),
      peopleMet: serializer.fromJson<int>(json['peopleMet']),
      remindersDone: serializer.fromJson<int>(json['remindersDone']),
      remindersTotal: serializer.fromJson<int>(json['remindersTotal']),
      snoozed: serializer.fromJson<int>(json['snoozed']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'day': serializer.toJson<String>(day),
      'peopleMet': serializer.toJson<int>(peopleMet),
      'remindersDone': serializer.toJson<int>(remindersDone),
      'remindersTotal': serializer.toJson<int>(remindersTotal),
      'snoozed': serializer.toJson<int>(snoozed),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  DashboardDay copyWith({
    String? caregiverId,
    String? patientId,
    String? day,
    int? peopleMet,
    int? remindersDone,
    int? remindersTotal,
    int? snoozed,
    DateTime? refreshedAt,
  }) => DashboardDay(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    day: day ?? this.day,
    peopleMet: peopleMet ?? this.peopleMet,
    remindersDone: remindersDone ?? this.remindersDone,
    remindersTotal: remindersTotal ?? this.remindersTotal,
    snoozed: snoozed ?? this.snoozed,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  DashboardDay copyWithCompanion(DashboardDaysCompanion data) {
    return DashboardDay(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      day: data.day.present ? data.day.value : this.day,
      peopleMet: data.peopleMet.present ? data.peopleMet.value : this.peopleMet,
      remindersDone: data.remindersDone.present
          ? data.remindersDone.value
          : this.remindersDone,
      remindersTotal: data.remindersTotal.present
          ? data.remindersTotal.value
          : this.remindersTotal,
      snoozed: data.snoozed.present ? data.snoozed.value : this.snoozed,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DashboardDay(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('day: $day, ')
          ..write('peopleMet: $peopleMet, ')
          ..write('remindersDone: $remindersDone, ')
          ..write('remindersTotal: $remindersTotal, ')
          ..write('snoozed: $snoozed, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    day,
    peopleMet,
    remindersDone,
    remindersTotal,
    snoozed,
    refreshedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardDay &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.day == this.day &&
          other.peopleMet == this.peopleMet &&
          other.remindersDone == this.remindersDone &&
          other.remindersTotal == this.remindersTotal &&
          other.snoozed == this.snoozed &&
          other.refreshedAt == this.refreshedAt);
}

class DashboardDaysCompanion extends UpdateCompanion<DashboardDay> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> day;
  final Value<int> peopleMet;
  final Value<int> remindersDone;
  final Value<int> remindersTotal;
  final Value<int> snoozed;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const DashboardDaysCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.day = const Value.absent(),
    this.peopleMet = const Value.absent(),
    this.remindersDone = const Value.absent(),
    this.remindersTotal = const Value.absent(),
    this.snoozed = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DashboardDaysCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String day,
    required int peopleMet,
    required int remindersDone,
    required int remindersTotal,
    required int snoozed,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       day = Value(day),
       peopleMet = Value(peopleMet),
       remindersDone = Value(remindersDone),
       remindersTotal = Value(remindersTotal),
       snoozed = Value(snoozed),
       refreshedAt = Value(refreshedAt);
  static Insertable<DashboardDay> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? day,
    Expression<int>? peopleMet,
    Expression<int>? remindersDone,
    Expression<int>? remindersTotal,
    Expression<int>? snoozed,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (day != null) 'day': day,
      if (peopleMet != null) 'people_met': peopleMet,
      if (remindersDone != null) 'reminders_done': remindersDone,
      if (remindersTotal != null) 'reminders_total': remindersTotal,
      if (snoozed != null) 'snoozed': snoozed,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DashboardDaysCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? day,
    Value<int>? peopleMet,
    Value<int>? remindersDone,
    Value<int>? remindersTotal,
    Value<int>? snoozed,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return DashboardDaysCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      day: day ?? this.day,
      peopleMet: peopleMet ?? this.peopleMet,
      remindersDone: remindersDone ?? this.remindersDone,
      remindersTotal: remindersTotal ?? this.remindersTotal,
      snoozed: snoozed ?? this.snoozed,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (peopleMet.present) {
      map['people_met'] = Variable<int>(peopleMet.value);
    }
    if (remindersDone.present) {
      map['reminders_done'] = Variable<int>(remindersDone.value);
    }
    if (remindersTotal.present) {
      map['reminders_total'] = Variable<int>(remindersTotal.value);
    }
    if (snoozed.present) {
      map['snoozed'] = Variable<int>(snoozed.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $DashboardDaysTable.$converterrefreshedAt.toSql(refreshedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DashboardDaysCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('day: $day, ')
          ..write('peopleMet: $peopleMet, ')
          ..write('remindersDone: $remindersDone, ')
          ..write('remindersTotal: $remindersTotal, ')
          ..write('snoozed: $snoozed, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPeopleTable extends CachedPeople
    with TableInfo<$CachedPeopleTable, CachedPeopleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationshipMeta = const VerificationMeta(
    'relationship',
  );
  @override
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
    'relationship',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _embeddingCountMeta = const VerificationMeta(
    'embeddingCount',
  );
  @override
  late final GeneratedColumn<int> embeddingCount = GeneratedColumn<int>(
    'embedding_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedPeopleTable.$converterupdatedAt);
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    id,
    name,
    relationship,
    status,
    embeddingCount,
    updatedAt,
    photoUrl,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_people';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPeopleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('relationship')) {
      context.handle(
        _relationshipMeta,
        relationship.isAcceptableOrUnknown(
          data['relationship']!,
          _relationshipMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationshipMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('embedding_count')) {
      context.handle(
        _embeddingCountMeta,
        embeddingCount.isAcceptableOrUnknown(
          data['embedding_count']!,
          _embeddingCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_embeddingCountMeta);
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, id};
  @override
  CachedPeopleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPeopleData(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      relationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      embeddingCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}embedding_count'],
      )!,
      updatedAt: $CachedPeopleTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedPeopleTable createAlias(String alias) {
    return $CachedPeopleTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterupdatedAt = const UtcMicros();
}

class CachedPeopleData extends DataClass
    implements Insertable<CachedPeopleData> {
  final String caregiverId;
  final String patientId;
  final String id;
  final String name;
  final String relationship;
  final String status;
  final int embeddingCount;
  final DateTime updatedAt;
  final String? photoUrl;
  final int position;
  const CachedPeopleData({
    required this.caregiverId,
    required this.patientId,
    required this.id,
    required this.name,
    required this.relationship,
    required this.status,
    required this.embeddingCount,
    required this.updatedAt,
    this.photoUrl,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['relationship'] = Variable<String>(relationship);
    map['status'] = Variable<String>(status);
    map['embedding_count'] = Variable<int>(embeddingCount);
    {
      map['updated_at'] = Variable<int>(
        $CachedPeopleTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedPeopleCompanion toCompanion(bool nullToAbsent) {
    return CachedPeopleCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      id: Value(id),
      name: Value(name),
      relationship: Value(relationship),
      status: Value(status),
      embeddingCount: Value(embeddingCount),
      updatedAt: Value(updatedAt),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      position: Value(position),
    );
  }

  factory CachedPeopleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPeopleData(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      relationship: serializer.fromJson<String>(json['relationship']),
      status: serializer.fromJson<String>(json['status']),
      embeddingCount: serializer.fromJson<int>(json['embeddingCount']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'relationship': serializer.toJson<String>(relationship),
      'status': serializer.toJson<String>(status),
      'embeddingCount': serializer.toJson<int>(embeddingCount),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedPeopleData copyWith({
    String? caregiverId,
    String? patientId,
    String? id,
    String? name,
    String? relationship,
    String? status,
    int? embeddingCount,
    DateTime? updatedAt,
    Value<String?> photoUrl = const Value.absent(),
    int? position,
  }) => CachedPeopleData(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    name: name ?? this.name,
    relationship: relationship ?? this.relationship,
    status: status ?? this.status,
    embeddingCount: embeddingCount ?? this.embeddingCount,
    updatedAt: updatedAt ?? this.updatedAt,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    position: position ?? this.position,
  );
  CachedPeopleData copyWithCompanion(CachedPeopleCompanion data) {
    return CachedPeopleData(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      status: data.status.present ? data.status.value : this.status,
      embeddingCount: data.embeddingCount.present
          ? data.embeddingCount.value
          : this.embeddingCount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPeopleData(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('relationship: $relationship, ')
          ..write('status: $status, ')
          ..write('embeddingCount: $embeddingCount, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    id,
    name,
    relationship,
    status,
    embeddingCount,
    updatedAt,
    photoUrl,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPeopleData &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.name == this.name &&
          other.relationship == this.relationship &&
          other.status == this.status &&
          other.embeddingCount == this.embeddingCount &&
          other.updatedAt == this.updatedAt &&
          other.photoUrl == this.photoUrl &&
          other.position == this.position);
}

class CachedPeopleCompanion extends UpdateCompanion<CachedPeopleData> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> id;
  final Value<String> name;
  final Value<String> relationship;
  final Value<String> status;
  final Value<int> embeddingCount;
  final Value<DateTime> updatedAt;
  final Value<String?> photoUrl;
  final Value<int> position;
  final Value<int> rowid;
  const CachedPeopleCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.relationship = const Value.absent(),
    this.status = const Value.absent(),
    this.embeddingCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPeopleCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String id,
    required String name,
    required String relationship,
    required String status,
    required int embeddingCount,
    required DateTime updatedAt,
    this.photoUrl = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       id = Value(id),
       name = Value(name),
       relationship = Value(relationship),
       status = Value(status),
       embeddingCount = Value(embeddingCount),
       updatedAt = Value(updatedAt),
       position = Value(position);
  static Insertable<CachedPeopleData> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? relationship,
    Expression<String>? status,
    Expression<int>? embeddingCount,
    Expression<int>? updatedAt,
    Expression<String>? photoUrl,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (relationship != null) 'relationship': relationship,
      if (status != null) 'status': status,
      if (embeddingCount != null) 'embedding_count': embeddingCount,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPeopleCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? id,
    Value<String>? name,
    Value<String>? relationship,
    Value<String>? status,
    Value<int>? embeddingCount,
    Value<DateTime>? updatedAt,
    Value<String?>? photoUrl,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CachedPeopleCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      status: status ?? this.status,
      embeddingCount: embeddingCount ?? this.embeddingCount,
      updatedAt: updatedAt ?? this.updatedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (embeddingCount.present) {
      map['embedding_count'] = Variable<int>(embeddingCount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $CachedPeopleTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPeopleCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('relationship: $relationship, ')
          ..write('status: $status, ')
          ..write('embeddingCount: $embeddingCount, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleCacheStatesTable extends PeopleCacheStates
    with TableInfo<$PeopleCacheStatesTable, PeopleCacheState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleCacheStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _unknownCountMeta = const VerificationMeta(
    'unknownCount',
  );
  @override
  late final GeneratedColumn<int> unknownCount = GeneratedColumn<int>(
    'unknown_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PeopleCacheStatesTable.$converterrefreshedAt);
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    unknownCount,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people_cache_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeopleCacheState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('unknown_count')) {
      context.handle(
        _unknownCountMeta,
        unknownCount.isAcceptableOrUnknown(
          data['unknown_count']!,
          _unknownCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unknownCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId};
  @override
  PeopleCacheState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeopleCacheState(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      unknownCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unknown_count'],
      )!,
      refreshedAt: $PeopleCacheStatesTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $PeopleCacheStatesTable createAlias(String alias) {
    return $PeopleCacheStatesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class PeopleCacheState extends DataClass
    implements Insertable<PeopleCacheState> {
  final String caregiverId;
  final String patientId;
  final int unknownCount;
  final DateTime refreshedAt;
  const PeopleCacheState({
    required this.caregiverId,
    required this.patientId,
    required this.unknownCount,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['unknown_count'] = Variable<int>(unknownCount);
    {
      map['refreshed_at'] = Variable<int>(
        $PeopleCacheStatesTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  PeopleCacheStatesCompanion toCompanion(bool nullToAbsent) {
    return PeopleCacheStatesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      unknownCount: Value(unknownCount),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory PeopleCacheState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeopleCacheState(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      unknownCount: serializer.fromJson<int>(json['unknownCount']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'unknownCount': serializer.toJson<int>(unknownCount),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  PeopleCacheState copyWith({
    String? caregiverId,
    String? patientId,
    int? unknownCount,
    DateTime? refreshedAt,
  }) => PeopleCacheState(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    unknownCount: unknownCount ?? this.unknownCount,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  PeopleCacheState copyWithCompanion(PeopleCacheStatesCompanion data) {
    return PeopleCacheState(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      unknownCount: data.unknownCount.present
          ? data.unknownCount.value
          : this.unknownCount,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCacheState(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('unknownCount: $unknownCount, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(caregiverId, patientId, unknownCount, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeopleCacheState &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.unknownCount == this.unknownCount &&
          other.refreshedAt == this.refreshedAt);
}

class PeopleCacheStatesCompanion extends UpdateCompanion<PeopleCacheState> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<int> unknownCount;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const PeopleCacheStatesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.unknownCount = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleCacheStatesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required int unknownCount,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       unknownCount = Value(unknownCount),
       refreshedAt = Value(refreshedAt);
  static Insertable<PeopleCacheState> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<int>? unknownCount,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (unknownCount != null) 'unknown_count': unknownCount,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleCacheStatesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<int>? unknownCount,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return PeopleCacheStatesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      unknownCount: unknownCount ?? this.unknownCount,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (unknownCount.present) {
      map['unknown_count'] = Variable<int>(unknownCount.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $PeopleCacheStatesTable.$converterrefreshedAt.toSql(refreshedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCacheStatesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('unknownCount: $unknownCount, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonDetailStatesTable extends PersonDetailStates
    with TableInfo<$PersonDetailStatesTable, PersonDetailState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonDetailStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enrolledByNameMeta = const VerificationMeta(
    'enrolledByName',
  );
  @override
  late final GeneratedColumn<String> enrolledByName = GeneratedColumn<String>(
    'enrolled_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PersonDetailStatesTable.$converterrefreshedAt);
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    personId,
    enrolledByName,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'person_detail_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonDetailState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('enrolled_by_name')) {
      context.handle(
        _enrolledByNameMeta,
        enrolledByName.isAcceptableOrUnknown(
          data['enrolled_by_name']!,
          _enrolledByNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, personId};
  @override
  PersonDetailState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonDetailState(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      enrolledByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enrolled_by_name'],
      ),
      refreshedAt: $PersonDetailStatesTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $PersonDetailStatesTable createAlias(String alias) {
    return $PersonDetailStatesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class PersonDetailState extends DataClass
    implements Insertable<PersonDetailState> {
  final String caregiverId;
  final String patientId;
  final String personId;
  final String? enrolledByName;
  final DateTime refreshedAt;
  const PersonDetailState({
    required this.caregiverId,
    required this.patientId,
    required this.personId,
    this.enrolledByName,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['person_id'] = Variable<String>(personId);
    if (!nullToAbsent || enrolledByName != null) {
      map['enrolled_by_name'] = Variable<String>(enrolledByName);
    }
    {
      map['refreshed_at'] = Variable<int>(
        $PersonDetailStatesTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  PersonDetailStatesCompanion toCompanion(bool nullToAbsent) {
    return PersonDetailStatesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      personId: Value(personId),
      enrolledByName: enrolledByName == null && nullToAbsent
          ? const Value.absent()
          : Value(enrolledByName),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory PersonDetailState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonDetailState(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      personId: serializer.fromJson<String>(json['personId']),
      enrolledByName: serializer.fromJson<String?>(json['enrolledByName']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'personId': serializer.toJson<String>(personId),
      'enrolledByName': serializer.toJson<String?>(enrolledByName),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  PersonDetailState copyWith({
    String? caregiverId,
    String? patientId,
    String? personId,
    Value<String?> enrolledByName = const Value.absent(),
    DateTime? refreshedAt,
  }) => PersonDetailState(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    personId: personId ?? this.personId,
    enrolledByName: enrolledByName.present
        ? enrolledByName.value
        : this.enrolledByName,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  PersonDetailState copyWithCompanion(PersonDetailStatesCompanion data) {
    return PersonDetailState(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      personId: data.personId.present ? data.personId.value : this.personId,
      enrolledByName: data.enrolledByName.present
          ? data.enrolledByName.value
          : this.enrolledByName,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonDetailState(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('personId: $personId, ')
          ..write('enrolledByName: $enrolledByName, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    personId,
    enrolledByName,
    refreshedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonDetailState &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.personId == this.personId &&
          other.enrolledByName == this.enrolledByName &&
          other.refreshedAt == this.refreshedAt);
}

class PersonDetailStatesCompanion extends UpdateCompanion<PersonDetailState> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> personId;
  final Value<String?> enrolledByName;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const PersonDetailStatesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.personId = const Value.absent(),
    this.enrolledByName = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonDetailStatesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String personId,
    this.enrolledByName = const Value.absent(),
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       personId = Value(personId),
       refreshedAt = Value(refreshedAt);
  static Insertable<PersonDetailState> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? personId,
    Expression<String>? enrolledByName,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (personId != null) 'person_id': personId,
      if (enrolledByName != null) 'enrolled_by_name': enrolledByName,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonDetailStatesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? personId,
    Value<String?>? enrolledByName,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return PersonDetailStatesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      personId: personId ?? this.personId,
      enrolledByName: enrolledByName ?? this.enrolledByName,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (enrolledByName.present) {
      map['enrolled_by_name'] = Variable<String>(enrolledByName.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $PersonDetailStatesTable.$converterrefreshedAt.toSql(refreshedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonDetailStatesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('personId: $personId, ')
          ..write('enrolledByName: $enrolledByName, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPersonPhotosTable extends CachedPersonPhotos
    with TableInfo<$CachedPersonPhotosTable, CachedPersonPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPersonPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    personId,
    id,
    url,
    thumbnailUrl,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_person_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPersonPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    caregiverId,
    patientId,
    personId,
    id,
  };
  @override
  CachedPersonPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPersonPhoto(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedPersonPhotosTable createAlias(String alias) {
    return $CachedPersonPhotosTable(attachedDatabase, alias);
  }
}

class CachedPersonPhoto extends DataClass
    implements Insertable<CachedPersonPhoto> {
  final String caregiverId;
  final String patientId;
  final String personId;
  final String id;
  final String url;
  final String? thumbnailUrl;
  final int position;
  const CachedPersonPhoto({
    required this.caregiverId,
    required this.patientId,
    required this.personId,
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['person_id'] = Variable<String>(personId);
    map['id'] = Variable<String>(id);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedPersonPhotosCompanion toCompanion(bool nullToAbsent) {
    return CachedPersonPhotosCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      personId: Value(personId),
      id: Value(id),
      url: Value(url),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      position: Value(position),
    );
  }

  factory CachedPersonPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPersonPhoto(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      personId: serializer.fromJson<String>(json['personId']),
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'personId': serializer.toJson<String>(personId),
      'id': serializer.toJson<String>(id),
      'url': serializer.toJson<String>(url),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedPersonPhoto copyWith({
    String? caregiverId,
    String? patientId,
    String? personId,
    String? id,
    String? url,
    Value<String?> thumbnailUrl = const Value.absent(),
    int? position,
  }) => CachedPersonPhoto(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    personId: personId ?? this.personId,
    id: id ?? this.id,
    url: url ?? this.url,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    position: position ?? this.position,
  );
  CachedPersonPhoto copyWithCompanion(CachedPersonPhotosCompanion data) {
    return CachedPersonPhoto(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      personId: data.personId.present ? data.personId.value : this.personId,
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPersonPhoto(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('personId: $personId, ')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    personId,
    id,
    url,
    thumbnailUrl,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPersonPhoto &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.personId == this.personId &&
          other.id == this.id &&
          other.url == this.url &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.position == this.position);
}

class CachedPersonPhotosCompanion extends UpdateCompanion<CachedPersonPhoto> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> personId;
  final Value<String> id;
  final Value<String> url;
  final Value<String?> thumbnailUrl;
  final Value<int> position;
  final Value<int> rowid;
  const CachedPersonPhotosCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.personId = const Value.absent(),
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPersonPhotosCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String personId,
    required String id,
    required String url,
    this.thumbnailUrl = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       personId = Value(personId),
       id = Value(id),
       url = Value(url),
       position = Value(position);
  static Insertable<CachedPersonPhoto> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? personId,
    Expression<String>? id,
    Expression<String>? url,
    Expression<String>? thumbnailUrl,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (personId != null) 'person_id': personId,
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPersonPhotosCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? personId,
    Value<String>? id,
    Value<String>? url,
    Value<String?>? thumbnailUrl,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CachedPersonPhotosCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      personId: personId ?? this.personId,
      id: id ?? this.id,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPersonPhotosCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('personId: $personId, ')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedRemindersTable extends CachedReminders
    with TableInfo<$CachedRemindersTable, CachedReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spokenTextMeta = const VerificationMeta(
    'spokenText',
  );
  @override
  late final GeneratedColumn<String> spokenText = GeneratedColumn<String>(
    'spoken_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> dtstart =
      GeneratedColumn<int>(
        'dtstart',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedRemindersTable.$converterdtstart);
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedRemindersTable.$converterupdatedAt);
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    id,
    title,
    spokenText,
    type,
    rrule,
    dtstart,
    timezone,
    active,
    updatedAt,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('spoken_text')) {
      context.handle(
        _spokenTextMeta,
        spokenText.isAcceptableOrUnknown(data['spoken_text']!, _spokenTextMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
    } else if (isInserting) {
      context.missing(_rruleMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, id};
  @override
  CachedReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedReminder(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      spokenText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spoken_text'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      )!,
      dtstart: $CachedRemindersTable.$converterdtstart.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}dtstart'],
        )!,
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      updatedAt: $CachedRemindersTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedRemindersTable createAlias(String alias) {
    return $CachedRemindersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdtstart = const UtcMicros();
  static TypeConverter<DateTime, int> $converterupdatedAt = const UtcMicros();
}

class CachedReminder extends DataClass implements Insertable<CachedReminder> {
  final String caregiverId;
  final String patientId;
  final String id;
  final String title;
  final String? spokenText;
  final String type;
  final String rrule;
  final DateTime dtstart;
  final String timezone;
  final bool active;
  final DateTime updatedAt;
  final int position;
  const CachedReminder({
    required this.caregiverId,
    required this.patientId,
    required this.id,
    required this.title,
    this.spokenText,
    required this.type,
    required this.rrule,
    required this.dtstart,
    required this.timezone,
    required this.active,
    required this.updatedAt,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || spokenText != null) {
      map['spoken_text'] = Variable<String>(spokenText);
    }
    map['type'] = Variable<String>(type);
    map['rrule'] = Variable<String>(rrule);
    {
      map['dtstart'] = Variable<int>(
        $CachedRemindersTable.$converterdtstart.toSql(dtstart),
      );
    }
    map['timezone'] = Variable<String>(timezone);
    map['active'] = Variable<bool>(active);
    {
      map['updated_at'] = Variable<int>(
        $CachedRemindersTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedRemindersCompanion toCompanion(bool nullToAbsent) {
    return CachedRemindersCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      id: Value(id),
      title: Value(title),
      spokenText: spokenText == null && nullToAbsent
          ? const Value.absent()
          : Value(spokenText),
      type: Value(type),
      rrule: Value(rrule),
      dtstart: Value(dtstart),
      timezone: Value(timezone),
      active: Value(active),
      updatedAt: Value(updatedAt),
      position: Value(position),
    );
  }

  factory CachedReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedReminder(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      spokenText: serializer.fromJson<String?>(json['spokenText']),
      type: serializer.fromJson<String>(json['type']),
      rrule: serializer.fromJson<String>(json['rrule']),
      dtstart: serializer.fromJson<DateTime>(json['dtstart']),
      timezone: serializer.fromJson<String>(json['timezone']),
      active: serializer.fromJson<bool>(json['active']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'spokenText': serializer.toJson<String?>(spokenText),
      'type': serializer.toJson<String>(type),
      'rrule': serializer.toJson<String>(rrule),
      'dtstart': serializer.toJson<DateTime>(dtstart),
      'timezone': serializer.toJson<String>(timezone),
      'active': serializer.toJson<bool>(active),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedReminder copyWith({
    String? caregiverId,
    String? patientId,
    String? id,
    String? title,
    Value<String?> spokenText = const Value.absent(),
    String? type,
    String? rrule,
    DateTime? dtstart,
    String? timezone,
    bool? active,
    DateTime? updatedAt,
    int? position,
  }) => CachedReminder(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    title: title ?? this.title,
    spokenText: spokenText.present ? spokenText.value : this.spokenText,
    type: type ?? this.type,
    rrule: rrule ?? this.rrule,
    dtstart: dtstart ?? this.dtstart,
    timezone: timezone ?? this.timezone,
    active: active ?? this.active,
    updatedAt: updatedAt ?? this.updatedAt,
    position: position ?? this.position,
  );
  CachedReminder copyWithCompanion(CachedRemindersCompanion data) {
    return CachedReminder(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      spokenText: data.spokenText.present
          ? data.spokenText.value
          : this.spokenText,
      type: data.type.present ? data.type.value : this.type,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      dtstart: data.dtstart.present ? data.dtstart.value : this.dtstart,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      active: data.active.present ? data.active.value : this.active,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedReminder(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('spokenText: $spokenText, ')
          ..write('type: $type, ')
          ..write('rrule: $rrule, ')
          ..write('dtstart: $dtstart, ')
          ..write('timezone: $timezone, ')
          ..write('active: $active, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    id,
    title,
    spokenText,
    type,
    rrule,
    dtstart,
    timezone,
    active,
    updatedAt,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedReminder &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.title == this.title &&
          other.spokenText == this.spokenText &&
          other.type == this.type &&
          other.rrule == this.rrule &&
          other.dtstart == this.dtstart &&
          other.timezone == this.timezone &&
          other.active == this.active &&
          other.updatedAt == this.updatedAt &&
          other.position == this.position);
}

class CachedRemindersCompanion extends UpdateCompanion<CachedReminder> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> id;
  final Value<String> title;
  final Value<String?> spokenText;
  final Value<String> type;
  final Value<String> rrule;
  final Value<DateTime> dtstart;
  final Value<String> timezone;
  final Value<bool> active;
  final Value<DateTime> updatedAt;
  final Value<int> position;
  final Value<int> rowid;
  const CachedRemindersCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.spokenText = const Value.absent(),
    this.type = const Value.absent(),
    this.rrule = const Value.absent(),
    this.dtstart = const Value.absent(),
    this.timezone = const Value.absent(),
    this.active = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedRemindersCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String id,
    required String title,
    this.spokenText = const Value.absent(),
    required String type,
    required String rrule,
    required DateTime dtstart,
    required String timezone,
    required bool active,
    required DateTime updatedAt,
    required int position,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       id = Value(id),
       title = Value(title),
       type = Value(type),
       rrule = Value(rrule),
       dtstart = Value(dtstart),
       timezone = Value(timezone),
       active = Value(active),
       updatedAt = Value(updatedAt),
       position = Value(position);
  static Insertable<CachedReminder> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? spokenText,
    Expression<String>? type,
    Expression<String>? rrule,
    Expression<int>? dtstart,
    Expression<String>? timezone,
    Expression<bool>? active,
    Expression<int>? updatedAt,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (spokenText != null) 'spoken_text': spokenText,
      if (type != null) 'type': type,
      if (rrule != null) 'rrule': rrule,
      if (dtstart != null) 'dtstart': dtstart,
      if (timezone != null) 'timezone': timezone,
      if (active != null) 'active': active,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedRemindersCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? id,
    Value<String>? title,
    Value<String?>? spokenText,
    Value<String>? type,
    Value<String>? rrule,
    Value<DateTime>? dtstart,
    Value<String>? timezone,
    Value<bool>? active,
    Value<DateTime>? updatedAt,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CachedRemindersCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      title: title ?? this.title,
      spokenText: spokenText ?? this.spokenText,
      type: type ?? this.type,
      rrule: rrule ?? this.rrule,
      dtstart: dtstart ?? this.dtstart,
      timezone: timezone ?? this.timezone,
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (spokenText.present) {
      map['spoken_text'] = Variable<String>(spokenText.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (dtstart.present) {
      map['dtstart'] = Variable<int>(
        $CachedRemindersTable.$converterdtstart.toSql(dtstart.value),
      );
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $CachedRemindersTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRemindersCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('spokenText: $spokenText, ')
          ..write('type: $type, ')
          ..write('rrule: $rrule, ')
          ..write('dtstart: $dtstart, ')
          ..write('timezone: $timezone, ')
          ..write('active: $active, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedReminderOccurrencesTable extends CachedReminderOccurrences
    with TableInfo<$CachedReminderOccurrencesTable, CachedReminderOccurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedReminderOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
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
      ).withConverter<DateTime>(
        $CachedReminderOccurrencesTable.$converterscheduledAt,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> snoozedUntil =
      GeneratedColumn<int>(
        'snoozed_until',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $CachedReminderOccurrencesTable.$convertersnoozedUntiln,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> completedAt =
      GeneratedColumn<int>(
        'completed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $CachedReminderOccurrencesTable.$convertercompletedAtn,
      );
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
      ).withConverter<DateTime>(
        $CachedReminderOccurrencesTable.$converterupdatedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    id,
    reminderId,
    day,
    title,
    type,
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
  static const String $name = 'cached_reminder_occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedReminderOccurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
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
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, id};
  @override
  CachedReminderOccurrence map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedReminderOccurrence(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      scheduledAt: $CachedReminderOccurrencesTable.$converterscheduledAt
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}scheduled_at'],
            )!,
          ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      snoozedUntil: $CachedReminderOccurrencesTable.$convertersnoozedUntiln
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}snoozed_until'],
            ),
          ),
      completedAt: $CachedReminderOccurrencesTable.$convertercompletedAtn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}completed_at'],
            ),
          ),
      confirmedVia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_via'],
      ),
      updatedAt: $CachedReminderOccurrencesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $CachedReminderOccurrencesTable createAlias(String alias) {
    return $CachedReminderOccurrencesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterscheduledAt = const UtcMicros();
  static TypeConverter<DateTime, int> $convertersnoozedUntil =
      const UtcMicros();
  static TypeConverter<DateTime?, int?> $convertersnoozedUntiln =
      NullAwareTypeConverter.wrap($convertersnoozedUntil);
  static TypeConverter<DateTime, int> $convertercompletedAt = const UtcMicros();
  static TypeConverter<DateTime?, int?> $convertercompletedAtn =
      NullAwareTypeConverter.wrap($convertercompletedAt);
  static TypeConverter<DateTime, int> $converterupdatedAt = const UtcMicros();
}

class CachedReminderOccurrence extends DataClass
    implements Insertable<CachedReminderOccurrence> {
  final String caregiverId;
  final String patientId;
  final String id;
  final String reminderId;
  final String day;
  final String title;
  final String type;
  final DateTime scheduledAt;
  final String status;
  final DateTime? snoozedUntil;
  final DateTime? completedAt;
  final String? confirmedVia;
  final DateTime updatedAt;
  const CachedReminderOccurrence({
    required this.caregiverId,
    required this.patientId,
    required this.id,
    required this.reminderId,
    required this.day,
    required this.title,
    required this.type,
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
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['id'] = Variable<String>(id);
    map['reminder_id'] = Variable<String>(reminderId);
    map['day'] = Variable<String>(day);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    {
      map['scheduled_at'] = Variable<int>(
        $CachedReminderOccurrencesTable.$converterscheduledAt.toSql(
          scheduledAt,
        ),
      );
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<int>(
        $CachedReminderOccurrencesTable.$convertersnoozedUntiln.toSql(
          snoozedUntil,
        ),
      );
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(
        $CachedReminderOccurrencesTable.$convertercompletedAtn.toSql(
          completedAt,
        ),
      );
    }
    if (!nullToAbsent || confirmedVia != null) {
      map['confirmed_via'] = Variable<String>(confirmedVia);
    }
    {
      map['updated_at'] = Variable<int>(
        $CachedReminderOccurrencesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  CachedReminderOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return CachedReminderOccurrencesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      id: Value(id),
      reminderId: Value(reminderId),
      day: Value(day),
      title: Value(title),
      type: Value(type),
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

  factory CachedReminderOccurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedReminderOccurrence(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      reminderId: serializer.fromJson<String>(json['reminderId']),
      day: serializer.fromJson<String>(json['day']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      status: serializer.fromJson<String>(json['status']),
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
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'reminderId': serializer.toJson<String>(reminderId),
      'day': serializer.toJson<String>(day),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'status': serializer.toJson<String>(status),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'confirmedVia': serializer.toJson<String?>(confirmedVia),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedReminderOccurrence copyWith({
    String? caregiverId,
    String? patientId,
    String? id,
    String? reminderId,
    String? day,
    String? title,
    String? type,
    DateTime? scheduledAt,
    String? status,
    Value<DateTime?> snoozedUntil = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> confirmedVia = const Value.absent(),
    DateTime? updatedAt,
  }) => CachedReminderOccurrence(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    reminderId: reminderId ?? this.reminderId,
    day: day ?? this.day,
    title: title ?? this.title,
    type: type ?? this.type,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    status: status ?? this.status,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    confirmedVia: confirmedVia.present ? confirmedVia.value : this.confirmedVia,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedReminderOccurrence copyWithCompanion(
    CachedReminderOccurrencesCompanion data,
  ) {
    return CachedReminderOccurrence(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      day: data.day.present ? data.day.value : this.day,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
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
    return (StringBuffer('CachedReminderOccurrence(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
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
    caregiverId,
    patientId,
    id,
    reminderId,
    day,
    title,
    type,
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
      (other is CachedReminderOccurrence &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.reminderId == this.reminderId &&
          other.day == this.day &&
          other.title == this.title &&
          other.type == this.type &&
          other.scheduledAt == this.scheduledAt &&
          other.status == this.status &&
          other.snoozedUntil == this.snoozedUntil &&
          other.completedAt == this.completedAt &&
          other.confirmedVia == this.confirmedVia &&
          other.updatedAt == this.updatedAt);
}

class CachedReminderOccurrencesCompanion
    extends UpdateCompanion<CachedReminderOccurrence> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> id;
  final Value<String> reminderId;
  final Value<String> day;
  final Value<String> title;
  final Value<String> type;
  final Value<DateTime> scheduledAt;
  final Value<String> status;
  final Value<DateTime?> snoozedUntil;
  final Value<DateTime?> completedAt;
  final Value<String?> confirmedVia;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedReminderOccurrencesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.id = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.day = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.status = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.confirmedVia = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedReminderOccurrencesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String id,
    required String reminderId,
    required String day,
    required String title,
    required String type,
    required DateTime scheduledAt,
    required String status,
    this.snoozedUntil = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.confirmedVia = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       id = Value(id),
       reminderId = Value(reminderId),
       day = Value(day),
       title = Value(title),
       type = Value(type),
       scheduledAt = Value(scheduledAt),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<CachedReminderOccurrence> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? id,
    Expression<String>? reminderId,
    Expression<String>? day,
    Expression<String>? title,
    Expression<String>? type,
    Expression<int>? scheduledAt,
    Expression<String>? status,
    Expression<int>? snoozedUntil,
    Expression<int>? completedAt,
    Expression<String>? confirmedVia,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (reminderId != null) 'reminder_id': reminderId,
      if (day != null) 'day': day,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (status != null) 'status': status,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (completedAt != null) 'completed_at': completedAt,
      if (confirmedVia != null) 'confirmed_via': confirmedVia,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedReminderOccurrencesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? id,
    Value<String>? reminderId,
    Value<String>? day,
    Value<String>? title,
    Value<String>? type,
    Value<DateTime>? scheduledAt,
    Value<String>? status,
    Value<DateTime?>? snoozedUntil,
    Value<DateTime?>? completedAt,
    Value<String?>? confirmedVia,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedReminderOccurrencesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      day: day ?? this.day,
      title: title ?? this.title,
      type: type ?? this.type,
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
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<int>(
        $CachedReminderOccurrencesTable.$converterscheduledAt.toSql(
          scheduledAt.value,
        ),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<int>(
        $CachedReminderOccurrencesTable.$convertersnoozedUntiln.toSql(
          snoozedUntil.value,
        ),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(
        $CachedReminderOccurrencesTable.$convertercompletedAtn.toSql(
          completedAt.value,
        ),
      );
    }
    if (confirmedVia.present) {
      map['confirmed_via'] = Variable<String>(confirmedVia.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $CachedReminderOccurrencesTable.$converterupdatedAt.toSql(
          updatedAt.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedReminderOccurrencesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
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

class $ReminderCacheStatesTable extends ReminderCacheStates
    with TableInfo<$ReminderCacheStatesTable, ReminderCacheState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderCacheStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $ReminderCacheStatesTable.$converterrefreshedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    day,
    timezone,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_cache_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderCacheState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId};
  @override
  ReminderCacheState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderCacheState(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      refreshedAt: $ReminderCacheStatesTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $ReminderCacheStatesTable createAlias(String alias) {
    return $ReminderCacheStatesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class ReminderCacheState extends DataClass
    implements Insertable<ReminderCacheState> {
  final String caregiverId;
  final String patientId;
  final String day;
  final String timezone;
  final DateTime refreshedAt;
  const ReminderCacheState({
    required this.caregiverId,
    required this.patientId,
    required this.day,
    required this.timezone,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['day'] = Variable<String>(day);
    map['timezone'] = Variable<String>(timezone);
    {
      map['refreshed_at'] = Variable<int>(
        $ReminderCacheStatesTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  ReminderCacheStatesCompanion toCompanion(bool nullToAbsent) {
    return ReminderCacheStatesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      day: Value(day),
      timezone: Value(timezone),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory ReminderCacheState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderCacheState(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      day: serializer.fromJson<String>(json['day']),
      timezone: serializer.fromJson<String>(json['timezone']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'day': serializer.toJson<String>(day),
      'timezone': serializer.toJson<String>(timezone),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  ReminderCacheState copyWith({
    String? caregiverId,
    String? patientId,
    String? day,
    String? timezone,
    DateTime? refreshedAt,
  }) => ReminderCacheState(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    day: day ?? this.day,
    timezone: timezone ?? this.timezone,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  ReminderCacheState copyWithCompanion(ReminderCacheStatesCompanion data) {
    return ReminderCacheState(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      day: data.day.present ? data.day.value : this.day,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderCacheState(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('day: $day, ')
          ..write('timezone: $timezone, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(caregiverId, patientId, day, timezone, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderCacheState &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.day == this.day &&
          other.timezone == this.timezone &&
          other.refreshedAt == this.refreshedAt);
}

class ReminderCacheStatesCompanion extends UpdateCompanion<ReminderCacheState> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> day;
  final Value<String> timezone;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const ReminderCacheStatesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.day = const Value.absent(),
    this.timezone = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderCacheStatesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String day,
    required String timezone,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       day = Value(day),
       timezone = Value(timezone),
       refreshedAt = Value(refreshedAt);
  static Insertable<ReminderCacheState> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? day,
    Expression<String>? timezone,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (day != null) 'day': day,
      if (timezone != null) 'timezone': timezone,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderCacheStatesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? day,
    Value<String>? timezone,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return ReminderCacheStatesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      day: day ?? this.day,
      timezone: timezone ?? this.timezone,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $ReminderCacheStatesTable.$converterrefreshedAt.toSql(
          refreshedAt.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderCacheStatesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('day: $day, ')
          ..write('timezone: $timezone, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedUnknownFacesTable extends CachedUnknownFaces
    with TableInfo<$CachedUnknownFacesTable, CachedUnknownFace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedUnknownFacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sightingCountMeta = const VerificationMeta(
    'sightingCount',
  );
  @override
  late final GeneratedColumn<int> sightingCount = GeneratedColumn<int>(
    'sighting_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distinctDaysMeta = const VerificationMeta(
    'distinctDays',
  );
  @override
  late final GeneratedColumn<int> distinctDays = GeneratedColumn<int>(
    'distinct_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> firstSeenAt =
      GeneratedColumn<int>(
        'first_seen_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedUnknownFacesTable.$converterfirstSeenAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> lastSeenAt =
      GeneratedColumn<int>(
        'last_seen_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedUnknownFacesTable.$converterlastSeenAt);
  static const VerificationMeta _sampleIdMeta = const VerificationMeta(
    'sampleId',
  );
  @override
  late final GeneratedColumn<String> sampleId = GeneratedColumn<String>(
    'sample_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleUrlMeta = const VerificationMeta(
    'sampleUrl',
  );
  @override
  late final GeneratedColumn<String> sampleUrl = GeneratedColumn<String>(
    'sample_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    id,
    sightingCount,
    distinctDays,
    firstSeenAt,
    lastSeenAt,
    sampleId,
    sampleUrl,
    thumbnailUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_unknown_faces';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedUnknownFace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sighting_count')) {
      context.handle(
        _sightingCountMeta,
        sightingCount.isAcceptableOrUnknown(
          data['sighting_count']!,
          _sightingCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sightingCountMeta);
    }
    if (data.containsKey('distinct_days')) {
      context.handle(
        _distinctDaysMeta,
        distinctDays.isAcceptableOrUnknown(
          data['distinct_days']!,
          _distinctDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distinctDaysMeta);
    }
    if (data.containsKey('sample_id')) {
      context.handle(
        _sampleIdMeta,
        sampleId.isAcceptableOrUnknown(data['sample_id']!, _sampleIdMeta),
      );
    }
    if (data.containsKey('sample_url')) {
      context.handle(
        _sampleUrlMeta,
        sampleUrl.isAcceptableOrUnknown(data['sample_url']!, _sampleUrlMeta),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, id};
  @override
  CachedUnknownFace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedUnknownFace(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sightingCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sighting_count'],
      )!,
      distinctDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distinct_days'],
      )!,
      firstSeenAt: $CachedUnknownFacesTable.$converterfirstSeenAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}first_seen_at'],
        )!,
      ),
      lastSeenAt: $CachedUnknownFacesTable.$converterlastSeenAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_seen_at'],
        )!,
      ),
      sampleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_id'],
      ),
      sampleUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_url'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
    );
  }

  @override
  $CachedUnknownFacesTable createAlias(String alias) {
    return $CachedUnknownFacesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterfirstSeenAt = const UtcMicros();
  static TypeConverter<DateTime, int> $converterlastSeenAt = const UtcMicros();
}

class CachedUnknownFace extends DataClass
    implements Insertable<CachedUnknownFace> {
  final String caregiverId;
  final String patientId;
  final String id;
  final int sightingCount;
  final int distinctDays;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final String? sampleId;
  final String? sampleUrl;
  final String? thumbnailUrl;
  const CachedUnknownFace({
    required this.caregiverId,
    required this.patientId,
    required this.id,
    required this.sightingCount,
    required this.distinctDays,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.sampleId,
    this.sampleUrl,
    this.thumbnailUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['id'] = Variable<String>(id);
    map['sighting_count'] = Variable<int>(sightingCount);
    map['distinct_days'] = Variable<int>(distinctDays);
    {
      map['first_seen_at'] = Variable<int>(
        $CachedUnknownFacesTable.$converterfirstSeenAt.toSql(firstSeenAt),
      );
    }
    {
      map['last_seen_at'] = Variable<int>(
        $CachedUnknownFacesTable.$converterlastSeenAt.toSql(lastSeenAt),
      );
    }
    if (!nullToAbsent || sampleId != null) {
      map['sample_id'] = Variable<String>(sampleId);
    }
    if (!nullToAbsent || sampleUrl != null) {
      map['sample_url'] = Variable<String>(sampleUrl);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    return map;
  }

  CachedUnknownFacesCompanion toCompanion(bool nullToAbsent) {
    return CachedUnknownFacesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      id: Value(id),
      sightingCount: Value(sightingCount),
      distinctDays: Value(distinctDays),
      firstSeenAt: Value(firstSeenAt),
      lastSeenAt: Value(lastSeenAt),
      sampleId: sampleId == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleId),
      sampleUrl: sampleUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleUrl),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
    );
  }

  factory CachedUnknownFace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedUnknownFace(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      sightingCount: serializer.fromJson<int>(json['sightingCount']),
      distinctDays: serializer.fromJson<int>(json['distinctDays']),
      firstSeenAt: serializer.fromJson<DateTime>(json['firstSeenAt']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      sampleId: serializer.fromJson<String?>(json['sampleId']),
      sampleUrl: serializer.fromJson<String?>(json['sampleUrl']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'sightingCount': serializer.toJson<int>(sightingCount),
      'distinctDays': serializer.toJson<int>(distinctDays),
      'firstSeenAt': serializer.toJson<DateTime>(firstSeenAt),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'sampleId': serializer.toJson<String?>(sampleId),
      'sampleUrl': serializer.toJson<String?>(sampleUrl),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
    };
  }

  CachedUnknownFace copyWith({
    String? caregiverId,
    String? patientId,
    String? id,
    int? sightingCount,
    int? distinctDays,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    Value<String?> sampleId = const Value.absent(),
    Value<String?> sampleUrl = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
  }) => CachedUnknownFace(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    sightingCount: sightingCount ?? this.sightingCount,
    distinctDays: distinctDays ?? this.distinctDays,
    firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    sampleId: sampleId.present ? sampleId.value : this.sampleId,
    sampleUrl: sampleUrl.present ? sampleUrl.value : this.sampleUrl,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
  );
  CachedUnknownFace copyWithCompanion(CachedUnknownFacesCompanion data) {
    return CachedUnknownFace(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      sightingCount: data.sightingCount.present
          ? data.sightingCount.value
          : this.sightingCount,
      distinctDays: data.distinctDays.present
          ? data.distinctDays.value
          : this.distinctDays,
      firstSeenAt: data.firstSeenAt.present
          ? data.firstSeenAt.value
          : this.firstSeenAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      sampleId: data.sampleId.present ? data.sampleId.value : this.sampleId,
      sampleUrl: data.sampleUrl.present ? data.sampleUrl.value : this.sampleUrl,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedUnknownFace(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('sightingCount: $sightingCount, ')
          ..write('distinctDays: $distinctDays, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('sampleId: $sampleId, ')
          ..write('sampleUrl: $sampleUrl, ')
          ..write('thumbnailUrl: $thumbnailUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    id,
    sightingCount,
    distinctDays,
    firstSeenAt,
    lastSeenAt,
    sampleId,
    sampleUrl,
    thumbnailUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedUnknownFace &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.sightingCount == this.sightingCount &&
          other.distinctDays == this.distinctDays &&
          other.firstSeenAt == this.firstSeenAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.sampleId == this.sampleId &&
          other.sampleUrl == this.sampleUrl &&
          other.thumbnailUrl == this.thumbnailUrl);
}

class CachedUnknownFacesCompanion extends UpdateCompanion<CachedUnknownFace> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> id;
  final Value<int> sightingCount;
  final Value<int> distinctDays;
  final Value<DateTime> firstSeenAt;
  final Value<DateTime> lastSeenAt;
  final Value<String?> sampleId;
  final Value<String?> sampleUrl;
  final Value<String?> thumbnailUrl;
  final Value<int> rowid;
  const CachedUnknownFacesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.id = const Value.absent(),
    this.sightingCount = const Value.absent(),
    this.distinctDays = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.sampleId = const Value.absent(),
    this.sampleUrl = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedUnknownFacesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String id,
    required int sightingCount,
    required int distinctDays,
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
    this.sampleId = const Value.absent(),
    this.sampleUrl = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       id = Value(id),
       sightingCount = Value(sightingCount),
       distinctDays = Value(distinctDays),
       firstSeenAt = Value(firstSeenAt),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<CachedUnknownFace> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? id,
    Expression<int>? sightingCount,
    Expression<int>? distinctDays,
    Expression<int>? firstSeenAt,
    Expression<int>? lastSeenAt,
    Expression<String>? sampleId,
    Expression<String>? sampleUrl,
    Expression<String>? thumbnailUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (sightingCount != null) 'sighting_count': sightingCount,
      if (distinctDays != null) 'distinct_days': distinctDays,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (sampleId != null) 'sample_id': sampleId,
      if (sampleUrl != null) 'sample_url': sampleUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedUnknownFacesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? id,
    Value<int>? sightingCount,
    Value<int>? distinctDays,
    Value<DateTime>? firstSeenAt,
    Value<DateTime>? lastSeenAt,
    Value<String?>? sampleId,
    Value<String?>? sampleUrl,
    Value<String?>? thumbnailUrl,
    Value<int>? rowid,
  }) {
    return CachedUnknownFacesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      sightingCount: sightingCount ?? this.sightingCount,
      distinctDays: distinctDays ?? this.distinctDays,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      sampleId: sampleId ?? this.sampleId,
      sampleUrl: sampleUrl ?? this.sampleUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sightingCount.present) {
      map['sighting_count'] = Variable<int>(sightingCount.value);
    }
    if (distinctDays.present) {
      map['distinct_days'] = Variable<int>(distinctDays.value);
    }
    if (firstSeenAt.present) {
      map['first_seen_at'] = Variable<int>(
        $CachedUnknownFacesTable.$converterfirstSeenAt.toSql(firstSeenAt.value),
      );
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(
        $CachedUnknownFacesTable.$converterlastSeenAt.toSql(lastSeenAt.value),
      );
    }
    if (sampleId.present) {
      map['sample_id'] = Variable<String>(sampleId.value);
    }
    if (sampleUrl.present) {
      map['sample_url'] = Variable<String>(sampleUrl.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedUnknownFacesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('sightingCount: $sightingCount, ')
          ..write('distinctDays: $distinctDays, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('sampleId: $sampleId, ')
          ..write('sampleUrl: $sampleUrl, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnknownFacesCacheStatesTable extends UnknownFacesCacheStates
    with TableInfo<$UnknownFacesCacheStatesTable, UnknownFacesCacheState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnknownFacesCacheStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $UnknownFacesCacheStatesTable.$converterrefreshedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [caregiverId, patientId, refreshedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unknown_faces_cache_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnknownFacesCacheState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId};
  @override
  UnknownFacesCacheState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnknownFacesCacheState(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      refreshedAt: $UnknownFacesCacheStatesTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $UnknownFacesCacheStatesTable createAlias(String alias) {
    return $UnknownFacesCacheStatesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class UnknownFacesCacheState extends DataClass
    implements Insertable<UnknownFacesCacheState> {
  final String caregiverId;
  final String patientId;
  final DateTime refreshedAt;
  const UnknownFacesCacheState({
    required this.caregiverId,
    required this.patientId,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    {
      map['refreshed_at'] = Variable<int>(
        $UnknownFacesCacheStatesTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  UnknownFacesCacheStatesCompanion toCompanion(bool nullToAbsent) {
    return UnknownFacesCacheStatesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory UnknownFacesCacheState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnknownFacesCacheState(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  UnknownFacesCacheState copyWith({
    String? caregiverId,
    String? patientId,
    DateTime? refreshedAt,
  }) => UnknownFacesCacheState(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  UnknownFacesCacheState copyWithCompanion(
    UnknownFacesCacheStatesCompanion data,
  ) {
    return UnknownFacesCacheState(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnknownFacesCacheState(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(caregiverId, patientId, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnknownFacesCacheState &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.refreshedAt == this.refreshedAt);
}

class UnknownFacesCacheStatesCompanion
    extends UpdateCompanion<UnknownFacesCacheState> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const UnknownFacesCacheStatesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnknownFacesCacheStatesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       refreshedAt = Value(refreshedAt);
  static Insertable<UnknownFacesCacheState> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnknownFacesCacheStatesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return UnknownFacesCacheStatesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $UnknownFacesCacheStatesTable.$converterrefreshedAt.toSql(
          refreshedAt.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnknownFacesCacheStatesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedUnknownFaceSamplesTable extends CachedUnknownFaceSamples
    with TableInfo<$CachedUnknownFaceSamplesTable, CachedUnknownFaceSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedUnknownFaceSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _clusterIdMeta = const VerificationMeta(
    'clusterId',
  );
  @override
  late final GeneratedColumn<String> clusterId = GeneratedColumn<String>(
    'cluster_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    clusterId,
    id,
    url,
    thumbnailUrl,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_unknown_face_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedUnknownFaceSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('cluster_id')) {
      context.handle(
        _clusterIdMeta,
        clusterId.isAcceptableOrUnknown(data['cluster_id']!, _clusterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clusterIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    caregiverId,
    patientId,
    clusterId,
    id,
  };
  @override
  CachedUnknownFaceSample map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedUnknownFaceSample(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      clusterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cluster_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedUnknownFaceSamplesTable createAlias(String alias) {
    return $CachedUnknownFaceSamplesTable(attachedDatabase, alias);
  }
}

class CachedUnknownFaceSample extends DataClass
    implements Insertable<CachedUnknownFaceSample> {
  final String caregiverId;
  final String patientId;
  final String clusterId;
  final String id;
  final String url;
  final String? thumbnailUrl;
  final int position;
  const CachedUnknownFaceSample({
    required this.caregiverId,
    required this.patientId,
    required this.clusterId,
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['cluster_id'] = Variable<String>(clusterId);
    map['id'] = Variable<String>(id);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedUnknownFaceSamplesCompanion toCompanion(bool nullToAbsent) {
    return CachedUnknownFaceSamplesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      clusterId: Value(clusterId),
      id: Value(id),
      url: Value(url),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      position: Value(position),
    );
  }

  factory CachedUnknownFaceSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedUnknownFaceSample(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      clusterId: serializer.fromJson<String>(json['clusterId']),
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'clusterId': serializer.toJson<String>(clusterId),
      'id': serializer.toJson<String>(id),
      'url': serializer.toJson<String>(url),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedUnknownFaceSample copyWith({
    String? caregiverId,
    String? patientId,
    String? clusterId,
    String? id,
    String? url,
    Value<String?> thumbnailUrl = const Value.absent(),
    int? position,
  }) => CachedUnknownFaceSample(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    clusterId: clusterId ?? this.clusterId,
    id: id ?? this.id,
    url: url ?? this.url,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    position: position ?? this.position,
  );
  CachedUnknownFaceSample copyWithCompanion(
    CachedUnknownFaceSamplesCompanion data,
  ) {
    return CachedUnknownFaceSample(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      clusterId: data.clusterId.present ? data.clusterId.value : this.clusterId,
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedUnknownFaceSample(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('clusterId: $clusterId, ')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    clusterId,
    id,
    url,
    thumbnailUrl,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedUnknownFaceSample &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.clusterId == this.clusterId &&
          other.id == this.id &&
          other.url == this.url &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.position == this.position);
}

class CachedUnknownFaceSamplesCompanion
    extends UpdateCompanion<CachedUnknownFaceSample> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> clusterId;
  final Value<String> id;
  final Value<String> url;
  final Value<String?> thumbnailUrl;
  final Value<int> position;
  final Value<int> rowid;
  const CachedUnknownFaceSamplesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.clusterId = const Value.absent(),
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedUnknownFaceSamplesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String clusterId,
    required String id,
    required String url,
    this.thumbnailUrl = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       clusterId = Value(clusterId),
       id = Value(id),
       url = Value(url),
       position = Value(position);
  static Insertable<CachedUnknownFaceSample> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? clusterId,
    Expression<String>? id,
    Expression<String>? url,
    Expression<String>? thumbnailUrl,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (clusterId != null) 'cluster_id': clusterId,
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedUnknownFaceSamplesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? clusterId,
    Value<String>? id,
    Value<String>? url,
    Value<String?>? thumbnailUrl,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CachedUnknownFaceSamplesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      clusterId: clusterId ?? this.clusterId,
      id: id ?? this.id,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (clusterId.present) {
      map['cluster_id'] = Variable<String>(clusterId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedUnknownFaceSamplesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('clusterId: $clusterId, ')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPlacesTable extends CachedPlaces
    with TableInfo<$CachedPlacesTable, CachedPlace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusMMeta = const VerificationMeta(
    'radiusM',
  );
  @override
  late final GeneratedColumn<int> radiusM = GeneratedColumn<int>(
    'radius_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedPlacesTable.$converterupdatedAt);
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    id,
    name,
    latitude,
    longitude,
    radiusM,
    createdBy,
    updatedAt,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPlace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('radius_m')) {
      context.handle(
        _radiusMMeta,
        radiusM.isAcceptableOrUnknown(data['radius_m']!, _radiusMMeta),
      );
    } else if (isInserting) {
      context.missing(_radiusMMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, id};
  @override
  CachedPlace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPlace(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      radiusM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}radius_m'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedAt: $CachedPlacesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedPlacesTable createAlias(String alias) {
    return $CachedPlacesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterupdatedAt = const UtcMicros();
}

class CachedPlace extends DataClass implements Insertable<CachedPlace> {
  final String caregiverId;
  final String patientId;
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusM;
  final String createdBy;
  final DateTime updatedAt;
  final int position;
  const CachedPlace({
    required this.caregiverId,
    required this.patientId,
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusM,
    required this.createdBy,
    required this.updatedAt,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['radius_m'] = Variable<int>(radiusM);
    map['created_by'] = Variable<String>(createdBy);
    {
      map['updated_at'] = Variable<int>(
        $CachedPlacesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedPlacesCompanion toCompanion(bool nullToAbsent) {
    return CachedPlacesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      id: Value(id),
      name: Value(name),
      latitude: Value(latitude),
      longitude: Value(longitude),
      radiusM: Value(radiusM),
      createdBy: Value(createdBy),
      updatedAt: Value(updatedAt),
      position: Value(position),
    );
  }

  factory CachedPlace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPlace(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      radiusM: serializer.fromJson<int>(json['radiusM']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'radiusM': serializer.toJson<int>(radiusM),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedPlace copyWith({
    String? caregiverId,
    String? patientId,
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    int? radiusM,
    String? createdBy,
    DateTime? updatedAt,
    int? position,
  }) => CachedPlace(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusM: radiusM ?? this.radiusM,
    createdBy: createdBy ?? this.createdBy,
    updatedAt: updatedAt ?? this.updatedAt,
    position: position ?? this.position,
  );
  CachedPlace copyWithCompanion(CachedPlacesCompanion data) {
    return CachedPlace(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      radiusM: data.radiusM.present ? data.radiusM.value : this.radiusM,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPlace(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusM: $radiusM, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    id,
    name,
    latitude,
    longitude,
    radiusM,
    createdBy,
    updatedAt,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPlace &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.radiusM == this.radiusM &&
          other.createdBy == this.createdBy &&
          other.updatedAt == this.updatedAt &&
          other.position == this.position);
}

class CachedPlacesCompanion extends UpdateCompanion<CachedPlace> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> id;
  final Value<String> name;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int> radiusM;
  final Value<String> createdBy;
  final Value<DateTime> updatedAt;
  final Value<int> position;
  final Value<int> rowid;
  const CachedPlacesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radiusM = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPlacesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required int radiusM,
    required String createdBy,
    required DateTime updatedAt,
    required int position,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       id = Value(id),
       name = Value(name),
       latitude = Value(latitude),
       longitude = Value(longitude),
       radiusM = Value(radiusM),
       createdBy = Value(createdBy),
       updatedAt = Value(updatedAt),
       position = Value(position);
  static Insertable<CachedPlace> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? radiusM,
    Expression<String>? createdBy,
    Expression<int>? updatedAt,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusM != null) 'radius_m': radiusM,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPlacesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? id,
    Value<String>? name,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<int>? radiusM,
    Value<String>? createdBy,
    Value<DateTime>? updatedAt,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CachedPlacesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusM: radiusM ?? this.radiusM,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (radiusM.present) {
      map['radius_m'] = Variable<int>(radiusM.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $CachedPlacesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPlacesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusM: $radiusM, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlacesCacheStatesTable extends PlacesCacheStates
    with TableInfo<$PlacesCacheStatesTable, PlacesCacheState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacesCacheStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PlacesCacheStatesTable.$converterrefreshedAt);
  @override
  List<GeneratedColumn> get $columns => [caregiverId, patientId, refreshedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'places_cache_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlacesCacheState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId};
  @override
  PlacesCacheState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlacesCacheState(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      refreshedAt: $PlacesCacheStatesTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $PlacesCacheStatesTable createAlias(String alias) {
    return $PlacesCacheStatesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class PlacesCacheState extends DataClass
    implements Insertable<PlacesCacheState> {
  final String caregiverId;
  final String patientId;
  final DateTime refreshedAt;
  const PlacesCacheState({
    required this.caregiverId,
    required this.patientId,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    {
      map['refreshed_at'] = Variable<int>(
        $PlacesCacheStatesTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  PlacesCacheStatesCompanion toCompanion(bool nullToAbsent) {
    return PlacesCacheStatesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory PlacesCacheState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlacesCacheState(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  PlacesCacheState copyWith({
    String? caregiverId,
    String? patientId,
    DateTime? refreshedAt,
  }) => PlacesCacheState(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  PlacesCacheState copyWithCompanion(PlacesCacheStatesCompanion data) {
    return PlacesCacheState(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlacesCacheState(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(caregiverId, patientId, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlacesCacheState &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.refreshedAt == this.refreshedAt);
}

class PlacesCacheStatesCompanion extends UpdateCompanion<PlacesCacheState> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const PlacesCacheStatesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlacesCacheStatesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       refreshedAt = Value(refreshedAt);
  static Insertable<PlacesCacheState> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlacesCacheStatesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return PlacesCacheStatesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $PlacesCacheStatesTable.$converterrefreshedAt.toSql(refreshedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacesCacheStatesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedJournalEntriesTable extends CachedJournalEntries
    with TableInfo<$CachedJournalEntriesTable, CachedJournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedJournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> occurredAt =
      GeneratedColumn<int>(
        'occurred_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $CachedJournalEntriesTable.$converteroccurredAt,
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
    caregiverId,
    patientId,
    day,
    id,
    occurredAt,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedJournalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, day, id};
  @override
  CachedJournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedJournalEntry(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occurredAt: $CachedJournalEntriesTable.$converteroccurredAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}occurred_at'],
        )!,
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $CachedJournalEntriesTable createAlias(String alias) {
    return $CachedJournalEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converteroccurredAt = const UtcMicros();
}

class CachedJournalEntry extends DataClass
    implements Insertable<CachedJournalEntry> {
  final String caregiverId;
  final String patientId;
  final String day;
  final String id;
  final DateTime occurredAt;
  final String payload;
  const CachedJournalEntry({
    required this.caregiverId,
    required this.patientId,
    required this.day,
    required this.id,
    required this.occurredAt,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['day'] = Variable<String>(day);
    map['id'] = Variable<String>(id);
    {
      map['occurred_at'] = Variable<int>(
        $CachedJournalEntriesTable.$converteroccurredAt.toSql(occurredAt),
      );
    }
    map['payload'] = Variable<String>(payload);
    return map;
  }

  CachedJournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return CachedJournalEntriesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      day: Value(day),
      id: Value(id),
      occurredAt: Value(occurredAt),
      payload: Value(payload),
    );
  }

  factory CachedJournalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedJournalEntry(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      day: serializer.fromJson<String>(json['day']),
      id: serializer.fromJson<String>(json['id']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'day': serializer.toJson<String>(day),
      'id': serializer.toJson<String>(id),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'payload': serializer.toJson<String>(payload),
    };
  }

  CachedJournalEntry copyWith({
    String? caregiverId,
    String? patientId,
    String? day,
    String? id,
    DateTime? occurredAt,
    String? payload,
  }) => CachedJournalEntry(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    day: day ?? this.day,
    id: id ?? this.id,
    occurredAt: occurredAt ?? this.occurredAt,
    payload: payload ?? this.payload,
  );
  CachedJournalEntry copyWithCompanion(CachedJournalEntriesCompanion data) {
    return CachedJournalEntry(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      day: data.day.present ? data.day.value : this.day,
      id: data.id.present ? data.id.value : this.id,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedJournalEntry(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('day: $day, ')
          ..write('id: $id, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(caregiverId, patientId, day, id, occurredAt, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedJournalEntry &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.day == this.day &&
          other.id == this.id &&
          other.occurredAt == this.occurredAt &&
          other.payload == this.payload);
}

class CachedJournalEntriesCompanion
    extends UpdateCompanion<CachedJournalEntry> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> day;
  final Value<String> id;
  final Value<DateTime> occurredAt;
  final Value<String> payload;
  final Value<int> rowid;
  const CachedJournalEntriesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.day = const Value.absent(),
    this.id = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedJournalEntriesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String day,
    required String id,
    required DateTime occurredAt,
    required String payload,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       day = Value(day),
       id = Value(id),
       occurredAt = Value(occurredAt),
       payload = Value(payload);
  static Insertable<CachedJournalEntry> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? day,
    Expression<String>? id,
    Expression<int>? occurredAt,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (day != null) 'day': day,
      if (id != null) 'id': id,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedJournalEntriesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? day,
    Value<String>? id,
    Value<DateTime>? occurredAt,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return CachedJournalEntriesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      day: day ?? this.day,
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(
        $CachedJournalEntriesTable.$converteroccurredAt.toSql(occurredAt.value),
      );
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedJournalEntriesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('day: $day, ')
          ..write('id: $id, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedJournalMediaTable extends CachedJournalMedia
    with TableInfo<$CachedJournalMediaTable, CachedJournalMediaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedJournalMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
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
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    day,
    id,
    eventId,
    payload,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_journal_media';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedJournalMediaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, day, id};
  @override
  CachedJournalMediaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedJournalMediaData(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedJournalMediaTable createAlias(String alias) {
    return $CachedJournalMediaTable(attachedDatabase, alias);
  }
}

class CachedJournalMediaData extends DataClass
    implements Insertable<CachedJournalMediaData> {
  final String caregiverId;
  final String patientId;
  final String day;
  final String id;
  final String eventId;
  final String payload;
  final int position;
  const CachedJournalMediaData({
    required this.caregiverId,
    required this.patientId,
    required this.day,
    required this.id,
    required this.eventId,
    required this.payload,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['day'] = Variable<String>(day);
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['payload'] = Variable<String>(payload);
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedJournalMediaCompanion toCompanion(bool nullToAbsent) {
    return CachedJournalMediaCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      day: Value(day),
      id: Value(id),
      eventId: Value(eventId),
      payload: Value(payload),
      position: Value(position),
    );
  }

  factory CachedJournalMediaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedJournalMediaData(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      day: serializer.fromJson<String>(json['day']),
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      payload: serializer.fromJson<String>(json['payload']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'day': serializer.toJson<String>(day),
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'payload': serializer.toJson<String>(payload),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedJournalMediaData copyWith({
    String? caregiverId,
    String? patientId,
    String? day,
    String? id,
    String? eventId,
    String? payload,
    int? position,
  }) => CachedJournalMediaData(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    day: day ?? this.day,
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    payload: payload ?? this.payload,
    position: position ?? this.position,
  );
  CachedJournalMediaData copyWithCompanion(CachedJournalMediaCompanion data) {
    return CachedJournalMediaData(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      day: data.day.present ? data.day.value : this.day,
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      payload: data.payload.present ? data.payload.value : this.payload,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedJournalMediaData(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('day: $day, ')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('payload: $payload, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(caregiverId, patientId, day, id, eventId, payload, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedJournalMediaData &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.day == this.day &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.payload == this.payload &&
          other.position == this.position);
}

class CachedJournalMediaCompanion
    extends UpdateCompanion<CachedJournalMediaData> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> day;
  final Value<String> id;
  final Value<String> eventId;
  final Value<String> payload;
  final Value<int> position;
  final Value<int> rowid;
  const CachedJournalMediaCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.day = const Value.absent(),
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.payload = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedJournalMediaCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String day,
    required String id,
    required String eventId,
    required String payload,
    required int position,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       day = Value(day),
       id = Value(id),
       eventId = Value(eventId),
       payload = Value(payload),
       position = Value(position);
  static Insertable<CachedJournalMediaData> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? day,
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? payload,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (day != null) 'day': day,
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (payload != null) 'payload': payload,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedJournalMediaCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? day,
    Value<String>? id,
    Value<String>? eventId,
    Value<String>? payload,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CachedJournalMediaCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      day: day ?? this.day,
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      payload: payload ?? this.payload,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedJournalMediaCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('day: $day, ')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('payload: $payload, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalCacheStatesTable extends JournalCacheStates
    with TableInfo<$JournalCacheStatesTable, JournalCacheState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalCacheStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($JournalCacheStatesTable.$converterrefreshedAt);
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    day,
    timezone,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_cache_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalCacheState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, day};
  @override
  JournalCacheState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalCacheState(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      refreshedAt: $JournalCacheStatesTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $JournalCacheStatesTable createAlias(String alias) {
    return $JournalCacheStatesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class JournalCacheState extends DataClass
    implements Insertable<JournalCacheState> {
  final String caregiverId;
  final String patientId;
  final String day;
  final String timezone;
  final DateTime refreshedAt;
  const JournalCacheState({
    required this.caregiverId,
    required this.patientId,
    required this.day,
    required this.timezone,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['day'] = Variable<String>(day);
    map['timezone'] = Variable<String>(timezone);
    {
      map['refreshed_at'] = Variable<int>(
        $JournalCacheStatesTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  JournalCacheStatesCompanion toCompanion(bool nullToAbsent) {
    return JournalCacheStatesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      day: Value(day),
      timezone: Value(timezone),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory JournalCacheState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalCacheState(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      day: serializer.fromJson<String>(json['day']),
      timezone: serializer.fromJson<String>(json['timezone']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'day': serializer.toJson<String>(day),
      'timezone': serializer.toJson<String>(timezone),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  JournalCacheState copyWith({
    String? caregiverId,
    String? patientId,
    String? day,
    String? timezone,
    DateTime? refreshedAt,
  }) => JournalCacheState(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    day: day ?? this.day,
    timezone: timezone ?? this.timezone,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  JournalCacheState copyWithCompanion(JournalCacheStatesCompanion data) {
    return JournalCacheState(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      day: data.day.present ? data.day.value : this.day,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalCacheState(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('day: $day, ')
          ..write('timezone: $timezone, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(caregiverId, patientId, day, timezone, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalCacheState &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.day == this.day &&
          other.timezone == this.timezone &&
          other.refreshedAt == this.refreshedAt);
}

class JournalCacheStatesCompanion extends UpdateCompanion<JournalCacheState> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> day;
  final Value<String> timezone;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const JournalCacheStatesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.day = const Value.absent(),
    this.timezone = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalCacheStatesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String day,
    required String timezone,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       day = Value(day),
       timezone = Value(timezone),
       refreshedAt = Value(refreshedAt);
  static Insertable<JournalCacheState> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? day,
    Expression<String>? timezone,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (day != null) 'day': day,
      if (timezone != null) 'timezone': timezone,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalCacheStatesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? day,
    Value<String>? timezone,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return JournalCacheStatesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      day: day ?? this.day,
      timezone: timezone ?? this.timezone,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $JournalCacheStatesTable.$converterrefreshedAt.toSql(refreshedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalCacheStatesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('day: $day, ')
          ..write('timezone: $timezone, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMediaDetailsTable extends CachedMediaDetails
    with TableInfo<$CachedMediaDetailsTable, CachedMediaDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMediaDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedMediaDetailsTable.$converterrefreshedAt);
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    id,
    payload,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_media_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMediaDetail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, id};
  @override
  CachedMediaDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMediaDetail(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      refreshedAt: $CachedMediaDetailsTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $CachedMediaDetailsTable createAlias(String alias) {
    return $CachedMediaDetailsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class CachedMediaDetail extends DataClass
    implements Insertable<CachedMediaDetail> {
  final String caregiverId;
  final String patientId;
  final String id;
  final String payload;
  final DateTime refreshedAt;
  const CachedMediaDetail({
    required this.caregiverId,
    required this.patientId,
    required this.id,
    required this.payload,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    {
      map['refreshed_at'] = Variable<int>(
        $CachedMediaDetailsTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  CachedMediaDetailsCompanion toCompanion(bool nullToAbsent) {
    return CachedMediaDetailsCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      id: Value(id),
      payload: Value(payload),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory CachedMediaDetail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMediaDetail(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  CachedMediaDetail copyWith({
    String? caregiverId,
    String? patientId,
    String? id,
    String? payload,
    DateTime? refreshedAt,
  }) => CachedMediaDetail(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    payload: payload ?? this.payload,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  CachedMediaDetail copyWithCompanion(CachedMediaDetailsCompanion data) {
    return CachedMediaDetail(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMediaDetail(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(caregiverId, patientId, id, payload, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMediaDetail &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.refreshedAt == this.refreshedAt);
}

class CachedMediaDetailsCompanion extends UpdateCompanion<CachedMediaDetail> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const CachedMediaDetailsCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMediaDetailsCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String id,
    required String payload,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       id = Value(id),
       payload = Value(payload),
       refreshedAt = Value(refreshedAt);
  static Insertable<CachedMediaDetail> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? id,
    Expression<String>? payload,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMediaDetailsCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return CachedMediaDetailsCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      payload: payload ?? this.payload,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $CachedMediaDetailsTable.$converterrefreshedAt.toSql(refreshedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMediaDetailsCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedDocumentsTable extends CachedDocuments
    with TableInfo<$CachedDocumentsTable, CachedDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _filterMeta = const VerificationMeta('filter');
  @override
  late final GeneratedColumn<String> filter = GeneratedColumn<String>(
    'filter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaAssetIdMeta = const VerificationMeta(
    'mediaAssetId',
  );
  @override
  late final GeneratedColumn<String> mediaAssetId = GeneratedColumn<String>(
    'media_asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentTypeMeta = const VerificationMeta(
    'documentType',
  );
  @override
  late final GeneratedColumn<String> documentType = GeneratedColumn<String>(
    'document_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headlineMeta = const VerificationMeta(
    'headline',
  );
  @override
  late final GeneratedColumn<String> headline = GeneratedColumn<String>(
    'headline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> capturedAt =
      GeneratedColumn<int>(
        'captured_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedDocumentsTable.$convertercapturedAt);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> previewUntil =
      GeneratedColumn<int>(
        'preview_until',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedDocumentsTable.$converterpreviewUntil);
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    filter,
    id,
    eventId,
    mediaAssetId,
    documentType,
    title,
    headline,
    capturedAt,
    url,
    thumbnailUrl,
    previewUntil,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('filter')) {
      context.handle(
        _filterMeta,
        filter.isAcceptableOrUnknown(data['filter']!, _filterMeta),
      );
    } else if (isInserting) {
      context.missing(_filterMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('media_asset_id')) {
      context.handle(
        _mediaAssetIdMeta,
        mediaAssetId.isAcceptableOrUnknown(
          data['media_asset_id']!,
          _mediaAssetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaAssetIdMeta);
    }
    if (data.containsKey('document_type')) {
      context.handle(
        _documentTypeMeta,
        documentType.isAcceptableOrUnknown(
          data['document_type']!,
          _documentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('headline')) {
      context.handle(
        _headlineMeta,
        headline.isAcceptableOrUnknown(data['headline']!, _headlineMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, filter, id};
  @override
  CachedDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDocument(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      filter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      mediaAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_asset_id'],
      )!,
      documentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      headline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headline'],
      ),
      capturedAt: $CachedDocumentsTable.$convertercapturedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}captured_at'],
        )!,
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      previewUntil: $CachedDocumentsTable.$converterpreviewUntil.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}preview_until'],
        )!,
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedDocumentsTable createAlias(String alias) {
    return $CachedDocumentsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercapturedAt = const UtcMicros();
  static TypeConverter<DateTime, int> $converterpreviewUntil =
      const UtcMicros();
}

class CachedDocument extends DataClass implements Insertable<CachedDocument> {
  final String caregiverId;
  final String patientId;
  final String filter;
  final String id;
  final String eventId;
  final String mediaAssetId;
  final String documentType;
  final String? title;
  final String? headline;
  final DateTime capturedAt;
  final String? url;
  final String? thumbnailUrl;
  final DateTime previewUntil;
  final int position;
  const CachedDocument({
    required this.caregiverId,
    required this.patientId,
    required this.filter,
    required this.id,
    required this.eventId,
    required this.mediaAssetId,
    required this.documentType,
    this.title,
    this.headline,
    required this.capturedAt,
    this.url,
    this.thumbnailUrl,
    required this.previewUntil,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['filter'] = Variable<String>(filter);
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['media_asset_id'] = Variable<String>(mediaAssetId);
    map['document_type'] = Variable<String>(documentType);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || headline != null) {
      map['headline'] = Variable<String>(headline);
    }
    {
      map['captured_at'] = Variable<int>(
        $CachedDocumentsTable.$convertercapturedAt.toSql(capturedAt),
      );
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    {
      map['preview_until'] = Variable<int>(
        $CachedDocumentsTable.$converterpreviewUntil.toSql(previewUntil),
      );
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedDocumentsCompanion toCompanion(bool nullToAbsent) {
    return CachedDocumentsCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      filter: Value(filter),
      id: Value(id),
      eventId: Value(eventId),
      mediaAssetId: Value(mediaAssetId),
      documentType: Value(documentType),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      headline: headline == null && nullToAbsent
          ? const Value.absent()
          : Value(headline),
      capturedAt: Value(capturedAt),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      previewUntil: Value(previewUntil),
      position: Value(position),
    );
  }

  factory CachedDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDocument(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      filter: serializer.fromJson<String>(json['filter']),
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      mediaAssetId: serializer.fromJson<String>(json['mediaAssetId']),
      documentType: serializer.fromJson<String>(json['documentType']),
      title: serializer.fromJson<String?>(json['title']),
      headline: serializer.fromJson<String?>(json['headline']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      url: serializer.fromJson<String?>(json['url']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      previewUntil: serializer.fromJson<DateTime>(json['previewUntil']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'filter': serializer.toJson<String>(filter),
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'mediaAssetId': serializer.toJson<String>(mediaAssetId),
      'documentType': serializer.toJson<String>(documentType),
      'title': serializer.toJson<String?>(title),
      'headline': serializer.toJson<String?>(headline),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'url': serializer.toJson<String?>(url),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'previewUntil': serializer.toJson<DateTime>(previewUntil),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedDocument copyWith({
    String? caregiverId,
    String? patientId,
    String? filter,
    String? id,
    String? eventId,
    String? mediaAssetId,
    String? documentType,
    Value<String?> title = const Value.absent(),
    Value<String?> headline = const Value.absent(),
    DateTime? capturedAt,
    Value<String?> url = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    DateTime? previewUntil,
    int? position,
  }) => CachedDocument(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    filter: filter ?? this.filter,
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    mediaAssetId: mediaAssetId ?? this.mediaAssetId,
    documentType: documentType ?? this.documentType,
    title: title.present ? title.value : this.title,
    headline: headline.present ? headline.value : this.headline,
    capturedAt: capturedAt ?? this.capturedAt,
    url: url.present ? url.value : this.url,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    previewUntil: previewUntil ?? this.previewUntil,
    position: position ?? this.position,
  );
  CachedDocument copyWithCompanion(CachedDocumentsCompanion data) {
    return CachedDocument(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      filter: data.filter.present ? data.filter.value : this.filter,
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      mediaAssetId: data.mediaAssetId.present
          ? data.mediaAssetId.value
          : this.mediaAssetId,
      documentType: data.documentType.present
          ? data.documentType.value
          : this.documentType,
      title: data.title.present ? data.title.value : this.title,
      headline: data.headline.present ? data.headline.value : this.headline,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      url: data.url.present ? data.url.value : this.url,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      previewUntil: data.previewUntil.present
          ? data.previewUntil.value
          : this.previewUntil,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocument(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('filter: $filter, ')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('mediaAssetId: $mediaAssetId, ')
          ..write('documentType: $documentType, ')
          ..write('title: $title, ')
          ..write('headline: $headline, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('url: $url, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('previewUntil: $previewUntil, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    filter,
    id,
    eventId,
    mediaAssetId,
    documentType,
    title,
    headline,
    capturedAt,
    url,
    thumbnailUrl,
    previewUntil,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDocument &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.filter == this.filter &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.mediaAssetId == this.mediaAssetId &&
          other.documentType == this.documentType &&
          other.title == this.title &&
          other.headline == this.headline &&
          other.capturedAt == this.capturedAt &&
          other.url == this.url &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.previewUntil == this.previewUntil &&
          other.position == this.position);
}

class CachedDocumentsCompanion extends UpdateCompanion<CachedDocument> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> filter;
  final Value<String> id;
  final Value<String> eventId;
  final Value<String> mediaAssetId;
  final Value<String> documentType;
  final Value<String?> title;
  final Value<String?> headline;
  final Value<DateTime> capturedAt;
  final Value<String?> url;
  final Value<String?> thumbnailUrl;
  final Value<DateTime> previewUntil;
  final Value<int> position;
  final Value<int> rowid;
  const CachedDocumentsCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.filter = const Value.absent(),
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.mediaAssetId = const Value.absent(),
    this.documentType = const Value.absent(),
    this.title = const Value.absent(),
    this.headline = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.url = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.previewUntil = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDocumentsCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String filter,
    required String id,
    required String eventId,
    required String mediaAssetId,
    required String documentType,
    this.title = const Value.absent(),
    this.headline = const Value.absent(),
    required DateTime capturedAt,
    this.url = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    required DateTime previewUntil,
    required int position,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       filter = Value(filter),
       id = Value(id),
       eventId = Value(eventId),
       mediaAssetId = Value(mediaAssetId),
       documentType = Value(documentType),
       capturedAt = Value(capturedAt),
       previewUntil = Value(previewUntil),
       position = Value(position);
  static Insertable<CachedDocument> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? filter,
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? mediaAssetId,
    Expression<String>? documentType,
    Expression<String>? title,
    Expression<String>? headline,
    Expression<int>? capturedAt,
    Expression<String>? url,
    Expression<String>? thumbnailUrl,
    Expression<int>? previewUntil,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (filter != null) 'filter': filter,
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (mediaAssetId != null) 'media_asset_id': mediaAssetId,
      if (documentType != null) 'document_type': documentType,
      if (title != null) 'title': title,
      if (headline != null) 'headline': headline,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (url != null) 'url': url,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (previewUntil != null) 'preview_until': previewUntil,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDocumentsCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? filter,
    Value<String>? id,
    Value<String>? eventId,
    Value<String>? mediaAssetId,
    Value<String>? documentType,
    Value<String?>? title,
    Value<String?>? headline,
    Value<DateTime>? capturedAt,
    Value<String?>? url,
    Value<String?>? thumbnailUrl,
    Value<DateTime>? previewUntil,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CachedDocumentsCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      filter: filter ?? this.filter,
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      mediaAssetId: mediaAssetId ?? this.mediaAssetId,
      documentType: documentType ?? this.documentType,
      title: title ?? this.title,
      headline: headline ?? this.headline,
      capturedAt: capturedAt ?? this.capturedAt,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      previewUntil: previewUntil ?? this.previewUntil,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (filter.present) {
      map['filter'] = Variable<String>(filter.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (mediaAssetId.present) {
      map['media_asset_id'] = Variable<String>(mediaAssetId.value);
    }
    if (documentType.present) {
      map['document_type'] = Variable<String>(documentType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (headline.present) {
      map['headline'] = Variable<String>(headline.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(
        $CachedDocumentsTable.$convertercapturedAt.toSql(capturedAt.value),
      );
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (previewUntil.present) {
      map['preview_until'] = Variable<int>(
        $CachedDocumentsTable.$converterpreviewUntil.toSql(previewUntil.value),
      );
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentsCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('filter: $filter, ')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('mediaAssetId: $mediaAssetId, ')
          ..write('documentType: $documentType, ')
          ..write('title: $title, ')
          ..write('headline: $headline, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('url: $url, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('previewUntil: $previewUntil, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsCacheStatesTable extends DocumentsCacheStates
    with TableInfo<$DocumentsCacheStatesTable, DocumentsCacheState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsCacheStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _filterMeta = const VerificationMeta('filter');
  @override
  late final GeneratedColumn<String> filter = GeneratedColumn<String>(
    'filter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextOffsetMeta = const VerificationMeta(
    'nextOffset',
  );
  @override
  late final GeneratedColumn<int> nextOffset = GeneratedColumn<int>(
    'next_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasMoreMeta = const VerificationMeta(
    'hasMore',
  );
  @override
  late final GeneratedColumn<bool> hasMore = GeneratedColumn<bool>(
    'has_more',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_more" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $DocumentsCacheStatesTable.$converterrefreshedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    filter,
    nextOffset,
    hasMore,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents_cache_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentsCacheState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('filter')) {
      context.handle(
        _filterMeta,
        filter.isAcceptableOrUnknown(data['filter']!, _filterMeta),
      );
    } else if (isInserting) {
      context.missing(_filterMeta);
    }
    if (data.containsKey('next_offset')) {
      context.handle(
        _nextOffsetMeta,
        nextOffset.isAcceptableOrUnknown(data['next_offset']!, _nextOffsetMeta),
      );
    } else if (isInserting) {
      context.missing(_nextOffsetMeta);
    }
    if (data.containsKey('has_more')) {
      context.handle(
        _hasMoreMeta,
        hasMore.isAcceptableOrUnknown(data['has_more']!, _hasMoreMeta),
      );
    } else if (isInserting) {
      context.missing(_hasMoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, filter};
  @override
  DocumentsCacheState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentsCacheState(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      filter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter'],
      )!,
      nextOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_offset'],
      )!,
      hasMore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_more'],
      )!,
      refreshedAt: $DocumentsCacheStatesTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $DocumentsCacheStatesTable createAlias(String alias) {
    return $DocumentsCacheStatesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class DocumentsCacheState extends DataClass
    implements Insertable<DocumentsCacheState> {
  final String caregiverId;
  final String patientId;
  final String filter;
  final int nextOffset;
  final bool hasMore;
  final DateTime refreshedAt;
  const DocumentsCacheState({
    required this.caregiverId,
    required this.patientId,
    required this.filter,
    required this.nextOffset,
    required this.hasMore,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['filter'] = Variable<String>(filter);
    map['next_offset'] = Variable<int>(nextOffset);
    map['has_more'] = Variable<bool>(hasMore);
    {
      map['refreshed_at'] = Variable<int>(
        $DocumentsCacheStatesTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  DocumentsCacheStatesCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCacheStatesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      filter: Value(filter),
      nextOffset: Value(nextOffset),
      hasMore: Value(hasMore),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory DocumentsCacheState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentsCacheState(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      filter: serializer.fromJson<String>(json['filter']),
      nextOffset: serializer.fromJson<int>(json['nextOffset']),
      hasMore: serializer.fromJson<bool>(json['hasMore']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'filter': serializer.toJson<String>(filter),
      'nextOffset': serializer.toJson<int>(nextOffset),
      'hasMore': serializer.toJson<bool>(hasMore),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  DocumentsCacheState copyWith({
    String? caregiverId,
    String? patientId,
    String? filter,
    int? nextOffset,
    bool? hasMore,
    DateTime? refreshedAt,
  }) => DocumentsCacheState(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    filter: filter ?? this.filter,
    nextOffset: nextOffset ?? this.nextOffset,
    hasMore: hasMore ?? this.hasMore,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  DocumentsCacheState copyWithCompanion(DocumentsCacheStatesCompanion data) {
    return DocumentsCacheState(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      filter: data.filter.present ? data.filter.value : this.filter,
      nextOffset: data.nextOffset.present
          ? data.nextOffset.value
          : this.nextOffset,
      hasMore: data.hasMore.present ? data.hasMore.value : this.hasMore,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCacheState(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('filter: $filter, ')
          ..write('nextOffset: $nextOffset, ')
          ..write('hasMore: $hasMore, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    filter,
    nextOffset,
    hasMore,
    refreshedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentsCacheState &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.filter == this.filter &&
          other.nextOffset == this.nextOffset &&
          other.hasMore == this.hasMore &&
          other.refreshedAt == this.refreshedAt);
}

class DocumentsCacheStatesCompanion
    extends UpdateCompanion<DocumentsCacheState> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> filter;
  final Value<int> nextOffset;
  final Value<bool> hasMore;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const DocumentsCacheStatesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.filter = const Value.absent(),
    this.nextOffset = const Value.absent(),
    this.hasMore = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCacheStatesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String filter,
    required int nextOffset,
    required bool hasMore,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       filter = Value(filter),
       nextOffset = Value(nextOffset),
       hasMore = Value(hasMore),
       refreshedAt = Value(refreshedAt);
  static Insertable<DocumentsCacheState> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? filter,
    Expression<int>? nextOffset,
    Expression<bool>? hasMore,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (filter != null) 'filter': filter,
      if (nextOffset != null) 'next_offset': nextOffset,
      if (hasMore != null) 'has_more': hasMore,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCacheStatesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? filter,
    Value<int>? nextOffset,
    Value<bool>? hasMore,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return DocumentsCacheStatesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      filter: filter ?? this.filter,
      nextOffset: nextOffset ?? this.nextOffset,
      hasMore: hasMore ?? this.hasMore,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (filter.present) {
      map['filter'] = Variable<String>(filter.value);
    }
    if (nextOffset.present) {
      map['next_offset'] = Variable<int>(nextOffset.value);
    }
    if (hasMore.present) {
      map['has_more'] = Variable<bool>(hasMore.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $DocumentsCacheStatesTable.$converterrefreshedAt.toSql(
          refreshedAt.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCacheStatesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('filter: $filter, ')
          ..write('nextOffset: $nextOffset, ')
          ..write('hasMore: $hasMore, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedDocumentDetailsTable extends CachedDocumentDetails
    with TableInfo<$CachedDocumentDetailsTable, CachedDocumentDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDocumentDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaAssetIdMeta = const VerificationMeta(
    'mediaAssetId',
  );
  @override
  late final GeneratedColumn<String> mediaAssetId = GeneratedColumn<String>(
    'media_asset_id',
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
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $CachedDocumentDetailsTable.$converterrefreshedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    id,
    mediaAssetId,
    payload,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_document_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDocumentDetail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_asset_id')) {
      context.handle(
        _mediaAssetIdMeta,
        mediaAssetId.isAcceptableOrUnknown(
          data['media_asset_id']!,
          _mediaAssetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaAssetIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, id};
  @override
  CachedDocumentDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDocumentDetail(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mediaAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_asset_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      refreshedAt: $CachedDocumentDetailsTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $CachedDocumentDetailsTable createAlias(String alias) {
    return $CachedDocumentDetailsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class CachedDocumentDetail extends DataClass
    implements Insertable<CachedDocumentDetail> {
  final String caregiverId;
  final String patientId;
  final String id;
  final String mediaAssetId;
  final String payload;
  final DateTime refreshedAt;
  const CachedDocumentDetail({
    required this.caregiverId,
    required this.patientId,
    required this.id,
    required this.mediaAssetId,
    required this.payload,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['id'] = Variable<String>(id);
    map['media_asset_id'] = Variable<String>(mediaAssetId);
    map['payload'] = Variable<String>(payload);
    {
      map['refreshed_at'] = Variable<int>(
        $CachedDocumentDetailsTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  CachedDocumentDetailsCompanion toCompanion(bool nullToAbsent) {
    return CachedDocumentDetailsCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      id: Value(id),
      mediaAssetId: Value(mediaAssetId),
      payload: Value(payload),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory CachedDocumentDetail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDocumentDetail(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      mediaAssetId: serializer.fromJson<String>(json['mediaAssetId']),
      payload: serializer.fromJson<String>(json['payload']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'mediaAssetId': serializer.toJson<String>(mediaAssetId),
      'payload': serializer.toJson<String>(payload),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  CachedDocumentDetail copyWith({
    String? caregiverId,
    String? patientId,
    String? id,
    String? mediaAssetId,
    String? payload,
    DateTime? refreshedAt,
  }) => CachedDocumentDetail(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    mediaAssetId: mediaAssetId ?? this.mediaAssetId,
    payload: payload ?? this.payload,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  CachedDocumentDetail copyWithCompanion(CachedDocumentDetailsCompanion data) {
    return CachedDocumentDetail(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      mediaAssetId: data.mediaAssetId.present
          ? data.mediaAssetId.value
          : this.mediaAssetId,
      payload: data.payload.present ? data.payload.value : this.payload,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentDetail(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('mediaAssetId: $mediaAssetId, ')
          ..write('payload: $payload, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    caregiverId,
    patientId,
    id,
    mediaAssetId,
    payload,
    refreshedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDocumentDetail &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.mediaAssetId == this.mediaAssetId &&
          other.payload == this.payload &&
          other.refreshedAt == this.refreshedAt);
}

class CachedDocumentDetailsCompanion
    extends UpdateCompanion<CachedDocumentDetail> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> id;
  final Value<String> mediaAssetId;
  final Value<String> payload;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const CachedDocumentDetailsCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.id = const Value.absent(),
    this.mediaAssetId = const Value.absent(),
    this.payload = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDocumentDetailsCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String id,
    required String mediaAssetId,
    required String payload,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       id = Value(id),
       mediaAssetId = Value(mediaAssetId),
       payload = Value(payload),
       refreshedAt = Value(refreshedAt);
  static Insertable<CachedDocumentDetail> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? id,
    Expression<String>? mediaAssetId,
    Expression<String>? payload,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (mediaAssetId != null) 'media_asset_id': mediaAssetId,
      if (payload != null) 'payload': payload,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDocumentDetailsCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? id,
    Value<String>? mediaAssetId,
    Value<String>? payload,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return CachedDocumentDetailsCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      mediaAssetId: mediaAssetId ?? this.mediaAssetId,
      payload: payload ?? this.payload,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaAssetId.present) {
      map['media_asset_id'] = Variable<String>(mediaAssetId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $CachedDocumentDetailsTable.$converterrefreshedAt.toSql(
          refreshedAt.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentDetailsCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('mediaAssetId: $mediaAssetId, ')
          ..write('payload: $payload, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCaregiverAccountsTable extends CachedCaregiverAccounts
    with TableInfo<$CachedCaregiverAccountsTable, CachedCaregiverAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCaregiverAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $CachedCaregiverAccountsTable.$converterrefreshedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [id, fullName, email, refreshedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_caregiver_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCaregiverAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCaregiverAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCaregiverAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      refreshedAt: $CachedCaregiverAccountsTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $CachedCaregiverAccountsTable createAlias(String alias) {
    return $CachedCaregiverAccountsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class CachedCaregiverAccount extends DataClass
    implements Insertable<CachedCaregiverAccount> {
  final String id;
  final String fullName;
  final String email;
  final DateTime refreshedAt;
  const CachedCaregiverAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    map['email'] = Variable<String>(email);
    {
      map['refreshed_at'] = Variable<int>(
        $CachedCaregiverAccountsTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  CachedCaregiverAccountsCompanion toCompanion(bool nullToAbsent) {
    return CachedCaregiverAccountsCompanion(
      id: Value(id),
      fullName: Value(fullName),
      email: Value(email),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory CachedCaregiverAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCaregiverAccount(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      email: serializer.fromJson<String>(json['email']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'email': serializer.toJson<String>(email),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  CachedCaregiverAccount copyWith({
    String? id,
    String? fullName,
    String? email,
    DateTime? refreshedAt,
  }) => CachedCaregiverAccount(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  CachedCaregiverAccount copyWithCompanion(
    CachedCaregiverAccountsCompanion data,
  ) {
    return CachedCaregiverAccount(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      email: data.email.present ? data.email.value : this.email,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCaregiverAccount(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('email: $email, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fullName, email, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCaregiverAccount &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.email == this.email &&
          other.refreshedAt == this.refreshedAt);
}

class CachedCaregiverAccountsCompanion
    extends UpdateCompanion<CachedCaregiverAccount> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String> email;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const CachedCaregiverAccountsCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.email = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCaregiverAccountsCompanion.insert({
    required String id,
    required String fullName,
    required String email,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fullName = Value(fullName),
       email = Value(email),
       refreshedAt = Value(refreshedAt);
  static Insertable<CachedCaregiverAccount> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? email,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCaregiverAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? fullName,
    Value<String>? email,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return CachedCaregiverAccountsCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $CachedCaregiverAccountsTable.$converterrefreshedAt.toSql(
          refreshedAt.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCaregiverAccountsCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('email: $email, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedConsentsTable extends CachedConsents
    with TableInfo<$CachedConsentsTable, CachedConsent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedConsentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CachedConsentsTable.$converterrefreshedAt);
  @override
  List<GeneratedColumn> get $columns => [
    caregiverId,
    patientId,
    id,
    payload,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_consents';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedConsent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, id};
  @override
  CachedConsent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedConsent(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      refreshedAt: $CachedConsentsTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $CachedConsentsTable createAlias(String alias) {
    return $CachedConsentsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class CachedConsent extends DataClass implements Insertable<CachedConsent> {
  final String caregiverId;
  final String patientId;
  final String id;
  final String payload;
  final DateTime refreshedAt;
  const CachedConsent({
    required this.caregiverId,
    required this.patientId,
    required this.id,
    required this.payload,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    {
      map['refreshed_at'] = Variable<int>(
        $CachedConsentsTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  CachedConsentsCompanion toCompanion(bool nullToAbsent) {
    return CachedConsentsCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      id: Value(id),
      payload: Value(payload),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory CachedConsent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedConsent(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  CachedConsent copyWith({
    String? caregiverId,
    String? patientId,
    String? id,
    String? payload,
    DateTime? refreshedAt,
  }) => CachedConsent(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    payload: payload ?? this.payload,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  CachedConsent copyWithCompanion(CachedConsentsCompanion data) {
    return CachedConsent(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedConsent(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(caregiverId, patientId, id, payload, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedConsent &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.refreshedAt == this.refreshedAt);
}

class CachedConsentsCompanion extends UpdateCompanion<CachedConsent> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const CachedConsentsCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedConsentsCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String id,
    required String payload,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       id = Value(id),
       payload = Value(payload),
       refreshedAt = Value(refreshedAt);
  static Insertable<CachedConsent> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? id,
    Expression<String>? payload,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedConsentsCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return CachedConsentsCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      payload: payload ?? this.payload,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $CachedConsentsTable.$converterrefreshedAt.toSql(refreshedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedConsentsCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCaregiverLinksTable extends CachedCaregiverLinks
    with TableInfo<$CachedCaregiverLinksTable, CachedCaregiverLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCaregiverLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  List<GeneratedColumn> get $columns => [caregiverId, patientId, id, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_caregiver_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCaregiverLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId, id};
  @override
  CachedCaregiverLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCaregiverLink(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $CachedCaregiverLinksTable createAlias(String alias) {
    return $CachedCaregiverLinksTable(attachedDatabase, alias);
  }
}

class CachedCaregiverLink extends DataClass
    implements Insertable<CachedCaregiverLink> {
  final String caregiverId;
  final String patientId;
  final String id;
  final String payload;
  const CachedCaregiverLink({
    required this.caregiverId,
    required this.patientId,
    required this.id,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  CachedCaregiverLinksCompanion toCompanion(bool nullToAbsent) {
    return CachedCaregiverLinksCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      id: Value(id),
      payload: Value(payload),
    );
  }

  factory CachedCaregiverLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCaregiverLink(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
    };
  }

  CachedCaregiverLink copyWith({
    String? caregiverId,
    String? patientId,
    String? id,
    String? payload,
  }) => CachedCaregiverLink(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    payload: payload ?? this.payload,
  );
  CachedCaregiverLink copyWithCompanion(CachedCaregiverLinksCompanion data) {
    return CachedCaregiverLink(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCaregiverLink(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(caregiverId, patientId, id, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCaregiverLink &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.payload == this.payload);
}

class CachedCaregiverLinksCompanion
    extends UpdateCompanion<CachedCaregiverLink> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<String> id;
  final Value<String> payload;
  final Value<int> rowid;
  const CachedCaregiverLinksCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCaregiverLinksCompanion.insert({
    required String caregiverId,
    required String patientId,
    required String id,
    required String payload,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       id = Value(id),
       payload = Value(payload);
  static Insertable<CachedCaregiverLink> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<String>? id,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCaregiverLinksCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<String>? id,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return CachedCaregiverLinksCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCaregiverLinksCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CaregiversCacheStatesTable extends CaregiversCacheStates
    with TableInfo<$CaregiversCacheStatesTable, CaregiversCacheState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaregiversCacheStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _caregiverIdMeta = const VerificationMeta(
    'caregiverId',
  );
  @override
  late final GeneratedColumn<String> caregiverId = GeneratedColumn<String>(
    'caregiver_id',
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
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $CaregiversCacheStatesTable.$converterrefreshedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [caregiverId, patientId, refreshedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'caregivers_cache_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaregiversCacheState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('caregiver_id')) {
      context.handle(
        _caregiverIdMeta,
        caregiverId.isAcceptableOrUnknown(
          data['caregiver_id']!,
          _caregiverIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caregiverIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {caregiverId, patientId};
  @override
  CaregiversCacheState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaregiversCacheState(
      caregiverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caregiver_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      refreshedAt: $CaregiversCacheStatesTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $CaregiversCacheStatesTable createAlias(String alias) {
    return $CaregiversCacheStatesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class CaregiversCacheState extends DataClass
    implements Insertable<CaregiversCacheState> {
  final String caregiverId;
  final String patientId;
  final DateTime refreshedAt;
  const CaregiversCacheState({
    required this.caregiverId,
    required this.patientId,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['caregiver_id'] = Variable<String>(caregiverId);
    map['patient_id'] = Variable<String>(patientId);
    {
      map['refreshed_at'] = Variable<int>(
        $CaregiversCacheStatesTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  CaregiversCacheStatesCompanion toCompanion(bool nullToAbsent) {
    return CaregiversCacheStatesCompanion(
      caregiverId: Value(caregiverId),
      patientId: Value(patientId),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory CaregiversCacheState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaregiversCacheState(
      caregiverId: serializer.fromJson<String>(json['caregiverId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'caregiverId': serializer.toJson<String>(caregiverId),
      'patientId': serializer.toJson<String>(patientId),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  CaregiversCacheState copyWith({
    String? caregiverId,
    String? patientId,
    DateTime? refreshedAt,
  }) => CaregiversCacheState(
    caregiverId: caregiverId ?? this.caregiverId,
    patientId: patientId ?? this.patientId,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  CaregiversCacheState copyWithCompanion(CaregiversCacheStatesCompanion data) {
    return CaregiversCacheState(
      caregiverId: data.caregiverId.present
          ? data.caregiverId.value
          : this.caregiverId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaregiversCacheState(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(caregiverId, patientId, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaregiversCacheState &&
          other.caregiverId == this.caregiverId &&
          other.patientId == this.patientId &&
          other.refreshedAt == this.refreshedAt);
}

class CaregiversCacheStatesCompanion
    extends UpdateCompanion<CaregiversCacheState> {
  final Value<String> caregiverId;
  final Value<String> patientId;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const CaregiversCacheStatesCompanion({
    this.caregiverId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaregiversCacheStatesCompanion.insert({
    required String caregiverId,
    required String patientId,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : caregiverId = Value(caregiverId),
       patientId = Value(patientId),
       refreshedAt = Value(refreshedAt);
  static Insertable<CaregiversCacheState> custom({
    Expression<String>? caregiverId,
    Expression<String>? patientId,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (patientId != null) 'patient_id': patientId,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaregiversCacheStatesCompanion copyWith({
    Value<String>? caregiverId,
    Value<String>? patientId,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return CaregiversCacheStatesCompanion(
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (caregiverId.present) {
      map['caregiver_id'] = Variable<String>(caregiverId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $CaregiversCacheStatesTable.$converterrefreshedAt.toSql(
          refreshedAt.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaregiversCacheStatesCompanion(')
          ..write('caregiverId: $caregiverId, ')
          ..write('patientId: $patientId, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatientTodaySettingsTable extends PatientTodaySettings
    with TableInfo<$PatientTodaySettingsTable, PatientTodaySetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientTodaySettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memoryEnabledMeta = const VerificationMeta(
    'memoryEnabled',
  );
  @override
  late final GeneratedColumn<bool> memoryEnabled = GeneratedColumn<bool>(
    'memory_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("memory_enabled" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> refreshedAt =
      GeneratedColumn<int>(
        'refreshed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $PatientTodaySettingsTable.$converterrefreshedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [
    patientId,
    deviceId,
    fullName,
    language,
    timezone,
    memoryEnabled,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patient_today_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PatientTodaySetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('memory_enabled')) {
      context.handle(
        _memoryEnabledMeta,
        memoryEnabled.isAcceptableOrUnknown(
          data['memory_enabled']!,
          _memoryEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_memoryEnabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {patientId, deviceId};
  @override
  PatientTodaySetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatientTodaySetting(
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      memoryEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}memory_enabled'],
      )!,
      refreshedAt: $PatientTodaySettingsTable.$converterrefreshedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}refreshed_at'],
        )!,
      ),
    );
  }

  @override
  $PatientTodaySettingsTable createAlias(String alias) {
    return $PatientTodaySettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrefreshedAt = const UtcMicros();
}

class PatientTodaySetting extends DataClass
    implements Insertable<PatientTodaySetting> {
  final String patientId;
  final String deviceId;
  final String fullName;
  final String language;
  final String timezone;
  final bool memoryEnabled;
  final DateTime refreshedAt;
  const PatientTodaySetting({
    required this.patientId,
    required this.deviceId,
    required this.fullName,
    required this.language,
    required this.timezone,
    required this.memoryEnabled,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['patient_id'] = Variable<String>(patientId);
    map['device_id'] = Variable<String>(deviceId);
    map['full_name'] = Variable<String>(fullName);
    map['language'] = Variable<String>(language);
    map['timezone'] = Variable<String>(timezone);
    map['memory_enabled'] = Variable<bool>(memoryEnabled);
    {
      map['refreshed_at'] = Variable<int>(
        $PatientTodaySettingsTable.$converterrefreshedAt.toSql(refreshedAt),
      );
    }
    return map;
  }

  PatientTodaySettingsCompanion toCompanion(bool nullToAbsent) {
    return PatientTodaySettingsCompanion(
      patientId: Value(patientId),
      deviceId: Value(deviceId),
      fullName: Value(fullName),
      language: Value(language),
      timezone: Value(timezone),
      memoryEnabled: Value(memoryEnabled),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory PatientTodaySetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatientTodaySetting(
      patientId: serializer.fromJson<String>(json['patientId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      fullName: serializer.fromJson<String>(json['fullName']),
      language: serializer.fromJson<String>(json['language']),
      timezone: serializer.fromJson<String>(json['timezone']),
      memoryEnabled: serializer.fromJson<bool>(json['memoryEnabled']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'patientId': serializer.toJson<String>(patientId),
      'deviceId': serializer.toJson<String>(deviceId),
      'fullName': serializer.toJson<String>(fullName),
      'language': serializer.toJson<String>(language),
      'timezone': serializer.toJson<String>(timezone),
      'memoryEnabled': serializer.toJson<bool>(memoryEnabled),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  PatientTodaySetting copyWith({
    String? patientId,
    String? deviceId,
    String? fullName,
    String? language,
    String? timezone,
    bool? memoryEnabled,
    DateTime? refreshedAt,
  }) => PatientTodaySetting(
    patientId: patientId ?? this.patientId,
    deviceId: deviceId ?? this.deviceId,
    fullName: fullName ?? this.fullName,
    language: language ?? this.language,
    timezone: timezone ?? this.timezone,
    memoryEnabled: memoryEnabled ?? this.memoryEnabled,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  PatientTodaySetting copyWithCompanion(PatientTodaySettingsCompanion data) {
    return PatientTodaySetting(
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      language: data.language.present ? data.language.value : this.language,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      memoryEnabled: data.memoryEnabled.present
          ? data.memoryEnabled.value
          : this.memoryEnabled,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatientTodaySetting(')
          ..write('patientId: $patientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('fullName: $fullName, ')
          ..write('language: $language, ')
          ..write('timezone: $timezone, ')
          ..write('memoryEnabled: $memoryEnabled, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    patientId,
    deviceId,
    fullName,
    language,
    timezone,
    memoryEnabled,
    refreshedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatientTodaySetting &&
          other.patientId == this.patientId &&
          other.deviceId == this.deviceId &&
          other.fullName == this.fullName &&
          other.language == this.language &&
          other.timezone == this.timezone &&
          other.memoryEnabled == this.memoryEnabled &&
          other.refreshedAt == this.refreshedAt);
}

class PatientTodaySettingsCompanion
    extends UpdateCompanion<PatientTodaySetting> {
  final Value<String> patientId;
  final Value<String> deviceId;
  final Value<String> fullName;
  final Value<String> language;
  final Value<String> timezone;
  final Value<bool> memoryEnabled;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const PatientTodaySettingsCompanion({
    this.patientId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fullName = const Value.absent(),
    this.language = const Value.absent(),
    this.timezone = const Value.absent(),
    this.memoryEnabled = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatientTodaySettingsCompanion.insert({
    required String patientId,
    required String deviceId,
    required String fullName,
    required String language,
    required String timezone,
    required bool memoryEnabled,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : patientId = Value(patientId),
       deviceId = Value(deviceId),
       fullName = Value(fullName),
       language = Value(language),
       timezone = Value(timezone),
       memoryEnabled = Value(memoryEnabled),
       refreshedAt = Value(refreshedAt);
  static Insertable<PatientTodaySetting> custom({
    Expression<String>? patientId,
    Expression<String>? deviceId,
    Expression<String>? fullName,
    Expression<String>? language,
    Expression<String>? timezone,
    Expression<bool>? memoryEnabled,
    Expression<int>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (patientId != null) 'patient_id': patientId,
      if (deviceId != null) 'device_id': deviceId,
      if (fullName != null) 'full_name': fullName,
      if (language != null) 'language': language,
      if (timezone != null) 'timezone': timezone,
      if (memoryEnabled != null) 'memory_enabled': memoryEnabled,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatientTodaySettingsCompanion copyWith({
    Value<String>? patientId,
    Value<String>? deviceId,
    Value<String>? fullName,
    Value<String>? language,
    Value<String>? timezone,
    Value<bool>? memoryEnabled,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return PatientTodaySettingsCompanion(
      patientId: patientId ?? this.patientId,
      deviceId: deviceId ?? this.deviceId,
      fullName: fullName ?? this.fullName,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      memoryEnabled: memoryEnabled ?? this.memoryEnabled,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (memoryEnabled.present) {
      map['memory_enabled'] = Variable<bool>(memoryEnabled.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<int>(
        $PatientTodaySettingsTable.$converterrefreshedAt.toSql(
          refreshedAt.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientTodaySettingsCompanion(')
          ..write('patientId: $patientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('fullName: $fullName, ')
          ..write('language: $language, ')
          ..write('timezone: $timezone, ')
          ..write('memoryEnabled: $memoryEnabled, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatientReminderCardsTable extends PatientReminderCards
    with TableInfo<$PatientReminderCardsTable, PatientReminderCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientReminderCardsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [patientId, deviceId, id, day, title];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patient_reminder_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<PatientReminderCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {patientId, deviceId, id};
  @override
  PatientReminderCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatientReminderCard(
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
    );
  }

  @override
  $PatientReminderCardsTable createAlias(String alias) {
    return $PatientReminderCardsTable(attachedDatabase, alias);
  }
}

class PatientReminderCard extends DataClass
    implements Insertable<PatientReminderCard> {
  final String patientId;
  final String deviceId;
  final String id;
  final String day;
  final String title;
  const PatientReminderCard({
    required this.patientId,
    required this.deviceId,
    required this.id,
    required this.day,
    required this.title,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['patient_id'] = Variable<String>(patientId);
    map['device_id'] = Variable<String>(deviceId);
    map['id'] = Variable<String>(id);
    map['day'] = Variable<String>(day);
    map['title'] = Variable<String>(title);
    return map;
  }

  PatientReminderCardsCompanion toCompanion(bool nullToAbsent) {
    return PatientReminderCardsCompanion(
      patientId: Value(patientId),
      deviceId: Value(deviceId),
      id: Value(id),
      day: Value(day),
      title: Value(title),
    );
  }

  factory PatientReminderCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatientReminderCard(
      patientId: serializer.fromJson<String>(json['patientId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      title: serializer.fromJson<String>(json['title']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'patientId': serializer.toJson<String>(patientId),
      'deviceId': serializer.toJson<String>(deviceId),
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<String>(day),
      'title': serializer.toJson<String>(title),
    };
  }

  PatientReminderCard copyWith({
    String? patientId,
    String? deviceId,
    String? id,
    String? day,
    String? title,
  }) => PatientReminderCard(
    patientId: patientId ?? this.patientId,
    deviceId: deviceId ?? this.deviceId,
    id: id ?? this.id,
    day: day ?? this.day,
    title: title ?? this.title,
  );
  PatientReminderCard copyWithCompanion(PatientReminderCardsCompanion data) {
    return PatientReminderCard(
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      title: data.title.present ? data.title.value : this.title,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatientReminderCard(')
          ..write('patientId: $patientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(patientId, deviceId, id, day, title);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatientReminderCard &&
          other.patientId == this.patientId &&
          other.deviceId == this.deviceId &&
          other.id == this.id &&
          other.day == this.day &&
          other.title == this.title);
}

class PatientReminderCardsCompanion
    extends UpdateCompanion<PatientReminderCard> {
  final Value<String> patientId;
  final Value<String> deviceId;
  final Value<String> id;
  final Value<String> day;
  final Value<String> title;
  final Value<int> rowid;
  const PatientReminderCardsCompanion({
    this.patientId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.title = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatientReminderCardsCompanion.insert({
    required String patientId,
    required String deviceId,
    required String id,
    required String day,
    required String title,
    this.rowid = const Value.absent(),
  }) : patientId = Value(patientId),
       deviceId = Value(deviceId),
       id = Value(id),
       day = Value(day),
       title = Value(title);
  static Insertable<PatientReminderCard> custom({
    Expression<String>? patientId,
    Expression<String>? deviceId,
    Expression<String>? id,
    Expression<String>? day,
    Expression<String>? title,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (patientId != null) 'patient_id': patientId,
      if (deviceId != null) 'device_id': deviceId,
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (title != null) 'title': title,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatientReminderCardsCompanion copyWith({
    Value<String>? patientId,
    Value<String>? deviceId,
    Value<String>? id,
    Value<String>? day,
    Value<String>? title,
    Value<int>? rowid,
  }) {
    return PatientReminderCardsCompanion(
      patientId: patientId ?? this.patientId,
      deviceId: deviceId ?? this.deviceId,
      id: id ?? this.id,
      day: day ?? this.day,
      title: title ?? this.title,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientReminderCardsCompanion(')
          ..write('patientId: $patientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatientKnownEncountersTable extends PatientKnownEncounters
    with TableInfo<$PatientKnownEncountersTable, PatientKnownEncounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientKnownEncountersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> firstSeen =
      GeneratedColumn<int>(
        'first_seen',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $PatientKnownEncountersTable.$converterfirstSeen,
      );
  @override
  List<GeneratedColumn> get $columns => [
    patientId,
    deviceId,
    day,
    personId,
    name,
    firstSeen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patient_known_encounters';
  @override
  VerificationContext validateIntegrity(
    Insertable<PatientKnownEncounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {patientId, deviceId, day, personId};
  @override
  PatientKnownEncounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatientKnownEncounter(
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      firstSeen: $PatientKnownEncountersTable.$converterfirstSeen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}first_seen'],
        )!,
      ),
    );
  }

  @override
  $PatientKnownEncountersTable createAlias(String alias) {
    return $PatientKnownEncountersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterfirstSeen = const UtcMicros();
}

class PatientKnownEncounter extends DataClass
    implements Insertable<PatientKnownEncounter> {
  final String patientId;
  final String deviceId;
  final String day;
  final String personId;
  final String name;
  final DateTime firstSeen;
  const PatientKnownEncounter({
    required this.patientId,
    required this.deviceId,
    required this.day,
    required this.personId,
    required this.name,
    required this.firstSeen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['patient_id'] = Variable<String>(patientId);
    map['device_id'] = Variable<String>(deviceId);
    map['day'] = Variable<String>(day);
    map['person_id'] = Variable<String>(personId);
    map['name'] = Variable<String>(name);
    {
      map['first_seen'] = Variable<int>(
        $PatientKnownEncountersTable.$converterfirstSeen.toSql(firstSeen),
      );
    }
    return map;
  }

  PatientKnownEncountersCompanion toCompanion(bool nullToAbsent) {
    return PatientKnownEncountersCompanion(
      patientId: Value(patientId),
      deviceId: Value(deviceId),
      day: Value(day),
      personId: Value(personId),
      name: Value(name),
      firstSeen: Value(firstSeen),
    );
  }

  factory PatientKnownEncounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatientKnownEncounter(
      patientId: serializer.fromJson<String>(json['patientId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      day: serializer.fromJson<String>(json['day']),
      personId: serializer.fromJson<String>(json['personId']),
      name: serializer.fromJson<String>(json['name']),
      firstSeen: serializer.fromJson<DateTime>(json['firstSeen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'patientId': serializer.toJson<String>(patientId),
      'deviceId': serializer.toJson<String>(deviceId),
      'day': serializer.toJson<String>(day),
      'personId': serializer.toJson<String>(personId),
      'name': serializer.toJson<String>(name),
      'firstSeen': serializer.toJson<DateTime>(firstSeen),
    };
  }

  PatientKnownEncounter copyWith({
    String? patientId,
    String? deviceId,
    String? day,
    String? personId,
    String? name,
    DateTime? firstSeen,
  }) => PatientKnownEncounter(
    patientId: patientId ?? this.patientId,
    deviceId: deviceId ?? this.deviceId,
    day: day ?? this.day,
    personId: personId ?? this.personId,
    name: name ?? this.name,
    firstSeen: firstSeen ?? this.firstSeen,
  );
  PatientKnownEncounter copyWithCompanion(
    PatientKnownEncountersCompanion data,
  ) {
    return PatientKnownEncounter(
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      day: data.day.present ? data.day.value : this.day,
      personId: data.personId.present ? data.personId.value : this.personId,
      name: data.name.present ? data.name.value : this.name,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatientKnownEncounter(')
          ..write('patientId: $patientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('day: $day, ')
          ..write('personId: $personId, ')
          ..write('name: $name, ')
          ..write('firstSeen: $firstSeen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(patientId, deviceId, day, personId, name, firstSeen);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatientKnownEncounter &&
          other.patientId == this.patientId &&
          other.deviceId == this.deviceId &&
          other.day == this.day &&
          other.personId == this.personId &&
          other.name == this.name &&
          other.firstSeen == this.firstSeen);
}

class PatientKnownEncountersCompanion
    extends UpdateCompanion<PatientKnownEncounter> {
  final Value<String> patientId;
  final Value<String> deviceId;
  final Value<String> day;
  final Value<String> personId;
  final Value<String> name;
  final Value<DateTime> firstSeen;
  final Value<int> rowid;
  const PatientKnownEncountersCompanion({
    this.patientId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.day = const Value.absent(),
    this.personId = const Value.absent(),
    this.name = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatientKnownEncountersCompanion.insert({
    required String patientId,
    required String deviceId,
    required String day,
    required String personId,
    required String name,
    required DateTime firstSeen,
    this.rowid = const Value.absent(),
  }) : patientId = Value(patientId),
       deviceId = Value(deviceId),
       day = Value(day),
       personId = Value(personId),
       name = Value(name),
       firstSeen = Value(firstSeen);
  static Insertable<PatientKnownEncounter> custom({
    Expression<String>? patientId,
    Expression<String>? deviceId,
    Expression<String>? day,
    Expression<String>? personId,
    Expression<String>? name,
    Expression<int>? firstSeen,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (patientId != null) 'patient_id': patientId,
      if (deviceId != null) 'device_id': deviceId,
      if (day != null) 'day': day,
      if (personId != null) 'person_id': personId,
      if (name != null) 'name': name,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatientKnownEncountersCompanion copyWith({
    Value<String>? patientId,
    Value<String>? deviceId,
    Value<String>? day,
    Value<String>? personId,
    Value<String>? name,
    Value<DateTime>? firstSeen,
    Value<int>? rowid,
  }) {
    return PatientKnownEncountersCompanion(
      patientId: patientId ?? this.patientId,
      deviceId: deviceId ?? this.deviceId,
      day: day ?? this.day,
      personId: personId ?? this.personId,
      name: name ?? this.name,
      firstSeen: firstSeen ?? this.firstSeen,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<int>(
        $PatientKnownEncountersTable.$converterfirstSeen.toSql(firstSeen.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientKnownEncountersCompanion(')
          ..write('patientId: $patientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('day: $day, ')
          ..write('personId: $personId, ')
          ..write('name: $name, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RemoriDatabase extends GeneratedDatabase {
  _$RemoriDatabase(QueryExecutor e) : super(e);
  $RemoriDatabaseManager get managers => $RemoriDatabaseManager(this);
  late final $ReminderLogsTable reminderLogs = $ReminderLogsTable(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  late final $DashboardPatientsTable dashboardPatients =
      $DashboardPatientsTable(this);
  late final $DashboardDevicesTable dashboardDevices = $DashboardDevicesTable(
    this,
  );
  late final $DashboardAlertsTable dashboardAlerts = $DashboardAlertsTable(
    this,
  );
  late final $DashboardDaysTable dashboardDays = $DashboardDaysTable(this);
  late final $CachedPeopleTable cachedPeople = $CachedPeopleTable(this);
  late final $PeopleCacheStatesTable peopleCacheStates =
      $PeopleCacheStatesTable(this);
  late final $PersonDetailStatesTable personDetailStates =
      $PersonDetailStatesTable(this);
  late final $CachedPersonPhotosTable cachedPersonPhotos =
      $CachedPersonPhotosTable(this);
  late final $CachedRemindersTable cachedReminders = $CachedRemindersTable(
    this,
  );
  late final $CachedReminderOccurrencesTable cachedReminderOccurrences =
      $CachedReminderOccurrencesTable(this);
  late final $ReminderCacheStatesTable reminderCacheStates =
      $ReminderCacheStatesTable(this);
  late final $CachedUnknownFacesTable cachedUnknownFaces =
      $CachedUnknownFacesTable(this);
  late final $UnknownFacesCacheStatesTable unknownFacesCacheStates =
      $UnknownFacesCacheStatesTable(this);
  late final $CachedUnknownFaceSamplesTable cachedUnknownFaceSamples =
      $CachedUnknownFaceSamplesTable(this);
  late final $CachedPlacesTable cachedPlaces = $CachedPlacesTable(this);
  late final $PlacesCacheStatesTable placesCacheStates =
      $PlacesCacheStatesTable(this);
  late final $CachedJournalEntriesTable cachedJournalEntries =
      $CachedJournalEntriesTable(this);
  late final $CachedJournalMediaTable cachedJournalMedia =
      $CachedJournalMediaTable(this);
  late final $JournalCacheStatesTable journalCacheStates =
      $JournalCacheStatesTable(this);
  late final $CachedMediaDetailsTable cachedMediaDetails =
      $CachedMediaDetailsTable(this);
  late final $CachedDocumentsTable cachedDocuments = $CachedDocumentsTable(
    this,
  );
  late final $DocumentsCacheStatesTable documentsCacheStates =
      $DocumentsCacheStatesTable(this);
  late final $CachedDocumentDetailsTable cachedDocumentDetails =
      $CachedDocumentDetailsTable(this);
  late final $CachedCaregiverAccountsTable cachedCaregiverAccounts =
      $CachedCaregiverAccountsTable(this);
  late final $CachedConsentsTable cachedConsents = $CachedConsentsTable(this);
  late final $CachedCaregiverLinksTable cachedCaregiverLinks =
      $CachedCaregiverLinksTable(this);
  late final $CaregiversCacheStatesTable caregiversCacheStates =
      $CaregiversCacheStatesTable(this);
  late final $PatientTodaySettingsTable patientTodaySettings =
      $PatientTodaySettingsTable(this);
  late final $PatientReminderCardsTable patientReminderCards =
      $PatientReminderCardsTable(this);
  late final $PatientKnownEncountersTable patientKnownEncounters =
      $PatientKnownEncountersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    reminderLogs,
    outboxEntries,
    dashboardPatients,
    dashboardDevices,
    dashboardAlerts,
    dashboardDays,
    cachedPeople,
    peopleCacheStates,
    personDetailStates,
    cachedPersonPhotos,
    cachedReminders,
    cachedReminderOccurrences,
    reminderCacheStates,
    cachedUnknownFaces,
    unknownFacesCacheStates,
    cachedUnknownFaceSamples,
    cachedPlaces,
    placesCacheStates,
    cachedJournalEntries,
    cachedJournalMedia,
    journalCacheStates,
    cachedMediaDetails,
    cachedDocuments,
    documentsCacheStates,
    cachedDocumentDetails,
    cachedCaregiverAccounts,
    cachedConsents,
    cachedCaregiverLinks,
    caregiversCacheStates,
    patientTodaySettings,
    patientReminderCards,
    patientKnownEncounters,
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
typedef $$DashboardPatientsTableCreateCompanionBuilder =
    DashboardPatientsCompanion Function({
      required String caregiverId,
      required String id,
      required String fullName,
      required String preferredLanguage,
      required String timezone,
      required bool memoryCaptureEnabled,
      required String permission,
      required int position,
      Value<int> rowid,
    });
typedef $$DashboardPatientsTableUpdateCompanionBuilder =
    DashboardPatientsCompanion Function({
      Value<String> caregiverId,
      Value<String> id,
      Value<String> fullName,
      Value<String> preferredLanguage,
      Value<String> timezone,
      Value<bool> memoryCaptureEnabled,
      Value<String> permission,
      Value<int> position,
      Value<int> rowid,
    });

class $$DashboardPatientsTableFilterComposer
    extends Composer<_$RemoriDatabase, $DashboardPatientsTable> {
  $$DashboardPatientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredLanguage => $composableBuilder(
    column: $table.preferredLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get memoryCaptureEnabled => $composableBuilder(
    column: $table.memoryCaptureEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DashboardPatientsTableOrderingComposer
    extends Composer<_$RemoriDatabase, $DashboardPatientsTable> {
  $$DashboardPatientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredLanguage => $composableBuilder(
    column: $table.preferredLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get memoryCaptureEnabled => $composableBuilder(
    column: $table.memoryCaptureEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DashboardPatientsTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $DashboardPatientsTable> {
  $$DashboardPatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get preferredLanguage => $composableBuilder(
    column: $table.preferredLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<bool> get memoryCaptureEnabled => $composableBuilder(
    column: $table.memoryCaptureEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$DashboardPatientsTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $DashboardPatientsTable,
          DashboardPatient,
          $$DashboardPatientsTableFilterComposer,
          $$DashboardPatientsTableOrderingComposer,
          $$DashboardPatientsTableAnnotationComposer,
          $$DashboardPatientsTableCreateCompanionBuilder,
          $$DashboardPatientsTableUpdateCompanionBuilder,
          (
            DashboardPatient,
            BaseReferences<
              _$RemoriDatabase,
              $DashboardPatientsTable,
              DashboardPatient
            >,
          ),
          DashboardPatient,
          PrefetchHooks Function()
        > {
  $$DashboardPatientsTableTableManager(
    _$RemoriDatabase db,
    $DashboardPatientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardPatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardPatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DashboardPatientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> preferredLanguage = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<bool> memoryCaptureEnabled = const Value.absent(),
                Value<String> permission = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DashboardPatientsCompanion(
                caregiverId: caregiverId,
                id: id,
                fullName: fullName,
                preferredLanguage: preferredLanguage,
                timezone: timezone,
                memoryCaptureEnabled: memoryCaptureEnabled,
                permission: permission,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String id,
                required String fullName,
                required String preferredLanguage,
                required String timezone,
                required bool memoryCaptureEnabled,
                required String permission,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => DashboardPatientsCompanion.insert(
                caregiverId: caregiverId,
                id: id,
                fullName: fullName,
                preferredLanguage: preferredLanguage,
                timezone: timezone,
                memoryCaptureEnabled: memoryCaptureEnabled,
                permission: permission,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DashboardPatientsTable, DashboardPatient>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $DashboardPatientsTable,
                    DashboardPatient
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DashboardPatientsTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $DashboardPatientsTable,
      DashboardPatient,
      $$DashboardPatientsTableFilterComposer,
      $$DashboardPatientsTableOrderingComposer,
      $$DashboardPatientsTableAnnotationComposer,
      $$DashboardPatientsTableCreateCompanionBuilder,
      $$DashboardPatientsTableUpdateCompanionBuilder,
      (
        DashboardPatient,
        BaseReferences<
          _$RemoriDatabase,
          $DashboardPatientsTable,
          DashboardPatient
        >,
      ),
      DashboardPatient,
      PrefetchHooks Function()
    >;
typedef $$DashboardDevicesTableCreateCompanionBuilder =
    DashboardDevicesCompanion Function({
      required String caregiverId,
      required String patientId,
      required String id,
      required String serial,
      Value<String?> firmwareVersion,
      Value<DateTime?> pairedAt,
      required bool online,
      Value<int?> batteryPct,
      Value<DateTime?> lastSeenAt,
      Value<int> rowid,
    });
typedef $$DashboardDevicesTableUpdateCompanionBuilder =
    DashboardDevicesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> id,
      Value<String> serial,
      Value<String?> firmwareVersion,
      Value<DateTime?> pairedAt,
      Value<bool> online,
      Value<int?> batteryPct,
      Value<DateTime?> lastSeenAt,
      Value<int> rowid,
    });

class $$DashboardDevicesTableFilterComposer
    extends Composer<_$RemoriDatabase, $DashboardDevicesTable> {
  $$DashboardDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firmwareVersion => $composableBuilder(
    column: $table.firmwareVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get pairedAt =>
      $composableBuilder(
        column: $table.pairedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get online => $composableBuilder(
    column: $table.online,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastSeenAt =>
      $composableBuilder(
        column: $table.lastSeenAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$DashboardDevicesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $DashboardDevicesTable> {
  $$DashboardDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firmwareVersion => $composableBuilder(
    column: $table.firmwareVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get online => $composableBuilder(
    column: $table.online,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DashboardDevicesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $DashboardDevicesTable> {
  $$DashboardDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serial =>
      $composableBuilder(column: $table.serial, builder: (column) => column);

  GeneratedColumn<String> get firmwareVersion => $composableBuilder(
    column: $table.firmwareVersion,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);

  GeneratedColumn<bool> get online =>
      $composableBuilder(column: $table.online, builder: (column) => column);

  GeneratedColumn<int> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastSeenAt =>
      $composableBuilder(
        column: $table.lastSeenAt,
        builder: (column) => column,
      );
}

class $$DashboardDevicesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $DashboardDevicesTable,
          DashboardDevice,
          $$DashboardDevicesTableFilterComposer,
          $$DashboardDevicesTableOrderingComposer,
          $$DashboardDevicesTableAnnotationComposer,
          $$DashboardDevicesTableCreateCompanionBuilder,
          $$DashboardDevicesTableUpdateCompanionBuilder,
          (
            DashboardDevice,
            BaseReferences<
              _$RemoriDatabase,
              $DashboardDevicesTable,
              DashboardDevice
            >,
          ),
          DashboardDevice,
          PrefetchHooks Function()
        > {
  $$DashboardDevicesTableTableManager(
    _$RemoriDatabase db,
    $DashboardDevicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DashboardDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> serial = const Value.absent(),
                Value<String?> firmwareVersion = const Value.absent(),
                Value<DateTime?> pairedAt = const Value.absent(),
                Value<bool> online = const Value.absent(),
                Value<int?> batteryPct = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DashboardDevicesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                serial: serial,
                firmwareVersion: firmwareVersion,
                pairedAt: pairedAt,
                online: online,
                batteryPct: batteryPct,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String id,
                required String serial,
                Value<String?> firmwareVersion = const Value.absent(),
                Value<DateTime?> pairedAt = const Value.absent(),
                required bool online,
                Value<int?> batteryPct = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DashboardDevicesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                serial: serial,
                firmwareVersion: firmwareVersion,
                pairedAt: pairedAt,
                online: online,
                batteryPct: batteryPct,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DashboardDevicesTable, DashboardDevice>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $DashboardDevicesTable,
                    DashboardDevice
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DashboardDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $DashboardDevicesTable,
      DashboardDevice,
      $$DashboardDevicesTableFilterComposer,
      $$DashboardDevicesTableOrderingComposer,
      $$DashboardDevicesTableAnnotationComposer,
      $$DashboardDevicesTableCreateCompanionBuilder,
      $$DashboardDevicesTableUpdateCompanionBuilder,
      (
        DashboardDevice,
        BaseReferences<
          _$RemoriDatabase,
          $DashboardDevicesTable,
          DashboardDevice
        >,
      ),
      DashboardDevice,
      PrefetchHooks Function()
    >;
typedef $$DashboardAlertsTableCreateCompanionBuilder =
    DashboardAlertsCompanion Function({
      required String caregiverId,
      required String id,
      required String patientId,
      required String alertType,
      required String message,
      required DateTime createdAt,
      Value<DateTime?> readAt,
      Value<String?> entityType,
      Value<String?> entityId,
      Value<int> rowid,
    });
typedef $$DashboardAlertsTableUpdateCompanionBuilder =
    DashboardAlertsCompanion Function({
      Value<String> caregiverId,
      Value<String> id,
      Value<String> patientId,
      Value<String> alertType,
      Value<String> message,
      Value<DateTime> createdAt,
      Value<DateTime?> readAt,
      Value<String?> entityType,
      Value<String?> entityId,
      Value<int> rowid,
    });

class $$DashboardAlertsTableFilterComposer
    extends Composer<_$RemoriDatabase, $DashboardAlertsTable> {
  $$DashboardAlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
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

  ColumnFilters<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get readAt =>
      $composableBuilder(
        column: $table.readAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DashboardAlertsTableOrderingComposer
    extends Composer<_$RemoriDatabase, $DashboardAlertsTable> {
  $$DashboardAlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
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

  ColumnOrderings<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DashboardAlertsTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $DashboardAlertsTable> {
  $$DashboardAlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get alertType =>
      $composableBuilder(column: $table.alertType, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);
}

class $$DashboardAlertsTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $DashboardAlertsTable,
          DashboardAlert,
          $$DashboardAlertsTableFilterComposer,
          $$DashboardAlertsTableOrderingComposer,
          $$DashboardAlertsTableAnnotationComposer,
          $$DashboardAlertsTableCreateCompanionBuilder,
          $$DashboardAlertsTableUpdateCompanionBuilder,
          (
            DashboardAlert,
            BaseReferences<
              _$RemoriDatabase,
              $DashboardAlertsTable,
              DashboardAlert
            >,
          ),
          DashboardAlert,
          PrefetchHooks Function()
        > {
  $$DashboardAlertsTableTableManager(
    _$RemoriDatabase db,
    $DashboardAlertsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardAlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardAlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DashboardAlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> alertType = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DashboardAlertsCompanion(
                caregiverId: caregiverId,
                id: id,
                patientId: patientId,
                alertType: alertType,
                message: message,
                createdAt: createdAt,
                readAt: readAt,
                entityType: entityType,
                entityId: entityId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String id,
                required String patientId,
                required String alertType,
                required String message,
                required DateTime createdAt,
                Value<DateTime?> readAt = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DashboardAlertsCompanion.insert(
                caregiverId: caregiverId,
                id: id,
                patientId: patientId,
                alertType: alertType,
                message: message,
                createdAt: createdAt,
                readAt: readAt,
                entityType: entityType,
                entityId: entityId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DashboardAlertsTable, DashboardAlert>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $DashboardAlertsTable,
                    DashboardAlert
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DashboardAlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $DashboardAlertsTable,
      DashboardAlert,
      $$DashboardAlertsTableFilterComposer,
      $$DashboardAlertsTableOrderingComposer,
      $$DashboardAlertsTableAnnotationComposer,
      $$DashboardAlertsTableCreateCompanionBuilder,
      $$DashboardAlertsTableUpdateCompanionBuilder,
      (
        DashboardAlert,
        BaseReferences<_$RemoriDatabase, $DashboardAlertsTable, DashboardAlert>,
      ),
      DashboardAlert,
      PrefetchHooks Function()
    >;
typedef $$DashboardDaysTableCreateCompanionBuilder =
    DashboardDaysCompanion Function({
      required String caregiverId,
      required String patientId,
      required String day,
      required int peopleMet,
      required int remindersDone,
      required int remindersTotal,
      required int snoozed,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$DashboardDaysTableUpdateCompanionBuilder =
    DashboardDaysCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> day,
      Value<int> peopleMet,
      Value<int> remindersDone,
      Value<int> remindersTotal,
      Value<int> snoozed,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$DashboardDaysTableFilterComposer
    extends Composer<_$RemoriDatabase, $DashboardDaysTable> {
  $$DashboardDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peopleMet => $composableBuilder(
    column: $table.peopleMet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindersDone => $composableBuilder(
    column: $table.remindersDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindersTotal => $composableBuilder(
    column: $table.remindersTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozed => $composableBuilder(
    column: $table.snoozed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$DashboardDaysTableOrderingComposer
    extends Composer<_$RemoriDatabase, $DashboardDaysTable> {
  $$DashboardDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peopleMet => $composableBuilder(
    column: $table.peopleMet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindersDone => $composableBuilder(
    column: $table.remindersDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindersTotal => $composableBuilder(
    column: $table.remindersTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozed => $composableBuilder(
    column: $table.snoozed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DashboardDaysTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $DashboardDaysTable> {
  $$DashboardDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get peopleMet =>
      $composableBuilder(column: $table.peopleMet, builder: (column) => column);

  GeneratedColumn<int> get remindersDone => $composableBuilder(
    column: $table.remindersDone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remindersTotal => $composableBuilder(
    column: $table.remindersTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozed =>
      $composableBuilder(column: $table.snoozed, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$DashboardDaysTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $DashboardDaysTable,
          DashboardDay,
          $$DashboardDaysTableFilterComposer,
          $$DashboardDaysTableOrderingComposer,
          $$DashboardDaysTableAnnotationComposer,
          $$DashboardDaysTableCreateCompanionBuilder,
          $$DashboardDaysTableUpdateCompanionBuilder,
          (
            DashboardDay,
            BaseReferences<_$RemoriDatabase, $DashboardDaysTable, DashboardDay>,
          ),
          DashboardDay,
          PrefetchHooks Function()
        > {
  $$DashboardDaysTableTableManager(
    _$RemoriDatabase db,
    $DashboardDaysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DashboardDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<int> peopleMet = const Value.absent(),
                Value<int> remindersDone = const Value.absent(),
                Value<int> remindersTotal = const Value.absent(),
                Value<int> snoozed = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DashboardDaysCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                day: day,
                peopleMet: peopleMet,
                remindersDone: remindersDone,
                remindersTotal: remindersTotal,
                snoozed: snoozed,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String day,
                required int peopleMet,
                required int remindersDone,
                required int remindersTotal,
                required int snoozed,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => DashboardDaysCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                day: day,
                peopleMet: peopleMet,
                remindersDone: remindersDone,
                remindersTotal: remindersTotal,
                snoozed: snoozed,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DashboardDaysTable, DashboardDay>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $DashboardDaysTable,
                    DashboardDay
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DashboardDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $DashboardDaysTable,
      DashboardDay,
      $$DashboardDaysTableFilterComposer,
      $$DashboardDaysTableOrderingComposer,
      $$DashboardDaysTableAnnotationComposer,
      $$DashboardDaysTableCreateCompanionBuilder,
      $$DashboardDaysTableUpdateCompanionBuilder,
      (
        DashboardDay,
        BaseReferences<_$RemoriDatabase, $DashboardDaysTable, DashboardDay>,
      ),
      DashboardDay,
      PrefetchHooks Function()
    >;
typedef $$CachedPeopleTableCreateCompanionBuilder =
    CachedPeopleCompanion Function({
      required String caregiverId,
      required String patientId,
      required String id,
      required String name,
      required String relationship,
      required String status,
      required int embeddingCount,
      required DateTime updatedAt,
      Value<String?> photoUrl,
      required int position,
      Value<int> rowid,
    });
typedef $$CachedPeopleTableUpdateCompanionBuilder =
    CachedPeopleCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> id,
      Value<String> name,
      Value<String> relationship,
      Value<String> status,
      Value<int> embeddingCount,
      Value<DateTime> updatedAt,
      Value<String?> photoUrl,
      Value<int> position,
      Value<int> rowid,
    });

class $$CachedPeopleTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedPeopleTable> {
  $$CachedPeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get embeddingCount => $composableBuilder(
    column: $table.embeddingCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPeopleTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedPeopleTable> {
  $$CachedPeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get embeddingCount => $composableBuilder(
    column: $table.embeddingCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPeopleTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedPeopleTable> {
  $$CachedPeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get embeddingCount => $composableBuilder(
    column: $table.embeddingCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedPeopleTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedPeopleTable,
          CachedPeopleData,
          $$CachedPeopleTableFilterComposer,
          $$CachedPeopleTableOrderingComposer,
          $$CachedPeopleTableAnnotationComposer,
          $$CachedPeopleTableCreateCompanionBuilder,
          $$CachedPeopleTableUpdateCompanionBuilder,
          (
            CachedPeopleData,
            BaseReferences<
              _$RemoriDatabase,
              $CachedPeopleTable,
              CachedPeopleData
            >,
          ),
          CachedPeopleData,
          PrefetchHooks Function()
        > {
  $$CachedPeopleTableTableManager(_$RemoriDatabase db, $CachedPeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> relationship = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> embeddingCount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPeopleCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                name: name,
                relationship: relationship,
                status: status,
                embeddingCount: embeddingCount,
                updatedAt: updatedAt,
                photoUrl: photoUrl,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String id,
                required String name,
                required String relationship,
                required String status,
                required int embeddingCount,
                required DateTime updatedAt,
                Value<String?> photoUrl = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => CachedPeopleCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                name: name,
                relationship: relationship,
                status: status,
                embeddingCount: embeddingCount,
                updatedAt: updatedAt,
                photoUrl: photoUrl,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedPeopleTable, CachedPeopleData>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedPeopleTable,
                    CachedPeopleData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedPeopleTable,
      CachedPeopleData,
      $$CachedPeopleTableFilterComposer,
      $$CachedPeopleTableOrderingComposer,
      $$CachedPeopleTableAnnotationComposer,
      $$CachedPeopleTableCreateCompanionBuilder,
      $$CachedPeopleTableUpdateCompanionBuilder,
      (
        CachedPeopleData,
        BaseReferences<_$RemoriDatabase, $CachedPeopleTable, CachedPeopleData>,
      ),
      CachedPeopleData,
      PrefetchHooks Function()
    >;
typedef $$PeopleCacheStatesTableCreateCompanionBuilder =
    PeopleCacheStatesCompanion Function({
      required String caregiverId,
      required String patientId,
      required int unknownCount,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$PeopleCacheStatesTableUpdateCompanionBuilder =
    PeopleCacheStatesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<int> unknownCount,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$PeopleCacheStatesTableFilterComposer
    extends Composer<_$RemoriDatabase, $PeopleCacheStatesTable> {
  $$PeopleCacheStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unknownCount => $composableBuilder(
    column: $table.unknownCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$PeopleCacheStatesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $PeopleCacheStatesTable> {
  $$PeopleCacheStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unknownCount => $composableBuilder(
    column: $table.unknownCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleCacheStatesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $PeopleCacheStatesTable> {
  $$PeopleCacheStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<int> get unknownCount => $composableBuilder(
    column: $table.unknownCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$PeopleCacheStatesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $PeopleCacheStatesTable,
          PeopleCacheState,
          $$PeopleCacheStatesTableFilterComposer,
          $$PeopleCacheStatesTableOrderingComposer,
          $$PeopleCacheStatesTableAnnotationComposer,
          $$PeopleCacheStatesTableCreateCompanionBuilder,
          $$PeopleCacheStatesTableUpdateCompanionBuilder,
          (
            PeopleCacheState,
            BaseReferences<
              _$RemoriDatabase,
              $PeopleCacheStatesTable,
              PeopleCacheState
            >,
          ),
          PeopleCacheState,
          PrefetchHooks Function()
        > {
  $$PeopleCacheStatesTableTableManager(
    _$RemoriDatabase db,
    $PeopleCacheStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleCacheStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleCacheStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleCacheStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<int> unknownCount = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCacheStatesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                unknownCount: unknownCount,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required int unknownCount,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => PeopleCacheStatesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                unknownCount: unknownCount,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeopleCacheStatesTable, PeopleCacheState>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $PeopleCacheStatesTable,
                    PeopleCacheState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeopleCacheStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $PeopleCacheStatesTable,
      PeopleCacheState,
      $$PeopleCacheStatesTableFilterComposer,
      $$PeopleCacheStatesTableOrderingComposer,
      $$PeopleCacheStatesTableAnnotationComposer,
      $$PeopleCacheStatesTableCreateCompanionBuilder,
      $$PeopleCacheStatesTableUpdateCompanionBuilder,
      (
        PeopleCacheState,
        BaseReferences<
          _$RemoriDatabase,
          $PeopleCacheStatesTable,
          PeopleCacheState
        >,
      ),
      PeopleCacheState,
      PrefetchHooks Function()
    >;
typedef $$PersonDetailStatesTableCreateCompanionBuilder =
    PersonDetailStatesCompanion Function({
      required String caregiverId,
      required String patientId,
      required String personId,
      Value<String?> enrolledByName,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$PersonDetailStatesTableUpdateCompanionBuilder =
    PersonDetailStatesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> personId,
      Value<String?> enrolledByName,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$PersonDetailStatesTableFilterComposer
    extends Composer<_$RemoriDatabase, $PersonDetailStatesTable> {
  $$PersonDetailStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enrolledByName => $composableBuilder(
    column: $table.enrolledByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$PersonDetailStatesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $PersonDetailStatesTable> {
  $$PersonDetailStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enrolledByName => $composableBuilder(
    column: $table.enrolledByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonDetailStatesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $PersonDetailStatesTable> {
  $$PersonDetailStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get enrolledByName => $composableBuilder(
    column: $table.enrolledByName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$PersonDetailStatesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $PersonDetailStatesTable,
          PersonDetailState,
          $$PersonDetailStatesTableFilterComposer,
          $$PersonDetailStatesTableOrderingComposer,
          $$PersonDetailStatesTableAnnotationComposer,
          $$PersonDetailStatesTableCreateCompanionBuilder,
          $$PersonDetailStatesTableUpdateCompanionBuilder,
          (
            PersonDetailState,
            BaseReferences<
              _$RemoriDatabase,
              $PersonDetailStatesTable,
              PersonDetailState
            >,
          ),
          PersonDetailState,
          PrefetchHooks Function()
        > {
  $$PersonDetailStatesTableTableManager(
    _$RemoriDatabase db,
    $PersonDetailStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonDetailStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonDetailStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonDetailStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String?> enrolledByName = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonDetailStatesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                personId: personId,
                enrolledByName: enrolledByName,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String personId,
                Value<String?> enrolledByName = const Value.absent(),
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => PersonDetailStatesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                personId: personId,
                enrolledByName: enrolledByName,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PersonDetailStatesTable, PersonDetailState>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $PersonDetailStatesTable,
                    PersonDetailState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonDetailStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $PersonDetailStatesTable,
      PersonDetailState,
      $$PersonDetailStatesTableFilterComposer,
      $$PersonDetailStatesTableOrderingComposer,
      $$PersonDetailStatesTableAnnotationComposer,
      $$PersonDetailStatesTableCreateCompanionBuilder,
      $$PersonDetailStatesTableUpdateCompanionBuilder,
      (
        PersonDetailState,
        BaseReferences<
          _$RemoriDatabase,
          $PersonDetailStatesTable,
          PersonDetailState
        >,
      ),
      PersonDetailState,
      PrefetchHooks Function()
    >;
typedef $$CachedPersonPhotosTableCreateCompanionBuilder =
    CachedPersonPhotosCompanion Function({
      required String caregiverId,
      required String patientId,
      required String personId,
      required String id,
      required String url,
      Value<String?> thumbnailUrl,
      required int position,
      Value<int> rowid,
    });
typedef $$CachedPersonPhotosTableUpdateCompanionBuilder =
    CachedPersonPhotosCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> personId,
      Value<String> id,
      Value<String> url,
      Value<String?> thumbnailUrl,
      Value<int> position,
      Value<int> rowid,
    });

class $$CachedPersonPhotosTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedPersonPhotosTable> {
  $$CachedPersonPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPersonPhotosTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedPersonPhotosTable> {
  $$CachedPersonPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPersonPhotosTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedPersonPhotosTable> {
  $$CachedPersonPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedPersonPhotosTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedPersonPhotosTable,
          CachedPersonPhoto,
          $$CachedPersonPhotosTableFilterComposer,
          $$CachedPersonPhotosTableOrderingComposer,
          $$CachedPersonPhotosTableAnnotationComposer,
          $$CachedPersonPhotosTableCreateCompanionBuilder,
          $$CachedPersonPhotosTableUpdateCompanionBuilder,
          (
            CachedPersonPhoto,
            BaseReferences<
              _$RemoriDatabase,
              $CachedPersonPhotosTable,
              CachedPersonPhoto
            >,
          ),
          CachedPersonPhoto,
          PrefetchHooks Function()
        > {
  $$CachedPersonPhotosTableTableManager(
    _$RemoriDatabase db,
    $CachedPersonPhotosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPersonPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPersonPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPersonPhotosTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPersonPhotosCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                personId: personId,
                id: id,
                url: url,
                thumbnailUrl: thumbnailUrl,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String personId,
                required String id,
                required String url,
                Value<String?> thumbnailUrl = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => CachedPersonPhotosCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                personId: personId,
                id: id,
                url: url,
                thumbnailUrl: thumbnailUrl,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedPersonPhotosTable, CachedPersonPhoto>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedPersonPhotosTable,
                    CachedPersonPhoto
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPersonPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedPersonPhotosTable,
      CachedPersonPhoto,
      $$CachedPersonPhotosTableFilterComposer,
      $$CachedPersonPhotosTableOrderingComposer,
      $$CachedPersonPhotosTableAnnotationComposer,
      $$CachedPersonPhotosTableCreateCompanionBuilder,
      $$CachedPersonPhotosTableUpdateCompanionBuilder,
      (
        CachedPersonPhoto,
        BaseReferences<
          _$RemoriDatabase,
          $CachedPersonPhotosTable,
          CachedPersonPhoto
        >,
      ),
      CachedPersonPhoto,
      PrefetchHooks Function()
    >;
typedef $$CachedRemindersTableCreateCompanionBuilder =
    CachedRemindersCompanion Function({
      required String caregiverId,
      required String patientId,
      required String id,
      required String title,
      Value<String?> spokenText,
      required String type,
      required String rrule,
      required DateTime dtstart,
      required String timezone,
      required bool active,
      required DateTime updatedAt,
      required int position,
      Value<int> rowid,
    });
typedef $$CachedRemindersTableUpdateCompanionBuilder =
    CachedRemindersCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> id,
      Value<String> title,
      Value<String?> spokenText,
      Value<String> type,
      Value<String> rrule,
      Value<DateTime> dtstart,
      Value<String> timezone,
      Value<bool> active,
      Value<DateTime> updatedAt,
      Value<int> position,
      Value<int> rowid,
    });

class $$CachedRemindersTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedRemindersTable> {
  $$CachedRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spokenText => $composableBuilder(
    column: $table.spokenText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get dtstart =>
      $composableBuilder(
        column: $table.dtstart,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRemindersTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedRemindersTable> {
  $$CachedRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spokenText => $composableBuilder(
    column: $table.spokenText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dtstart => $composableBuilder(
    column: $table.dtstart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRemindersTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedRemindersTable> {
  $$CachedRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get spokenText => $composableBuilder(
    column: $table.spokenText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get dtstart =>
      $composableBuilder(column: $table.dtstart, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedRemindersTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedRemindersTable,
          CachedReminder,
          $$CachedRemindersTableFilterComposer,
          $$CachedRemindersTableOrderingComposer,
          $$CachedRemindersTableAnnotationComposer,
          $$CachedRemindersTableCreateCompanionBuilder,
          $$CachedRemindersTableUpdateCompanionBuilder,
          (
            CachedReminder,
            BaseReferences<
              _$RemoriDatabase,
              $CachedRemindersTable,
              CachedReminder
            >,
          ),
          CachedReminder,
          PrefetchHooks Function()
        > {
  $$CachedRemindersTableTableManager(
    _$RemoriDatabase db,
    $CachedRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> spokenText = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> rrule = const Value.absent(),
                Value<DateTime> dtstart = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedRemindersCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                title: title,
                spokenText: spokenText,
                type: type,
                rrule: rrule,
                dtstart: dtstart,
                timezone: timezone,
                active: active,
                updatedAt: updatedAt,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String id,
                required String title,
                Value<String?> spokenText = const Value.absent(),
                required String type,
                required String rrule,
                required DateTime dtstart,
                required String timezone,
                required bool active,
                required DateTime updatedAt,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => CachedRemindersCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                title: title,
                spokenText: spokenText,
                type: type,
                rrule: rrule,
                dtstart: dtstart,
                timezone: timezone,
                active: active,
                updatedAt: updatedAt,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedRemindersTable, CachedReminder>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedRemindersTable,
                    CachedReminder
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedRemindersTable,
      CachedReminder,
      $$CachedRemindersTableFilterComposer,
      $$CachedRemindersTableOrderingComposer,
      $$CachedRemindersTableAnnotationComposer,
      $$CachedRemindersTableCreateCompanionBuilder,
      $$CachedRemindersTableUpdateCompanionBuilder,
      (
        CachedReminder,
        BaseReferences<_$RemoriDatabase, $CachedRemindersTable, CachedReminder>,
      ),
      CachedReminder,
      PrefetchHooks Function()
    >;
typedef $$CachedReminderOccurrencesTableCreateCompanionBuilder =
    CachedReminderOccurrencesCompanion Function({
      required String caregiverId,
      required String patientId,
      required String id,
      required String reminderId,
      required String day,
      required String title,
      required String type,
      required DateTime scheduledAt,
      required String status,
      Value<DateTime?> snoozedUntil,
      Value<DateTime?> completedAt,
      Value<String?> confirmedVia,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedReminderOccurrencesTableUpdateCompanionBuilder =
    CachedReminderOccurrencesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> id,
      Value<String> reminderId,
      Value<String> day,
      Value<String> title,
      Value<String> type,
      Value<DateTime> scheduledAt,
      Value<String> status,
      Value<DateTime?> snoozedUntil,
      Value<DateTime?> completedAt,
      Value<String?> confirmedVia,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedReminderOccurrencesTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedReminderOccurrencesTable> {
  $$CachedReminderOccurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get scheduledAt =>
      $composableBuilder(
        column: $table.scheduledAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
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

class $$CachedReminderOccurrencesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedReminderOccurrencesTable> {
  $$CachedReminderOccurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
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

class $$CachedReminderOccurrencesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedReminderOccurrencesTable> {
  $$CachedReminderOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get scheduledAt =>
      $composableBuilder(
        column: $table.scheduledAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get status =>
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

class $$CachedReminderOccurrencesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedReminderOccurrencesTable,
          CachedReminderOccurrence,
          $$CachedReminderOccurrencesTableFilterComposer,
          $$CachedReminderOccurrencesTableOrderingComposer,
          $$CachedReminderOccurrencesTableAnnotationComposer,
          $$CachedReminderOccurrencesTableCreateCompanionBuilder,
          $$CachedReminderOccurrencesTableUpdateCompanionBuilder,
          (
            CachedReminderOccurrence,
            BaseReferences<
              _$RemoriDatabase,
              $CachedReminderOccurrencesTable,
              CachedReminderOccurrence
            >,
          ),
          CachedReminderOccurrence,
          PrefetchHooks Function()
        > {
  $$CachedReminderOccurrencesTableTableManager(
    _$RemoriDatabase db,
    $CachedReminderOccurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedReminderOccurrencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedReminderOccurrencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedReminderOccurrencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> reminderId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> confirmedVia = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedReminderOccurrencesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                reminderId: reminderId,
                day: day,
                title: title,
                type: type,
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
                required String caregiverId,
                required String patientId,
                required String id,
                required String reminderId,
                required String day,
                required String title,
                required String type,
                required DateTime scheduledAt,
                required String status,
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> confirmedVia = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedReminderOccurrencesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                reminderId: reminderId,
                day: day,
                title: title,
                type: type,
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
                  e.readTable<
                    $CachedReminderOccurrencesTable,
                    CachedReminderOccurrence
                  >(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedReminderOccurrencesTable,
                    CachedReminderOccurrence
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedReminderOccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedReminderOccurrencesTable,
      CachedReminderOccurrence,
      $$CachedReminderOccurrencesTableFilterComposer,
      $$CachedReminderOccurrencesTableOrderingComposer,
      $$CachedReminderOccurrencesTableAnnotationComposer,
      $$CachedReminderOccurrencesTableCreateCompanionBuilder,
      $$CachedReminderOccurrencesTableUpdateCompanionBuilder,
      (
        CachedReminderOccurrence,
        BaseReferences<
          _$RemoriDatabase,
          $CachedReminderOccurrencesTable,
          CachedReminderOccurrence
        >,
      ),
      CachedReminderOccurrence,
      PrefetchHooks Function()
    >;
typedef $$ReminderCacheStatesTableCreateCompanionBuilder =
    ReminderCacheStatesCompanion Function({
      required String caregiverId,
      required String patientId,
      required String day,
      required String timezone,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$ReminderCacheStatesTableUpdateCompanionBuilder =
    ReminderCacheStatesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> day,
      Value<String> timezone,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$ReminderCacheStatesTableFilterComposer
    extends Composer<_$RemoriDatabase, $ReminderCacheStatesTable> {
  $$ReminderCacheStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ReminderCacheStatesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $ReminderCacheStatesTable> {
  $$ReminderCacheStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReminderCacheStatesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $ReminderCacheStatesTable> {
  $$ReminderCacheStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$ReminderCacheStatesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $ReminderCacheStatesTable,
          ReminderCacheState,
          $$ReminderCacheStatesTableFilterComposer,
          $$ReminderCacheStatesTableOrderingComposer,
          $$ReminderCacheStatesTableAnnotationComposer,
          $$ReminderCacheStatesTableCreateCompanionBuilder,
          $$ReminderCacheStatesTableUpdateCompanionBuilder,
          (
            ReminderCacheState,
            BaseReferences<
              _$RemoriDatabase,
              $ReminderCacheStatesTable,
              ReminderCacheState
            >,
          ),
          ReminderCacheState,
          PrefetchHooks Function()
        > {
  $$ReminderCacheStatesTableTableManager(
    _$RemoriDatabase db,
    $ReminderCacheStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderCacheStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderCacheStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReminderCacheStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderCacheStatesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                day: day,
                timezone: timezone,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String day,
                required String timezone,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReminderCacheStatesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                day: day,
                timezone: timezone,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReminderCacheStatesTable, ReminderCacheState>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $ReminderCacheStatesTable,
                    ReminderCacheState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReminderCacheStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $ReminderCacheStatesTable,
      ReminderCacheState,
      $$ReminderCacheStatesTableFilterComposer,
      $$ReminderCacheStatesTableOrderingComposer,
      $$ReminderCacheStatesTableAnnotationComposer,
      $$ReminderCacheStatesTableCreateCompanionBuilder,
      $$ReminderCacheStatesTableUpdateCompanionBuilder,
      (
        ReminderCacheState,
        BaseReferences<
          _$RemoriDatabase,
          $ReminderCacheStatesTable,
          ReminderCacheState
        >,
      ),
      ReminderCacheState,
      PrefetchHooks Function()
    >;
typedef $$CachedUnknownFacesTableCreateCompanionBuilder =
    CachedUnknownFacesCompanion Function({
      required String caregiverId,
      required String patientId,
      required String id,
      required int sightingCount,
      required int distinctDays,
      required DateTime firstSeenAt,
      required DateTime lastSeenAt,
      Value<String?> sampleId,
      Value<String?> sampleUrl,
      Value<String?> thumbnailUrl,
      Value<int> rowid,
    });
typedef $$CachedUnknownFacesTableUpdateCompanionBuilder =
    CachedUnknownFacesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> id,
      Value<int> sightingCount,
      Value<int> distinctDays,
      Value<DateTime> firstSeenAt,
      Value<DateTime> lastSeenAt,
      Value<String?> sampleId,
      Value<String?> sampleUrl,
      Value<String?> thumbnailUrl,
      Value<int> rowid,
    });

class $$CachedUnknownFacesTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedUnknownFacesTable> {
  $$CachedUnknownFacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sightingCount => $composableBuilder(
    column: $table.sightingCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distinctDays => $composableBuilder(
    column: $table.distinctDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get firstSeenAt =>
      $composableBuilder(
        column: $table.firstSeenAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get lastSeenAt =>
      $composableBuilder(
        column: $table.lastSeenAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get sampleId => $composableBuilder(
    column: $table.sampleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sampleUrl => $composableBuilder(
    column: $table.sampleUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedUnknownFacesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedUnknownFacesTable> {
  $$CachedUnknownFacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sightingCount => $composableBuilder(
    column: $table.sightingCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distinctDays => $composableBuilder(
    column: $table.distinctDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sampleId => $composableBuilder(
    column: $table.sampleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sampleUrl => $composableBuilder(
    column: $table.sampleUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedUnknownFacesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedUnknownFacesTable> {
  $$CachedUnknownFacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sightingCount => $composableBuilder(
    column: $table.sightingCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get distinctDays => $composableBuilder(
    column: $table.distinctDays,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get firstSeenAt =>
      $composableBuilder(
        column: $table.firstSeenAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get lastSeenAt =>
      $composableBuilder(
        column: $table.lastSeenAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get sampleId =>
      $composableBuilder(column: $table.sampleId, builder: (column) => column);

  GeneratedColumn<String> get sampleUrl =>
      $composableBuilder(column: $table.sampleUrl, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );
}

class $$CachedUnknownFacesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedUnknownFacesTable,
          CachedUnknownFace,
          $$CachedUnknownFacesTableFilterComposer,
          $$CachedUnknownFacesTableOrderingComposer,
          $$CachedUnknownFacesTableAnnotationComposer,
          $$CachedUnknownFacesTableCreateCompanionBuilder,
          $$CachedUnknownFacesTableUpdateCompanionBuilder,
          (
            CachedUnknownFace,
            BaseReferences<
              _$RemoriDatabase,
              $CachedUnknownFacesTable,
              CachedUnknownFace
            >,
          ),
          CachedUnknownFace,
          PrefetchHooks Function()
        > {
  $$CachedUnknownFacesTableTableManager(
    _$RemoriDatabase db,
    $CachedUnknownFacesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedUnknownFacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedUnknownFacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedUnknownFacesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<int> sightingCount = const Value.absent(),
                Value<int> distinctDays = const Value.absent(),
                Value<DateTime> firstSeenAt = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<String?> sampleId = const Value.absent(),
                Value<String?> sampleUrl = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedUnknownFacesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                sightingCount: sightingCount,
                distinctDays: distinctDays,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                sampleId: sampleId,
                sampleUrl: sampleUrl,
                thumbnailUrl: thumbnailUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String id,
                required int sightingCount,
                required int distinctDays,
                required DateTime firstSeenAt,
                required DateTime lastSeenAt,
                Value<String?> sampleId = const Value.absent(),
                Value<String?> sampleUrl = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedUnknownFacesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                sightingCount: sightingCount,
                distinctDays: distinctDays,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                sampleId: sampleId,
                sampleUrl: sampleUrl,
                thumbnailUrl: thumbnailUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedUnknownFacesTable, CachedUnknownFace>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedUnknownFacesTable,
                    CachedUnknownFace
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedUnknownFacesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedUnknownFacesTable,
      CachedUnknownFace,
      $$CachedUnknownFacesTableFilterComposer,
      $$CachedUnknownFacesTableOrderingComposer,
      $$CachedUnknownFacesTableAnnotationComposer,
      $$CachedUnknownFacesTableCreateCompanionBuilder,
      $$CachedUnknownFacesTableUpdateCompanionBuilder,
      (
        CachedUnknownFace,
        BaseReferences<
          _$RemoriDatabase,
          $CachedUnknownFacesTable,
          CachedUnknownFace
        >,
      ),
      CachedUnknownFace,
      PrefetchHooks Function()
    >;
typedef $$UnknownFacesCacheStatesTableCreateCompanionBuilder =
    UnknownFacesCacheStatesCompanion Function({
      required String caregiverId,
      required String patientId,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$UnknownFacesCacheStatesTableUpdateCompanionBuilder =
    UnknownFacesCacheStatesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$UnknownFacesCacheStatesTableFilterComposer
    extends Composer<_$RemoriDatabase, $UnknownFacesCacheStatesTable> {
  $$UnknownFacesCacheStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$UnknownFacesCacheStatesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $UnknownFacesCacheStatesTable> {
  $$UnknownFacesCacheStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnknownFacesCacheStatesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $UnknownFacesCacheStatesTable> {
  $$UnknownFacesCacheStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$UnknownFacesCacheStatesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $UnknownFacesCacheStatesTable,
          UnknownFacesCacheState,
          $$UnknownFacesCacheStatesTableFilterComposer,
          $$UnknownFacesCacheStatesTableOrderingComposer,
          $$UnknownFacesCacheStatesTableAnnotationComposer,
          $$UnknownFacesCacheStatesTableCreateCompanionBuilder,
          $$UnknownFacesCacheStatesTableUpdateCompanionBuilder,
          (
            UnknownFacesCacheState,
            BaseReferences<
              _$RemoriDatabase,
              $UnknownFacesCacheStatesTable,
              UnknownFacesCacheState
            >,
          ),
          UnknownFacesCacheState,
          PrefetchHooks Function()
        > {
  $$UnknownFacesCacheStatesTableTableManager(
    _$RemoriDatabase db,
    $UnknownFacesCacheStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnknownFacesCacheStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UnknownFacesCacheStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UnknownFacesCacheStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnknownFacesCacheStatesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => UnknownFacesCacheStatesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $UnknownFacesCacheStatesTable,
                    UnknownFacesCacheState
                  >(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $UnknownFacesCacheStatesTable,
                    UnknownFacesCacheState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnknownFacesCacheStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $UnknownFacesCacheStatesTable,
      UnknownFacesCacheState,
      $$UnknownFacesCacheStatesTableFilterComposer,
      $$UnknownFacesCacheStatesTableOrderingComposer,
      $$UnknownFacesCacheStatesTableAnnotationComposer,
      $$UnknownFacesCacheStatesTableCreateCompanionBuilder,
      $$UnknownFacesCacheStatesTableUpdateCompanionBuilder,
      (
        UnknownFacesCacheState,
        BaseReferences<
          _$RemoriDatabase,
          $UnknownFacesCacheStatesTable,
          UnknownFacesCacheState
        >,
      ),
      UnknownFacesCacheState,
      PrefetchHooks Function()
    >;
typedef $$CachedUnknownFaceSamplesTableCreateCompanionBuilder =
    CachedUnknownFaceSamplesCompanion Function({
      required String caregiverId,
      required String patientId,
      required String clusterId,
      required String id,
      required String url,
      Value<String?> thumbnailUrl,
      required int position,
      Value<int> rowid,
    });
typedef $$CachedUnknownFaceSamplesTableUpdateCompanionBuilder =
    CachedUnknownFaceSamplesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> clusterId,
      Value<String> id,
      Value<String> url,
      Value<String?> thumbnailUrl,
      Value<int> position,
      Value<int> rowid,
    });

class $$CachedUnknownFaceSamplesTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedUnknownFaceSamplesTable> {
  $$CachedUnknownFaceSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedUnknownFaceSamplesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedUnknownFaceSamplesTable> {
  $$CachedUnknownFaceSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedUnknownFaceSamplesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedUnknownFaceSamplesTable> {
  $$CachedUnknownFaceSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get clusterId =>
      $composableBuilder(column: $table.clusterId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedUnknownFaceSamplesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedUnknownFaceSamplesTable,
          CachedUnknownFaceSample,
          $$CachedUnknownFaceSamplesTableFilterComposer,
          $$CachedUnknownFaceSamplesTableOrderingComposer,
          $$CachedUnknownFaceSamplesTableAnnotationComposer,
          $$CachedUnknownFaceSamplesTableCreateCompanionBuilder,
          $$CachedUnknownFaceSamplesTableUpdateCompanionBuilder,
          (
            CachedUnknownFaceSample,
            BaseReferences<
              _$RemoriDatabase,
              $CachedUnknownFaceSamplesTable,
              CachedUnknownFaceSample
            >,
          ),
          CachedUnknownFaceSample,
          PrefetchHooks Function()
        > {
  $$CachedUnknownFaceSamplesTableTableManager(
    _$RemoriDatabase db,
    $CachedUnknownFaceSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedUnknownFaceSamplesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedUnknownFaceSamplesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedUnknownFaceSamplesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> clusterId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedUnknownFaceSamplesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                clusterId: clusterId,
                id: id,
                url: url,
                thumbnailUrl: thumbnailUrl,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String clusterId,
                required String id,
                required String url,
                Value<String?> thumbnailUrl = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => CachedUnknownFaceSamplesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                clusterId: clusterId,
                id: id,
                url: url,
                thumbnailUrl: thumbnailUrl,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CachedUnknownFaceSamplesTable,
                    CachedUnknownFaceSample
                  >(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedUnknownFaceSamplesTable,
                    CachedUnknownFaceSample
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedUnknownFaceSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedUnknownFaceSamplesTable,
      CachedUnknownFaceSample,
      $$CachedUnknownFaceSamplesTableFilterComposer,
      $$CachedUnknownFaceSamplesTableOrderingComposer,
      $$CachedUnknownFaceSamplesTableAnnotationComposer,
      $$CachedUnknownFaceSamplesTableCreateCompanionBuilder,
      $$CachedUnknownFaceSamplesTableUpdateCompanionBuilder,
      (
        CachedUnknownFaceSample,
        BaseReferences<
          _$RemoriDatabase,
          $CachedUnknownFaceSamplesTable,
          CachedUnknownFaceSample
        >,
      ),
      CachedUnknownFaceSample,
      PrefetchHooks Function()
    >;
typedef $$CachedPlacesTableCreateCompanionBuilder =
    CachedPlacesCompanion Function({
      required String caregiverId,
      required String patientId,
      required String id,
      required String name,
      required double latitude,
      required double longitude,
      required int radiusM,
      required String createdBy,
      required DateTime updatedAt,
      required int position,
      Value<int> rowid,
    });
typedef $$CachedPlacesTableUpdateCompanionBuilder =
    CachedPlacesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> id,
      Value<String> name,
      Value<double> latitude,
      Value<double> longitude,
      Value<int> radiusM,
      Value<String> createdBy,
      Value<DateTime> updatedAt,
      Value<int> position,
      Value<int> rowid,
    });

class $$CachedPlacesTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedPlacesTable> {
  $$CachedPlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPlacesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedPlacesTable> {
  $$CachedPlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPlacesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedPlacesTable> {
  $$CachedPlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get radiusM =>
      $composableBuilder(column: $table.radiusM, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedPlacesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedPlacesTable,
          CachedPlace,
          $$CachedPlacesTableFilterComposer,
          $$CachedPlacesTableOrderingComposer,
          $$CachedPlacesTableAnnotationComposer,
          $$CachedPlacesTableCreateCompanionBuilder,
          $$CachedPlacesTableUpdateCompanionBuilder,
          (
            CachedPlace,
            BaseReferences<_$RemoriDatabase, $CachedPlacesTable, CachedPlace>,
          ),
          CachedPlace,
          PrefetchHooks Function()
        > {
  $$CachedPlacesTableTableManager(_$RemoriDatabase db, $CachedPlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<int> radiusM = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPlacesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                radiusM: radiusM,
                createdBy: createdBy,
                updatedAt: updatedAt,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String id,
                required String name,
                required double latitude,
                required double longitude,
                required int radiusM,
                required String createdBy,
                required DateTime updatedAt,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => CachedPlacesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                radiusM: radiusM,
                createdBy: createdBy,
                updatedAt: updatedAt,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedPlacesTable, CachedPlace>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedPlacesTable,
                    CachedPlace
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedPlacesTable,
      CachedPlace,
      $$CachedPlacesTableFilterComposer,
      $$CachedPlacesTableOrderingComposer,
      $$CachedPlacesTableAnnotationComposer,
      $$CachedPlacesTableCreateCompanionBuilder,
      $$CachedPlacesTableUpdateCompanionBuilder,
      (
        CachedPlace,
        BaseReferences<_$RemoriDatabase, $CachedPlacesTable, CachedPlace>,
      ),
      CachedPlace,
      PrefetchHooks Function()
    >;
typedef $$PlacesCacheStatesTableCreateCompanionBuilder =
    PlacesCacheStatesCompanion Function({
      required String caregiverId,
      required String patientId,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$PlacesCacheStatesTableUpdateCompanionBuilder =
    PlacesCacheStatesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$PlacesCacheStatesTableFilterComposer
    extends Composer<_$RemoriDatabase, $PlacesCacheStatesTable> {
  $$PlacesCacheStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$PlacesCacheStatesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $PlacesCacheStatesTable> {
  $$PlacesCacheStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlacesCacheStatesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $PlacesCacheStatesTable> {
  $$PlacesCacheStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$PlacesCacheStatesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $PlacesCacheStatesTable,
          PlacesCacheState,
          $$PlacesCacheStatesTableFilterComposer,
          $$PlacesCacheStatesTableOrderingComposer,
          $$PlacesCacheStatesTableAnnotationComposer,
          $$PlacesCacheStatesTableCreateCompanionBuilder,
          $$PlacesCacheStatesTableUpdateCompanionBuilder,
          (
            PlacesCacheState,
            BaseReferences<
              _$RemoriDatabase,
              $PlacesCacheStatesTable,
              PlacesCacheState
            >,
          ),
          PlacesCacheState,
          PrefetchHooks Function()
        > {
  $$PlacesCacheStatesTableTableManager(
    _$RemoriDatabase db,
    $PlacesCacheStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacesCacheStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacesCacheStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacesCacheStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacesCacheStatesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlacesCacheStatesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlacesCacheStatesTable, PlacesCacheState>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $PlacesCacheStatesTable,
                    PlacesCacheState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlacesCacheStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $PlacesCacheStatesTable,
      PlacesCacheState,
      $$PlacesCacheStatesTableFilterComposer,
      $$PlacesCacheStatesTableOrderingComposer,
      $$PlacesCacheStatesTableAnnotationComposer,
      $$PlacesCacheStatesTableCreateCompanionBuilder,
      $$PlacesCacheStatesTableUpdateCompanionBuilder,
      (
        PlacesCacheState,
        BaseReferences<
          _$RemoriDatabase,
          $PlacesCacheStatesTable,
          PlacesCacheState
        >,
      ),
      PlacesCacheState,
      PrefetchHooks Function()
    >;
typedef $$CachedJournalEntriesTableCreateCompanionBuilder =
    CachedJournalEntriesCompanion Function({
      required String caregiverId,
      required String patientId,
      required String day,
      required String id,
      required DateTime occurredAt,
      required String payload,
      Value<int> rowid,
    });
typedef $$CachedJournalEntriesTableUpdateCompanionBuilder =
    CachedJournalEntriesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> day,
      Value<String> id,
      Value<DateTime> occurredAt,
      Value<String> payload,
      Value<int> rowid,
    });

class $$CachedJournalEntriesTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedJournalEntriesTable> {
  $$CachedJournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedJournalEntriesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedJournalEntriesTable> {
  $$CachedJournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedJournalEntriesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedJournalEntriesTable> {
  $$CachedJournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$CachedJournalEntriesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedJournalEntriesTable,
          CachedJournalEntry,
          $$CachedJournalEntriesTableFilterComposer,
          $$CachedJournalEntriesTableOrderingComposer,
          $$CachedJournalEntriesTableAnnotationComposer,
          $$CachedJournalEntriesTableCreateCompanionBuilder,
          $$CachedJournalEntriesTableUpdateCompanionBuilder,
          (
            CachedJournalEntry,
            BaseReferences<
              _$RemoriDatabase,
              $CachedJournalEntriesTable,
              CachedJournalEntry
            >,
          ),
          CachedJournalEntry,
          PrefetchHooks Function()
        > {
  $$CachedJournalEntriesTableTableManager(
    _$RemoriDatabase db,
    $CachedJournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedJournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedJournalEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedJournalEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedJournalEntriesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                day: day,
                id: id,
                occurredAt: occurredAt,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String day,
                required String id,
                required DateTime occurredAt,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => CachedJournalEntriesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                day: day,
                id: id,
                occurredAt: occurredAt,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedJournalEntriesTable, CachedJournalEntry>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedJournalEntriesTable,
                    CachedJournalEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedJournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedJournalEntriesTable,
      CachedJournalEntry,
      $$CachedJournalEntriesTableFilterComposer,
      $$CachedJournalEntriesTableOrderingComposer,
      $$CachedJournalEntriesTableAnnotationComposer,
      $$CachedJournalEntriesTableCreateCompanionBuilder,
      $$CachedJournalEntriesTableUpdateCompanionBuilder,
      (
        CachedJournalEntry,
        BaseReferences<
          _$RemoriDatabase,
          $CachedJournalEntriesTable,
          CachedJournalEntry
        >,
      ),
      CachedJournalEntry,
      PrefetchHooks Function()
    >;
typedef $$CachedJournalMediaTableCreateCompanionBuilder =
    CachedJournalMediaCompanion Function({
      required String caregiverId,
      required String patientId,
      required String day,
      required String id,
      required String eventId,
      required String payload,
      required int position,
      Value<int> rowid,
    });
typedef $$CachedJournalMediaTableUpdateCompanionBuilder =
    CachedJournalMediaCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> day,
      Value<String> id,
      Value<String> eventId,
      Value<String> payload,
      Value<int> position,
      Value<int> rowid,
    });

class $$CachedJournalMediaTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedJournalMediaTable> {
  $$CachedJournalMediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedJournalMediaTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedJournalMediaTable> {
  $$CachedJournalMediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedJournalMediaTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedJournalMediaTable> {
  $$CachedJournalMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedJournalMediaTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedJournalMediaTable,
          CachedJournalMediaData,
          $$CachedJournalMediaTableFilterComposer,
          $$CachedJournalMediaTableOrderingComposer,
          $$CachedJournalMediaTableAnnotationComposer,
          $$CachedJournalMediaTableCreateCompanionBuilder,
          $$CachedJournalMediaTableUpdateCompanionBuilder,
          (
            CachedJournalMediaData,
            BaseReferences<
              _$RemoriDatabase,
              $CachedJournalMediaTable,
              CachedJournalMediaData
            >,
          ),
          CachedJournalMediaData,
          PrefetchHooks Function()
        > {
  $$CachedJournalMediaTableTableManager(
    _$RemoriDatabase db,
    $CachedJournalMediaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedJournalMediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedJournalMediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedJournalMediaTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedJournalMediaCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                day: day,
                id: id,
                eventId: eventId,
                payload: payload,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String day,
                required String id,
                required String eventId,
                required String payload,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => CachedJournalMediaCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                day: day,
                id: id,
                eventId: eventId,
                payload: payload,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedJournalMediaTable, CachedJournalMediaData>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedJournalMediaTable,
                    CachedJournalMediaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedJournalMediaTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedJournalMediaTable,
      CachedJournalMediaData,
      $$CachedJournalMediaTableFilterComposer,
      $$CachedJournalMediaTableOrderingComposer,
      $$CachedJournalMediaTableAnnotationComposer,
      $$CachedJournalMediaTableCreateCompanionBuilder,
      $$CachedJournalMediaTableUpdateCompanionBuilder,
      (
        CachedJournalMediaData,
        BaseReferences<
          _$RemoriDatabase,
          $CachedJournalMediaTable,
          CachedJournalMediaData
        >,
      ),
      CachedJournalMediaData,
      PrefetchHooks Function()
    >;
typedef $$JournalCacheStatesTableCreateCompanionBuilder =
    JournalCacheStatesCompanion Function({
      required String caregiverId,
      required String patientId,
      required String day,
      required String timezone,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$JournalCacheStatesTableUpdateCompanionBuilder =
    JournalCacheStatesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> day,
      Value<String> timezone,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$JournalCacheStatesTableFilterComposer
    extends Composer<_$RemoriDatabase, $JournalCacheStatesTable> {
  $$JournalCacheStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$JournalCacheStatesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $JournalCacheStatesTable> {
  $$JournalCacheStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalCacheStatesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $JournalCacheStatesTable> {
  $$JournalCacheStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$JournalCacheStatesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $JournalCacheStatesTable,
          JournalCacheState,
          $$JournalCacheStatesTableFilterComposer,
          $$JournalCacheStatesTableOrderingComposer,
          $$JournalCacheStatesTableAnnotationComposer,
          $$JournalCacheStatesTableCreateCompanionBuilder,
          $$JournalCacheStatesTableUpdateCompanionBuilder,
          (
            JournalCacheState,
            BaseReferences<
              _$RemoriDatabase,
              $JournalCacheStatesTable,
              JournalCacheState
            >,
          ),
          JournalCacheState,
          PrefetchHooks Function()
        > {
  $$JournalCacheStatesTableTableManager(
    _$RemoriDatabase db,
    $JournalCacheStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalCacheStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalCacheStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalCacheStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalCacheStatesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                day: day,
                timezone: timezone,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String day,
                required String timezone,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => JournalCacheStatesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                day: day,
                timezone: timezone,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JournalCacheStatesTable, JournalCacheState>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $JournalCacheStatesTable,
                    JournalCacheState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalCacheStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $JournalCacheStatesTable,
      JournalCacheState,
      $$JournalCacheStatesTableFilterComposer,
      $$JournalCacheStatesTableOrderingComposer,
      $$JournalCacheStatesTableAnnotationComposer,
      $$JournalCacheStatesTableCreateCompanionBuilder,
      $$JournalCacheStatesTableUpdateCompanionBuilder,
      (
        JournalCacheState,
        BaseReferences<
          _$RemoriDatabase,
          $JournalCacheStatesTable,
          JournalCacheState
        >,
      ),
      JournalCacheState,
      PrefetchHooks Function()
    >;
typedef $$CachedMediaDetailsTableCreateCompanionBuilder =
    CachedMediaDetailsCompanion Function({
      required String caregiverId,
      required String patientId,
      required String id,
      required String payload,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$CachedMediaDetailsTableUpdateCompanionBuilder =
    CachedMediaDetailsCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> id,
      Value<String> payload,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$CachedMediaDetailsTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedMediaDetailsTable> {
  $$CachedMediaDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$CachedMediaDetailsTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedMediaDetailsTable> {
  $$CachedMediaDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMediaDetailsTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedMediaDetailsTable> {
  $$CachedMediaDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$CachedMediaDetailsTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedMediaDetailsTable,
          CachedMediaDetail,
          $$CachedMediaDetailsTableFilterComposer,
          $$CachedMediaDetailsTableOrderingComposer,
          $$CachedMediaDetailsTableAnnotationComposer,
          $$CachedMediaDetailsTableCreateCompanionBuilder,
          $$CachedMediaDetailsTableUpdateCompanionBuilder,
          (
            CachedMediaDetail,
            BaseReferences<
              _$RemoriDatabase,
              $CachedMediaDetailsTable,
              CachedMediaDetail
            >,
          ),
          CachedMediaDetail,
          PrefetchHooks Function()
        > {
  $$CachedMediaDetailsTableTableManager(
    _$RemoriDatabase db,
    $CachedMediaDetailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMediaDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMediaDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMediaDetailsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMediaDetailsCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                payload: payload,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String id,
                required String payload,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMediaDetailsCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                payload: payload,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedMediaDetailsTable, CachedMediaDetail>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedMediaDetailsTable,
                    CachedMediaDetail
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMediaDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedMediaDetailsTable,
      CachedMediaDetail,
      $$CachedMediaDetailsTableFilterComposer,
      $$CachedMediaDetailsTableOrderingComposer,
      $$CachedMediaDetailsTableAnnotationComposer,
      $$CachedMediaDetailsTableCreateCompanionBuilder,
      $$CachedMediaDetailsTableUpdateCompanionBuilder,
      (
        CachedMediaDetail,
        BaseReferences<
          _$RemoriDatabase,
          $CachedMediaDetailsTable,
          CachedMediaDetail
        >,
      ),
      CachedMediaDetail,
      PrefetchHooks Function()
    >;
typedef $$CachedDocumentsTableCreateCompanionBuilder =
    CachedDocumentsCompanion Function({
      required String caregiverId,
      required String patientId,
      required String filter,
      required String id,
      required String eventId,
      required String mediaAssetId,
      required String documentType,
      Value<String?> title,
      Value<String?> headline,
      required DateTime capturedAt,
      Value<String?> url,
      Value<String?> thumbnailUrl,
      required DateTime previewUntil,
      required int position,
      Value<int> rowid,
    });
typedef $$CachedDocumentsTableUpdateCompanionBuilder =
    CachedDocumentsCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> filter,
      Value<String> id,
      Value<String> eventId,
      Value<String> mediaAssetId,
      Value<String> documentType,
      Value<String?> title,
      Value<String?> headline,
      Value<DateTime> capturedAt,
      Value<String?> url,
      Value<String?> thumbnailUrl,
      Value<DateTime> previewUntil,
      Value<int> position,
      Value<int> rowid,
    });

class $$CachedDocumentsTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaAssetId => $composableBuilder(
    column: $table.mediaAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headline => $composableBuilder(
    column: $table.headline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get capturedAt =>
      $composableBuilder(
        column: $table.capturedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get previewUntil =>
      $composableBuilder(
        column: $table.previewUntil,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDocumentsTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaAssetId => $composableBuilder(
    column: $table.mediaAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headline => $composableBuilder(
    column: $table.headline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get previewUntil => $composableBuilder(
    column: $table.previewUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDocumentsTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get filter =>
      $composableBuilder(column: $table.filter, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get mediaAssetId => $composableBuilder(
    column: $table.mediaAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get headline =>
      $composableBuilder(column: $table.headline, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get capturedAt =>
      $composableBuilder(
        column: $table.capturedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get previewUntil =>
      $composableBuilder(
        column: $table.previewUntil,
        builder: (column) => column,
      );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedDocumentsTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedDocumentsTable,
          CachedDocument,
          $$CachedDocumentsTableFilterComposer,
          $$CachedDocumentsTableOrderingComposer,
          $$CachedDocumentsTableAnnotationComposer,
          $$CachedDocumentsTableCreateCompanionBuilder,
          $$CachedDocumentsTableUpdateCompanionBuilder,
          (
            CachedDocument,
            BaseReferences<
              _$RemoriDatabase,
              $CachedDocumentsTable,
              CachedDocument
            >,
          ),
          CachedDocument,
          PrefetchHooks Function()
        > {
  $$CachedDocumentsTableTableManager(
    _$RemoriDatabase db,
    $CachedDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> filter = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> mediaAssetId = const Value.absent(),
                Value<String> documentType = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> headline = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<DateTime> previewUntil = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDocumentsCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                filter: filter,
                id: id,
                eventId: eventId,
                mediaAssetId: mediaAssetId,
                documentType: documentType,
                title: title,
                headline: headline,
                capturedAt: capturedAt,
                url: url,
                thumbnailUrl: thumbnailUrl,
                previewUntil: previewUntil,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String filter,
                required String id,
                required String eventId,
                required String mediaAssetId,
                required String documentType,
                Value<String?> title = const Value.absent(),
                Value<String?> headline = const Value.absent(),
                required DateTime capturedAt,
                Value<String?> url = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                required DateTime previewUntil,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => CachedDocumentsCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                filter: filter,
                id: id,
                eventId: eventId,
                mediaAssetId: mediaAssetId,
                documentType: documentType,
                title: title,
                headline: headline,
                capturedAt: capturedAt,
                url: url,
                thumbnailUrl: thumbnailUrl,
                previewUntil: previewUntil,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedDocumentsTable, CachedDocument>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedDocumentsTable,
                    CachedDocument
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedDocumentsTable,
      CachedDocument,
      $$CachedDocumentsTableFilterComposer,
      $$CachedDocumentsTableOrderingComposer,
      $$CachedDocumentsTableAnnotationComposer,
      $$CachedDocumentsTableCreateCompanionBuilder,
      $$CachedDocumentsTableUpdateCompanionBuilder,
      (
        CachedDocument,
        BaseReferences<_$RemoriDatabase, $CachedDocumentsTable, CachedDocument>,
      ),
      CachedDocument,
      PrefetchHooks Function()
    >;
typedef $$DocumentsCacheStatesTableCreateCompanionBuilder =
    DocumentsCacheStatesCompanion Function({
      required String caregiverId,
      required String patientId,
      required String filter,
      required int nextOffset,
      required bool hasMore,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$DocumentsCacheStatesTableUpdateCompanionBuilder =
    DocumentsCacheStatesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> filter,
      Value<int> nextOffset,
      Value<bool> hasMore,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$DocumentsCacheStatesTableFilterComposer
    extends Composer<_$RemoriDatabase, $DocumentsCacheStatesTable> {
  $$DocumentsCacheStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextOffset => $composableBuilder(
    column: $table.nextOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasMore => $composableBuilder(
    column: $table.hasMore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$DocumentsCacheStatesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $DocumentsCacheStatesTable> {
  $$DocumentsCacheStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextOffset => $composableBuilder(
    column: $table.nextOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasMore => $composableBuilder(
    column: $table.hasMore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsCacheStatesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $DocumentsCacheStatesTable> {
  $$DocumentsCacheStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get filter =>
      $composableBuilder(column: $table.filter, builder: (column) => column);

  GeneratedColumn<int> get nextOffset => $composableBuilder(
    column: $table.nextOffset,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasMore =>
      $composableBuilder(column: $table.hasMore, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$DocumentsCacheStatesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $DocumentsCacheStatesTable,
          DocumentsCacheState,
          $$DocumentsCacheStatesTableFilterComposer,
          $$DocumentsCacheStatesTableOrderingComposer,
          $$DocumentsCacheStatesTableAnnotationComposer,
          $$DocumentsCacheStatesTableCreateCompanionBuilder,
          $$DocumentsCacheStatesTableUpdateCompanionBuilder,
          (
            DocumentsCacheState,
            BaseReferences<
              _$RemoriDatabase,
              $DocumentsCacheStatesTable,
              DocumentsCacheState
            >,
          ),
          DocumentsCacheState,
          PrefetchHooks Function()
        > {
  $$DocumentsCacheStatesTableTableManager(
    _$RemoriDatabase db,
    $DocumentsCacheStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsCacheStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsCacheStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DocumentsCacheStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> filter = const Value.absent(),
                Value<int> nextOffset = const Value.absent(),
                Value<bool> hasMore = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCacheStatesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                filter: filter,
                nextOffset: nextOffset,
                hasMore: hasMore,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String filter,
                required int nextOffset,
                required bool hasMore,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCacheStatesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                filter: filter,
                nextOffset: nextOffset,
                hasMore: hasMore,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentsCacheStatesTable, DocumentsCacheState>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $DocumentsCacheStatesTable,
                    DocumentsCacheState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentsCacheStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $DocumentsCacheStatesTable,
      DocumentsCacheState,
      $$DocumentsCacheStatesTableFilterComposer,
      $$DocumentsCacheStatesTableOrderingComposer,
      $$DocumentsCacheStatesTableAnnotationComposer,
      $$DocumentsCacheStatesTableCreateCompanionBuilder,
      $$DocumentsCacheStatesTableUpdateCompanionBuilder,
      (
        DocumentsCacheState,
        BaseReferences<
          _$RemoriDatabase,
          $DocumentsCacheStatesTable,
          DocumentsCacheState
        >,
      ),
      DocumentsCacheState,
      PrefetchHooks Function()
    >;
typedef $$CachedDocumentDetailsTableCreateCompanionBuilder =
    CachedDocumentDetailsCompanion Function({
      required String caregiverId,
      required String patientId,
      required String id,
      required String mediaAssetId,
      required String payload,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$CachedDocumentDetailsTableUpdateCompanionBuilder =
    CachedDocumentDetailsCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> id,
      Value<String> mediaAssetId,
      Value<String> payload,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$CachedDocumentDetailsTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedDocumentDetailsTable> {
  $$CachedDocumentDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaAssetId => $composableBuilder(
    column: $table.mediaAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$CachedDocumentDetailsTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedDocumentDetailsTable> {
  $$CachedDocumentDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaAssetId => $composableBuilder(
    column: $table.mediaAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDocumentDetailsTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedDocumentDetailsTable> {
  $$CachedDocumentDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaAssetId => $composableBuilder(
    column: $table.mediaAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$CachedDocumentDetailsTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedDocumentDetailsTable,
          CachedDocumentDetail,
          $$CachedDocumentDetailsTableFilterComposer,
          $$CachedDocumentDetailsTableOrderingComposer,
          $$CachedDocumentDetailsTableAnnotationComposer,
          $$CachedDocumentDetailsTableCreateCompanionBuilder,
          $$CachedDocumentDetailsTableUpdateCompanionBuilder,
          (
            CachedDocumentDetail,
            BaseReferences<
              _$RemoriDatabase,
              $CachedDocumentDetailsTable,
              CachedDocumentDetail
            >,
          ),
          CachedDocumentDetail,
          PrefetchHooks Function()
        > {
  $$CachedDocumentDetailsTableTableManager(
    _$RemoriDatabase db,
    $CachedDocumentDetailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDocumentDetailsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedDocumentDetailsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedDocumentDetailsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> mediaAssetId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDocumentDetailsCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                mediaAssetId: mediaAssetId,
                payload: payload,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String id,
                required String mediaAssetId,
                required String payload,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedDocumentDetailsCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                mediaAssetId: mediaAssetId,
                payload: payload,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CachedDocumentDetailsTable,
                    CachedDocumentDetail
                  >(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedDocumentDetailsTable,
                    CachedDocumentDetail
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDocumentDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedDocumentDetailsTable,
      CachedDocumentDetail,
      $$CachedDocumentDetailsTableFilterComposer,
      $$CachedDocumentDetailsTableOrderingComposer,
      $$CachedDocumentDetailsTableAnnotationComposer,
      $$CachedDocumentDetailsTableCreateCompanionBuilder,
      $$CachedDocumentDetailsTableUpdateCompanionBuilder,
      (
        CachedDocumentDetail,
        BaseReferences<
          _$RemoriDatabase,
          $CachedDocumentDetailsTable,
          CachedDocumentDetail
        >,
      ),
      CachedDocumentDetail,
      PrefetchHooks Function()
    >;
typedef $$CachedCaregiverAccountsTableCreateCompanionBuilder =
    CachedCaregiverAccountsCompanion Function({
      required String id,
      required String fullName,
      required String email,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$CachedCaregiverAccountsTableUpdateCompanionBuilder =
    CachedCaregiverAccountsCompanion Function({
      Value<String> id,
      Value<String> fullName,
      Value<String> email,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$CachedCaregiverAccountsTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedCaregiverAccountsTable> {
  $$CachedCaregiverAccountsTableFilterComposer({
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

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$CachedCaregiverAccountsTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedCaregiverAccountsTable> {
  $$CachedCaregiverAccountsTableOrderingComposer({
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

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCaregiverAccountsTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedCaregiverAccountsTable> {
  $$CachedCaregiverAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$CachedCaregiverAccountsTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedCaregiverAccountsTable,
          CachedCaregiverAccount,
          $$CachedCaregiverAccountsTableFilterComposer,
          $$CachedCaregiverAccountsTableOrderingComposer,
          $$CachedCaregiverAccountsTableAnnotationComposer,
          $$CachedCaregiverAccountsTableCreateCompanionBuilder,
          $$CachedCaregiverAccountsTableUpdateCompanionBuilder,
          (
            CachedCaregiverAccount,
            BaseReferences<
              _$RemoriDatabase,
              $CachedCaregiverAccountsTable,
              CachedCaregiverAccount
            >,
          ),
          CachedCaregiverAccount,
          PrefetchHooks Function()
        > {
  $$CachedCaregiverAccountsTableTableManager(
    _$RemoriDatabase db,
    $CachedCaregiverAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCaregiverAccountsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedCaregiverAccountsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedCaregiverAccountsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCaregiverAccountsCompanion(
                id: id,
                fullName: fullName,
                email: email,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fullName,
                required String email,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCaregiverAccountsCompanion.insert(
                id: id,
                fullName: fullName,
                email: email,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CachedCaregiverAccountsTable,
                    CachedCaregiverAccount
                  >(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedCaregiverAccountsTable,
                    CachedCaregiverAccount
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCaregiverAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedCaregiverAccountsTable,
      CachedCaregiverAccount,
      $$CachedCaregiverAccountsTableFilterComposer,
      $$CachedCaregiverAccountsTableOrderingComposer,
      $$CachedCaregiverAccountsTableAnnotationComposer,
      $$CachedCaregiverAccountsTableCreateCompanionBuilder,
      $$CachedCaregiverAccountsTableUpdateCompanionBuilder,
      (
        CachedCaregiverAccount,
        BaseReferences<
          _$RemoriDatabase,
          $CachedCaregiverAccountsTable,
          CachedCaregiverAccount
        >,
      ),
      CachedCaregiverAccount,
      PrefetchHooks Function()
    >;
typedef $$CachedConsentsTableCreateCompanionBuilder =
    CachedConsentsCompanion Function({
      required String caregiverId,
      required String patientId,
      required String id,
      required String payload,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$CachedConsentsTableUpdateCompanionBuilder =
    CachedConsentsCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> id,
      Value<String> payload,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$CachedConsentsTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedConsentsTable> {
  $$CachedConsentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$CachedConsentsTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedConsentsTable> {
  $$CachedConsentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedConsentsTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedConsentsTable> {
  $$CachedConsentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$CachedConsentsTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedConsentsTable,
          CachedConsent,
          $$CachedConsentsTableFilterComposer,
          $$CachedConsentsTableOrderingComposer,
          $$CachedConsentsTableAnnotationComposer,
          $$CachedConsentsTableCreateCompanionBuilder,
          $$CachedConsentsTableUpdateCompanionBuilder,
          (
            CachedConsent,
            BaseReferences<
              _$RemoriDatabase,
              $CachedConsentsTable,
              CachedConsent
            >,
          ),
          CachedConsent,
          PrefetchHooks Function()
        > {
  $$CachedConsentsTableTableManager(
    _$RemoriDatabase db,
    $CachedConsentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedConsentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedConsentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedConsentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedConsentsCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                payload: payload,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String id,
                required String payload,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedConsentsCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                payload: payload,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedConsentsTable, CachedConsent>(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedConsentsTable,
                    CachedConsent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedConsentsTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedConsentsTable,
      CachedConsent,
      $$CachedConsentsTableFilterComposer,
      $$CachedConsentsTableOrderingComposer,
      $$CachedConsentsTableAnnotationComposer,
      $$CachedConsentsTableCreateCompanionBuilder,
      $$CachedConsentsTableUpdateCompanionBuilder,
      (
        CachedConsent,
        BaseReferences<_$RemoriDatabase, $CachedConsentsTable, CachedConsent>,
      ),
      CachedConsent,
      PrefetchHooks Function()
    >;
typedef $$CachedCaregiverLinksTableCreateCompanionBuilder =
    CachedCaregiverLinksCompanion Function({
      required String caregiverId,
      required String patientId,
      required String id,
      required String payload,
      Value<int> rowid,
    });
typedef $$CachedCaregiverLinksTableUpdateCompanionBuilder =
    CachedCaregiverLinksCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<String> id,
      Value<String> payload,
      Value<int> rowid,
    });

class $$CachedCaregiverLinksTableFilterComposer
    extends Composer<_$RemoriDatabase, $CachedCaregiverLinksTable> {
  $$CachedCaregiverLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCaregiverLinksTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CachedCaregiverLinksTable> {
  $$CachedCaregiverLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCaregiverLinksTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CachedCaregiverLinksTable> {
  $$CachedCaregiverLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$CachedCaregiverLinksTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CachedCaregiverLinksTable,
          CachedCaregiverLink,
          $$CachedCaregiverLinksTableFilterComposer,
          $$CachedCaregiverLinksTableOrderingComposer,
          $$CachedCaregiverLinksTableAnnotationComposer,
          $$CachedCaregiverLinksTableCreateCompanionBuilder,
          $$CachedCaregiverLinksTableUpdateCompanionBuilder,
          (
            CachedCaregiverLink,
            BaseReferences<
              _$RemoriDatabase,
              $CachedCaregiverLinksTable,
              CachedCaregiverLink
            >,
          ),
          CachedCaregiverLink,
          PrefetchHooks Function()
        > {
  $$CachedCaregiverLinksTableTableManager(
    _$RemoriDatabase db,
    $CachedCaregiverLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCaregiverLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCaregiverLinksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedCaregiverLinksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCaregiverLinksCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required String id,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => CachedCaregiverLinksCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedCaregiverLinksTable, CachedCaregiverLink>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CachedCaregiverLinksTable,
                    CachedCaregiverLink
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCaregiverLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CachedCaregiverLinksTable,
      CachedCaregiverLink,
      $$CachedCaregiverLinksTableFilterComposer,
      $$CachedCaregiverLinksTableOrderingComposer,
      $$CachedCaregiverLinksTableAnnotationComposer,
      $$CachedCaregiverLinksTableCreateCompanionBuilder,
      $$CachedCaregiverLinksTableUpdateCompanionBuilder,
      (
        CachedCaregiverLink,
        BaseReferences<
          _$RemoriDatabase,
          $CachedCaregiverLinksTable,
          CachedCaregiverLink
        >,
      ),
      CachedCaregiverLink,
      PrefetchHooks Function()
    >;
typedef $$CaregiversCacheStatesTableCreateCompanionBuilder =
    CaregiversCacheStatesCompanion Function({
      required String caregiverId,
      required String patientId,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$CaregiversCacheStatesTableUpdateCompanionBuilder =
    CaregiversCacheStatesCompanion Function({
      Value<String> caregiverId,
      Value<String> patientId,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$CaregiversCacheStatesTableFilterComposer
    extends Composer<_$RemoriDatabase, $CaregiversCacheStatesTable> {
  $$CaregiversCacheStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$CaregiversCacheStatesTableOrderingComposer
    extends Composer<_$RemoriDatabase, $CaregiversCacheStatesTable> {
  $$CaregiversCacheStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CaregiversCacheStatesTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $CaregiversCacheStatesTable> {
  $$CaregiversCacheStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get caregiverId => $composableBuilder(
    column: $table.caregiverId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$CaregiversCacheStatesTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $CaregiversCacheStatesTable,
          CaregiversCacheState,
          $$CaregiversCacheStatesTableFilterComposer,
          $$CaregiversCacheStatesTableOrderingComposer,
          $$CaregiversCacheStatesTableAnnotationComposer,
          $$CaregiversCacheStatesTableCreateCompanionBuilder,
          $$CaregiversCacheStatesTableUpdateCompanionBuilder,
          (
            CaregiversCacheState,
            BaseReferences<
              _$RemoriDatabase,
              $CaregiversCacheStatesTable,
              CaregiversCacheState
            >,
          ),
          CaregiversCacheState,
          PrefetchHooks Function()
        > {
  $$CaregiversCacheStatesTableTableManager(
    _$RemoriDatabase db,
    $CaregiversCacheStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CaregiversCacheStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CaregiversCacheStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CaregiversCacheStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> caregiverId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaregiversCacheStatesCompanion(
                caregiverId: caregiverId,
                patientId: patientId,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String caregiverId,
                required String patientId,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => CaregiversCacheStatesCompanion.insert(
                caregiverId: caregiverId,
                patientId: patientId,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CaregiversCacheStatesTable,
                    CaregiversCacheState
                  >(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $CaregiversCacheStatesTable,
                    CaregiversCacheState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CaregiversCacheStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $CaregiversCacheStatesTable,
      CaregiversCacheState,
      $$CaregiversCacheStatesTableFilterComposer,
      $$CaregiversCacheStatesTableOrderingComposer,
      $$CaregiversCacheStatesTableAnnotationComposer,
      $$CaregiversCacheStatesTableCreateCompanionBuilder,
      $$CaregiversCacheStatesTableUpdateCompanionBuilder,
      (
        CaregiversCacheState,
        BaseReferences<
          _$RemoriDatabase,
          $CaregiversCacheStatesTable,
          CaregiversCacheState
        >,
      ),
      CaregiversCacheState,
      PrefetchHooks Function()
    >;
typedef $$PatientTodaySettingsTableCreateCompanionBuilder =
    PatientTodaySettingsCompanion Function({
      required String patientId,
      required String deviceId,
      required String fullName,
      required String language,
      required String timezone,
      required bool memoryEnabled,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$PatientTodaySettingsTableUpdateCompanionBuilder =
    PatientTodaySettingsCompanion Function({
      Value<String> patientId,
      Value<String> deviceId,
      Value<String> fullName,
      Value<String> language,
      Value<String> timezone,
      Value<bool> memoryEnabled,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$PatientTodaySettingsTableFilterComposer
    extends Composer<_$RemoriDatabase, $PatientTodaySettingsTable> {
  $$PatientTodaySettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get memoryEnabled => $composableBuilder(
    column: $table.memoryEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$PatientTodaySettingsTableOrderingComposer
    extends Composer<_$RemoriDatabase, $PatientTodaySettingsTable> {
  $$PatientTodaySettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get memoryEnabled => $composableBuilder(
    column: $table.memoryEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatientTodaySettingsTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $PatientTodaySettingsTable> {
  $$PatientTodaySettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<bool> get memoryEnabled => $composableBuilder(
    column: $table.memoryEnabled,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get refreshedAt =>
      $composableBuilder(
        column: $table.refreshedAt,
        builder: (column) => column,
      );
}

class $$PatientTodaySettingsTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $PatientTodaySettingsTable,
          PatientTodaySetting,
          $$PatientTodaySettingsTableFilterComposer,
          $$PatientTodaySettingsTableOrderingComposer,
          $$PatientTodaySettingsTableAnnotationComposer,
          $$PatientTodaySettingsTableCreateCompanionBuilder,
          $$PatientTodaySettingsTableUpdateCompanionBuilder,
          (
            PatientTodaySetting,
            BaseReferences<
              _$RemoriDatabase,
              $PatientTodaySettingsTable,
              PatientTodaySetting
            >,
          ),
          PatientTodaySetting,
          PrefetchHooks Function()
        > {
  $$PatientTodaySettingsTableTableManager(
    _$RemoriDatabase db,
    $PatientTodaySettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatientTodaySettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatientTodaySettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PatientTodaySettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> patientId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<bool> memoryEnabled = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatientTodaySettingsCompanion(
                patientId: patientId,
                deviceId: deviceId,
                fullName: fullName,
                language: language,
                timezone: timezone,
                memoryEnabled: memoryEnabled,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String patientId,
                required String deviceId,
                required String fullName,
                required String language,
                required String timezone,
                required bool memoryEnabled,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => PatientTodaySettingsCompanion.insert(
                patientId: patientId,
                deviceId: deviceId,
                fullName: fullName,
                language: language,
                timezone: timezone,
                memoryEnabled: memoryEnabled,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PatientTodaySettingsTable, PatientTodaySetting>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $PatientTodaySettingsTable,
                    PatientTodaySetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PatientTodaySettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $PatientTodaySettingsTable,
      PatientTodaySetting,
      $$PatientTodaySettingsTableFilterComposer,
      $$PatientTodaySettingsTableOrderingComposer,
      $$PatientTodaySettingsTableAnnotationComposer,
      $$PatientTodaySettingsTableCreateCompanionBuilder,
      $$PatientTodaySettingsTableUpdateCompanionBuilder,
      (
        PatientTodaySetting,
        BaseReferences<
          _$RemoriDatabase,
          $PatientTodaySettingsTable,
          PatientTodaySetting
        >,
      ),
      PatientTodaySetting,
      PrefetchHooks Function()
    >;
typedef $$PatientReminderCardsTableCreateCompanionBuilder =
    PatientReminderCardsCompanion Function({
      required String patientId,
      required String deviceId,
      required String id,
      required String day,
      required String title,
      Value<int> rowid,
    });
typedef $$PatientReminderCardsTableUpdateCompanionBuilder =
    PatientReminderCardsCompanion Function({
      Value<String> patientId,
      Value<String> deviceId,
      Value<String> id,
      Value<String> day,
      Value<String> title,
      Value<int> rowid,
    });

class $$PatientReminderCardsTableFilterComposer
    extends Composer<_$RemoriDatabase, $PatientReminderCardsTable> {
  $$PatientReminderCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PatientReminderCardsTableOrderingComposer
    extends Composer<_$RemoriDatabase, $PatientReminderCardsTable> {
  $$PatientReminderCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatientReminderCardsTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $PatientReminderCardsTable> {
  $$PatientReminderCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);
}

class $$PatientReminderCardsTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $PatientReminderCardsTable,
          PatientReminderCard,
          $$PatientReminderCardsTableFilterComposer,
          $$PatientReminderCardsTableOrderingComposer,
          $$PatientReminderCardsTableAnnotationComposer,
          $$PatientReminderCardsTableCreateCompanionBuilder,
          $$PatientReminderCardsTableUpdateCompanionBuilder,
          (
            PatientReminderCard,
            BaseReferences<
              _$RemoriDatabase,
              $PatientReminderCardsTable,
              PatientReminderCard
            >,
          ),
          PatientReminderCard,
          PrefetchHooks Function()
        > {
  $$PatientReminderCardsTableTableManager(
    _$RemoriDatabase db,
    $PatientReminderCardsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatientReminderCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatientReminderCardsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PatientReminderCardsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> patientId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatientReminderCardsCompanion(
                patientId: patientId,
                deviceId: deviceId,
                id: id,
                day: day,
                title: title,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String patientId,
                required String deviceId,
                required String id,
                required String day,
                required String title,
                Value<int> rowid = const Value.absent(),
              }) => PatientReminderCardsCompanion.insert(
                patientId: patientId,
                deviceId: deviceId,
                id: id,
                day: day,
                title: title,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PatientReminderCardsTable, PatientReminderCard>(
                    table,
                  ),
                  BaseReferences<
                    _$RemoriDatabase,
                    $PatientReminderCardsTable,
                    PatientReminderCard
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PatientReminderCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $PatientReminderCardsTable,
      PatientReminderCard,
      $$PatientReminderCardsTableFilterComposer,
      $$PatientReminderCardsTableOrderingComposer,
      $$PatientReminderCardsTableAnnotationComposer,
      $$PatientReminderCardsTableCreateCompanionBuilder,
      $$PatientReminderCardsTableUpdateCompanionBuilder,
      (
        PatientReminderCard,
        BaseReferences<
          _$RemoriDatabase,
          $PatientReminderCardsTable,
          PatientReminderCard
        >,
      ),
      PatientReminderCard,
      PrefetchHooks Function()
    >;
typedef $$PatientKnownEncountersTableCreateCompanionBuilder =
    PatientKnownEncountersCompanion Function({
      required String patientId,
      required String deviceId,
      required String day,
      required String personId,
      required String name,
      required DateTime firstSeen,
      Value<int> rowid,
    });
typedef $$PatientKnownEncountersTableUpdateCompanionBuilder =
    PatientKnownEncountersCompanion Function({
      Value<String> patientId,
      Value<String> deviceId,
      Value<String> day,
      Value<String> personId,
      Value<String> name,
      Value<DateTime> firstSeen,
      Value<int> rowid,
    });

class $$PatientKnownEncountersTableFilterComposer
    extends Composer<_$RemoriDatabase, $PatientKnownEncountersTable> {
  $$PatientKnownEncountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get firstSeen =>
      $composableBuilder(
        column: $table.firstSeen,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$PatientKnownEncountersTableOrderingComposer
    extends Composer<_$RemoriDatabase, $PatientKnownEncountersTable> {
  $$PatientKnownEncountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatientKnownEncountersTableAnnotationComposer
    extends Composer<_$RemoriDatabase, $PatientKnownEncountersTable> {
  $$PatientKnownEncountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);
}

class $$PatientKnownEncountersTableTableManager
    extends
        RootTableManager<
          _$RemoriDatabase,
          $PatientKnownEncountersTable,
          PatientKnownEncounter,
          $$PatientKnownEncountersTableFilterComposer,
          $$PatientKnownEncountersTableOrderingComposer,
          $$PatientKnownEncountersTableAnnotationComposer,
          $$PatientKnownEncountersTableCreateCompanionBuilder,
          $$PatientKnownEncountersTableUpdateCompanionBuilder,
          (
            PatientKnownEncounter,
            BaseReferences<
              _$RemoriDatabase,
              $PatientKnownEncountersTable,
              PatientKnownEncounter
            >,
          ),
          PatientKnownEncounter,
          PrefetchHooks Function()
        > {
  $$PatientKnownEncountersTableTableManager(
    _$RemoriDatabase db,
    $PatientKnownEncountersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatientKnownEncountersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PatientKnownEncountersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PatientKnownEncountersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> patientId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> firstSeen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatientKnownEncountersCompanion(
                patientId: patientId,
                deviceId: deviceId,
                day: day,
                personId: personId,
                name: name,
                firstSeen: firstSeen,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String patientId,
                required String deviceId,
                required String day,
                required String personId,
                required String name,
                required DateTime firstSeen,
                Value<int> rowid = const Value.absent(),
              }) => PatientKnownEncountersCompanion.insert(
                patientId: patientId,
                deviceId: deviceId,
                day: day,
                personId: personId,
                name: name,
                firstSeen: firstSeen,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PatientKnownEncountersTable,
                    PatientKnownEncounter
                  >(table),
                  BaseReferences<
                    _$RemoriDatabase,
                    $PatientKnownEncountersTable,
                    PatientKnownEncounter
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PatientKnownEncountersTableProcessedTableManager =
    ProcessedTableManager<
      _$RemoriDatabase,
      $PatientKnownEncountersTable,
      PatientKnownEncounter,
      $$PatientKnownEncountersTableFilterComposer,
      $$PatientKnownEncountersTableOrderingComposer,
      $$PatientKnownEncountersTableAnnotationComposer,
      $$PatientKnownEncountersTableCreateCompanionBuilder,
      $$PatientKnownEncountersTableUpdateCompanionBuilder,
      (
        PatientKnownEncounter,
        BaseReferences<
          _$RemoriDatabase,
          $PatientKnownEncountersTable,
          PatientKnownEncounter
        >,
      ),
      PatientKnownEncounter,
      PrefetchHooks Function()
    >;

class $RemoriDatabaseManager {
  final _$RemoriDatabase _db;
  $RemoriDatabaseManager(this._db);
  $$ReminderLogsTableTableManager get reminderLogs =>
      $$ReminderLogsTableTableManager(_db, _db.reminderLogs);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
  $$DashboardPatientsTableTableManager get dashboardPatients =>
      $$DashboardPatientsTableTableManager(_db, _db.dashboardPatients);
  $$DashboardDevicesTableTableManager get dashboardDevices =>
      $$DashboardDevicesTableTableManager(_db, _db.dashboardDevices);
  $$DashboardAlertsTableTableManager get dashboardAlerts =>
      $$DashboardAlertsTableTableManager(_db, _db.dashboardAlerts);
  $$DashboardDaysTableTableManager get dashboardDays =>
      $$DashboardDaysTableTableManager(_db, _db.dashboardDays);
  $$CachedPeopleTableTableManager get cachedPeople =>
      $$CachedPeopleTableTableManager(_db, _db.cachedPeople);
  $$PeopleCacheStatesTableTableManager get peopleCacheStates =>
      $$PeopleCacheStatesTableTableManager(_db, _db.peopleCacheStates);
  $$PersonDetailStatesTableTableManager get personDetailStates =>
      $$PersonDetailStatesTableTableManager(_db, _db.personDetailStates);
  $$CachedPersonPhotosTableTableManager get cachedPersonPhotos =>
      $$CachedPersonPhotosTableTableManager(_db, _db.cachedPersonPhotos);
  $$CachedRemindersTableTableManager get cachedReminders =>
      $$CachedRemindersTableTableManager(_db, _db.cachedReminders);
  $$CachedReminderOccurrencesTableTableManager get cachedReminderOccurrences =>
      $$CachedReminderOccurrencesTableTableManager(
        _db,
        _db.cachedReminderOccurrences,
      );
  $$ReminderCacheStatesTableTableManager get reminderCacheStates =>
      $$ReminderCacheStatesTableTableManager(_db, _db.reminderCacheStates);
  $$CachedUnknownFacesTableTableManager get cachedUnknownFaces =>
      $$CachedUnknownFacesTableTableManager(_db, _db.cachedUnknownFaces);
  $$UnknownFacesCacheStatesTableTableManager get unknownFacesCacheStates =>
      $$UnknownFacesCacheStatesTableTableManager(
        _db,
        _db.unknownFacesCacheStates,
      );
  $$CachedUnknownFaceSamplesTableTableManager get cachedUnknownFaceSamples =>
      $$CachedUnknownFaceSamplesTableTableManager(
        _db,
        _db.cachedUnknownFaceSamples,
      );
  $$CachedPlacesTableTableManager get cachedPlaces =>
      $$CachedPlacesTableTableManager(_db, _db.cachedPlaces);
  $$PlacesCacheStatesTableTableManager get placesCacheStates =>
      $$PlacesCacheStatesTableTableManager(_db, _db.placesCacheStates);
  $$CachedJournalEntriesTableTableManager get cachedJournalEntries =>
      $$CachedJournalEntriesTableTableManager(_db, _db.cachedJournalEntries);
  $$CachedJournalMediaTableTableManager get cachedJournalMedia =>
      $$CachedJournalMediaTableTableManager(_db, _db.cachedJournalMedia);
  $$JournalCacheStatesTableTableManager get journalCacheStates =>
      $$JournalCacheStatesTableTableManager(_db, _db.journalCacheStates);
  $$CachedMediaDetailsTableTableManager get cachedMediaDetails =>
      $$CachedMediaDetailsTableTableManager(_db, _db.cachedMediaDetails);
  $$CachedDocumentsTableTableManager get cachedDocuments =>
      $$CachedDocumentsTableTableManager(_db, _db.cachedDocuments);
  $$DocumentsCacheStatesTableTableManager get documentsCacheStates =>
      $$DocumentsCacheStatesTableTableManager(_db, _db.documentsCacheStates);
  $$CachedDocumentDetailsTableTableManager get cachedDocumentDetails =>
      $$CachedDocumentDetailsTableTableManager(_db, _db.cachedDocumentDetails);
  $$CachedCaregiverAccountsTableTableManager get cachedCaregiverAccounts =>
      $$CachedCaregiverAccountsTableTableManager(
        _db,
        _db.cachedCaregiverAccounts,
      );
  $$CachedConsentsTableTableManager get cachedConsents =>
      $$CachedConsentsTableTableManager(_db, _db.cachedConsents);
  $$CachedCaregiverLinksTableTableManager get cachedCaregiverLinks =>
      $$CachedCaregiverLinksTableTableManager(_db, _db.cachedCaregiverLinks);
  $$CaregiversCacheStatesTableTableManager get caregiversCacheStates =>
      $$CaregiversCacheStatesTableTableManager(_db, _db.caregiversCacheStates);
  $$PatientTodaySettingsTableTableManager get patientTodaySettings =>
      $$PatientTodaySettingsTableTableManager(_db, _db.patientTodaySettings);
  $$PatientReminderCardsTableTableManager get patientReminderCards =>
      $$PatientReminderCardsTableTableManager(_db, _db.patientReminderCards);
  $$PatientKnownEncountersTableTableManager get patientKnownEncounters =>
      $$PatientKnownEncountersTableTableManager(
        _db,
        _db.patientKnownEncounters,
      );
}
