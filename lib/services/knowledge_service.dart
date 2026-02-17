import 'local_data_service.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../utils/image_cache_util.dart';

class KnowledgeService {
  /// Fetch all knowledge articles
  static Future<List<KnowledgeArticle>> getArticles({
    String? category,
    String? tag,
  }) async {
    try {
      var url = '${ApiService.baseUrl}/knowledge';
      final queryParams = <String, String>{};

      if (category != null) queryParams['category'] = category;
      if (tag != null) queryParams['tag'] = tag;

      if (queryParams.isNotEmpty) {
        url +=
            '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      developer.log('Fetching articles from: $url', name: 'KnowledgeService');

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: ApiService.getHeaders(),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          final articles = data
              .map((json) => KnowledgeArticle.fromJson(json))
              .toList();
          developer.log(
            '✓ Fetched ${articles.length} articles',
            name: 'KnowledgeService',
          );
          // Cache images for offline use
          for (final article in articles) {
            if (article.fullImageUrl != null &&
                article.fullImageUrl!.isNotEmpty) {
              await ImageCacheUtil.cacheImage(article.fullImageUrl!);
            }
          }
          // Save to local storage for offline use
          try {
            await LocalDataService.saveData(
              'knowledge_articles',
              articles.map((a) => a.toJson()).toList(),
            );
          } catch (e) {
            developer.log(
              'Failed to save articles locally: $e',
              name: 'KnowledgeService',
            );
          }
          return articles;
        } else {
          throw Exception('Failed to load articles: ${response.statusCode}');
        }
      } catch (e) {
        // If fetch fails, try to load from local storage
        developer.log(
          '❌ Error fetching articles from API: $e',
          name: 'KnowledgeService',
        );
        try {
          final localData = LocalDataService.getData('knowledge_articles');
          if (localData != null) {
            final articles = (localData as List)
                .map(
                  (json) => KnowledgeArticle.fromJson(
                    Map<String, dynamic>.from(json),
                  ),
                )
                .toList();
            developer.log(
              'Loaded ${articles.length} articles from local storage',
              name: 'KnowledgeService',
            );
            return articles;
          } else {
            throw Exception('No local articles found');
          }
        } catch (e) {
          developer.log(
            '❌ Error loading articles from local storage: $e',
            name: 'KnowledgeService',
          );
          rethrow;
        }
      }
    } catch (e) {
      developer.log('❌ Error in getArticles: $e', name: 'KnowledgeService');
      rethrow;
    }
  }

  /// Fetch a single article by ID
  static Future<KnowledgeArticle> getArticle(int id) async {
    try {
      final url = '${ApiService.baseUrl}/knowledge/$id';
      developer.log('Fetching article: $url', name: 'KnowledgeService');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return KnowledgeArticle.fromJson(data);
      } else {
        throw Exception('Failed to load article: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Error fetching article: $e', name: 'KnowledgeService');
      rethrow;
    }
  }
}

/// Knowledge Article model
class KnowledgeArticle {
  final int id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final String? imageUrl;

  /// Returns the full image URL for display
  /// This constructs the complete URL using the API base URL
  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;

    final trimmedUrl = imageUrl!.trim();

    // If already an absolute URL with http/https, return as-is
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      return trimmedUrl;
    }

    // Get the base URL from ApiService
    final baseUrl = ApiService.baseUrl;

    // Extract just the filename from the path
    final filename = trimmedUrl.split('/').last;

    // Construct the full URL
    final fullUrl = '$baseUrl/uploads/files/$filename';

    developer.log(
      'KnowledgeArticle image URL: imageUrl=$imageUrl, baseUrl=$baseUrl, fullUrl=$fullUrl',
      name: 'KnowledgeArticle',
    );

    return fullUrl;
  }

  final int? authorId;
  final int views;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  KnowledgeArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    this.imageUrl,
    this.authorId,
    required this.views,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KnowledgeArticle.fromJson(Map<String, dynamic> json) {
    return KnowledgeArticle(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e.toString()).toList(),
      imageUrl: json['image_url'] as String?,
      authorId: json['author_id'] as int?,
      views: json['views'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'image_url': imageUrl,
      'author_id': authorId,
      'views': views,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get categoryDisplay {
    switch (category) {
      case 'pest-management':
        return 'Pest Management';
      case 'disease-control':
        return 'Disease Control';
      case 'best-practices':
        return 'Best Practices';
      case 'fertilization':
        return 'Fertilization';
      case 'harvesting':
        return 'Harvesting';
      default:
        return category;
    }
  }
}
