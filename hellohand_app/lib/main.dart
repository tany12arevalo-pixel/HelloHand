import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'screens/test_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_conversacion_rapida_screen.dart';
import 'screens/menu_conversacion_grupal_screen.dart';
import 'services/api_service.dart';

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
      GoRoute(
        path: '/menu-conversacion-rapida',
        builder: (context, state) => MenuConversacionRapidaScreen(),
      ),
      GoRoute(
        path: '/menu-conversacion-grupal',
        builder: (context, state) => MenuConversacionGrupalScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ApiService(),
      child: MaterialApp.router(
        title: 'HelloHand',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}