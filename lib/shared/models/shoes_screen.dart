import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/features/inventory/providers/shoe_provider.dart';
import 'package:procoach_os/features/athlete/providers/athlete_provider.dart';
import 'package:procoach_os/shared/models/shoe.dart';

class ShoesScreen extends ConsumerWidget {
  const ShoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoesAsync = ref.watch(shoeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EQUIPAMENTOS (TÊNIS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
      ),
      body: shoesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.deepOrangeAccent)),
        error: (error, _) => Center(child: Text('Erro ao carregar tênis: $error', style: const TextStyle(color: Colors.redAccent))),
        data: (shoes) {
          final activeShoes = shoes.where((s) => s.isActive).toList();
          final archivedShoes = shoes.where((s) => !s.isActive).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(athleteProvider.future);
              await ref.refresh(shoeProvider.future);
            },
            color: Colors.deepOrangeAccent,
            backgroundColor: const Color(0xFF1A1A1A),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildGelCard(context, ref),
                const SizedBox(height: 24),
                _buildAddButton(context, ref),
                const SizedBox(height: 24),
                
                const Text('ATIVOS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                if (activeShoes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text('Nenhum tênis ativo no momento.', style: TextStyle(color: Colors.white70)),
                  )
                else
                  ...activeShoes.map((shoe) => _buildShoeCard(context, ref, shoe)),
                
                const SizedBox(height: 24),
                const Text('ARQUIVADOS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                if (archivedShoes.isEmpty)
                  const Text('Nenhum tênis aposentado.', style: TextStyle(color: Colors.white70))
                else
                  ...archivedShoes.map((shoe) => _buildShoeCard(context, ref, shoe)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGelCard(BuildContext context, WidgetRef ref) {
    final athleteAsync = ref.watch(athleteProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTOQUE DE GÉIS',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          athleteAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.deepOrangeAccent)),
            error: (error, _) => Text('Erro ao carregar: $error', style: const TextStyle(color: Colors.redAccent)),
            data: (athlete) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 24, color: Colors.deepOrangeAccent),
                      const SizedBox(width: 12),
                      Text(
                        '${athlete.gelInventory} unidades',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: athlete.gelInventory > 0 
                            ? () => ref.read(athleteProvider.notifier).updateGelInventory(athlete.gelInventory - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                      ),
                      IconButton(
                        onPressed: () => ref.read(athleteProvider.notifier).updateGelInventory(athlete.gelInventory + 1),
                        icon: const Icon(Icons.add_circle_outline, color: Colors.deepOrangeAccent),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddShoeModal(context, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white24)),
        ),
        icon: const Icon(Icons.add_circle_outline, color: Colors.deepOrangeAccent),
        label: const Text('+ TÊNIS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildShoeCard(BuildContext context, WidgetRef ref, Shoe shoe) {
    final double progress = shoe.targetKm > 0 ? (shoe.currentKm / shoe.targetKm).clamp(0.0, 1.0) : 0;
    final isCritical = progress >= 0.9;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shoe.isActive ? Colors.white10 : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shoe.nickname, style: TextStyle(color: shoe.isActive ? Colors.white : Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (shoe.brandModel != null && shoe.brandModel!.isNotEmpty)
                      Text(shoe.brandModel!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (shoe.isActive)
                TextButton(
                  onPressed: () => ref.read(shoeProvider.notifier).retireShoe(shoe.id),
                  child: const Text('APOSENTAR', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${shoe.currentKm.toStringAsFixed(1)} km', style: TextStyle(color: isCritical && shoe.isActive ? Colors.redAccent : Colors.deepOrangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Meta: ${shoe.targetKm.toStringAsFixed(0)} km', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black,
              color: isCritical && shoe.isActive ? Colors.redAccent : (shoe.isActive ? Colors.deepOrangeAccent : Colors.grey),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddShoeModal(BuildContext context, WidgetRef ref) {
    final nicknameController = TextEditingController();
    final brandController = TextEditingController();
    final initialKmController = TextEditingController(text: '0');
    final targetKmController = TextEditingController(text: '500');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CADASTRAR TÊNIS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(controller: nicknameController, decoration: const InputDecoration(labelText: 'Apelido (obrigatório)', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Marca/Modelo (opcional)', labelStyle: TextStyle(color: Colors.grey)), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextField(controller: initialKmController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'KM Inicial'), style: const TextStyle(color: Colors.white))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: targetKmController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Meta (KM)'), style: const TextStyle(color: Colors.white))),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (nicknameController.text.trim().isEmpty) return;
                    
                    try {
                      await ref.read(shoeProvider.notifier).addShoe({
                        'nickname': nicknameController.text.trim(),
                        'brand': brandController.text.trim(),
                        'initialKm': double.tryParse(initialKmController.text) ?? 0.0,
                        'targetKm': double.tryParse(targetKmController.text) ?? 500.0,
                      });
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha: $e', style: const TextStyle(color: Colors.white))));
                      }
                    }
                  },
                  child: const Text('SALVAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}