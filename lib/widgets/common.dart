import 'package:flutter/material.dart';

import '../theme.dart';

class FocusXCard extends StatelessWidget {
  const FocusXCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.gradient,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: FocusXColors.surface,
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.035)),
      ),
      child: child,
    );
  }
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: FocusXColors.green,
        foregroundColor: FocusXColors.background,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class PreviewBadge extends StatelessWidget {
  const PreviewBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FocusXColors.violet.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: FocusXColors.violet,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class PrototypeNotice extends StatelessWidget {
  const PrototypeNotice({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return FocusXCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: FocusXColors.violet),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FocusXColors.muted,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.body,
    this.icon = Icons.hourglass_empty_rounded,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FocusXCard(
      child: Column(
        children: [
          Icon(icon, size: 34, color: FocusXColors.muted),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: FocusXColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}
