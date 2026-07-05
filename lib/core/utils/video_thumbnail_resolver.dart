class VideoThumbnailResolver {
  static String? resolve({String? thumbnailUrl, String? videoUrl}) {
    final direct = thumbnailUrl?.trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    return fromVideoUrl(videoUrl);
  }

  static String? fromVideoUrl(String? videoUrl) {
    if (videoUrl == null || videoUrl.trim().isEmpty) return null;
    final raw = videoUrl.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();

    if (host.contains('youtu.be')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      return _youtubeThumbnail(id);
    }

    if (host.contains('youtube.com')) {
      String? id = uri.queryParameters['v'];
      final shortsIndex = uri.pathSegments.indexOf('shorts');
      if ((id == null || id.isEmpty) &&
          shortsIndex >= 0 &&
          uri.pathSegments.length > shortsIndex + 1) {
        id = uri.pathSegments[shortsIndex + 1];
      }
      final embedIndex = uri.pathSegments.indexOf('embed');
      if ((id == null || id.isEmpty) &&
          embedIndex >= 0 &&
          uri.pathSegments.length > embedIndex + 1) {
        id = uri.pathSegments[embedIndex + 1];
      }
      return _youtubeThumbnail(id);
    }

    if (host.contains('vimeo.com') && uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.last;
      if (id.isNotEmpty) {
        return 'https://vumbnail.com/$id.jpg';
      }
    }

    if (host.contains('cloudinary.com') && uri.path.contains('/video/upload/')) {
      final videoPath = uri.path;
      final transformedPath = videoPath.replaceFirst(
        '/video/upload/',
        '/video/upload/so_1/',
      );
      final jpgPath = transformedPath.replaceFirst(RegExp(r'\.[a-zA-Z0-9]{2,5}$'), '.jpg');
      return uri.replace(path: jpgPath).toString();
    }

    final path = uri.path.toLowerCase();
    if (path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.webm') ||
        path.endsWith('.m4v')) {
      final jpgPath = uri.path.replaceFirst(RegExp(r'\.[a-zA-Z0-9]{2,5}$'), '.jpg');
      return uri.replace(path: jpgPath).toString();
    }

    return null;
  }

  static String? _youtubeThumbnail(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    return 'https://img.youtube.com/vi/${id.trim()}/hqdefault.jpg';
  }
}