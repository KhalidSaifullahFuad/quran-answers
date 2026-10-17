import 'package:flutter_test/flutter_test.dart';

import '../../tool/content_source.dart';

void main() {
  final mushaf = Mushaf(
    [
      {'number': 1, 'ayahCount': 7},
    ],
    {
      for (var a = 1; a <= 7; a++) '1:$a': {'surah': 1, 'ayah': a},
    },
    'test',
    'test',
  );

  Map<String, dynamic> question(
    String status,
    List<String> refs, {
    bool noAyah = false,
  }) => {
    'slug': 'q',
    'status': status,
    'category': 'c',
    if (noAyah) 'noAyah': true,
    'questionBn': 'প্রশ্ন',
    'answerBn': 'উত্তর',
    'sortOrder': 1,
    'refs': refs,
  };

  List<String> errorsFor(Map<String, dynamic> q) => validate(
    Questions(
      1,
      [
        {'id': 'c', 'nameBn': 'ক', 'nameEn': 'C'},
      ],
      [q],
    ),
    mushaf,
  ).map((e) => e.message).toList();

  test('a published answer must cite an ayah', () {
    expect(errorsFor(question('published', [])), ['no ayah references']);
  });

  test('the author may publish an answer without an ayah', () {
    expect(errorsFor(question('published', [], noAyah: true)), isEmpty);
  });

  test('noAyah with refs is a contradiction', () {
    expect(errorsFor(question('published', ['1:1'], noAyah: true)), [
      'noAyah is set but refs are given',
    ]);
  });

  test('a draft may cite none while the author decides', () {
    expect(errorsFor(question('draft', [])), isEmpty);
  });

  test('a draft ref is still checked against the mushaf', () {
    expect(errorsFor(question('draft', ['1:8'])), [
      'ref "1:8": surah 1 has 7 ayat',
    ]);
  });
}
