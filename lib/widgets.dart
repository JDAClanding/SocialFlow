/// Shared theme colors + reusable widgets matching the original web design.
library;

import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFFF7F3EC);
  static const ink = Color(0xFF2C231C);
  static const soft = Color(0xFF7A6A5D);
  static const brand = Color(0xFF5B3A29);
  static const accent = Color(0xFFB07A4F);
  static const cream = Color(0xFFF3E9DD);
  static const line = Color(0xFFE7DCC9);
  static const gold = Color(0xFFC9A24B);
  static const green = Color(0xFF7A8B6F);
  static const rose = Color(0xFFC98A7D);
  static const blue = Color(0xFF8A97A5);
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.brand,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
}

/// crumb + h1 + lead header used on every step.
class StepHeader extends StatelessWidget {
  final String crumb, title, lead;
  const StepHeader(
      {super.key, required this.crumb, required this.title, required this.lead});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(crumb,
            style: const TextStyle(
                fontSize: 11.5,
                letterSpacing: 3,
                color: C.accent,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(title,
            style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 30,
                color: C.brand,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(lead, style: const TextStyle(color: C.soft, fontSize: 15)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class SfCard extends StatelessWidget {
  final Widget child;
  final bool glow;
  final EdgeInsets padding;
  const SfCard(
      {super.key,
      required this.child,
      this.glow = false,
      this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: glow ? C.accent : C.line, width: glow ? 1.5 : 1),
        boxShadow: const [
          BoxShadow(color: Color(0x0D5B3A29), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class SfButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool alt, ghost, big;
  const SfButton(this.label,
      {super.key, this.onPressed, this.alt = false, this.ghost = false, this.big = false});

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((s) =>
          ghost ? Colors.transparent : (alt ? C.cream : C.brand)),
      foregroundColor: WidgetStateProperty.resolveWith(
          (s) => ghost ? C.soft : (alt ? C.brand : Colors.white)),
      side: WidgetStateProperty.resolveWith((s) => ghost
          ? const BorderSide(color: C.line, width: 1.5)
          : BorderSide.none),
      padding: WidgetStateProperty.all(EdgeInsets.symmetric(
          horizontal: big ? 34 : 24, vertical: big ? 16 : 13)),
      textStyle: WidgetStateProperty.all(TextStyle(
          fontSize: big ? 17 : 14.5, fontWeight: FontWeight.w700)),
      shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      elevation: WidgetStateProperty.all(0),
    );
    return ghost
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

/// Small colored label chip ("pill").
class Pill extends StatelessWidget {
  final String text;
  final Color? color;
  const Pill(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? C.accent;
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.withOpacity(.14), C.cream),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

Color stageColor(String stage) => switch (stage) {
      'Conversion' => C.gold,
      'Engagement' => C.green,
      'Advocacy' => C.rose,
      _ => C.accent,
    };

/// Back / Continue navigation row.
class NavRow extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const NavRow(
      {super.key, this.showBack = true, this.onBack, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          showBack
              ? SfButton('← Back', ghost: true, onPressed: onBack)
              : const SizedBox.shrink(),
          SfButton('Continue →', onPressed: onNext),
        ],
      ),
    );
  }
}

/// Label + input used across the wizard.
class Field extends StatelessWidget {
  final String label;
  final Widget child;
  const Field(this.label, this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: C.brand)),
        ),
        child,
      ],
    );
  }
}

InputDecoration sfInput([String? hint]) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFFFFDF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: C.line, width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: C.line, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: C.accent, width: 1.5)),
    );

/// Loading row ("reading site…", "generating…").
class Thinking extends StatelessWidget {
  final String message;
  const Thinking(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 3, color: C.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: C.soft, fontSize: 13.5))),
        ],
      ),
    );
  }
}

/// Error text line.
class ErrText extends StatelessWidget {
  final String message;
  const ErrText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(message,
          style: const TextStyle(color: C.rose, fontSize: 13)),
    );
  }
}

/// Selectable research card (used in deep-dive & trend scan results).
class SelCard extends StatelessWidget {
  final String title, snippet;
  final bool selected;
  final VoidCallback onTap;
  final String? url;
  const SelCard({
    super.key,
    required this.title,
    required this.snippet,
    required this.selected,
    required this.onTap,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5F8F2) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: selected ? C.green : C.line, width: selected ? 2 : 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: C.brand)),
                ),
                if (selected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: C.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check,
                        size: 13, color: Colors.white),
                  ),
              ],
            ),
            if (snippet.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(snippet,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 12, color: C.soft)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Square selectable image thumbnail.
class Thumb extends StatelessWidget {
  final String url;
  final bool selected;
  final VoidCallback onTap;
  const Thumb(
      {super.key, required this.url, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: selected ? C.green : Colors.transparent, width: 3),
          color: C.cream,
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(url, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined, color: C.soft)),
        ),
      ),
    );
  }
}
