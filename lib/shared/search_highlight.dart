import 'package:flutter/painting.dart';

import '../core/db/content_search.dart';

/// Whitespace runs and the words between them, kept in order so the text
/// reassembles exactly.
final _pieces = RegExp(r'\s+|\S+');

/// [text] as spans, with every word the query matched in [hit].
///
/// With no [terms] the text comes back as one plain span.
TextSpan highlightSpan(String text, SearchTerms? terms, TextStyle hit) {
  if (terms == null) return TextSpan(text: text);
  final children = <TextSpan>[];
  final plain = StringBuffer();
  void flush() {
    if (plain.isEmpty) return;
    children.add(TextSpan(text: plain.toString()));
    plain.clear();
  }

  for (final m in _pieces.allMatches(text)) {
    final piece = m[0]!;
    if (piece.trim().isNotEmpty && terms.hits(piece)) {
      flush();
      children.add(TextSpan(text: piece, style: hit));
    } else {
      plain.write(piece);
    }
  }
  flush();
  return TextSpan(children: children);
}

/// A few words of [text] around its first match, or null if none matched.
///
/// Shown under a question whose answer, not its title, held the match, so the
/// row says why it is there.
TextSpan? snippetSpan(
  String text,
  SearchTerms terms,
  TextStyle hit, {
  int before = 4,
  int after = 14,
}) {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final first = words.indexWhere(terms.hits);
  if (first < 0) return null;
  final start = (first - before).clamp(0, words.length);
  final end = (first + after).clamp(0, words.length);
  final excerpt = [
    if (start > 0) '…',
    ...words.sublist(start, end),
    if (end < words.length) '…',
  ].join(' ');
  return highlightSpan(excerpt, terms, hit);
}
