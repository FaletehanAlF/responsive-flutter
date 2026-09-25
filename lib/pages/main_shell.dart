import 'package:flutter/material.dart';

import 'add_post_page.dart';
import 'articles_page.dart';
import 'home_page.dart';
import 'settings_page.dart';

/// Navigasi utama NARATA: Home | Articles | Add | Settings.
/// Menggunakan IndexedStack agar state tiap tab tidak hilang saat berpindah.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Bertambah setiap kali ada perubahan data (tambah/edit/hapus/kategori).
  /// Diteruskan ke Home & Articles agar mereka reload tanpa F5.
  int _dataVersion = 0;

  void _notifyDataChanged() {
    setState(() {
      _dataVersion++;
    });
  }

  void _handleAddSaved() {
    _notifyDataChanged();
    setState(() {
      _index = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Artikel berhasil ditambahkan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(refreshSignal: _dataVersion),
          ArticlesPage(refreshSignal: _dataVersion),
          AddPostPage(onSaved: _handleAddSaved),
          SettingsPage(onDataChanged: _notifyDataChanged),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Articles',
          ),
          NavigationDestination(
            icon: Icon(Icons.add),
            selectedIcon: Icon(Icons.add),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
