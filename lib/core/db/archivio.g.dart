// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archivio.dart';

// ignore_for_file: type=lint
class $DefinizioniTipoTable extends DefinizioniTipo
    with TableInfo<$DefinizioniTipoTable, DefinizioneTipo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DefinizioniTipoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggiornatoIlMeta = const VerificationMeta(
    'aggiornatoIl',
  );
  @override
  late final GeneratedColumn<String> aggiornatoIl = GeneratedColumn<String>(
    'aggiornato_il',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eliminatoMeta = const VerificationMeta(
    'eliminato',
  );
  @override
  late final GeneratedColumn<bool> eliminato = GeneratedColumn<bool>(
    'eliminato',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("eliminato" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ambitoMeta = const VerificationMeta('ambito');
  @override
  late final GeneratedColumn<String> ambito = GeneratedColumn<String>(
    'ambito',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effettoMeta = const VerificationMeta(
    'effetto',
  );
  @override
  late final GeneratedColumn<String> effetto = GeneratedColumn<String>(
    'effetto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schemaCampiMeta = const VerificationMeta(
    'schemaCampi',
  );
  @override
  late final GeneratedColumn<String> schemaCampi = GeneratedColumn<String>(
    'schema_campi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _versioneSchemaMeta = const VerificationMeta(
    'versioneSchema',
  );
  @override
  late final GeneratedColumn<int> versioneSchema = GeneratedColumn<int>(
    'versione_schema',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _diSistemaMeta = const VerificationMeta(
    'diSistema',
  );
  @override
  late final GeneratedColumn<bool> diSistema = GeneratedColumn<bool>(
    'di_sistema',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("di_sistema" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archiviatoMeta = const VerificationMeta(
    'archiviato',
  );
  @override
  late final GeneratedColumn<bool> archiviato = GeneratedColumn<bool>(
    'archiviato',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archiviato" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ordineMeta = const VerificationMeta('ordine');
  @override
  late final GeneratedColumn<int> ordine = GeneratedColumn<int>(
    'ordine',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    ambito,
    nome,
    effetto,
    schemaCampi,
    versioneSchema,
    diSistema,
    archiviato,
    ordine,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'definizioni_tipo';
  @override
  VerificationContext validateIntegrity(
    Insertable<DefinizioneTipo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('aggiornato_il')) {
      context.handle(
        _aggiornatoIlMeta,
        aggiornatoIl.isAcceptableOrUnknown(
          data['aggiornato_il']!,
          _aggiornatoIlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggiornatoIlMeta);
    }
    if (data.containsKey('eliminato')) {
      context.handle(
        _eliminatoMeta,
        eliminato.isAcceptableOrUnknown(data['eliminato']!, _eliminatoMeta),
      );
    }
    if (data.containsKey('ambito')) {
      context.handle(
        _ambitoMeta,
        ambito.isAcceptableOrUnknown(data['ambito']!, _ambitoMeta),
      );
    } else if (isInserting) {
      context.missing(_ambitoMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('effetto')) {
      context.handle(
        _effettoMeta,
        effetto.isAcceptableOrUnknown(data['effetto']!, _effettoMeta),
      );
    }
    if (data.containsKey('schema_campi')) {
      context.handle(
        _schemaCampiMeta,
        schemaCampi.isAcceptableOrUnknown(
          data['schema_campi']!,
          _schemaCampiMeta,
        ),
      );
    }
    if (data.containsKey('versione_schema')) {
      context.handle(
        _versioneSchemaMeta,
        versioneSchema.isAcceptableOrUnknown(
          data['versione_schema']!,
          _versioneSchemaMeta,
        ),
      );
    }
    if (data.containsKey('di_sistema')) {
      context.handle(
        _diSistemaMeta,
        diSistema.isAcceptableOrUnknown(data['di_sistema']!, _diSistemaMeta),
      );
    }
    if (data.containsKey('archiviato')) {
      context.handle(
        _archiviatoMeta,
        archiviato.isAcceptableOrUnknown(data['archiviato']!, _archiviatoMeta),
      );
    }
    if (data.containsKey('ordine')) {
      context.handle(
        _ordineMeta,
        ordine.isAcceptableOrUnknown(data['ordine']!, _ordineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DefinizioneTipo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DefinizioneTipo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      aggiornatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggiornato_il'],
      )!,
      eliminato: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}eliminato'],
      )!,
      ambito: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ambito'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      effetto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effetto'],
      ),
      schemaCampi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schema_campi'],
      )!,
      versioneSchema: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}versione_schema'],
      )!,
      diSistema: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}di_sistema'],
      )!,
      archiviato: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archiviato'],
      )!,
      ordine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordine'],
      )!,
    );
  }

  @override
  $DefinizioniTipoTable createAlias(String alias) {
    return $DefinizioniTipoTable(attachedDatabase, alias);
  }
}

