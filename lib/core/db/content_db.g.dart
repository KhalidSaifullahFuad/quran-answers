// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_db.dart';

// ignore_for_file: type=lint
class $SurahsTable extends Surahs with TableInfo<$SurahsTable, Surah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameBnMeta = const VerificationMeta('nameBn');
  @override
  late final GeneratedColumn<String> nameBn = GeneratedColumn<String>(
    'name_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahCountMeta = const VerificationMeta(
    'ayahCount',
  );
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
    'ayah_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revelationPlaceMeta = const VerificationMeta(
    'revelationPlace',
  );
  @override
  late final GeneratedColumn<String> revelationPlace = GeneratedColumn<String>(
    'revelation_place',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    number,
    nameAr,
    nameBn,
    nameEn,
    ayahCount,
    revelationPlace,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Surah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_bn')) {
      context.handle(
        _nameBnMeta,
        nameBn.isAcceptableOrUnknown(data['name_bn']!, _nameBnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameBnMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('ayah_count')) {
      context.handle(
        _ayahCountMeta,
        ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahCountMeta);
    }
    if (data.containsKey('revelation_place')) {
      context.handle(
        _revelationPlaceMeta,
        revelationPlace.isAcceptableOrUnknown(
          data['revelation_place']!,
          _revelationPlaceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_revelationPlaceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {number};
  @override
  Surah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Surah(
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_bn'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      ayahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_count'],
      )!,
      revelationPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revelation_place'],
      )!,
    );
  }

  @override
  $SurahsTable createAlias(String alias) {
    return $SurahsTable(attachedDatabase, alias);
  }
}

