import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../state/connectivity_controller.dart';

/// Downloads every font option once so they work offline afterwards.
/// google_fonts keeps downloaded font files on the device.
class FontDownloadTile extends StatefulWidget {
  const FontDownloadTile({super.key});

  @override
  State<FontDownloadTile> createState() => _FontDownloadTileState();
}

class _FontDownloadTileState extends State<FontDownloadTile> {
  bool _busy = false;
  String? _message;
  bool _failed = false;

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _message = null;
      _failed = false;
    });
    try {
      final styles = <TextStyle>[];
      for (final family in ThemeController.fontOptions) {
        if (family == ThemeController.systemFont) continue;
        for (final w in const [
          FontWeight.w400,
          FontWeight.w500,
          FontWeight.w600,
          FontWeight.w700,
          FontWeight.w800,
        ]) {
          styles.add(GoogleFonts.getFont(family, fontWeight: w));
        }
      }
      await GoogleFonts.pendingFonts(styles);
      if (!mounted) return;
      setState(() => _message = 'Fonts saved. They now work offline.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _message = 'Could not download all fonts. Check your connection '
            'and try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityController>().isOnline;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: (online && !_busy) ? _download : null,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_for_offline_rounded),
          label: Text(
            _busy
                ? 'Downloading fonts...'
                : (online ? 'Download fonts for offline use' : 'Offline'),
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _message!,
              style: text.bodySmall?.copyWith(
                color: _failed ? const Color(0xFFFF6B6B) : null,
              ),
            ),
          ),
      ],
    );
  }
}
