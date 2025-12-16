/**
 * Created in Windsurf Editor 1.12.41 - GPT 5.1 (High Reasoning)
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025/11/27 20:51
 * Email        : tkaviya@t3ratech.co.zw
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CreatorDashboardScreen extends StatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    final url = _urlController.text;
    final videoId = _extractVideoId(url);
    if (videoId != null) {
      setState(() {
        _thumbnailUrlController.text = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
      });
    }
  }

  String? _extractVideoId(String url) {
    RegExp regExp = RegExp(r'(?:youtu\.be\/|youtube\.com\/(?:.*v=|.*\/))([a-zA-Z0-9_-]{11})');
    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _titleController.dispose();
    _descController.dispose();
    _urlController.dispose();
    _thumbnailUrlController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      
      await apiService.addContent(
        title: _titleController.text,
        description: _descController.text,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : 'General',
        creatorId: authProvider.userId ?? 0,
        videoUrl: _urlController.text,
        thumbnailUrl: _thumbnailUrlController.text,
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );
      
      // Refresh content list
      if (mounted) {
        Provider.of<ContentProvider>(context, listen: false).loadContent();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Content Studio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload New Content',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://www.youtube.com/watch?v=...',
                  helperText: 'Only YouTube URLs are supported',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final regex = RegExp(r'^(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[a-zA-Z0-9_-]{11}.*$');
                  if (!regex.hasMatch(v)) return 'Must be a valid YouTube URL';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thumbnailUrlController,
                readOnly: true, // Auto-populated
                enabled: false, // Greyed out
                decoration: const InputDecoration(
                  labelText: 'Thumbnail URL (Auto-populated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add Content'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
