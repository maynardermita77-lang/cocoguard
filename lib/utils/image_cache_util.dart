import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ImageCacheUtil {
  /// Returns the local file path for a given image URL
  static Future<String> getLocalImagePath(String imageUrl) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = Uri.parse(imageUrl).pathSegments.last;
    return '${dir.path}/article_images/$filename';
  }

  /// Downloads and saves the image to local storage if not already present
  static Future<String?> cacheImage(String imageUrl) async {
    try {
      final localPath = await getLocalImagePath(imageUrl);
      final file = File(localPath);
      if (await file.exists()) {
        developer.log(
          'Image already cached: $localPath',
          name: 'ImageCacheUtil',
        );
        return localPath;
      }
      developer.log('Downloading image: $imageUrl', name: 'ImageCacheUtil');
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        developer.log('Image cached at: $localPath', name: 'ImageCacheUtil');
        return localPath;
      } else {
        developer.log(
          'Failed to download image: $imageUrl, status: ${response.statusCode}',
          name: 'ImageCacheUtil',
          level: 900,
        );
      }
      return null;
    } catch (e) {
      developer.log(
        'Error caching image: $imageUrl, error: $e',
        name: 'ImageCacheUtil',
        error: e,
      );
      return null;
    }
  }

  /// Checks if the image is cached locally
  static Future<bool> isImageCached(String imageUrl) async {
    final localPath = await getLocalImagePath(imageUrl);
    return File(localPath).exists();
  }

  /// Returns the local file if cached, otherwise null
  static Future<File?> getCachedImageFile(String imageUrl) async {
    final localPath = await getLocalImagePath(imageUrl);
    final file = File(localPath);
    return await file.exists() ? file : null;
  }
}
