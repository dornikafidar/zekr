import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/situation_dhikrs.dart';
import '../l10n/fa.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'counter_screen.dart';

class SituationsScreen extends StatelessWidget {
  const SituationsScreen({super.key});

  IconData _icon(String key) => switch (key) {
        'shield' => Icons.shield_outlined,
        'heart' => Icons.favorite_border_rounded,
        'visibility' => Icons.visibility_outlined,
        _ => Icons.spa_outlined,
      };

  Future<void> _open(BuildContext context, SituationDhikr sit) async {
    final provider = context.read<ZekrProvider>();
    var zekr = provider.byId(sit.id);
    if (zekr == null) {
      await provider.init();
      zekr = provider.byId(sit.id);
    }
    if (zekr == null || !context.mounted) return;

    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CounterScreen(zekrId: sit.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        Fa.situations,
                        textAlign: TextAlign.center,
                        style: AppTheme.latin(
                          fontSize: 18,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Column(
                  children: [
                    Text(
                      Fa.situationsTitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.latin(
                        fontSize: 15,
                        weight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Fa.situationsHint,
                      textAlign: TextAlign.center,
                      style: AppTheme.latin(
                        fontSize: 13,
                        color: AppColors.mist,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  itemCount: situationDhikrs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final sit = situationDhikrs[i];
                    return GlassCard(
                      accent: true,
                      onTap: () => _open(context, sit),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Icon(
                                  _icon(sit.icon),
                                  color: AppColors.gold,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sit.title,
                                      style: AppTheme.latin(
                                        fontSize: 16,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      sit.hint,
                                      style: AppTheme.latin(
                                        fontSize: 12,
                                        color: AppColors.mist,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusPill(
                                label: Fa.sayNow,
                                color: AppColors.mint,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            sit.text,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: AppTheme.arabic(
                              fontSize: 22,
                              color: AppColors.cream,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
