import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/default_zekrs.dart';
import '../models/zekr.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AddEditZekrScreen extends StatefulWidget {
  const AddEditZekrScreen({super.key, this.existing});

  final Zekr? existing;

  @override
  State<AddEditZekrScreen> createState() => _AddEditZekrScreenState();
}

class _AddEditZekrScreenState extends State<AddEditZekrScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _incrementCtrl;
  late final TextEditingController _intervalCtrl;

  late RepeatType _repeatType;
  late TimeOfDay _reminderTime;
  late bool _reminderEnabled;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _textCtrl = TextEditingController(
      text: e?.text ?? (_isEdit ? '' : exampleZekrText),
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _targetCtrl = TextEditingController(text: '${e?.targetCount ?? 110}');
    _incrementCtrl =
        TextEditingController(text: '${e?.incrementPerTap ?? 1}');
    _intervalCtrl = TextEditingController(text: '${e?.intervalDays ?? 3}');
    _repeatType = e?.repeatType ?? RepeatType.daily;
    _reminderEnabled = e?.reminderEnabled ?? true;
    _reminderTime = TimeOfDay(
      hour: e?.reminderHour ?? 8,
      minute: e?.reminderMinute ?? 0,
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _noteCtrl.dispose();
    _targetCtrl.dispose();
    _incrementCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              surface: AppColors.forest,
              onSurface: AppColors.cream,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final text = _textCtrl.text.trim();
    final target = int.parse(_targetCtrl.text.trim());
    final increment = int.parse(_incrementCtrl.text.trim());
    final interval = int.tryParse(_intervalCtrl.text.trim()) ?? 1;
    final note = _noteCtrl.text.trim();

    final provider = context.read<ZekrProvider>();

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        text: text,
        note: note.isEmpty ? null : note,
        clearNote: note.isEmpty,
        targetCount: target,
        incrementPerTap: increment,
        repeatType: _repeatType,
        intervalDays: _repeatType == RepeatType.everyXDays ? interval : 1,
        reminderHour: _reminderTime.hour,
        reminderMinute: _reminderTime.minute,
        reminderEnabled: _reminderEnabled,
      );
      await provider.update(updated);
    } else {
      await provider.add(
        text: text,
        note: note.isEmpty ? null : note,
        targetCount: target,
        incrementPerTap: increment,
        repeatType: _repeatType,
        intervalDays: _repeatType == RepeatType.everyXDays ? interval : 1,
        reminderHour: _reminderTime.hour,
        reminderMinute: _reminderTime.minute,
        reminderEnabled: _reminderEnabled,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.cream,
                    ),
                    Expanded(
                      child: Text(
                        _isEdit ? 'Zekr bearbeiten' : 'Neues Zekr',
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
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _SectionLabel('Text'),
                      TextFormField(
                        controller: _textCtrl,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: AppTheme.arabic(fontSize: 24),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: exampleZekrText,
                          hintTextDirection: TextDirection.rtl,
                          hintStyle: AppTheme.arabic(
                            fontSize: 24,
                            color: AppColors.mist.withValues(alpha: 0.35),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Bitte einen Text eingeben';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      _QuickChips(
                        onSelect: (t) => setState(() => _textCtrl.text = t),
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel('Notiz (optional)'),
                      TextFormField(
                        controller: _noteCtrl,
                        style: GoogleFonts.outfit(),
                        decoration: const InputDecoration(
                          hintText: 'z. B. nach dem Gebet',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel('Ziel & Tippen'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _targetCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.outfit(),
                              decoration: const InputDecoration(
                                labelText: 'Zielanzahl',
                              ),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n < 1) {
                                  return 'Mind. 1';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _incrementCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.outfit(),
                              decoration: const InputDecoration(
                                labelText: 'Pro Tipp',
                              ),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n < 1) {
                                  return 'Mind. 1';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel('Wiederholen'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            _RepeatTile(
                              title: 'Täglich',
                              subtitle: 'Jeden Tag neu zählen',
                              selected: _repeatType == RepeatType.daily,
                              onTap: () => setState(
                                () => _repeatType = RepeatType.daily,
                              ),
                            ),
                            _RepeatTile(
                              title: 'Alle X Tage',
                              subtitle: 'Eigenes Intervall',
                              selected: _repeatType == RepeatType.everyXDays,
                              onTap: () => setState(
                                () => _repeatType = RepeatType.everyXDays,
                              ),
                            ),
                            _RepeatTile(
                              title: 'Wöchentlich',
                              subtitle: 'Alle 7 Tage',
                              selected: _repeatType == RepeatType.weekly,
                              onTap: () => setState(
                                () => _repeatType = RepeatType.weekly,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_repeatType == RepeatType.everyXDays) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _intervalCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.outfit(),
                          decoration: const InputDecoration(
                            labelText: 'Alle wie viele Tage?',
                            suffixText: 'Tage',
                          ),
                          validator: (v) {
                            if (_repeatType != RepeatType.everyXDays) {
                              return null;
                            }
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1) return 'Mind. 1';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      _SectionLabel('Erinnerung'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Push-Erinnerung',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Benachrichtigung zur gewählten Zeit',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppColors.mist,
                                ),
                              ),
                              activeTrackColor:
                                  AppColors.gold.withValues(alpha: 0.45),
                              thumbColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppColors.gold;
                                }
                                return AppColors.mist;
                              }),
                              value: _reminderEnabled,
                              onChanged: (v) =>
                                  setState(() => _reminderEnabled = v),
                            ),
                            if (_reminderEnabled)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.schedule_rounded,
                                  color: AppColors.gold,
                                ),
                                title: Text(
                                  _reminderTime.format(context),
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Text(
                                  'Ändern',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.mint,
                                  ),
                                ),
                                onTap: _pickTime,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.deepNight,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isEdit ? 'Speichern' : 'Anlegen',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: AppColors.mist,
        ),
      ),
    );
  }
}

class _RepeatTile extends StatelessWidget {
  const _RepeatTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.mist),
      ),
      trailing: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: selected ? AppColors.gold : AppColors.mist,
      ),
    );
  }
}

class _QuickChips extends StatelessWidget {
  const _QuickChips({required this.onSelect});

  final ValueChanged<String> onSelect;

  static const _presets = [
    exampleZekrText,
    defaultSalamText,
    defaultTasbihZahraTitle,
    'سُبْحَانَ ٱللَّهِ',
    'ٱلْحَمْدُ لِلَّهِ',
    'ٱللَّهُ أَكْبَرُ',
    'لَا إِلَٰهَ إِلَّا ٱللَّهُ',
    'أَسْتَغْفِرُ ٱللَّهَ',
    'صَلَّى ٱللَّهُ عَلَيْهِ وَسَلَّمَ',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presets
          .map(
            (t) => ActionChip(
              label: Text(
                t,
                style: AppTheme.arabic(fontSize: 14, color: AppColors.cream),
                textDirection: TextDirection.rtl,
              ),
              backgroundColor: AppColors.card,
              side: const BorderSide(color: AppColors.cardBorder),
              onPressed: () => onSelect(t),
            ),
          )
          .toList(),
    );
  }
}
