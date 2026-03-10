import 'package:flutter/material.dart';

class SecurityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SecurityAppBar({
    super.key,
    required this.title,
    required this.isProtected,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final bool isProtected;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _ProtectionBadge(isProtected: isProtected),
        ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ProtectionBadge extends StatelessWidget {
  const _ProtectionBadge({required this.isProtected});

  final bool isProtected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey<bool>(isProtected),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isProtected
              ? colors.primary.withValues(alpha: 0.16)
              : colors.error.withValues(alpha: 0.18),
          border: Border.all(
            color: isProtected ? colors.primary : colors.error,
          ),
        ),
        child: Text(
          isProtected ? 'PROTECTED' : 'EXPOSED',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: isProtected ? colors.primary : colors.error,
              ),
        ),
      ),
    );
  }
}
