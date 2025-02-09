import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantalla Principal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Ir a Grabación'),
              onPressed: () {
                Navigator.pushNamed(context, '/record');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Ver videos guardados'),
              onPressed: () {
                // Navega a la lista de videos
                Navigator.pushNamed(context, '/videos');
              },
            ),
          ],
        ),
      ),
    );
  }
}
