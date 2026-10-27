import 'achievement_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String handle;
  final String avatarUrl;
  final int trustScore; // 0 - 100
  final int verifiedContributions;
  final double accuracyRating; // Percentage e.g. 98.6%
  final int helpfulVotes;
  final String tier; // e.g. "Senior Ground Witness", "Verified Eyewitness"
  final String deviceModel;
  final bool hasAttestationKey;
  final bool isMockLocationDetected;
  final bool isRootedOrJailbroken;
  final String role;

  // Gamification & Achievement activity counters
  final int xp;
  final int level;
  final String levelTitle;
  final int postsCreated;
  final int verificationsDone; // Likes / Dislikes performed inside tag radius
  final int commentsAdded;
  final int tagsCreated;
  final List<AchievementModel> achievements;

  // Social & Follow stats
  final int followersCount;
  final int followingCount;
  final List<String> following;
  final String bio;
  final String? location;
  final String? organization;
  final bool isFollowed;

  const UserModel({
    required this.id,
    required this.name,
    this.email = 'vikram@groundtruth.org',
    required this.handle,
    required this.avatarUrl,
    required this.trustScore,
    required this.verifiedContributions,
    required this.accuracyRating,
    required this.helpfulVotes,
    required this.tier,
    required this.deviceModel,
    this.hasAttestationKey = true,
    this.isMockLocationDetected = false,
    this.isRootedOrJailbroken = false,
    this.role = 'eyewitness',
    this.xp = 450,
    this.level = 2,
    this.levelTitle = 'Verified Field Scout',
    this.postsCreated = 4,
    this.verificationsDone = 12,
    this.commentsAdded = 9,
    this.tagsCreated = 2,
    this.achievements = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.following = const [],
    this.bio = '',
    this.location,
    this.organization,
    this.isFollowed = false,
  });

  int get nextLevelXp => level * 500;
  int get currentLevelBaseXp => (level - 1) * 500;
  double get levelProgress {
    final needed = nextLevelXp - currentLevelBaseXp;
    if (needed <= 0) return 1.0;
    final current = xp - currentLevelBaseXp;
    return (current / needed).clamp(0.0, 1.0);
  }

  bool get isJournalist => role.trim().toLowerCase() == 'journalist';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? 'user_dev_01',
      name: json['name']?.toString() ?? 'Eyewitness',
      email: json['email']?.toString() ?? '',
      handle: json['handle']?.toString() ?? '@eyewitness',
      avatarUrl: json['avatarUrl']?.toString() ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 90,
      verifiedContributions: (json['verifiedContributions'] as num?)?.toInt() ?? 0,
      accuracyRating: (json['accuracyRating'] as num?)?.toDouble() ?? 99.0,
      helpfulVotes: (json['helpfulVotes'] as num?)?.toInt() ?? 0,
      tier: json['tier']?.toString() ?? 'Tier 1 Verified Senior Eyewitness',
      deviceModel: json['deviceModel']?.toString() ?? 'Hardware Keystore Attested',
      hasAttestationKey: json['hasAttestationKey'] ?? true,
      role: json['role']?.toString() ?? 'eyewitness',
      xp: (json['xp'] as num?)?.toInt() ?? 500,
      level: (json['level'] as num?)?.toInt() ?? 2,
      levelTitle: json['levelTitle']?.toString() ?? 'Verified Field Scout',
      postsCreated: (json['postsCreated'] as num?)?.toInt() ?? 0,
      verificationsDone: (json['verificationsDone'] as num?)?.toInt() ?? 0,
      commentsAdded: (json['commentsAdded'] as num?)?.toInt() ?? 0,
      tagsCreated: (json['tagsCreated'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ??
          (json['followers'] is List ? (json['followers'] as List).length : 0),
      followingCount: (json['followingCount'] as num?)?.toInt() ??
          (json['following'] is List ? (json['following'] as List).length : 0),
      following: (json['following'] is List)
          ? (json['following'] as List).map((e) => e.toString()).toList()
          : const [],
      bio: json['bio']?.toString() ?? '',
      location: json['location']?.toString(),
      organization: json['organization']?.toString(),
      isFollowed: json['isFollowed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'handle': handle,
      'avatarUrl': avatarUrl,
      'trustScore': trustScore,
      'verifiedContributions': verifiedContributions,
      'accuracyRating': accuracyRating,
      'helpfulVotes': helpfulVotes,
      'tier': tier,
      'deviceModel': deviceModel,
      'hasAttestationKey': hasAttestationKey,
      'role': role,
      'xp': xp,
      'level': level,
      'levelTitle': levelTitle,
      'postsCreated': postsCreated,
      'verificationsDone': verificationsDone,
      'commentsAdded': commentsAdded,
      'tagsCreated': tagsCreated,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'following': following,
      'bio': bio,
      'location': location,
      'organization': organization,
      'isFollowed': isFollowed,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? handle,
    String? avatarUrl,
    int? trustScore,
    int? verifiedContributions,
    double? accuracyRating,
    int? helpfulVotes,
    String? tier,
    String? deviceModel,
    bool? hasAttestationKey,
    bool? isMockLocationDetected,
    bool? isRootedOrJailbroken,
    String? role,
    int? xp,
    int? level,
    String? levelTitle,
    int? postsCreated,
    int? verificationsDone,
    int? commentsAdded,
    int? tagsCreated,
    List<AchievementModel>? achievements,
    int? followersCount,
    int? followingCount,
    List<String>? following,
    String? bio,
    String? location,
    String? organization,
    bool? isFollowed,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      handle: handle ?? this.handle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      trustScore: trustScore ?? this.trustScore,
      verifiedContributions: verifiedContributions ?? this.verifiedContributions,
      accuracyRating: accuracyRating ?? this.accuracyRating,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      tier: tier ?? this.tier,
      deviceModel: deviceModel ?? this.deviceModel,
      hasAttestationKey: hasAttestationKey ?? this.hasAttestationKey,
      isMockLocationDetected: isMockLocationDetected ?? this.isMockLocationDetected,
      isRootedOrJailbroken: isRootedOrJailbroken ?? this.isRootedOrJailbroken,
      role: role ?? this.role,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      postsCreated: postsCreated ?? this.postsCreated,
      verificationsDone: verificationsDone ?? this.verificationsDone,
      commentsAdded: commentsAdded ?? this.commentsAdded,
      tagsCreated: tagsCreated ?? this.tagsCreated,
      achievements: achievements ?? this.achievements,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      following: following ?? this.following,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      organization: organization ?? this.organization,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}
