import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/core/network/dio_client.dart';
import 'package:procoach_os/shared/models/shoe.dart';

final shoeServiceProvider = Provider<ShoeService>((ref) {
  return ShoeService(ref.watch(dioProvider));
});

class ShoeService {
  final Dio _dio;
  ShoeService(this._dio);

  Future<List<Shoe>> getShoes() async {
    final response = await _dio.get('/athletes/me/shoes');
    final data = response.data as List;
    return data.map((e) => Shoe.fromJson(e)).toList();
  }

  Future<void> addShoe(Map<String, dynamic> shoeData) async {
    await _dio.post('/athletes/me/shoes', data: shoeData);
  }

  Future<void> retireShoe(String shoeId) async {
    // Rota que inativa o tênis (Aposentar)
    await _dio.patch('/athletes/me/shoes/$shoeId/retire');
  }
}