import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuConversacionRapidaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversación Rápida'),
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: Text(
          'Próximamente',
          style: TextStyle(
            fontSize: 24,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}