class JournalistModel {
  final String id;
  final String name;
  final String handle;
  final String avatarUrl;
  final int trustScore;
  final String title;
  final String organization;
  final String location;
  final int followersCount;
  final int verifiedReportsCount;
  final bool isFollowed;
  final String bio;

  const JournalistModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarUrl,
    required this.trustScore,
    required this.title,
    required this.organization,
    required this.location,
    required this.followersCount,
    required this.verifiedReportsCount,
    this.isFollowed = true,
    required this.bio,
  });

  JournalistModel copyWith({
    String? id,
    String? name,
    String? handle,
    String? avatarUrl,
    int? trustScore,
    String? title,
    String? organization,
    String? location,
    int? followersCount,
    int? verifiedReportsCount,
    bool? isFollowed,
    String? bio,
  }) {
    return JournalistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      trustScore: trustScore ?? this.trustScore,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      location: location ?? this.location,
      followersCount: followersCount ?? this.followersCount,
      verifiedReportsCount: verifiedReportsCount ?? this.verifiedReportsCount,
      isFollowed: isFollowed ?? this.isFollowed,
      bio: bio ?? this.bio,
    );
  }
}
