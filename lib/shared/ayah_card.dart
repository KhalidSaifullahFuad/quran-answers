import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/content_db.dart';
import '../core/db/database_providers.dart';
import '../core/strings.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../features/questions/question_providers.dart';
import 'references.dart';
import 'widgets.dart';

/// One ayah, whole: citation, Arabic, Bengali translation, and a bookmark.
///
/// Never excerpted. Where a list would grow too long the list is capped, not
/// the verse, so a reader never sees half an ayah presented as evidence.
class AyahCard extends ConsumerWidget {
  const AyahCard({
    super.key,
    required this.ayah,
    required this.surah,
    this.actions = const [],
  });

  final Ayah ayah;
  final Surah surah;

  /// Extra buttons placed before the bookmark, e.g. filing into a folder.
  final List<Widget> actions;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = await ref.read(userDatabaseProvider.future);
    final on = await db.toggleAyahBookmark(ayah.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            on ? Strings.ayahBookmarked : Strings.ayahUnbookmarked,
            textAlign: TextAlign.center,
          ),
          duration: const Duration(milliseconds: 1800),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final saved = ref.watch(isAyahBookmarkedProvider(ayah.id)).value ?? false;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 6, 16),
      decoration: BoxDecoration(
        color: c.evidence,
        borderRadius: BorderRadius.circular(Space.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RefPill(label: refLong(surah, ayah.id)),
                ),
              ),
              ...actions,
              IconButton(
                onPressed: () => _toggle(context, ref),
                tooltip: Strings.bookmarkAyah,
                isSelected: saved,
                visualDensity: VisualDensity.compact,
                iconSize: 21,
                color: c.fg2,
                icon: const Icon(Icons.bookmark_border_rounded),
                selectedIcon: const Icon(Icons.bookmark_rounded),
              ),
            ],
          ),
          Padding(
            // The card's right padding is narrow to seat the icon button; the
            // text keeps the full inset.
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                ArabicText(ayah.textUthmani, ayah: ayah.ayah),
                const SizedBox(height: 14),
                Text(ayah.translationBn, style: t.translation),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
