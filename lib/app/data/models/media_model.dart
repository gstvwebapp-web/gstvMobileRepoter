class MediaModel {
  final int id;
  final int userID;
  final String photos;
  final String? photoTitle;
  final String? photoAlt;
  final String fullpath;
  final String createdAt;
  final String updatedAt;

  MediaModel({
    required this.id,
    required this.userID,
    required this.photos,
    this.photoTitle,
    this.photoAlt,
    required this.fullpath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] ?? 0,
      userID: json['userID'] ?? 0,
      photos: json['photos'] ?? '',
      photoTitle: json['photoTitle'],
      photoAlt: json['photoAlt'],
      fullpath: json['fullpath'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userID': userID,
      'photos': photos,
      'photoTitle': photoTitle,
      'photoAlt': photoAlt,
      'fullpath': fullpath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get isVideo {
    final extension = photos.toLowerCase();
    return extension.contains('.mp4') ||
        extension.contains('.mov') ||
        extension.contains('.avi') ||
        extension.contains('video');
  }

  bool get isGif {
    return photos.toLowerCase().contains('.gif');
  }

  /// Primary thumbnail URL for the media.
  /// For videos, returns the `_video.gif` preview URL.
  String get thumbnailUrl {
    if (isVideo) {
      if (fullpath.contains('_video.gif')) {
        return fullpath;
      }
      final lastDotIndex = fullpath.lastIndexOf('.');
      if (lastDotIndex != -1) {
        return '${fullpath.substring(0, lastDotIndex)}_video.gif';
      }
      if (fullpath.contains('.mp4')) {
        return fullpath.replaceFirst('.mp4', '_video.gif');
      }
    }
    return fullpath;
  }

  /// Fallback thumbnail URL if `thumbnailUrl` (e.g. `_video.gif`) returns 404.
  /// Returns `_video_small.jpg` for videos.
  String? get fallbackThumbnailUrl {
    if (isVideo || fullpath.contains('_video.gif')) {
      if (fullpath.contains('_video.gif')) {
        return fullpath.replaceFirst('_video.gif', '_video_small.jpg');
      }
      final lastDotIndex = fullpath.lastIndexOf('.');
      if (lastDotIndex != -1) {
        return '${fullpath.substring(0, lastDotIndex)}_video_small.jpg';
      }
      if (fullpath.contains('.mp4')) {
        return fullpath.replaceFirst('.mp4', '_video_small.jpg');
      }
    }
    return null;
  }
}

class MediaResponse {
  final List<MediaModel> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? nextPageUrl;
  final String? prevPageUrl;

  MediaResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory MediaResponse.fromJson(Map<String, dynamic> json) {
    return MediaResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => MediaModel.fromJson(item))
              .toList() ??
          [],
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
      nextPageUrl: json['next_page_url'],
      prevPageUrl: json['prev_page_url'],
    );
  }
}

class MediaListResponse {
  final MediaResponse media;
  final MediaResponse videoMedia;

  MediaListResponse({required this.media, required this.videoMedia});

  factory MediaListResponse.fromJson(Map<String, dynamic> json) {
    return MediaListResponse(
      media: MediaResponse.fromJson(json['media'] ?? {}),
      videoMedia: MediaResponse.fromJson(json['videomedia'] ?? {}),
    );
  }
}
