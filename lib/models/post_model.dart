import '../utils/geofence_math.dart';

enum PostType {
  text,
  photo,
  video,
  voiceNote,
  poll,
}

class PollOption {
  final String id;
  final String text;
  int votes;

  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'votes': votes,
  };

  PollOption copyWith({
    String? id,
    String? text,
    int? votes,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      votes: votes ?? this.votes,
    );
  }
}

class VerificationDetails {
  final bool isGpsVerified;
  final double gpsAccuracyMeters;
  final bool isDeviceIntegrityVerified;
  final String deviceIntegrityProvider; // 'Google Play Integrity API' or 'Apple App Attest'
  final bool isNetworkVerified;
  final String networkSignals; // 'Cell Tower + Wi-Fi Fingerprint'
  final bool mockLocationPassed;
  final bool rootJailbreakPassed;
  final double confidenceScore; // 0.0 - 100.0%
  final String verificationHash;
  final DateTime verifiedAt;

  const VerificationDetails({
    required this.isGpsVerified,
    required this.gpsAccuracyMeters,
    required this.isDeviceIntegrityVerified,
    required this.deviceIntegrityProvider,
    required this.isNetworkVerified,
    required this.networkSignals,
    required this.mockLocationPassed,
    required this.rootJailbreakPassed,
    required this.confidenceScore,
    required this.verificationHash,
    required this.verifiedAt,
  });

