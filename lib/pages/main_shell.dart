import 'package:flutter/material.dart';

import 'add_post_page.dart';
import 'articles_page.dart';
import 'detail_page.dart';
import 'home_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _dataVersion = 0;
  int? _detailPostId;

  void _notifyDataChanged() {
    setState(() => _dataVersion++);
  }

  void _handleAddSaved() {
    setState(() {
      _dataVersion++;
      _index = 0;
      _detailPostId = null;
    });
    _showMessage('Artikel berhasil ditambahkan');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _select(int value) {
    setState(() {
      _index = value;
      _detailPostId = null;
    });
  }

  void _openDetail(int id) {
    setState(() => _detailPostId = id);
  }

  void _closeDetail(bool changed) {
    if (_detailPostId == null) return;
    setState(() {
      _detailPostId = null;
      if (changed) _dataVersion++;
    });
  }

  Widget _buildBody() {
    final detailId = _detailPostId;
    if (detailId != null) {
      return DetailPage(
        key: ValueKey(detailId),
        postId: detailId,
        onClose: _closeDetail,
      );
    }

    return IndexedStack(
      index: _index,
      children: [
        HomePage(refreshSignal: _dataVersion, onOpenDetail: _openDetail),
        ArticlesPage(
          refreshSignal: _dataVersion,
          onOpenDetail: _openDetail,
        ),
        AddPostPage(onSaved: _handleAddSaved),
        SettingsPage(onDataChanged: _notifyDataChanged),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _detailPostId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeDetail(false);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 600;
          return isDesktop ? _buildDesktop() : _buildMobile();
        },
      ),
    );
  }

  Widget _buildMobile() {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Artikel',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Tambah',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktop() {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 240,
            selectedIndex: _index,
            onDestinationSelected: _select,
            groupAlignment: -1.0,
            backgroundColor: colorScheme.surface,
            indicatorColor: colorScheme.primaryContainer,
            selectedIconTheme: IconThemeData(color: colorScheme.primary),
            selectedLabelTextStyle: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
            leading: const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 16, 8),
              child: _BrandHeader(),
            ),
            trailing: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Versi 1.0.0',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Beranda'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article),
                label: Text('Artikel'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Tambah Artikel'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Pengaturan'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'NARATA',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Blog Management',
          style: TextStyle(fontSize: 12, color: colorScheme.outline),
        ),
      ],
    );
  }
}
