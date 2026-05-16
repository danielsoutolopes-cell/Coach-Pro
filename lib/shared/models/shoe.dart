class Shoe {
  final String id;
  final String nickname;
  final String? brandModel;
  final double initialKm;
  final double currentKm;
  final double targetKm;
  final bool isActive;

  Shoe({
    required this.id,
    required this.nickname,
    this.brandModel,
    this.initialKm = 0.0,
    this.currentKm = 0.0,
    this.targetKm = 500.0,
    this.isActive = true,
  });

  Shoe copyWith({
    String? id,
    String? nickname,
    String? brandModel,
    double? initialKm,
    double? currentKm,
    double? targetKm,
    bool? isActive,
  }) {
    return Shoe(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      brandModel: brandModel ?? this.brandModel,
      initialKm: initialKm ?? this.initialKm,
      currentKm: currentKm ?? this.currentKm,
      targetKm: targetKm ?? this.targetKm,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Shoe.fromJson(Map<String, dynamic> json) {
    return Shoe(
      id: json['id'] ?? '',
      nickname: json['nickname'] ?? '',
      brandModel: json['brandModel'],
      initialKm: (json['initialKm'] as num?)?.toDouble() ?? 0.0,
      currentKm: (json['currentKm'] as num?)?.toDouble() ?? 0.0,
      targetKm: (json['targetKm'] as num?)?.toDouble() ?? 500.0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'brandModel': brandModel,
      'initialKm': initialKm,
      'currentKm': currentKm,
      'targetKm': targetKm,
      'isActive': isActive,
    };
  }
}