import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/core/network/dio_client.dart';
import 'package:procoach_os/shared/models/strength_routine.dart';

class StrengthService {
  final Dio _dio;

  StrengthService(this._dio);

  Future<List<StrengthRoutine>> getStrengthRoutines() async {
    try {
      final response = await _dio.get('/athletes/me/strength-routines');
      if (response.data == null) return [];
      final data = response.data as List<dynamic>;
      return data.map((e) => StrengthRoutine.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar fichas de força: $e');
    }
  }

  Future<void> saveStrengthRoutine(StrengthRoutine routine) async {
    try {
      await _dio.post(
        '/athletes/me/strength-routines', // Uso no plural mantendo a padronização REST
        data: routine.toJson(),
      );
    } catch (e) {
      throw Exception('Erro ao salvar ficha de força: $e');
    }
  }
}

final strengthServiceProvider = Provider<StrengthService>((ref) {
  return StrengthService(ref.watch(dioProvider));
});