import 'package:flutter/material.dart';
import 'package:cres_carnets_ibmcloud/ui/brand.dart';

Color _on(Color bg) =>
    ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black87;

// Usando colores institucionales UAGro existentes
Color _blue(BuildContext c) => UAGroColors.blue;
Color _gold(BuildContext c) => UAGroColors.gold;
Color _red(BuildContext c) => UAGroColors.error;

void showOk(BuildContext c, String m) =>
    _sb(c, m, _gold(c), Icons.check_circle_rounded);
void showInfo(BuildContext c, String m) =>
    _sb(c, m, _blue(c), Icons.info_rounded);
void showErr(BuildContext c, String m) =>
    _sb(c, m, _red(c), Icons.error_outline);

void _sb(BuildContext c, String m, Color bg, IconData icon) {
  final on = _on(bg);
  ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: on, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(m,
                  style: TextStyle(color: on, fontWeight: FontWeight.w600))),
        ],
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ),
  );
}

Widget busyOverlay(BuildContext c, bool busy) {
  return IgnorePointer(
    ignoring: !busy,
    child: AnimatedOpacity(
      opacity: busy ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: Container(
        color: Colors.black.withOpacity(0.25),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 3, color: _blue(c)),
        ),
      ),
    ),
  );
}
