import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/shared/widgets/procoach_button.dart';
import 'package:procoach_os/features/dashboard/providers/workout_provider.dart';

class WorkoutCard extends ConsumerWidget {
  const WorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TREINO DO DIA',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.directions_run, color: Colors.deepOrangeAccent, size: 28),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Corrida (Leve)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('🎯 Pace: 6:00 min/km  •  📏 8km', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Componente partilhado que criámos na Fase 4!
          ProCoachButton(
            label: 'CONCLUIR TREINO',
            onPressed: () {
              // TODO: Acionar o fluxo de Debrief (Géis + RPE + Dor)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Treino concluído! Abrindo Debrief...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}