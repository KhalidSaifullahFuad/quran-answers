import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/db/content_db.dart';
import '../../core/db/database_providers.dart';
import '../../core/db/user_db.dart';
import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/ayah_card.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/widgets.dart';
import '../questions/question_providers.dart';

/// Saved questions and verses, filtered by folder, then reading history.
///
/// Everything here is held by slug or ayah id in the user database. An item
/// whose question a content update removed is simply skipped.
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
              const ContentFrame(
                child: ScreenHeader(title: Strings.navSaved, showBack: false),
              ),
              _FolderBar(
                folders: folders,
                selected: folder,
                onSelect: (id) => setState(() => _folder = id),
              ),
              const SizedBox(height: 18),
              ContentFrame(
                child: _SavedLists(
                  index: index,
                  folders: folders,
                  folder: folder,
                ),
              ),
              if (folder == null) ...[
                const SizedBox(height: 22),
                ContentFrame(child: _History(index: index)),
              ],
            ],
          ),
        ),
      ),
    );
  }
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

  Future<void> _manage(BuildContext context, WidgetRef ref, Folder f) async {
    final action = await showModalBottomSheet<_FolderAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetTitle(f.name),
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
            icon: IconsaxPlusLinear.save_2,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final f in folders) ...[
            const SizedBox(width: 8),
            TopicChip(
              label: f.name,
              icon: selected == f.id
                  ? IconsaxPlusBold.folder
                  : IconsaxPlusLinear.folder,
              selected: selected == f.id,
              onTap: () => onSelect(f.id),
              onLongPress: () => _manage(context, ref, f),
            ),
          ],
          const SizedBox(width: 8),
          TopicChip(
            label: Strings.newFolder,
            icon: IconsaxPlusLinear.folder_add,
            onTap: () => _create(context, ref),
          ),
        ],
      ),
    );
  }
}

enum _FolderAction { rename, delete }

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
  String _meta(Question q, int? inFolder) {
    final refs = refsSummary(index.citationsOf(q));
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
      child: Text(text, style: t.meta.copyWith(fontSize: 14)),
    );

    if (folder != null && questions.isEmpty && verses.isEmpty) {
      return note(Strings.folderEmpty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (folder == null || questions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: SectionTitle(
              Strings.savedQuestions,
              trailing: questions.isEmpty
                  ? null
                  : Strings.questionCount(bnDigits(questions.length)),
            ),
          ),
          const SizedBox(height: 4),
          if (questions.isEmpty) note(Strings.savedEmpty),
          for (final (q, inFolder) in questions)
            QuestionTile(
              icon: IconsaxPlusBold.archive_1,
              title: q.questionBn,
              meta: _meta(q, inFolder),
              onTap: () => context.openQuestion(q.slug),
              trailing: _FileButton(
                current: inFolder,
                move: (db, to) => db.moveBookmark(q.slug, to),
              ),
            ),
          const SizedBox(height: 22),
        ],
        if (folder == null || verses.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: SectionTitle(
              Strings.savedAyat,
              trailing: verses.isEmpty
                  ? null
                  : Strings.ayahCount(bnDigits(verses.length)),
            ),
          ),
          if (verses.isEmpty) ...[
            const SizedBox(height: 4),
            note(Strings.savedAyatEmpty),
          ],
          for (final (a, s, inFolder) in verses)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                12,
                Space.gutter,
                0,
              ),
              child: AyahCard(
                ayah: a,
                surah: s,
                actions: [
                  _FileButton(
                    current: inFolder,
                    move: (db, to) => db.moveAyahBookmark(a.id, to),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Reading history, newest first, with a way to clear it.
class _History extends ConsumerWidget {
  const _History({required this.index});

  final QuestionIndex index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppText.of(context);
    final history = ref.watch(recentSlugsProvider).value ?? const [];
    final questions = history.map(index.bySlug).nonNulls.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Space.gutter, right: 6),
          child: Row(
            children: [
              Expanded(child: Text(Strings.readingHistory, style: t.section)),
              if (questions.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final ok = await confirm(
                      context,
                      Strings.clearHistoryConfirm,
                      action: Strings.delete,
                    );
                    if (!ok) return;
                    final db = await ref.read(userDatabaseProvider.future);
                    await db.clearHistory();
                  },
                  child: Text(Strings.clearHistory, style: t.link),
                ),
            ],
          ),
        ),
        if (questions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.gutter,
              vertical: 10,
            ),
            child: Text(
              Strings.historyEmpty,
              style: t.meta.copyWith(fontSize: 14),
            ),
          ),
        for (final q in questions)
          QuestionTile(
            icon: IconsaxPlusLinear.clock_1,
            title: q.questionBn,
            meta: refsSummary(index.citationsOf(q)),
            onTap: () => context.openQuestion(q.slug),
          ),
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
        // The container, not ref: filing can remove this row from a filtered
        // list, and ref is unusable once the row is gone.
        final container = ProviderScope.containerOf(context, listen: false);
        final folders = container.read(foldersProvider).value ?? const [];
        final choice = await showModalBottomSheet<_Choice>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const _SheetTitle(Strings.moveToFolder),
                _choiceTile(
                  context,
                  IconsaxPlusLinear.folder_cross,
                  Strings.noFolder,
                  const _Choice(null),
                  selected: current == null,
                ),
                for (final f in folders)
                  _choiceTile(
                    context,
                    IconsaxPlusLinear.folder,
                    f.name,
                    _Choice(f.id),
                    selected: current == f.id,
                  ),
                _choiceTile(
                  context,
                  IconsaxPlusLinear.folder_add,
                  Strings.newFolder,
                  const _Choice.create(),
                ),
              ],
            ),
          ),
        );
        if (choice == null || !context.mounted) return;
        final db = await container.read(userDatabaseProvider.future);
        if (!context.mounted) return;
        var target = choice.folder;
        if (choice.create) {
          final name = await askFolderName(context);
          if (name == null) return;
          target = await db.createFolder(name);
        }
        await move(db, target);
      },
    );
  }

  Widget _choiceTile(
    BuildContext context,
    IconData icon,
    String label,
    _Choice value, {
    bool selected = false,
  }) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: selected ? const Icon(IconsaxPlusLinear.tick_circle) : null,
    onTap: () => Navigator.pop(context, value),
  );
}

/// A destination picked in the folder sheet.
class _Choice {
  const _Choice(this.folder) : create = false;
  const _Choice.create() : folder = null, create = true;

  /// The folder to file into; null unfiles.
  final int? folder;

  /// Make a new folder and file into that.
  final bool create;
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, 8),
      child: Text(text, style: AppText.of(context).section),
    );
  }
}

/// Asks for a folder name; null when cancelled or left blank.
Future<String?> askFolderName(BuildContext context, {String initial = ''}) =>
    showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: initial),
    );

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Strings.folderName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Strings.cancel),
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => TextButton(
            onPressed: _controller.text.trim().isEmpty ? null : _submit,
            child: const Text(Strings.save),
          ),
        ),
      ],
    );
  }
}

/// A yes/no question before something destructive; false when dismissed.
Future<bool> confirm(
  BuildContext context,
  String message, {
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(Strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
