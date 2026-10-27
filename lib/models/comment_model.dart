import '../utils/geofence_math.dart';

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final int authorTrustScore;
  final String text;
  final DateTime createdAt;
  final bool isVerifiedOnSite;
  final double distanceMeters;
  final GeoPoint location;

  const CommentModel({
    required this.id,
    required this.postId,
    this.authorId = 'anonymous_witness',
    required this.authorName,
    required this.authorAvatar,
    required this.authorTrustScore,
    required this.text,
    required this.createdAt,
    required this.isVerifiedOnSite,
    required this.distanceMeters,
    required this.location,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? {};
    final coords = json['location']?['coordinates'] as List<dynamic>?;
    final double lng = coords != null && coords.isNotEmpty ? (coords[0] as num).toDouble() : 77.2185;
    final double lat = coords != null && coords.length > 1 ? (coords[1] as num).toDouble() : 28.6274;

    return CommentModel(
      id: json['_id'] ?? json['id'] ?? 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      postId: json['postId']?.toString() ?? '',
      authorId: author['userId']?.toString() ?? author['id']?.toString() ?? 'anonymous_witness',
      authorName: author['name'] ?? 'Verified Eyewitness',
      authorAvatar: author['avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
      authorTrustScore: (author['trustScore'] as num?)?.toInt() ?? 90,
      text: json['text'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isVerifiedOnSite: json['isVerifiedOnSite'] ?? true,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      location: GeoPoint(lat, lng),
    );
  }
}