class Surah extends DataClass implements Insertable<Surah> {
  final int number;
  final String nameAr;
  final String nameBn;
  final String nameEn;
  final int ayahCount;
  final String revelationPlace;
  const Surah({
    required this.number,
    required this.nameAr,
    required this.nameBn,
    required this.nameEn,
    required this.ayahCount,
    required this.revelationPlace,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['number'] = Variable<int>(number);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_bn'] = Variable<String>(nameBn);
    map['name_en'] = Variable<String>(nameEn);
    map['ayah_count'] = Variable<int>(ayahCount);
    map['revelation_place'] = Variable<String>(revelationPlace);
    return map;
  }

  SurahsCompanion toCompanion(bool nullToAbsent) {
    return SurahsCompanion(
      number: Value(number),
      nameAr: Value(nameAr),
      nameBn: Value(nameBn),
      nameEn: Value(nameEn),
      ayahCount: Value(ayahCount),
      revelationPlace: Value(revelationPlace),
    );
  }

  factory Surah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Surah(
      number: serializer.fromJson<int>(json['number']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameBn: serializer.fromJson<String>(json['nameBn']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
      revelationPlace: serializer.fromJson<String>(json['revelationPlace']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'number': serializer.toJson<int>(number),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameBn': serializer.toJson<String>(nameBn),
      'nameEn': serializer.toJson<String>(nameEn),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'revelationPlace': serializer.toJson<String>(revelationPlace),
    };
  }

  Surah copyWith({
    int? number,
    String? nameAr,
    String? nameBn,
    String? nameEn,
    int? ayahCount,
    String? revelationPlace,
  }) => Surah(
    number: number ?? this.number,
    nameAr: nameAr ?? this.nameAr,
    nameBn: nameBn ?? this.nameBn,
    nameEn: nameEn ?? this.nameEn,
    ayahCount: ayahCount ?? this.ayahCount,
    revelationPlace: revelationPlace ?? this.revelationPlace,
  );
  Surah copyWithCompanion(SurahsCompanion data) {
    return Surah(
      number: data.number.present ? data.number.value : this.number,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameBn: data.nameBn.present ? data.nameBn.value : this.nameBn,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
      revelationPlace: data.revelationPlace.present
          ? data.revelationPlace.value
          : this.revelationPlace,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Surah(')
          ..write('number: $number, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameBn: $nameBn, ')
          ..write('nameEn: $nameEn, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('revelationPlace: $revelationPlace')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(number, nameAr, nameBn, nameEn, ayahCount, revelationPlace);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Surah &&
          other.number == this.number &&
          other.nameAr == this.nameAr &&
          other.nameBn == this.nameBn &&
          other.nameEn == this.nameEn &&
          other.ayahCount == this.ayahCount &&
          other.revelationPlace == this.revelationPlace);
}

class SurahsCompanion extends UpdateCompanion<Surah> {
  final Value<int> number;
  final Value<String> nameAr;
  final Value<String> nameBn;
  final Value<String> nameEn;
  final Value<int> ayahCount;
  final Value<String> revelationPlace;
  const SurahsCompanion({
    this.number = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameBn = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.revelationPlace = const Value.absent(),
  });
  SurahsCompanion.insert({
    this.number = const Value.absent(),
    required String nameAr,
    required String nameBn,
    required String nameEn,
    required int ayahCount,
    required String revelationPlace,
  }) : nameAr = Value(nameAr),
       nameBn = Value(nameBn),
       nameEn = Value(nameEn),
       ayahCount = Value(ayahCount),
       revelationPlace = Value(revelationPlace);
  static Insertable<Surah> custom({
    Expression<int>? number,
    Expression<String>? nameAr,
    Expression<String>? nameBn,
    Expression<String>? nameEn,
    Expression<int>? ayahCount,
    Expression<String>? revelationPlace,
  }) {
    return RawValuesInsertable({
      if (number != null) 'number': number,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameBn != null) 'name_bn': nameBn,
      if (nameEn != null) 'name_en': nameEn,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (revelationPlace != null) 'revelation_place': revelationPlace,
    });
  }

  SurahsCompanion copyWith({
    Value<int>? number,
    Value<String>? nameAr,
    Value<String>? nameBn,
    Value<String>? nameEn,
    Value<int>? ayahCount,
    Value<String>? revelationPlace,
  }) {
    return SurahsCompanion(
      number: number ?? this.number,
      nameAr: nameAr ?? this.nameAr,
      nameBn: nameBn ?? this.nameBn,
      nameEn: nameEn ?? this.nameEn,
      ayahCount: ayahCount ?? this.ayahCount,
      revelationPlace: revelationPlace ?? this.revelationPlace,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameBn.present) {
      map['name_bn'] = Variable<String>(nameBn.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (revelationPlace.present) {
      map['revelation_place'] = Variable<String>(revelationPlace.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurahsCompanion(')
          ..write('number: $number, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameBn: $nameBn, ')
          ..write('nameEn: $nameEn, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('revelationPlace: $revelationPlace')
          ..write(')'))
        .toString();
  }
}

class $AyahsTable extends Ayahs with TableInfo<$AyahsTable, Ayah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES surahs (number)',
    ),
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textUthmaniMeta = const VerificationMeta(
    'textUthmani',
  );
  @override
  late final GeneratedColumn<String> textUthmani = GeneratedColumn<String>(
    'text_uthmani',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textPlainMeta = const VerificationMeta(
    'textPlain',
  );
  @override
  late final GeneratedColumn<String> textPlain = GeneratedColumn<String>(
    'text_plain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationBnMeta = const VerificationMeta(
    'translationBn',
  );
  @override
  late final GeneratedColumn<String> translationBn = GeneratedColumn<String>(
    'translation_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchArMeta = const VerificationMeta(
    'searchAr',
  );
  @override
  late final GeneratedColumn<String> searchAr = GeneratedColumn<String>(
    'search_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchBnMeta = const VerificationMeta(
    'searchBn',
  );
  @override
  late final GeneratedColumn<String> searchBn = GeneratedColumn<String>(
    'search_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    surah,
    ayah,
    textUthmani,
    textPlain,
    translationBn,
    searchAr,
    searchBn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ayah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('text_uthmani')) {
      context.handle(
        _textUthmaniMeta,
        textUthmani.isAcceptableOrUnknown(
          data['text_uthmani']!,
          _textUthmaniMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textUthmaniMeta);
    }
    if (data.containsKey('text_plain')) {
      context.handle(
        _textPlainMeta,
        textPlain.isAcceptableOrUnknown(data['text_plain']!, _textPlainMeta),
      );
    } else if (isInserting) {
      context.missing(_textPlainMeta);
    }
    if (data.containsKey('translation_bn')) {
      context.handle(
        _translationBnMeta,
        translationBn.isAcceptableOrUnknown(
          data['translation_bn']!,
          _translationBnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationBnMeta);
    }
    if (data.containsKey('search_ar')) {
      context.handle(
        _searchArMeta,
        searchAr.isAcceptableOrUnknown(data['search_ar']!, _searchArMeta),
      );
    } else if (isInserting) {
      context.missing(_searchArMeta);
    }
    if (data.containsKey('search_bn')) {
      context.handle(
        _searchBnMeta,
        searchBn.isAcceptableOrUnknown(data['search_bn']!, _searchBnMeta),
      );
    } else if (isInserting) {
      context.missing(_searchBnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ayah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ayah(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      textUthmani: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_uthmani'],
      )!,
      textPlain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_plain'],
      )!,
      translationBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_bn'],
      )!,
      searchAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_ar'],
      )!,
      searchBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_bn'],
      )!,
    );
  }

  @override
  $AyahsTable createAlias(String alias) {
    return $AyahsTable(attachedDatabase, alias);
  }
}

class Ayah extends DataClass implements Insertable<Ayah> {
  /// `surah * 1000 + ayah`. Deterministic rather than autoincrement, so the id
  /// of a verse is the same in every rebuild of the database and is readable in
  /// a query. The longest surah has 286 ayat, well inside the multiplier.
  final int id;
  final int surah;
  final int ayah;

  /// Uthmani script, as fetched. Displayed text — never normalized in place.
  final String textUthmani;

  /// Imlaei (simple) script, kept as a fallback for renderers that handle
  /// Uthmani diacritics badly.
  final String textPlain;
  final String translationBn;

  /// Normalized copies used only for the FTS index. See core/text/normalize.dart.
  final String searchAr;
  final String searchBn;
  const Ayah({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.textUthmani,
    required this.textPlain,
    required this.translationBn,
    required this.searchAr,
    required this.searchBn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['text_uthmani'] = Variable<String>(textUthmani);
    map['text_plain'] = Variable<String>(textPlain);
    map['translation_bn'] = Variable<String>(translationBn);
    map['search_ar'] = Variable<String>(searchAr);
    map['search_bn'] = Variable<String>(searchBn);
    return map;
  }

  AyahsCompanion toCompanion(bool nullToAbsent) {
    return AyahsCompanion(
      id: Value(id),
      surah: Value(surah),
      ayah: Value(ayah),
      textUthmani: Value(textUthmani),
      textPlain: Value(textPlain),
      translationBn: Value(translationBn),
      searchAr: Value(searchAr),
      searchBn: Value(searchBn),
    );
  }

  factory Ayah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ayah(
      id: serializer.fromJson<int>(json['id']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      textUthmani: serializer.fromJson<String>(json['textUthmani']),
      textPlain: serializer.fromJson<String>(json['textPlain']),
      translationBn: serializer.fromJson<String>(json['translationBn']),
      searchAr: serializer.fromJson<String>(json['searchAr']),
      searchBn: serializer.fromJson<String>(json['searchBn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'textUthmani': serializer.toJson<String>(textUthmani),
      'textPlain': serializer.toJson<String>(textPlain),
      'translationBn': serializer.toJson<String>(translationBn),
      'searchAr': serializer.toJson<String>(searchAr),
      'searchBn': serializer.toJson<String>(searchBn),
    };
  }

  Ayah copyWith({
    int? id,
    int? surah,
    int? ayah,
    String? textUthmani,
    String? textPlain,
    String? translationBn,
    String? searchAr,
    String? searchBn,
  }) => Ayah(
    id: id ?? this.id,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    textUthmani: textUthmani ?? this.textUthmani,
    textPlain: textPlain ?? this.textPlain,
    translationBn: translationBn ?? this.translationBn,
    searchAr: searchAr ?? this.searchAr,
    searchBn: searchBn ?? this.searchBn,
  );
  Ayah copyWithCompanion(AyahsCompanion data) {
    return Ayah(
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      textUthmani: data.textUthmani.present
          ? data.textUthmani.value
          : this.textUthmani,
      textPlain: data.textPlain.present ? data.textPlain.value : this.textPlain,
      translationBn: data.translationBn.present
          ? data.translationBn.value
          : this.translationBn,
      searchAr: data.searchAr.present ? data.searchAr.value : this.searchAr,
      searchBn: data.searchBn.present ? data.searchBn.value : this.searchBn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ayah(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('textPlain: $textPlain, ')
          ..write('translationBn: $translationBn, ')
          ..write('searchAr: $searchAr, ')
          ..write('searchBn: $searchBn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    surah,
    ayah,
    textUthmani,
    textPlain,
    translationBn,
    searchAr,
    searchBn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ayah &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.textUthmani == this.textUthmani &&
          other.textPlain == this.textPlain &&
          other.translationBn == this.translationBn &&
          other.searchAr == this.searchAr &&
          other.searchBn == this.searchBn);
}

class AyahsCompanion extends UpdateCompanion<Ayah> {
  final Value<int> id;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<String> textUthmani;
  final Value<String> textPlain;
  final Value<String> translationBn;
  final Value<String> searchAr;
  final Value<String> searchBn;
  const AyahsCompanion({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.textUthmani = const Value.absent(),
    this.textPlain = const Value.absent(),
    this.translationBn = const Value.absent(),
    this.searchAr = const Value.absent(),
    this.searchBn = const Value.absent(),
  });
  AyahsCompanion.insert({
    this.id = const Value.absent(),
    required int surah,
    required int ayah,
    required String textUthmani,
    required String textPlain,
    required String translationBn,
    required String searchAr,
    required String searchBn,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       textUthmani = Value(textUthmani),
       textPlain = Value(textPlain),
       translationBn = Value(translationBn),
       searchAr = Value(searchAr),
       searchBn = Value(searchBn);
  static Insertable<Ayah> custom({
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<String>? textUthmani,
    Expression<String>? textPlain,
    Expression<String>? translationBn,
    Expression<String>? searchAr,
    Expression<String>? searchBn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (textUthmani != null) 'text_uthmani': textUthmani,
      if (textPlain != null) 'text_plain': textPlain,
      if (translationBn != null) 'translation_bn': translationBn,
      if (searchAr != null) 'search_ar': searchAr,
      if (searchBn != null) 'search_bn': searchBn,
    });
  }

  AyahsCompanion copyWith({
    Value<int>? id,
    Value<int>? surah,
    Value<int>? ayah,
    Value<String>? textUthmani,
    Value<String>? textPlain,
    Value<String>? translationBn,
    Value<String>? searchAr,
    Value<String>? searchBn,
  }) {
    return AyahsCompanion(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      textUthmani: textUthmani ?? this.textUthmani,
      textPlain: textPlain ?? this.textPlain,
      translationBn: translationBn ?? this.translationBn,
      searchAr: searchAr ?? this.searchAr,
      searchBn: searchBn ?? this.searchBn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (textUthmani.present) {
      map['text_uthmani'] = Variable<String>(textUthmani.value);
    }
    if (textPlain.present) {
      map['text_plain'] = Variable<String>(textPlain.value);
    }
    if (translationBn.present) {
      map['translation_bn'] = Variable<String>(translationBn.value);
    }
    if (searchAr.present) {
      map['search_ar'] = Variable<String>(searchAr.value);
    }
    if (searchBn.present) {
      map['search_bn'] = Variable<String>(searchBn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahsCompanion(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('textPlain: $textPlain, ')
          ..write('translationBn: $translationBn, ')
          ..write('searchAr: $searchAr, ')
          ..write('searchBn: $searchBn')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameBnMeta = const VerificationMeta('nameBn');
  @override
  late final GeneratedColumn<String> nameBn = GeneratedColumn<String>(
    'name_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nameBn, nameEn, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name_bn')) {
      context.handle(
        _nameBnMeta,
        nameBn.isAcceptableOrUnknown(data['name_bn']!, _nameBnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameBnMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nameBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_bn'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String nameBn;
  final String nameEn;
  final int sortOrder;
  const Category({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name_bn'] = Variable<String>(nameBn);
    map['name_en'] = Variable<String>(nameEn);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      nameBn: Value(nameBn),
      nameEn: Value(nameEn),
      sortOrder: Value(sortOrder),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      nameBn: serializer.fromJson<String>(json['nameBn']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nameBn': serializer.toJson<String>(nameBn),
      'nameEn': serializer.toJson<String>(nameEn),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Category copyWith({
    String? id,
    String? nameBn,
    String? nameEn,
    int? sortOrder,
  }) => Category(
    id: id ?? this.id,
    nameBn: nameBn ?? this.nameBn,
    nameEn: nameEn ?? this.nameEn,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      nameBn: data.nameBn.present ? data.nameBn.value : this.nameBn,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('nameBn: $nameBn, ')
          ..write('nameEn: $nameEn, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nameBn, nameEn, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.nameBn == this.nameBn &&
          other.nameEn == this.nameEn &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> nameBn;
  final Value<String> nameEn;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.nameBn = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String nameBn,
    required String nameEn,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nameBn = Value(nameBn),
       nameEn = Value(nameEn),
       sortOrder = Value(sortOrder);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? nameBn,
    Expression<String>? nameEn,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameBn != null) 'name_bn': nameBn,
      if (nameEn != null) 'name_en': nameEn,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? nameBn,
    Value<String>? nameEn,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      nameBn: nameBn ?? this.nameBn,
      nameEn: nameEn ?? this.nameEn,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nameBn.present) {
      map['name_bn'] = Variable<String>(nameBn.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('nameBn: $nameBn, ')
          ..write('nameEn: $nameEn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, Question> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionBnMeta = const VerificationMeta(
    'questionBn',
  );
  @override
  late final GeneratedColumn<String> questionBn = GeneratedColumn<String>(
    'question_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerBnMeta = const VerificationMeta(
    'answerBn',
  );
  @override
  late final GeneratedColumn<String> answerBn = GeneratedColumn<String>(
    'answer_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _searchBnMeta = const VerificationMeta(
    'searchBn',
  );
  @override
  late final GeneratedColumn<String> searchBn = GeneratedColumn<String>(
    'search_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    slug,
    questionBn,
    answerBn,
    category,
    searchBn,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Question> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('question_bn')) {
      context.handle(
        _questionBnMeta,
        questionBn.isAcceptableOrUnknown(data['question_bn']!, _questionBnMeta),
      );
    } else if (isInserting) {
      context.missing(_questionBnMeta);
    }
    if (data.containsKey('answer_bn')) {
      context.handle(
        _answerBnMeta,
        answerBn.isAcceptableOrUnknown(data['answer_bn']!, _answerBnMeta),
      );
    } else if (isInserting) {
      context.missing(_answerBnMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('search_bn')) {
      context.handle(
        _searchBnMeta,
        searchBn.isAcceptableOrUnknown(data['search_bn']!, _searchBnMeta),
      );
    } else if (isInserting) {
      context.missing(_searchBnMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slug};
  @override
  Question map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Question(
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      questionBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_bn'],
      )!,
      answerBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_bn'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      searchBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_bn'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class Question extends DataClass implements Insertable<Question> {
  /// A human-authored slug, not an integer.
  ///
  /// Bookmarks and reading history in the user database reference questions by
  /// this value. Integer ids would be reassigned whenever the content database
  /// is regenerated, silently repointing every saved bookmark at a different
  /// question; a slug is stable across rebuilds.
  final String slug;
  final String questionBn;
  final String answerBn;
  final String category;
  final String searchBn;
  final int sortOrder;
  const Question({
    required this.slug,
    required this.questionBn,
    required this.answerBn,
    required this.category,
    required this.searchBn,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slug'] = Variable<String>(slug);
    map['question_bn'] = Variable<String>(questionBn);
    map['answer_bn'] = Variable<String>(answerBn);
    map['category'] = Variable<String>(category);
    map['search_bn'] = Variable<String>(searchBn);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      slug: Value(slug),
      questionBn: Value(questionBn),
      answerBn: Value(answerBn),
      category: Value(category),
      searchBn: Value(searchBn),
      sortOrder: Value(sortOrder),
    );
  }

  factory Question.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Question(
      slug: serializer.fromJson<String>(json['slug']),
      questionBn: serializer.fromJson<String>(json['questionBn']),
      answerBn: serializer.fromJson<String>(json['answerBn']),
      category: serializer.fromJson<String>(json['category']),
      searchBn: serializer.fromJson<String>(json['searchBn']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slug': serializer.toJson<String>(slug),
      'questionBn': serializer.toJson<String>(questionBn),
      'answerBn': serializer.toJson<String>(answerBn),
      'category': serializer.toJson<String>(category),
      'searchBn': serializer.toJson<String>(searchBn),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Question copyWith({
    String? slug,
    String? questionBn,
    String? answerBn,
    String? category,
    String? searchBn,
    int? sortOrder,
  }) => Question(
    slug: slug ?? this.slug,
    questionBn: questionBn ?? this.questionBn,
    answerBn: answerBn ?? this.answerBn,
    category: category ?? this.category,
    searchBn: searchBn ?? this.searchBn,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Question copyWithCompanion(QuestionsCompanion data) {
    return Question(
      slug: data.slug.present ? data.slug.value : this.slug,
      questionBn: data.questionBn.present
          ? data.questionBn.value
          : this.questionBn,
      answerBn: data.answerBn.present ? data.answerBn.value : this.answerBn,
      category: data.category.present ? data.category.value : this.category,
      searchBn: data.searchBn.present ? data.searchBn.value : this.searchBn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Question(')
          ..write('slug: $slug, ')
          ..write('questionBn: $questionBn, ')
          ..write('answerBn: $answerBn, ')
          ..write('category: $category, ')
          ..write('searchBn: $searchBn, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(slug, questionBn, answerBn, category, searchBn, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Question &&
          other.slug == this.slug &&
          other.questionBn == this.questionBn &&
          other.answerBn == this.answerBn &&
          other.category == this.category &&
          other.searchBn == this.searchBn &&
          other.sortOrder == this.sortOrder);
}

class QuestionsCompanion extends UpdateCompanion<Question> {
  final Value<String> slug;
  final Value<String> questionBn;
  final Value<String> answerBn;
  final Value<String> category;
  final Value<String> searchBn;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const QuestionsCompanion({
    this.slug = const Value.absent(),
    this.questionBn = const Value.absent(),
    this.answerBn = const Value.absent(),
    this.category = const Value.absent(),
    this.searchBn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionsCompanion.insert({
    required String slug,
    required String questionBn,
    required String answerBn,
    required String category,
    required String searchBn,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : slug = Value(slug),
       questionBn = Value(questionBn),
       answerBn = Value(answerBn),
       category = Value(category),
       searchBn = Value(searchBn),
       sortOrder = Value(sortOrder);
  static Insertable<Question> custom({
    Expression<String>? slug,
    Expression<String>? questionBn,
    Expression<String>? answerBn,
    Expression<String>? category,
    Expression<String>? searchBn,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slug != null) 'slug': slug,
      if (questionBn != null) 'question_bn': questionBn,
      if (answerBn != null) 'answer_bn': answerBn,
      if (category != null) 'category': category,
      if (searchBn != null) 'search_bn': searchBn,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionsCompanion copyWith({
    Value<String>? slug,
    Value<String>? questionBn,
    Value<String>? answerBn,
    Value<String>? category,
    Value<String>? searchBn,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return QuestionsCompanion(
      slug: slug ?? this.slug,
      questionBn: questionBn ?? this.questionBn,
      answerBn: answerBn ?? this.answerBn,
      category: category ?? this.category,
      searchBn: searchBn ?? this.searchBn,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (questionBn.present) {
      map['question_bn'] = Variable<String>(questionBn.value);
    }
    if (answerBn.present) {
      map['answer_bn'] = Variable<String>(answerBn.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (searchBn.present) {
      map['search_bn'] = Variable<String>(searchBn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('slug: $slug, ')
          ..write('questionBn: $questionBn, ')
          ..write('answerBn: $answerBn, ')
          ..write('category: $category, ')
          ..write('searchBn: $searchBn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionAyahsTable extends QuestionAyahs
    with TableInfo<$QuestionAyahsTable, QuestionAyah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionAyahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionSlugMeta = const VerificationMeta(
    'questionSlug',
  );
  @override
  late final GeneratedColumn<String> questionSlug = GeneratedColumn<String>(
    'question_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES questions (slug)',
    ),
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ayahs (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [questionSlug, ayahId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_ayahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionAyah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_slug')) {
      context.handle(
        _questionSlugMeta,
        questionSlug.isAcceptableOrUnknown(
          data['question_slug']!,
          _questionSlugMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionSlugMeta);
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionSlug, ayahId};
  @override
  QuestionAyah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionAyah(
      questionSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_slug'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $QuestionAyahsTable createAlias(String alias) {
    return $QuestionAyahsTable(attachedDatabase, alias);
  }
}

class QuestionAyah extends DataClass implements Insertable<QuestionAyah> {
  final String questionSlug;
  final int ayahId;
  final int sortOrder;
  const QuestionAyah({
    required this.questionSlug,
    required this.ayahId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_slug'] = Variable<String>(questionSlug);
    map['ayah_id'] = Variable<int>(ayahId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  QuestionAyahsCompanion toCompanion(bool nullToAbsent) {
    return QuestionAyahsCompanion(
      questionSlug: Value(questionSlug),
      ayahId: Value(ayahId),
      sortOrder: Value(sortOrder),
    );
  }

  factory QuestionAyah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionAyah(
      questionSlug: serializer.fromJson<String>(json['questionSlug']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionSlug': serializer.toJson<String>(questionSlug),
      'ayahId': serializer.toJson<int>(ayahId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  QuestionAyah copyWith({String? questionSlug, int? ayahId, int? sortOrder}) =>
      QuestionAyah(
        questionSlug: questionSlug ?? this.questionSlug,
        ayahId: ayahId ?? this.ayahId,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  QuestionAyah copyWithCompanion(QuestionAyahsCompanion data) {
    return QuestionAyah(
      questionSlug: data.questionSlug.present
          ? data.questionSlug.value
          : this.questionSlug,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionAyah(')
          ..write('questionSlug: $questionSlug, ')
          ..write('ayahId: $ayahId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(questionSlug, ayahId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionAyah &&
          other.questionSlug == this.questionSlug &&
          other.ayahId == this.ayahId &&
          other.sortOrder == this.sortOrder);
}

class QuestionAyahsCompanion extends UpdateCompanion<QuestionAyah> {
  final Value<String> questionSlug;
  final Value<int> ayahId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const QuestionAyahsCompanion({
    this.questionSlug = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionAyahsCompanion.insert({
    required String questionSlug,
    required int ayahId,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : questionSlug = Value(questionSlug),
       ayahId = Value(ayahId),
       sortOrder = Value(sortOrder);
  static Insertable<QuestionAyah> custom({
    Expression<String>? questionSlug,
    Expression<int>? ayahId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionSlug != null) 'question_slug': questionSlug,
      if (ayahId != null) 'ayah_id': ayahId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionAyahsCompanion copyWith({
    Value<String>? questionSlug,
    Value<int>? ayahId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return QuestionAyahsCompanion(
      questionSlug: questionSlug ?? this.questionSlug,
      ayahId: ayahId ?? this.ayahId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionSlug.present) {
      map['question_slug'] = Variable<String>(questionSlug.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionAyahsCompanion(')
          ..write('questionSlug: $questionSlug, ')
          ..write('ayahId: $ayahId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetaTable extends Meta with TableInfo<$MetaTable, MetaEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetaTable createAlias(String alias) {
    return $MetaTable(attachedDatabase, alias);
  }
}

class MetaEntry extends DataClass implements Insertable<MetaEntry> {
  final String key;
  final String value;
  const MetaEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaEntry copyWith({String? key, String? value}) =>
      MetaEntry(key: key ?? this.key, value: value ?? this.value);
  MetaEntry copyWithCompanion(MetaCompanion data) {
    return MetaEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContentDatabase extends GeneratedDatabase {
  _$ContentDatabase(QueryExecutor e) : super(e);
  $ContentDatabaseManager get managers => $ContentDatabaseManager(this);
  late final $SurahsTable surahs = $SurahsTable(this);
  late final $AyahsTable ayahs = $AyahsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $QuestionAyahsTable questionAyahs = $QuestionAyahsTable(this);
  late final $MetaTable meta = $MetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    surahs,
    ayahs,
    categories,
    questions,
    questionAyahs,
    meta,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SurahsTableCreateCompanionBuilder =
    SurahsCompanion Function({
      Value<int> number,
      required String nameAr,
      required String nameBn,
      required String nameEn,
      required int ayahCount,
      required String revelationPlace,
    });
typedef $$SurahsTableUpdateCompanionBuilder =
    SurahsCompanion Function({
      Value<int> number,
      Value<String> nameAr,
      Value<String> nameBn,
      Value<String> nameEn,
      Value<int> ayahCount,
      Value<String> revelationPlace,
    });

final class $$SurahsTableReferences
    extends BaseReferences<_$ContentDatabase, $SurahsTable, Surah> {
  $$SurahsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AyahsTable, List<Ayah>> _ayahsRefsTable(
    _$ContentDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ayahs,
    aliasName: 'surahs__number__ayahs__surah',
  );

  $$AyahsTableProcessedTableManager get ayahsRefs {
    final manager = $$AyahsTableTableManager(
      $_db,
      $_db.ayahs,
    ).filter((f) => f.surah.number.sqlEquals($_itemColumn<int>('number')!));

    final cache = $_typedResult.readTableOrNull(_ayahsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SurahsTableFilterComposer
    extends Composer<_$ContentDatabase, $SurahsTable> {
  $$SurahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameBn => $composableBuilder(
    column: $table.nameBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revelationPlace => $composableBuilder(
    column: $table.revelationPlace,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ayahsRefs(
    Expression<bool> Function($$AyahsTableFilterComposer f) f,
  ) {
    final $$AyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.number,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.surah,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableFilterComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SurahsTableOrderingComposer
    extends Composer<_$ContentDatabase, $SurahsTable> {
  $$SurahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameBn => $composableBuilder(
    column: $table.nameBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revelationPlace => $composableBuilder(
    column: $table.revelationPlace,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurahsTableAnnotationComposer
    extends Composer<_$ContentDatabase, $SurahsTable> {
  $$SurahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameBn =>
      $composableBuilder(column: $table.nameBn, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);

  GeneratedColumn<String> get revelationPlace => $composableBuilder(
    column: $table.revelationPlace,
    builder: (column) => column,
  );

  Expression<T> ayahsRefs<T extends Object>(
    Expression<T> Function($$AyahsTableAnnotationComposer a) f,
  ) {
    final $$AyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.number,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.surah,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SurahsTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $SurahsTable,
          Surah,
          $$SurahsTableFilterComposer,
          $$SurahsTableOrderingComposer,
          $$SurahsTableAnnotationComposer,
          $$SurahsTableCreateCompanionBuilder,
          $$SurahsTableUpdateCompanionBuilder,
          (Surah, $$SurahsTableReferences),
          Surah,
          PrefetchHooks Function({bool ayahsRefs})
        > {
  $$SurahsTableTableManager(_$ContentDatabase db, $SurahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> nameBn = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<int> ayahCount = const Value.absent(),
                Value<String> revelationPlace = const Value.absent(),
              }) => SurahsCompanion(
                number: number,
                nameAr: nameAr,
                nameBn: nameBn,
                nameEn: nameEn,
                ayahCount: ayahCount,
                revelationPlace: revelationPlace,
              ),
          createCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                required String nameAr,
                required String nameBn,
                required String nameEn,
                required int ayahCount,
                required String revelationPlace,
              }) => SurahsCompanion.insert(
                number: number,
                nameAr: nameAr,
                nameBn: nameBn,
                nameEn: nameEn,
                ayahCount: ayahCount,
                revelationPlace: revelationPlace,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SurahsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({ayahsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ayahsRefs) db.ayahs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ayahsRefs)
                    await $_getPrefetchedData<Surah, $SurahsTable, Ayah>(
                      currentTable: table,
                      referencedTable: $$SurahsTableReferences._ayahsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$SurahsTableReferences(db, table, p0).ayahsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.surah == item.number),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SurahsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $SurahsTable,
      Surah,
      $$SurahsTableFilterComposer,
      $$SurahsTableOrderingComposer,
      $$SurahsTableAnnotationComposer,
      $$SurahsTableCreateCompanionBuilder,
      $$SurahsTableUpdateCompanionBuilder,
      (Surah, $$SurahsTableReferences),
      Surah,
      PrefetchHooks Function({bool ayahsRefs})
    >;
typedef $$AyahsTableCreateCompanionBuilder =
    AyahsCompanion Function({
      Value<int> id,
      required int surah,
      required int ayah,
      required String textUthmani,
      required String textPlain,
      required String translationBn,
      required String searchAr,
      required String searchBn,
    });
typedef $$AyahsTableUpdateCompanionBuilder =
    AyahsCompanion Function({
      Value<int> id,
      Value<int> surah,
      Value<int> ayah,
      Value<String> textUthmani,
      Value<String> textPlain,
      Value<String> translationBn,
      Value<String> searchAr,
      Value<String> searchBn,
    });

final class $$AyahsTableReferences
    extends BaseReferences<_$ContentDatabase, $AyahsTable, Ayah> {
  $$AyahsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SurahsTable _surahTable(_$ContentDatabase db) =>
      db.surahs.createAlias('ayahs__surah__surahs__number');

  $$SurahsTableProcessedTableManager get surah {
    final $_column = $_itemColumn<int>('surah')!;

    final manager = $$SurahsTableTableManager(
      $_db,
      $_db.surahs,
    ).filter((f) => f.number.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surahTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$QuestionAyahsTable, List<QuestionAyah>>
  _questionAyahsRefsTable(_$ContentDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.questionAyahs,
        aliasName: 'ayahs__id__question_ayahs__ayah_id',
      );

  $$QuestionAyahsTableProcessedTableManager get questionAyahsRefs {
    final manager = $$QuestionAyahsTableTableManager(
      $_db,
      $_db.questionAyahs,
    ).filter((f) => f.ayahId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_questionAyahsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AyahsTableFilterComposer
    extends Composer<_$ContentDatabase, $AyahsTable> {
  $$AyahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textUthmani => $composableBuilder(
    column: $table.textUthmani,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textPlain => $composableBuilder(
    column: $table.textPlain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationBn => $composableBuilder(
    column: $table.translationBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchAr => $composableBuilder(
    column: $table.searchAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchBn => $composableBuilder(
    column: $table.searchBn,
    builder: (column) => ColumnFilters(column),
  );

  $$SurahsTableFilterComposer get surah {
    final $$SurahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableFilterComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> questionAyahsRefs(
    Expression<bool> Function($$QuestionAyahsTableFilterComposer f) f,
  ) {
    final $$QuestionAyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questionAyahs,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionAyahsTableFilterComposer(
            $db: $db,
            $table: $db.questionAyahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AyahsTableOrderingComposer
    extends Composer<_$ContentDatabase, $AyahsTable> {
  $$AyahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textUthmani => $composableBuilder(
    column: $table.textUthmani,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textPlain => $composableBuilder(
    column: $table.textPlain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationBn => $composableBuilder(
    column: $table.translationBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchAr => $composableBuilder(
    column: $table.searchAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchBn => $composableBuilder(
    column: $table.searchBn,
    builder: (column) => ColumnOrderings(column),
  );

  $$SurahsTableOrderingComposer get surah {
    final $$SurahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableOrderingComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AyahsTableAnnotationComposer
    extends Composer<_$ContentDatabase, $AyahsTable> {
  $$AyahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<String> get textUthmani => $composableBuilder(
    column: $table.textUthmani,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textPlain =>
      $composableBuilder(column: $table.textPlain, builder: (column) => column);

  GeneratedColumn<String> get translationBn => $composableBuilder(
    column: $table.translationBn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchAr =>
      $composableBuilder(column: $table.searchAr, builder: (column) => column);

  GeneratedColumn<String> get searchBn =>
      $composableBuilder(column: $table.searchBn, builder: (column) => column);

  $$SurahsTableAnnotationComposer get surah {
    final $$SurahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surah,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableAnnotationComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> questionAyahsRefs<T extends Object>(
    Expression<T> Function($$QuestionAyahsTableAnnotationComposer a) f,
  ) {
    final $$QuestionAyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questionAyahs,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionAyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.questionAyahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AyahsTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $AyahsTable,
          Ayah,
          $$AyahsTableFilterComposer,
          $$AyahsTableOrderingComposer,
          $$AyahsTableAnnotationComposer,
          $$AyahsTableCreateCompanionBuilder,
          $$AyahsTableUpdateCompanionBuilder,
          (Ayah, $$AyahsTableReferences),
          Ayah,
          PrefetchHooks Function({bool surah, bool questionAyahsRefs})
        > {
  $$AyahsTableTableManager(_$ContentDatabase db, $AyahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<String> textUthmani = const Value.absent(),
                Value<String> textPlain = const Value.absent(),
                Value<String> translationBn = const Value.absent(),
                Value<String> searchAr = const Value.absent(),
                Value<String> searchBn = const Value.absent(),
              }) => AyahsCompanion(
                id: id,
                surah: surah,
                ayah: ayah,
                textUthmani: textUthmani,
                textPlain: textPlain,
                translationBn: translationBn,
                searchAr: searchAr,
                searchBn: searchBn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surah,
                required int ayah,
                required String textUthmani,
                required String textPlain,
                required String translationBn,
                required String searchAr,
                required String searchBn,
              }) => AyahsCompanion.insert(
                id: id,
                surah: surah,
                ayah: ayah,
                textUthmani: textUthmani,
                textPlain: textPlain,
                translationBn: translationBn,
                searchAr: searchAr,
                searchBn: searchBn,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AyahsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({surah = false, questionAyahsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (questionAyahsRefs) db.questionAyahs,
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
                    if (surah) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.surah,
                                referencedTable: $$AyahsTableReferences
                                    ._surahTable(db),
                                referencedColumn: $$AyahsTableReferences
                                    ._surahTable(db)
                                    .number,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (questionAyahsRefs)
                    await $_getPrefetchedData<Ayah, $AyahsTable, QuestionAyah>(
                      currentTable: table,
                      referencedTable: $$AyahsTableReferences
                          ._questionAyahsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AyahsTableReferences(
                        db,
                        table,
                        p0,
                      ).questionAyahsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.ayahId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AyahsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $AyahsTable,
      Ayah,
      $$AyahsTableFilterComposer,
      $$AyahsTableOrderingComposer,
      $$AyahsTableAnnotationComposer,
      $$AyahsTableCreateCompanionBuilder,
      $$AyahsTableUpdateCompanionBuilder,
      (Ayah, $$AyahsTableReferences),
      Ayah,
      PrefetchHooks Function({bool surah, bool questionAyahsRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String nameBn,
      required String nameEn,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> nameBn,
      Value<String> nameEn,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$ContentDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$QuestionsTable, List<Question>>
  _questionsRefsTable(_$ContentDatabase db) => MultiTypedResultKey.fromTable(
    db.questions,
    aliasName: 'categories__id__questions__category',
  );

  $$QuestionsTableProcessedTableManager get questionsRefs {
    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.category.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_questionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$ContentDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get nameBn => $composableBuilder(
    column: $table.nameBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> questionsRefs(
    Expression<bool> Function($$QuestionsTableFilterComposer f) f,
  ) {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.category,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$ContentDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get nameBn => $composableBuilder(
    column: $table.nameBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$ContentDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameBn =>
      $composableBuilder(column: $table.nameBn, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> questionsRefs<T extends Object>(
    Expression<T> Function($$QuestionsTableAnnotationComposer a) f,
  ) {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.category,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool questionsRefs})
        > {
  $$CategoriesTableTableManager(_$ContentDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nameBn = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                nameBn: nameBn,
                nameEn: nameEn,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nameBn,
                required String nameEn,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                nameBn: nameBn,
                nameEn: nameEn,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (questionsRefs) db.questions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (questionsRefs)
                    await $_getPrefetchedData<
                      Category,
                      $CategoriesTable,
                      Question
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._questionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).questionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.category == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool questionsRefs})
    >;
typedef $$QuestionsTableCreateCompanionBuilder =
    QuestionsCompanion Function({
      required String slug,
      required String questionBn,
      required String answerBn,
      required String category,
      required String searchBn,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$QuestionsTableUpdateCompanionBuilder =
    QuestionsCompanion Function({
      Value<String> slug,
      Value<String> questionBn,
      Value<String> answerBn,
      Value<String> category,
      Value<String> searchBn,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$QuestionsTableReferences
    extends BaseReferences<_$ContentDatabase, $QuestionsTable, Question> {
  $$QuestionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryTable(_$ContentDatabase db) =>
      db.categories.createAlias('questions__category__categories__id');

  $$CategoriesTableProcessedTableManager get category {
    final $_column = $_itemColumn<String>('category')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$QuestionAyahsTable, List<QuestionAyah>>
  _questionAyahsRefsTable(_$ContentDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.questionAyahs,
        aliasName: 'questions__slug__question_ayahs__question_slug',
      );

  $$QuestionAyahsTableProcessedTableManager get questionAyahsRefs {
    final manager = $$QuestionAyahsTableTableManager($_db, $_db.questionAyahs)
        .filter(
          (f) => f.questionSlug.slug.sqlEquals($_itemColumn<String>('slug')!),
        );

    final cache = $_typedResult.readTableOrNull(_questionAyahsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QuestionsTableFilterComposer
    extends Composer<_$ContentDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionBn => $composableBuilder(
    column: $table.questionBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerBn => $composableBuilder(
    column: $table.answerBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchBn => $composableBuilder(
    column: $table.searchBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get category {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> questionAyahsRefs(
    Expression<bool> Function($$QuestionAyahsTableFilterComposer f) f,
  ) {
    final $$QuestionAyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slug,
      referencedTable: $db.questionAyahs,
      getReferencedColumn: (t) => t.questionSlug,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionAyahsTableFilterComposer(
            $db: $db,
            $table: $db.questionAyahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$ContentDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionBn => $composableBuilder(
    column: $table.questionBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerBn => $composableBuilder(
    column: $table.answerBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchBn => $composableBuilder(
    column: $table.searchBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get category {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$ContentDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get questionBn => $composableBuilder(
    column: $table.questionBn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerBn =>
      $composableBuilder(column: $table.answerBn, builder: (column) => column);

  GeneratedColumn<String> get searchBn =>
      $composableBuilder(column: $table.searchBn, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get category {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> questionAyahsRefs<T extends Object>(
    Expression<T> Function($$QuestionAyahsTableAnnotationComposer a) f,
  ) {
    final $$QuestionAyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slug,
      referencedTable: $db.questionAyahs,
      getReferencedColumn: (t) => t.questionSlug,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionAyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.questionAyahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestionsTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $QuestionsTable,
          Question,
          $$QuestionsTableFilterComposer,
          $$QuestionsTableOrderingComposer,
          $$QuestionsTableAnnotationComposer,
          $$QuestionsTableCreateCompanionBuilder,
          $$QuestionsTableUpdateCompanionBuilder,
          (Question, $$QuestionsTableReferences),
          Question,
          PrefetchHooks Function({bool category, bool questionAyahsRefs})
        > {
  $$QuestionsTableTableManager(_$ContentDatabase db, $QuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> slug = const Value.absent(),
                Value<String> questionBn = const Value.absent(),
                Value<String> answerBn = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> searchBn = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion(
                slug: slug,
                questionBn: questionBn,
                answerBn: answerBn,
                category: category,
                searchBn: searchBn,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slug,
                required String questionBn,
                required String answerBn,
                required String category,
                required String searchBn,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion.insert(
                slug: slug,
                questionBn: questionBn,
                answerBn: answerBn,
                category: category,
                searchBn: searchBn,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuestionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({category = false, questionAyahsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (questionAyahsRefs) db.questionAyahs,
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
                        if (category) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.category,
                                    referencedTable: $$QuestionsTableReferences
                                        ._categoryTable(db),
                                    referencedColumn: $$QuestionsTableReferences
                                        ._categoryTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (questionAyahsRefs)
                        await $_getPrefetchedData<
                          Question,
                          $QuestionsTable,
                          QuestionAyah
                        >(
                          currentTable: table,
                          referencedTable: $$QuestionsTableReferences
                              ._questionAyahsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).questionAyahsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionSlug == item.slug,
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

typedef $$QuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $QuestionsTable,
      Question,
      $$QuestionsTableFilterComposer,
      $$QuestionsTableOrderingComposer,
      $$QuestionsTableAnnotationComposer,
      $$QuestionsTableCreateCompanionBuilder,
      $$QuestionsTableUpdateCompanionBuilder,
      (Question, $$QuestionsTableReferences),
      Question,
      PrefetchHooks Function({bool category, bool questionAyahsRefs})
    >;
typedef $$QuestionAyahsTableCreateCompanionBuilder =
    QuestionAyahsCompanion Function({
      required String questionSlug,
      required int ayahId,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$QuestionAyahsTableUpdateCompanionBuilder =
    QuestionAyahsCompanion Function({
      Value<String> questionSlug,
      Value<int> ayahId,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$QuestionAyahsTableReferences
    extends
        BaseReferences<_$ContentDatabase, $QuestionAyahsTable, QuestionAyah> {
  $$QuestionAyahsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $QuestionsTable _questionSlugTable(_$ContentDatabase db) => db
      .questions
      .createAlias('question_ayahs__question_slug__questions__slug');

  $$QuestionsTableProcessedTableManager get questionSlug {
    final $_column = $_itemColumn<String>('question_slug')!;

    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.slug.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionSlugTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AyahsTable _ayahIdTable(_$ContentDatabase db) =>
      db.ayahs.createAlias('question_ayahs__ayah_id__ayahs__id');

  $$AyahsTableProcessedTableManager get ayahId {
    final $_column = $_itemColumn<int>('ayah_id')!;

    final manager = $$AyahsTableTableManager(
      $_db,
      $_db.ayahs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ayahIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuestionAyahsTableFilterComposer
    extends Composer<_$ContentDatabase, $QuestionAyahsTable> {
  $$QuestionAyahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestionsTableFilterComposer get questionSlug {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionSlug,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.slug,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AyahsTableFilterComposer get ayahId {
    final $$AyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableFilterComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionAyahsTableOrderingComposer
    extends Composer<_$ContentDatabase, $QuestionAyahsTable> {
  $$QuestionAyahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestionsTableOrderingComposer get questionSlug {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionSlug,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.slug,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AyahsTableOrderingComposer get ayahId {
    final $$AyahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableOrderingComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionAyahsTableAnnotationComposer
    extends Composer<_$ContentDatabase, $QuestionAyahsTable> {
  $$QuestionAyahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$QuestionsTableAnnotationComposer get questionSlug {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionSlug,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.slug,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AyahsTableAnnotationComposer get ayahId {
    final $$AyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionAyahsTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $QuestionAyahsTable,
          QuestionAyah,
          $$QuestionAyahsTableFilterComposer,
          $$QuestionAyahsTableOrderingComposer,
          $$QuestionAyahsTableAnnotationComposer,
          $$QuestionAyahsTableCreateCompanionBuilder,
          $$QuestionAyahsTableUpdateCompanionBuilder,
          (QuestionAyah, $$QuestionAyahsTableReferences),
          QuestionAyah,
          PrefetchHooks Function({bool questionSlug, bool ayahId})
        > {
  $$QuestionAyahsTableTableManager(
    _$ContentDatabase db,
    $QuestionAyahsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionAyahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionAyahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionAyahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questionSlug = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionAyahsCompanion(
                questionSlug: questionSlug,
                ayahId: ayahId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionSlug,
                required int ayahId,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => QuestionAyahsCompanion.insert(
                questionSlug: questionSlug,
                ayahId: ayahId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuestionAyahsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionSlug = false, ayahId = false}) {
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
                    if (questionSlug) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.questionSlug,
                                referencedTable: $$QuestionAyahsTableReferences
                                    ._questionSlugTable(db),
                                referencedColumn: $$QuestionAyahsTableReferences
                                    ._questionSlugTable(db)
                                    .slug,
                              )
                              as T;
                    }
                    if (ayahId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ayahId,
                                referencedTable: $$QuestionAyahsTableReferences
                                    ._ayahIdTable(db),
                                referencedColumn: $$QuestionAyahsTableReferences
                                    ._ayahIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$QuestionAyahsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $QuestionAyahsTable,
      QuestionAyah,
      $$QuestionAyahsTableFilterComposer,
      $$QuestionAyahsTableOrderingComposer,
      $$QuestionAyahsTableAnnotationComposer,
      $$QuestionAyahsTableCreateCompanionBuilder,
      $$QuestionAyahsTableUpdateCompanionBuilder,
      (QuestionAyah, $$QuestionAyahsTableReferences),
      QuestionAyah,
      PrefetchHooks Function({bool questionSlug, bool ayahId})
    >;
typedef $$MetaTableCreateCompanionBuilder =
    MetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$MetaTableUpdateCompanionBuilder =
    MetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$MetaTableFilterComposer
    extends Composer<_$ContentDatabase, $MetaTable> {
  $$MetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetaTableOrderingComposer
    extends Composer<_$ContentDatabase, $MetaTable> {
  $$MetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetaTableAnnotationComposer
    extends Composer<_$ContentDatabase, $MetaTable> {
  $$MetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetaTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $MetaTable,
          MetaEntry,
          $$MetaTableFilterComposer,
          $$MetaTableOrderingComposer,
          $$MetaTableAnnotationComposer,
          $$MetaTableCreateCompanionBuilder,
          $$MetaTableUpdateCompanionBuilder,
          (MetaEntry, BaseReferences<_$ContentDatabase, $MetaTable, MetaEntry>),
          MetaEntry,
          PrefetchHooks Function()
        > {
  $$MetaTableTableManager(_$ContentDatabase db, $MetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $MetaTable,
      MetaEntry,
      $$MetaTableFilterComposer,
      $$MetaTableOrderingComposer,
      $$MetaTableAnnotationComposer,
      $$MetaTableCreateCompanionBuilder,
      $$MetaTableUpdateCompanionBuilder,
      (MetaEntry, BaseReferences<_$ContentDatabase, $MetaTable, MetaEntry>),
      MetaEntry,
      PrefetchHooks Function()
    >;

class $ContentDatabaseManager {
  final _$ContentDatabase _db;
  $ContentDatabaseManager(this._db);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db, _db.ayahs);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$QuestionAyahsTableTableManager get questionAyahs =>
      $$QuestionAyahsTableTableManager(_db, _db.questionAyahs);
  $$MetaTableTableManager get meta => $$MetaTableTableManager(_db, _db.meta);
}
