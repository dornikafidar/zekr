import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ziarat_places.dart';
import '../l10n/fa.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'ziarat_detail_screen.dart';

class ZiaratPlacesScreen extends StatelessWidget {
  const ZiaratPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNight,
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    BackCircleButton(onPressed: () => Navigator.pop(context)),
                    Expanded(
                      child: Text(
                        Fa.ziaratPlaces,
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  Fa.ziaratPlacesHint,
                  textAlign: TextAlign.center,
                  style: AppTheme.latin(fontSize: 12, color: AppColors.mist),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                  itemCount: ziaratPlaces.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = ziaratPlaces[i];
                    return Material(
                      color: AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ZiaratDetailScreen(place: p),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.gold.withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.mosque_rounded,
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
                                      p.nameFa,
                                      style: AppTheme.latin(
                                        fontSize: 17,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${p.cityFa} · ${p.subtitle}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.latin(
                                        fontSize: 12,
                                        color: AppColors.mist,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${p.ziarat.length}',
                                style: AppTheme.latin(
                                  fontSize: 12,
                                  color: AppColors.gold,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: AppColors.mist,
                                size: 15,
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ),
                        ),
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
