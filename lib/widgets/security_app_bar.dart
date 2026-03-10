import 'package:flutter/material.dart';

class SecurityTopBar extends StatelessWidget {
  const SecurityTopBar({
    super.key,
    required this.isProtected,
    this.actions,
    this.showBackButton = true,
  });

  final bool isProtected;
  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            if (showBackButton && canPop)
              TopBarActionButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
              ),
            Container(
              width: 36,
              height: 36,
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
            const Spacer(),
            _ProtectionBadge(isProtected: isProtected),
            ...?actions,
          ],
        ),
      ),
    );
  }
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
        margin: const EdgeInsets.only(right: 8),
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

class TopBarActionButton extends StatelessWidget {
  const TopBarActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: colors.onSurface,
          ),
        ),
      ),
    );
  }
}
