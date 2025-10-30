import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../widgets/feature_card.dart';
import 'profile_screen.dart';
import 'product_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const CategoriesTabUpdated(),
    const CartTab(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Smart Cart'),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'User',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    FeatureCard(
                      icon: Icons.edit_document,
                      title: 'Read User',
                      subtitle: 'View document',
                      color: Colors.blue,
                      onTap: () => _readUserDocument(context, user?.uid),
                    ),
                    FeatureCard(
                      icon: Icons.message,
                      title: 'Add Message',
                      subtitle: 'Append to array',
                      color: Colors.green,
                      onTap: () => _appendMessage(context, user?.uid),
                    ),
                    FeatureCard(
                      icon: Icons.history,
                      title: 'Add History',
                      subtitle: 'New entry',
                      color: Colors.orange,
                      onTap: () => _addHistoryEntry(context, user?.uid),
                    ),
                    FeatureCard(
                      icon: Icons.stream,
                      title: 'Live Updates',
                      subtitle: 'Real-time data',
                      color: Colors.purple,
                      onTap: () => _showLiveUpdates(context, user?.uid),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _readUserDocument(BuildContext context, String? uid) async {
    if (uid == null) {
      _showSnackBar(context, 'No user is signed in');
      return;
    }
    try {
      final data = await FirestoreService.instance.getUser(uid);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('User Document'),
            content: SingleChildScrollView(
              child: Text(
                data == null ? 'No document found' : data.toString(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) _showSnackBar(context, 'Error: $e');
    }
  }

  Future<void> _appendMessage(BuildContext context, String? uid) async {
    if (uid == null) {
      _showSnackBar(context, 'No user is signed in');
      return;
    }
    try {
      final msg = {
        'text': 'Button pressed',
        'at': DateTime.now().toIso8601String(),
      };
      await FirestoreService.instance.appendToArrayField(
        'users/$uid',
        'messages',
        msg,
      );
      if (context.mounted) {
        _showSnackBar(context, 'Message added successfully', isError: false);
      }
    } catch (e) {
      if (context.mounted) _showSnackBar(context, 'Error: $e');
    }
  }

  Future<void> _addHistoryEntry(BuildContext context, String? uid) async {
    if (uid == null) {
      _showSnackBar(context, 'No user is signed in');
      return;
    }
    try {
      final entry = {
        'action': 'button_press',
        'time': FieldValue.serverTimestamp(),
      };
      await FirestoreService.instance.addSubcollectionDocument(
        'users/$uid',
        'history',
        entry,
      );
      if (context.mounted) {
        _showSnackBar(context, 'History entry added', isError: false);
      }
    } catch (e) {
      if (context.mounted) _showSnackBar(context, 'Error: $e');
    }
  }

  void _showLiveUpdates(BuildContext context, String? uid) {
    if (uid == null) {
      _showSnackBar(context, 'No user is signed in');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => StreamBuilder<Map<String, dynamic>?>(
        stream: FirestoreService.instance.streamUser(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.radar, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('Live Updates'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                snap.data == null ? 'No document' : snap.data.toString(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class CategoriesTabUpdated extends StatelessWidget {
  const CategoriesTabUpdated({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductsListScreen(),
                ),
              );
            },
            tooltip: 'View All Products',
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          final categories = [
            {'name': 'Electronics', 'icon': Icons.devices, 'color': Colors.blue},
            {'name': 'Fashion', 'icon': Icons.checkroom, 'color': Colors.pink},
            {'name': 'Food', 'icon': Icons.fastfood, 'color': Colors.orange},
            {'name': 'Books', 'icon': Icons.menu_book, 'color': Colors.brown},
            {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': Colors.green},
            {'name': 'Home', 'icon': Icons.home, 'color': Colors.purple},
            {'name': 'Beauty', 'icon': Icons.spa, 'color': Colors.teal},
            {'name': 'Toys', 'icon': Icons.toys, 'color': Colors.red},
          ];
          
          final category = categories[index];
          
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                // Navigate to products filtered by category
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductsListScreen(
                      category: category['name'] as String,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (category['color'] as Color).withOpacity(0.7),
                      (category['color'] as Color).withOpacity(0.4),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category['name'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shop feature coming soon')),
                );
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}