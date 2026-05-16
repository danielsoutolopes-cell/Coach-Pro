import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/core/network/dio_client.dart';
import 'package:procoach_os/shared/models/shoe.dart';

class ShoeService {
  final Dio _dio;

  ShoeService(this._dio);

  Future<List<Shoe>> getAthleteShoes() async {
    final response = await _dio.get('/athletes/me/shoes');
    final data = response.data as List<dynamic>;
    return data.map((e) => Shoe.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Shoe> addShoe(Map<String, dynamic> shoeData) async {
    final response = await _dio.post('/athletes/me/shoes', data: shoeData);
    return Shoe.fromJson(response.data);
  }

  Future<void> retireShoe(String shoeId) async {
    await _dio.patch('/athletes/me/shoes/$shoeId/retire');
  }
}

final shoeServiceProvider = Provider<ShoeService>((ref) {
  return ShoeService(ref.watch(dioProvider));
});