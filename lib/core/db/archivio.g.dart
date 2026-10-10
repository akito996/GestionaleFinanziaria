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

class $PianificazioniTable extends Pianificazioni
    with TableInfo<$PianificazioniTable, Pianificazione> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PianificazioniTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _origineMeta = const VerificationMeta(
    'origine',
  );
  @override
  late final GeneratedColumn<String> origine = GeneratedColumn<String>(
    'origine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _origineIdMeta = const VerificationMeta(
    'origineId',
  );
  @override
  late final GeneratedColumn<String> origineId = GeneratedColumn<String>(
    'origine_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portafoglioIdMeta = const VerificationMeta(
    'portafoglioId',
  );
  @override
  late final GeneratedColumn<String> portafoglioId = GeneratedColumn<String>(
    'portafoglio_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES portafogli (id)',
    ),
  );
  static const VerificationMeta _destinazioneIdMeta = const VerificationMeta(
    'destinazioneId',
  );
  @override
  late final GeneratedColumn<String> destinazioneId = GeneratedColumn<String>(
    'destinazione_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES portafogli (id)',
    ),
  );
  static const VerificationMeta _tipoIdMeta = const VerificationMeta('tipoId');
  @override
  late final GeneratedColumn<String> tipoId = GeneratedColumn<String>(
    'tipo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES definizioni_tipo (id)',
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
  static const VerificationMeta _importoMinimoMeta = const VerificationMeta(
    'importoMinimo',
  );
  @override
  late final GeneratedColumn<int> importoMinimo = GeneratedColumn<int>(
    'importo_minimo',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: const Constant('EUR'),
  );
  static const VerificationMeta _inizioMeta = const VerificationMeta('inizio');
  @override
  late final GeneratedColumn<String> inizio = GeneratedColumn<String>(
    'inizio',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequenzaMeta = const VerificationMeta(
    'frequenza',
  );
  @override
  late final GeneratedColumn<String> frequenza = GeneratedColumn<String>(
    'frequenza',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('mensile'),
  );
  static const VerificationMeta _fineMeta = const VerificationMeta('fine');
  @override
  late final GeneratedColumn<String> fine = GeneratedColumn<String>(
    'fine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occorrenzeMeta = const VerificationMeta(
    'occorrenze',
  );
  @override
  late final GeneratedColumn<int> occorrenze = GeneratedColumn<int>(
    'occorrenze',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avvisoGiorniMeta = const VerificationMeta(
    'avvisoGiorni',
  );
  @override
  late final GeneratedColumn<int> avvisoGiorni = GeneratedColumn<int>(
    'avviso_giorni',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _attivaMeta = const VerificationMeta('attiva');
  @override
  late final GeneratedColumn<bool> attiva = GeneratedColumn<bool>(
    'attiva',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("attiva" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    origine,
    origineId,
    portafoglioId,
    destinazioneId,
    tipoId,
    categoriaId,
    descrizione,
    importoMinimo,
    valuta,
    inizio,
    frequenza,
    fine,
    occorrenze,
    avvisoGiorni,
    attiva,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pianificazioni';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pianificazione> instance, {
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
    if (data.containsKey('origine')) {
      context.handle(
        _origineMeta,
        origine.isAcceptableOrUnknown(data['origine']!, _origineMeta),
      );
    } else if (isInserting) {
      context.missing(_origineMeta);
    }
    if (data.containsKey('origine_id')) {
      context.handle(
        _origineIdMeta,
        origineId.isAcceptableOrUnknown(data['origine_id']!, _origineIdMeta),
      );
    }
    if (data.containsKey('portafoglio_id')) {
      context.handle(
        _portafoglioIdMeta,
        portafoglioId.isAcceptableOrUnknown(
          data['portafoglio_id']!,
          _portafoglioIdMeta,
        ),
      );
    }
    if (data.containsKey('destinazione_id')) {
      context.handle(
        _destinazioneIdMeta,
        destinazioneId.isAcceptableOrUnknown(
          data['destinazione_id']!,
          _destinazioneIdMeta,
        ),
      );
    }
    if (data.containsKey('tipo_id')) {
      context.handle(
        _tipoIdMeta,
        tipoId.isAcceptableOrUnknown(data['tipo_id']!, _tipoIdMeta),
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
    if (data.containsKey('descrizione')) {
      context.handle(
        _descrizioneMeta,
        descrizione.isAcceptableOrUnknown(
          data['descrizione']!,
          _descrizioneMeta,
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
    }
    if (data.containsKey('valuta')) {
      context.handle(
        _valutaMeta,
        valuta.isAcceptableOrUnknown(data['valuta']!, _valutaMeta),
      );
    }
    if (data.containsKey('inizio')) {
      context.handle(
        _inizioMeta,
        inizio.isAcceptableOrUnknown(data['inizio']!, _inizioMeta),
      );
    } else if (isInserting) {
      context.missing(_inizioMeta);
    }
    if (data.containsKey('frequenza')) {
      context.handle(
        _frequenzaMeta,
        frequenza.isAcceptableOrUnknown(data['frequenza']!, _frequenzaMeta),
      );
    }
    if (data.containsKey('fine')) {
      context.handle(
        _fineMeta,
        fine.isAcceptableOrUnknown(data['fine']!, _fineMeta),
      );
    }
    if (data.containsKey('occorrenze')) {
      context.handle(
        _occorrenzeMeta,
        occorrenze.isAcceptableOrUnknown(data['occorrenze']!, _occorrenzeMeta),
      );
    }
    if (data.containsKey('avviso_giorni')) {
      context.handle(
        _avvisoGiorniMeta,
        avvisoGiorni.isAcceptableOrUnknown(
          data['avviso_giorni']!,
          _avvisoGiorniMeta,
        ),
      );
    }
    if (data.containsKey('attiva')) {
      context.handle(
        _attivaMeta,
        attiva.isAcceptableOrUnknown(data['attiva']!, _attivaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pianificazione map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pianificazione(
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
      origine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origine'],
      )!,
      origineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origine_id'],
      ),
      portafoglioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portafoglio_id'],
      ),
      destinazioneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destinazione_id'],
      ),
      tipoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_id'],
      ),
      categoriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria_id'],
      ),
      descrizione: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descrizione'],
      )!,
      importoMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importo_minimo'],
      ),
      valuta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valuta'],
      )!,
      inizio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inizio'],
      )!,
      frequenza: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequenza'],
      )!,
      fine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fine'],
      ),
      occorrenze: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occorrenze'],
      ),
      avvisoGiorni: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avviso_giorni'],
      )!,
      attiva: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}attiva'],
      )!,
    );
  }

  @override
  $PianificazioniTable createAlias(String alias) {
    return $PianificazioniTable(attachedDatabase, alias);
  }
}

