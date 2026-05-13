import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:procoach_os/features/athlete/providers/athlete_provider.dart';
import 'package:procoach_os/features/dashboard/widgets/weather_card.dart';
import 'package:procoach_os/features/dashboard/widgets/workout_card.dart';
import 'package:procoach_os/shared/models/athlete.dart';
import 'package:procoach_os/shared/widgets/async_value_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // O Riverpod "escuta" o estado do atleta. 
    // Se a API estiver a carregar, o AsyncValueWidget trata disso!
    final athleteAsync = ref.watch(athleteProvider);
    final today = DateFormat("dd 'de' MMMM", 'pt_BR').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Fundo escuro ProCoach
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          'PROCOACH OS V6.1',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: AsyncValueWidget<Athlete>(
        value: athleteAsync,
        data: (athlete) {
          // Calcula os dias para a prova âncora
          final anchorRace = athlete.races.where((r) => r.isAnchor).firstOrNull;
          final daysToRace = anchorRace != null 
              ? anchorRace.date.difference(DateTime.now()).inDays 
              : 0;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(athleteProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Cabeçalho de Data e Prova
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      today.toUpperCase(),
                      style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (anchorRace != null)
                      Text(
                        '$daysToRace DIAS P/ PROVA',
                        style: const TextStyle(color: Colors.deepOrangeAccent, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Previsão de Hoje
                const WeatherCard(),
                const SizedBox(height: 16),
                
                // Treino do Dia
                const WorkoutCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}