import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/features/status/services/strength_service.dart';
import 'package:procoach_os/shared/models/strength_routine.dart';

final strengthRoutinesProvider = AsyncNotifierProvider<StrengthRoutinesNotifier, List<StrengthRoutine>>(() {
  return StrengthRoutinesNotifier();
});

class StrengthRoutinesNotifier extends AsyncNotifier<List<StrengthRoutine>> {
  @override
  FutureOr<List<StrengthRoutine>> build() async {
    final service = ref.watch(strengthServiceProvider);
    return await service.getStrengthRoutines();
  }

  Future<void> saveRoutine(StrengthRoutine routine) async {
    final service = ref.read(strengthServiceProvider);
    final previousState = state;

    // Atualização Otimista: Muda a UI imediatamente (UX muito rápida)
    if (state.value != null) {
      final updatedList = List<StrengthRoutine>.from(state.value!);
      final index = updatedList.indexWhere((r) => r.routineType == routine.routineType);
      
      if (index != -1) {
        updatedList[index] = routine;
      } else {
        updatedList.add(routine);
      }
      state = AsyncData(updatedList);
    }

    try {
      await service.saveStrengthRoutine(routine);
    } catch (e) {
      state = previousState; // Rollback em caso de erro de rede
      rethrow;
    }
  }
}