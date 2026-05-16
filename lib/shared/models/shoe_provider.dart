import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/features/equipment/services/shoe_service.dart';
import 'package:procoach_os/shared/models/shoe.dart';

final shoeProvider = AsyncNotifierProvider<ShoeNotifier, List<Shoe>>(() {
  return ShoeNotifier();
});

class ShoeNotifier extends AsyncNotifier<List<Shoe>> {
  @override
  FutureOr<List<Shoe>> build() async {
    return await ref.watch(shoeServiceProvider).getShoes();
  }

  Future<void> addShoe(Map<String, dynamic> shoeData) async {
    await ref.read(shoeServiceProvider).addShoe(shoeData);
    ref.invalidateSelf(); // Recarrega a lista do backend
  }

  Future<void> retireShoe(String shoeId) async {
    await ref.read(shoeServiceProvider).retireShoe(shoeId);
    ref.invalidateSelf(); // Recarrega a lista do backend
  }
}