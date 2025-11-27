class Content {
  final int id;
  final int creatorId;
  final String title;
  final String? description;
  final String category;
  final List<String> tags;
  final String? thumbnailUrl;
  final String? videoUrl;
  final int? durationSeconds;
  final String? aiGeneratedDescription;
  final String? aiPredictedCategory;
  final double? aiRelevanceScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  final int viewCount;
  
  Content({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    required this.category,
    required this.tags,
    this.thumbnailUrl,
    this.videoUrl,
    this.durationSeconds,
    this.aiGeneratedDescription,
    this.aiPredictedCategory,
    this.aiRelevanceScore,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublished,
    required this.viewCount,
  });
  
  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'] ?? 0,
      creatorId: json['creatorId'] ?? 0,
      title: json['title'] ?? 'Untitled',
      description: json['description'],
      category: json['category'] ?? 'Uncategorized',
      tags: List<String>.from(json['tags'] ?? []),
      thumbnailUrl: json['thumbnailUrl'],
      videoUrl: json['videoUrl'],
      durationSeconds: json['durationSeconds'],
      aiGeneratedDescription: json['aiGeneratedDescription'],
      aiPredictedCategory: json['aiPredictedCategory'],
      aiRelevanceScore: json['aiRelevanceScore']?.toDouble(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      isPublished: json['isPublished'] ?? false,
      viewCount: json['viewCount'] ?? 0,
    );
  }
  
  String get displayDescription => aiGeneratedDescription ?? description ?? 'No description available';
  
  String get formattedDuration {
    if (durationSeconds == null) return '';
    final duration = Duration(seconds: durationSeconds!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