class Pianificazione extends DataClass implements Insertable<Pianificazione> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;

  /// Vedi [OriginePianificazione].
  final String origine;
  final String? origineId;

  /// Da dove escono i soldi. Senza portafoglio è solo un promemoria.
  final String? portafoglioId;

  /// Per i trasferimenti (es. addebito della carta sul conto).
  final String? destinazioneId;
  final String? tipoId;
  final String? categoriaId;
  final String descrizione;

  /// Importo fisso; `null` = lo calcola l'origine (es. importo del mese della voce).
  final int? importoMinimo;
  final String valuta;

  /// Regola: primo giorno (AAAA-MM-GG), frequenza, fine per data o numero di volte.
  final String inizio;
  final String frequenza;
  final String? fine;
  final int? occorrenze;

  /// Quanti giorni prima avvisare.
  final int avvisoGiorni;
  final bool attiva;
  const Pianificazione({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    required this.origine,
    this.origineId,
    this.portafoglioId,
    this.destinazioneId,
    this.tipoId,
    this.categoriaId,
    required this.descrizione,
    this.importoMinimo,
    required this.valuta,
    required this.inizio,
    required this.frequenza,
    this.fine,
    this.occorrenze,
    required this.avvisoGiorni,
    required this.attiva,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    map['origine'] = Variable<String>(origine);
    if (!nullToAbsent || origineId != null) {
      map['origine_id'] = Variable<String>(origineId);
    }
    if (!nullToAbsent || portafoglioId != null) {
      map['portafoglio_id'] = Variable<String>(portafoglioId);
    }
    if (!nullToAbsent || destinazioneId != null) {
      map['destinazione_id'] = Variable<String>(destinazioneId);
    }
    if (!nullToAbsent || tipoId != null) {
      map['tipo_id'] = Variable<String>(tipoId);
    }
    if (!nullToAbsent || categoriaId != null) {
      map['categoria_id'] = Variable<String>(categoriaId);
    }
    map['descrizione'] = Variable<String>(descrizione);
    if (!nullToAbsent || importoMinimo != null) {
      map['importo_minimo'] = Variable<int>(importoMinimo);
    }
    map['valuta'] = Variable<String>(valuta);
    map['inizio'] = Variable<String>(inizio);
    map['frequenza'] = Variable<String>(frequenza);
    if (!nullToAbsent || fine != null) {
      map['fine'] = Variable<String>(fine);
    }
    if (!nullToAbsent || occorrenze != null) {
      map['occorrenze'] = Variable<int>(occorrenze);
    }
    map['avviso_giorni'] = Variable<int>(avvisoGiorni);
    map['attiva'] = Variable<bool>(attiva);
    return map;
  }

  PianificazioniCompanion toCompanion(bool nullToAbsent) {
    return PianificazioniCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      origine: Value(origine),
      origineId: origineId == null && nullToAbsent
          ? const Value.absent()
          : Value(origineId),
      portafoglioId: portafoglioId == null && nullToAbsent
          ? const Value.absent()
          : Value(portafoglioId),
      destinazioneId: destinazioneId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinazioneId),
      tipoId: tipoId == null && nullToAbsent
          ? const Value.absent()
          : Value(tipoId),
      categoriaId: categoriaId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoriaId),
      descrizione: Value(descrizione),
      importoMinimo: importoMinimo == null && nullToAbsent
          ? const Value.absent()
          : Value(importoMinimo),
      valuta: Value(valuta),
      inizio: Value(inizio),
      frequenza: Value(frequenza),
      fine: fine == null && nullToAbsent ? const Value.absent() : Value(fine),
      occorrenze: occorrenze == null && nullToAbsent
          ? const Value.absent()
          : Value(occorrenze),
      avvisoGiorni: Value(avvisoGiorni),
      attiva: Value(attiva),
    );
  }

  factory Pianificazione.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pianificazione(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      origine: serializer.fromJson<String>(json['origine']),
      origineId: serializer.fromJson<String?>(json['origineId']),
      portafoglioId: serializer.fromJson<String?>(json['portafoglioId']),
      destinazioneId: serializer.fromJson<String?>(json['destinazioneId']),
      tipoId: serializer.fromJson<String?>(json['tipoId']),
      categoriaId: serializer.fromJson<String?>(json['categoriaId']),
      descrizione: serializer.fromJson<String>(json['descrizione']),
      importoMinimo: serializer.fromJson<int?>(json['importoMinimo']),
      valuta: serializer.fromJson<String>(json['valuta']),
      inizio: serializer.fromJson<String>(json['inizio']),
      frequenza: serializer.fromJson<String>(json['frequenza']),
      fine: serializer.fromJson<String?>(json['fine']),
      occorrenze: serializer.fromJson<int?>(json['occorrenze']),
      avvisoGiorni: serializer.fromJson<int>(json['avvisoGiorni']),
      attiva: serializer.fromJson<bool>(json['attiva']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'origine': serializer.toJson<String>(origine),
      'origineId': serializer.toJson<String?>(origineId),
      'portafoglioId': serializer.toJson<String?>(portafoglioId),
      'destinazioneId': serializer.toJson<String?>(destinazioneId),
      'tipoId': serializer.toJson<String?>(tipoId),
      'categoriaId': serializer.toJson<String?>(categoriaId),
      'descrizione': serializer.toJson<String>(descrizione),
      'importoMinimo': serializer.toJson<int?>(importoMinimo),
      'valuta': serializer.toJson<String>(valuta),
      'inizio': serializer.toJson<String>(inizio),
      'frequenza': serializer.toJson<String>(frequenza),
      'fine': serializer.toJson<String?>(fine),
      'occorrenze': serializer.toJson<int?>(occorrenze),
      'avvisoGiorni': serializer.toJson<int>(avvisoGiorni),
      'attiva': serializer.toJson<bool>(attiva),
    };
  }

  Pianificazione copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    String? origine,
    Value<String?> origineId = const Value.absent(),
    Value<String?> portafoglioId = const Value.absent(),
    Value<String?> destinazioneId = const Value.absent(),
    Value<String?> tipoId = const Value.absent(),
    Value<String?> categoriaId = const Value.absent(),
    String? descrizione,
    Value<int?> importoMinimo = const Value.absent(),
    String? valuta,
    String? inizio,
    String? frequenza,
    Value<String?> fine = const Value.absent(),
    Value<int?> occorrenze = const Value.absent(),
    int? avvisoGiorni,
    bool? attiva,
  }) => Pianificazione(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    origine: origine ?? this.origine,
    origineId: origineId.present ? origineId.value : this.origineId,
    portafoglioId: portafoglioId.present
        ? portafoglioId.value
        : this.portafoglioId,
    destinazioneId: destinazioneId.present
        ? destinazioneId.value
        : this.destinazioneId,
    tipoId: tipoId.present ? tipoId.value : this.tipoId,
    categoriaId: categoriaId.present ? categoriaId.value : this.categoriaId,
    descrizione: descrizione ?? this.descrizione,
    importoMinimo: importoMinimo.present
        ? importoMinimo.value
        : this.importoMinimo,
    valuta: valuta ?? this.valuta,
    inizio: inizio ?? this.inizio,
    frequenza: frequenza ?? this.frequenza,
    fine: fine.present ? fine.value : this.fine,
    occorrenze: occorrenze.present ? occorrenze.value : this.occorrenze,
    avvisoGiorni: avvisoGiorni ?? this.avvisoGiorni,
    attiva: attiva ?? this.attiva,
  );
  Pianificazione copyWithCompanion(PianificazioniCompanion data) {
    return Pianificazione(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      origine: data.origine.present ? data.origine.value : this.origine,
      origineId: data.origineId.present ? data.origineId.value : this.origineId,
      portafoglioId: data.portafoglioId.present
          ? data.portafoglioId.value
          : this.portafoglioId,
      destinazioneId: data.destinazioneId.present
          ? data.destinazioneId.value
          : this.destinazioneId,
      tipoId: data.tipoId.present ? data.tipoId.value : this.tipoId,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      descrizione: data.descrizione.present
          ? data.descrizione.value
          : this.descrizione,
      importoMinimo: data.importoMinimo.present
          ? data.importoMinimo.value
          : this.importoMinimo,
      valuta: data.valuta.present ? data.valuta.value : this.valuta,
      inizio: data.inizio.present ? data.inizio.value : this.inizio,
      frequenza: data.frequenza.present ? data.frequenza.value : this.frequenza,
      fine: data.fine.present ? data.fine.value : this.fine,
      occorrenze: data.occorrenze.present
          ? data.occorrenze.value
          : this.occorrenze,
      avvisoGiorni: data.avvisoGiorni.present
          ? data.avvisoGiorni.value
          : this.avvisoGiorni,
      attiva: data.attiva.present ? data.attiva.value : this.attiva,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pianificazione(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('origine: $origine, ')
          ..write('origineId: $origineId, ')
          ..write('portafoglioId: $portafoglioId, ')
          ..write('destinazioneId: $destinazioneId, ')
          ..write('tipoId: $tipoId, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('descrizione: $descrizione, ')
          ..write('importoMinimo: $importoMinimo, ')
          ..write('valuta: $valuta, ')
          ..write('inizio: $inizio, ')
          ..write('frequenza: $frequenza, ')
          ..write('fine: $fine, ')
          ..write('occorrenze: $occorrenze, ')
          ..write('avvisoGiorni: $avvisoGiorni, ')
          ..write('attiva: $attiva')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aggiornatoIl,
    eliminato,
    origine,
    origineId,
    portafoglioId,
    destinazioneId,
    tipoId,
    categoriaId,
    descrizione,
    importoMinimo,
    valuta,
    inizio,
    frequenza,
    fine,
    occorrenze,
    avvisoGiorni,
    attiva,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pianificazione &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.origine == this.origine &&
          other.origineId == this.origineId &&
          other.portafoglioId == this.portafoglioId &&
          other.destinazioneId == this.destinazioneId &&
          other.tipoId == this.tipoId &&
          other.categoriaId == this.categoriaId &&
          other.descrizione == this.descrizione &&
          other.importoMinimo == this.importoMinimo &&
          other.valuta == this.valuta &&
          other.inizio == this.inizio &&
          other.frequenza == this.frequenza &&
          other.fine == this.fine &&
          other.occorrenze == this.occorrenze &&
          other.avvisoGiorni == this.avvisoGiorni &&
          other.attiva == this.attiva);
}

class PianificazioniCompanion extends UpdateCompanion<Pianificazione> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String> origine;
  final Value<String?> origineId;
  final Value<String?> portafoglioId;
  final Value<String?> destinazioneId;
  final Value<String?> tipoId;
  final Value<String?> categoriaId;
  final Value<String> descrizione;
  final Value<int?> importoMinimo;
  final Value<String> valuta;
  final Value<String> inizio;
  final Value<String> frequenza;
  final Value<String?> fine;
  final Value<int?> occorrenze;
  final Value<int> avvisoGiorni;
  final Value<bool> attiva;
  final Value<int> rowid;
  const PianificazioniCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.origine = const Value.absent(),
    this.origineId = const Value.absent(),
    this.portafoglioId = const Value.absent(),
    this.destinazioneId = const Value.absent(),
    this.tipoId = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.descrizione = const Value.absent(),
    this.importoMinimo = const Value.absent(),
    this.valuta = const Value.absent(),
    this.inizio = const Value.absent(),
    this.frequenza = const Value.absent(),
    this.fine = const Value.absent(),
    this.occorrenze = const Value.absent(),
    this.avvisoGiorni = const Value.absent(),
    this.attiva = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PianificazioniCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    required String origine,
    this.origineId = const Value.absent(),
    this.portafoglioId = const Value.absent(),
    this.destinazioneId = const Value.absent(),
    this.tipoId = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.descrizione = const Value.absent(),
    this.importoMinimo = const Value.absent(),
    this.valuta = const Value.absent(),
    required String inizio,
    this.frequenza = const Value.absent(),
    this.fine = const Value.absent(),
    this.occorrenze = const Value.absent(),
    this.avvisoGiorni = const Value.absent(),
    this.attiva = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       origine = Value(origine),
       inizio = Value(inizio);
  static Insertable<Pianificazione> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? origine,
    Expression<String>? origineId,
    Expression<String>? portafoglioId,
    Expression<String>? destinazioneId,
    Expression<String>? tipoId,
    Expression<String>? categoriaId,
    Expression<String>? descrizione,
    Expression<int>? importoMinimo,
    Expression<String>? valuta,
    Expression<String>? inizio,
    Expression<String>? frequenza,
    Expression<String>? fine,
    Expression<int>? occorrenze,
    Expression<int>? avvisoGiorni,
    Expression<bool>? attiva,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (origine != null) 'origine': origine,
      if (origineId != null) 'origine_id': origineId,
      if (portafoglioId != null) 'portafoglio_id': portafoglioId,
      if (destinazioneId != null) 'destinazione_id': destinazioneId,
      if (tipoId != null) 'tipo_id': tipoId,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (descrizione != null) 'descrizione': descrizione,
      if (importoMinimo != null) 'importo_minimo': importoMinimo,
      if (valuta != null) 'valuta': valuta,
      if (inizio != null) 'inizio': inizio,
      if (frequenza != null) 'frequenza': frequenza,
      if (fine != null) 'fine': fine,
      if (occorrenze != null) 'occorrenze': occorrenze,
      if (avvisoGiorni != null) 'avviso_giorni': avvisoGiorni,
      if (attiva != null) 'attiva': attiva,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PianificazioniCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String>? origine,
    Value<String?>? origineId,
    Value<String?>? portafoglioId,
    Value<String?>? destinazioneId,
    Value<String?>? tipoId,
    Value<String?>? categoriaId,
    Value<String>? descrizione,
    Value<int?>? importoMinimo,
    Value<String>? valuta,
    Value<String>? inizio,
    Value<String>? frequenza,
    Value<String?>? fine,
    Value<int?>? occorrenze,
    Value<int>? avvisoGiorni,
    Value<bool>? attiva,
    Value<int>? rowid,
  }) {
    return PianificazioniCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      origine: origine ?? this.origine,
      origineId: origineId ?? this.origineId,
      portafoglioId: portafoglioId ?? this.portafoglioId,
      destinazioneId: destinazioneId ?? this.destinazioneId,
      tipoId: tipoId ?? this.tipoId,
      categoriaId: categoriaId ?? this.categoriaId,
      descrizione: descrizione ?? this.descrizione,
      importoMinimo: importoMinimo ?? this.importoMinimo,
      valuta: valuta ?? this.valuta,
      inizio: inizio ?? this.inizio,
      frequenza: frequenza ?? this.frequenza,
      fine: fine ?? this.fine,
      occorrenze: occorrenze ?? this.occorrenze,
      avvisoGiorni: avvisoGiorni ?? this.avvisoGiorni,
      attiva: attiva ?? this.attiva,
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
    if (origine.present) {
      map['origine'] = Variable<String>(origine.value);
    }
    if (origineId.present) {
      map['origine_id'] = Variable<String>(origineId.value);
    }
    if (portafoglioId.present) {
      map['portafoglio_id'] = Variable<String>(portafoglioId.value);
    }
    if (destinazioneId.present) {
      map['destinazione_id'] = Variable<String>(destinazioneId.value);
    }
    if (tipoId.present) {
      map['tipo_id'] = Variable<String>(tipoId.value);
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<String>(categoriaId.value);
    }
    if (descrizione.present) {
      map['descrizione'] = Variable<String>(descrizione.value);
    }
    if (importoMinimo.present) {
      map['importo_minimo'] = Variable<int>(importoMinimo.value);
    }
    if (valuta.present) {
      map['valuta'] = Variable<String>(valuta.value);
    }
    if (inizio.present) {
      map['inizio'] = Variable<String>(inizio.value);
    }
    if (frequenza.present) {
      map['frequenza'] = Variable<String>(frequenza.value);
    }
    if (fine.present) {
      map['fine'] = Variable<String>(fine.value);
    }
    if (occorrenze.present) {
      map['occorrenze'] = Variable<int>(occorrenze.value);
    }
    if (avvisoGiorni.present) {
      map['avviso_giorni'] = Variable<int>(avvisoGiorni.value);
    }
    if (attiva.present) {
      map['attiva'] = Variable<bool>(attiva.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PianificazioniCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('origine: $origine, ')
          ..write('origineId: $origineId, ')
          ..write('portafoglioId: $portafoglioId, ')
          ..write('destinazioneId: $destinazioneId, ')
          ..write('tipoId: $tipoId, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('descrizione: $descrizione, ')
          ..write('importoMinimo: $importoMinimo, ')
          ..write('valuta: $valuta, ')
          ..write('inizio: $inizio, ')
          ..write('frequenza: $frequenza, ')
          ..write('fine: $fine, ')
          ..write('occorrenze: $occorrenze, ')
          ..write('avvisoGiorni: $avvisoGiorni, ')
          ..write('attiva: $attiva, ')
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
  static const VerificationMeta _pianificazioneIdMeta = const VerificationMeta(
    'pianificazioneId',
  );
  @override
  late final GeneratedColumn<String> pianificazioneId = GeneratedColumn<String>(
    'pianificazione_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pianificazioni (id)',
    ),
  );
  static const VerificationMeta _dataPrevistaMeta = const VerificationMeta(
    'dataPrevista',
  );
  @override
  late final GeneratedColumn<String> dataPrevista = GeneratedColumn<String>(
    'data_prevista',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    pianificazioneId,
    dataPrevista,
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
    if (data.containsKey('pianificazione_id')) {
      context.handle(
        _pianificazioneIdMeta,
        pianificazioneId.isAcceptableOrUnknown(
          data['pianificazione_id']!,
          _pianificazioneIdMeta,
        ),
      );
    }
    if (data.containsKey('data_prevista')) {
      context.handle(
        _dataPrevistaMeta,
        dataPrevista.isAcceptableOrUnknown(
          data['data_prevista']!,
          _dataPrevistaMeta,
        ),
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
      pianificazioneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pianificazione_id'],
      ),
      dataPrevista: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_prevista'],
      ),
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

  /// Movimento creato da un pagamento programmato (bolletta, rata, carta):
  /// la coppia (pianificazione, data prevista) è unica, così non si registra due volte.
  final String? pianificazioneId;
  final String? dataPrevista;
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
    this.pianificazioneId,
    this.dataPrevista,
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
    if (!nullToAbsent || pianificazioneId != null) {
      map['pianificazione_id'] = Variable<String>(pianificazioneId);
    }
    if (!nullToAbsent || dataPrevista != null) {
      map['data_prevista'] = Variable<String>(dataPrevista);
    }
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
      pianificazioneId: pianificazioneId == null && nullToAbsent
          ? const Value.absent()
          : Value(pianificazioneId),
      dataPrevista: dataPrevista == null && nullToAbsent
          ? const Value.absent()
          : Value(dataPrevista),
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
      pianificazioneId: serializer.fromJson<String?>(json['pianificazioneId']),
      dataPrevista: serializer.fromJson<String?>(json['dataPrevista']),
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
      'pianificazioneId': serializer.toJson<String?>(pianificazioneId),
      'dataPrevista': serializer.toJson<String?>(dataPrevista),
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
    Value<String?> pianificazioneId = const Value.absent(),
    Value<String?> dataPrevista = const Value.absent(),
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
    pianificazioneId: pianificazioneId.present
        ? pianificazioneId.value
        : this.pianificazioneId,
    dataPrevista: dataPrevista.present ? dataPrevista.value : this.dataPrevista,
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
      pianificazioneId: data.pianificazioneId.present
          ? data.pianificazioneId.value
          : this.pianificazioneId,
      dataPrevista: data.dataPrevista.present
          ? data.dataPrevista.value
          : this.dataPrevista,
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
          ..write('campi: $campi, ')
          ..write('pianificazioneId: $pianificazioneId, ')
          ..write('dataPrevista: $dataPrevista')
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
    pianificazioneId,
    dataPrevista,
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
          other.campi == this.campi &&
          other.pianificazioneId == this.pianificazioneId &&
          other.dataPrevista == this.dataPrevista);
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
  final Value<String?> pianificazioneId;
  final Value<String?> dataPrevista;
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
    this.pianificazioneId = const Value.absent(),
    this.dataPrevista = const Value.absent(),
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
    this.pianificazioneId = const Value.absent(),
    this.dataPrevista = const Value.absent(),
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
    Expression<String>? pianificazioneId,
    Expression<String>? dataPrevista,
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
      if (pianificazioneId != null) 'pianificazione_id': pianificazioneId,
      if (dataPrevista != null) 'data_prevista': dataPrevista,
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
    Value<String?>? pianificazioneId,
    Value<String?>? dataPrevista,
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
      pianificazioneId: pianificazioneId ?? this.pianificazioneId,
      dataPrevista: dataPrevista ?? this.dataPrevista,
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
    if (pianificazioneId.present) {
      map['pianificazione_id'] = Variable<String>(pianificazioneId.value);
    }
    if (dataPrevista.present) {
      map['data_prevista'] = Variable<String>(dataPrevista.value);
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
          ..write('pianificazioneId: $pianificazioneId, ')
          ..write('dataPrevista: $dataPrevista, ')
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

class $VociCostoTable extends VociCosto
    with TableInfo<$VociCostoTable, VoceCosto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VociCostoTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: const Constant('EUR'),
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
    nome,
    tipo,
    categoriaId,
    valuta,
    archiviata,
    ordine,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voci_costo';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoceCosto> instance, {
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
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
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
    if (data.containsKey('valuta')) {
      context.handle(
        _valutaMeta,
        valuta.isAcceptableOrUnknown(data['valuta']!, _valutaMeta),
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
  VoceCosto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoceCosto(
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
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      categoriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria_id'],
      ),
      valuta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valuta'],
      )!,
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
  $VociCostoTable createAlias(String alias) {
    return $VociCostoTable(attachedDatabase, alias);
  }
}

class VoceCosto extends DataClass implements Insertable<VoceCosto> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;
  final String nome;

  /// Vedi [TipoVoce].
  final String tipo;

  /// Per le variabili: le spese reali sono i movimenti di questa categoria
  /// (e delle sue sottocategorie).
  final String? categoriaId;
  final String valuta;
  final bool archiviata;
  final int ordine;
  const VoceCosto({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    required this.nome,
    required this.tipo,
    this.categoriaId,
    required this.valuta,
    required this.archiviata,
    required this.ordine,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    map['nome'] = Variable<String>(nome);
    map['tipo'] = Variable<String>(tipo);
    if (!nullToAbsent || categoriaId != null) {
      map['categoria_id'] = Variable<String>(categoriaId);
    }
    map['valuta'] = Variable<String>(valuta);
    map['archiviata'] = Variable<bool>(archiviata);
    map['ordine'] = Variable<int>(ordine);
    return map;
  }

  VociCostoCompanion toCompanion(bool nullToAbsent) {
    return VociCostoCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      nome: Value(nome),
      tipo: Value(tipo),
      categoriaId: categoriaId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoriaId),
      valuta: Value(valuta),
      archiviata: Value(archiviata),
      ordine: Value(ordine),
    );
  }

  factory VoceCosto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoceCosto(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      nome: serializer.fromJson<String>(json['nome']),
      tipo: serializer.fromJson<String>(json['tipo']),
      categoriaId: serializer.fromJson<String?>(json['categoriaId']),
      valuta: serializer.fromJson<String>(json['valuta']),
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
      'nome': serializer.toJson<String>(nome),
      'tipo': serializer.toJson<String>(tipo),
      'categoriaId': serializer.toJson<String?>(categoriaId),
      'valuta': serializer.toJson<String>(valuta),
      'archiviata': serializer.toJson<bool>(archiviata),
      'ordine': serializer.toJson<int>(ordine),
    };
  }

  VoceCosto copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    String? nome,
    String? tipo,
    Value<String?> categoriaId = const Value.absent(),
    String? valuta,
    bool? archiviata,
    int? ordine,
  }) => VoceCosto(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    nome: nome ?? this.nome,
    tipo: tipo ?? this.tipo,
    categoriaId: categoriaId.present ? categoriaId.value : this.categoriaId,
    valuta: valuta ?? this.valuta,
    archiviata: archiviata ?? this.archiviata,
    ordine: ordine ?? this.ordine,
  );
  VoceCosto copyWithCompanion(VociCostoCompanion data) {
    return VoceCosto(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      nome: data.nome.present ? data.nome.value : this.nome,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      valuta: data.valuta.present ? data.valuta.value : this.valuta,
      archiviata: data.archiviata.present
          ? data.archiviata.value
          : this.archiviata,
      ordine: data.ordine.present ? data.ordine.value : this.ordine,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoceCosto(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('nome: $nome, ')
          ..write('tipo: $tipo, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('valuta: $valuta, ')
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
    nome,
    tipo,
    categoriaId,
    valuta,
    archiviata,
    ordine,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoceCosto &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.nome == this.nome &&
          other.tipo == this.tipo &&
          other.categoriaId == this.categoriaId &&
          other.valuta == this.valuta &&
          other.archiviata == this.archiviata &&
          other.ordine == this.ordine);
}

class VociCostoCompanion extends UpdateCompanion<VoceCosto> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String> nome;
  final Value<String> tipo;
  final Value<String?> categoriaId;
  final Value<String> valuta;
  final Value<bool> archiviata;
  final Value<int> ordine;
  final Value<int> rowid;
  const VociCostoCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.nome = const Value.absent(),
    this.tipo = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.valuta = const Value.absent(),
    this.archiviata = const Value.absent(),
    this.ordine = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VociCostoCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    required String nome,
    required String tipo,
    this.categoriaId = const Value.absent(),
    this.valuta = const Value.absent(),
    this.archiviata = const Value.absent(),
    this.ordine = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       nome = Value(nome),
       tipo = Value(tipo);
  static Insertable<VoceCosto> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? nome,
    Expression<String>? tipo,
    Expression<String>? categoriaId,
    Expression<String>? valuta,
    Expression<bool>? archiviata,
    Expression<int>? ordine,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (nome != null) 'nome': nome,
      if (tipo != null) 'tipo': tipo,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (valuta != null) 'valuta': valuta,
      if (archiviata != null) 'archiviata': archiviata,
      if (ordine != null) 'ordine': ordine,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VociCostoCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String>? nome,
    Value<String>? tipo,
    Value<String?>? categoriaId,
    Value<String>? valuta,
    Value<bool>? archiviata,
    Value<int>? ordine,
    Value<int>? rowid,
  }) {
    return VociCostoCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      categoriaId: categoriaId ?? this.categoriaId,
      valuta: valuta ?? this.valuta,
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
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<String>(categoriaId.value);
    }
    if (valuta.present) {
      map['valuta'] = Variable<String>(valuta.value);
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
    return (StringBuffer('VociCostoCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('nome: $nome, ')
          ..write('tipo: $tipo, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('valuta: $valuta, ')
          ..write('archiviata: $archiviata, ')
          ..write('ordine: $ordine, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportiVoceTable extends ImportiVoce
    with TableInfo<$ImportiVoceTable, ImportoVoce> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportiVoceTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _voceIdMeta = const VerificationMeta('voceId');
  @override
  late final GeneratedColumn<String> voceId = GeneratedColumn<String>(
    'voce_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES voci_costo (id)',
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
  static const VerificationMeta _validoDalMeta = const VerificationMeta(
    'validoDal',
  );
  @override
  late final GeneratedColumn<String> validoDal = GeneratedColumn<String>(
    'valido_dal',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    voceId,
    importoMinimo,
    validoDal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'importi_voce';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportoVoce> instance, {
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
    if (data.containsKey('voce_id')) {
      context.handle(
        _voceIdMeta,
        voceId.isAcceptableOrUnknown(data['voce_id']!, _voceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_voceIdMeta);
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
    if (data.containsKey('valido_dal')) {
      context.handle(
        _validoDalMeta,
        validoDal.isAcceptableOrUnknown(data['valido_dal']!, _validoDalMeta),
      );
    } else if (isInserting) {
      context.missing(_validoDalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportoVoce map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportoVoce(
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
      voceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voce_id'],
      )!,
      importoMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importo_minimo'],
      )!,
      validoDal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valido_dal'],
      )!,
    );
  }

  @override
  $ImportiVoceTable createAlias(String alias) {
    return $ImportiVoceTable(attachedDatabase, alias);
  }
}

class ImportoVoce extends DataClass implements Insertable<ImportoVoce> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;
  final String voceId;
  final int importoMinimo;

  /// AAAA-MM-GG: da questo giorno vale il nuovo importo.
  final String validoDal;
  const ImportoVoce({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    required this.voceId,
    required this.importoMinimo,
    required this.validoDal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    map['voce_id'] = Variable<String>(voceId);
    map['importo_minimo'] = Variable<int>(importoMinimo);
    map['valido_dal'] = Variable<String>(validoDal);
    return map;
  }

  ImportiVoceCompanion toCompanion(bool nullToAbsent) {
    return ImportiVoceCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      voceId: Value(voceId),
      importoMinimo: Value(importoMinimo),
      validoDal: Value(validoDal),
    );
  }

  factory ImportoVoce.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportoVoce(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      voceId: serializer.fromJson<String>(json['voceId']),
      importoMinimo: serializer.fromJson<int>(json['importoMinimo']),
      validoDal: serializer.fromJson<String>(json['validoDal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'voceId': serializer.toJson<String>(voceId),
      'importoMinimo': serializer.toJson<int>(importoMinimo),
      'validoDal': serializer.toJson<String>(validoDal),
    };
  }

  ImportoVoce copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    String? voceId,
    int? importoMinimo,
    String? validoDal,
  }) => ImportoVoce(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    voceId: voceId ?? this.voceId,
    importoMinimo: importoMinimo ?? this.importoMinimo,
    validoDal: validoDal ?? this.validoDal,
  );
  ImportoVoce copyWithCompanion(ImportiVoceCompanion data) {
    return ImportoVoce(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      voceId: data.voceId.present ? data.voceId.value : this.voceId,
      importoMinimo: data.importoMinimo.present
          ? data.importoMinimo.value
          : this.importoMinimo,
      validoDal: data.validoDal.present ? data.validoDal.value : this.validoDal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportoVoce(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('voceId: $voceId, ')
          ..write('importoMinimo: $importoMinimo, ')
          ..write('validoDal: $validoDal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aggiornatoIl,
    eliminato,
    voceId,
    importoMinimo,
    validoDal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportoVoce &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.voceId == this.voceId &&
          other.importoMinimo == this.importoMinimo &&
          other.validoDal == this.validoDal);
}

class ImportiVoceCompanion extends UpdateCompanion<ImportoVoce> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String> voceId;
  final Value<int> importoMinimo;
  final Value<String> validoDal;
  final Value<int> rowid;
  const ImportiVoceCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.voceId = const Value.absent(),
    this.importoMinimo = const Value.absent(),
    this.validoDal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportiVoceCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    required String voceId,
    required int importoMinimo,
    required String validoDal,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       voceId = Value(voceId),
       importoMinimo = Value(importoMinimo),
       validoDal = Value(validoDal);
  static Insertable<ImportoVoce> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? voceId,
    Expression<int>? importoMinimo,
    Expression<String>? validoDal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (voceId != null) 'voce_id': voceId,
      if (importoMinimo != null) 'importo_minimo': importoMinimo,
      if (validoDal != null) 'valido_dal': validoDal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportiVoceCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String>? voceId,
    Value<int>? importoMinimo,
    Value<String>? validoDal,
    Value<int>? rowid,
  }) {
    return ImportiVoceCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      voceId: voceId ?? this.voceId,
      importoMinimo: importoMinimo ?? this.importoMinimo,
      validoDal: validoDal ?? this.validoDal,
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
    if (voceId.present) {
      map['voce_id'] = Variable<String>(voceId.value);
    }
    if (importoMinimo.present) {
      map['importo_minimo'] = Variable<int>(importoMinimo.value);
    }
    if (validoDal.present) {
      map['valido_dal'] = Variable<String>(validoDal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportiVoceCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('voceId: $voceId, ')
          ..write('importoMinimo: $importoMinimo, ')
          ..write('validoDal: $validoDal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VariazioniMeseTable extends VariazioniMese
    with TableInfo<$VariazioniMeseTable, VariazioneMese> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VariazioniMeseTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _voceIdMeta = const VerificationMeta('voceId');
  @override
  late final GeneratedColumn<String> voceId = GeneratedColumn<String>(
    'voce_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES voci_costo (id)',
    ),
  );
  static const VerificationMeta _meseMeta = const VerificationMeta('mese');
  @override
  late final GeneratedColumn<String> mese = GeneratedColumn<String>(
    'mese',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 7,
      maxTextLength: 7,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    voceId,
    mese,
    importoMinimo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'variazioni_mese';
  @override
  VerificationContext validateIntegrity(
    Insertable<VariazioneMese> instance, {
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
    if (data.containsKey('voce_id')) {
      context.handle(
        _voceIdMeta,
        voceId.isAcceptableOrUnknown(data['voce_id']!, _voceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_voceIdMeta);
    }
    if (data.containsKey('mese')) {
      context.handle(
        _meseMeta,
        mese.isAcceptableOrUnknown(data['mese']!, _meseMeta),
      );
    } else if (isInserting) {
      context.missing(_meseMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VariazioneMese map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VariazioneMese(
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
      voceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voce_id'],
      )!,
      mese: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mese'],
      )!,
      importoMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importo_minimo'],
      )!,
    );
  }

  @override
  $VariazioniMeseTable createAlias(String alias) {
    return $VariazioniMeseTable(attachedDatabase, alias);
  }
}

class VariazioneMese extends DataClass implements Insertable<VariazioneMese> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;
  final String voceId;

  /// AAAA-MM.
  final String mese;
  final int importoMinimo;
  const VariazioneMese({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    required this.voceId,
    required this.mese,
    required this.importoMinimo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    map['voce_id'] = Variable<String>(voceId);
    map['mese'] = Variable<String>(mese);
    map['importo_minimo'] = Variable<int>(importoMinimo);
    return map;
  }

  VariazioniMeseCompanion toCompanion(bool nullToAbsent) {
    return VariazioniMeseCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      voceId: Value(voceId),
      mese: Value(mese),
      importoMinimo: Value(importoMinimo),
    );
  }

  factory VariazioneMese.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VariazioneMese(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      voceId: serializer.fromJson<String>(json['voceId']),
      mese: serializer.fromJson<String>(json['mese']),
      importoMinimo: serializer.fromJson<int>(json['importoMinimo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'voceId': serializer.toJson<String>(voceId),
      'mese': serializer.toJson<String>(mese),
      'importoMinimo': serializer.toJson<int>(importoMinimo),
    };
  }

  VariazioneMese copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    String? voceId,
    String? mese,
    int? importoMinimo,
  }) => VariazioneMese(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    voceId: voceId ?? this.voceId,
    mese: mese ?? this.mese,
    importoMinimo: importoMinimo ?? this.importoMinimo,
  );
  VariazioneMese copyWithCompanion(VariazioniMeseCompanion data) {
    return VariazioneMese(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      voceId: data.voceId.present ? data.voceId.value : this.voceId,
      mese: data.mese.present ? data.mese.value : this.mese,
      importoMinimo: data.importoMinimo.present
          ? data.importoMinimo.value
          : this.importoMinimo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VariazioneMese(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('voceId: $voceId, ')
          ..write('mese: $mese, ')
          ..write('importoMinimo: $importoMinimo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, aggiornatoIl, eliminato, voceId, mese, importoMinimo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VariazioneMese &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.voceId == this.voceId &&
          other.mese == this.mese &&
          other.importoMinimo == this.importoMinimo);
}

class VariazioniMeseCompanion extends UpdateCompanion<VariazioneMese> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String> voceId;
  final Value<String> mese;
  final Value<int> importoMinimo;
  final Value<int> rowid;
  const VariazioniMeseCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.voceId = const Value.absent(),
    this.mese = const Value.absent(),
    this.importoMinimo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VariazioniMeseCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    required String voceId,
    required String mese,
    required int importoMinimo,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       voceId = Value(voceId),
       mese = Value(mese),
       importoMinimo = Value(importoMinimo);
  static Insertable<VariazioneMese> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? voceId,
    Expression<String>? mese,
    Expression<int>? importoMinimo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (voceId != null) 'voce_id': voceId,
      if (mese != null) 'mese': mese,
      if (importoMinimo != null) 'importo_minimo': importoMinimo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VariazioniMeseCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String>? voceId,
    Value<String>? mese,
    Value<int>? importoMinimo,
    Value<int>? rowid,
  }) {
    return VariazioniMeseCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      voceId: voceId ?? this.voceId,
      mese: mese ?? this.mese,
      importoMinimo: importoMinimo ?? this.importoMinimo,
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
    if (voceId.present) {
      map['voce_id'] = Variable<String>(voceId.value);
    }
    if (mese.present) {
      map['mese'] = Variable<String>(mese.value);
    }
    if (importoMinimo.present) {
      map['importo_minimo'] = Variable<int>(importoMinimo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VariazioniMeseCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('voceId: $voceId, ')
          ..write('mese: $mese, ')
          ..write('importoMinimo: $importoMinimo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CarteCreditoTable extends CarteCredito
    with TableInfo<$CarteCreditoTable, CartaCredito> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CarteCreditoTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _contoAddebitoIdMeta = const VerificationMeta(
    'contoAddebitoId',
  );
  @override
  late final GeneratedColumn<String> contoAddebitoId = GeneratedColumn<String>(
    'conto_addebito_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES portafogli (id)',
    ),
  );
  static const VerificationMeta _giornoAddebitoMeta = const VerificationMeta(
    'giornoAddebito',
  );
  @override
  late final GeneratedColumn<int> giornoAddebito = GeneratedColumn<int>(
    'giorno_addebito',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _giornoChiusuraMeta = const VerificationMeta(
    'giornoChiusura',
  );
  @override
  late final GeneratedColumn<int> giornoChiusura = GeneratedColumn<int>(
    'giorno_chiusura',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _plafondMinimoMeta = const VerificationMeta(
    'plafondMinimo',
  );
  @override
  late final GeneratedColumn<int> plafondMinimo = GeneratedColumn<int>(
    'plafond_minimo',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    portafoglioId,
    contoAddebitoId,
    giornoAddebito,
    giornoChiusura,
    plafondMinimo,
    archiviata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'carte_credito';
  @override
  VerificationContext validateIntegrity(
    Insertable<CartaCredito> instance, {
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
    if (data.containsKey('conto_addebito_id')) {
      context.handle(
        _contoAddebitoIdMeta,
        contoAddebitoId.isAcceptableOrUnknown(
          data['conto_addebito_id']!,
          _contoAddebitoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contoAddebitoIdMeta);
    }
    if (data.containsKey('giorno_addebito')) {
      context.handle(
        _giornoAddebitoMeta,
        giornoAddebito.isAcceptableOrUnknown(
          data['giorno_addebito']!,
          _giornoAddebitoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_giornoAddebitoMeta);
    }
    if (data.containsKey('giorno_chiusura')) {
      context.handle(
        _giornoChiusuraMeta,
        giornoChiusura.isAcceptableOrUnknown(
          data['giorno_chiusura']!,
          _giornoChiusuraMeta,
        ),
      );
    }
    if (data.containsKey('plafond_minimo')) {
      context.handle(
        _plafondMinimoMeta,
        plafondMinimo.isAcceptableOrUnknown(
          data['plafond_minimo']!,
          _plafondMinimoMeta,
        ),
      );
    }
    if (data.containsKey('archiviata')) {
      context.handle(
        _archiviataMeta,
        archiviata.isAcceptableOrUnknown(data['archiviata']!, _archiviataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CartaCredito map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CartaCredito(
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
      portafoglioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portafoglio_id'],
      )!,
      contoAddebitoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conto_addebito_id'],
      )!,
      giornoAddebito: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}giorno_addebito'],
      )!,
      giornoChiusura: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}giorno_chiusura'],
      )!,
      plafondMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plafond_minimo'],
      ),
      archiviata: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archiviata'],
      )!,
    );
  }

  @override
  $CarteCreditoTable createAlias(String alias) {
    return $CarteCreditoTable(attachedDatabase, alias);
  }
}

class CartaCredito extends DataClass implements Insertable<CartaCredito> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;
  final String portafoglioId;
  final String contoAddebitoId;

  /// Giorno del mese in cui il conto viene addebitato (es. 15).
  final int giornoAddebito;

  /// Ultimo giorno di spese incluse nell'addebito: 0 = fine del mese precedente,
  /// altrimenti quel giorno del mese precedente all'addebito.
  final int giornoChiusura;

  /// Plafond (fido) in unità minime, facoltativo.
  final int? plafondMinimo;
  final bool archiviata;
  const CartaCredito({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    required this.portafoglioId,
    required this.contoAddebitoId,
    required this.giornoAddebito,
    required this.giornoChiusura,
    this.plafondMinimo,
    required this.archiviata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    map['portafoglio_id'] = Variable<String>(portafoglioId);
    map['conto_addebito_id'] = Variable<String>(contoAddebitoId);
    map['giorno_addebito'] = Variable<int>(giornoAddebito);
    map['giorno_chiusura'] = Variable<int>(giornoChiusura);
    if (!nullToAbsent || plafondMinimo != null) {
      map['plafond_minimo'] = Variable<int>(plafondMinimo);
    }
    map['archiviata'] = Variable<bool>(archiviata);
    return map;
  }

  CarteCreditoCompanion toCompanion(bool nullToAbsent) {
    return CarteCreditoCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      portafoglioId: Value(portafoglioId),
      contoAddebitoId: Value(contoAddebitoId),
      giornoAddebito: Value(giornoAddebito),
      giornoChiusura: Value(giornoChiusura),
      plafondMinimo: plafondMinimo == null && nullToAbsent
          ? const Value.absent()
          : Value(plafondMinimo),
      archiviata: Value(archiviata),
    );
  }

  factory CartaCredito.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CartaCredito(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      portafoglioId: serializer.fromJson<String>(json['portafoglioId']),
      contoAddebitoId: serializer.fromJson<String>(json['contoAddebitoId']),
      giornoAddebito: serializer.fromJson<int>(json['giornoAddebito']),
      giornoChiusura: serializer.fromJson<int>(json['giornoChiusura']),
      plafondMinimo: serializer.fromJson<int?>(json['plafondMinimo']),
      archiviata: serializer.fromJson<bool>(json['archiviata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'portafoglioId': serializer.toJson<String>(portafoglioId),
      'contoAddebitoId': serializer.toJson<String>(contoAddebitoId),
      'giornoAddebito': serializer.toJson<int>(giornoAddebito),
      'giornoChiusura': serializer.toJson<int>(giornoChiusura),
      'plafondMinimo': serializer.toJson<int?>(plafondMinimo),
      'archiviata': serializer.toJson<bool>(archiviata),
    };
  }

  CartaCredito copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    String? portafoglioId,
    String? contoAddebitoId,
    int? giornoAddebito,
    int? giornoChiusura,
    Value<int?> plafondMinimo = const Value.absent(),
    bool? archiviata,
  }) => CartaCredito(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    portafoglioId: portafoglioId ?? this.portafoglioId,
    contoAddebitoId: contoAddebitoId ?? this.contoAddebitoId,
    giornoAddebito: giornoAddebito ?? this.giornoAddebito,
    giornoChiusura: giornoChiusura ?? this.giornoChiusura,
    plafondMinimo: plafondMinimo.present
        ? plafondMinimo.value
        : this.plafondMinimo,
    archiviata: archiviata ?? this.archiviata,
  );
  CartaCredito copyWithCompanion(CarteCreditoCompanion data) {
    return CartaCredito(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      portafoglioId: data.portafoglioId.present
          ? data.portafoglioId.value
          : this.portafoglioId,
      contoAddebitoId: data.contoAddebitoId.present
          ? data.contoAddebitoId.value
          : this.contoAddebitoId,
      giornoAddebito: data.giornoAddebito.present
          ? data.giornoAddebito.value
          : this.giornoAddebito,
      giornoChiusura: data.giornoChiusura.present
          ? data.giornoChiusura.value
          : this.giornoChiusura,
      plafondMinimo: data.plafondMinimo.present
          ? data.plafondMinimo.value
          : this.plafondMinimo,
      archiviata: data.archiviata.present
          ? data.archiviata.value
          : this.archiviata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CartaCredito(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('portafoglioId: $portafoglioId, ')
          ..write('contoAddebitoId: $contoAddebitoId, ')
          ..write('giornoAddebito: $giornoAddebito, ')
          ..write('giornoChiusura: $giornoChiusura, ')
          ..write('plafondMinimo: $plafondMinimo, ')
          ..write('archiviata: $archiviata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aggiornatoIl,
    eliminato,
    portafoglioId,
    contoAddebitoId,
    giornoAddebito,
    giornoChiusura,
    plafondMinimo,
    archiviata,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartaCredito &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.portafoglioId == this.portafoglioId &&
          other.contoAddebitoId == this.contoAddebitoId &&
          other.giornoAddebito == this.giornoAddebito &&
          other.giornoChiusura == this.giornoChiusura &&
          other.plafondMinimo == this.plafondMinimo &&
          other.archiviata == this.archiviata);
}

class CarteCreditoCompanion extends UpdateCompanion<CartaCredito> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String> portafoglioId;
  final Value<String> contoAddebitoId;
  final Value<int> giornoAddebito;
  final Value<int> giornoChiusura;
  final Value<int?> plafondMinimo;
  final Value<bool> archiviata;
  final Value<int> rowid;
  const CarteCreditoCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.portafoglioId = const Value.absent(),
    this.contoAddebitoId = const Value.absent(),
    this.giornoAddebito = const Value.absent(),
    this.giornoChiusura = const Value.absent(),
    this.plafondMinimo = const Value.absent(),
    this.archiviata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CarteCreditoCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    required String portafoglioId,
    required String contoAddebitoId,
    required int giornoAddebito,
    this.giornoChiusura = const Value.absent(),
    this.plafondMinimo = const Value.absent(),
    this.archiviata = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       portafoglioId = Value(portafoglioId),
       contoAddebitoId = Value(contoAddebitoId),
       giornoAddebito = Value(giornoAddebito);
  static Insertable<CartaCredito> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? portafoglioId,
    Expression<String>? contoAddebitoId,
    Expression<int>? giornoAddebito,
    Expression<int>? giornoChiusura,
    Expression<int>? plafondMinimo,
    Expression<bool>? archiviata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (portafoglioId != null) 'portafoglio_id': portafoglioId,
      if (contoAddebitoId != null) 'conto_addebito_id': contoAddebitoId,
      if (giornoAddebito != null) 'giorno_addebito': giornoAddebito,
      if (giornoChiusura != null) 'giorno_chiusura': giornoChiusura,
      if (plafondMinimo != null) 'plafond_minimo': plafondMinimo,
      if (archiviata != null) 'archiviata': archiviata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CarteCreditoCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String>? portafoglioId,
    Value<String>? contoAddebitoId,
    Value<int>? giornoAddebito,
    Value<int>? giornoChiusura,
    Value<int?>? plafondMinimo,
    Value<bool>? archiviata,
    Value<int>? rowid,
  }) {
    return CarteCreditoCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      portafoglioId: portafoglioId ?? this.portafoglioId,
      contoAddebitoId: contoAddebitoId ?? this.contoAddebitoId,
      giornoAddebito: giornoAddebito ?? this.giornoAddebito,
      giornoChiusura: giornoChiusura ?? this.giornoChiusura,
      plafondMinimo: plafondMinimo ?? this.plafondMinimo,
      archiviata: archiviata ?? this.archiviata,
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
    if (portafoglioId.present) {
      map['portafoglio_id'] = Variable<String>(portafoglioId.value);
    }
    if (contoAddebitoId.present) {
      map['conto_addebito_id'] = Variable<String>(contoAddebitoId.value);
    }
    if (giornoAddebito.present) {
      map['giorno_addebito'] = Variable<int>(giornoAddebito.value);
    }
    if (giornoChiusura.present) {
      map['giorno_chiusura'] = Variable<int>(giornoChiusura.value);
    }
    if (plafondMinimo.present) {
      map['plafond_minimo'] = Variable<int>(plafondMinimo.value);
    }
    if (archiviata.present) {
      map['archiviata'] = Variable<bool>(archiviata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CarteCreditoCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('portafoglioId: $portafoglioId, ')
          ..write('contoAddebitoId: $contoAddebitoId, ')
          ..write('giornoAddebito: $giornoAddebito, ')
          ..write('giornoChiusura: $giornoChiusura, ')
          ..write('plafondMinimo: $plafondMinimo, ')
          ..write('archiviata: $archiviata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrestitiTable extends Prestiti with TableInfo<$PrestitiTable, Prestito> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrestitiTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finanziatoreMeta = const VerificationMeta(
    'finanziatore',
  );
  @override
  late final GeneratedColumn<String> finanziatore = GeneratedColumn<String>(
    'finanziatore',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _capitaleMinimoMeta = const VerificationMeta(
    'capitaleMinimo',
  );
  @override
  late final GeneratedColumn<int> capitaleMinimo = GeneratedColumn<int>(
    'capitale_minimo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroRateMeta = const VerificationMeta(
    'numeroRate',
  );
  @override
  late final GeneratedColumn<int> numeroRate = GeneratedColumn<int>(
    'numero_rate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importoRataMinimoMeta = const VerificationMeta(
    'importoRataMinimo',
  );
  @override
  late final GeneratedColumn<int> importoRataMinimo = GeneratedColumn<int>(
    'importo_rata_minimo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanPuntiBaseMeta = const VerificationMeta(
    'tanPuntiBase',
  );
  @override
  late final GeneratedColumn<int> tanPuntiBase = GeneratedColumn<int>(
    'tan_punti_base',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taegPuntiBaseMeta = const VerificationMeta(
    'taegPuntiBase',
  );
  @override
  late final GeneratedColumn<int> taegPuntiBase = GeneratedColumn<int>(
    'taeg_punti_base',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primaRataMeta = const VerificationMeta(
    'primaRata',
  );
  @override
  late final GeneratedColumn<String> primaRata = GeneratedColumn<String>(
    'prima_rata',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequenzaMeta = const VerificationMeta(
    'frequenza',
  );
  @override
  late final GeneratedColumn<String> frequenza = GeneratedColumn<String>(
    'frequenza',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('mensile'),
  );
  static const VerificationMeta _portafoglioIdMeta = const VerificationMeta(
    'portafoglioId',
  );
  @override
  late final GeneratedColumn<String> portafoglioId = GeneratedColumn<String>(
    'portafoglio_id',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('EUR'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aggiornatoIl,
    eliminato,
    nome,
    tipo,
    finanziatore,
    capitaleMinimo,
    numeroRate,
    importoRataMinimo,
    tanPuntiBase,
    taegPuntiBase,
    primaRata,
    frequenza,
    portafoglioId,
    categoriaId,
    valuta,
    note,
    archiviato,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prestiti';
  @override
  VerificationContext validateIntegrity(
    Insertable<Prestito> instance, {
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
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('finanziatore')) {
      context.handle(
        _finanziatoreMeta,
        finanziatore.isAcceptableOrUnknown(
          data['finanziatore']!,
          _finanziatoreMeta,
        ),
      );
    }
    if (data.containsKey('capitale_minimo')) {
      context.handle(
        _capitaleMinimoMeta,
        capitaleMinimo.isAcceptableOrUnknown(
          data['capitale_minimo']!,
          _capitaleMinimoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capitaleMinimoMeta);
    }
    if (data.containsKey('numero_rate')) {
      context.handle(
        _numeroRateMeta,
        numeroRate.isAcceptableOrUnknown(data['numero_rate']!, _numeroRateMeta),
      );
    } else if (isInserting) {
      context.missing(_numeroRateMeta);
    }
    if (data.containsKey('importo_rata_minimo')) {
      context.handle(
        _importoRataMinimoMeta,
        importoRataMinimo.isAcceptableOrUnknown(
          data['importo_rata_minimo']!,
          _importoRataMinimoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importoRataMinimoMeta);
    }
    if (data.containsKey('tan_punti_base')) {
      context.handle(
        _tanPuntiBaseMeta,
        tanPuntiBase.isAcceptableOrUnknown(
          data['tan_punti_base']!,
          _tanPuntiBaseMeta,
        ),
      );
    }
    if (data.containsKey('taeg_punti_base')) {
      context.handle(
        _taegPuntiBaseMeta,
        taegPuntiBase.isAcceptableOrUnknown(
          data['taeg_punti_base']!,
          _taegPuntiBaseMeta,
        ),
      );
    }
    if (data.containsKey('prima_rata')) {
      context.handle(
        _primaRataMeta,
        primaRata.isAcceptableOrUnknown(data['prima_rata']!, _primaRataMeta),
      );
    } else if (isInserting) {
      context.missing(_primaRataMeta);
    }
    if (data.containsKey('frequenza')) {
      context.handle(
        _frequenzaMeta,
        frequenza.isAcceptableOrUnknown(data['frequenza']!, _frequenzaMeta),
      );
    }
    if (data.containsKey('portafoglio_id')) {
      context.handle(
        _portafoglioIdMeta,
        portafoglioId.isAcceptableOrUnknown(
          data['portafoglio_id']!,
          _portafoglioIdMeta,
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
    if (data.containsKey('valuta')) {
      context.handle(
        _valutaMeta,
        valuta.isAcceptableOrUnknown(data['valuta']!, _valutaMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('archiviato')) {
      context.handle(
        _archiviatoMeta,
        archiviato.isAcceptableOrUnknown(data['archiviato']!, _archiviatoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prestito map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prestito(
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
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      finanziatore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finanziatore'],
      )!,
      capitaleMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}capitale_minimo'],
      )!,
      numeroRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}numero_rate'],
      )!,
      importoRataMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importo_rata_minimo'],
      )!,
      tanPuntiBase: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tan_punti_base'],
      ),
      taegPuntiBase: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taeg_punti_base'],
      ),
      primaRata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prima_rata'],
      )!,
      frequenza: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequenza'],
      )!,
      portafoglioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portafoglio_id'],
      ),
      categoriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria_id'],
      ),
      valuta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valuta'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      archiviato: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archiviato'],
      )!,
    );
  }

  @override
  $PrestitiTable createAlias(String alias) {
    return $PrestitiTable(attachedDatabase, alias);
  }
}

class Prestito extends DataClass implements Insertable<Prestito> {
  final String id;
  final String aggiornatoIl;
  final bool eliminato;
  final String nome;

  /// Vedi [TipoPrestito].
  final String tipo;
  final String finanziatore;

  /// Capitale finanziato, in unità minime.
  final int capitaleMinimo;
  final int numeroRate;
  final int importoRataMinimo;

  /// Tassi in punti base (1% = 100), facoltativi.
  final int? tanPuntiBase;
  final int? taegPuntiBase;

  /// AAAA-MM-GG della prima rata.
  final String primaRata;
  final String frequenza;

  /// Conto da cui escono le rate (senza: solo promemoria).
  final String? portafoglioId;
  final String? categoriaId;
  final String valuta;
  final String note;
  final bool archiviato;
  const Prestito({
    required this.id,
    required this.aggiornatoIl,
    required this.eliminato,
    required this.nome,
    required this.tipo,
    required this.finanziatore,
    required this.capitaleMinimo,
    required this.numeroRate,
    required this.importoRataMinimo,
    this.tanPuntiBase,
    this.taegPuntiBase,
    required this.primaRata,
    required this.frequenza,
    this.portafoglioId,
    this.categoriaId,
    required this.valuta,
    required this.note,
    required this.archiviato,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['aggiornato_il'] = Variable<String>(aggiornatoIl);
    map['eliminato'] = Variable<bool>(eliminato);
    map['nome'] = Variable<String>(nome);
    map['tipo'] = Variable<String>(tipo);
    map['finanziatore'] = Variable<String>(finanziatore);
    map['capitale_minimo'] = Variable<int>(capitaleMinimo);
    map['numero_rate'] = Variable<int>(numeroRate);
    map['importo_rata_minimo'] = Variable<int>(importoRataMinimo);
    if (!nullToAbsent || tanPuntiBase != null) {
      map['tan_punti_base'] = Variable<int>(tanPuntiBase);
    }
    if (!nullToAbsent || taegPuntiBase != null) {
      map['taeg_punti_base'] = Variable<int>(taegPuntiBase);
    }
    map['prima_rata'] = Variable<String>(primaRata);
    map['frequenza'] = Variable<String>(frequenza);
    if (!nullToAbsent || portafoglioId != null) {
      map['portafoglio_id'] = Variable<String>(portafoglioId);
    }
    if (!nullToAbsent || categoriaId != null) {
      map['categoria_id'] = Variable<String>(categoriaId);
    }
    map['valuta'] = Variable<String>(valuta);
    map['note'] = Variable<String>(note);
    map['archiviato'] = Variable<bool>(archiviato);
    return map;
  }

  PrestitiCompanion toCompanion(bool nullToAbsent) {
    return PrestitiCompanion(
      id: Value(id),
      aggiornatoIl: Value(aggiornatoIl),
      eliminato: Value(eliminato),
      nome: Value(nome),
      tipo: Value(tipo),
      finanziatore: Value(finanziatore),
      capitaleMinimo: Value(capitaleMinimo),
      numeroRate: Value(numeroRate),
      importoRataMinimo: Value(importoRataMinimo),
      tanPuntiBase: tanPuntiBase == null && nullToAbsent
          ? const Value.absent()
          : Value(tanPuntiBase),
      taegPuntiBase: taegPuntiBase == null && nullToAbsent
          ? const Value.absent()
          : Value(taegPuntiBase),
      primaRata: Value(primaRata),
      frequenza: Value(frequenza),
      portafoglioId: portafoglioId == null && nullToAbsent
          ? const Value.absent()
          : Value(portafoglioId),
      categoriaId: categoriaId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoriaId),
      valuta: Value(valuta),
      note: Value(note),
      archiviato: Value(archiviato),
    );
  }

  factory Prestito.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prestito(
      id: serializer.fromJson<String>(json['id']),
      aggiornatoIl: serializer.fromJson<String>(json['aggiornatoIl']),
      eliminato: serializer.fromJson<bool>(json['eliminato']),
      nome: serializer.fromJson<String>(json['nome']),
      tipo: serializer.fromJson<String>(json['tipo']),
      finanziatore: serializer.fromJson<String>(json['finanziatore']),
      capitaleMinimo: serializer.fromJson<int>(json['capitaleMinimo']),
      numeroRate: serializer.fromJson<int>(json['numeroRate']),
      importoRataMinimo: serializer.fromJson<int>(json['importoRataMinimo']),
      tanPuntiBase: serializer.fromJson<int?>(json['tanPuntiBase']),
      taegPuntiBase: serializer.fromJson<int?>(json['taegPuntiBase']),
      primaRata: serializer.fromJson<String>(json['primaRata']),
      frequenza: serializer.fromJson<String>(json['frequenza']),
      portafoglioId: serializer.fromJson<String?>(json['portafoglioId']),
      categoriaId: serializer.fromJson<String?>(json['categoriaId']),
      valuta: serializer.fromJson<String>(json['valuta']),
      note: serializer.fromJson<String>(json['note']),
      archiviato: serializer.fromJson<bool>(json['archiviato']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggiornatoIl': serializer.toJson<String>(aggiornatoIl),
      'eliminato': serializer.toJson<bool>(eliminato),
      'nome': serializer.toJson<String>(nome),
      'tipo': serializer.toJson<String>(tipo),
      'finanziatore': serializer.toJson<String>(finanziatore),
      'capitaleMinimo': serializer.toJson<int>(capitaleMinimo),
      'numeroRate': serializer.toJson<int>(numeroRate),
      'importoRataMinimo': serializer.toJson<int>(importoRataMinimo),
      'tanPuntiBase': serializer.toJson<int?>(tanPuntiBase),
      'taegPuntiBase': serializer.toJson<int?>(taegPuntiBase),
      'primaRata': serializer.toJson<String>(primaRata),
      'frequenza': serializer.toJson<String>(frequenza),
      'portafoglioId': serializer.toJson<String?>(portafoglioId),
      'categoriaId': serializer.toJson<String?>(categoriaId),
      'valuta': serializer.toJson<String>(valuta),
      'note': serializer.toJson<String>(note),
      'archiviato': serializer.toJson<bool>(archiviato),
    };
  }

  Prestito copyWith({
    String? id,
    String? aggiornatoIl,
    bool? eliminato,
    String? nome,
    String? tipo,
    String? finanziatore,
    int? capitaleMinimo,
    int? numeroRate,
    int? importoRataMinimo,
    Value<int?> tanPuntiBase = const Value.absent(),
    Value<int?> taegPuntiBase = const Value.absent(),
    String? primaRata,
    String? frequenza,
    Value<String?> portafoglioId = const Value.absent(),
    Value<String?> categoriaId = const Value.absent(),
    String? valuta,
    String? note,
    bool? archiviato,
  }) => Prestito(
    id: id ?? this.id,
    aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
    eliminato: eliminato ?? this.eliminato,
    nome: nome ?? this.nome,
    tipo: tipo ?? this.tipo,
    finanziatore: finanziatore ?? this.finanziatore,
    capitaleMinimo: capitaleMinimo ?? this.capitaleMinimo,
    numeroRate: numeroRate ?? this.numeroRate,
    importoRataMinimo: importoRataMinimo ?? this.importoRataMinimo,
    tanPuntiBase: tanPuntiBase.present ? tanPuntiBase.value : this.tanPuntiBase,
    taegPuntiBase: taegPuntiBase.present
        ? taegPuntiBase.value
        : this.taegPuntiBase,
    primaRata: primaRata ?? this.primaRata,
    frequenza: frequenza ?? this.frequenza,
    portafoglioId: portafoglioId.present
        ? portafoglioId.value
        : this.portafoglioId,
    categoriaId: categoriaId.present ? categoriaId.value : this.categoriaId,
    valuta: valuta ?? this.valuta,
    note: note ?? this.note,
    archiviato: archiviato ?? this.archiviato,
  );
  Prestito copyWithCompanion(PrestitiCompanion data) {
    return Prestito(
      id: data.id.present ? data.id.value : this.id,
      aggiornatoIl: data.aggiornatoIl.present
          ? data.aggiornatoIl.value
          : this.aggiornatoIl,
      eliminato: data.eliminato.present ? data.eliminato.value : this.eliminato,
      nome: data.nome.present ? data.nome.value : this.nome,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      finanziatore: data.finanziatore.present
          ? data.finanziatore.value
          : this.finanziatore,
      capitaleMinimo: data.capitaleMinimo.present
          ? data.capitaleMinimo.value
          : this.capitaleMinimo,
      numeroRate: data.numeroRate.present
          ? data.numeroRate.value
          : this.numeroRate,
      importoRataMinimo: data.importoRataMinimo.present
          ? data.importoRataMinimo.value
          : this.importoRataMinimo,
      tanPuntiBase: data.tanPuntiBase.present
          ? data.tanPuntiBase.value
          : this.tanPuntiBase,
      taegPuntiBase: data.taegPuntiBase.present
          ? data.taegPuntiBase.value
          : this.taegPuntiBase,
      primaRata: data.primaRata.present ? data.primaRata.value : this.primaRata,
      frequenza: data.frequenza.present ? data.frequenza.value : this.frequenza,
      portafoglioId: data.portafoglioId.present
          ? data.portafoglioId.value
          : this.portafoglioId,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      valuta: data.valuta.present ? data.valuta.value : this.valuta,
      note: data.note.present ? data.note.value : this.note,
      archiviato: data.archiviato.present
          ? data.archiviato.value
          : this.archiviato,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prestito(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('nome: $nome, ')
          ..write('tipo: $tipo, ')
          ..write('finanziatore: $finanziatore, ')
          ..write('capitaleMinimo: $capitaleMinimo, ')
          ..write('numeroRate: $numeroRate, ')
          ..write('importoRataMinimo: $importoRataMinimo, ')
          ..write('tanPuntiBase: $tanPuntiBase, ')
          ..write('taegPuntiBase: $taegPuntiBase, ')
          ..write('primaRata: $primaRata, ')
          ..write('frequenza: $frequenza, ')
          ..write('portafoglioId: $portafoglioId, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('valuta: $valuta, ')
          ..write('note: $note, ')
          ..write('archiviato: $archiviato')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aggiornatoIl,
    eliminato,
    nome,
    tipo,
    finanziatore,
    capitaleMinimo,
    numeroRate,
    importoRataMinimo,
    tanPuntiBase,
    taegPuntiBase,
    primaRata,
    frequenza,
    portafoglioId,
    categoriaId,
    valuta,
    note,
    archiviato,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prestito &&
          other.id == this.id &&
          other.aggiornatoIl == this.aggiornatoIl &&
          other.eliminato == this.eliminato &&
          other.nome == this.nome &&
          other.tipo == this.tipo &&
          other.finanziatore == this.finanziatore &&
          other.capitaleMinimo == this.capitaleMinimo &&
          other.numeroRate == this.numeroRate &&
          other.importoRataMinimo == this.importoRataMinimo &&
          other.tanPuntiBase == this.tanPuntiBase &&
          other.taegPuntiBase == this.taegPuntiBase &&
          other.primaRata == this.primaRata &&
          other.frequenza == this.frequenza &&
          other.portafoglioId == this.portafoglioId &&
          other.categoriaId == this.categoriaId &&
          other.valuta == this.valuta &&
          other.note == this.note &&
          other.archiviato == this.archiviato);
}

class PrestitiCompanion extends UpdateCompanion<Prestito> {
  final Value<String> id;
  final Value<String> aggiornatoIl;
  final Value<bool> eliminato;
  final Value<String> nome;
  final Value<String> tipo;
  final Value<String> finanziatore;
  final Value<int> capitaleMinimo;
  final Value<int> numeroRate;
  final Value<int> importoRataMinimo;
  final Value<int?> tanPuntiBase;
  final Value<int?> taegPuntiBase;
  final Value<String> primaRata;
  final Value<String> frequenza;
  final Value<String?> portafoglioId;
  final Value<String?> categoriaId;
  final Value<String> valuta;
  final Value<String> note;
  final Value<bool> archiviato;
  final Value<int> rowid;
  const PrestitiCompanion({
    this.id = const Value.absent(),
    this.aggiornatoIl = const Value.absent(),
    this.eliminato = const Value.absent(),
    this.nome = const Value.absent(),
    this.tipo = const Value.absent(),
    this.finanziatore = const Value.absent(),
    this.capitaleMinimo = const Value.absent(),
    this.numeroRate = const Value.absent(),
    this.importoRataMinimo = const Value.absent(),
    this.tanPuntiBase = const Value.absent(),
    this.taegPuntiBase = const Value.absent(),
    this.primaRata = const Value.absent(),
    this.frequenza = const Value.absent(),
    this.portafoglioId = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.valuta = const Value.absent(),
    this.note = const Value.absent(),
    this.archiviato = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrestitiCompanion.insert({
    required String id,
    required String aggiornatoIl,
    this.eliminato = const Value.absent(),
    required String nome,
    required String tipo,
    this.finanziatore = const Value.absent(),
    required int capitaleMinimo,
    required int numeroRate,
    required int importoRataMinimo,
    this.tanPuntiBase = const Value.absent(),
    this.taegPuntiBase = const Value.absent(),
    required String primaRata,
    this.frequenza = const Value.absent(),
    this.portafoglioId = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.valuta = const Value.absent(),
    this.note = const Value.absent(),
    this.archiviato = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aggiornatoIl = Value(aggiornatoIl),
       nome = Value(nome),
       tipo = Value(tipo),
       capitaleMinimo = Value(capitaleMinimo),
       numeroRate = Value(numeroRate),
       importoRataMinimo = Value(importoRataMinimo),
       primaRata = Value(primaRata);
  static Insertable<Prestito> custom({
    Expression<String>? id,
    Expression<String>? aggiornatoIl,
    Expression<bool>? eliminato,
    Expression<String>? nome,
    Expression<String>? tipo,
    Expression<String>? finanziatore,
    Expression<int>? capitaleMinimo,
    Expression<int>? numeroRate,
    Expression<int>? importoRataMinimo,
    Expression<int>? tanPuntiBase,
    Expression<int>? taegPuntiBase,
    Expression<String>? primaRata,
    Expression<String>? frequenza,
    Expression<String>? portafoglioId,
    Expression<String>? categoriaId,
    Expression<String>? valuta,
    Expression<String>? note,
    Expression<bool>? archiviato,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggiornatoIl != null) 'aggiornato_il': aggiornatoIl,
      if (eliminato != null) 'eliminato': eliminato,
      if (nome != null) 'nome': nome,
      if (tipo != null) 'tipo': tipo,
      if (finanziatore != null) 'finanziatore': finanziatore,
      if (capitaleMinimo != null) 'capitale_minimo': capitaleMinimo,
      if (numeroRate != null) 'numero_rate': numeroRate,
      if (importoRataMinimo != null) 'importo_rata_minimo': importoRataMinimo,
      if (tanPuntiBase != null) 'tan_punti_base': tanPuntiBase,
      if (taegPuntiBase != null) 'taeg_punti_base': taegPuntiBase,
      if (primaRata != null) 'prima_rata': primaRata,
      if (frequenza != null) 'frequenza': frequenza,
      if (portafoglioId != null) 'portafoglio_id': portafoglioId,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (valuta != null) 'valuta': valuta,
      if (note != null) 'note': note,
      if (archiviato != null) 'archiviato': archiviato,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrestitiCompanion copyWith({
    Value<String>? id,
    Value<String>? aggiornatoIl,
    Value<bool>? eliminato,
    Value<String>? nome,
    Value<String>? tipo,
    Value<String>? finanziatore,
    Value<int>? capitaleMinimo,
    Value<int>? numeroRate,
    Value<int>? importoRataMinimo,
    Value<int?>? tanPuntiBase,
    Value<int?>? taegPuntiBase,
    Value<String>? primaRata,
    Value<String>? frequenza,
    Value<String?>? portafoglioId,
    Value<String?>? categoriaId,
    Value<String>? valuta,
    Value<String>? note,
    Value<bool>? archiviato,
    Value<int>? rowid,
  }) {
    return PrestitiCompanion(
      id: id ?? this.id,
      aggiornatoIl: aggiornatoIl ?? this.aggiornatoIl,
      eliminato: eliminato ?? this.eliminato,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      finanziatore: finanziatore ?? this.finanziatore,
      capitaleMinimo: capitaleMinimo ?? this.capitaleMinimo,
      numeroRate: numeroRate ?? this.numeroRate,
      importoRataMinimo: importoRataMinimo ?? this.importoRataMinimo,
      tanPuntiBase: tanPuntiBase ?? this.tanPuntiBase,
      taegPuntiBase: taegPuntiBase ?? this.taegPuntiBase,
      primaRata: primaRata ?? this.primaRata,
      frequenza: frequenza ?? this.frequenza,
      portafoglioId: portafoglioId ?? this.portafoglioId,
      categoriaId: categoriaId ?? this.categoriaId,
      valuta: valuta ?? this.valuta,
      note: note ?? this.note,
      archiviato: archiviato ?? this.archiviato,
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
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (finanziatore.present) {
      map['finanziatore'] = Variable<String>(finanziatore.value);
    }
    if (capitaleMinimo.present) {
      map['capitale_minimo'] = Variable<int>(capitaleMinimo.value);
    }
    if (numeroRate.present) {
      map['numero_rate'] = Variable<int>(numeroRate.value);
    }
    if (importoRataMinimo.present) {
      map['importo_rata_minimo'] = Variable<int>(importoRataMinimo.value);
    }
    if (tanPuntiBase.present) {
      map['tan_punti_base'] = Variable<int>(tanPuntiBase.value);
    }
    if (taegPuntiBase.present) {
      map['taeg_punti_base'] = Variable<int>(taegPuntiBase.value);
    }
    if (primaRata.present) {
      map['prima_rata'] = Variable<String>(primaRata.value);
    }
    if (frequenza.present) {
      map['frequenza'] = Variable<String>(frequenza.value);
    }
    if (portafoglioId.present) {
      map['portafoglio_id'] = Variable<String>(portafoglioId.value);
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<String>(categoriaId.value);
    }
    if (valuta.present) {
      map['valuta'] = Variable<String>(valuta.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (archiviato.present) {
      map['archiviato'] = Variable<bool>(archiviato.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrestitiCompanion(')
          ..write('id: $id, ')
          ..write('aggiornatoIl: $aggiornatoIl, ')
          ..write('eliminato: $eliminato, ')
          ..write('nome: $nome, ')
          ..write('tipo: $tipo, ')
          ..write('finanziatore: $finanziatore, ')
          ..write('capitaleMinimo: $capitaleMinimo, ')
          ..write('numeroRate: $numeroRate, ')
          ..write('importoRataMinimo: $importoRataMinimo, ')
          ..write('tanPuntiBase: $tanPuntiBase, ')
          ..write('taegPuntiBase: $taegPuntiBase, ')
          ..write('primaRata: $primaRata, ')
          ..write('frequenza: $frequenza, ')
          ..write('portafoglioId: $portafoglioId, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('valuta: $valuta, ')
          ..write('note: $note, ')
          ..write('archiviato: $archiviato, ')
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
  late final $PianificazioniTable pianificazioni = $PianificazioniTable(this);
  late final $MovimentiTable movimenti = $MovimentiTable(this);
  late final $EtichetteTable etichette = $EtichetteTable(this);
  late final $MovimentiEtichetteTable movimentiEtichette =
      $MovimentiEtichetteTable(this);
  late final $VociCostoTable vociCosto = $VociCostoTable(this);
  late final $ImportiVoceTable importiVoce = $ImportiVoceTable(this);
  late final $VariazioniMeseTable variazioniMese = $VariazioniMeseTable(this);
  late final $CarteCreditoTable carteCredito = $CarteCreditoTable(this);
  late final $PrestitiTable prestiti = $PrestitiTable(this);
  late final $ImpostazioniTable impostazioni = $ImpostazioniTable(this);
  late final Index movimentiPianificatiUnici = Index(
    'movimenti_pianificati_unici',
    'CREATE UNIQUE INDEX movimenti_pianificati_unici ON movimenti (pianificazione_id, data_prevista)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    definizioniTipo,
    portafogli,
    categorie,
    pianificazioni,
    movimenti,
    etichette,
    movimentiEtichette,
    vociCosto,
    importiVoce,
    variazioniMese,
    carteCredito,
    prestiti,
    impostazioni,
    movimentiPianificatiUnici,
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

  static MultiTypedResultKey<$PianificazioniTable, List<Pianificazione>>
  _pianificazioniRefsTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.pianificazioni,
    aliasName: 'definizioni_tipo__id__pianificazioni__tipo_id',
  );

  $$PianificazioniTableProcessedTableManager get pianificazioniRefs {
    final manager = $$PianificazioniTableTableManager(
      $_db,
      $_db.pianificazioni,
    ).filter((f) => f.tipoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pianificazioniRefsTable($_db));
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

  Expression<bool> pianificazioniRefs(
    Expression<bool> Function($$PianificazioniTableFilterComposer f) f,
  ) {
    final $$PianificazioniTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.tipoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableFilterComposer(
            $db: $db,
            $table: $db.pianificazioni,
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

  Expression<T> pianificazioniRefs<T extends Object>(
    Expression<T> Function($$PianificazioniTableAnnotationComposer a) f,
  ) {
    final $$PianificazioniTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.tipoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableAnnotationComposer(
            $db: $db,
            $table: $db.pianificazioni,
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
          PrefetchHooks Function({
            bool portafogliRefs,
            bool pianificazioniRefs,
            bool movimentiRefs,
          })
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
              ({
                portafogliRefs = false,
                pianificazioniRefs = false,
                movimentiRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (portafogliRefs) db.portafogli,
                    if (pianificazioniRefs) db.pianificazioni,
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
                      if (pianificazioniRefs)
                        await $_getPrefetchedData<
                          DefinizioneTipo,
                          $DefinizioniTipoTable,
                          Pianificazione
                        >(
                          currentTable: table,
                          referencedTable: $$DefinizioniTipoTableReferences
                              ._pianificazioniRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DefinizioniTipoTableReferences(
                                db,
                                table,
                                p0,
                              ).pianificazioniRefs,
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
      PrefetchHooks Function({
        bool portafogliRefs,
        bool pianificazioniRefs,
        bool movimentiRefs,
      })
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

  static MultiTypedResultKey<$PianificazioniTable, List<Pianificazione>>
  _pianificazioniInUscitaTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.pianificazioni,
    aliasName: 'portafogli__id__pianificazioni__portafoglio_id',
  );

  $$PianificazioniTableProcessedTableManager get pianificazioniInUscita {
    final manager = $$PianificazioniTableTableManager(
      $_db,
      $_db.pianificazioni,
    ).filter((f) => f.portafoglioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pianificazioniInUscitaTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PianificazioniTable, List<Pianificazione>>
  _pianificazioniInEntrataTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.pianificazioni,
    aliasName: 'portafogli__id__pianificazioni__destinazione_id',
  );

  $$PianificazioniTableProcessedTableManager get pianificazioniInEntrata {
    final manager = $$PianificazioniTableTableManager(
      $_db,
      $_db.pianificazioni,
    ).filter((f) => f.destinazioneId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pianificazioniInEntrataTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  static MultiTypedResultKey<$CarteCreditoTable, List<CartaCredito>>
  _cartaDelPortafoglioTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.carteCredito,
    aliasName: 'portafogli__id__carte_credito__portafoglio_id',
  );

  $$CarteCreditoTableProcessedTableManager get cartaDelPortafoglio {
    final manager = $$CarteCreditoTableTableManager(
      $_db,
      $_db.carteCredito,
    ).filter((f) => f.portafoglioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cartaDelPortafoglioTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CarteCreditoTable, List<CartaCredito>>
  _carteAddebitateTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.carteCredito,
    aliasName: 'portafogli__id__carte_credito__conto_addebito_id',
  );

  $$CarteCreditoTableProcessedTableManager get carteAddebitate {
    final manager = $$CarteCreditoTableTableManager($_db, $_db.carteCredito)
        .filter(
          (f) => f.contoAddebitoId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_carteAddebitateTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PrestitiTable, List<Prestito>> _prestitiRefsTable(
    _$Archivio db,
  ) => MultiTypedResultKey.fromTable(
    db.prestiti,
    aliasName: 'portafogli__id__prestiti__portafoglio_id',
  );

  $$PrestitiTableProcessedTableManager get prestitiRefs {
    final manager = $$PrestitiTableTableManager(
      $_db,
      $_db.prestiti,
    ).filter((f) => f.portafoglioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_prestitiRefsTable($_db));
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

  Expression<bool> pianificazioniInUscita(
    Expression<bool> Function($$PianificazioniTableFilterComposer f) f,
  ) {
    final $$PianificazioniTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.portafoglioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableFilterComposer(
            $db: $db,
            $table: $db.pianificazioni,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pianificazioniInEntrata(
    Expression<bool> Function($$PianificazioniTableFilterComposer f) f,
  ) {
    final $$PianificazioniTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.destinazioneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableFilterComposer(
            $db: $db,
            $table: $db.pianificazioni,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  Expression<bool> cartaDelPortafoglio(
    Expression<bool> Function($$CarteCreditoTableFilterComposer f) f,
  ) {
    final $$CarteCreditoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.carteCredito,
      getReferencedColumn: (t) => t.portafoglioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarteCreditoTableFilterComposer(
            $db: $db,
            $table: $db.carteCredito,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> carteAddebitate(
    Expression<bool> Function($$CarteCreditoTableFilterComposer f) f,
  ) {
    final $$CarteCreditoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.carteCredito,
      getReferencedColumn: (t) => t.contoAddebitoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarteCreditoTableFilterComposer(
            $db: $db,
            $table: $db.carteCredito,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> prestitiRefs(
    Expression<bool> Function($$PrestitiTableFilterComposer f) f,
  ) {
    final $$PrestitiTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prestiti,
      getReferencedColumn: (t) => t.portafoglioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrestitiTableFilterComposer(
            $db: $db,
            $table: $db.prestiti,
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

  Expression<T> pianificazioniInUscita<T extends Object>(
    Expression<T> Function($$PianificazioniTableAnnotationComposer a) f,
  ) {
    final $$PianificazioniTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.portafoglioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableAnnotationComposer(
            $db: $db,
            $table: $db.pianificazioni,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pianificazioniInEntrata<T extends Object>(
    Expression<T> Function($$PianificazioniTableAnnotationComposer a) f,
  ) {
    final $$PianificazioniTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.destinazioneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableAnnotationComposer(
            $db: $db,
            $table: $db.pianificazioni,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  Expression<T> cartaDelPortafoglio<T extends Object>(
    Expression<T> Function($$CarteCreditoTableAnnotationComposer a) f,
  ) {
    final $$CarteCreditoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.carteCredito,
      getReferencedColumn: (t) => t.portafoglioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarteCreditoTableAnnotationComposer(
            $db: $db,
            $table: $db.carteCredito,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> carteAddebitate<T extends Object>(
    Expression<T> Function($$CarteCreditoTableAnnotationComposer a) f,
  ) {
    final $$CarteCreditoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.carteCredito,
      getReferencedColumn: (t) => t.contoAddebitoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarteCreditoTableAnnotationComposer(
            $db: $db,
            $table: $db.carteCredito,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> prestitiRefs<T extends Object>(
    Expression<T> Function($$PrestitiTableAnnotationComposer a) f,
  ) {
    final $$PrestitiTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prestiti,
      getReferencedColumn: (t) => t.portafoglioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrestitiTableAnnotationComposer(
            $db: $db,
            $table: $db.prestiti,
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
            bool pianificazioniInUscita,
            bool pianificazioniInEntrata,
            bool movimentiInUscita,
            bool movimentiInEntrata,
            bool cartaDelPortafoglio,
            bool carteAddebitate,
            bool prestitiRefs,
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
                pianificazioniInUscita = false,
                pianificazioniInEntrata = false,
                movimentiInUscita = false,
                movimentiInEntrata = false,
                cartaDelPortafoglio = false,
                carteAddebitate = false,
                prestitiRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pianificazioniInUscita) db.pianificazioni,
                    if (pianificazioniInEntrata) db.pianificazioni,
                    if (movimentiInUscita) db.movimenti,
                    if (movimentiInEntrata) db.movimenti,
                    if (cartaDelPortafoglio) db.carteCredito,
                    if (carteAddebitate) db.carteCredito,
                    if (prestitiRefs) db.prestiti,
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
                      if (pianificazioniInUscita)
                        await $_getPrefetchedData<
                          Portafoglio,
                          $PortafogliTable,
                          Pianificazione
                        >(
                          currentTable: table,
                          referencedTable: $$PortafogliTableReferences
                              ._pianificazioniInUscitaTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PortafogliTableReferences(
                                db,
                                table,
                                p0,
                              ).pianificazioniInUscita,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.portafoglioId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pianificazioniInEntrata)
                        await $_getPrefetchedData<
                          Portafoglio,
                          $PortafogliTable,
                          Pianificazione
                        >(
                          currentTable: table,
                          referencedTable: $$PortafogliTableReferences
                              ._pianificazioniInEntrataTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PortafogliTableReferences(
                                db,
                                table,
                                p0,
                              ).pianificazioniInEntrata,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.destinazioneId == item.id,
                              ),
                          typedResults: items,
                        ),
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
                      if (cartaDelPortafoglio)
                        await $_getPrefetchedData<
                          Portafoglio,
                          $PortafogliTable,
                          CartaCredito
                        >(
                          currentTable: table,
                          referencedTable: $$PortafogliTableReferences
                              ._cartaDelPortafoglioTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PortafogliTableReferences(
                                db,
                                table,
                                p0,
                              ).cartaDelPortafoglio,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.portafoglioId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (carteAddebitate)
                        await $_getPrefetchedData<
                          Portafoglio,
                          $PortafogliTable,
                          CartaCredito
                        >(
                          currentTable: table,
                          referencedTable: $$PortafogliTableReferences
                              ._carteAddebitateTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PortafogliTableReferences(
                                db,
                                table,
                                p0,
                              ).carteAddebitate,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contoAddebitoId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (prestitiRefs)
                        await $_getPrefetchedData<
                          Portafoglio,
                          $PortafogliTable,
                          Prestito
                        >(
                          currentTable: table,
                          referencedTable: $$PortafogliTableReferences
                              ._prestitiRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PortafogliTableReferences(
                                db,
                                table,
                                p0,
                              ).prestitiRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.portafoglioId == item.id,
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
        bool pianificazioniInUscita,
        bool pianificazioniInEntrata,
        bool movimentiInUscita,
        bool movimentiInEntrata,
        bool cartaDelPortafoglio,
        bool carteAddebitate,
        bool prestitiRefs,
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

  static MultiTypedResultKey<$PianificazioniTable, List<Pianificazione>>
  _pianificazioniRefsTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.pianificazioni,
    aliasName: 'categorie__id__pianificazioni__categoria_id',
  );

  $$PianificazioniTableProcessedTableManager get pianificazioniRefs {
    final manager = $$PianificazioniTableTableManager(
      $_db,
      $_db.pianificazioni,
    ).filter((f) => f.categoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pianificazioniRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  static MultiTypedResultKey<$VociCostoTable, List<VoceCosto>>
  _vociCostoRefsTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.vociCosto,
    aliasName: 'categorie__id__voci_costo__categoria_id',
  );

  $$VociCostoTableProcessedTableManager get vociCostoRefs {
    final manager = $$VociCostoTableTableManager(
      $_db,
      $_db.vociCosto,
    ).filter((f) => f.categoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vociCostoRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PrestitiTable, List<Prestito>> _prestitiRefsTable(
    _$Archivio db,
  ) => MultiTypedResultKey.fromTable(
    db.prestiti,
    aliasName: 'categorie__id__prestiti__categoria_id',
  );

  $$PrestitiTableProcessedTableManager get prestitiRefs {
    final manager = $$PrestitiTableTableManager(
      $_db,
      $_db.prestiti,
    ).filter((f) => f.categoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_prestitiRefsTable($_db));
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

  Expression<bool> pianificazioniRefs(
    Expression<bool> Function($$PianificazioniTableFilterComposer f) f,
  ) {
    final $$PianificazioniTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableFilterComposer(
            $db: $db,
            $table: $db.pianificazioni,
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

  Expression<bool> vociCostoRefs(
    Expression<bool> Function($$VociCostoTableFilterComposer f) f,
  ) {
    final $$VociCostoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vociCosto,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VociCostoTableFilterComposer(
            $db: $db,
            $table: $db.vociCosto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> prestitiRefs(
    Expression<bool> Function($$PrestitiTableFilterComposer f) f,
  ) {
    final $$PrestitiTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prestiti,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrestitiTableFilterComposer(
            $db: $db,
            $table: $db.prestiti,
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

  Expression<T> pianificazioniRefs<T extends Object>(
    Expression<T> Function($$PianificazioniTableAnnotationComposer a) f,
  ) {
    final $$PianificazioniTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableAnnotationComposer(
            $db: $db,
            $table: $db.pianificazioni,
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

  Expression<T> vociCostoRefs<T extends Object>(
    Expression<T> Function($$VociCostoTableAnnotationComposer a) f,
  ) {
    final $$VociCostoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vociCosto,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VociCostoTableAnnotationComposer(
            $db: $db,
            $table: $db.vociCosto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> prestitiRefs<T extends Object>(
    Expression<T> Function($$PrestitiTableAnnotationComposer a) f,
  ) {
    final $$PrestitiTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prestiti,
      getReferencedColumn: (t) => t.categoriaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrestitiTableAnnotationComposer(
            $db: $db,
            $table: $db.prestiti,
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
          PrefetchHooks Function({
            bool padreId,
            bool pianificazioniRefs,
            bool movimentiRefs,
            bool vociCostoRefs,
            bool prestitiRefs,
          })
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
          prefetchHooksCallback:
              ({
                padreId = false,
                pianificazioniRefs = false,
                movimentiRefs = false,
                vociCostoRefs = false,
                prestitiRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pianificazioniRefs) db.pianificazioni,
                    if (movimentiRefs) db.movimenti,
                    if (vociCostoRefs) db.vociCosto,
                    if (prestitiRefs) db.prestiti,
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
                      if (pianificazioniRefs)
                        await $_getPrefetchedData<
                          Categoria,
                          $CategorieTable,
                          Pianificazione
                        >(
                          currentTable: table,
                          referencedTable: $$CategorieTableReferences
                              ._pianificazioniRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategorieTableReferences(
                                db,
                                table,
                                p0,
                              ).pianificazioniRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoriaId == item.id,
                              ),
                          typedResults: items,
                        ),
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
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoriaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (vociCostoRefs)
                        await $_getPrefetchedData<
                          Categoria,
                          $CategorieTable,
                          VoceCosto
                        >(
                          currentTable: table,
                          referencedTable: $$CategorieTableReferences
                              ._vociCostoRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategorieTableReferences(
                                db,
                                table,
                                p0,
                              ).vociCostoRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoriaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (prestitiRefs)
                        await $_getPrefetchedData<
                          Categoria,
                          $CategorieTable,
                          Prestito
                        >(
                          currentTable: table,
                          referencedTable: $$CategorieTableReferences
                              ._prestitiRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategorieTableReferences(
                                db,
                                table,
                                p0,
                              ).prestitiRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
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
      PrefetchHooks Function({
        bool padreId,
        bool pianificazioniRefs,
        bool movimentiRefs,
        bool vociCostoRefs,
        bool prestitiRefs,
      })
    >;
typedef $$PianificazioniTableCreateCompanionBuilder =
    PianificazioniCompanion Function({
      required String id,
      required String aggiornatoIl,
      Value<bool> eliminato,
      required String origine,
      Value<String?> origineId,
      Value<String?> portafoglioId,
      Value<String?> destinazioneId,
      Value<String?> tipoId,
      Value<String?> categoriaId,
      Value<String> descrizione,
      Value<int?> importoMinimo,
      Value<String> valuta,
      required String inizio,
      Value<String> frequenza,
      Value<String?> fine,
      Value<int?> occorrenze,
      Value<int> avvisoGiorni,
      Value<bool> attiva,
      Value<int> rowid,
    });
typedef $$PianificazioniTableUpdateCompanionBuilder =
    PianificazioniCompanion Function({
      Value<String> id,
      Value<String> aggiornatoIl,
      Value<bool> eliminato,
      Value<String> origine,
      Value<String?> origineId,
      Value<String?> portafoglioId,
      Value<String?> destinazioneId,
      Value<String?> tipoId,
      Value<String?> categoriaId,
      Value<String> descrizione,
      Value<int?> importoMinimo,
      Value<String> valuta,
      Value<String> inizio,
      Value<String> frequenza,
      Value<String?> fine,
      Value<int?> occorrenze,
      Value<int> avvisoGiorni,
      Value<bool> attiva,
      Value<int> rowid,
    });

final class $$PianificazioniTableReferences
    extends BaseReferences<_$Archivio, $PianificazioniTable, Pianificazione> {
  $$PianificazioniTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PortafogliTable _portafoglioIdTable(_$Archivio db) => db.portafogli
      .createAlias('pianificazioni__portafoglio_id__portafogli__id');

  $$PortafogliTableProcessedTableManager? get portafoglioId {
    final $_column = $_itemColumn<String>('portafoglio_id');
    if ($_column == null) return null;
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

  static $PortafogliTable _destinazioneIdTable(_$Archivio db) => db.portafogli
      .createAlias('pianificazioni__destinazione_id__portafogli__id');

  $$PortafogliTableProcessedTableManager? get destinazioneId {
    final $_column = $_itemColumn<String>('destinazione_id');
    if ($_column == null) return null;
    final manager = $$PortafogliTableTableManager(
      $_db,
      $_db.portafogli,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_destinazioneIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DefinizioniTipoTable _tipoIdTable(_$Archivio db) => db.definizioniTipo
      .createAlias('pianificazioni__tipo_id__definizioni_tipo__id');

  $$DefinizioniTipoTableProcessedTableManager? get tipoId {
    final $_column = $_itemColumn<String>('tipo_id');
    if ($_column == null) return null;
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

  static $CategorieTable _categoriaIdTable(_$Archivio db) =>
      db.categorie.createAlias('pianificazioni__categoria_id__categorie__id');

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

  static MultiTypedResultKey<$MovimentiTable, List<Movimento>>
  _movimentiGeneratiTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.movimenti,
    aliasName: 'pianificazioni__id__movimenti__pianificazione_id',
  );

  $$MovimentiTableProcessedTableManager get movimentiGenerati {
    final manager = $$MovimentiTableTableManager($_db, $_db.movimenti).filter(
      (f) => f.pianificazioneId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_movimentiGeneratiTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PianificazioniTableFilterComposer
    extends Composer<_$Archivio, $PianificazioniTable> {
  $$PianificazioniTableFilterComposer({
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

  ColumnFilters<String> get origine => $composableBuilder(
    column: $table.origine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origineId => $composableBuilder(
    column: $table.origineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
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

  ColumnFilters<String> get inizio => $composableBuilder(
    column: $table.inizio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequenza => $composableBuilder(
    column: $table.frequenza,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fine => $composableBuilder(
    column: $table.fine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occorrenze => $composableBuilder(
    column: $table.occorrenze,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avvisoGiorni => $composableBuilder(
    column: $table.avvisoGiorni,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get attiva => $composableBuilder(
    column: $table.attiva,
    builder: (column) => ColumnFilters(column),
  );

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

  $$PortafogliTableFilterComposer get destinazioneId {
    final $$PortafogliTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinazioneId,
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

  Expression<bool> movimentiGenerati(
    Expression<bool> Function($$MovimentiTableFilterComposer f) f,
  ) {
    final $$MovimentiTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.pianificazioneId,
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

class $$PianificazioniTableOrderingComposer
    extends Composer<_$Archivio, $PianificazioniTable> {
  $$PianificazioniTableOrderingComposer({
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

  ColumnOrderings<String> get origine => $composableBuilder(
    column: $table.origine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origineId => $composableBuilder(
    column: $table.origineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
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

  ColumnOrderings<String> get inizio => $composableBuilder(
    column: $table.inizio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequenza => $composableBuilder(
    column: $table.frequenza,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fine => $composableBuilder(
    column: $table.fine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occorrenze => $composableBuilder(
    column: $table.occorrenze,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avvisoGiorni => $composableBuilder(
    column: $table.avvisoGiorni,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get attiva => $composableBuilder(
    column: $table.attiva,
    builder: (column) => ColumnOrderings(column),
  );

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

  $$PortafogliTableOrderingComposer get destinazioneId {
    final $$PortafogliTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinazioneId,
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

class $$PianificazioniTableAnnotationComposer
    extends Composer<_$Archivio, $PianificazioniTable> {
  $$PianificazioniTableAnnotationComposer({
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

  GeneratedColumn<String> get origine =>
      $composableBuilder(column: $table.origine, builder: (column) => column);

  GeneratedColumn<String> get origineId =>
      $composableBuilder(column: $table.origineId, builder: (column) => column);

  GeneratedColumn<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
    builder: (column) => column,
  );

  GeneratedColumn<int> get importoMinimo => $composableBuilder(
    column: $table.importoMinimo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valuta =>
      $composableBuilder(column: $table.valuta, builder: (column) => column);

  GeneratedColumn<String> get inizio =>
      $composableBuilder(column: $table.inizio, builder: (column) => column);

  GeneratedColumn<String> get frequenza =>
      $composableBuilder(column: $table.frequenza, builder: (column) => column);

  GeneratedColumn<String> get fine =>
      $composableBuilder(column: $table.fine, builder: (column) => column);

  GeneratedColumn<int> get occorrenze => $composableBuilder(
    column: $table.occorrenze,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avvisoGiorni => $composableBuilder(
    column: $table.avvisoGiorni,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get attiva =>
      $composableBuilder(column: $table.attiva, builder: (column) => column);

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

  $$PortafogliTableAnnotationComposer get destinazioneId {
    final $$PortafogliTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinazioneId,
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

  Expression<T> movimentiGenerati<T extends Object>(
    Expression<T> Function($$MovimentiTableAnnotationComposer a) f,
  ) {
    final $$MovimentiTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimenti,
      getReferencedColumn: (t) => t.pianificazioneId,
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

class $$PianificazioniTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $PianificazioniTable,
          Pianificazione,
          $$PianificazioniTableFilterComposer,
          $$PianificazioniTableOrderingComposer,
          $$PianificazioniTableAnnotationComposer,
          $$PianificazioniTableCreateCompanionBuilder,
          $$PianificazioniTableUpdateCompanionBuilder,
          (Pianificazione, $$PianificazioniTableReferences),
          Pianificazione,
          PrefetchHooks Function({
            bool portafoglioId,
            bool destinazioneId,
            bool tipoId,
            bool categoriaId,
            bool movimentiGenerati,
          })
        > {
  $$PianificazioniTableTableManager(_$Archivio db, $PianificazioniTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PianificazioniTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PianificazioniTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PianificazioniTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String> origine = const Value.absent(),
                Value<String?> origineId = const Value.absent(),
                Value<String?> portafoglioId = const Value.absent(),
                Value<String?> destinazioneId = const Value.absent(),
                Value<String?> tipoId = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                Value<String> descrizione = const Value.absent(),
                Value<int?> importoMinimo = const Value.absent(),
                Value<String> valuta = const Value.absent(),
                Value<String> inizio = const Value.absent(),
                Value<String> frequenza = const Value.absent(),
                Value<String?> fine = const Value.absent(),
                Value<int?> occorrenze = const Value.absent(),
                Value<int> avvisoGiorni = const Value.absent(),
                Value<bool> attiva = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PianificazioniCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                origine: origine,
                origineId: origineId,
                portafoglioId: portafoglioId,
                destinazioneId: destinazioneId,
                tipoId: tipoId,
                categoriaId: categoriaId,
                descrizione: descrizione,
                importoMinimo: importoMinimo,
                valuta: valuta,
                inizio: inizio,
                frequenza: frequenza,
                fine: fine,
                occorrenze: occorrenze,
                avvisoGiorni: avvisoGiorni,
                attiva: attiva,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                required String origine,
                Value<String?> origineId = const Value.absent(),
                Value<String?> portafoglioId = const Value.absent(),
                Value<String?> destinazioneId = const Value.absent(),
                Value<String?> tipoId = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                Value<String> descrizione = const Value.absent(),
                Value<int?> importoMinimo = const Value.absent(),
                Value<String> valuta = const Value.absent(),
                required String inizio,
                Value<String> frequenza = const Value.absent(),
                Value<String?> fine = const Value.absent(),
                Value<int?> occorrenze = const Value.absent(),
                Value<int> avvisoGiorni = const Value.absent(),
                Value<bool> attiva = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PianificazioniCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                origine: origine,
                origineId: origineId,
                portafoglioId: portafoglioId,
                destinazioneId: destinazioneId,
                tipoId: tipoId,
                categoriaId: categoriaId,
                descrizione: descrizione,
                importoMinimo: importoMinimo,
                valuta: valuta,
                inizio: inizio,
                frequenza: frequenza,
                fine: fine,
                occorrenze: occorrenze,
                avvisoGiorni: avvisoGiorni,
                attiva: attiva,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PianificazioniTable, Pianificazione>(table),
                  $$PianificazioniTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                portafoglioId = false,
                destinazioneId = false,
                tipoId = false,
                categoriaId = false,
                movimentiGenerati = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movimentiGenerati) db.movimenti,
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
                        if (portafoglioId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.portafoglioId,
                            referencedTable: $$PianificazioniTableReferences
                                ._portafoglioIdTable(db),
                            referencedColumn: $$PianificazioniTableReferences
                                ._portafoglioIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (destinazioneId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.destinazioneId,
                            referencedTable: $$PianificazioniTableReferences
                                ._destinazioneIdTable(db),
                            referencedColumn: $$PianificazioniTableReferences
                                ._destinazioneIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (tipoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tipoId,
                            referencedTable: $$PianificazioniTableReferences
                                ._tipoIdTable(db),
                            referencedColumn: $$PianificazioniTableReferences
                                ._tipoIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (categoriaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoriaId,
                            referencedTable: $$PianificazioniTableReferences
                                ._categoriaIdTable(db),
                            referencedColumn: $$PianificazioniTableReferences
                                ._categoriaIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movimentiGenerati)
                        await $_getPrefetchedData<
                          Pianificazione,
                          $PianificazioniTable,
                          Movimento
                        >(
                          currentTable: table,
                          referencedTable: $$PianificazioniTableReferences
                              ._movimentiGeneratiTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PianificazioniTableReferences(
                                db,
                                table,
                                p0,
                              ).movimentiGenerati,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pianificazioneId == item.id,
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

typedef $$PianificazioniTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $PianificazioniTable,
      Pianificazione,
      $$PianificazioniTableFilterComposer,
      $$PianificazioniTableOrderingComposer,
      $$PianificazioniTableAnnotationComposer,
      $$PianificazioniTableCreateCompanionBuilder,
      $$PianificazioniTableUpdateCompanionBuilder,
      (Pianificazione, $$PianificazioniTableReferences),
      Pianificazione,
      PrefetchHooks Function({
        bool portafoglioId,
        bool destinazioneId,
        bool tipoId,
        bool categoriaId,
        bool movimentiGenerati,
      })
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
  Value<String?> pianificazioneId,
  Value<String?> dataPrevista,
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
  Value<String?> pianificazioneId,
  Value<String?> dataPrevista,
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

  static $PianificazioniTable _pianificazioneIdTable(_$Archivio db) => db
      .pianificazioni
      .createAlias('movimenti__pianificazione_id__pianificazioni__id');

  $$PianificazioniTableProcessedTableManager? get pianificazioneId {
    final $_column = $_itemColumn<String>('pianificazione_id');
    if ($_column == null) return null;
    final manager = $$PianificazioniTableTableManager(
      $_db,
      $_db.pianificazioni,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pianificazioneIdTable($_db));
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

  ColumnFilters<String> get dataPrevista => $composableBuilder(
    column: $table.dataPrevista,
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

  $$PianificazioniTableFilterComposer get pianificazioneId {
    final $$PianificazioniTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pianificazioneId,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableFilterComposer(
            $db: $db,
            $table: $db.pianificazioni,
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

  ColumnOrderings<String> get dataPrevista => $composableBuilder(
    column: $table.dataPrevista,
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

  $$PianificazioniTableOrderingComposer get pianificazioneId {
    final $$PianificazioniTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pianificazioneId,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableOrderingComposer(
            $db: $db,
            $table: $db.pianificazioni,
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

  GeneratedColumn<String> get dataPrevista => $composableBuilder(
    column: $table.dataPrevista,
    builder: (column) => column,
  );

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

  $$PianificazioniTableAnnotationComposer get pianificazioneId {
    final $$PianificazioniTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pianificazioneId,
      referencedTable: $db.pianificazioni,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PianificazioniTableAnnotationComposer(
            $db: $db,
            $table: $db.pianificazioni,
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
            bool pianificazioneId,
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
                Value<String?> pianificazioneId = const Value.absent(),
                Value<String?> dataPrevista = const Value.absent(),
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
                pianificazioneId: pianificazioneId,
                dataPrevista: dataPrevista,
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
                Value<String?> pianificazioneId = const Value.absent(),
                Value<String?> dataPrevista = const Value.absent(),
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
                pianificazioneId: pianificazioneId,
                dataPrevista: dataPrevista,
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
                pianificazioneId = false,
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
                        if (pianificazioneId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.pianificazioneId,
                            referencedTable: $$MovimentiTableReferences
                                ._pianificazioneIdTable(db),
                            referencedColumn: $$MovimentiTableReferences
                                ._pianificazioneIdTable(db)
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
        bool pianificazioneId,
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
typedef $$VociCostoTableCreateCompanionBuilder = VociCostoCompanion Function({
  required String id,
  required String aggiornatoIl,
  Value<bool> eliminato,
  required String nome,
  required String tipo,
  Value<String?> categoriaId,
  Value<String> valuta,
  Value<bool> archiviata,
  Value<int> ordine,
  Value<int> rowid,
});
typedef $$VociCostoTableUpdateCompanionBuilder = VociCostoCompanion Function({
  Value<String> id,
  Value<String> aggiornatoIl,
  Value<bool> eliminato,
  Value<String> nome,
  Value<String> tipo,
  Value<String?> categoriaId,
  Value<String> valuta,
  Value<bool> archiviata,
  Value<int> ordine,
  Value<int> rowid,
});

final class $$VociCostoTableReferences
    extends BaseReferences<_$Archivio, $VociCostoTable, VoceCosto> {
  $$VociCostoTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategorieTable _categoriaIdTable(_$Archivio db) =>
      db.categorie.createAlias('voci_costo__categoria_id__categorie__id');

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

  static MultiTypedResultKey<$ImportiVoceTable, List<ImportoVoce>>
  _importiVoceRefsTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.importiVoce,
    aliasName: 'voci_costo__id__importi_voce__voce_id',
  );

  $$ImportiVoceTableProcessedTableManager get importiVoceRefs {
    final manager = $$ImportiVoceTableTableManager(
      $_db,
      $_db.importiVoce,
    ).filter((f) => f.voceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_importiVoceRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VariazioniMeseTable, List<VariazioneMese>>
  _variazioniMeseRefsTable(_$Archivio db) => MultiTypedResultKey.fromTable(
    db.variazioniMese,
    aliasName: 'voci_costo__id__variazioni_mese__voce_id',
  );

  $$VariazioniMeseTableProcessedTableManager get variazioniMeseRefs {
    final manager = $$VariazioniMeseTableTableManager(
      $_db,
      $_db.variazioniMese,
    ).filter((f) => f.voceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_variazioniMeseRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VociCostoTableFilterComposer
    extends Composer<_$Archivio, $VociCostoTable> {
  $$VociCostoTableFilterComposer({
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

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valuta => $composableBuilder(
    column: $table.valuta,
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

  Expression<bool> importiVoceRefs(
    Expression<bool> Function($$ImportiVoceTableFilterComposer f) f,
  ) {
    final $$ImportiVoceTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importiVoce,
      getReferencedColumn: (t) => t.voceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportiVoceTableFilterComposer(
            $db: $db,
            $table: $db.importiVoce,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> variazioniMeseRefs(
    Expression<bool> Function($$VariazioniMeseTableFilterComposer f) f,
  ) {
    final $$VariazioniMeseTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.variazioniMese,
      getReferencedColumn: (t) => t.voceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariazioniMeseTableFilterComposer(
            $db: $db,
            $table: $db.variazioniMese,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VociCostoTableOrderingComposer
    extends Composer<_$Archivio, $VociCostoTable> {
  $$VociCostoTableOrderingComposer({
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

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valuta => $composableBuilder(
    column: $table.valuta,
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

class $$VociCostoTableAnnotationComposer
    extends Composer<_$Archivio, $VociCostoTable> {
  $$VociCostoTableAnnotationComposer({
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

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get valuta =>
      $composableBuilder(column: $table.valuta, builder: (column) => column);

  GeneratedColumn<bool> get archiviata => $composableBuilder(
    column: $table.archiviata,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordine =>
      $composableBuilder(column: $table.ordine, builder: (column) => column);

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

  Expression<T> importiVoceRefs<T extends Object>(
    Expression<T> Function($$ImportiVoceTableAnnotationComposer a) f,
  ) {
    final $$ImportiVoceTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importiVoce,
      getReferencedColumn: (t) => t.voceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportiVoceTableAnnotationComposer(
            $db: $db,
            $table: $db.importiVoce,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> variazioniMeseRefs<T extends Object>(
    Expression<T> Function($$VariazioniMeseTableAnnotationComposer a) f,
  ) {
    final $$VariazioniMeseTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.variazioniMese,
      getReferencedColumn: (t) => t.voceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariazioniMeseTableAnnotationComposer(
            $db: $db,
            $table: $db.variazioniMese,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VociCostoTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $VociCostoTable,
          VoceCosto,
          $$VociCostoTableFilterComposer,
          $$VociCostoTableOrderingComposer,
          $$VociCostoTableAnnotationComposer,
          $$VociCostoTableCreateCompanionBuilder,
          $$VociCostoTableUpdateCompanionBuilder,
          (VoceCosto, $$VociCostoTableReferences),
          VoceCosto,
          PrefetchHooks Function({
            bool categoriaId,
            bool importiVoceRefs,
            bool variazioniMeseRefs,
          })
        > {
  $$VociCostoTableTableManager(_$Archivio db, $VociCostoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VociCostoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VociCostoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VociCostoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                Value<String> valuta = const Value.absent(),
                Value<bool> archiviata = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VociCostoCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                nome: nome,
                tipo: tipo,
                categoriaId: categoriaId,
                valuta: valuta,
                archiviata: archiviata,
                ordine: ordine,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                required String nome,
                required String tipo,
                Value<String?> categoriaId = const Value.absent(),
                Value<String> valuta = const Value.absent(),
                Value<bool> archiviata = const Value.absent(),
                Value<int> ordine = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VociCostoCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                nome: nome,
                tipo: tipo,
                categoriaId: categoriaId,
                valuta: valuta,
                archiviata: archiviata,
                ordine: ordine,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VociCostoTable, VoceCosto>(table),
                  $$VociCostoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoriaId = false,
                importiVoceRefs = false,
                variazioniMeseRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (importiVoceRefs) db.importiVoce,
                    if (variazioniMeseRefs) db.variazioniMese,
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
                        if (categoriaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoriaId,
                            referencedTable: $$VociCostoTableReferences
                                ._categoriaIdTable(db),
                            referencedColumn: $$VociCostoTableReferences
                                ._categoriaIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (importiVoceRefs)
                        await $_getPrefetchedData<
                          VoceCosto,
                          $VociCostoTable,
                          ImportoVoce
                        >(
                          currentTable: table,
                          referencedTable: $$VociCostoTableReferences
                              ._importiVoceRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VociCostoTableReferences(
                                db,
                                table,
                                p0,
                              ).importiVoceRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.voceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (variazioniMeseRefs)
                        await $_getPrefetchedData<
                          VoceCosto,
                          $VociCostoTable,
                          VariazioneMese
                        >(
                          currentTable: table,
                          referencedTable: $$VociCostoTableReferences
                              ._variazioniMeseRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VociCostoTableReferences(
                                db,
                                table,
                                p0,
                              ).variazioniMeseRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.voceId == item.id,
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

typedef $$VociCostoTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $VociCostoTable,
      VoceCosto,
      $$VociCostoTableFilterComposer,
      $$VociCostoTableOrderingComposer,
      $$VociCostoTableAnnotationComposer,
      $$VociCostoTableCreateCompanionBuilder,
      $$VociCostoTableUpdateCompanionBuilder,
      (VoceCosto, $$VociCostoTableReferences),
      VoceCosto,
      PrefetchHooks Function({
        bool categoriaId,
        bool importiVoceRefs,
        bool variazioniMeseRefs,
      })
    >;
typedef $$ImportiVoceTableCreateCompanionBuilder =
    ImportiVoceCompanion Function({
      required String id,
      required String aggiornatoIl,
      Value<bool> eliminato,
      required String voceId,
      required int importoMinimo,
      required String validoDal,
      Value<int> rowid,
    });
typedef $$ImportiVoceTableUpdateCompanionBuilder =
    ImportiVoceCompanion Function({
      Value<String> id,
      Value<String> aggiornatoIl,
      Value<bool> eliminato,
      Value<String> voceId,
      Value<int> importoMinimo,
      Value<String> validoDal,
      Value<int> rowid,
    });

final class $$ImportiVoceTableReferences
    extends BaseReferences<_$Archivio, $ImportiVoceTable, ImportoVoce> {
  $$ImportiVoceTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VociCostoTable _voceIdTable(_$Archivio db) =>
      db.vociCosto.createAlias('importi_voce__voce_id__voci_costo__id');

  $$VociCostoTableProcessedTableManager get voceId {
    final $_column = $_itemColumn<String>('voce_id')!;

    final manager = $$VociCostoTableTableManager(
      $_db,
      $_db.vociCosto,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_voceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImportiVoceTableFilterComposer
    extends Composer<_$Archivio, $ImportiVoceTable> {
  $$ImportiVoceTableFilterComposer({
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

  ColumnFilters<String> get validoDal => $composableBuilder(
    column: $table.validoDal,
    builder: (column) => ColumnFilters(column),
  );

  $$VociCostoTableFilterComposer get voceId {
    final $$VociCostoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.voceId,
      referencedTable: $db.vociCosto,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VociCostoTableFilterComposer(
            $db: $db,
            $table: $db.vociCosto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportiVoceTableOrderingComposer
    extends Composer<_$Archivio, $ImportiVoceTable> {
  $$ImportiVoceTableOrderingComposer({
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

  ColumnOrderings<String> get validoDal => $composableBuilder(
    column: $table.validoDal,
    builder: (column) => ColumnOrderings(column),
  );

  $$VociCostoTableOrderingComposer get voceId {
    final $$VociCostoTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.voceId,
      referencedTable: $db.vociCosto,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VociCostoTableOrderingComposer(
            $db: $db,
            $table: $db.vociCosto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportiVoceTableAnnotationComposer
    extends Composer<_$Archivio, $ImportiVoceTable> {
  $$ImportiVoceTableAnnotationComposer({
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

  GeneratedColumn<String> get validoDal =>
      $composableBuilder(column: $table.validoDal, builder: (column) => column);

  $$VociCostoTableAnnotationComposer get voceId {
    final $$VociCostoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.voceId,
      referencedTable: $db.vociCosto,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VociCostoTableAnnotationComposer(
            $db: $db,
            $table: $db.vociCosto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportiVoceTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $ImportiVoceTable,
          ImportoVoce,
          $$ImportiVoceTableFilterComposer,
          $$ImportiVoceTableOrderingComposer,
          $$ImportiVoceTableAnnotationComposer,
          $$ImportiVoceTableCreateCompanionBuilder,
          $$ImportiVoceTableUpdateCompanionBuilder,
          (ImportoVoce, $$ImportiVoceTableReferences),
          ImportoVoce,
          PrefetchHooks Function({bool voceId})
        > {
  $$ImportiVoceTableTableManager(_$Archivio db, $ImportiVoceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportiVoceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportiVoceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportiVoceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String> voceId = const Value.absent(),
                Value<int> importoMinimo = const Value.absent(),
                Value<String> validoDal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportiVoceCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                voceId: voceId,
                importoMinimo: importoMinimo,
                validoDal: validoDal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                required String voceId,
                required int importoMinimo,
                required String validoDal,
                Value<int> rowid = const Value.absent(),
              }) => ImportiVoceCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                voceId: voceId,
                importoMinimo: importoMinimo,
                validoDal: validoDal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportiVoceTable, ImportoVoce>(table),
                  $$ImportiVoceTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({voceId = false}) {
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
                    if (voceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.voceId,
                        referencedTable: $$ImportiVoceTableReferences
                            ._voceIdTable(db),
                        referencedColumn: $$ImportiVoceTableReferences
                            ._voceIdTable(db)
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

typedef $$ImportiVoceTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $ImportiVoceTable,
      ImportoVoce,
      $$ImportiVoceTableFilterComposer,
      $$ImportiVoceTableOrderingComposer,
      $$ImportiVoceTableAnnotationComposer,
      $$ImportiVoceTableCreateCompanionBuilder,
      $$ImportiVoceTableUpdateCompanionBuilder,
      (ImportoVoce, $$ImportiVoceTableReferences),
      ImportoVoce,
      PrefetchHooks Function({bool voceId})
    >;
typedef $$VariazioniMeseTableCreateCompanionBuilder =
    VariazioniMeseCompanion Function({
      required String id,
      required String aggiornatoIl,
      Value<bool> eliminato,
      required String voceId,
      required String mese,
      required int importoMinimo,
      Value<int> rowid,
    });
typedef $$VariazioniMeseTableUpdateCompanionBuilder =
    VariazioniMeseCompanion Function({
      Value<String> id,
      Value<String> aggiornatoIl,
      Value<bool> eliminato,
      Value<String> voceId,
      Value<String> mese,
      Value<int> importoMinimo,
      Value<int> rowid,
    });

final class $$VariazioniMeseTableReferences
    extends BaseReferences<_$Archivio, $VariazioniMeseTable, VariazioneMese> {
  $$VariazioniMeseTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VociCostoTable _voceIdTable(_$Archivio db) =>
      db.vociCosto.createAlias('variazioni_mese__voce_id__voci_costo__id');

  $$VociCostoTableProcessedTableManager get voceId {
    final $_column = $_itemColumn<String>('voce_id')!;

    final manager = $$VociCostoTableTableManager(
      $_db,
      $_db.vociCosto,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_voceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VariazioniMeseTableFilterComposer
    extends Composer<_$Archivio, $VariazioniMeseTable> {
  $$VariazioniMeseTableFilterComposer({
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

  ColumnFilters<String> get mese => $composableBuilder(
    column: $table.mese,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importoMinimo => $composableBuilder(
    column: $table.importoMinimo,
    builder: (column) => ColumnFilters(column),
  );

  $$VociCostoTableFilterComposer get voceId {
    final $$VociCostoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.voceId,
      referencedTable: $db.vociCosto,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VociCostoTableFilterComposer(
            $db: $db,
            $table: $db.vociCosto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VariazioniMeseTableOrderingComposer
    extends Composer<_$Archivio, $VariazioniMeseTable> {
  $$VariazioniMeseTableOrderingComposer({
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

  ColumnOrderings<String> get mese => $composableBuilder(
    column: $table.mese,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importoMinimo => $composableBuilder(
    column: $table.importoMinimo,
    builder: (column) => ColumnOrderings(column),
  );

  $$VociCostoTableOrderingComposer get voceId {
    final $$VociCostoTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.voceId,
      referencedTable: $db.vociCosto,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VociCostoTableOrderingComposer(
            $db: $db,
            $table: $db.vociCosto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VariazioniMeseTableAnnotationComposer
    extends Composer<_$Archivio, $VariazioniMeseTable> {
  $$VariazioniMeseTableAnnotationComposer({
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

  GeneratedColumn<String> get mese =>
      $composableBuilder(column: $table.mese, builder: (column) => column);

  GeneratedColumn<int> get importoMinimo => $composableBuilder(
    column: $table.importoMinimo,
    builder: (column) => column,
  );

  $$VociCostoTableAnnotationComposer get voceId {
    final $$VociCostoTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.voceId,
      referencedTable: $db.vociCosto,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VociCostoTableAnnotationComposer(
            $db: $db,
            $table: $db.vociCosto,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VariazioniMeseTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $VariazioniMeseTable,
          VariazioneMese,
          $$VariazioniMeseTableFilterComposer,
          $$VariazioniMeseTableOrderingComposer,
          $$VariazioniMeseTableAnnotationComposer,
          $$VariazioniMeseTableCreateCompanionBuilder,
          $$VariazioniMeseTableUpdateCompanionBuilder,
          (VariazioneMese, $$VariazioniMeseTableReferences),
          VariazioneMese,
          PrefetchHooks Function({bool voceId})
        > {
  $$VariazioniMeseTableTableManager(_$Archivio db, $VariazioniMeseTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VariazioniMeseTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VariazioniMeseTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VariazioniMeseTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String> voceId = const Value.absent(),
                Value<String> mese = const Value.absent(),
                Value<int> importoMinimo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VariazioniMeseCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                voceId: voceId,
                mese: mese,
                importoMinimo: importoMinimo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                required String voceId,
                required String mese,
                required int importoMinimo,
                Value<int> rowid = const Value.absent(),
              }) => VariazioniMeseCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                voceId: voceId,
                mese: mese,
                importoMinimo: importoMinimo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VariazioniMeseTable, VariazioneMese>(table),
                  $$VariazioniMeseTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({voceId = false}) {
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
                    if (voceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.voceId,
                        referencedTable: $$VariazioniMeseTableReferences
                            ._voceIdTable(db),
                        referencedColumn: $$VariazioniMeseTableReferences
                            ._voceIdTable(db)
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

typedef $$VariazioniMeseTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $VariazioniMeseTable,
      VariazioneMese,
      $$VariazioniMeseTableFilterComposer,
      $$VariazioniMeseTableOrderingComposer,
      $$VariazioniMeseTableAnnotationComposer,
      $$VariazioniMeseTableCreateCompanionBuilder,
      $$VariazioniMeseTableUpdateCompanionBuilder,
      (VariazioneMese, $$VariazioniMeseTableReferences),
      VariazioneMese,
      PrefetchHooks Function({bool voceId})
    >;
typedef $$CarteCreditoTableCreateCompanionBuilder =
    CarteCreditoCompanion Function({
      required String id,
      required String aggiornatoIl,
      Value<bool> eliminato,
      required String portafoglioId,
      required String contoAddebitoId,
      required int giornoAddebito,
      Value<int> giornoChiusura,
      Value<int?> plafondMinimo,
      Value<bool> archiviata,
      Value<int> rowid,
    });
typedef $$CarteCreditoTableUpdateCompanionBuilder =
    CarteCreditoCompanion Function({
      Value<String> id,
      Value<String> aggiornatoIl,
      Value<bool> eliminato,
      Value<String> portafoglioId,
      Value<String> contoAddebitoId,
      Value<int> giornoAddebito,
      Value<int> giornoChiusura,
      Value<int?> plafondMinimo,
      Value<bool> archiviata,
      Value<int> rowid,
    });

final class $$CarteCreditoTableReferences
    extends BaseReferences<_$Archivio, $CarteCreditoTable, CartaCredito> {
  $$CarteCreditoTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PortafogliTable _portafoglioIdTable(_$Archivio db) => db.portafogli
      .createAlias('carte_credito__portafoglio_id__portafogli__id');

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

  static $PortafogliTable _contoAddebitoIdTable(_$Archivio db) => db.portafogli
      .createAlias('carte_credito__conto_addebito_id__portafogli__id');

  $$PortafogliTableProcessedTableManager get contoAddebitoId {
    final $_column = $_itemColumn<String>('conto_addebito_id')!;

    final manager = $$PortafogliTableTableManager(
      $_db,
      $_db.portafogli,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contoAddebitoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CarteCreditoTableFilterComposer
    extends Composer<_$Archivio, $CarteCreditoTable> {
  $$CarteCreditoTableFilterComposer({
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

  ColumnFilters<int> get giornoAddebito => $composableBuilder(
    column: $table.giornoAddebito,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get giornoChiusura => $composableBuilder(
    column: $table.giornoChiusura,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plafondMinimo => $composableBuilder(
    column: $table.plafondMinimo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archiviata => $composableBuilder(
    column: $table.archiviata,
    builder: (column) => ColumnFilters(column),
  );

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

  $$PortafogliTableFilterComposer get contoAddebitoId {
    final $$PortafogliTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contoAddebitoId,
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
}

class $$CarteCreditoTableOrderingComposer
    extends Composer<_$Archivio, $CarteCreditoTable> {
  $$CarteCreditoTableOrderingComposer({
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

  ColumnOrderings<int> get giornoAddebito => $composableBuilder(
    column: $table.giornoAddebito,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get giornoChiusura => $composableBuilder(
    column: $table.giornoChiusura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plafondMinimo => $composableBuilder(
    column: $table.plafondMinimo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archiviata => $composableBuilder(
    column: $table.archiviata,
    builder: (column) => ColumnOrderings(column),
  );

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

  $$PortafogliTableOrderingComposer get contoAddebitoId {
    final $$PortafogliTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contoAddebitoId,
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
}

class $$CarteCreditoTableAnnotationComposer
    extends Composer<_$Archivio, $CarteCreditoTable> {
  $$CarteCreditoTableAnnotationComposer({
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

  GeneratedColumn<int> get giornoAddebito => $composableBuilder(
    column: $table.giornoAddebito,
    builder: (column) => column,
  );

  GeneratedColumn<int> get giornoChiusura => $composableBuilder(
    column: $table.giornoChiusura,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plafondMinimo => $composableBuilder(
    column: $table.plafondMinimo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archiviata => $composableBuilder(
    column: $table.archiviata,
    builder: (column) => column,
  );

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

  $$PortafogliTableAnnotationComposer get contoAddebitoId {
    final $$PortafogliTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contoAddebitoId,
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
}

class $$CarteCreditoTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $CarteCreditoTable,
          CartaCredito,
          $$CarteCreditoTableFilterComposer,
          $$CarteCreditoTableOrderingComposer,
          $$CarteCreditoTableAnnotationComposer,
          $$CarteCreditoTableCreateCompanionBuilder,
          $$CarteCreditoTableUpdateCompanionBuilder,
          (CartaCredito, $$CarteCreditoTableReferences),
          CartaCredito,
          PrefetchHooks Function({bool portafoglioId, bool contoAddebitoId})
        > {
  $$CarteCreditoTableTableManager(_$Archivio db, $CarteCreditoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CarteCreditoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CarteCreditoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CarteCreditoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String> portafoglioId = const Value.absent(),
                Value<String> contoAddebitoId = const Value.absent(),
                Value<int> giornoAddebito = const Value.absent(),
                Value<int> giornoChiusura = const Value.absent(),
                Value<int?> plafondMinimo = const Value.absent(),
                Value<bool> archiviata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CarteCreditoCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                portafoglioId: portafoglioId,
                contoAddebitoId: contoAddebitoId,
                giornoAddebito: giornoAddebito,
                giornoChiusura: giornoChiusura,
                plafondMinimo: plafondMinimo,
                archiviata: archiviata,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                required String portafoglioId,
                required String contoAddebitoId,
                required int giornoAddebito,
                Value<int> giornoChiusura = const Value.absent(),
                Value<int?> plafondMinimo = const Value.absent(),
                Value<bool> archiviata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CarteCreditoCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                portafoglioId: portafoglioId,
                contoAddebitoId: contoAddebitoId,
                giornoAddebito: giornoAddebito,
                giornoChiusura: giornoChiusura,
                plafondMinimo: plafondMinimo,
                archiviata: archiviata,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CarteCreditoTable, CartaCredito>(table),
                  $$CarteCreditoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({portafoglioId = false, contoAddebitoId = false}) {
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
                        if (portafoglioId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.portafoglioId,
                            referencedTable: $$CarteCreditoTableReferences
                                ._portafoglioIdTable(db),
                            referencedColumn: $$CarteCreditoTableReferences
                                ._portafoglioIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (contoAddebitoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contoAddebitoId,
                            referencedTable: $$CarteCreditoTableReferences
                                ._contoAddebitoIdTable(db),
                            referencedColumn: $$CarteCreditoTableReferences
                                ._contoAddebitoIdTable(db)
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

typedef $$CarteCreditoTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $CarteCreditoTable,
      CartaCredito,
      $$CarteCreditoTableFilterComposer,
      $$CarteCreditoTableOrderingComposer,
      $$CarteCreditoTableAnnotationComposer,
      $$CarteCreditoTableCreateCompanionBuilder,
      $$CarteCreditoTableUpdateCompanionBuilder,
      (CartaCredito, $$CarteCreditoTableReferences),
      CartaCredito,
      PrefetchHooks Function({bool portafoglioId, bool contoAddebitoId})
    >;
typedef $$PrestitiTableCreateCompanionBuilder = PrestitiCompanion Function({
  required String id,
  required String aggiornatoIl,
  Value<bool> eliminato,
  required String nome,
  required String tipo,
  Value<String> finanziatore,
  required int capitaleMinimo,
  required int numeroRate,
  required int importoRataMinimo,
  Value<int?> tanPuntiBase,
  Value<int?> taegPuntiBase,
  required String primaRata,
  Value<String> frequenza,
  Value<String?> portafoglioId,
  Value<String?> categoriaId,
  Value<String> valuta,
  Value<String> note,
  Value<bool> archiviato,
  Value<int> rowid,
});
typedef $$PrestitiTableUpdateCompanionBuilder = PrestitiCompanion Function({
  Value<String> id,
  Value<String> aggiornatoIl,
  Value<bool> eliminato,
  Value<String> nome,
  Value<String> tipo,
  Value<String> finanziatore,
  Value<int> capitaleMinimo,
  Value<int> numeroRate,
  Value<int> importoRataMinimo,
  Value<int?> tanPuntiBase,
  Value<int?> taegPuntiBase,
  Value<String> primaRata,
  Value<String> frequenza,
  Value<String?> portafoglioId,
  Value<String?> categoriaId,
  Value<String> valuta,
  Value<String> note,
  Value<bool> archiviato,
  Value<int> rowid,
});

final class $$PrestitiTableReferences
    extends BaseReferences<_$Archivio, $PrestitiTable, Prestito> {
  $$PrestitiTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PortafogliTable _portafoglioIdTable(_$Archivio db) =>
      db.portafogli.createAlias('prestiti__portafoglio_id__portafogli__id');

  $$PortafogliTableProcessedTableManager? get portafoglioId {
    final $_column = $_itemColumn<String>('portafoglio_id');
    if ($_column == null) return null;
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

  static $CategorieTable _categoriaIdTable(_$Archivio db) =>
      db.categorie.createAlias('prestiti__categoria_id__categorie__id');

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
}

class $$PrestitiTableFilterComposer
    extends Composer<_$Archivio, $PrestitiTable> {
  $$PrestitiTableFilterComposer({
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

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finanziatore => $composableBuilder(
    column: $table.finanziatore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capitaleMinimo => $composableBuilder(
    column: $table.capitaleMinimo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numeroRate => $composableBuilder(
    column: $table.numeroRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importoRataMinimo => $composableBuilder(
    column: $table.importoRataMinimo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tanPuntiBase => $composableBuilder(
    column: $table.tanPuntiBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taegPuntiBase => $composableBuilder(
    column: $table.taegPuntiBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaRata => $composableBuilder(
    column: $table.primaRata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequenza => $composableBuilder(
    column: $table.frequenza,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valuta => $composableBuilder(
    column: $table.valuta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archiviato => $composableBuilder(
    column: $table.archiviato,
    builder: (column) => ColumnFilters(column),
  );

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
}

class $$PrestitiTableOrderingComposer
    extends Composer<_$Archivio, $PrestitiTable> {
  $$PrestitiTableOrderingComposer({
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

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finanziatore => $composableBuilder(
    column: $table.finanziatore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capitaleMinimo => $composableBuilder(
    column: $table.capitaleMinimo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numeroRate => $composableBuilder(
    column: $table.numeroRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importoRataMinimo => $composableBuilder(
    column: $table.importoRataMinimo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tanPuntiBase => $composableBuilder(
    column: $table.tanPuntiBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taegPuntiBase => $composableBuilder(
    column: $table.taegPuntiBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaRata => $composableBuilder(
    column: $table.primaRata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequenza => $composableBuilder(
    column: $table.frequenza,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valuta => $composableBuilder(
    column: $table.valuta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archiviato => $composableBuilder(
    column: $table.archiviato,
    builder: (column) => ColumnOrderings(column),
  );

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

class $$PrestitiTableAnnotationComposer
    extends Composer<_$Archivio, $PrestitiTable> {
  $$PrestitiTableAnnotationComposer({
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

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get finanziatore => $composableBuilder(
    column: $table.finanziatore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get capitaleMinimo => $composableBuilder(
    column: $table.capitaleMinimo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get numeroRate => $composableBuilder(
    column: $table.numeroRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get importoRataMinimo => $composableBuilder(
    column: $table.importoRataMinimo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tanPuntiBase => $composableBuilder(
    column: $table.tanPuntiBase,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taegPuntiBase => $composableBuilder(
    column: $table.taegPuntiBase,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaRata =>
      $composableBuilder(column: $table.primaRata, builder: (column) => column);

  GeneratedColumn<String> get frequenza =>
      $composableBuilder(column: $table.frequenza, builder: (column) => column);

  GeneratedColumn<String> get valuta =>
      $composableBuilder(column: $table.valuta, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get archiviato => $composableBuilder(
    column: $table.archiviato,
    builder: (column) => column,
  );

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
}

class $$PrestitiTableTableManager
    extends
        RootTableManager<
          _$Archivio,
          $PrestitiTable,
          Prestito,
          $$PrestitiTableFilterComposer,
          $$PrestitiTableOrderingComposer,
          $$PrestitiTableAnnotationComposer,
          $$PrestitiTableCreateCompanionBuilder,
          $$PrestitiTableUpdateCompanionBuilder,
          (Prestito, $$PrestitiTableReferences),
          Prestito,
          PrefetchHooks Function({bool portafoglioId, bool categoriaId})
        > {
  $$PrestitiTableTableManager(_$Archivio db, $PrestitiTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrestitiTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrestitiTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrestitiTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aggiornatoIl = const Value.absent(),
                Value<bool> eliminato = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> finanziatore = const Value.absent(),
                Value<int> capitaleMinimo = const Value.absent(),
                Value<int> numeroRate = const Value.absent(),
                Value<int> importoRataMinimo = const Value.absent(),
                Value<int?> tanPuntiBase = const Value.absent(),
                Value<int?> taegPuntiBase = const Value.absent(),
                Value<String> primaRata = const Value.absent(),
                Value<String> frequenza = const Value.absent(),
                Value<String?> portafoglioId = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                Value<String> valuta = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<bool> archiviato = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrestitiCompanion(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                nome: nome,
                tipo: tipo,
                finanziatore: finanziatore,
                capitaleMinimo: capitaleMinimo,
                numeroRate: numeroRate,
                importoRataMinimo: importoRataMinimo,
                tanPuntiBase: tanPuntiBase,
                taegPuntiBase: taegPuntiBase,
                primaRata: primaRata,
                frequenza: frequenza,
                portafoglioId: portafoglioId,
                categoriaId: categoriaId,
                valuta: valuta,
                note: note,
                archiviato: archiviato,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggiornatoIl,
                Value<bool> eliminato = const Value.absent(),
                required String nome,
                required String tipo,
                Value<String> finanziatore = const Value.absent(),
                required int capitaleMinimo,
                required int numeroRate,
                required int importoRataMinimo,
                Value<int?> tanPuntiBase = const Value.absent(),
                Value<int?> taegPuntiBase = const Value.absent(),
                required String primaRata,
                Value<String> frequenza = const Value.absent(),
                Value<String?> portafoglioId = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                Value<String> valuta = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<bool> archiviato = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrestitiCompanion.insert(
                id: id,
                aggiornatoIl: aggiornatoIl,
                eliminato: eliminato,
                nome: nome,
                tipo: tipo,
                finanziatore: finanziatore,
                capitaleMinimo: capitaleMinimo,
                numeroRate: numeroRate,
                importoRataMinimo: importoRataMinimo,
                tanPuntiBase: tanPuntiBase,
                taegPuntiBase: taegPuntiBase,
                primaRata: primaRata,
                frequenza: frequenza,
                portafoglioId: portafoglioId,
                categoriaId: categoriaId,
                valuta: valuta,
                note: note,
                archiviato: archiviato,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrestitiTable, Prestito>(table),
                  $$PrestitiTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({portafoglioId = false, categoriaId = false}) {
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
                        if (portafoglioId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.portafoglioId,
                            referencedTable: $$PrestitiTableReferences
                                ._portafoglioIdTable(db),
                            referencedColumn: $$PrestitiTableReferences
                                ._portafoglioIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (categoriaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoriaId,
                            referencedTable: $$PrestitiTableReferences
                                ._categoriaIdTable(db),
                            referencedColumn: $$PrestitiTableReferences
                                ._categoriaIdTable(db)
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

typedef $$PrestitiTableProcessedTableManager =
    ProcessedTableManager<
      _$Archivio,
      $PrestitiTable,
      Prestito,
      $$PrestitiTableFilterComposer,
      $$PrestitiTableOrderingComposer,
      $$PrestitiTableAnnotationComposer,
      $$PrestitiTableCreateCompanionBuilder,
      $$PrestitiTableUpdateCompanionBuilder,
      (Prestito, $$PrestitiTableReferences),
      Prestito,
      PrefetchHooks Function({bool portafoglioId, bool categoriaId})
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
  $$PianificazioniTableTableManager get pianificazioni =>
      $$PianificazioniTableTableManager(_db, _db.pianificazioni);
  $$MovimentiTableTableManager get movimenti =>
      $$MovimentiTableTableManager(_db, _db.movimenti);
  $$EtichetteTableTableManager get etichette =>
      $$EtichetteTableTableManager(_db, _db.etichette);
  $$MovimentiEtichetteTableTableManager get movimentiEtichette =>
      $$MovimentiEtichetteTableTableManager(_db, _db.movimentiEtichette);
  $$VociCostoTableTableManager get vociCosto =>
      $$VociCostoTableTableManager(_db, _db.vociCosto);
  $$ImportiVoceTableTableManager get importiVoce =>
      $$ImportiVoceTableTableManager(_db, _db.importiVoce);
  $$VariazioniMeseTableTableManager get variazioniMese =>
      $$VariazioniMeseTableTableManager(_db, _db.variazioniMese);
  $$CarteCreditoTableTableManager get carteCredito =>
      $$CarteCreditoTableTableManager(_db, _db.carteCredito);
  $$PrestitiTableTableManager get prestiti =>
      $$PrestitiTableTableManager(_db, _db.prestiti);
  $$ImpostazioniTableTableManager get impostazioni =>
      $$ImpostazioniTableTableManager(_db, _db.impostazioni);
}
