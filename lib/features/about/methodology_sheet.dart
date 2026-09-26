import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

/// How the answers are put together, and what they are not.
///
/// Opened beside every compiled answer, because the distinction it draws — a
/// human summary above, the Qur'an itself below — is the one a reader most
/// needs when weighing an answer.
Future<void> showMethodologySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final c = AppColors.of(context);
      final t = AppText.of(context);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              24,
            ),
            children: [
              Text(Strings.methodology, style: t.screenTitle),
              const SizedBox(height: 16),
              for (final point in Strings.methodologyPoints)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: c.fg3,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          point,
                          style: t.meta.copyWith(
                            fontSize: 14.5,
                            height: 1.65,
                            color: c.fg2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
