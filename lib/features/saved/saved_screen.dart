import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/db/database_providers.dart';
import '../../core/db/user_db.dart';
import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/folder_sheet.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/widgets.dart';
import '../questions/question_providers.dart';

/// Saved questions and verses, filtered by folder.
///
/// Everything here is held by slug or ayah id in the user database. An item
/// whose question a content update removed is simply skipped. Reading history
/// is not saved content, so it has its own screen, reached from the header.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  /// The folder being shown, or null for everything.
  int? _folder;

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(questionIndexProvider);
    final folders = ref.watch(foldersProvider).value ?? const [];
    // A folder deleted while selected falls back to showing everything.
    final folder = folders.any((f) => f.id == _folder) ? _folder : null;

    return Scaffold(
      body: SafeArea(
        child: AsyncBody(
          value: index,
          data: (index) => ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              ContentFrame(
                child: ScreenHeader(
                  title: Strings.navSaved,
                  showBack: false,
                  actions: [
                    IconButton(
                      onPressed: context.openHistory,
                      tooltip: Strings.readingHistory,
                      icon: const Icon(IconsaxPlusLinear.clock_1),
                    ),
                    IconButton(
                      onPressed: () => _manageFolders(context, ref, folders),
                      tooltip: Strings.manageFolders,
                      icon: const Icon(IconsaxPlusLinear.folder_2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ContentFrame(
                child: _FolderBar(
                  folders: folders,
                  selected: folder,
                  onSelect: (id) => setState(() => _folder = id),
                ),
              ),
              const SizedBox(height: 18),
              ContentFrame(
                child: _SavedLists(
                  index: index,
                  folders: folders,
                  folder: folder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FolderAction { rename, delete }

/// Rename or delete one folder: the sheet behind a long press on its chip and
/// behind each row of the manage sheet.
Future<void> _editFolder(
  BuildContext context,
  WidgetRef ref,
  Folder f, {
  _FolderAction? action,
}) async {
  action ??= await showModalBottomSheet<_FolderAction>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(f.name),
          ListTile(
            leading: const Icon(IconsaxPlusLinear.edit_2),
            title: const Text(Strings.renameFolder),
            onTap: () => Navigator.pop(context, _FolderAction.rename),
          ),
          ListTile(
            leading: const Icon(IconsaxPlusLinear.trash),
            title: const Text(Strings.deleteFolder),
            onTap: () => Navigator.pop(context, _FolderAction.delete),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  final db = await ref.read(userDatabaseProvider.future);
  if (!context.mounted) return;
  switch (action) {
    case _FolderAction.rename:
      final name = await askFolderName(context, initial: f.name);
      if (name != null) await db.renameFolder(f.id, name);
    case _FolderAction.delete:
      final ok = await confirm(
        context,
        Strings.deleteFolderConfirm(f.name),
        action: Strings.delete,
      );
      if (ok) await db.deleteFolder(f.id);
  }
}

/// Every folder with its rename and delete buttons in view, plus a new one.
/// The discoverable route to what a long press on a chip also offers.
Future<void> _manageFolders(
  BuildContext context,
  WidgetRef ref,
  List<Folder> folders,
) async {
  final picked = await showModalBottomSheet<(Folder?, _FolderAction?)>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const SheetTitle(Strings.manageFolders),
          for (final f in folders)
            ListTile(
              leading: const Icon(IconsaxPlusLinear.folder),
              title: Text(f.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: Strings.renameFolder,
                    icon: const Icon(IconsaxPlusLinear.edit_2, size: 20),
                    onPressed: () =>
                        Navigator.pop(context, (f, _FolderAction.rename)),
                  ),
                  IconButton(
                    tooltip: Strings.deleteFolder,
                    icon: const Icon(IconsaxPlusLinear.trash, size: 20),
                    onPressed: () =>
                        Navigator.pop(context, (f, _FolderAction.delete)),
                  ),
                ],
              ),
            ),
          ListTile(
            leading: const Icon(IconsaxPlusLinear.folder_add),
            title: const Text(Strings.newFolder),
            onTap: () => Navigator.pop(context, (null, null)),
          ),
        ],
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  final (folder, action) = picked;
  if (folder != null) {
    await _editFolder(context, ref, folder, action: action);
    return;
  }
  final name = await askFolderName(context);
  if (name == null) return;
  final db = await ref.read(userDatabaseProvider.future);
  await db.createFolder(name);
}

/// `সব`, one chip per folder, then a chip that makes a new one. Long-pressing
/// a folder offers rename and delete.
class _FolderBar extends ConsumerWidget {
  const _FolderBar({
    required this.folders,
    required this.selected,
    required this.onSelect,
  });

  final List<Folder> folders;
  final int? selected;
  final ValueChanged<int?> onSelect;

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await askFolderName(context);
    if (name == null) return;
    final db = await ref.read(userDatabaseProvider.future);
    onSelect(await db.createFolder(name));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: Row(
        children: [
          TopicChip(
            label: Strings.allFolders,
            icon: const Icon(IconsaxPlusLinear.save_2),
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final f in folders) ...[
            const SizedBox(width: 8),
            TopicChip(
              label: f.name,
              icon: Icon(
                selected == f.id
                    ? IconsaxPlusBold.folder
                    : IconsaxPlusLinear.folder,
              ),
              selected: selected == f.id,
              onTap: () => onSelect(f.id),
              onLongPress: () => _editFolder(context, ref, f),
            ),
          ],
          const SizedBox(width: 8),
          TopicChip(
            label: Strings.newFolder,
            icon: const Icon(IconsaxPlusLinear.folder_add),
            onTap: () => _create(context, ref),
          ),
        ],
      ),
    );
  }
}

/// Saved questions, then saved verses, both limited to [folder] when set.
class _SavedLists extends ConsumerWidget {
  const _SavedLists({
    required this.index,
    required this.folders,
    required this.folder,
  });

  final QuestionIndex index;
  final List<Folder> folders;
  final int? folder;

  /// `মুখস্থ করব • ৭৮:২, ৩৮:৬৭` — the folder is named only in the unfiltered
  /// view; inside a folder it would repeat the selected chip.
  String _meta(String refs, int? inFolder) {
    if (folder != null || inFolder == null) return refs;
    final name = folders.where((f) => f.id == inFolder).firstOrNull?.name;
    return [?name, refs].join(' • ');
  }

  bool _inView(int? itemFolder) => folder == null || itemFolder == folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppText.of(context);
    final marks = ref.watch(bookmarksProvider).value ?? const [];
    final ayahMarks = ref.watch(ayahBookmarksProvider).value ?? const [];
    final ayahs = ref.watch(savedAyahsProvider).value ?? const {};
    final surahs = ref.watch(surahsProvider).value ?? const {};

    final questions = [
      for (final b in marks)
        if (_inView(b.folderId))
          if (index.bySlug(b.questionSlug) case final q?) (q, b.folderId),
    ];
    final verses = [
      for (final b in ayahMarks)
        if (_inView(b.folderId))
          if (ayahs[b.ayahId] case final a?)
            if (surahs[a.surah] case final s?) (a, s, b.folderId),
    ];

    Widget note(String text) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.gutter,
        vertical: 10,
      ),
      child: Text(text, style: t.meta.copyWith(fontSize: 14, height: 1.6)),
    );

    if (questions.isEmpty && verses.isEmpty) {
      return note(folder == null ? Strings.nothingSaved : Strings.folderEmpty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (questions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: SectionTitle(
              Strings.savedQuestions,
              trailing: Strings.questionCount(bnDigits(questions.length)),
            ),
          ),
          const SizedBox(height: 4),
          for (final (q, inFolder) in questions)
            QuestionTile(
              icon: CategoryIcon(q.category),
              title: q.questionBn,
              meta: _meta(refsSummary(index.citationsOf(q)), inFolder),
              onTap: () => context.openQuestion(q.slug),
              trailing: _FileButton(
                current: inFolder,
                move: (db, to) => db.moveBookmark(q.slug, to),
              ),
            ),
          const SizedBox(height: 22),
        ],
        if (verses.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: SectionTitle(
              Strings.savedAyat,
              trailing: Strings.ayahCount(bnDigits(verses.length)),
            ),
          ),
          const SizedBox(height: 4),
          // A row that leads to the verse, not evidence: the whole ayah is
          // one tap away on its own screen.
          for (final (a, s, inFolder) in verses)
            QuestionTile(
              icon: const Icon(IconsaxPlusLinear.book_1),
              title: a.translationBn,
              titleMaxLines: 2,
              meta: _meta(refLong(s, a.id), inFolder),
              onTap: () => context.openAyah(a.surah, a.ayah),
              trailing: _FileButton(
                current: inFolder,
                move: (db, to) => db.moveAyahBookmark(a.id, to),
              ),
            ),
        ],
      ],
    );
  }
}

/// Files one saved item: pick a folder, no folder, or a new folder.
class _FileButton extends StatelessWidget {
  const _FileButton({required this.current, required this.move});

  final int? current;
  final Future<void> Function(UserDatabase db, int? folder) move;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return IconButton(
      tooltip: Strings.moveToFolder,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      color: current == null ? c.fg3 : c.fg2,
      icon: Icon(
        current == null
            ? IconsaxPlusLinear.folder_open
            : IconsaxPlusBold.folder,
      ),
      onPressed: () async {
        final container = ProviderScope.containerOf(context, listen: false);
        final choice = await pickFolder(context, current: current);
        if (choice == null) return;
        await move(
          await container.read(userDatabaseProvider.future),
          choice.id,
        );
      },
    );
  }
}
