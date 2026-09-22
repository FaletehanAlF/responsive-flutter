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
        body: LayoutBuilder(
          builder: (context, constraint) {
            if (constraint.maxWidth < 600) {
              // Mobile
              return Column(
                children: [
                  Container(
                    height: 100,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 100),
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.blue,
                  ),
                ],
              );
            }

            // Desktop / Web
            return Row(
              children: [
                Container(
                  width: 200,
                  height: 300,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 20),
                Container(
                  width: 300,
                  height: 300,
                  color: Colors.blue,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
