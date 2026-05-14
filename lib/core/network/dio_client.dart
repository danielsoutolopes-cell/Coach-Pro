import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/core/network/interceptors/rounding_interceptor.dart';

/// Provider do Riverpod que cria e expõe uma instância única (singleton) do Dio.
/// Widgets e outros providers poderão ler este provider para obter o cliente HTTP
/// já configurado.
final dioProvider = Provider<Dio>((ref) {
  // TODO: A URL base será lida dinamicamente do SharedPreferences.
  // Por agora, usaremos um placeholder.
  const baseUrl = 'https://sua-api.onrender.com/api/procoach';

  final options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  final dio = Dio(options);

  // Adicionando nosso interceptor customizado para a "Regra de Ouro".
  dio.interceptors.add(RoundingInterceptor());

  return dio;
});