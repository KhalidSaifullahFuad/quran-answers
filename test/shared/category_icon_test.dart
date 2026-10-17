import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/shared/references.dart';

import '../support/authored_content.dart';

void main() {
  test('every authored category has its own icon', () {
    final ids = AuthoredContent.load().categoryIds;
    final icons = {for (final id in ids) id: categoryIcon(id)};
    for (final MapEntry(:key, :value) in icons.entries) {
      expect(value, isNot(fallbackCategoryIcon), reason: key);
    }
    expect(icons.values.toSet(), hasLength(ids.length), reason: 'duplicates');
  });
}
