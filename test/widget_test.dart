import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/app.dart';
import 'package:quran_answers/core/db/database_providers.dart';

/// Boots the app the way a device does: the real asset is copied out of the
/// bundle, opened, and queried. Only the target directory and the opener are
/// substituted — path_provider has no implementation in a test, and a background
/// isolate cannot deliver messages through a fake clock.
///
/// The copy runs inside [WidgetTester.runAsync] and, importantly, *before* the
/// widget is pumped. A widget test fakes async: a future started while the fake
/// clock is in charge has its continuations queued in that zone, so awaiting it
/// from inside runAsync afterwards waits forever. Resolving the database first
/// means the screen only ever awaits work that is already done.
///
/// This is the one test that exercises the whole startup path at once, which is
/// where a mistake would otherwise first surface as a blank screen on a phone.
void main() {
  testWidgets('app opens the shipped database and reads from it', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('app_startup_test');
    final container = ProviderContainer(
      overrides: [
        appDirectoryProvider.overrideWith((ref) async => directory),
        databaseOpenerProvider.overrideWithValue(NativeDatabase.new),
      ],
    );
    addTearDown(() async {
      // Closed explicitly before the directory goes: on Windows the open
      // database file keeps a handle that makes the delete fail.
      final db = await container.read(contentDatabaseProvider.future);
      await db.close();
      container.dispose();
      try {
        if (directory.existsSync()) directory.deleteSync(recursive: true);
      } on FileSystemException {
        // The temp directory is disposable; a lingering handle is not a failure
        // worth failing a passing test over.
      }
    });

    await tester.runAsync(() async {
      await container.read(contentDatabaseProvider.future);
      await container.read(startupSummaryProvider.future);
    });

    // The copy really landed on disk, under the names the store documents.
    expect(File('${directory.path}/content.db').existsSync(), isTrue);
    expect(File('${directory.path}/content.db.version').existsSync(), isTrue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const QuranAnswersApp(),
      ),
    );
    // Not pumpAndSettle: the loading state is an indeterminate progress
    // indicator, which animates forever, so nothing ever "settles". One frame is
    // enough, because both providers were resolved above.
    await tester.pump();

    expect(
      find.textContaining('6236 ayat'),
      findsOne,
      reason: 'the whole mushaf should be readable',
    );
    expect(find.textContaining('Sheikh Mujibur Rahman'), findsOne);
    expect(find.textContaining('Failed to open'), findsNothing);
  });
}
