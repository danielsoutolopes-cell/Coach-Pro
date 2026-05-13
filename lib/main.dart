import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procoach_os/core/router/app_router.dart';

void main() {
  // O ProviderScope é o coração do Riverpod. Ele envolve o app inteiro 
  // para que os nossos Providers (como o athleteProvider) funcionem globalmente.
  runApp(
    const ProviderScope(
      child: ProCoachApp(),
    ),
  );
}

class ProCoachApp extends ConsumerWidget {
  const ProCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'ProCoach OS V6.1',
      debugShowCheckedModeBanner: false,
      // Tema sombrio oficial do ProCoach OS (Input-Light / Visual-First)
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: Colors.deepOrangeAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepOrangeAccent,
          secondary: Colors.blueAccent,
        ),
      ),
      // Liga o Flutter ao GoRouter
      routerConfig: goRouter,
    );
  }
}