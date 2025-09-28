// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'screens/test_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_conversacion_rapida_screen.dart';
import 'screens/menu_conversacion_grupal_screen.dart';
import 'screens/menu_crear_conversacion_grupal_screen.dart';
import 'screens/menu_unirse_conversacion_grupal_screen.dart';
import 'screens/menu_crear_conversacion_rapida_screen.dart';
import 'screens/menu_unirse_conversacion_rapida_screen.dart'; 
import 'screens/conversacion_grupal_screen.dart';
import 'screens/conversacion_rapida_screen.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GoRouter _router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => HomeScreen(),
      ),
      GoRoute(
        path: '/test',
        builder: (context, state) => TestScreen(),
      ),
      
      // RUTAS CONVERSACIÓN RÁPIDA
      GoRoute(
        path: '/menu-conversacion-rapida',
        builder: (context, state) => MenuConversacionRapidaScreen(),
      ),
      GoRoute(
        path: '/menu-crear-conversacion-rapida',
        builder: (context, state) => MenuCrearConversacionRapidaScreen(),
      ),
      GoRoute(
        path: '/menu-unirse-conversacion-rapida',
        builder: (context, state) => MenuUnirseConversacionRapidaScreen(),
      ),
      // RUTAS CONVERSACIÓN GRUPAL
      GoRoute(
        path: '/menu-conversacion-grupal',
        builder: (context, state) => MenuConversacionGrupalScreen(),
      ),
      GoRoute(
        path: '/menu-crear-conversacion-grupal',
        builder: (context, state) => MenuCrearConversacionGrupalScreen(),
      ),
      GoRoute(
        path: '/menu-unirse-conversacion-grupal',
        builder: (context, state) => MenuUnirseConversacionGrupalScreen(),
      ),
      GoRoute(
        path: '/conversacion-rapida/:roomId',
        builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        final name = state.uri.queryParameters['name'] ?? '';
        final participantId = state.uri.queryParameters['participantId'];
        final isCreator = state.uri.queryParameters['isCreator'] == 'true';
    
          return ConversacionRapidaScreen(
          roomId: roomId,
          participantName: name,
          participantId: participantId,
          isCreator: isCreator,
        );
      },
    ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // API Service para llamadas REST
        ChangeNotifierProvider(
          create: (context) => ApiService(),
        ),
        // WebSocket Service para comunicación en tiempo real
        ChangeNotifierProvider(
          create: (context) => WebSocketService(),
        ),
      ],
      child: MaterialApp.router(
        title: 'HelloHand',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          useMaterial3: true,
        ),
        routerConfig: _router,
        // Remover banner de debug en release
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}