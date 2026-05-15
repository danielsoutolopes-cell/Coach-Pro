import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/shared/models/plan_service.dart';
import 'package:procoach_os/shared/models/plan_session.dart';

final planSessionsProvider = AsyncNotifierProvider<PlanSessionsNotifier, List<PlanSession>>(() {
  return PlanSessionsNotifier();
});

class PlanSessionsNotifier extends AsyncNotifier<List<PlanSession>> {
  @override
  FutureOr<List<PlanSession>> build() async {
    final service = ref.watch(planServiceProvider);
    return await service.getPlanSessions();
  }
}