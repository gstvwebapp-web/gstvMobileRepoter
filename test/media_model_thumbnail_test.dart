import 'package:flutter_test/flutter_test.dart';
import 'package:gstv_admin/app/data/models/media_model.dart';

void main() {
  group('MediaModel Thumbnail and Fallback URLs', () {
    test('Video with .mp4 generates _video.gif and fallback _video_small.jpg', () {
      final media = MediaModel(
        id: 1,
        userID: 1,
        photos: 'imageE4C8F67D-51DB-45C6-88F8-74A38C67B4EB1789640278mp4_wL43ov1o1789640287.mp4',
        fullpath:
            'https://staging.gstv.in/backend/public/media/2026/09/17/imageE4C8F67D-51DB-45C6-88F8-74A38C67B4EB1789640278mp4_wL43ov1o1789640287.mp4',
        createdAt: '2026-09-17',
        updatedAt: '2026-09-17',
      );

      expect(media.isVideo, isTrue);
      expect(
        media.thumbnailUrl,
        'https://staging.gstv.in/backend/public/media/2026/09/17/imageE4C8F67D-51DB-45C6-88F8-74A38C67B4EB1789640278mp4_wL43ov1o1789640287_video.gif',
      );
      expect(
        media.fallbackThumbnailUrl,
        'https://staging.gstv.in/backend/public/media/2026/09/17/imageE4C8F67D-51DB-45C6-88F8-74A38C67B4EB1789640278mp4_wL43ov1o1789640287_video_small.jpg',
      );
    });

    test('Video already having _video.gif in fullpath generates fallback _video_small.jpg', () {
      final media = MediaModel(
        id: 2,
        userID: 1,
        photos: 'video_file.gif',
        fullpath:
            'https://staging.gstv.in/backend/public/media/2026/09/17/imageE4C8F67D-51DB-45C6-88F8-74A38C67B4EB1789640278mp4_wL43ov1o1789640287_video.gif',
        createdAt: '2026-09-17',
        updatedAt: '2026-09-17',
      );

      expect(
        media.thumbnailUrl,
        'https://staging.gstv.in/backend/public/media/2026/09/17/imageE4C8F67D-51DB-45C6-88F8-74A38C67B4EB1789640278mp4_wL43ov1o1789640287_video.gif',
      );
      expect(
        media.fallbackThumbnailUrl,
        'https://staging.gstv.in/backend/public/media/2026/09/17/imageE4C8F67D-51DB-45C6-88F8-74A38C67B4EB1789640278mp4_wL43ov1o1789640287_video_small.jpg',
      );
    });

    test('Normal image keeps fullpath as thumbnailUrl and has null fallbackThumbnailUrl', () {
      final media = MediaModel(
        id: 3,
        userID: 1,
        photos: 'sample.jpg',
        fullpath: 'https://staging.gstv.in/backend/public/media/2026/09/17/sample.jpg',
        createdAt: '2026-09-17',
        updatedAt: '2026-09-17',
      );

      expect(media.isVideo, isFalse);
      expect(media.thumbnailUrl, 'https://staging.gstv.in/backend/public/media/2026/09/17/sample.jpg');
      expect(media.fallbackThumbnailUrl, isNull);
    });
  });
}
