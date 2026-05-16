import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/features/inventory/services/shoe_service.dart';
import 'package:procoach_os/shared/models/shoe.dart';

final shoeProvider = AsyncNotifierProvider<ShoeNotifier, List<Shoe>>(() {
  return ShoeNotifier();
});

class ShoeNotifier extends AsyncNotifier<List<Shoe>> {
  @override
  FutureOr<List<Shoe>> build() async {
    final shoeService = ref.watch(shoeServiceProvider);
    return await shoeService.getAthleteShoes();
  }

  /// Adiciona KM a um tênis localmente para resposta instantânea da UI
  void addKmToShoeOptimistically(String shoeId, double addedDistance) {
    final currentShoes = state.value;
    if (currentShoes == null) return;
    
    final updatedList = currentShoes.map((shoe) {
      if (shoe.id == shoeId) {
        return shoe.copyWith(currentKm: shoe.currentKm + addedDistance);
      }
      return shoe;
    }).toList();
    
    state = AsyncData(updatedList);
  }

  /// Aposenta o tênis (Atualização Otimista)
  Future<void> retireShoe(String shoeId) async {
    final currentShoes = state.value;
    if (currentShoes == null) return;

    final previousState = state;

    // 1. Atualiza a UI imediatamente
    final updatedList = currentShoes.map((shoe) {
      if (shoe.id == shoeId) {
        return shoe.copyWith(isActive: false);
      }
      return shoe;
    }).toList();
    state = AsyncData(updatedList);

    try {
      // 2. Tenta fazer a alteração via API
      final shoeService = ref.read(shoeServiceProvider);
      await shoeService.retireShoe(shoeId);
    } catch (e) {
      // 3. Reverte se houver erro (Rollback)
      state = previousState;
      throw Exception('Erro ao aposentar tênis: $e');
    }
  }

  /// Adiciona um novo tênis à lista
  Future<void> addShoe(Map<String, dynamic> shoeData) async {
    final currentShoes = state.value ?? [];
    
    try {
      final shoeService = ref.read(shoeServiceProvider);
      final newShoe = await shoeService.addShoe(shoeData);
      
      // Adiciona o tênis recém-retornado pela API na lista atual de forma reativa
      state = AsyncData([...currentShoes, newShoe]);
    } catch (e) {
      throw Exception('Erro ao cadastrar tênis: $e');
    }
  }
}