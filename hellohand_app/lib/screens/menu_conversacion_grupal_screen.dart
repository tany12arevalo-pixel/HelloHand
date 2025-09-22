import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuConversacionGrupalScreen extends StatelessWidget {
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
                      // Botón Crear Conversación en Grupo
                      GestureDetector(
                        onTap: () => context.go('/menu-crear-conversacion-grupal'),
                        child: Image.asset(
                          'assets/images/elements/Menu conversacion grupal/boton_crear_conversacion_en_grupo.png',
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      SizedBox(height: 0),
                      
                      // Botón Unirse a Conversación en Grupo
                      GestureDetector(
                        // Cambiar este onTap:
                        onTap: () => context.go('/menu-unirse-conversacion-grupal'),
                        child: Image.asset(
                          'assets/images/elements/Menu conversacion grupal/uneta_a_una_conversacion_del_grupo.png',
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