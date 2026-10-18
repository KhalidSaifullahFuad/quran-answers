import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../core/db/content_db.dart';
import '../core/db/database_providers.dart';
import '../core/strings.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../features/questions/question_providers.dart';
import 'folder_sheet.dart';
import 'navigation.dart';
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
    this.linkToAyah = true,
  });

  final Ayah ayah;
  final Surah surah;

  /// Extra buttons placed before the bookmark, e.g. filing into a folder.
  final List<Widget> actions;

  /// Whether the citation opens the verse on its own screen, with its context.
  /// Off on that screen itself.
  final bool linkToAyah;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = await ref.read(userDatabaseProvider.future);
    final on = await db.toggleAyahBookmark(ayah.id);
    if (!context.mounted) return;
    showStatusToast(
      messenger,
      icon: on ? IconsaxPlusBold.archive_1 : IconsaxPlusLinear.archive_1,
      text: on ? Strings.ayahBookmarked : Strings.unbookmarked,
      actionLabel: on ? Strings.folderAction : Strings.undo,
      onAction: on
          ? () async {
              final choice = await pickFolder(context, current: null);
              if (choice != null) await db.moveAyahBookmark(ayah.id, choice.id);
            }
          : () => db.toggleAyahBookmark(ayah.id),
    );
  }

  /// Arabic, translation and citation, ready to paste.
  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(
        text:
            '${ayah.textUthmani}\n\n${ayah.translationBn}\n— ${refLong(surah, ayah.id)}',
      ),
    );
    showStatusToast(
      messenger,
      icon: IconsaxPlusLinear.copy_success,
      text: Strings.copied,
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
                  child: RefPill(
                    label: refLong(surah, ayah.id),
                    onTap: linkToAyah
                        ? () => context.openAyah(ayah.surah, ayah.ayah)
                        : null,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copy(context),
                tooltip: Strings.copyAyah,
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                color: c.fg3,
                icon: const Icon(IconsaxPlusLinear.copy),
              ),
              ...actions,
              IconButton(
                onPressed: () => _toggle(context, ref),
                tooltip: Strings.bookmarkAyah,
                isSelected: saved,
                visualDensity: VisualDensity.compact,
                iconSize: 21,
                color: c.fg2,
                icon: const Icon(IconsaxPlusLinear.archive_1),
                selectedIcon: const Icon(IconsaxPlusBold.archive_1),
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
