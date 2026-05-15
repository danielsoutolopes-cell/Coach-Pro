class PlanSession {
  final String date;
  final String activity;
  final String? paceTarget;
  final String? structure;
  final num? plannedKm;

  PlanSession({
    required this.date,
    required this.activity,
    this.paceTarget,
    this.structure,
    this.plannedKm,
  });

  factory PlanSession.fromJson(Map<String, dynamic> json) {
    return PlanSession(
      date: json['session_date'] ?? '',
      activity: json['activity'] ?? '',
      paceTarget: json['pace_target'],
      structure: json['structure'],
      plannedKm: json['planned_km'],
    );
  }
}