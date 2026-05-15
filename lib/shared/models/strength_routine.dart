class StrengthExercise {
  final String name;
  final int sets;
  final String reps;
  final String? weight;
  final int? rpe;
  final String? tempo;
  final String? rest;
  final String? notes;

  StrengthExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    this.rpe,
    this.tempo,
    this.rest,
    this.notes,
  });

  // Converte o objeto Dart para o JSON que a API espera
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      if (weight != null) 'weight': weight,
      if (rpe != null) 'rpe': rpe,
      if (tempo != null) 'tempo': tempo,
      if (rest != null) 'rest': rest,
      if (notes != null) 'notes': notes,
    };
  }

  // Cria o objeto Dart a partir do JSON do banco de dados
  factory StrengthExercise.fromJson(Map<String, dynamic> json) {
    return StrengthExercise(
      name: json['name'] ?? '',
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? '',
      weight: json['weight'],
      rpe: json['rpe'],
      tempo: json['tempo'],
      rest: json['rest'],
      notes: json['notes'],
    );
  }
}

class StrengthRoutine {
  final String routineType; // 'A', 'B' ou 'C'
  final String name;
  final List<StrengthExercise> exercises;

  StrengthRoutine({
    required this.routineType,
    required this.name,
    required this.exercises,
  });

  factory StrengthRoutine.fromJson(Map<String, dynamic> json) {
    return StrengthRoutine(
      routineType: json['routine_type'] ?? json['routineType'] ?? '',
      name: json['name'] ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => StrengthExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routineType': routineType,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}