class DefinizioneTipo extends DataClass implements Insertable<DefinizioneTipo> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;

  /// A cosa si applica: vedi [AmbitoTipo].
  final String ambito;
  final String nome;

  /// Comportamento contabile per i tipi di movimento: vedi [EffettoSaldo].
  final String? effetto;
  final String schemaCampi;
  final int versioneSchema;

  /// Tipi forniti dall'app (spesa, entrata, trasferimento...): rinominabili, non eliminabili.
  final bool diSistema;
  final bool archiviato;
  final int ordine;
  const DefinizioneTipo({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    required this.ambito,
    required this.nome,
    this.effetto,
    required this.schemaCampi,
    required this.versioneSchema,
    required this.diSistema,
    required this.archiviato,
    required this.ordine,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    map['ambito'] = Variable<String>(ambito);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || effetto != null) {
      map['effetto'] = Variable<String>(effetto);
    }
    map['schema_campi'] = Variable<String>(schemaCampi);
    map['versione_schema'] = Variable<int>(versioneSchema);
    map['di_sistema'] = Variable<bool>(diSistema);
    map['archiviato'] = Variable<bool>(archiviato);
    map['ordine'] = Variable<int>(ordine);
    return map;
  }

  DefinizioniTipoCompanion toCompanion(bool nullToAbsent) {
    return DefinizioniTipoCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      ambito: Value(ambito),
      nome: Value(nome),
      effetto: effetto == null && nullToAbsent
          ? const Value.absent()
          : Value(effetto),
      schemaCampi: Value(schemaCampi),
      versioneSchema: Value(versioneSchema),
      diSistema: Value(diSistema),
      archiviato: Value(archiviato),
      ordine: Value(ordine),
    );
  }

  factory DefinizioneTipo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DefinizioneTipo(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      ambito: serializer.fromJson<String>(json['ambito']),
      nome: serializer.fromJson<String>(json['nome']),
      effetto: serializer.fromJson<String?>(json['effetto']),
      schemaCampi: serializer.fromJson<String>(json['schemaCampi']),
      versioneSchema: serializer.fromJson<int>(json['versioneSchema']),
      diSistema: serializer.fromJson<bool>(json['diSistema']),
      archiviato: serializer.fromJson<bool>(json['archiviato']),
      ordine: serializer.fromJson<int>(json['ordine']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'ambito': serializer.toJson<String>(ambito),
      'nome': serializer.toJson<String>(nome),
      'effetto': serializer.toJson<String?>(effetto),
      'schemaCampi': serializer.toJson<String>(schemaCampi),
      'versioneSchema': serializer.toJson<int>(versioneSchema),
      'diSistema': serializer.toJson<bool>(diSistema),
      'archiviato': serializer.toJson<bool>(archiviato),
      'ordine': serializer.toJson<int>(ordine),
    };
  }

  DefinizioneTipo copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    String? ambito,
    String? nome,
    Value<String?> effetto = const Value.absent(),
    String? schemaCampi,
    int? versioneSchema,
    bool? diSistema,
    bool? archiviato,
    int? ordine,
  }) => DefinizioneTipo(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    ambito: ambito ?? this.ambito,
    nome: nome ?? this.nome,
    effetto: effetto.present ? effetto.value : this.effetto,
    schemaCampi: schemaCampi ?? this.schemaCampi,
    versioneSchema: versioneSchema ?? this.versioneSchema,
    diSistema: diSistema ?? this.diSistema,
    archiviato: archiviato ?? this.archiviato,
    ordine: ordine ?? this.ordine,
  );
  DefinizioneTipo copyWithCompanion(DefinizioniTipoCompanion data) {
    return DefinizioneTipo(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      ambito: data.ambito.present ? data.ambito.value : this.ambito,
      nome: data.nome.present ? data.nome.value : this.nome,
      effetto: data.effetto.present ? data.effetto.value : this.effetto,
      schemaCampi: data.schemaCampi.present
          ? data.schemaCampi.value
          : this.schemaCampi,
      versioneSchema: data.versioneSchema.present
          ? data.versioneSchema.value
          : this.versioneSchema,
      diSistema: data.diSistema.present ? data.diSistema.value : this.diSistema,
      archiviato: data.archiviato.present
          ? data.archiviato.value
          : this.archiviato,
      ordine: data.ordine.present ? data.ordine.value : this.ordine,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DefinizioneTipo(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('ambito: $ambito, ')
          ..write('nome: $nome, ')
          ..write('effetto: $effetto, ')
          ..write('schemaCampi: $schemaCampi, ')
          ..write('versioneSchema: $versioneSchema, ')
          ..write('diSistema: $diSistema, ')
          ..write('archiviato: $archiviato, ')
          ..write('ordine: $ordine')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aggiornatoIl,
    eliminato,
    ambito,
    nome,
    effetto,
    schemaCampi,
    versioneSchema,
    diSistema,
    archiviato,
    ordine,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DefinizioneTipo &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.ambito == this.ambito &&
          other.nome == this.nome &&
          other.effetto == this.effetto &&
          other.schemaCampi == this.schemaCampi &&
          other.versioneSchema == this.versioneSchema &&
          other.diSistema == this.diSistema &&
          other.archiviato == this.archiviato &&
          other.ordine == this.ordine);
}

class DefinizioniTipoCompanion extends UpdateCompanion<DefinizioneTipo> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String> ambito;
  final Value<String> nome;
  final Value<String?> effetto;
  final Value<String> schemaCampi;
  final Value<int> versioneSchema;
  final Value<bool> diSistema;
  final Value<bool> archiviato;
  final Value<int> ordine;
  final Value<int> rowid;
  const DefinizioniTipoCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.ambito = const Value.absent(),
    this.nome = const Value.absent(),
    this.effetto = const Value.absent(),
    this.schemaCampi = const Value.absent(),
    this.versioneSchema = const Value.absent(),
    this.diSistema = const Value.absent(),
    this.archiviato = const Value.absent(),
    this.ordine = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DefinizioniTipoCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    required String ambito,
    required String nome,
    this.effetto = const Value.absent(),
    this.schemaCampi = const Value.absent(),
    this.versioneSchema = const Value.absent(),
    this.diSistema = const Value.absent(),
    this.archiviato = const Value.absent(),
    this.ordine = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       ambito = Value(ambito),
       nome = Value(nome);
  static Insertable<DefinizioneTipo> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? ambito,
    Expression<String>? nome,
    Expression<String>? effetto,
    Expression<String>? schemaCampi,
    Expression<int>? versioneSchema,
    Expression<bool>? diSistema,
    Expression<bool>? archiviato,
    Expression<int>? ordine,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (ambito != null) 'ambito': ambito,
      if (nome != null) 'nome': nome,
      if (effetto != null) 'effetto': effetto,
      if (schemaCampi != null) 'schema_campi': schemaCampi,
      if (versioneSchema != null) 'versione_schema': versioneSchema,
      if (diSistema != null) 'di_sistema': diSistema,
      if (archiviato != null) 'archiviato': archiviato,
      if (ordine != null) 'ordine': ordine,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DefinizioniTipoCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String>? ambito,
    Value<String>? nome,
    Value<String?>? effetto,
    Value<String>? schemaCampi,
    Value<int>? versioneSchema,
    Value<bool>? diSistema,
    Value<bool>? archiviato,
    Value<int>? ordine,
    Value<int>? rowid,
  }) {
    return DefinizioniTipoCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      ambito: ambito ?? this.ambito,
      nome: nome ?? this.nome,
      effetto: effetto ?? this.effetto,
      schemaCampi: schemaCampi ?? this.schemaCampi,
      versioneSchema: versioneSchema ?? this.versioneSchema,
      diSistema: diSistema ?? this.diSistema,
      archiviato: archiviato ?? this.archiviato,
      ordine: ordine ?? this.ordine,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (aggiornatoIl.present) {
      map['aggiornato_il'] = Variable<String>(aggiornatoIl.value);
    }
    if (eliminato.present) {
      map['eliminato'] = Variable<bool>(eliminato.value);
    }
    if (ambito.present) {
      map['ambito'] = Variable<String>(ambito.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (effetto.present) {
      map['effetto'] = Variable<String>(effetto.value);
    }
    if (schemaCampi.present) {
      map['schema_campi'] = Variable<String>(schemaCampi.value);
    }
    if (versioneSchema.present) {
      map['versione_schema'] = Variable<int>(versioneSchema.value);
    }
    if (diSistema.present) {
      map['di_sistema'] = Variable<bool>(diSistema.value);
    }
    if (archiviato.present) {
      map['archiviato'] = Variable<bool>(archiviato.value);
    }
    if (ordine.present) {
      map['ordine'] = Variable<int>(ordine.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DefinizioniTipoCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('ambito: $ambito, ')
          ..write('nome: $nome, ')
          ..write('effetto: $effetto, ')
          ..write('schemaCampi: $schemaCampi, ')
          ..write('versioneSchema: $versioneSchema, ')
          ..write('diSistema: $diSistema, ')
          ..write('archiviato: $archiviato, ')
          ..write('ordine: $ordine, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PortafogliTable extends Portafogli
    with TableInfo<$PortafogliTable, Portafoglio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PortafogliTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggiornatoIlMeta = const VerificationMeta(
    'aggiornatoIl',
  );
  @override
  late final GeneratedColumn<String> aggiornatoIl = GeneratedColumn<String>(
    'aggiornato_il',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eliminatoMeta = const VerificationMeta(
    'eliminato',
  );
  @override
  late final GeneratedColumn<bool> eliminato = GeneratedColumn<bool>(
    'eliminato',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("eliminato" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tipoIdMeta = const VerificationMeta('tipoId');
  @override
  late final GeneratedColumn<String> tipoId = GeneratedColumn<String>(
    'tipo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES definizioni_tipo (id)',
    ),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valutaMeta = const VerificationMeta('valuta');
  @override
  late final GeneratedColumn<String> valuta = GeneratedColumn<String>(
    'valuta',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saldoInizialeMinimoMeta =
      const VerificationMeta('saldoInizialeMinimo');
  @override
  late final GeneratedColumn<int> saldoInizialeMinimo = GeneratedColumn<int>(
    'saldo_iniziale_minimo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _campiMeta = const VerificationMeta('campi');
  @override
  late final GeneratedColumn<String> campi = GeneratedColumn<String>(
    'campi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _archiviatoMeta = const VerificationMeta(
    'archiviato',
  );
  @override
  late final GeneratedColumn<bool> archiviato = GeneratedColumn<bool>(
    'archiviato',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archiviato" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ordineMeta = const VerificationMeta('ordine');
  @override
  late final GeneratedColumn<int> ordine = GeneratedColumn<int>(
    'ordine',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    tipoId,
    nome,
    valuta,
    saldoInizialeMinimo,
    campi,
    archiviato,
    ordine,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'portafogli';
  @override
  VerificationContext validateIntegrity(
    Insertable<Portafoglio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('aggiornato_il')) {
      context.handle(
        _aggiornatoIlMeta,
        aggiornatoIl.isAcceptableOrUnknown(
          data['aggiornato_il']!,
          _aggiornatoIlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggiornatoIlMeta);
    }
    if (data.containsKey('eliminato')) {
      context.handle(
        _eliminatoMeta,
        eliminato.isAcceptableOrUnknown(data['eliminato']!, _eliminatoMeta),
      );
    }
    if (data.containsKey('tipo_id')) {
      context.handle(
        _tipoIdMeta,
        tipoId.isAcceptableOrUnknown(data['tipo_id']!, _tipoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('valuta')) {
      context.handle(
        _valutaMeta,
        valuta.isAcceptableOrUnknown(data['valuta']!, _valutaMeta),
      );
    } else if (isInserting) {
      context.missing(_valutaMeta);
    }
    if (data.containsKey('saldo_iniziale_minimo')) {
      context.handle(
        _saldoInizialeMinimoMeta,
        saldoInizialeMinimo.isAcceptableOrUnknown(
          data['saldo_iniziale_minimo']!,
          _saldoInizialeMinimoMeta,
        ),
      );
    }
    if (data.containsKey('campi')) {
      context.handle(
        _campiMeta,
        campi.isAcceptableOrUnknown(data['campi']!, _campiMeta),
      );
    }
    if (data.containsKey('archiviato')) {
      context.handle(
        _archiviatoMeta,
        archiviato.isAcceptableOrUnknown(data['archiviato']!, _archiviatoMeta),
      );
    }
    if (data.containsKey('ordine')) {
      context.handle(
        _ordineMeta,
        ordine.isAcceptableOrUnknown(data['ordine']!, _ordineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Portafoglio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Portafoglio(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      aggiornatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggiornato_il'],
      )!,
      eliminato: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}eliminato'],
      )!,
      tipoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      valuta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valuta'],
      )!,
      saldoInizialeMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saldo_iniziale_minimo'],
      )!,
      campi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}campi'],
      )!,
      archiviato: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archiviato'],
      )!,
      ordine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordine'],
      )!,
    );
  }

  @override
  $PortafogliTable createAlias(String alias) {
    return $PortafogliTable(attachedDatabase, alias);
  }
}

class Portafoglio extends DataClass implements Insertable<Portafoglio> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;
  final String tipoId;
  final String nome;

  /// Codice ISO 4217 (EUR, USD, ...) o codice crypto.
  final String valuta;

  /// Importi sempre in unità minime intere (centesimi): mai numeri decimali per i soldi.
  final int saldoInizialeMinimo;
  final String campi;
  final bool archiviato;
  final int ordine;
  const Portafoglio({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    required this.tipoId,
    required this.nome,
    required this.valuta,
    required this.saldoInizialeMinimo,
    required this.campi,
    required this.archiviato,
    required this.ordine,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    map['tipo_id'] = Variable<String>(tipoId);
    map['nome'] = Variable<String>(nome);
    map['valuta'] = Variable<String>(valuta);
    map['saldo_iniziale_minimo'] = Variable<int>(saldoInizialeMinimo);
    map['campi'] = Variable<String>(campi);
    map['archiviato'] = Variable<bool>(archiviato);
    map['ordine'] = Variable<int>(ordine);
    return map;
  }

  PortafogliCompanion toCompanion(bool nullToAbsent) {
    return PortafogliCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      tipoId: Value(tipoId),
      nome: Value(nome),
      valuta: Value(valuta),
      saldoInizialeMinimo: Value(saldoInizialeMinimo),
      campi: Value(campi),
      archiviato: Value(archiviato),
      ordine: Value(ordine),
    );
  }

  factory Portafoglio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Portafoglio(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      tipoId: serializer.fromJson<String>(json['tipoId']),
      nome: serializer.fromJson<String>(json['nome']),
      valuta: serializer.fromJson<String>(json['valuta']),
      saldoInizialeMinimo: serializer.fromJson<int>(
        json['saldoInizialeMinimo'],
      ),
      campi: serializer.fromJson<String>(json['campi']),
      archiviato: serializer.fromJson<bool>(json['archiviato']),
      ordine: serializer.fromJson<int>(json['ordine']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'tipoId': serializer.toJson<String>(tipoId),
      'nome': serializer.toJson<String>(nome),
      'valuta': serializer.toJson<String>(valuta),
      'saldoInizialeMinimo': serializer.toJson<int>(saldoInizialeMinimo),
      'campi': serializer.toJson<String>(campi),
      'archiviato': serializer.toJson<bool>(archiviato),
      'ordine': serializer.toJson<int>(ordine),
    };
  }

  Portafoglio copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    String? tipoId,
    String? nome,
    String? valuta,
    int? saldoInizialeMinimo,
    String? campi,
    bool? archiviato,
    int? ordine,
  }) => Portafoglio(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    tipoId: tipoId ?? this.tipoId,
    nome: nome ?? this.nome,
    valuta: valuta ?? this.valuta,
    saldoInizialeMinimo: saldoInizialeMinimo ?? this.saldoInizialeMinimo,
    campi: campi ?? this.campi,
    archiviato: archiviato ?? this.archiviato,
    ordine: ordine ?? this.ordine,
  );
  Portafoglio copyWithCompanion(PortafogliCompanion data) {
    return Portafoglio(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      tipoId: data.tipoId.present ? data.tipoId.value : this.tipoId,
      nome: data.nome.present ? data.nome.value : this.nome,
      valuta: data.valuta.present ? data.valuta.value : this.valuta,
      saldoInizialeMinimo: data.saldoInizialeMinimo.present
          ? data.saldoInizialeMinimo.value
          : this.saldoInizialeMinimo,
      campi: data.campi.present ? data.campi.value : this.campi,
      archiviato: data.archiviato.present
          ? data.archiviato.value
          : this.archiviato,
      ordine: data.ordine.present ? data.ordine.value : this.ordine,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Portafoglio(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('tipoId: $tipoId, ')
          ..write('nome: $nome, ')
          ..write('valuta: $valuta, ')
          ..write('saldoInizialeMinimo: $saldoInizialeMinimo, ')
          ..write('campi: $campi, ')
          ..write('archiviato: $archiviato, ')
          ..write('ordine: $ordine')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aggiornatoIl,
    eliminato,
    tipoId,
    nome,
    valuta,
    saldoInizialeMinimo,
    campi,
    archiviato,
    ordine,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Portafoglio &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.tipoId == this.tipoId &&
          other.nome == this.nome &&
          other.valuta == this.valuta &&
          other.saldoInizialeMinimo == this.saldoInizialeMinimo &&
          other.campi == this.campi &&
          other.archiviato == this.archiviato &&
          other.ordine == this.ordine);
}

class PortafogliCompanion extends UpdateCompanion<Portafoglio> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String> tipoId;
  final Value<String> nome;
  final Value<String> valuta;
  final Value<int> saldoInizialeMinimo;
  final Value<String> campi;
  final Value<bool> archiviato;
  final Value<int> ordine;
  final Value<int> rowid;
  const PortafogliCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.tipoId = const Value.absent(),
    this.nome = const Value.absent(),
    this.valuta = const Value.absent(),
    this.saldoInizialeMinimo = const Value.absent(),
    this.campi = const Value.absent(),
    this.archiviato = const Value.absent(),
    this.ordine = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PortafogliCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    required String tipoId,
    required String nome,
    required String valuta,
    this.saldoInizialeMinimo = const Value.absent(),
    this.campi = const Value.absent(),
    this.archiviato = const Value.absent(),
    this.ordine = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       tipoId = Value(tipoId),
       nome = Value(nome),
       valuta = Value(valuta);
  static Insertable<Portafoglio> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? tipoId,
    Expression<String>? nome,
    Expression<String>? valuta,
    Expression<int>? saldoInizialeMinimo,
    Expression<String>? campi,
    Expression<bool>? archiviato,
    Expression<int>? ordine,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (tipoId != null) 'tipo_id': tipoId,
      if (nome != null) 'nome': nome,
      if (valuta != null) 'valuta': valuta,
      if (saldoInizialeMinimo != null)
        'saldo_iniziale_minimo': saldoInizialeMinimo,
      if (campi != null) 'campi': campi,
      if (archiviato != null) 'archiviato': archiviato,
      if (ordine != null) 'ordine': ordine,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PortafogliCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String>? tipoId,
    Value<String>? nome,
    Value<String>? valuta,
    Value<int>? saldoInizialeMinimo,
    Value<String>? campi,
    Value<bool>? archiviato,
    Value<int>? ordine,
    Value<int>? rowid,
  }) {
    return PortafogliCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      tipoId: tipoId ?? this.tipoId,
      nome: nome ?? this.nome,
      valuta: valuta ?? this.valuta,
      saldoInizialeMinimo: saldoInizialeMinimo ?? this.saldoInizialeMinimo,
      campi: campi ?? this.campi,
      archiviato: archiviato ?? this.archiviato,
      ordine: ordine ?? this.ordine,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (aggiornatoIl.present) {
      map['aggiornato_il'] = Variable<String>(aggiornatoIl.value);
    }
    if (eliminato.present) {
      map['eliminato'] = Variable<bool>(eliminato.value);
    }
    if (tipoId.present) {
      map['tipo_id'] = Variable<String>(tipoId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (valuta.present) {
      map['valuta'] = Variable<String>(valuta.value);
    }
    if (saldoInizialeMinimo.present) {
      map['saldo_iniziale_minimo'] = Variable<int>(saldoInizialeMinimo.value);
    }
    if (campi.present) {
      map['campi'] = Variable<String>(campi.value);
    }
    if (archiviato.present) {
      map['archiviato'] = Variable<bool>(archiviato.value);
    }
    if (ordine.present) {
      map['ordine'] = Variable<int>(ordine.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PortafogliCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('tipoId: $tipoId, ')
          ..write('nome: $nome, ')
          ..write('valuta: $valuta, ')
          ..write('saldoInizialeMinimo: $saldoInizialeMinimo, ')
          ..write('campi: $campi, ')
          ..write('archiviato: $archiviato, ')
          ..write('ordine: $ordine, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategorieTable extends Categorie
    with TableInfo<$CategorieTable, Categoria> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategorieTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggiornatoIlMeta = const VerificationMeta(
    'aggiornatoIl',
  );
  @override
  late final GeneratedColumn<String> aggiornatoIl = GeneratedColumn<String>(
    'aggiornato_il',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eliminatoMeta = const VerificationMeta(
    'eliminato',
  );
  @override
  late final GeneratedColumn<bool> eliminato = GeneratedColumn<bool>(
    'eliminato',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("eliminato" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _padreIdMeta = const VerificationMeta(
    'padreId',
  );
  @override
  late final GeneratedColumn<String> padreId = GeneratedColumn<String>(
    'padre_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categorie (id)',
    ),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconaMeta = const VerificationMeta('icona');
  @override
  late final GeneratedColumn<String> icona = GeneratedColumn<String>(
    'icona',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coloreMeta = const VerificationMeta('colore');
  @override
  late final GeneratedColumn<int> colore = GeneratedColumn<int>(
    'colore',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archiviataMeta = const VerificationMeta(
    'archiviata',
  );
  @override
  late final GeneratedColumn<bool> archiviata = GeneratedColumn<bool>(
    'archiviata',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archiviata" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ordineMeta = const VerificationMeta('ordine');
  @override
  late final GeneratedColumn<int> ordine = GeneratedColumn<int>(
    'ordine',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    padreId,
    nome,
    icona,
    colore,
    archiviata,
    ordine,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categorie';
  @override
  VerificationContext validateIntegrity(
    Insertable<Categoria> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('aggiornato_il')) {
      context.handle(
        _aggiornatoIlMeta,
        aggiornatoIl.isAcceptableOrUnknown(
          data['aggiornato_il']!,
          _aggiornatoIlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggiornatoIlMeta);
    }
    if (data.containsKey('eliminato')) {
      context.handle(
        _eliminatoMeta,
        eliminato.isAcceptableOrUnknown(data['eliminato']!, _eliminatoMeta),
      );
    }
    if (data.containsKey('padre_id')) {
      context.handle(
        _padreIdMeta,
        padreId.isAcceptableOrUnknown(data['padre_id']!, _padreIdMeta),
      );
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('icona')) {
      context.handle(
        _iconaMeta,
        icona.isAcceptableOrUnknown(data['icona']!, _iconaMeta),
      );
    }
    if (data.containsKey('colore')) {
      context.handle(
        _coloreMeta,
        colore.isAcceptableOrUnknown(data['colore']!, _coloreMeta),
      );
    }
    if (data.containsKey('archiviata')) {
      context.handle(
        _archiviataMeta,
        archiviata.isAcceptableOrUnknown(data['archiviata']!, _archiviataMeta),
      );
    }
    if (data.containsKey('ordine')) {
      context.handle(
        _ordineMeta,
        ordine.isAcceptableOrUnknown(data['ordine']!, _ordineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Categoria map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Categoria(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      aggiornatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggiornato_il'],
      )!,
      eliminato: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}eliminato'],
      )!,
      padreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}padre_id'],
      ),
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      icona: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icona'],
      ),
      colore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}colore'],
      ),
      archiviata: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archiviata'],
      )!,
      ordine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordine'],
      )!,
    );
  }

  @override
  $CategorieTable createAlias(String alias) {
    return $CategorieTable(attachedDatabase, alias);
  }
}

class Categoria extends DataClass implements Insertable<Categoria> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;
  final String? padreId;
  final String nome;
  final String? icona;
  final int? colore;
  final bool archiviata;
  final int ordine;
  const Categoria({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    this.padreId,
    required this.nome,
    this.icona,
    this.colore,
    required this.archiviata,
    required this.ordine,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    if (!nullToAbsent || padreId != null) {
      map['padre_id'] = Variable<String>(padreId);
    }
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || icona != null) {
      map['icona'] = Variable<String>(icona);
    }
    if (!nullToAbsent || colore != null) {
      map['colore'] = Variable<int>(colore);
    }
    map['archiviata'] = Variable<bool>(archiviata);
    map['ordine'] = Variable<int>(ordine);
    return map;
  }

  CategorieCompanion toCompanion(bool nullToAbsent) {
    return CategorieCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      padreId: padreId == null && nullToAbsent
          ? const Value.absent()
          : Value(padreId),
      nome: Value(nome),
      icona: icona == null && nullToAbsent
          ? const Value.absent()
          : Value(icona),
      colore: colore == null && nullToAbsent
          ? const Value.absent()
          : Value(colore),
      archiviata: Value(archiviata),
      ordine: Value(ordine),
    );
  }

  factory Categoria.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Categoria(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      padreId: serializer.fromJson<String?>(json['padreId']),
      nome: serializer.fromJson<String>(json['nome']),
      icona: serializer.fromJson<String?>(json['icona']),
      colore: serializer.fromJson<int?>(json['colore']),
      archiviata: serializer.fromJson<bool>(json['archiviata']),
      ordine: serializer.fromJson<int>(json['ordine']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'padreId': serializer.toJson<String?>(padreId),
      'nome': serializer.toJson<String>(nome),
      'icona': serializer.toJson<String?>(icona),
      'colore': serializer.toJson<int?>(colore),
      'archiviata': serializer.toJson<bool>(archiviata),
      'ordine': serializer.toJson<int>(ordine),
    };
  }

  Categoria copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    Value<String?> padreId = const Value.absent(),
    String? nome,
    Value<String?> icona = const Value.absent(),
    Value<int?> colore = const Value.absent(),
    bool? archiviata,
    int? ordine,
  }) => Categoria(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    padreId: padreId.present ? padreId.value : this.padreId,
    nome: nome ?? this.nome,
    icona: icona.present ? icona.value : this.icona,
    colore: colore.present ? colore.value : this.colore,
    archiviata: archiviata ?? this.archiviata,
    ordine: ordine ?? this.ordine,
  );
  Categoria copyWithCompanion(CategorieCompanion data) {
    return Categoria(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      padreId: data.padreId.present ? data.padreId.value : this.padreId,
      nome: data.nome.present ? data.nome.value : this.nome,
      icona: data.icona.present ? data.icona.value : this.icona,
      colore: data.colore.present ? data.colore.value : this.colore,
      archiviata: data.archiviata.present
          ? data.archiviata.value
          : this.archiviata,
      ordine: data.ordine.present ? data.ordine.value : this.ordine,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Categoria(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('padreId: $padreId, ')
          ..write('nome: $nome, ')
          ..write('icona: $icona, ')
          ..write('colore: $colore, ')
          ..write('archiviata: $archiviata, ')
          ..write('ordine: $ordine')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aggiornatoIl,
    eliminato,
    padreId,
    nome,
    icona,
    colore,
    archiviata,
    ordine,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Categoria &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.padreId == this.padreId &&
          other.nome == this.nome &&
          other.icona == this.icona &&
          other.colore == this.colore &&
          other.archiviata == this.archiviata &&
          other.ordine == this.ordine);
}

class CategorieCompanion extends UpdateCompanion<Categoria> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String?> padreId;
  final Value<String> nome;
  final Value<String?> icona;
  final Value<int?> colore;
  final Value<bool> archiviata;
  final Value<int> ordine;
  final Value<int> rowid;
  const CategorieCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.padreId = const Value.absent(),
    this.nome = const Value.absent(),
    this.icona = const Value.absent(),
    this.colore = const Value.absent(),
    this.archiviata = const Value.absent(),
    this.ordine = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategorieCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    this.padreId = const Value.absent(),
    required String nome,
    this.icona = const Value.absent(),
    this.colore = const Value.absent(),
    this.archiviata = const Value.absent(),
    this.ordine = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       nome = Value(nome);
  static Insertable<Categoria> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? padreId,
    Expression<String>? nome,
    Expression<String>? icona,
    Expression<int>? colore,
    Expression<bool>? archiviata,
    Expression<int>? ordine,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (padreId != null) 'padre_id': padreId,
      if (nome != null) 'nome': nome,
      if (icona != null) 'icona': icona,
      if (colore != null) 'colore': colore,
      if (archiviata != null) 'archiviata': archiviata,
      if (ordine != null) 'ordine': ordine,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategorieCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String?>? padreId,
    Value<String>? nome,
    Value<String?>? icona,
    Value<int?>? colore,
    Value<bool>? archiviata,
    Value<int>? ordine,
    Value<int>? rowid,
  }) {
    return CategorieCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      padreId: padreId ?? this.padreId,
      nome: nome ?? this.nome,
      icona: icona ?? this.icona,
      colore: colore ?? this.colore,
      archiviata: archiviata ?? this.archiviata,
      ordine: ordine ?? this.ordine,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (aggiornatoIl.present) {
      map['aggiornato_il'] = Variable<String>(aggiornatoIl.value);
    }
    if (eliminato.present) {
      map['eliminato'] = Variable<bool>(eliminato.value);
    }
    if (padreId.present) {
      map['padre_id'] = Variable<String>(padreId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (icona.present) {
      map['icona'] = Variable<String>(icona.value);
    }
    if (colore.present) {
      map['colore'] = Variable<int>(colore.value);
    }
    if (archiviata.present) {
      map['archiviata'] = Variable<bool>(archiviata.value);
    }
    if (ordine.present) {
      map['ordine'] = Variable<int>(ordine.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategorieCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('padreId: $padreId, ')
          ..write('nome: $nome, ')
          ..write('icona: $icona, ')
          ..write('colore: $colore, ')
          ..write('archiviata: $archiviata, ')
          ..write('ordine: $ordine, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovimentiTable extends Movimenti
    with TableInfo<$MovimentiTable, Movimento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimentiTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggiornatoIlMeta = const VerificationMeta(
    'aggiornatoIl',
  );
  @override
  late final GeneratedColumn<String> aggiornatoIl = GeneratedColumn<String>(
    'aggiornato_il',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eliminatoMeta = const VerificationMeta(
    'eliminato',
  );
  @override
  late final GeneratedColumn<bool> eliminato = GeneratedColumn<bool>(
    'eliminato',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("eliminato" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tipoIdMeta = const VerificationMeta('tipoId');
  @override
  late final GeneratedColumn<String> tipoId = GeneratedColumn<String>(
    'tipo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES definizioni_tipo (id)',
    ),
  );
  static const VerificationMeta _portafoglioIdMeta = const VerificationMeta(
    'portafoglioId',
  );
  @override
  late final GeneratedColumn<String> portafoglioId = GeneratedColumn<String>(
    'portafoglio_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES portafogli (id)',
    ),
  );
  static const VerificationMeta _portafoglioDestinazioneIdMeta =
      const VerificationMeta('portafoglioDestinazioneId');
  @override
  late final GeneratedColumn<String> portafoglioDestinazioneId =
      GeneratedColumn<String>(
        'portafoglio_destinazione_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES portafogli (id)',
        ),
      );
  static const VerificationMeta _categoriaIdMeta = const VerificationMeta(
    'categoriaId',
  );
  @override
  late final GeneratedColumn<String> categoriaId = GeneratedColumn<String>(
    'categoria_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categorie (id)',
    ),
  );
  static const VerificationMeta _importoMinimoMeta = const VerificationMeta(
    'importoMinimo',
  );
  @override
  late final GeneratedColumn<int> importoMinimo = GeneratedColumn<int>(
    'importo_minimo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valutaMeta = const VerificationMeta('valuta');
  @override
  late final GeneratedColumn<String> valuta = GeneratedColumn<String>(
    'valuta',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descrizioneMeta = const VerificationMeta(
    'descrizione',
  );
  @override
  late final GeneratedColumn<String> descrizione = GeneratedColumn<String>(
    'descrizione',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _campiMeta = const VerificationMeta('campi');
  @override
  late final GeneratedColumn<String> campi = GeneratedColumn<String>(
    'campi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    tipoId,
    portafoglioId,
    portafoglioDestinazioneId,
    categoriaId,
    importoMinimo,
    valuta,
    data,
    descrizione,
    campi,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimenti';
  @override
  VerificationContext validateIntegrity(
    Insertable<Movimento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('aggiornato_il')) {
      context.handle(
        _aggiornatoIlMeta,
        aggiornatoIl.isAcceptableOrUnknown(
          data['aggiornato_il']!,
          _aggiornatoIlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggiornatoIlMeta);
    }
    if (data.containsKey('eliminato')) {
      context.handle(
        _eliminatoMeta,
        eliminato.isAcceptableOrUnknown(data['eliminato']!, _eliminatoMeta),
      );
    }
    if (data.containsKey('tipo_id')) {
      context.handle(
        _tipoIdMeta,
        tipoId.isAcceptableOrUnknown(data['tipo_id']!, _tipoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoIdMeta);
    }
    if (data.containsKey('portafoglio_id')) {
      context.handle(
        _portafoglioIdMeta,
        portafoglioId.isAcceptableOrUnknown(
          data['portafoglio_id']!,
          _portafoglioIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_portafoglioIdMeta);
    }
    if (data.containsKey('portafoglio_destinazione_id')) {
      context.handle(
        _portafoglioDestinazioneIdMeta,
        portafoglioDestinazioneId.isAcceptableOrUnknown(
          data['portafoglio_destinazione_id']!,
          _portafoglioDestinazioneIdMeta,
        ),
      );
    }
    if (data.containsKey('categoria_id')) {
      context.handle(
        _categoriaIdMeta,
        categoriaId.isAcceptableOrUnknown(
          data['categoria_id']!,
          _categoriaIdMeta,
        ),
      );
    }
    if (data.containsKey('importo_minimo')) {
      context.handle(
        _importoMinimoMeta,
        importoMinimo.isAcceptableOrUnknown(
          data['importo_minimo']!,
          _importoMinimoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importoMinimoMeta);
    }
    if (data.containsKey('valuta')) {
      context.handle(
        _valutaMeta,
        valuta.isAcceptableOrUnknown(data['valuta']!, _valutaMeta),
      );
    } else if (isInserting) {
      context.missing(_valutaMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('descrizione')) {
      context.handle(
        _descrizioneMeta,
        descrizione.isAcceptableOrUnknown(
          data['descrizione']!,
          _descrizioneMeta,
        ),
      );
    }
    if (data.containsKey('campi')) {
      context.handle(
        _campiMeta,
        campi.isAcceptableOrUnknown(data['campi']!, _campiMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Movimento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movimento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      aggiornatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggiornato_il'],
      )!,
      eliminato: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}eliminato'],
      )!,
      tipoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_id'],
      )!,
      portafoglioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portafoglio_id'],
      )!,
      portafoglioDestinazioneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portafoglio_destinazione_id'],
      ),
      categoriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria_id'],
      ),
      importoMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importo_minimo'],
      )!,
      valuta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valuta'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      descrizione: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descrizione'],
      )!,
      campi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}campi'],
      )!,
    );
  }

  @override
  $MovimentiTable createAlias(String alias) {
    return $MovimentiTable(attachedDatabase, alias);
  }
}

class Movimento extends DataClass implements Insertable<Movimento> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;
  final String tipoId;
  final String portafoglioId;

  /// Solo per i trasferimenti: portafoglio che riceve.
  final String? portafoglioDestinazioneId;
  final String? categoriaId;

  /// Importo positivo in unità minime; il segno lo decide l'effetto del tipo.
  final int importoMinimo;
  final String valuta;

  /// Data contabile (giorno), formato AAAA-MM-GG.
  final String data;
  final String descrizione;
  final String campi;
  const Movimento({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    required this.tipoId,
    required this.portafoglioId,
    this.portafoglioDestinazioneId,
    this.categoriaId,
    required this.importoMinimo,
    required this.valuta,
    required this.data,
    required this.descrizione,
    required this.campi,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    map['tipo_id'] = Variable<String>(tipoId);
    map['portafoglio_id'] = Variable<String>(portafoglioId);
    if (!nullToAbsent || portafoglioDestinazioneId != null) {
      map['portafoglio_destinazione_id'] = Variable<String>(
        portafoglioDestinazioneId,
      );
    }
    if (!nullToAbsent || categoriaId != null) {
      map['categoria_id'] = Variable<String>(categoriaId);
    }
    map['importo_minimo'] = Variable<int>(importoMinimo);
    map['valuta'] = Variable<String>(valuta);
    map['data'] = Variable<String>(data);
    map['descrizione'] = Variable<String>(descrizione);
    map['campi'] = Variable<String>(campi);
    return map;
  }

  MovimentiCompanion toCompanion(bool nullToAbsent) {
    return MovimentiCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      tipoId: Value(tipoId),
      portafoglioId: Value(portafoglioId),
      portafoglioDestinazioneId:
          portafoglioDestinazioneId == null && nullToAbsent
          ? const Value.absent()
          : Value(portafoglioDestinazioneId),
      categoriaId: categoriaId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoriaId),
      importoMinimo: Value(importoMinimo),
      valuta: Value(valuta),
      data: Value(data),
      descrizione: Value(descrizione),
      campi: Value(campi),
    );
  }

  factory Movimento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Movimento(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      tipoId: serializer.fromJson<String>(json['tipoId']),
      portafoglioId: serializer.fromJson<String>(json['portafoglioId']),
      portafoglioDestinazioneId: serializer.fromJson<String?>(
        json['portafoglioDestinazioneId'],
      ),
      categoriaId: serializer.fromJson<String?>(json['categoriaId']),
      importoMinimo: serializer.fromJson<int>(json['importoMinimo']),
      valuta: serializer.fromJson<String>(json['valuta']),
      data: serializer.fromJson<String>(json['data']),
      descrizione: serializer.fromJson<String>(json['descrizione']),
      campi: serializer.fromJson<String>(json['campi']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'tipoId': serializer.toJson<String>(tipoId),
      'portafoglioId': serializer.toJson<String>(portafoglioId),
      'portafoglioDestinazioneId': serializer.toJson<String?>(
        portafoglioDestinazioneId,
      ),
      'categoriaId': serializer.toJson<String?>(categoriaId),
      'importoMinimo': serializer.toJson<int>(importoMinimo),
      'valuta': serializer.toJson<String>(valuta),
      'data': serializer.toJson<String>(data),
      'descrizione': serializer.toJson<String>(descrizione),
      'campi': serializer.toJson<String>(campi),
    };
  }

  Movimento copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    String? tipoId,
    String? portafoglioId,
    Value<String?> portafoglioDestinazioneId = const Value.absent(),
    Value<String?> categoriaId = const Value.absent(),
    int? importoMinimo,
    String? valuta,
    String? data,
    String? descrizione,
    String? campi,
  }) => Movimento(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    tipoId: tipoId ?? this.tipoId,
    portafoglioId: portafoglioId ?? this.portafoglioId,
    portafoglioDestinazioneId: portafoglioDestinazioneId.present
        ? portafoglioDestinazioneId.value
        : this.portafoglioDestinazioneId,
    categoriaId: categoriaId.present ? categoriaId.value : this.categoriaId,
    importoMinimo: importoMinimo ?? this.importoMinimo,
    valuta: valuta ?? this.valuta,
    data: data ?? this.data,
    descrizione: descrizione ?? this.descrizione,
    campi: campi ?? this.campi,
  );
  Movimento copyWithCompanion(MovimentiCompanion data) {
    return Movimento(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      tipoId: data.tipoId.present ? data.tipoId.value : this.tipoId,
      portafoglioId: data.portafoglioId.present
          ? data.portafoglioId.value
          : this.portafoglioId,
      portafoglioDestinazioneId: data.portafoglioDestinazioneId.present
          ? data.portafoglioDestinazioneId.value
          : this.portafoglioDestinazioneId,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      importoMinimo: data.importoMinimo.present
          ? data.importoMinimo.value
          : this.importoMinimo,
      valuta: data.valuta.present ? data.valuta.value : this.valuta,
      data: data.data.present ? data.data.value : this.data,
      descrizione: data.descrizione.present
          ? data.descrizione.value
          : this.descrizione,
      campi: data.campi.present ? data.campi.value : this.campi,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Movimento(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('tipoId: $tipoId, ')
          ..write('portafoglioId: $portafoglioId, ')
          ..write('portafoglioDestinazioneId: $portafoglioDestinazioneId, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('importoMinimo: $importoMinimo, ')
          ..write('valuta: $valuta, ')
          ..write('data: $data, ')
          ..write('descrizione: $descrizione, ')
          ..write('campi: $campi')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aggiornatoIl,
    eliminato,
    tipoId,
    portafoglioId,
    portafoglioDestinazioneId,
    categoriaId,
    importoMinimo,
    valuta,
    data,
    descrizione,
    campi,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Movimento &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.tipoId == this.tipoId &&
          other.portafoglioId == this.portafoglioId &&
          other.portafoglioDestinazioneId == this.portafoglioDestinazioneId &&
          other.categoriaId == this.categoriaId &&
          other.importoMinimo == this.importoMinimo &&
          other.valuta == this.valuta &&
          other.data == this.data &&
          other.descrizione == this.descrizione &&
          other.campi == this.campi);
}

class MovimentiCompanion extends UpdateCompanion<Movimento> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String> tipoId;
  final Value<String> portafoglioId;
  final Value<String?> portafoglioDestinazioneId;
  final Value<String?> categoriaId;
  final Value<int> importoMinimo;
  final Value<String> valuta;
  final Value<String> data;
  final Value<String> descrizione;
  final Value<String> campi;
  final Value<int> rowid;
  const MovimentiCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.tipoId = const Value.absent(),
    this.portafoglioId = const Value.absent(),
    this.portafoglioDestinazioneId = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.importoMinimo = const Value.absent(),
    this.valuta = const Value.absent(),
    this.data = const Value.absent(),
    this.descrizione = const Value.absent(),
    this.campi = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovimentiCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    required String tipoId,
    required String portafoglioId,
    this.portafoglioDestinazioneId = const Value.absent(),
    this.categoriaId = const Value.absent(),
    required int importoMinimo,
    required String valuta,
    required String data,
    this.descrizione = const Value.absent(),
    this.campi = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       tipoId = Value(tipoId),
       portafoglioId = Value(portafoglioId),
       importoMinimo = Value(importoMinimo),
       valuta = Value(valuta),
       data = Value(data);
  static Insertable<Movimento> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? tipoId,
    Expression<String>? portafoglioId,
    Expression<String>? portafoglioDestinazioneId,
    Expression<String>? categoriaId,
    Expression<int>? importoMinimo,
    Expression<String>? valuta,
    Expression<String>? data,
    Expression<String>? descrizione,
    Expression<String>? campi,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (tipoId != null) 'tipo_id': tipoId,
      if (portafoglioId != null) 'portafoglio_id': portafoglioId,
      if (portafoglioDestinazioneId != null)
        'portafoglio_destinazione_id': portafoglioDestinazioneId,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (importoMinimo != null) 'importo_minimo': importoMinimo,
      if (valuta != null) 'valuta': valuta,
      if (data != null) 'data': data,
      if (descrizione != null) 'descrizione': descrizione,
      if (campi != null) 'campi': campi,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovimentiCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String>? tipoId,
    Value<String>? portafoglioId,
    Value<String?>? portafoglioDestinazioneId,
    Value<String?>? categoriaId,
    Value<int>? importoMinimo,
    Value<String>? valuta,
    Value<String>? data,
    Value<String>? descrizione,
    Value<String>? campi,
    Value<int>? rowid,
  }) {
    return MovimentiCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      tipoId: tipoId ?? this.tipoId,
      portafoglioId: portafoglioId ?? this.portafoglioId,
      portafoglioDestinazioneId:
          portafoglioDestinazioneId ?? this.portafoglioDestinazioneId,
      categoriaId: categoriaId ?? this.categoriaId,
      importoMinimo: importoMinimo ?? this.importoMinimo,
      valuta: valuta ?? this.valuta,
      data: data ?? this.data,
      descrizione: descrizione ?? this.descrizione,
      campi: campi ?? this.campi,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (aggiornatoIl.present) {
      map['aggiornato_il'] = Variable<String>(aggiornatoIl.value);
    }
    if (eliminato.present) {
      map['eliminato'] = Variable<bool>(eliminato.value);
    }
    if (tipoId.present) {
      map['tipo_id'] = Variable<String>(tipoId.value);
    }
    if (portafoglioId.present) {
      map['portafoglio_id'] = Variable<String>(portafoglioId.value);
    }
    if (portafoglioDestinazioneId.present) {
      map['portafoglio_destinazione_id'] = Variable<String>(
        portafoglioDestinazioneId.value,
      );
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<String>(categoriaId.value);
    }
    if (importoMinimo.present) {
      map['importo_minimo'] = Variable<int>(importoMinimo.value);
    }
    if (valuta.present) {
      map['valuta'] = Variable<String>(valuta.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (descrizione.present) {
      map['descrizione'] = Variable<String>(descrizione.value);
    }
    if (campi.present) {
      map['campi'] = Variable<String>(campi.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimentiCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('tipoId: $tipoId, ')
          ..write('portafoglioId: $portafoglioId, ')
          ..write('portafoglioDestinazioneId: $portafoglioDestinazioneId, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('importoMinimo: $importoMinimo, ')
          ..write('valuta: $valuta, ')
          ..write('data: $data, ')
          ..write('descrizione: $descrizione, ')
          ..write('campi: $campi, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EtichetteTable extends Etichette
    with TableInfo<$EtichetteTable, Etichetta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EtichetteTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggiornatoIlMeta = const VerificationMeta(
    'aggiornatoIl',
  );
  @override
  late final GeneratedColumn<String> aggiornatoIl = GeneratedColumn<String>(
    'aggiornato_il',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eliminatoMeta = const VerificationMeta(
    'eliminato',
  );
  @override
  late final GeneratedColumn<bool> eliminato = GeneratedColumn<bool>(
    'eliminato',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("eliminato" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _padreIdMeta = const VerificationMeta(
    'padreId',
  );
  @override
  late final GeneratedColumn<String> padreId = GeneratedColumn<String>(
    'padre_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES etichette (id)',
    ),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    padreId,
    nome,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'etichette';
  @override
  VerificationContext validateIntegrity(
    Insertable<Etichetta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('aggiornato_il')) {
      context.handle(
        _aggiornatoIlMeta,
        aggiornatoIl.isAcceptableOrUnknown(
          data['aggiornato_il']!,
          _aggiornatoIlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggiornatoIlMeta);
    }
    if (data.containsKey('eliminato')) {
      context.handle(
        _eliminatoMeta,
        eliminato.isAcceptableOrUnknown(data['eliminato']!, _eliminatoMeta),
      );
    }
    if (data.containsKey('padre_id')) {
      context.handle(
        _padreIdMeta,
        padreId.isAcceptableOrUnknown(data['padre_id']!, _padreIdMeta),
      );
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Etichetta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Etichetta(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      aggiornatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggiornato_il'],
      )!,
      eliminato: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}eliminato'],
      )!,
      padreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}padre_id'],
      ),
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
    );
  }

  @override
  $EtichetteTable createAlias(String alias) {
    return $EtichetteTable(attachedDatabase, alias);
  }
}

class Etichetta extends DataClass implements Insertable<Etichetta> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;
  final String? padreId;
  final String nome;
  const Etichetta({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    this.padreId,
    required this.nome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    if (!nullToAbsent || padreId != null) {
      map['padre_id'] = Variable<String>(padreId);
    }
    map['nome'] = Variable<String>(nome);
    return map;
  }

  EtichetteCompanion toCompanion(bool nullToAbsent) {
    return EtichetteCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      padreId: padreId == null && nullToAbsent
          ? const Value.absent()
          : Value(padreId),
      nome: Value(nome),
    );
  }

  factory Etichetta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Etichetta(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      padreId: serializer.fromJson<String?>(json['padreId']),
      nome: serializer.fromJson<String>(json['nome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'padreId': serializer.toJson<String?>(padreId),
      'nome': serializer.toJson<String>(nome),
    };
  }

  Etichetta copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    Value<String?> padreId = const Value.absent(),
    String? nome,
  }) => Etichetta(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    padreId: padreId.present ? padreId.value : this.padreId,
    nome: nome ?? this.nome,
  );
  Etichetta copyWithCompanion(EtichetteCompanion data) {
    return Etichetta(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      padreId: data.padreId.present ? data.padreId.value : this.padreId,
      nome: data.nome.present ? data.nome.value : this.nome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Etichetta(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('padreId: $padreId, ')
          ..write('nome: $nome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, aggiornatoIl, eliminato, padreId, nome);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Etichetta &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.padreId == this.padreId &&
          other.nome == this.nome);
}

class EtichetteCompanion extends UpdateCompanion<Etichetta> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String?> padreId;
  final Value<String> nome;
  final Value<int> rowid;
  const EtichetteCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.padreId = const Value.absent(),
    this.nome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EtichetteCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    this.padreId = const Value.absent(),
    required String nome,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       nome = Value(nome);
  static Insertable<Etichetta> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? padreId,
    Expression<String>? nome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (padreId != null) 'padre_id': padreId,
      if (nome != null) 'nome': nome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EtichetteCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String?>? padreId,
    Value<String>? nome,
    Value<int>? rowid,
  }) {
    return EtichetteCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      padreId: padreId ?? this.padreId,
      nome: nome ?? this.nome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (aggiornatoIl.present) {
      map['aggiornato_il'] = Variable<String>(aggiornatoIl.value);
    }
    if (eliminato.present) {
      map['eliminato'] = Variable<bool>(eliminato.value);
    }
    if (padreId.present) {
      map['padre_id'] = Variable<String>(padreId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EtichetteCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('padreId: $padreId, ')
          ..write('nome: $nome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovimentiEtichetteTable extends MovimentiEtichette
    with TableInfo<$MovimentiEtichetteTable, MovimentoEtichetta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimentiEtichetteTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggiornatoIlMeta = const VerificationMeta(
    'aggiornatoIl',
  );
  @override
  late final GeneratedColumn<String> aggiornatoIl = GeneratedColumn<String>(
    'aggiornato_il',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eliminatoMeta = const VerificationMeta(
    'eliminato',
  );
  @override
  late final GeneratedColumn<bool> eliminato = GeneratedColumn<bool>(
    'eliminato',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("eliminato" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _movimentoIdMeta = const VerificationMeta(
    'movimentoId',
  );
  @override
  late final GeneratedColumn<String> movimentoId = GeneratedColumn<String>(
    'movimento_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES movimenti (id)',
    ),
  );
  static const VerificationMeta _etichettaIdMeta = const VerificationMeta(
    'etichettaId',
  );
  @override
  late final GeneratedColumn<String> etichettaId = GeneratedColumn<String>(
    'etichetta_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES etichette (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    movimentoId,
    etichettaId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimenti_etichette';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovimentoEtichetta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('aggiornato_il')) {
      context.handle(
        _aggiornatoIlMeta,
        aggiornatoIl.isAcceptableOrUnknown(
          data['aggiornato_il']!,
          _aggiornatoIlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggiornatoIlMeta);
    }
    if (data.containsKey('eliminato')) {
      context.handle(
        _eliminatoMeta,
        eliminato.isAcceptableOrUnknown(data['eliminato']!, _eliminatoMeta),
      );
    }
    if (data.containsKey('movimento_id')) {
      context.handle(
        _movimentoIdMeta,
        movimentoId.isAcceptableOrUnknown(
          data['movimento_id']!,
          _movimentoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movimentoIdMeta);
    }
    if (data.containsKey('etichetta_id')) {
      context.handle(
        _etichettaIdMeta,
        etichettaId.isAcceptableOrUnknown(
          data['etichetta_id']!,
          _etichettaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_etichettaIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MovimentoEtichetta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovimentoEtichetta(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      aggiornatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggiornato_il'],
      )!,
      eliminato: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}eliminato'],
      )!,
      movimentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movimento_id'],
      )!,
      etichettaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etichetta_id'],
      )!,
    );
  }

  @override
  $MovimentiEtichetteTable createAlias(String alias) {
    return $MovimentiEtichetteTable(attachedDatabase, alias);
  }
}

class MovimentoEtichetta extends DataClass
    implements Insertable<MovimentoEtichetta> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;
  final String movimentoId;
  final String etichettaId;
  const MovimentoEtichetta({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    required this.movimentoId,
    required this.etichettaId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    map['movimento_id'] = Variable<String>(movimentoId);
    map['etichetta_id'] = Variable<String>(etichettaId);
    return map;
  }

  MovimentiEtichetteCompanion toCompanion(bool nullToAbsent) {
    return MovimentiEtichetteCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      movimentoId: Value(movimentoId),
      etichettaId: Value(etichettaId),
    );
  }

  factory MovimentoEtichetta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovimentoEtichetta(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      movimentoId: serializer.fromJson<String>(json['movimentoId']),
      etichettaId: serializer.fromJson<String>(json['etichettaId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'movimentoId': serializer.toJson<String>(movimentoId),
      'etichettaId': serializer.toJson<String>(etichettaId),
    };
  }

  MovimentoEtichetta copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    String? movimentoId,
    String? etichettaId,
  }) => MovimentoEtichetta(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    movimentoId: movimentoId ?? this.movimentoId,
    etichettaId: etichettaId ?? this.etichettaId,
  );
  MovimentoEtichetta copyWithCompanion(MovimentiEtichetteCompanion data) {
    return MovimentoEtichetta(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      movimentoId: data.movimentoId.present
          ? data.movimentoId.value
          : this.movimentoId,
      etichettaId: data.etichettaId.present
          ? data.etichettaId.value
          : this.etichettaId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovimentoEtichetta(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('movimentoId: $movimentoId, ')
          ..write('etichettaId: $etichettaId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, aggiornatoIl, eliminato, movimentoId, etichettaId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovimentoEtichetta &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.movimentoId == this.movimentoId &&
          other.etichettaId == this.etichettaId);
}

class MovimentiEtichetteCompanion extends UpdateCompanion<MovimentoEtichetta> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String> movimentoId;
  final Value<String> etichettaId;
  final Value<int> rowid;
  const MovimentiEtichetteCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.movimentoId = const Value.absent(),
    this.etichettaId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovimentiEtichetteCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    required String movimentoId,
    required String etichettaId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       movimentoId = Value(movimentoId),
       etichettaId = Value(etichettaId);
  static Insertable<MovimentoEtichetta> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? movimentoId,
    Expression<String>? etichettaId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (movimentoId != null) 'movimento_id': movimentoId,
      if (etichettaId != null) 'etichetta_id': etichettaId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovimentiEtichetteCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String>? movimentoId,
    Value<String>? etichettaId,
    Value<int>? rowid,
  }) {
    return MovimentiEtichetteCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      movimentoId: movimentoId ?? this.movimentoId,
      etichettaId: etichettaId ?? this.etichettaId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (aggiornatoIl.present) {
      map['aggiornato_il'] = Variable<String>(aggiornatoIl.value);
    }
    if (eliminato.present) {
      map['eliminato'] = Variable<bool>(eliminato.value);
    }
    if (movimentoId.present) {
      map['movimento_id'] = Variable<String>(movimentoId.value);
    }
    if (etichettaId.present) {
      map['etichetta_id'] = Variable<String>(etichettaId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimentiEtichetteCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('movimentoId: $movimentoId, ')
          ..write('etichettaId: $etichettaId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImpostazioniTable extends Impostazioni
    with TableInfo<$ImpostazioniTable, Impostazione> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImpostazioniTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chiaveMeta = const VerificationMeta('chiave');
  @override
  late final GeneratedColumn<String> chiave = GeneratedColumn<String>(
    'chiave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valoreMeta = const VerificationMeta('valore');
  @override
  late final GeneratedColumn<String> valore = GeneratedColumn<String>(
    'valore',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [chiave, valore];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'impostazioni';
  @override
  VerificationContext validateIntegrity(
    Insertable<Impostazione> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chiave')) {
      context.handle(
        _chiaveMeta,
        chiave.isAcceptableOrUnknown(data['chiave']!, _chiaveMeta),
      );
    } else if (isInserting) {
      context.missing(_chiaveMeta);
    }
    if (data.containsKey('valore')) {
      context.handle(
        _valoreMeta,
        valore.isAcceptableOrUnknown(data['valore']!, _valoreMeta),
      );
    } else if (isInserting) {
      context.missing(_valoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chiave};
  @override
  Impostazione map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Impostazione(
      chiave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chiave'],
      )!,
      valore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valore'],
      )!,
    );
  }

  @override
  $ImpostazioniTable createAlias(String alias) {
    return $ImpostazioniTable(attachedDatabase, alias);
  }
}

class Impostazione extends DataClass implements Insertable<Impostazione> {
  final String chiave;
  final String valore;
  const Impostazione({required this.chiave, required this.valore});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chiave'] = Variable<String>(chiave);
    map['valore'] = Variable<String>(valore);
    return map;
  }

  ImpostazioniCompanion toCompanion(bool nullToAbsent) {
    return ImpostazioniCompanion(chiave: Value(chiave), valore: Value(valore));
  }

  factory Impostazione.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Impostazione(
      chiave: serializer.fromJson<String>(json['chiave']),
      valore: serializer.fromJson<String>(json['valore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chiave': serializer.toJson<String>(chiave),
      'valore': serializer.toJson<String>(valore),
    };
  }

  Impostazione copyWith({String? chiave, String? valore}) => Impostazione(
    chiave: chiave ?? this.chiave,
    valore: valore ?? this.valore,
  );
  Impostazione copyWithCompanion(ImpostazioniCompanion data) {
    return Impostazione(
      chiave: data.chiave.present ? data.chiave.value : this.chiave,
      valore: data.valore.present ? data.valore.value : this.valore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Impostazione(')
          ..write('chiave: $chiave, ')
          ..write('valore: $valore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chiave, valore);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Impostazione &&
          other.chiave == this.chiave &&
          other.valore == this.valore);
}

class ImpostazioniCompanion extends UpdateCompanion<Impostazione> {
  final Value<String> chiave;
  final Value<String> valore;
  final Value<int> rowid;
  const ImpostazioniCompanion({
    this.chiave = const Value.absent(),
    this.valore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImpostazioniCompanion.insert({
    required String chiave,
    required String valore,
    this.rowid = const Value.absent(),
  }) : chiave = Value(chiave),
       valore = Value(valore);
  static Insertable<Impostazione> custom({
    Expression<String>? chiave,
    Expression<String>? valore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chiave != null) 'chiave': chiave,
      if (valore != null) 'valore': valore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImpostazioniCompanion copyWith({
    Value<String>? chiave,
    Value<String>? valore,
    Value<int>? rowid,
  }) {
    return ImpostazioniCompanion(
      chiave: chiave ?? this.chiave,
      valore: valore ?? this.valore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chiave.present) {
      map['chiave'] = Variable<String>(chiave.value);
    }
    if (valore.present) {
      map['valore'] = Variable<String>(valore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImpostazioniCompanion(')
          ..write('chiave: $chiave, ')
          ..write('valore: $valore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$Archivio extends GeneratedDatabase {
  _$Archivio(QueryExecutor e) : super(e);
  $ArchivioManager get managers => $ArchivioManager(this);
  late final $DefinizioniTipoTable definizioniTipo = $DefinizioniTipoTable(
    this,
  );
  late final $PortafogliTable portafogli = $PortafogliTable(this);
  late final $CategorieTable categorie = $CategorieTable(this);
  late final $MovimentiTable movimenti = $MovimentiTable(this);
  late final $EtichetteTable etichette = $EtichetteTable(this);
  late final $MovimentiEtichetteTable movimentiEtichette =
      $MovimentiEtichetteTable(this);
  late final $ImpostazioniTable impostazioni = $ImpostazioniTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    definizioniTipo,
    portafogli,
    categorie,
    movimenti,
    etichette,
    movimentiEtichette,
    impostazioni,
  ];
}

typedef $$DefinizioniTipoTableCreateCompanionBuilder =
    DefinizioniTipoCompanion Function({
      required String id,
      required String aggiornatoIl,
      Value<bool> eliminato,
      required String ambito,
      required String nome,
      Value<String?> effetto,
      Value<String> schemaCampi,
      Value<int> versioneSchema,
      Value<bool> diSistema,
      Value<bool> archiviato,
      Value<int> ordine,
      Value<int> rowid,
    });
typedef $$DefinizioniTipoTableUpdateCompanionBuilder =
    DefinizioniTipoCompanion Function({
      Value<String> id,
      Value<String> aggiornatoIl,
      Value<bool> eliminato,
      Value<String> ambito,
      Value<String> nome,
      Value<String?> effetto,
      Value<String> schemaCampi,
      Value<int> versioneSchema,
      Value<bool> diSistema,
      Value<bool> archiviato,
      Value<int> ordine,
      Value<int> rowid,
    });

final class $$DefinizioniTipoTableReferences
    extends BaseReferences<_$Archivio, $DefinizioniTipoTable, DefinizioneTipo> {
  $$DefinizioniTipoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PortafogliTable, List<Portafoglio>>
  _portafogliRefsTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.portafogli,
    aliasName: 'definizioni_tipo__id__portafogli__tipo_id',
  );

  $$PortafogliTableProcessedTableManager get portafogliRefs {
    final manager = $$PortafogliTableTableManager(
      $_db,
      $_db.portafogli,
    ).filter((f) => f.tipoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_portafogliRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MovimentiTable, List<Movimento>>
  _movimentiRefsTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.movimenti,
    aliasName: 'definizioni_tipo__id__movimenti__tipo_id',
  );

  $$MovimentiTableProcessedTableManager get movimentiRefs {
    final manager = $$MovimentiTableTableManager(
      $_db,
      $_db.movimenti,
    ).filter((f) => f.tipoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movimentiRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DefinizioniTipoTableFilterComposer
    extends Composer<_$Archivio, $DefinizioniTipoTable> {
  $$DefinizioniTipoTableFilterComposer({
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

  ColumnFilters<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ambito => $composableBuilder(
    column: $table.ambito,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effetto => $composableBuilder(
    column: $table.effetto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schemaCampi => $composableBuilder(
    column: $table.schemaCampi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versioneSchema => $composableBuilder(
    column: $table.versioneSchema,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get diSistema => $composableBuilder(
    column: $table.diSistema,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archiviato => $composableBuilder(
    column: $table.archiviato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> portafogliRefs(
    Expression<bool> Function($$PortafogliTableFilterComposer f) f,
  ) {
    final $$PortafogliTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.portafogli,
      getReferencedColumn: (t) => t.tipoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PortafogliTableFilterComposer(
            $db: $db,
            $table: $db.portafogli,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> movimentiRefs(
    Expression<bool> Function($$MovimentiTableFilterComposer f) f,
  ) {
    final $$MovimentiTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.tipoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableFilterComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DefinizioniTipoTableOrderingComposer
    extends Composer<_$Archivio, $DefinizioniTipoTable> {
  $$DefinizioniTipoTableOrderingComposer({
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

  ColumnOrderings<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ambito => $composableBuilder(
    column: $table.ambito,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effetto => $composableBuilder(
    column: $table.effetto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schemaCampi => $composableBuilder(
    column: $table.schemaCampi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versioneSchema => $composableBuilder(
    column: $table.versioneSchema,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get diSistema => $composableBuilder(
    column: $table.diSistema,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archiviato => $composableBuilder(
    column: $table.archiviato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DefinizioniTipoTableAnnotationComposer
    extends Composer<_$Archivio, $DefinizioniTipoTable> {
  $$DefinizioniTipoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get eliminato =>
      $composableBuilder(column: $table.eliminato, builder: (column) => column);

  GeneratedColumn<String> get ambito =>
      $composableBuilder(column: $table.ambito, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get effetto =>
      $composableBuilder(column: $table.effetto, builder: (column) => column);

  GeneratedColumn<String> get schemaCampi => $composableBuilder(
    column: $table.schemaCampi,
    builder: (column) => column,
  );

  GeneratedColumn<int> get versioneSchema => $composableBuilder(
    column: $table.versioneSchema,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get diSistema =>
      $composableBuilder(column: $table.diSistema, builder: (column) => column);

  GeneratedColumn<bool> get archiviato => $composableBuilder(
    column: $table.archiviato,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordine =>
      $composableBuilder(column: $table.ordine, builder: (column) => column);

  Expression<T> portafogliRefs<T extends Object>(
    Expression<T> Function($$PortafogliTableAnnotationComposer a) f,
  ) {
    final $$PortafogliTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.portafogli,
      getReferencedColumn: (t) => t.tipoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PortafogliTableAnnotationComposer(
            $db: $db,
            $table: $db.portafogli,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> movimentiRefs<T extends Object>(
    Expression<T> Function($$MovimentiTableAnnotationComposer a) f,
  ) {
    final $$MovimentiTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.tipoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableAnnotationComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DefinizioniTipoTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $DefinizioniTipoTable,
          DefinizioneTipo,
          $$DefinizioniTipoTableFilterComposer,
          $$DefinizioniTipoTableOrderingComposer,
          $$DefinizioniTipoTableAnnotationComposer,
          $$DefinizioniTipoTableCreateCompanionBuilder,
          $$DefinizioniTipoTableUpdateCompanionBuilder,
          (DefinizioneTipo, $$DefinizioniTipoTableReferences),
          DefinizioneTipo,
          PrefetchHooks Function({bool portafogliRefs, bool movimentiRefs})
        > {
  $$DefinizioniTipoTableTableManager(_$Archivio db, $DefinizioniTipoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DefinizioniTipoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DefinizioniTipoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DefinizioniTipoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String> ambito = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String?> effetto = const Value.absent(),
                Value<String> schemaCampi = const Value.absent(),
                Value<int> versioneSchema = const Value.absent(),
                Value<bool> diSistema = const Value.absent(),
                Value<bool> archiviato = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DefinizioniTipoCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                ambito: ambito,
                nome: nome,
                effetto: effetto,
                schemaCampi: schemaCampi,
                versioneSchema: versioneSchema,
                diSistema: diSistema,
                archiviato: archiviato,
                ordine: ordine,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                required String ambito,
                required String nome,
                Value<String?> effetto = const Value.absent(),
                Value<String> schemaCampi = const Value.absent(),
                Value<int> versioneSchema = const Value.absent(),
                Value<bool> diSistema = const Value.absent(),
                Value<bool> archiviato = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DefinizioniTipoCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                ambito: ambito,
                nome: nome,
                effetto: effetto,
                schemaCampi: schemaCampi,
                versioneSchema: versioneSchema,
                diSistema: diSistema,
                archiviato: archiviato,
                ordine: ordine,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DefinizioniTipoTable, DefinizioneTipo>(table),
                  $$DefinizioniTipoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({portafogliRefs = false, movimentiRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (portafogliRefs) db.portafogli,
                    if (movimentiRefs) db.movimenti,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (portafogliRefs)
                        await $_getPrefetchedData<
                          DefinizioneTipo,
                          $DefinizioniTipoTable,
                          Portafoglio
                        >(
                          currentTable: table,
                          referencedTable: $$DefinizioniTipoTableReferences
                              ._portafogliRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DefinizioniTipoTableReferences(
                                db,
                                table,
                                p0,
                              ).portafogliRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tipoId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (movimentiRefs)
                        await $_getPrefetchedData<
                          DefinizioneTipo,
                          $DefinizioniTipoTable,
                          Movimento
                        >(
                          currentTable: table,
                          referencedTable: $$DefinizioniTipoTableReferences
                              ._movimentiRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DefinizioniTipoTableReferences(
                                db,
                                table,
                                p0,
                              ).movimentiRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tipoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DefinizioniTipoTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $DefinizioniTipoTable,
      DefinizioneTipo,
      $$DefinizioniTipoTableFilterComposer,
      $$DefinizioniTipoTableOrderingComposer,
      $$DefinizioniTipoTableAnnotationComposer,
      $$DefinizioniTipoTableCreateCompanionBuilder,
      $$DefinizioniTipoTableUpdateCompanionBuilder,
      (DefinizioneTipo, $$DefinizioniTipoTableReferences),
      DefinizioneTipo,
      PrefetchHooks Function({bool portafogliRefs, bool movimentiRefs})
    >;
typedef $$PortafogliTableCreateCompanionBuilder = PortafogliCompanion Function({
  required String id,
  required String aggiornatoIl,
  Value<bool> eliminato,
  required String tipoId,
  required String nome,
  required String valuta,
  Value<int> saldoInizialeMinimo,
  Value<String> campi,
  Value<bool> archiviato,
  Value<int> ordine,
  Value<int> rowid,
});
typedef $$PortafogliTableUpdateCompanionBuilder = PortafogliCompanion Function({
  Value<String> id,
  Value<String> aggiornatoIl,
  Value<bool> eliminato,
  Value<String> tipoId,
  Value<String> nome,
  Value<String> valuta,
  Value<int> saldoInizialeMinimo,
  Value<String> campi,
  Value<bool> archiviato,
  Value<int> ordine,
  Value<int> rowid,
});

final class $$PortafogliTableReferences
    extends BaseReferences<_$Archivio, $PortafogliTable, Portafoglio> {
  $$PortafogliTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DefinizioniTipoTable _tipoIdTable(_$Archivio db) => db.definizioniTipo
      .createAlias('portafogli__tipo_id__definizioni_tipo__id');

  $$DefinizioniTipoTableProcessedTableManager get tipoId {
    final $_column = $_itemColumn<String>('tipo_id')!;

    final manager = $$DefinizioniTipoTableTableManager(
      $_db,
      $_db.definizioniTipo,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tipoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MovimentiTable, List<Movimento>>
  _movimentiInUscitaTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.movimenti,
    aliasName: 'portafogli__id__movimenti__portafoglio_id',
  );

  $$MovimentiTableProcessedTableManager get movimentiInUscita {
    final manager = $$MovimentiTableTableManager(
      $_db,
      $_db.movimenti,
    ).filter((f) => f.portafoglioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movimentiInUscitaTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MovimentiTable, List<Movimento>>
  _movimentiInEntrataTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.movimenti,
    aliasName: 'portafogli__id__movimenti__portafoglio_destinazione_id',
  );

  $$MovimentiTableProcessedTableManager get movimentiInEntrata {
    final manager = $$MovimentiTableTableManager($_db, $_db.movimenti).filter(
      (f) =>
          f.portafoglioDestinazioneId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_movimentiInEntrataTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PortafogliTableFilterComposer
    extends Composer<_$Archivio, $PortafogliTable> {
  $$PortafogliTableFilterComposer({
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

  ColumnFilters<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valuta => $composableBuilder(
    column: $table.valuta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saldoInizialeMinimo => $composableBuilder(
    column: $table.saldoInizialeMinimo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get campi => $composableBuilder(
    column: $table.campi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archiviato => $composableBuilder(
    column: $table.archiviato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnFilters(column),
  );

  $$DefinizioniTipoTableFilterComposer get tipoId {
    final $$DefinizioniTipoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoId,
      referencedTable: $db.definizioniTipo,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DefinizioniTipoTableFilterComposer(
            $db: $db,
            $table: $db.definizioniTipo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> movimentiInUscita(
    Expression<bool> Function($$MovimentiTableFilterComposer f) f,
  ) {
    final $$MovimentiTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.portafoglioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableFilterComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> movimentiInEntrata(
    Expression<bool> Function($$MovimentiTableFilterComposer f) f,
  ) {
    final $$MovimentiTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.portafoglioDestinazioneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableFilterComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PortafogliTableOrderingComposer
    extends Composer<_$Archivio, $PortafogliTable> {
  $$PortafogliTableOrderingComposer({
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

  ColumnOrderings<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valuta => $composableBuilder(
    column: $table.valuta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saldoInizialeMinimo => $composableBuilder(
    column: $table.saldoInizialeMinimo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get campi => $composableBuilder(
    column: $table.campi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archiviato => $composableBuilder(
    column: $table.archiviato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnOrderings(column),
  );

  $$DefinizioniTipoTableOrderingComposer get tipoId {
    final $$DefinizioniTipoTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoId,
      referencedTable: $db.definizioniTipo,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DefinizioniTipoTableOrderingComposer(
            $db: $db,
            $table: $db.definizioniTipo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PortafogliTableAnnotationComposer
    extends Composer<_$Archivio, $PortafogliTable> {
  $$PortafogliTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get eliminato =>
      $composableBuilder(column: $table.eliminato, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get valuta =>
      $composableBuilder(column: $table.valuta, builder: (column) => column);

  GeneratedColumn<int> get saldoInizialeMinimo => $composableBuilder(
    column: $table.saldoInizialeMinimo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get campi =>
      $composableBuilder(column: $table.campi, builder: (column) => column);

  GeneratedColumn<bool> get archiviato => $composableBuilder(
    column: $table.archiviato,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordine =>
      $composableBuilder(column: $table.ordine, builder: (column) => column);

  $$DefinizioniTipoTableAnnotationComposer get tipoId {
    final $$DefinizioniTipoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoId,
      referencedTable: $db.definizioniTipo,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DefinizioniTipoTableAnnotationComposer(
            $db: $db,
            $table: $db.definizioniTipo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> movimentiInUscita<T extends Object>(
    Expression<T> Function($$MovimentiTableAnnotationComposer a) f,
  ) {
    final $$MovimentiTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.portafoglioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableAnnotationComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> movimentiInEntrata<T extends Object>(
    Expression<T> Function($$MovimentiTableAnnotationComposer a) f,
  ) {
    final $$MovimentiTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.portafoglioDestinazioneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableAnnotationComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PortafogliTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $PortafogliTable,
          Portafoglio,
          $$PortafogliTableFilterComposer,
          $$PortafogliTableOrderingComposer,
          $$PortafogliTableAnnotationComposer,
          $$PortafogliTableCreateCompanionBuilder,
          $$PortafogliTableUpdateCompanionBuilder,
          (Portafoglio, $$PortafogliTableReferences),
          Portafoglio,
          PrefetchHooks Function({
            bool tipoId,
            bool movimentiInUscita,
            bool movimentiInEntrata,
          })
        > {
  $$PortafogliTableTableManager(_$Archivio db, $PortafogliTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PortafogliTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PortafogliTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PortafogliTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String> tipoId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> valuta = const Value.absent(),
                Value<int> saldoInizialeMinimo = const Value.absent(),
                Value<String> campi = const Value.absent(),
                Value<bool> archiviato = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PortafogliCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                tipoId: tipoId,
                nome: nome,
                valuta: valuta,
                saldoInizialeMinimo: saldoInizialeMinimo,
                campi: campi,
                archiviato: archiviato,
                ordine: ordine,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                required String tipoId,
                required String nome,
                required String valuta,
                Value<int> saldoInizialeMinimo = const Value.absent(),
                Value<String> campi = const Value.absent(),
                Value<bool> archiviato = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PortafogliCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                tipoId: tipoId,
                nome: nome,
                valuta: valuta,
                saldoInizialeMinimo: saldoInizialeMinimo,
                campi: campi,
                archiviato: archiviato,
                ordine: ordine,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PortafogliTable, Portafoglio>(table),
                  $$PortafogliTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tipoId = false,
                movimentiInUscita = false,
                movimentiInEntrata = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movimentiInUscita) db.movimenti,
                    if (movimentiInEntrata) db.movimenti,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tipoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tipoId,
                            referencedTable: $$PortafogliTableReferences
                                ._tipoIdTable(db),
                            referencedColumn: $$PortafogliTableReferences
                                ._tipoIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movimentiInUscita)
                        await $_getPrefetchedData<
                          Portafoglio,
                          $PortafogliTable,
                          Movimento
                        >(
                          currentTable: table,
                          referencedTable: $$PortafogliTableReferences
                              ._movimentiInUscitaTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PortafogliTableReferences(
                                db,
                                table,
                                p0,
                              ).movimentiInUscita,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.portafoglioId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (movimentiInEntrata)
                        await $_getPrefetchedData<
                          Portafoglio,
                          $PortafogliTable,
                          Movimento
                        >(
                          currentTable: table,
                          referencedTable: $$PortafogliTableReferences
                              ._movimentiInEntrataTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PortafogliTableReferences(
                                db,
                                table,
                                p0,
                              ).movimentiInEntrata,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.portafoglioDestinazioneId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PortafogliTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $PortafogliTable,
      Portafoglio,
      $$PortafogliTableFilterComposer,
      $$PortafogliTableOrderingComposer,
      $$PortafogliTableAnnotationComposer,
      $$PortafogliTableCreateCompanionBuilder,
      $$PortafogliTableUpdateCompanionBuilder,
      (Portafoglio, $$PortafogliTableReferences),
      Portafoglio,
      PrefetchHooks Function({
        bool tipoId,
        bool movimentiInUscita,
        bool movimentiInEntrata,
      })
    >;
typedef $$CategorieTableCreateCompanionBuilder = CategorieCompanion Function({
  required String id,
  required String aggiornatoIl,
  Value<bool> eliminato,
  Value<String?> padreId,
  required String nome,
  Value<String?> icona,
  Value<int?> colore,
  Value<bool> archiviata,
  Value<int> ordine,
  Value<int> rowid,
});
typedef $$CategorieTableUpdateCompanionBuilder = CategorieCompanion Function({
  Value<String> id,
  Value<String> aggiornatoIl,
  Value<bool> eliminato,
  Value<String?> padreId,
  Value<String> nome,
  Value<String?> icona,
  Value<int?> colore,
  Value<bool> archiviata,
  Value<int> ordine,
  Value<int> rowid,
});

final class $$CategorieTableReferences
    extends BaseReferences<_$Archivio, $CategorieTable, Categoria> {
  $$CategorieTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategorieTable _padreIdTable(_$Archivio db) =>
      db.categorie.createAlias('categorie__padre_id__categorie__id');

  $$CategorieTableProcessedTableManager? get padreId {
    final $_column = $_itemColumn<String>('padre_id');
    if ($_column == null) return null;
    final manager = $$CategorieTableTableManager(
      $_db,
      $_db.categorie,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_padreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MovimentiTable, List<Movimento>>
  _movimentiRefsTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.movimenti,
    aliasName: 'categorie__id__movimenti__categoria_id',
  );

  $$MovimentiTableProcessedTableManager get movimentiRefs {
    final manager = $$MovimentiTableTableManager(
      $_db,
      $_db.movimenti,
    ).filter((f) => f.categoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_movimentiRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategorieTableFilterComposer
    extends Composer<_$Archivio, $CategorieTable> {
  $$CategorieTableFilterComposer({
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

  ColumnFilters<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icona => $composableBuilder(
    column: $table.icona,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colore => $composableBuilder(
    column: $table.colore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archiviata => $composableBuilder(
    column: $table.archiviata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnFilters(column),
  );

  $$CategorieTableFilterComposer get padreId {
    final $$CategorieTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.padreId,
      referencedTable: $db.categorie,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategorieTableFilterComposer(
            $db: $db,
            $table: $db.categorie,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> movimentiRefs(
    Expression<bool> Function($$MovimentiTableFilterComposer f) f,
  ) {
    final $$MovimentiTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableFilterComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategorieTableOrderingComposer
    extends Composer<_$Archivio, $CategorieTable> {
  $$CategorieTableOrderingComposer({
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

  ColumnOrderings<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icona => $composableBuilder(
    column: $table.icona,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colore => $composableBuilder(
    column: $table.colore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archiviata => $composableBuilder(
    column: $table.archiviata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordine => $composableBuilder(
    column: $table.ordine,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategorieTableOrderingComposer get padreId {
    final $$CategorieTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.padreId,
      referencedTable: $db.categorie,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategorieTableOrderingComposer(
            $db: $db,
            $table: $db.categorie,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategorieTableAnnotationComposer
    extends Composer<_$Archivio, $CategorieTable> {
  $$CategorieTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get eliminato =>
      $composableBuilder(column: $table.eliminato, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get icona =>
      $composableBuilder(column: $table.icona, builder: (column) => column);

  GeneratedColumn<int> get colore =>
      $composableBuilder(column: $table.colore, builder: (column) => column);

  GeneratedColumn<bool> get archiviata => $composableBuilder(
    column: $table.archiviata,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordine =>
      $composableBuilder(column: $table.ordine, builder: (column) => column);

  $$CategorieTableAnnotationComposer get padreId {
    final $$CategorieTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.padreId,
      referencedTable: $db.categorie,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategorieTableAnnotationComposer(
            $db: $db,
            $table: $db.categorie,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> movimentiRefs<T extends Object>(
    Expression<T> Function($$MovimentiTableAnnotationComposer a) f,
  ) {
    final $$MovimentiTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableAnnotationComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategorieTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $CategorieTable,
          Categoria,
          $$CategorieTableFilterComposer,
          $$CategorieTableOrderingComposer,
          $$CategorieTableAnnotationComposer,
          $$CategorieTableCreateCompanionBuilder,
          $$CategorieTableUpdateCompanionBuilder,
          (Categoria, $$CategorieTableReferences),
          Categoria,
          PrefetchHooks Function({bool padreId, bool movimentiRefs})
        > {
  $$CategorieTableTableManager(_$Archivio db, $CategorieTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategorieTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategorieTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategorieTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String?> padreId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String?> icona = const Value.absent(),
                Value<int?> colore = const Value.absent(),
                Value<bool> archiviata = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategorieCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                padreId: padreId,
                nome: nome,
                icona: icona,
                colore: colore,
                archiviata: archiviata,
                ordine: ordine,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                Value<String?> padreId = const Value.absent(),
                required String nome,
                Value<String?> icona = const Value.absent(),
                Value<int?> colore = const Value.absent(),
                Value<bool> archiviata = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategorieCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                padreId: padreId,
                nome: nome,
                icona: icona,
                colore: colore,
                archiviata: archiviata,
                ordine: ordine,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategorieTable, Categoria>(table),
                  $$CategorieTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({padreId = false, movimentiRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (movimentiRefs) db.movimenti],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (padreId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.padreId,
                        referencedTable: $$CategorieTableReferences
                            ._padreIdTable(db),
                        referencedColumn: $$CategorieTableReferences
                            ._padreIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (movimentiRefs)
                    await $_getPrefetchedData<
                      Categoria,
                      $CategorieTable,
                      Movimento
                    >(
                      currentTable: table,
                      referencedTable: $$CategorieTableReferences
                          ._movimentiRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategorieTableReferences(
                            db,
                            table,
                            p0,
                          ).movimentiRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.categoriaId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategorieTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $CategorieTable,
      Categoria,
      $$CategorieTableFilterComposer,
      $$CategorieTableOrderingComposer,
      $$CategorieTableAnnotationComposer,
      $$CategorieTableCreateCompanionBuilder,
      $$CategorieTableUpdateCompanionBuilder,
      (Categoria, $$CategorieTableReferences),
      Categoria,
      PrefetchHooks Function({bool padreId, bool movimentiRefs})
    >;
typedef $$MovimentiTableCreateCompanionBuilder = MovimentiCompanion Function({
  required String id,
  required String aggiornatoIl,
  Value<bool> eliminato,
  required String tipoId,
  required String portafoglioId,
  Value<String?> portafoglioDestinazioneId,
  Value<String?> categoriaId,
  required int importoMinimo,
  required String valuta,
  required String data,
  Value<String> descrizione,
  Value<String> campi,
  Value<int> rowid,
});
typedef $$MovimentiTableUpdateCompanionBuilder = MovimentiCompanion Function({
  Value<String> id,
  Value<String> aggiornatoIl,
  Value<bool> eliminato,
  Value<String> tipoId,
  Value<String> portafoglioId,
  Value<String?> portafoglioDestinazioneId,
  Value<String?> categoriaId,
  Value<int> importoMinimo,
  Value<String> valuta,
  Value<String> data,
  Value<String> descrizione,
  Value<String> campi,
  Value<int> rowid,
});

final class $$MovimentiTableReferences
    extends BaseReferences<_$Archivio, $MovimentiTable, Movimento> {
  $$MovimentiTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DefinizioniTipoTable _tipoIdTable(_$Archivio db) => db.definizioniTipo
      .createAlias('movimenti__tipo_id__definizioni_tipo__id');

  $$DefinizioniTipoTableProcessedTableManager get tipoId {
    final $_column = $_itemColumn<String>('tipo_id')!;

    final manager = $$DefinizioniTipoTableTableManager(
      $_db,
      $_db.definizioniTipo,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tipoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PortafogliTable _portafoglioIdTable(_$Archivio db) =>
      db.portafogli.createAlias('movimenti__portafoglio_id__portafogli__id');

  $$PortafogliTableProcessedTableManager get portafoglioId {
    final $_column = $_itemColumn<String>('portafoglio_id')!;

    final manager = $$PortafogliTableTableManager(
      $_db,
      $_db.portafogli,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_portafoglioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PortafogliTable _portafoglioDestinazioneIdTable(_$Archivio db) => db
      .portafogli
      .createAlias('movimenti__portafoglio_destinazione_id__portafogli__id');

  $$PortafogliTableProcessedTableManager? get portafoglioDestinazioneId {
    final $_column = $_itemColumn<String>('portafoglio_destinazione_id');
    if ($_column == null) return null;
    final manager = $$PortafogliTableTableManager(
      $_db,
      $_db.portafogli,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _portafoglioDestinazioneIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategorieTable _categoriaIdTable(_$Archivio db) =>
      db.categorie.createAlias('movimenti__categoria_id__categorie__id');

  $$CategorieTableProcessedTableManager? get categoriaId {
    final $_column = $_itemColumn<String>('categoria_id');
    if ($_column == null) return null;
    final manager = $$CategorieTableTableManager(
      $_db,
      $_db.categorie,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MovimentiEtichetteTable, List<MovimentoEtichetta>>
  _movimentiEtichetteRefsTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.movimentiEtichette,
    aliasName: 'movimenti__id__movimenti_etichette__movimento_id',
  );

  $$MovimentiEtichetteTableProcessedTableManager get movimentiEtichetteRefs {
    final manager = $$MovimentiEtichetteTableTableManager(
      $_db,
      $_db.movimentiEtichette,
    ).filter((f) => f.movimentoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _movimentiEtichetteRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MovimentiTableFilterComposer
    extends Composer<_$Archivio, $MovimentiTable> {
  $$MovimentiTableFilterComposer({
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

  ColumnFilters<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importoMinimo => $composableBuilder(
    column: $table.importoMinimo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valuta => $composableBuilder(
    column: $table.valuta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get campi => $composableBuilder(
    column: $table.campi,
    builder: (column) => ColumnFilters(column),
  );

  $$DefinizioniTipoTableFilterComposer get tipoId {
    final $$DefinizioniTipoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoId,
      referencedTable: $db.definizioniTipo,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DefinizioniTipoTableFilterComposer(
            $db: $db,
            $table: $db.definizioniTipo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PortafogliTableFilterComposer get portafoglioId {
    final $$PortafogliTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portafoglioId,
      referencedTable: $db.portafogli,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PortafogliTableFilterComposer(
            $db: $db,
            $table: $db.portafogli,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PortafogliTableFilterComposer get portafoglioDestinazioneId {
    final $$PortafogliTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portafoglioDestinazioneId,
      referencedTable: $db.portafogli,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PortafogliTableFilterComposer(
            $db: $db,
            $table: $db.portafogli,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategorieTableFilterComposer get categoriaId {
    final $$CategorieTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorie,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategorieTableFilterComposer(
            $db: $db,
            $table: $db.categorie,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> movimentiEtichetteRefs(
    Expression<bool> Function($$MovimentiEtichetteTableFilterComposer f) f,
  ) {
    final $$MovimentiEtichetteTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimentiEtichette,
      getReferencedColumn: (t) => t.movimentoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiEtichetteTableFilterComposer(
            $db: $db,
            $table: $db.movimentiEtichette,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MovimentiTableOrderingComposer
    extends Composer<_$Archivio, $MovimentiTable> {
  $$MovimentiTableOrderingComposer({
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

  ColumnOrderings<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importoMinimo => $composableBuilder(
    column: $table.importoMinimo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valuta => $composableBuilder(
    column: $table.valuta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get campi => $composableBuilder(
    column: $table.campi,
    builder: (column) => ColumnOrderings(column),
  );

  $$DefinizioniTipoTableOrderingComposer get tipoId {
    final $$DefinizioniTipoTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoId,
      referencedTable: $db.definizioniTipo,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DefinizioniTipoTableOrderingComposer(
            $db: $db,
            $table: $db.definizioniTipo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PortafogliTableOrderingComposer get portafoglioId {
    final $$PortafogliTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portafoglioId,
      referencedTable: $db.portafogli,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PortafogliTableOrderingComposer(
            $db: $db,
            $table: $db.portafogli,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PortafogliTableOrderingComposer get portafoglioDestinazioneId {
    final $$PortafogliTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portafoglioDestinazioneId,
      referencedTable: $db.portafogli,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PortafogliTableOrderingComposer(
            $db: $db,
            $table: $db.portafogli,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategorieTableOrderingComposer get categoriaId {
    final $$CategorieTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorie,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategorieTableOrderingComposer(
            $db: $db,
            $table: $db.categorie,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimentiTableAnnotationComposer
    extends Composer<_$Archivio, $MovimentiTable> {
  $$MovimentiTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get eliminato =>
      $composableBuilder(column: $table.eliminato, builder: (column) => column);

  GeneratedColumn<int> get importoMinimo => $composableBuilder(
    column: $table.importoMinimo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valuta =>
      $composableBuilder(column: $table.valuta, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
    builder: (column) => column,
  );

  GeneratedColumn<String> get campi =>
      $composableBuilder(column: $table.campi, builder: (column) => column);

  $$DefinizioniTipoTableAnnotationComposer get tipoId {
    final $$DefinizioniTipoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tipoId,
      referencedTable: $db.definizioniTipo,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DefinizioniTipoTableAnnotationComposer(
            $db: $db,
            $table: $db.definizioniTipo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PortafogliTableAnnotationComposer get portafoglioId {
    final $$PortafogliTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portafoglioId,
      referencedTable: $db.portafogli,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PortafogliTableAnnotationComposer(
            $db: $db,
            $table: $db.portafogli,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PortafogliTableAnnotationComposer get portafoglioDestinazioneId {
    final $$PortafogliTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portafoglioDestinazioneId,
      referencedTable: $db.portafogli,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PortafogliTableAnnotationComposer(
            $db: $db,
            $table: $db.portafogli,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategorieTableAnnotationComposer get categoriaId {
    final $$CategorieTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoriaId,
      referencedTable: $db.categorie,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategorieTableAnnotationComposer(
            $db: $db,
            $table: $db.categorie,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> movimentiEtichetteRefs<T extends Object>(
    Expression<T> Function($$MovimentiEtichetteTableAnnotationComposer a) f,
  ) {
    final $$MovimentiEtichetteTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.movimentiEtichette,
          getReferencedColumn: (t) => t.movimentoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MovimentiEtichetteTableAnnotationComposer(
                $db: $db,
                $table: $db.movimentiEtichette,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MovimentiTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $MovimentiTable,
          Movimento,
          $$MovimentiTableFilterComposer,
          $$MovimentiTableOrderingComposer,
          $$MovimentiTableAnnotationComposer,
          $$MovimentiTableCreateCompanionBuilder,
          $$MovimentiTableUpdateCompanionBuilder,
          (Movimento, $$MovimentiTableReferences),
          Movimento,
          PrefetchHooks Function({
            bool tipoId,
            bool portafoglioId,
            bool portafoglioDestinazioneId,
            bool categoriaId,
            bool movimentiEtichetteRefs,
          })
        > {
  $$MovimentiTableTableManager(_$Archivio db, $MovimentiTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimentiTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovimentiTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovimentiTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String> tipoId = const Value.absent(),
                Value<String> portafoglioId = const Value.absent(),
                Value<String?> portafoglioDestinazioneId = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                Value<int> importoMinimo = const Value.absent(),
                Value<String> valuta = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<String> descrizione = const Value.absent(),
                Value<String> campi = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimentiCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                tipoId: tipoId,
                portafoglioId: portafoglioId,
                portafoglioDestinazioneId: portafoglioDestinazioneId,
                categoriaId: categoriaId,
                importoMinimo: importoMinimo,
                valuta: valuta,
                data: data,
                descrizione: descrizione,
                campi: campi,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                required String tipoId,
                required String portafoglioId,
                Value<String?> portafoglioDestinazioneId = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                required int importoMinimo,
                required String valuta,
                required String data,
                Value<String> descrizione = const Value.absent(),
                Value<String> campi = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimentiCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                tipoId: tipoId,
                portafoglioId: portafoglioId,
                portafoglioDestinazioneId: portafoglioDestinazioneId,
                categoriaId: categoriaId,
                importoMinimo: importoMinimo,
                valuta: valuta,
                data: data,
                descrizione: descrizione,
                campi: campi,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MovimentiTable, Movimento>(table),
                  $$MovimentiTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tipoId = false,
                portafoglioId = false,
                portafoglioDestinazioneId = false,
                categoriaId = false,
                movimentiEtichetteRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movimentiEtichetteRefs) db.movimentiEtichette,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tipoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tipoId,
                            referencedTable: $$MovimentiTableReferences
                                ._tipoIdTable(db),
                            referencedColumn: $$MovimentiTableReferences
                                ._tipoIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (portafoglioId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.portafoglioId,
                            referencedTable: $$MovimentiTableReferences
                                ._portafoglioIdTable(db),
                            referencedColumn: $$MovimentiTableReferences
                                ._portafoglioIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (portafoglioDestinazioneId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.portafoglioDestinazioneId,
                            referencedTable: $$MovimentiTableReferences
                                ._portafoglioDestinazioneIdTable(db),
                            referencedColumn: $$MovimentiTableReferences
                                ._portafoglioDestinazioneIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (categoriaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoriaId,
                            referencedTable: $$MovimentiTableReferences
                                ._categoriaIdTable(db),
                            referencedColumn: $$MovimentiTableReferences
                                ._categoriaIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movimentiEtichetteRefs)
                        await $_getPrefetchedData<
                          Movimento,
                          $MovimentiTable,
                          MovimentoEtichetta
                        >(
                          currentTable: table,
                          referencedTable: $$MovimentiTableReferences
                              ._movimentiEtichetteRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovimentiTableReferences(
                                db,
                                table,
                                p0,
                              ).movimentiEtichetteRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.movimentoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MovimentiTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $MovimentiTable,
      Movimento,
      $$MovimentiTableFilterComposer,
      $$MovimentiTableOrderingComposer,
      $$MovimentiTableAnnotationComposer,
      $$MovimentiTableCreateCompanionBuilder,
      $$MovimentiTableUpdateCompanionBuilder,
      (Movimento, $$MovimentiTableReferences),
      Movimento,
      PrefetchHooks Function({
        bool tipoId,
        bool portafoglioId,
        bool portafoglioDestinazioneId,
        bool categoriaId,
        bool movimentiEtichetteRefs,
      })
    >;
typedef $$EtichetteTableCreateCompanionBuilder = EtichetteCompanion Function({
  required String id,
  required String aggiornatoIl,
  Value<bool> eliminato,
  Value<String?> padreId,
  required String nome,
  Value<int> rowid,
});
typedef $$EtichetteTableUpdateCompanionBuilder = EtichetteCompanion Function({
  Value<String> id,
  Value<String> aggiornatoIl,
  Value<bool> eliminato,
  Value<String?> padreId,
  Value<String> nome,
  Value<int> rowid,
});

final class $$EtichetteTableReferences
    extends BaseReferences<_$Archivio, $EtichetteTable, Etichetta> {
  $$EtichetteTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EtichetteTable _padreIdTable(_$Archivio db) =>
      db.etichette.createAlias('etichette__padre_id__etichette__id');

  $$EtichetteTableProcessedTableManager? get padreId {
    final $_column = $_itemColumn<String>('padre_id');
    if ($_column == null) return null;
    final manager = $$EtichetteTableTableManager(
      $_db,
      $_db.etichette,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_padreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MovimentiEtichetteTable, List<MovimentoEtichetta>>
  _movimentiEtichetteRefsTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.movimentiEtichette,
    aliasName: 'etichette__id__movimenti_etichette__etichetta_id',
  );

  $$MovimentiEtichetteTableProcessedTableManager get movimentiEtichetteRefs {
    final manager = $$MovimentiEtichetteTableTableManager(
      $_db,
      $_db.movimentiEtichette,
    ).filter((f) => f.etichettaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _movimentiEtichetteRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EtichetteTableFilterComposer
    extends Composer<_$Archivio, $EtichetteTable> {
  $$EtichetteTableFilterComposer({
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

  ColumnFilters<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  $$EtichetteTableFilterComposer get padreId {
    final $$EtichetteTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.padreId,
      referencedTable: $db.etichette,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EtichetteTableFilterComposer(
            $db: $db,
            $table: $db.etichette,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> movimentiEtichetteRefs(
    Expression<bool> Function($$MovimentiEtichetteTableFilterComposer f) f,
  ) {
    final $$MovimentiEtichetteTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimentiEtichette,
      getReferencedColumn: (t) => t.etichettaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiEtichetteTableFilterComposer(
            $db: $db,
            $table: $db.movimentiEtichette,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EtichetteTableOrderingComposer
    extends Composer<_$Archivio, $EtichetteTable> {
  $$EtichetteTableOrderingComposer({
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

  ColumnOrderings<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  $$EtichetteTableOrderingComposer get padreId {
    final $$EtichetteTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.padreId,
      referencedTable: $db.etichette,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EtichetteTableOrderingComposer(
            $db: $db,
            $table: $db.etichette,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EtichetteTableAnnotationComposer
    extends Composer<_$Archivio, $EtichetteTable> {
  $$EtichetteTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get eliminato =>
      $composableBuilder(column: $table.eliminato, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  $$EtichetteTableAnnotationComposer get padreId {
    final $$EtichetteTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.padreId,
      referencedTable: $db.etichette,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EtichetteTableAnnotationComposer(
            $db: $db,
            $table: $db.etichette,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> movimentiEtichetteRefs<T extends Object>(
    Expression<T> Function($$MovimentiEtichetteTableAnnotationComposer a) f,
  ) {
    final $$MovimentiEtichetteTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.movimentiEtichette,
          getReferencedColumn: (t) => t.etichettaId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MovimentiEtichetteTableAnnotationComposer(
                $db: $db,
                $table: $db.movimentiEtichette,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EtichetteTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $EtichetteTable,
          Etichetta,
          $$EtichetteTableFilterComposer,
          $$EtichetteTableOrderingComposer,
          $$EtichetteTableAnnotationComposer,
          $$EtichetteTableCreateCompanionBuilder,
          $$EtichetteTableUpdateCompanionBuilder,
          (Etichetta, $$EtichetteTableReferences),
          Etichetta,
          PrefetchHooks Function({bool padreId, bool movimentiEtichetteRefs})
        > {
  $$EtichetteTableTableManager(_$Archivio db, $EtichetteTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EtichetteTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EtichetteTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EtichetteTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String?> padreId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EtichetteCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                padreId: padreId,
                nome: nome,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                Value<String?> padreId = const Value.absent(),
                required String nome,
                Value<int> rowid = const Value.absent(),
              }) => EtichetteCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                padreId: padreId,
                nome: nome,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EtichetteTable, Etichetta>(table),
                  $$EtichetteTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({padreId = false, movimentiEtichetteRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movimentiEtichetteRefs) db.movimentiEtichette,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (padreId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.padreId,
                            referencedTable: $$EtichetteTableReferences
                                ._padreIdTable(db),
                            referencedColumn: $$EtichetteTableReferences
                                ._padreIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movimentiEtichetteRefs)
                        await $_getPrefetchedData<
                          Etichetta,
                          $EtichetteTable,
                          MovimentoEtichetta
                        >(
                          currentTable: table,
                          referencedTable: $$EtichetteTableReferences
                              ._movimentiEtichetteRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EtichetteTableReferences(
                                db,
                                table,
                                p0,
                              ).movimentiEtichetteRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.etichettaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EtichetteTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $EtichetteTable,
      Etichetta,
      $$EtichetteTableFilterComposer,
      $$EtichetteTableOrderingComposer,
      $$EtichetteTableAnnotationComposer,
      $$EtichetteTableCreateCompanionBuilder,
      $$EtichetteTableUpdateCompanionBuilder,
      (Etichetta, $$EtichetteTableReferences),
      Etichetta,
      PrefetchHooks Function({bool padreId, bool movimentiEtichetteRefs})
    >;
typedef $$MovimentiEtichetteTableCreateCompanionBuilder =
    MovimentiEtichetteCompanion Function({
      required String id,
      required String aggiornatoIl,
      Value<bool> eliminato,
      required String movimentoId,
      required String etichettaId,
      Value<int> rowid,
    });
typedef $$MovimentiEtichetteTableUpdateCompanionBuilder =
    MovimentiEtichetteCompanion Function({
      Value<String> id,
      Value<String> aggiornatoIl,
      Value<bool> eliminato,
      Value<String> movimentoId,
      Value<String> etichettaId,
      Value<int> rowid,
    });

final class $$MovimentiEtichetteTableReferences
    extends
        BaseReferences<
          _$Archivio,
          $MovimentiEtichetteTable,
          MovimentoEtichetta
        > {
  $$MovimentiEtichetteTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MovimentiTable _movimentoIdTable(_$Archivio db) => db.movimenti
      .createAlias('movimenti_etichette__movimento_id__movimenti__id');

  $$MovimentiTableProcessedTableManager get movimentoId {
    final $_column = $_itemColumn<String>('movimento_id')!;

    final manager = $$MovimentiTableTableManager(
      $_db,
      $_db.movimenti,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_movimentoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EtichetteTable _etichettaIdTable(_$Archivio db) => db.etichette
      .createAlias('movimenti_etichette__etichetta_id__etichette__id');

  $$EtichetteTableProcessedTableManager get etichettaId {
    final $_column = $_itemColumn<String>('etichetta_id')!;

    final manager = $$EtichetteTableTableManager(
      $_db,
      $_db.etichette,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_etichettaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MovimentiEtichetteTableFilterComposer
    extends Composer<_$Archivio, $MovimentiEtichetteTable> {
  $$MovimentiEtichetteTableFilterComposer({
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

  ColumnFilters<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnFilters(column),
  );

  $$MovimentiTableFilterComposer get movimentoId {
    final $$MovimentiTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movimentoId,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableFilterComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EtichetteTableFilterComposer get etichettaId {
    final $$EtichetteTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.etichettaId,
      referencedTable: $db.etichette,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EtichetteTableFilterComposer(
            $db: $db,
            $table: $db.etichette,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimentiEtichetteTableOrderingComposer
    extends Composer<_$Archivio, $MovimentiEtichetteTable> {
  $$MovimentiEtichetteTableOrderingComposer({
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

  ColumnOrderings<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eliminato => $composableBuilder(
    column: $table.eliminato,
    builder: (column) => ColumnOrderings(column),
  );

  $$MovimentiTableOrderingComposer get movimentoId {
    final $$MovimentiTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movimentoId,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableOrderingComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EtichetteTableOrderingComposer get etichettaId {
    final $$EtichetteTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.etichettaId,
      referencedTable: $db.etichette,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EtichetteTableOrderingComposer(
            $db: $db,
            $table: $db.etichette,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimentiEtichetteTableAnnotationComposer
    extends Composer<_$Archivio, $MovimentiEtichetteTable> {
  $$MovimentiEtichetteTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get aggiornatoIl => $composableBuilder(
    column: $table.aggiornatoIl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get eliminato =>
      $composableBuilder(column: $table.eliminato, builder: (column) => column);

  $$MovimentiTableAnnotationComposer get movimentoId {
    final $$MovimentiTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movimentoId,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimentiTableAnnotationComposer(
            $db: $db,
            $table: $db.movimenti,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EtichetteTableAnnotationComposer get etichettaId {
    final $$EtichetteTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.etichettaId,
      referencedTable: $db.etichette,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EtichetteTableAnnotationComposer(
            $db: $db,
            $table: $db.etichette,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimentiEtichetteTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $MovimentiEtichetteTable,
          MovimentoEtichetta,
          $$MovimentiEtichetteTableFilterComposer,
          $$MovimentiEtichetteTableOrderingComposer,
          $$MovimentiEtichetteTableAnnotationComposer,
          $$MovimentiEtichetteTableCreateCompanionBuilder,
          $$MovimentiEtichetteTableUpdateCompanionBuilder,
          (MovimentoEtichetta, $$MovimentiEtichetteTableReferences),
          MovimentoEtichetta,
          PrefetchHooks Function({bool movimentoId, bool etichettaId})
        > {
  $$MovimentiEtichetteTableTableManager(
    _$Archivio db,
    $MovimentiEtichetteTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimentiEtichetteTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovimentiEtichetteTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovimentiEtichetteTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String> movimentoId = const Value.absent(),
                Value<String> etichettaId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimentiEtichetteCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                movimentoId: movimentoId,
                etichettaId: etichettaId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                required String movimentoId,
                required String etichettaId,
                Value<int> rowid = const Value.absent(),
              }) => MovimentiEtichetteCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                movimentoId: movimentoId,
                etichettaId: etichettaId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MovimentiEtichetteTable, MovimentoEtichetta>(
                    table,
                  ),
                  $$MovimentiEtichetteTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({movimentoId = false, etichettaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (movimentoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.movimentoId,
                        referencedTable: $$MovimentiEtichetteTableReferences
                            ._movimentoIdTable(db),
                        referencedColumn: $$MovimentiEtichetteTableReferences
                            ._movimentoIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (etichettaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.etichettaId,
                        referencedTable: $$MovimentiEtichetteTableReferences
                            ._etichettaIdTable(db),
                        referencedColumn: $$MovimentiEtichetteTableReferences
                            ._etichettaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MovimentiEtichetteTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $MovimentiEtichetteTable,
      MovimentoEtichetta,
      $$MovimentiEtichetteTableFilterComposer,
      $$MovimentiEtichetteTableOrderingComposer,
      $$MovimentiEtichetteTableAnnotationComposer,
      $$MovimentiEtichetteTableCreateCompanionBuilder,
      $$MovimentiEtichetteTableUpdateCompanionBuilder,
      (MovimentoEtichetta, $$MovimentiEtichetteTableReferences),
      MovimentoEtichetta,
      PrefetchHooks Function({bool movimentoId, bool etichettaId})
    >;
typedef $$ImpostazioniTableCreateCompanionBuilder =
    ImpostazioniCompanion Function({
      required String chiave,
      required String valore,
      Value<int> rowid,
    });
typedef $$ImpostazioniTableUpdateCompanionBuilder =
    ImpostazioniCompanion Function({
      Value<String> chiave,
      Value<String> valore,
      Value<int> rowid,
    });

class $$ImpostazioniTableFilterComposer
    extends Composer<_$Archivio, $ImpostazioniTable> {
  $$ImpostazioniTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chiave => $composableBuilder(
    column: $table.chiave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valore => $composableBuilder(
    column: $table.valore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImpostazioniTableOrderingComposer
    extends Composer<_$Archivio, $ImpostazioniTable> {
  $$ImpostazioniTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chiave => $composableBuilder(
    column: $table.chiave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valore => $composableBuilder(
    column: $table.valore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImpostazioniTableAnnotationComposer
    extends Composer<_$Archivio, $ImpostazioniTable> {
  $$ImpostazioniTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chiave =>
      $composableBuilder(column: $table.chiave, builder: (column) => column);

  GeneratedColumn<String> get valore =>
      $composableBuilder(column: $table.valore, builder: (column) => column);
}

class $$ImpostazioniTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $ImpostazioniTable,
          Impostazione,
          $$ImpostazioniTableFilterComposer,
          $$ImpostazioniTableOrderingComposer,
          $$ImpostazioniTableAnnotationComposer,
          $$ImpostazioniTableCreateCompanionBuilder,
          $$ImpostazioniTableUpdateCompanionBuilder,
          (
            Impostazione,
            BaseReferences<_$Archivio, $ImpostazioniTable, Impostazione>,
          ),
          Impostazione,
          PrefetchHooks Function()
        > {
  $$ImpostazioniTableTableManager(_$Archivio db, $ImpostazioniTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImpostazioniTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImpostazioniTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImpostazioniTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> chiave = const Value.absent(),
                Value<String> valore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImpostazioniCompanion(
                chiave: chiave,
                valore: valore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chiave,
                required String valore,
                Value<int> rowid = const Value.absent(),
              }) => ImpostazioniCompanion.insert(
                chiave: chiave,
                valore: valore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImpostazioniTable, Impostazione>(table),
                  BaseReferences<_$Archivio, $ImpostazioniTable, Impostazione>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImpostazioniTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $ImpostazioniTable,
      Impostazione,
      $$ImpostazioniTableFilterComposer,
      $$ImpostazioniTableOrderingComposer,
      $$ImpostazioniTableAnnotationComposer,
      $$ImpostazioniTableCreateCompanionBuilder,
      $$ImpostazioniTableUpdateCompanionBuilder,
      (
        Impostazione,
        BaseReferences<_$Archivio, $ImpostazioniTable, Impostazione>,
      ),
      Impostazione,
      PrefetchHooks Function()
    >;

class $ArchivioManager {
  final _$Archivio _db;
  $ArchivioManager(this._db);
  $$DefinizioniTipoTableTableManager get definizioniTipo =>
      $$DefinizioniTipoTableTableManager(_db, _db.definizioniTipo);
  $$PortafogliTableTableManager get portafogli =>
      $$PortafogliTableTableManager(_db, _db.portafogli);
  $$CategorieTableTableManager get categorie =>
      $$CategorieTableTableManager(_db, _db.categorie);
  $$MovimentiTableTableManager get movimenti =>
      $$MovimentiTableTableManager(_db, _db.movimenti);
  $$EtichetteTableTableManager get etichette =>
      $$EtichetteTableTableManager(_db, _db.etichette);
  $$MovimentiEtichetteTableTableManager get movimentiEtichette =>
      $$MovimentiEtichetteTableTableManager(_db, _db.movimentiEtichette);
  $$ImpostazioniTableTableManager get impostazioni =>
      $$ImpostazioniTableTableManager(_db, _db.impostazioni);
}
