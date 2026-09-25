import 'package:flutter/material.dart';

/// Halaman profil sederhana tanpa autentikasi.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profil'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 600;
          double horizontalPadding = 16;
          if (isDesktop) {
            horizontalPadding = (constraints.maxWidth - 700) / 2;
            if (horizontalPadding < 16) horizontalPadding = 16;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_outline,
                    size: 44,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pengguna NARATA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Halaman profil ini merupakan bagian dari aplikasi NARATA '
                  'untuk identitas pengguna lokal tanpa autentikasi.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1,
                  child: const Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.article_outlined),
                        title: Text('Penulis & Pembaca'),
                        subtitle: Text('Mengelola artikel blog'),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.devices_outlined),
                        title: Text('Perangkat ini'),
                        subtitle: Text('Data tersimpan di server lokal'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