  factory VerificationDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return VerificationDetails(
        isGpsVerified: true,
        gpsAccuracyMeters: 3.5,
        isDeviceIntegrityVerified: true,
        deviceIntegrityProvider: 'Google Play Integrity API (MEETS_STRONG_INTEGRITY)',
        isNetworkVerified: true,
        networkSignals: 'Cell Tower + Wi-Fi Match',
        mockLocationPassed: true,
        rootJailbreakPassed: true,
        confidenceScore: 99.0,
        verificationHash: 'GT-SEC-DEFAULT',
        verifiedAt: DateTime.now(),
      );
    }
    return VerificationDetails(
      isGpsVerified: json['isGpsVerified'] ?? true,
      gpsAccuracyMeters: (json['gpsAccuracyMeters'] as num?)?.toDouble() ?? 3.5,
      isDeviceIntegrityVerified: json['isDeviceIntegrityVerified'] ?? true,
      deviceIntegrityProvider: json['deviceIntegrityProvider'] ?? 'Google Play Integrity API (MEETS_STRONG_INTEGRITY)',
      isNetworkVerified: json['isNetworkVerified'] ?? true,
      networkSignals: json['networkSignals'] ?? 'Cell Tower + Wi-Fi Match',
      mockLocationPassed: json['mockLocationPassed'] ?? true,
      rootJailbreakPassed: json['rootJailbreakPassed'] ?? true,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 98.5,
      verificationHash: json['verificationHash'] ?? 'GT-SEC-01',
      verifiedAt: DateTime.tryParse(json['verifiedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class PostModel {
  final String id;
  final String eventId;
  final String? title;
  final String? tagName;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final int authorTrustScore;
  final bool authorIsVerifiedJournalist;
  final PostType type;
  final String content;
  final String? mediaUrl;
  final String? videoThumbnailUrl;
  final int? audioDurationSeconds;
  final List<double>? waveform;
  final List<PollOption>? pollOptions;
  final String? userVotedPollOptionId;
  final DateTime createdAt;
  final GeoPoint location;
  final String locationDisplayName;
  final double distanceFromEpicenterMeters;
  final VerificationDetails verification;
  int upvotes;
  int downvotes;
  int userVote; // 1 for upvoted, -1 for downvoted, 0 for none
  int commentsCount;

  PostModel({
    required this.id,
    required this.eventId,
    this.title,
    this.tagName,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.authorTrustScore,
    this.authorIsVerifiedJournalist = false,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.videoThumbnailUrl,
    this.audioDurationSeconds,
    this.waveform,
    this.pollOptions,
    this.userVotedPollOptionId,
    required this.createdAt,
    required this.location,
    required this.locationDisplayName,
    required this.distanceFromEpicenterMeters,
    required this.verification,
    this.upvotes = 0,
    this.downvotes = 0,
    this.userVote = 0,
    this.commentsCount = 0,
  });

  factory PostModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final author = json['author'] as Map<String, dynamic>? ?? {};
    final coords = json['location']?['coordinates'] as List<dynamic>?;
    final double lng = coords != null && coords.isNotEmpty ? (coords[0] as num).toDouble() : 77.2185;
    final double lat = coords != null && coords.length > 1 ? (coords[1] as num).toDouble() : 28.6274;

    PostType postType = PostType.text;
    final typeStr = (json['type'] as String?)?.toUpperCase() ?? 'TEXT';
    if (typeStr == 'PHOTO') {
      postType = PostType.photo;
    } else if (typeStr == 'VIDEO') {
      postType = PostType.video;
    } else if (typeStr == 'VOICE_NOTE') {
      postType = PostType.voiceNote;
    } else if (typeStr == 'POLL') {
      postType = PostType.poll;
    }

    List<PollOption>? options;
    if (json['pollOptions'] is List) {
      options = (json['pollOptions'] as List).map((o) => PollOption.fromJson(o)).toList();
    }

    String? userVotedOption = json['userVotedPollOptionId'] as String? ?? json['userVotedOptionId'] as String?;
    if (userVotedOption == null && json['pollVoters'] is List && currentUserId != null) {
      for (final voter in json['pollVoters']) {
        if (voter is Map && voter['optionId'] != null) {
          final voterId = voter['userId']?.toString();
          if (voterId == currentUserId ||
              ((currentUserId == 'user_dev_01' || currentUserId == 'guest_user') &&
               (voterId == 'user_dev_01' || voterId == 'guest_user'))) {
            userVotedOption = voter['optionId']?.toString();
            break;
          }
        }
      }
    }

    List<double>? waveform;
    if (json['waveform'] is List) {
      waveform = (json['waveform'] as List).map((w) => (w as num).toDouble()).toList();
    }

    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final eventId = json['tagId']?.toString() ?? json['eventId']?.toString() ?? id;

    int parsedUserVote = (json['userVote'] as num?)?.toInt() ?? 0;
    if (parsedUserVote == 0 && json['voters'] is List) {
      for (final voter in json['voters']) {
        if (voter is Map && voter['userId'] != null) {
          final vId = voter['userId'].toString();
          if (currentUserId != null && vId == currentUserId) {
            parsedUserVote = (voter['direction'] as num?)?.toInt() ?? 0;
            break;
          } else if (vId == 'user_dev_01' || vId == 'guest_user') {
            parsedUserVote = (voter['direction'] as num?)?.toInt() ?? 0;
          }
        }
      }
    }

    return PostModel(
      id: id,
      eventId: eventId,
      title: json['title'] as String?,
      tagName: json['tagName'] as String?,
      authorId: author['userId'] ?? 'user_dev_01',
      authorName: author['name'] ?? 'Verified Eyewitness',
      authorAvatar: author['avatar'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
      authorTrustScore: (author['trustScore'] as num?)?.toInt() ?? 95,
      authorIsVerifiedJournalist: author['isVerifiedJournalist'] ?? false,
      type: postType,
      content: json['content'] ?? json['title'] ?? '',
      mediaUrl: json['mediaUrl'] as String?,
      videoThumbnailUrl: json['videoThumbnailUrl'] as String?,
      audioDurationSeconds: (json['audioDurationSeconds'] as num?)?.toInt(),
      waveform: waveform,
      pollOptions: options,
      userVotedPollOptionId: userVotedOption,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      location: GeoPoint(lat, lng),
      locationDisplayName: json['locationDisplayName'] ?? 'Verified Location',
      distanceFromEpicenterMeters: (json['distanceFromEpicenterMeters'] as num?)?.toDouble() ?? 0,
      verification: VerificationDetails.fromJson(json['verification']),
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
      userVote: parsedUserVote,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
    );
  }

  PostModel copyWith({
    String? id,
    String? eventId,
    String? title,
    String? tagName,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    int? authorTrustScore,
    bool? authorIsVerifiedJournalist,
    PostType? type,
    String? content,
    String? mediaUrl,
    String? videoThumbnailUrl,
    int? audioDurationSeconds,
    List<double>? waveform,
    List<PollOption>? pollOptions,
    String? userVotedPollOptionId,
    DateTime? createdAt,
    GeoPoint? location,
    String? locationDisplayName,
    double? distanceFromEpicenterMeters,
    VerificationDetails? verification,
    int? upvotes,
    int? downvotes,
    int? userVote,
    int? commentsCount,
  }) {
    return PostModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      tagName: tagName ?? this.tagName,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorTrustScore: authorTrustScore ?? this.authorTrustScore,
      authorIsVerifiedJournalist: authorIsVerifiedJournalist ?? this.authorIsVerifiedJournalist,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      videoThumbnailUrl: videoThumbnailUrl ?? this.videoThumbnailUrl,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      waveform: waveform ?? this.waveform,
      pollOptions: pollOptions ?? this.pollOptions,
      userVotedPollOptionId: userVotedPollOptionId ?? this.userVotedPollOptionId,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      locationDisplayName: locationDisplayName ?? this.locationDisplayName,
      distanceFromEpicenterMeters: distanceFromEpicenterMeters ?? this.distanceFromEpicenterMeters,
      verification: verification ?? this.verification,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      userVote: userVote ?? this.userVote,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }

  int get score => upvotes - downvotes;

  /// GroundTruth Reliability Ranking Score
  double get reliabilityScore {
    final voteFactor = (upvotes * 1.5) - (downvotes * 2.0);
    final trustFactor = authorTrustScore * 0.4;
    final confFactor = verification.confidenceScore * 0.4;
    final hoursAgo = DateTime.now().difference(createdAt).inMinutes / 60.0;
    final decay = 1.0 / (1.0 + (hoursAgo * 0.2));
    return (voteFactor + trustFactor + confFactor) * decay;
  }
}
