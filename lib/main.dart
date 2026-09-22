import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Percobaan LayoutBuilder'),
        ),
        body: Column(
          children: [
            Container(
              width: 500,
              height: 400,
              color: Colors.blue,
              alignment: Alignment.topLeft,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth * 0.6,
                    height: 100,
                    color: Colors.amber,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

