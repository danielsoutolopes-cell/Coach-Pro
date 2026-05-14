import 'package:dio/dio.dart';

/// Este interceptor aplica a "Regra de Ouro": toda telemetria de distância
/// é arredondada para o inteiro mais próximo antes de chegar à camada de parsing.
class RoundingInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      _roundValues(data);
    } else if (data is List) {
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          _roundValues(item);
        }
      }
    }

    super.onResponse(response, handler);
  }

  void _roundValues(Map<String, dynamic> json) {
    // Procura pela chave 'distancia_km' em qualquer nível do JSON.
    if (json.containsKey('distancia_km') && json['distancia_km'] is num) {
      json['distancia_km'] = (json['distancia_km'] as num).round();
    }

    // Itera recursivamente para encontrar a chave em objetos aninhados.
    for (var value in json.values) {
      if (value is Map<String, dynamic>) _roundValues(value);
    }
  }
}