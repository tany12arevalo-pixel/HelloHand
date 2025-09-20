import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
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
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título - Ajusta height para cambiar tamaño
                Image.asset(
                  'assets/images/elements/home_screen/Titulo.png',
                  height: 100, // Cambia este valor para ajustar tamaño del título
                ),
                
                SizedBox(height: 20), // Espacio entre título y primer botón
                
                // Botón Conversación Rápida - Ajusta height para cambiar tamaño
                GestureDetector(
                  onTap: () => context.go('/menu-conversacion-rapida'),
                  child: Image.asset(
                    'assets/images/elements/home_screen/boton_conversacion_rapida.png',
                    width: double.infinity, // Ancho completo
                    height: 250, // Cambia este valor para ajustar tamaño del botón
                    fit: BoxFit.contain, // Mantiene proporciones
                  ),
                ),
                
                SizedBox(height: 5), // Espacio entre botones
                
                // Botón Conversación Grupal - Ajusta height para cambiar tamaño
                GestureDetector(
                  onTap: () => context.go('/menu-conversacion-grupal'),
                  child: Image.asset(
                    'assets/images/elements/home_screen/boton_conversacion_grupal.png',
                    width: double.infinity, // Ancho completo
                    height: 250, // Cambia este valor para ajustar tamaño del botón
                    fit: BoxFit.contain, // Mantiene proporciones
                  ),
                ),
                
                SizedBox(height: 10), // Espacio antes del botón test
                
                // Botón Test (más pequeño, mantenemos el estilo original)
                SizedBox(
                  width: 120,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => context.go('/test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Test',
                      style: TextStyle(fontSize: 14),
                    ),
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