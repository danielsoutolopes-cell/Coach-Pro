import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:procoach_os/shared/models/athlete.dart';
import 'package:procoach_os/shared/widgets/procoach_button.dart';
import 'package:procoach_os/features/dashboard/providers/race_strategy_provider.dart';

class RaceDayCard extends ConsumerWidget {
  final dynamic race;
  final int daysToRace;
  final int currentWeek;
  final bool isRaceDayMode;

  const RaceDayCard({
    super.key, 
    required this.race, 
    required this.daysToRace,
    required this.currentWeek,
    required this.isRaceDayMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategyAsync = ref.watch(raceStrategyProvider);
    final double progress = currentWeek / 16.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRaceDayMode 
            ? Colors.deepOrangeAccent.withOpacity(0.1) // Fundo avermelhado no dia da prova
            : const Color(0xFF1A1A1A), // Fundo escuro normal
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRaceDayMode ? Colors.deepOrangeAccent : Colors.white10,
          width: isRaceDayMode ? 2 : 1,
        ),
        boxShadow: isRaceDayMode ? [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRaceDayMode ? '🔥 RACE DAY MODE' : 'MACROCICLO (16 SEMANAS)',
                style: TextStyle(
                  color: isRaceDayMode ? Colors.deepOrangeAccent : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Semana $currentWeek',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            race.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRaceDayMode 
              ? 'Faltam apenas $daysToRace dias! Prepare os seus equipamentos.' 
              : 'Foco no processo. Faltam $daysToRace dias para o grande dia.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black,
              color: Colors.deepOrangeAccent,
              minHeight: 8,
            ),
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isRaceDayMode ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text('✅ CHECKLIST DE LOGÍSTICA', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildChecklistItem('Carb-load focado (Refeições ricas em massas)'),
                _buildChecklistItem('Equipamento separado (Tênis oficial de placa)'),
                _buildChecklistItem('Géis conferidos e alarmes ajustados'),
                const SizedBox(height: 24),
                
                strategyAsync.when(
                  data: (strategy) {
                    if (strategy == null) {
                      return ProCoachButton(
                        label: 'GERAR ESTRATÉGIA (IA)',
                        isPrimary: false,
                        onPressed: () => ref.read(raceStrategyProvider.notifier).generateStrategy(race.name),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🧠 ESTRATÉGIA DO CÉREBRO', style: TextStyle(color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(strategy, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  error: (e, _) => const Text('Erro ao contactar o Cérebro.', style: TextStyle(color: Colors.yellow)),
                )
              ],
            ) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.deepOrangeAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }
}
