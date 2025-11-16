import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../favorites/favorites_screen.dart';
import '../categories/categories_screen.dart';
import '../notepad/notepad_screen.dart';
import 'home_screen.dart';
import 'add_edit_link_sheet.dart';
import '../auth/auth_controller.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  StreamSubscription? _intentDataStreamSubscription;

  final List<Widget> _screens = const [
    HomeScreen(),
    FavoritesScreen(),
    CategoriesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Listen to shared content while app is running  
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _handleSharedText(value.first.path);
        }
      },
      onError: (err) {
        debugPrint('Error receiving shared content: $err');
      },
    );

    // Get initial shared content (when app is opened via share)
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedText(value.first.path);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  void _handleSharedText(String text) {
    // Wait for frame to complete before showing bottom sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddEditLinkSheet(initialUrl: text.trim()),
        );
      }
    });
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkHub'),
        actions: [
          // Overflow menu (three dots) for Notepad and Logout
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'notepad') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotepadScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _showLogoutDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'notepad',
                child: Row(
                  children: [
                    Icon(Icons.note_outlined),
                    SizedBox(width: 8),
                    Text('Link Notepad'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
    );
  }
}
