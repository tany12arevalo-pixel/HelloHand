// lib/screens/menu_conversacion_rapida_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuConversacionRapidaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/elements/Background_1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(0),
            child: Column(
              children: [
                // Botón Volver al Inicio (arriba)
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Image.asset(
                      'assets/images/elements/boton_volver_al_inicio.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Contenido centrado
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botón Crear Conversación Rápida
                      GestureDetector(
                        onTap: () => context.go('/menu-crear-conversacion-rapida'),
                        child: Image.asset(
                          'assets/images/elements/menu conversacion rapdia/boton crear conversaison rapida.png',
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      SizedBox(height: 5),
                      
                      // Botón Unirse a Conversación Rápida
                      GestureDetector(
                        onTap: () => context.go('/menu-unirse-conversacion-rapida'),
                        child: Image.asset(
                          'assets/images/elements/menu conversacion rapdia/boton unirse a conversasion rapida.png',
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}