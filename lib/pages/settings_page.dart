import 'package:flutter/material.dart';

import 'category_page.dart';

/// Pengaturan sederhana: tentang aplikasi, kelola kategori, versi.
class SettingsPage extends StatelessWidget {
  final VoidCallback? onDataChanged;

  const SettingsPage({super.key, this.onDataChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Pengaturan'),
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
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tentang NARATA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'NARATA adalah aplikasi blog sederhana untuk membuat, '
                          'membaca, mengubah, dan menghapus artikel beserta kategorinya.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: const Text('Kelola Kategori'),
                        subtitle:
                            const Text('Tambah, ubah, dan hapus kategori'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoryPage(),
                            ),
                          );
                          onDataChanged?.call();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Aplikasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Nama: NARATA Blog'),
                        SizedBox(height: 4),
                        Text('Versi: 1.0.0'),
                        SizedBox(height: 4),
                        Text('Backend: http://localhost:8000'),
                      ],
                    ),
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
