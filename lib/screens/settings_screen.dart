import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/settings_provider.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final zekrCount = context.watch<ZekrProvider>().items.length;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.cream,
                    ),
                    Expanded(
                      child: Text(
                        'Einstellungen',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _label('SCHRIFTGRÖSSE'),
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'A',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppColors.mist,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: settings.fontScale,
                                  min: 0.85,
                                  max: 1.6,
                                  divisions: 15,
                                  activeColor: AppColors.gold,
                                  inactiveColor: AppColors.cardBorder,
                                  label:
                                      '${(settings.fontScale * 100).round()}%',
                                  onChanged: (v) =>
                                      settings.setFontScale(v),
                                ),
                              ),
                              Text(
                                'A',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  color: AppColors.cream,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Aktuell: ${(settings.fontScale * 100).round()}%',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.mist,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سُبْحَانَ ٱللَّهِ',
                            textDirection: TextDirection.rtl,
                            style: AppTheme.arabic(fontSize: 28),
                          ),
                          Text(
                            'Vorschau der arabischen Schrift',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.mist,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _label('BACKUP'),
                    Text(
                      'Alle Zekr lokal sichern oder wiederherstellen ($zekrCount Einträge).',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.mist,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.upload_file_rounded,
                              color: AppColors.gold,
                            ),
                            title: Text(
                              'Exportieren',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'JSON-Datei speichern / teilen',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.mist,
                              ),
                            ),
                            onTap: () => _export(context),
                          ),
                          const Divider(
                            color: AppColors.cardBorder,
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.download_rounded,
                              color: AppColors.mint,
                            ),
                            title: Text(
                              'Importieren',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Backup laden (ersetzt alle lokalen Zekr)',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.mist,
                              ),
                            ),
                            onTap: () => _import(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: AppColors.mist,
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final provider = context.read<ZekrProvider>();
    final json = provider.exportBackupJson();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final fileName = 'zekr-backup-$stamp.json';

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json, encoding: utf8);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Zekr Backup',
          text: 'Lokales Zekr-Backup',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup bereit (${provider.items.length} Zekr)',
              style: GoogleFonts.outfit(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export fehlgeschlagen: $e',
              style: GoogleFonts.outfit(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forest,
        title: Text('Backup importieren?', style: GoogleFonts.outfit()),
        content: Text(
          'Alle aktuellen Zekr auf diesem Gerät werden durch das Backup ersetzt.',
          style: GoogleFonts.outfit(color: AppColors.mist),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Importieren',
              style: GoogleFonts.outfit(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final zekrProvider = context.read<ZekrProvider>();

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    String? raw;
    if (file.bytes != null) {
      raw = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      raw = await File(file.path!).readAsString(encoding: utf8);
    }
    if (raw == null || raw.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Datei konnte nicht gelesen werden',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
      return;
    }

    try {
      final count = await zekrProvider.importBackupJson(raw);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '$count Zekr importiert',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Import fehlgeschlagen: $e',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    }
  }
}
