import 'package:flutter/material.dart';

class RoomScreen extends StatelessWidget {
  final String roomId;

  const RoomScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a0828),
              Color(0xFF2d1b69),
              Color(0xFF1a0828),
            ],
          ),
        ),
        child: Center(
          child: Text(
            'Room Screen - Sala: $roomId',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}