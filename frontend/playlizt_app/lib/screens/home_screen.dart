import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/content_card.dart';
import '../widgets/themed_logo.dart';
import 'creator_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      contentProvider.loadContent();
      contentProvider.loadCategories();
      if (authProvider.userId != null) {
        contentProvider.loadContinueWatching(authProvider.userId!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      Provider.of<ContentProvider>(context, listen: false).searchContent(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 160,
        title: const ThemedLogo(height: 144),
        centerTitle: false,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          if (authProvider.role == 'CREATOR' || authProvider.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.upload),
              tooltip: 'Upload',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatorDashboardScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Profile'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ThemedLogo(height: 180),
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person, size: 40),
                      ),
                      Text('Username: ${authProvider.username}'),
                      Text('Email: ${authProvider.email}'),
                      Text('Role: ${authProvider.role}'),
                    ],
                  ),
                  actions: [
                    if (authProvider.role == 'ADMIN')
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminDashboardScreen(),
                            ),
                          );
                        },
                        child: const Text('Admin Dashboard'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        authProvider.logout();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => contentProvider.loadContent(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search content...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      contentProvider.loadContent();
                    },
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 24),

              // Continue Watching
              if (contentProvider.continueWatching.isNotEmpty) ...[
                Text(
                  'Continue Watching',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: contentProvider.continueWatching.length,
                    itemBuilder: (context, index) {
                      return ContentCard(
                        content: contentProvider.continueWatching[index],
                        width: 240,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // All Content
              Text(
                'Browse Content',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),

              if (contentProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (contentProvider.error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Text(
                          'Error: ${contentProvider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => contentProvider.loadContent(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (contentProvider.contentList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No content available'),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: contentProvider.contentList.length,
                  itemBuilder: (context, index) {
                    return ContentCard(
                      content: contentProvider.contentList[index],
                    );
                  },
                ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Image.asset(
                     'assets/images/blaklizt_logo.jpg',
                     height: 40,
                     errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                   ),
                   const SizedBox(width: 12),
                   Text(
                     'Powered by Blaklizt Entertainment', 
                     style: Theme.of(context).textTheme.bodySmall,
                   ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
