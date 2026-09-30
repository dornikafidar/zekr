import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/settings_provider.dart';
import '../providers/zekr_provider.dart';
import '../l10n/fa.dart';
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
                        Fa.settings,
                        textAlign: TextAlign.center,
                        style: AppTheme.latin(
                          fontSize: 18,
                          weight: FontWeight.w600,
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
                    _label(Fa.fontSize),
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'A',
                                style: AppTheme.latin(
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
                                  onChanged: (v) => settings.setFontScale(v),
                                ),
                              ),
                              Text(
                                'A',
                                style: AppTheme.latin(
                                  fontSize: 24,
                                  color: AppColors.cream,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${Fa.current}: ${(settings.fontScale * 100).round()}٪',
                            style: AppTheme.latin(
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
                            Fa.arabicPreview,
                            style: AppTheme.latin(
                              fontSize: 14,
                              color: AppColors.mist,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _label(Fa.backup),
                    Text(
                      '${Fa.backupHint} (${Fa.entries(zekrCount)}).',
                      style: AppTheme.latin(
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
                              Fa.export,
                              style: AppTheme.latin(
                                weight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              Fa.exportSub,
                              style: AppTheme.latin(
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
                              Fa.import_,
                              style: AppTheme.latin(
                                weight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              Fa.importSub,
                              style: AppTheme.latin(
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
        style: AppTheme.latin(
          fontSize: 12,
          weight: FontWeight.w600,
          letterSpacing: 1.4,
          color: AppColors.mist,
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final provider = context.read<ZekrProvider>();
    final json = provider.exportBackupJson();
    final stamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = 'zekr-backup-$stamp.json';

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json, encoding: utf8);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'پشتیبان ذکر',
          text: 'پشتیبان محلی ذکر',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Fa.backupReadyN(provider.items.length),
              style: AppTheme.latin(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Fa.exportFailed}: $e',
              style: AppTheme.latin(),
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
        title: Text(Fa.importBackupQ, style: AppTheme.latin()),
        content: Text(
          Fa.importBackupHint,
          style: AppTheme.latin(color: AppColors.mist),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(Fa.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              Fa.import_,
              style: AppTheme.latin(color: AppColors.gold),
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
            Fa.fileReadFail,
            style: AppTheme.latin(),
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
            Fa.importedN(count),
            style: AppTheme.latin(),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${Fa.importFailed}: $e',
            style: AppTheme.latin(),
          ),
        ),
      );
    }
  }
}
