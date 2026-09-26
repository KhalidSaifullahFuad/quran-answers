import 'package:flutter/material.dart';

import '../core/db/content_db.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import 'references.dart';
import 'widgets.dart';

/// One ayah, whole: citation, Arabic, Bengali translation.
///
/// Never excerpted. Where a list would grow too long the list is capped, not
/// the verse, so a reader never sees half an ayah presented as evidence.
class AyahCard extends StatelessWidget {
  const AyahCard({super.key, required this.ayah, required this.surah});

  final Ayah ayah;
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: c.evidence,
        borderRadius: BorderRadius.circular(Space.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: RefPill(label: refLong(surah, ayah.id)),
          ),
          const SizedBox(height: 14),
          ArabicText(ayah.textUthmani, ayah: ayah.ayah),
          const SizedBox(height: 14),
          Text(ayah.translationBn, style: t.translation),
        ],
      ),
    );
  }
}
