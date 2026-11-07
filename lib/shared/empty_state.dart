import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/typography.dart';

/// Centered empty-screen message: a large muted icon from the app's icon
/// set, a title and a one-line hint. Optional [action] sits underneath.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  /// Large Iconsax icon for the context (clock, bookmark, search...).
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    // Centered in whatever space the parent gives it; scrolls only if the
    // screen is too short (large text, landscape).
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 56),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmptyGraphic(icon: icon, colors: c),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: t.rowTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.fg1,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: t.meta.copyWith(fontSize: 13.5, height: 1.6),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGraphic extends StatelessWidget {
  const _EmptyGraphic({required this.icon, required this.colors});

  final IconData icon;
  final AppColors colors;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: Icon(icon, size: 64, color: colors.fg4));
}
