import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../core/db/database_providers.dart';
import '../core/strings.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../features/questions/question_providers.dart';

/// A folder picked in [pickFolder]; [id] null means "no folder".
typedef FolderChoice = ({int? id});

/// Asks where a saved item goes: no folder, an existing folder, or a new one
/// (named on the spot). Null when the sheet is dismissed.
///
/// Reads through the provider container rather than a ref: filing can remove
/// the calling row from a filtered list, and a ref is unusable once it's gone.
Future<FolderChoice?> pickFolder(
  BuildContext context, {
  required int? current,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final folders = container.read(foldersProvider).value ?? const [];

  Widget tile(
    BuildContext context,
    IconData icon,
    String label,
    _Pick value, {
    bool selected = false,
  }) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: selected ? const Icon(IconsaxPlusLinear.tick_circle) : null,
    onTap: () => Navigator.pop(context, value),
  );

  final pick = await showModalBottomSheet<_Pick>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const SheetTitle(Strings.moveToFolder),
          tile(
            context,
            IconsaxPlusLinear.folder_cross,
            Strings.noFolder,
            const _Pick(null),
            selected: current == null,
          ),
          for (final f in folders)
            tile(
              context,
              IconsaxPlusLinear.folder,
              f.name,
              _Pick(f.id),
              selected: current == f.id,
            ),
          tile(
            context,
            IconsaxPlusLinear.folder_add,
            Strings.newFolder,
            const _Pick.create(),
          ),
        ],
      ),
    ),
  );
  if (pick == null || !context.mounted) return null;
  if (!pick.create) return (id: pick.folder);
  final name = await askFolderName(context);
  if (name == null) return null;
  final db = await container.read(userDatabaseProvider.future);
  return (id: await db.createFolder(name));
}

/// A destination picked in the folder sheet.
class _Pick {
  const _Pick(this.folder) : create = false;
  const _Pick.create() : folder = null, create = true;

  /// The folder to file into; null unfiles.
  final int? folder;

  /// Make a new folder and file into that.
  final bool create;
}

/// The heading at the top of a bottom sheet.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key});

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
