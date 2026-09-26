/// Digit conversion for display.
///
/// Stored numbers are Latin; the UI shows Bengali digits in Bengali text and
/// Arabic-Indic digits inside the end-of-ayah ornament.
library;

const _bengaliDigits = '০১২৩৪৫৬৭৮৯';
const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

String _mapDigits(Object value, String digits) =>
    value.toString().replaceAllMapped(
      RegExp('[0-9]'),
      (m) => digits[m[0]!.codeUnitAt(0) - 0x30],
    );

/// `54` → `৫৪`. Non-digit characters pass through unchanged.
String bnDigits(Object value) => _mapDigits(value, _bengaliDigits);

/// `15` → `١٥`.
String arDigits(Object value) => _mapDigits(value, _arabicDigits);

/// The end-of-ayah ornament followed by the verse number.
///
/// Amiri Quran draws the digits that follow U+06DD inside the ornament, so this
/// must stay one run of text with no space between the two.
String ayahEndMark(int ayah) => '۝${arDigits(ayah)}';

const _bengaliMonths = [
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

/// `2026-09-23` → `২৩ সেপ্টেম্বর`.
String bnDayMonth(DateTime date) =>
    '${bnDigits(date.day)} ${_bengaliMonths[date.month - 1]}';
