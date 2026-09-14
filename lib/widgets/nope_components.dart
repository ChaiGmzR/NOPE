import 'package:flutter/material.dart';

class NopeWordmark extends StatelessWidget {
  const NopeWordmark({super.key, this.inverse = false, this.compact = false});

  final bool inverse;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = inverse
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NOPE',
          style: TextStyle(
            color: color,
            fontSize: compact ? 23 : 31,
            height: .9,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 5),
          Text(
            'STAY FOCUS',
            style: TextStyle(
              color: color.withValues(alpha: .62),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
        ],
      ],
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.8,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class NopeButton extends StatelessWidget {
  const NopeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label.toUpperCase()),
      style: secondary
          ? FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            )
          : FilledButton.styleFrom(
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? scheme.onSurface : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: active ? scheme.surface : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class NumberBadge extends StatelessWidget {
  const NumberBadge(this.value, {super.key});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
