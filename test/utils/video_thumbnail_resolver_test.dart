import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/core/utils/video_thumbnail_resolver.dart';

void main() {
  test('exercise demo prefers the GIF over a stale thumbnail', () {
    expect(
      VideoThumbnailResolver.resolveDemo(
        thumbnailUrl: 'https://example.com/old.jpg',
        videoUrl: 'https://example.com/exercise.gif?version=2',
      ),
      'https://example.com/exercise.gif?version=2',
    );
  });

  test('relative GIF links resolve to the configured API host', () {
    const gif = '/assets/exercises/gifs/push_up.gif';
    expect(
      VideoThumbnailResolver.resolveDemo(
          thumbnailUrl: 'assets/old.png', videoUrl: gif),
      VideoThumbnailResolver.assetUrl(gif),
    );
  });

  test('video and thumbnail-only demos retain their image preview', () {
    for (final video in [null, 'https://example.com/exercise.mp4']) {
      expect(
        VideoThumbnailResolver.resolveDemo(
            thumbnailUrl: 'https://example.com/preview.jpg', videoUrl: video),
        'https://example.com/preview.jpg',
      );
    }
  });
}
