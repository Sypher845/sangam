class Tweet {
  final int id;
  final String tweetId;
  final String hazardType;
  final String title;
  final String hazardDescription;
  final String area;
  final double latitude;
  final double longitude;
  final int upvoteCount;
  final int downvoteCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int userId;
  final List<TweetImage> images;
  final bool isUpvoted;
  final bool isDownvoted;
  final bool isVerified;
  final int? credibility;

  Tweet({
    required this.id,
    required this.tweetId,
    required this.hazardType,
    required this.title,
    required this.hazardDescription,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.upvoteCount,
    required this.downvoteCount,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    required this.images,
    this.isUpvoted = false,
    this.isDownvoted = false,
    this.isVerified = false,
    this.credibility,
  });

  factory Tweet.fromJson(Map<String, dynamic> json) {
    return Tweet(
      id: json['id'] as int? ?? 0,
      tweetId: json['tweet_id'] as String? ?? '',
      hazardType: json['hazard_type'] as String? ?? '',
      title: json['Title'] as String? ?? '',
      hazardDescription: json['hazard_description'] as String? ?? '',
      area: json['area'] as String? ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['lon'] as num?)?.toDouble() ?? 0.0,
      upvoteCount: json['upvote'] as int? ?? 0,
      downvoteCount: json['downvote'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      userId: json['user'] as int? ?? 0,
      images:
          (json['images'] as List<dynamic>?)
              ?.map(
                (imageJson) =>
                    TweetImage.fromJson(imageJson as Map<String, dynamic>),
              )
              .toList() ??
          [],
      isUpvoted: json['is_upvoted'] as bool? ?? false,
      isDownvoted: json['is_downvoted'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      credibility: json['credibility'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tweet_id': tweetId,
      'hazard_type': hazardType,
      'title': title,
      'hazard_description': hazardDescription,
      'area': area,
      'lat': latitude,
      'lon': longitude,
      'upvote': upvoteCount,
      'downvote': downvoteCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user': userId,
      'images': images.map((image) => image.toJson()).toList(),
      'is_upvoted': isUpvoted,
      'is_downvoted': isDownvoted,
      'is_verified': isVerified,
      'credibility': credibility,
    };
  }

  Tweet copyWith({
    int? id,
    String? tweetId,
    String? hazardType,
    String? title,
    String? hazardDescription,
    String? area,
    double? latitude,
    double? longitude,
    int? upvoteCount,
    int? downvoteCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? userId,
    List<TweetImage>? images,
    bool? isUpvoted,
    bool? isDownvoted,
    bool? isVerified,
    int? credibility,
  }) {
    return Tweet(
      id: id ?? this.id,
      tweetId: tweetId ?? this.tweetId,
      hazardType: hazardType ?? this.hazardType,
      title: title ?? this.title,
      hazardDescription: hazardDescription ?? this.hazardDescription,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      downvoteCount: downvoteCount ?? this.downvoteCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      images: images ?? this.images,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      isDownvoted: isDownvoted ?? this.isDownvoted,
      isVerified: isVerified ?? this.isVerified,
      credibility: credibility ?? this.credibility,
    );
  }

  @override
  String toString() {
    return 'Tweet(id: $id, title: $title, hazardType: $hazardType, area: $area, upvotes: $upvoteCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tweet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class TweetImage {
  final int id;
  final String imageUrl;
  final String publicId;
  final DateTime uploadedAt;

  TweetImage({
    required this.id,
    required this.imageUrl,
    required this.publicId,
    required this.uploadedAt,
  });

  factory TweetImage.fromJson(Map<String, dynamic> json) {
    return TweetImage(
      id: json['image_id'] is String
          ? json['image_id'].hashCode
          : (json['image_id'] as int? ?? 0),
      imageUrl: json['image_url'] as String? ?? '',
      publicId: json['public_id'] as String? ?? '',
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_id': id,
      'image_url': imageUrl,
      'public_id': publicId,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TweetImage(id: $id, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TweetImage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
