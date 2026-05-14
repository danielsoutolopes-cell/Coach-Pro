import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/core/network/dio_client.dart';
import 'package:procoach_os/shared/models/shoe.dart';

final shoeServiceProvider = Provider<ShoeService>((ref) {
  final dio = ref.watch(dioProvider);
  return ShoeService(dio);
});

/// Serviço dedicado à gestão de equipamentos (Tênis).
class ShoeService {
  final Dio _dio;

  ShoeService(this._dio);

  /// Retorna a lista de tênis ativos do atleta.
  Future<List<Shoe>> getAthleteShoes(String athleteId) async {
    // Altere a rota de acordo com a configuração do seu backend Node.js
    final response = await _dio.get('/athletes/$athleteId/shoes');
    final List<dynamic> data = response.data;
    return data.map((json) => Shoe.fromJson(json)).toList();
  }
}