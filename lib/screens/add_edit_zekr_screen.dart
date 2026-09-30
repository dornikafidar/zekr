import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/default_zekrs.dart';
import '../models/zekr.dart';
import '../providers/zekr_provider.dart';
import '../l10n/fa.dart';
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
    _incrementCtrl = TextEditingController(text: '${e?.incrementPerTap ?? 1}');
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
                        _isEdit ? Fa.editZekr : Fa.newZekr,
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
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _SectionLabel('متن'),
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
                            return Fa.enterText;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      _QuickChips(
                        onSelect: (t) => setState(() => _textCtrl.text = t),
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(Fa.noteOptional),
                      TextFormField(
                        controller: _noteCtrl,
                        style: AppTheme.latin(),
                        decoration: const InputDecoration(
                          hintText: Fa.noteHint,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(Fa.goalAndTap),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _targetCtrl,
                              keyboardType: TextInputType.number,
                              style: AppTheme.latin(),
                              decoration: const InputDecoration(
                                labelText: Fa.targetCount,
                              ),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n < 1) {
                                  return Fa.minOne;
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
                              style: AppTheme.latin(),
                              decoration: const InputDecoration(
                                labelText: Fa.perTap,
                              ),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n < 1) {
                                  return Fa.minOne;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(Fa.repeat),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            _RepeatTile(
                              title: Fa.daily,
                              subtitle: Fa.dailySub,
                              selected: _repeatType == RepeatType.daily,
                              onTap: () => setState(
                                () => _repeatType = RepeatType.daily,
                              ),
                            ),
                            _RepeatTile(
                              title: Fa.everyXDays,
                              subtitle: Fa.everyXDaysSub,
                              selected: _repeatType == RepeatType.everyXDays,
                              onTap: () => setState(
                                () => _repeatType = RepeatType.everyXDays,
                              ),
                            ),
                            _RepeatTile(
                              title: Fa.weekly,
                              subtitle: Fa.weeklySub,
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
                          style: AppTheme.latin(),
                          decoration: const InputDecoration(
                            labelText: Fa.everyHowManyDays,
                            suffixText: Fa.days,
                          ),
                          validator: (v) {
                            if (_repeatType != RepeatType.everyXDays) {
                              return null;
                            }
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1) return Fa.minOne;
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      _SectionLabel(Fa.reminder),
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
                                Fa.pushReminder,
                                style: AppTheme.latin(
                                  weight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                Fa.pushReminderSub,
                                style: AppTheme.latin(
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
                                  style: AppTheme.latin(
                                    fontSize: 20,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Text(
                                  Fa.change,
                                  style: AppTheme.latin(
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
                          _isEdit ? Fa.save : Fa.create,
                          style: AppTheme.latin(
                            fontSize: 16,
                            weight: FontWeight.w700,
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
        style: AppTheme.latin(
          fontSize: 12,
          weight: FontWeight.w600,
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
        style: AppTheme.latin(weight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.latin(fontSize: 12, color: AppColors.mist),
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
