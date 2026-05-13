import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/features/dashboard/services/workout_service.dart';
import 'package:procoach_os/shared/models/workout.dart';

final workoutProvider = AsyncNotifierProvider<WorkoutNotifier, Workout?>(() {
  return WorkoutNotifier();
});

class WorkoutNotifier extends AsyncNotifier<Workout?> {
  @override
  FutureOr<Workout?> build() async {
    final workoutService = ref.watch(workoutServiceProvider);
    const monoAthleteId = '1'; // App mono-usuário
    return await workoutService.getTodayWorkout(monoAthleteId);
  }
}