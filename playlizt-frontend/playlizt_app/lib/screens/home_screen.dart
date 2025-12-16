/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/26 12:59
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../widgets/content_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      
      contentProvider.loadContent();
      contentProvider.loadCategories();
      // User specific data loading moved to didChangeDependencies to handle async auth loading
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);

    if (authProvider.userId != null && authProvider.userId != _lastLoadedUserId) {
      print('HomeScreen: User loaded (${authProvider.userId}), fetching recommendations...');
      _lastLoadedUserId = authProvider.userId;
      contentProvider.loadContinueWatching(authProvider.userId!);
      contentProvider.loadRecommendations(authProvider.userId!);
    }
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
    final contentProvider = Provider.of<ContentProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: () async {
            await contentProvider.loadContent();
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (auth.userId != null) {
              await contentProvider.loadContinueWatching(auth.userId!);
              await contentProvider.loadRecommendations(auth.userId!);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                      const SizedBox(height: 16),

                      // Category Chips
                      if (contentProvider.categories.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: contentProvider.categories.map((category) {
                              final isSelected =
                                  contentProvider.selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    contentProvider
                                        .selectCategory(selected ? category : null);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

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

                      // Recommendations
                      if (contentProvider.recommendations.isNotEmpty) ...[
                        Semantics(
                          label: 'Recommended for You',
                          child: Text(
                            'Recommended for You',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: contentProvider.recommendations.length,
                            itemBuilder: (context, index) {
                              return ContentCard(
                                content: contentProvider.recommendations[index],
                                width: 240,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // All Content
                      Semantics(
                        label: 'Browse Content',
                        child: Text(
                          'Browse Content',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
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
                            crossAxisCount:
                                (MediaQuery.of(context).size.width / 200).floor().clamp(2, 6),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: contentProvider.contentList.length,
                          itemBuilder: (context, index) {
                            return ContentCard(
                              content: contentProvider.contentList[index],
                            );
                          },
                        ),
                    ],
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/blaklizt_logo.jpg',
                            height: 40,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
