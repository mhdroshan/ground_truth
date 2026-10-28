import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../models/achievement_model.dart';
import '../models/journalist_model.dart';
import '../utils/geofence_math.dart';
import '../services/api_service.dart';
import 'location_service.dart';

enum FeedTab { trending, nearby, live, highActivity }
enum PostSortBy { mostReliable, latest, mostUpvoted }
enum HomeFeedFilter { interests, following, trending, all }

class VoteResult {
  final bool allowed;
  final String? message;
  final double? distanceMeters;
  final EventModel? event;
  final int userVote;
  final bool isRemoved;

  const VoteResult({
    required this.allowed,
    this.message,
    this.distanceMeters,
    this.event,
    this.userVote = 0,
    this.isRemoved = false,
  });

  static const success = VoteResult(allowed: true);
}

class AppAlert {
  final String id;
  final String title;
  final String message;
  final String eventId;
  final DateTime timestamp;
  final bool isCritical;
  bool isRead;

  AppAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.eventId,
    required this.timestamp,
    this.isCritical = false,
    this.isRead = false,
  });
}

class AppState extends ChangeNotifier {
  // SharedPreferences Keys for Session Persistence
  static const String _prefKeyIsLoggedIn = 'groundtruth_is_logged_in';
  static const String _prefKeyAuthToken = 'groundtruth_auth_token';
  static const String _prefKeyUserData = 'groundtruth_user_data';
  static const String _prefKeyFollowedUserIds = 'groundtruth_followed_user_ids';
  static const String _prefKeyUserPostVotes = 'groundtruth_user_post_votes';

  // Local user post votes: postId -> direction (1 or -1)
  final Map<String, int> _userVotesByPostId = {};
  int getUserVote(String postId) => _userVotesByPostId[postId] ?? 0;

  // Followed User IDs (Persisted real followed profiles)
  final Set<String> _followedUserIds = {};

  Set<String> get followedUserIds => Set.unmodifiable(_followedUserIds);
  bool isFollowing(String userId) => _followedUserIds.contains(userId);

  // Cached User Profiles
  final Map<String, UserModel> _cachedUserProfiles = {};

  // Authentication & Session State
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _authToken;
  String? get authToken => _authToken;

  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  String? _authError;
  String? get authError => _authError;

  String? _authSuccessMessage;
  String? get authSuccessMessage => _authSuccessMessage;

  void clearAuthError() {
    _authError = null;
    _authSuccessMessage = null;
    notifyListeners();
  }

  // Default guest profile when not logged in
  static const UserModel guestUser = UserModel(
    id: 'guest_user',
    name: 'Guest User',
    email: '',
    handle: '@guest',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop&q=80',
    trustScore: 50,
    verifiedContributions: 0,
    accuracyRating: 90.0,
    helpfulVotes: 0,
    tier: 'Guest',
    deviceModel: 'Web / Mobile Client',
    hasAttestationKey: false,
    xp: 0,
    level: 1,
    levelTitle: 'Unverified Guest',
    postsCreated: 0,
    verificationsDone: 0,
    commentsAdded: 0,
    tagsCreated: 0,
  );

  // Current user profile
  UserModel _currentUser = guestUser;

  UserModel get currentUser => _currentUser;

  Future<void> _savePersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyIsLoggedIn, _isLoggedIn);
      if (_authToken != null) {
        await prefs.setString(_prefKeyAuthToken, _authToken!);
      } else {
        await prefs.remove(_prefKeyAuthToken);
      }
      final userJson = json.encode(_currentUser.toJson());
      await prefs.setString(_prefKeyUserData, userJson);
    } catch (e) {
      if (kDebugMode) print('Failed to save auth session: $e');
    }
  }

  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyIsLoggedIn);
      await prefs.remove(_prefKeyAuthToken);
      await prefs.remove(_prefKeyUserData);
    } catch (e) {
      if (kDebugMode) print('Failed to clear auth session: $e');
    }
  }

  /// Restores saved authentication session so the user stays logged in across app restarts
  Future<void> loadPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_prefKeyIsLoggedIn) ?? false;
      final token = prefs.getString(_prefKeyAuthToken);
      final userDataStr = prefs.getString(_prefKeyUserData);

      if (isLoggedIn && userDataStr != null) {
        final Map<String, dynamic> userMap = json.decode(userDataStr);
        final loadedUser = UserModel.fromJson(userMap);
        _currentUser = loadedUser.copyWith(achievements: _currentUser.achievements);
        _authToken = token;
        _isLoggedIn = true;
        _syncAchievements();
        notifyListeners();

        // Background-refresh user profile from backend if online token exists
        if (token != null && token.isNotEmpty && !token.startsWith('local_token_')) {
          _refreshSessionFromBackend(token);
        }
      }

      // Restore followed users list (filter out legacy dummy seed IDs)
      final savedFollowed = prefs.getStringList(_prefKeyFollowedUserIds);
      if (savedFollowed != null) {
        _followedUserIds.clear();
        final cleanFollowed = savedFollowed.where((id) => !id.startsWith('auth_') && !id.startsWith('seed_')).toList();
        _followedUserIds.addAll(cleanFollowed);
        await prefs.setStringList(_prefKeyFollowedUserIds, cleanFollowed);
      }

      // Merge user's following list from account if logged in
      if (_currentUser.following.isNotEmpty) {
        _followedUserIds.addAll(_currentUser.following);
      }
      for (final id in _followedUserIds) {
        getUserProfile(id);
      }
      notifyListeners();

      // Restore user post votes
      final savedVotesStr = prefs.getString(_prefKeyUserPostVotes);
      if (savedVotesStr != null && savedVotesStr.isNotEmpty) {
        try {
          final decoded = json.decode(savedVotesStr) as Map<String, dynamic>;
          _userVotesByPostId.clear();
          decoded.forEach((key, val) {
            if (val is num) _userVotesByPostId[key] = val.toInt();
          });
          _applyUserVotesToLoadedPosts();
        } catch (_) {}
      }
    } catch (e) {
      if (kDebugMode) print('Failed to restore auth session: $e');
    }
  }

  Future<void> _refreshSessionFromBackend(String token) async {
    try {
      final remoteUser = await ApiService.fetchCurrentUser(token);
      if (remoteUser != null && !_disposed) {
        _currentUser = remoteUser.copyWith(achievements: _currentUser.achievements);
        if (_currentUser.following.isNotEmpty) {
          _followedUserIds.addAll(_currentUser.following);
          for (final fId in _currentUser.following) {
            getUserProfile(fId);
          }
          await _saveFollowedUserIds();
        }
        _syncAchievements();
        await _savePersistedSession();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Session refresh from backend skipped: $e');
    }
  }

  void _syncAchievements() {
    final updatedAchievements = <AchievementModel>[];
    for (final ach in _currentUser.achievements) {
      int current = ach.currentProgress;
      switch (ach.id) {
        case 'ach_ground_reporter_1':
        case 'ach_ground_reporter_2':
          current = _currentUser.postsCreated;
          break;
        case 'ach_truth_guardian_1':
        case 'ach_truth_guardian_2':
        case 'ach_consensus_master':
          current = _currentUser.verificationsDone;
          break;
        case 'ach_tag_pioneer_1':
        case 'ach_tag_pioneer_2':
          current = _currentUser.tagsCreated;
          break;
        case 'ach_community_voice_1':
        case 'ach_community_voice_2':
          current = _currentUser.commentsAdded;
          break;
        case 'ach_mastery_sentinel':
          current = _currentUser.xp;
          break;
      }
      final bool nowUnlocked = current >= ach.maxProgress;
      updatedAchievements.add(ach.copyWith(
        currentProgress: current,
        isUnlocked: nowUnlocked || ach.isUnlocked,
      ));
    }
    _currentUser = _currentUser.copyWith(achievements: updatedAchievements);
  }

  Future<bool> login(String identifier, String password) async {
    _isAuthenticating = true;
    _authError = null;
    _authSuccessMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.login(identifier: identifier, password: password);
      if (res.success && res.user != null) {
        final existingAchievements = _currentUser.achievements;
        _currentUser = res.user!.copyWith(achievements: existingAchievements);
        _authToken = res.token;
        _isLoggedIn = true;
        if (_currentUser.following.isNotEmpty) {
          _followedUserIds.addAll(_currentUser.following);
          for (final fId in _currentUser.following) {
            getUserProfile(fId);
          }
          await _saveFollowedUserIds();
        }
        _syncAchievements();
        await _savePersistedSession();
        _authSuccessMessage = res.message ?? 'Welcome back, ${_currentUser.name}';
        _isAuthenticating = false;
        notifyListeners();
        return true;
      } else {
        _authError = res.error ?? 'Invalid email or password.';
        _isAuthenticating = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _authError = 'Authentication error: $e';
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String handle,
    required String password,
    String? deviceModel,
    String? tier,
  }) async {
    _isAuthenticating = true;
    _authError = null;
    _authSuccessMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.register(
        name: name,
        email: email,
        handle: handle,
        password: password,
        deviceModel: deviceModel,
        tier: tier,
      );

      if (res.success && res.user != null) {
        final existingAchievements = _currentUser.achievements;
        _currentUser = res.user!.copyWith(achievements: existingAchievements);
        _authToken = res.token;
        _isLoggedIn = true;
        _syncAchievements();
        await _savePersistedSession();
        _authSuccessMessage = 'Account created successfully!';
        _isAuthenticating = false;
        notifyListeners();
        return true;
      } else {
        // Fallback local registration if network blocked
        final existingAchievements = _currentUser.achievements;
        final cleanHandle = handle.startsWith('@') ? handle : '@$handle';
        _currentUser = UserModel(
          id: 'user_local_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          email: email,
          handle: cleanHandle,
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
          trustScore: 90,
          verifiedContributions: 0,
          accuracyRating: 99.0,
          helpfulVotes: 0,
          tier: tier ?? 'Tier 1 Verified Senior Eyewitness',
          deviceModel: deviceModel ?? 'Standard Device',
          achievements: existingAchievements,
        );
        _authToken = 'local_token_${DateTime.now().millisecondsSinceEpoch}';
        _isLoggedIn = true;
        _syncAchievements();
        await _savePersistedSession();
        _authSuccessMessage = 'Account registered successfully!';
        _isAuthenticating = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _authError = 'Registration error: $e';
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _authToken = null;
    _currentUser = guestUser;
    notifyListeners();
    await _clearPersistedSession();
  }

  /// Updates personal info and profile picture for the current user, persisting locally and syncing to backend
  Future<bool> updateCurrentUserProfile({
    String? name,
    String? email,
    String? handle,
    String? avatarUrl,
    String? bio,
    String? location,
    String? organization,
  }) async {
    String cleanHandle = handle ?? _currentUser.handle;
    if (cleanHandle.trim().isNotEmpty && !cleanHandle.trim().startsWith('@')) {
      cleanHandle = '@${cleanHandle.trim()}';
    }

    final updated = _currentUser.copyWith(
      name: name?.trim() ?? _currentUser.name,
      email: email?.trim() ?? _currentUser.email,
      handle: cleanHandle,
      avatarUrl: avatarUrl ?? _currentUser.avatarUrl,
      bio: bio?.trim() ?? _currentUser.bio,
      location: location?.trim() ?? _currentUser.location,
      organization: organization?.trim() ?? _currentUser.organization,
    );

    _currentUser = updated;
    await _savePersistedSession();

    // Update posts authored by current user in local state so feed displays fresh author details
    if (name != null || avatarUrl != null) {
      for (final eventId in _postsByEvent.keys) {
        final list = _postsByEvent[eventId];
        if (list != null) {
          for (int i = 0; i < list.length; i++) {
            if (isCurrentUserPost(list[i])) {
              list[i] = list[i].copyWith(
                authorName: name?.trim() ?? list[i].authorName,
                authorAvatar: avatarUrl ?? list[i].authorAvatar,
              );
            }
          }
        }
      }
    }

    notifyListeners();

    // Sync to backend if logged in and not temporary local guest
    if (_isLoggedIn &&
        _currentUser.id.isNotEmpty &&
        !_currentUser.id.startsWith('user_local_') &&
        _currentUser.id != 'guest_user') {
      try {
        final res = await ApiService.updateUserProfile(
          userId: _currentUser.id,
          token: _authToken,
          name: name?.trim(),
          email: email?.trim(),
          handle: cleanHandle,
          avatarUrl: avatarUrl,
          bio: bio?.trim(),
          location: location?.trim(),
          organization: organization?.trim(),
        );
        if (res.success && res.user != null) {
          _currentUser = res.user!.copyWith(achievements: _currentUser.achievements);
          await _savePersistedSession();
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) print('Failed to sync updated profile to backend: $e');
      }
    }

    return true;
  }

  // Active filter states
  FeedTab _selectedFeedTab = FeedTab.trending;
  FeedTab get selectedFeedTab => _selectedFeedTab;

  EventCategory? _selectedCategory;
  EventCategory? get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  PostSortBy _postSortBy = PostSortBy.mostReliable;
  PostSortBy get postSortBy => _postSortBy;

  PostType? _postTypeFilter;
  PostType? get postTypeFilter => _postTypeFilter;

  // Currently focused event
  String? _selectedEventId;
  String? get selectedEventId => _selectedEventId;

  // Seed events
  static const Set<String> dummyTagIds = {
    'delhi_protest_2026',
    'kerala_floods_2026',
    'london_fire_2026',
    'tokyo_earthquake_2026',
    'election_counting_2026',
    'paris_strike_2026',
    'sf_climate_2026',
    'sydney_heatwave_2026',
  };

  static bool isDummyTag(String tagId) => dummyTagIds.contains(tagId);

  List<EventModel> _events = [];
  List<EventModel> get events => _events;

  /// Returns only real events from MongoDB or created by user (excludes mock dummy tags)
  List<EventModel> get realEvents => _events.where((e) => !dummyTagIds.contains(e.id)).toList();

  // Seed posts keyed by eventId
  final Map<String, List<PostModel>> _postsByEvent = {};

  // Seed comments keyed by postId
  final Map<String, List<CommentModel>> _commentsByPost = {};

  // Alerts
  final List<AppAlert> _alerts = [];
  List<AppAlert> get alerts => _alerts;

  // Latest unlocked achievement for celebration toast
  AchievementModel? _recentlyUnlockedAchievement;
  AchievementModel? get recentlyUnlockedAchievement => _recentlyUnlockedAchievement;

  void clearRecentAchievement() {
    _recentlyUnlockedAchievement = null;
    notifyListeners();
  }

  // Interests selected by user
  static final Set<EventCategory> _defaultInterests = {
    EventCategory.protest,
    EventCategory.naturalDisaster,
    EventCategory.weather,
    EventCategory.election,
    EventCategory.fire,
  };

  Set<EventCategory> _selectedInterests = {
    EventCategory.protest,
    EventCategory.naturalDisaster,
    EventCategory.weather,
    EventCategory.election,
    EventCategory.fire,
  };

  Set<EventCategory> get selectedInterests {
    if (_selectedInterests.isEmpty) {
      _selectedInterests = Set.from(_defaultInterests);
    }
    return _selectedInterests;
  }

  void toggleInterest(EventCategory cat) {
    final set = selectedInterests;
    if (set.contains(cat)) {
      if (set.length > 1) {
        set.remove(cat);
      }
    } else {
      set.add(cat);
    }
    _selectedInterests = set;
    notifyListeners();
  }

  bool isInterestSelected(EventCategory cat) => selectedInterests.contains(cat);

  void selectAllInterests() {
    _selectedInterests = EventCategory.values.toSet();
    notifyListeners();
  }

  // Journalists / Writers Seed Data
  static const List<JournalistModel> _seedJournalists = [
    JournalistModel(
      id: 'auth_rajesh',
      name: 'Rajesh K. Sandhu',
      handle: '@rajesh_sandhu',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
      trustScore: 97,
      title: 'Senior Ground Reporter',
      organization: 'The Ground Wire',
      location: 'New Delhi, India',
      followersCount: 18400,
      verifiedReportsCount: 142,
      isFollowed: true,
      bio: 'Covering grassroots demonstrations, civil assemblies and public policy with live telemetry verification.',
    ),
    JournalistModel(
      id: 'auth_ananya',
      name: 'Ananya Sharma',
      handle: '@ananya_reports',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
      trustScore: 95,
      title: 'Investigative Eyewitness',
      organization: 'Civic Dispatch',
      location: 'New Delhi, India',
      followersCount: 26500,
      verifiedReportsCount: 210,
      isFollowed: true,
      bio: 'Fact-checking breaking incidents with forensic device attestation and verified media hashes.',
    ),
    JournalistModel(
      id: 'auth_rahul_k',
      name: 'Dr. Rahul Mathew',
      handle: '@dr_rahul_mathew',
      avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&auto=format&fit=crop&q=80',
      trustScore: 98,
      title: 'Disaster Response Specialist',
      organization: 'Kerala Emergency Network',
      location: 'Wayanad, India',
      followersCount: 12300,
      verifiedReportsCount: 88,
      isFollowed: true,
      bio: 'Medical officer and first responder coordinating live ground logistics during cloudbursts and landslides.',
    ),
    JournalistModel(
      id: 'auth_meera',
      name: 'Meera Nambiar',
      handle: '@meera_field',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&auto=format&fit=crop&q=80',
      trustScore: 92,
      title: 'Public Welfare Observer',
      organization: 'Truth Watch India',
      location: 'New Delhi, India',
      followersCount: 9400,
      verifiedReportsCount: 64,
      isFollowed: true,
      bio: 'Reporting on emergency medical camps, aid distribution, and civic logistics.',
    ),
    JournalistModel(
      id: 'auth_kenji',
      name: 'Kenji Sato',
      handle: '@kenji_tokyo_eye',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
      trustScore: 94,
      title: 'Urban Seismic & Transit Lead',
      organization: 'Disaster Pulse Japan',
      location: 'Tokyo, Japan',
      followersCount: 34200,
      verifiedReportsCount: 312,
      isFollowed: false,
      bio: 'Real-time seismic tremor and transit infrastructure verification across the Tokyo Metropolitan area.',
    ),
    JournalistModel(
      id: 'auth_elena',
      name: 'Elena Rostova',
      handle: '@elena_fielddesk',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
      trustScore: 91,
      title: 'European Field Correspondent',
      organization: 'Global Observer Desk',
      location: 'London, UK',
      followersCount: 41000,
      verifiedReportsCount: 420,
      isFollowed: false,
      bio: 'Covering structural emergencies, major transit strikes and city-wide public demonstrations.',
    ),
  ];

  List<JournalistModel> _journalists = List.from(_seedJournalists);

  List<JournalistModel> get journalists {
    if (_journalists.isEmpty) {
      _journalists = List.from(_seedJournalists);
    }
    return _journalists;
  }

  List<JournalistModel> get followedJournalists {
    return journalists.where((j) => j.isFollowed).toList();
  }

  void _syncJournalistFollowStates() {
    final list = List<JournalistModel>.from(journalists);
    for (int i = 0; i < list.length; i++) {
      final isFollowed = _followedUserIds.contains(list[i].id);
      if (list[i].isFollowed != isFollowed) {
        list[i] = list[i].copyWith(isFollowed: isFollowed);
      }
    }
    _journalists = list;
  }

  Future<void> _saveFollowedUserIds() async {
    _syncJournalistFollowStates();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKeyFollowedUserIds, _followedUserIds.toList());
    } catch (e) {
      if (kDebugMode) print('Failed to save followed users: $e');
    }
  }

  Future<void> _saveUserVotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyUserPostVotes, json.encode(_userVotesByPostId));
    } catch (e) {
      if (kDebugMode) print('Failed to save user votes: $e');
    }
  }

  void _applyUserVotesToLoadedPosts() {
    for (final entry in _postsByEvent.entries) {
      for (int i = 0; i < entry.value.length; i++) {
        final p = entry.value[i];
        if (isCurrentUserPost(p)) {
          _userVotesByPostId.remove(p.id);
          if (p.userVote != 0) {
            entry.value[i] = p.copyWith(userVote: 0);
          }
        } else if (_userVotesByPostId.containsKey(p.id)) {
          final recordedVote = _userVotesByPostId[p.id]!;
          if (p.userVote != recordedVote) {
            entry.value[i] = p.copyWith(userVote: recordedVote);
          }
        }
      }
    }
  }

  void toggleFollowJournalist(String id) {
    toggleFollowUser(id);
  }

  /// Toggle follow state for any eyewitness contributor or journalist
  Future<bool> toggleFollowUser(
    String userId, {
    String? userName,
    String? userAvatar,
    int? userTrustScore,
    bool? isJournalist,
  }) async {
    if (userId == _currentUser.id) return false;

    final wasFollowing = _followedUserIds.contains(userId);
    final nowFollowing = !wasFollowing;

    if (nowFollowing) {
      _followedUserIds.add(userId);
    } else {
      _followedUserIds.remove(userId);
    }

    // Update journalists list if applicable
    final jList = List<JournalistModel>.from(journalists);
    final jIdx = jList.indexWhere((j) => j.id == userId);
    if (jIdx != -1) {
      final currentJ = jList[jIdx];
      jList[jIdx] = currentJ.copyWith(
        isFollowed: nowFollowing,
        followersCount: (currentJ.followersCount + (nowFollowing ? 1 : -1)).clamp(0, 9999999),
      );
      _journalists = jList;
    }

    // Update cached user profile if present
    if (_cachedUserProfiles.containsKey(userId)) {
      final currentProfile = _cachedUserProfiles[userId]!;
      _cachedUserProfiles[userId] = currentProfile.copyWith(
        isFollowed: nowFollowing,
        followersCount: (currentProfile.followersCount + (nowFollowing ? 1 : -1)).clamp(0, 9999999),
      );
    }

    // Update currentUser following count and list
    final updatedFollowingCount = (_currentUser.followingCount + (nowFollowing ? 1 : -1)).clamp(0, 999999);
    final updatedFollowing = List<String>.from(_currentUser.following);
    if (nowFollowing) {
      if (!updatedFollowing.contains(userId)) updatedFollowing.add(userId);
      getUserProfile(userId, fallbackName: userName, fallbackAvatar: userAvatar, fallbackTrustScore: userTrustScore);
    } else {
      updatedFollowing.remove(userId);
    }
    _currentUser = _currentUser.copyWith(
      followingCount: updatedFollowingCount,
      following: updatedFollowing,
    );

    await _saveFollowedUserIds();
    notifyListeners();

    // Fire-and-forget backend follow toggle
    try {
      ApiService.toggleFollowUser(
        targetUserId: userId,
        token: _authToken,
        followerId: _currentUser.id,
        followerName: _currentUser.name,
      ).then((res) {
        if (res != null && res['followersCount'] != null && _cachedUserProfiles.containsKey(userId)) {
          final count = (res['followersCount'] as num).toInt();
          _cachedUserProfiles[userId] = _cachedUserProfiles[userId]!.copyWith(followersCount: count);
          notifyListeners();
        }
      });
    } catch (_) {}

    return nowFollowing;
  }

  /// Retrieve or synthesize a rich UserModel for any contributor
  UserModel getUserProfile(
    String userId, {
    String? fallbackName,
    String? fallbackAvatar,
    int? fallbackTrustScore,
    bool? isVerifiedJournalist,
    String? fallbackBio,
    String? fallbackLocation,
    String? fallbackOrganization,
  }) {
    if (userId == _currentUser.id) {
      return _currentUser;
    }

    // Check cached profile
    if (_cachedUserProfiles.containsKey(userId)) {
      return _cachedUserProfiles[userId]!.copyWith(
        isFollowed: isFollowing(userId),
      );
    }

    // Check seed journalists
    final jMatch = journalists.where((j) => j.id == userId).firstOrNull;
    if (jMatch != null) {
      final profile = UserModel(
        id: jMatch.id,
        name: jMatch.name,
        email: '${jMatch.handle.replaceFirst('@', '')}@groundtruth.org',
        handle: jMatch.handle,
        avatarUrl: jMatch.avatarUrl,
        trustScore: jMatch.trustScore,
        verifiedContributions: jMatch.verifiedReportsCount,
        accuracyRating: 98.8,
        helpfulVotes: jMatch.followersCount ~/ 10,
        tier: jMatch.title,
        deviceModel: 'Pixel 9 Pro (Hardware Keystore Attested)',
        hasAttestationKey: true,
        role: 'journalist',
        xp: 2800,
        level: 6,
        levelTitle: 'Lead Field Reporter',
        postsCreated: allPosts.where((p) => p.authorId == jMatch.id).length,
        verificationsDone: 180,
        commentsAdded: 64,
        tagsCreated: 5,
        followersCount: jMatch.followersCount,
        followingCount: 34,
        bio: jMatch.bio,
        location: jMatch.location,
        organization: jMatch.organization,
        isFollowed: isFollowing(userId),
      );
      _cachedUserProfiles[userId] = profile;
      return profile;
    }

    // Check existing posts for author info
    final authorPost = allPosts.where((p) => p.authorId == userId).firstOrNull;
    final name = fallbackName ?? authorPost?.authorName ?? 'Verified Eyewitness';
    final avatar = fallbackAvatar ?? authorPost?.authorAvatar ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80';
    final trust = fallbackTrustScore ?? authorPost?.authorTrustScore ?? 90;
    final isJ = isVerifiedJournalist ?? authorPost?.authorIsVerifiedJournalist ?? false;
    final handle = '@${name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    final authorPostsCount = allPosts.where((p) => p.authorId == userId).length;

    final synthesizedUser = UserModel(
      id: userId,
      name: name,
      email: '',
      handle: handle,
      avatarUrl: avatar,
      trustScore: trust,
      verifiedContributions: authorPostsCount,
      accuracyRating: 98.4,
      helpfulVotes: 32,
      tier: isJ ? 'Verified Field Reporter' : 'Tier 1 Verified Senior Eyewitness',
      deviceModel: 'Hardware Keystore Attested',
      hasAttestationKey: true,
      role: isJ ? 'journalist' : 'eyewitness',
      xp: 600,
      level: 2,
      levelTitle: 'Verified Field Scout',
      postsCreated: authorPostsCount,
      verificationsDone: 14,
      commentsAdded: 8,
      tagsCreated: 1,
      followersCount: 142,
      followingCount: 29,
      bio: fallbackBio ?? 'Active on-the-ground contributor with verified ground telemetry.',
      location: fallbackLocation ?? 'On-Site Verification Point',
      organization: fallbackOrganization,
      isFollowed: isFollowing(userId),
    );

    _cachedUserProfiles[userId] = synthesizedUser;

    // Asynchronously fetch from server to hydrate latest remote data
    _fetchRemoteUserProfile(userId);

    return synthesizedUser;
  }

  Future<void> _fetchRemoteUserProfile(String userId) async {
    try {
      final remote = await ApiService.fetchUserProfile(
        userId,
        token: _authToken,
        followerId: _currentUser.id,
      );
      if (remote != null && !_disposed) {
        _cachedUserProfiles[userId] = remote.copyWith(
          isFollowed: isFollowing(userId),
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  List<UserModel> getFollowedProfiles() {
    final List<UserModel> list = [];
    final seen = <String>{};
    for (final id in _followedUserIds) {
      if (id == _currentUser.id || id.startsWith('auth_') || id.startsWith('seed_')) continue;
      if (seen.contains(id)) continue;
      seen.add(id);
      list.add(getUserProfile(id));
    }
    return list;
  }

  // Home Screen Filter States
  HomeFeedFilter _homeFeedFilter = HomeFeedFilter.interests;
  HomeFeedFilter get homeFeedFilter => _homeFeedFilter;

  void setHomeFeedFilter(HomeFeedFilter filter) {
    _homeFeedFilter = filter;
    _homeWriterFilterId = null;
    _homeTagFilter = null;
    notifyListeners();
  }

  String? _homeWriterFilterId;
  String? get homeWriterFilterId => _homeWriterFilterId;

  void setHomeWriterFilter(String? writerId) {
    _homeWriterFilterId = writerId;
    if (writerId != null) {
      _homeTagFilter = null;
    }
    notifyListeners();
  }

  String? _homeTagFilter;
  String? get homeTagFilter => _homeTagFilter;

  void setHomeTagFilter(String? tag) {
    _homeTagFilter = tag;
    if (tag != null) {
      _homeWriterFilterId = null;
    }
    notifyListeners();
  }

  // Query posts
  List<PostModel> get allPosts {
    final List<PostModel> all = [];
    for (final posts in _postsByEvent.values) {
      all.addAll(posts);
    }
    return all;
  }

  EventModel? getEventById(String eventId) {
    try {
      return _events.firstWhere((e) => e.id == eventId);
    } catch (_) {
      return null;
    }
  }

  EventModel? getEventForPost(PostModel post) {
    // 1. Direct ID match
    final byId = getEventById(post.eventId);
    if (byId != null) return byId;

    // 2. Tag name match
    if (post.tagName != null && post.tagName!.isNotEmpty) {
      final cleanTag = post.tagName!.replaceAll('#', '').trim().toLowerCase();
      try {
        return _events.firstWhere((e) =>
            e.tagName.replaceAll('#', '').trim().toLowerCase() == cleanTag ||
            e.title.toLowerCase() == cleanTag);
      } catch (_) {}
    }

    // 3. Post location match inside active event boundary
    try {
      return _events.firstWhere((e) => e.isUserInside(post.location));
    } catch (_) {}

    return null;
  }

  bool isUserInsidePostGeofence(PostModel post, GeoPoint userLocation) {
    final event = getEventForPost(post);
    if (event != null) {
      return event.isUserInside(userLocation);
    }
    // Fallback: If no event is bound, check against the post's physical coordinates within standard 2000m radius
    final distanceMeters = GeofenceMath.distanceBetweenPoints(userLocation, post.location);
    return distanceMeters <= 2000.0;
  }

  double distanceToPostGeofence(PostModel post, GeoPoint userLocation) {
    final event = getEventForPost(post);
    if (event != null) {
      return event.distanceFromUser(userLocation);
    }
    return GeofenceMath.distanceBetweenPoints(userLocation, post.location);
  }

  List<PostModel> getHomePosts() {
    List<PostModel> posts = allPosts;

    // If explicit writer filter is active
    if (_homeWriterFilterId != null) {
      final filtered = posts.where((p) => p.authorId == _homeWriterFilterId).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }

    // If explicit tag filter is active
    if (_homeTagFilter != null) {
      final ev = _events.where((e) => e.tagName.toLowerCase() == _homeTagFilter!.toLowerCase()).firstOrNull;
      if (ev != null) {
        final filtered = List<PostModel>.from(_postsByEvent[ev.id] ?? []);
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return filtered;
      }
    }

    // Otherwise apply home tab filter
    switch (_homeFeedFilter) {
      case HomeFeedFilter.interests:
        posts = posts.where((p) {
          final ev = getEventById(p.eventId);
          if (ev == null) return false;
          return _selectedInterests.contains(ev.category);
        }).toList();
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case HomeFeedFilter.following:
        posts = posts.where((p) => _followedUserIds.contains(p.authorId)).toList();
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case HomeFeedFilter.trending:
        posts = List.from(posts);
        posts.sort((a, b) => (b.score * 2 + b.commentsCount).compareTo(a.score * 2 + a.commentsCount));
        break;

      case HomeFeedFilter.all:
        posts = List.from(posts);
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return posts;
  }

  List<PostModel> getWorldwideTrendingPosts({String sortBy = 'trending'}) {
    final list = List<PostModel>.from(allPosts);
    switch (sortBy) {
      case 'mostComments':
        list.sort((a, b) => b.commentsCount.compareTo(a.commentsCount));
        break;
      case 'mostLikes':
        list.sort((a, b) => b.upvotes.compareTo(a.upvotes));
        break;
      case 'trending':
      default:
        list.sort((a, b) => (b.upvotes + (b.commentsCount * 2)).compareTo(a.upvotes + (a.commentsCount * 2)));
        break;
    }
    return list;
  }

  /// Checks whether a given post was authored / created by the current user
  bool isCurrentUserPost(PostModel post) {
    if (post.authorId.isNotEmpty && post.authorId == _currentUser.id) {
      return true;
    }
    if (_currentUser.name.isNotEmpty &&
        post.authorName.trim().toLowerCase() == _currentUser.name.trim().toLowerCase()) {
      return true;
    }
    if ((_currentUser.id == 'user_dev_01' || _currentUser.id == 'guest_user') &&
        (post.authorId == 'user_dev_01' || post.authorId == 'guest_user')) {
      return true;
    }
    return false;
  }

  List<PostModel> getMyWrittenPosts() {
    final my = allPosts.where((p) => isCurrentUserPost(p)).toList();
    my.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return my;
  }

  /// Retrieve all verified posts authored by a specific user/journalist
  List<PostModel> getPostsByAuthor(String authorId, {String? authorName}) {
    final posts = allPosts.where((p) {
      if (p.authorId == authorId) return true;
      if (authorName != null &&
          authorName.trim().isNotEmpty &&
          p.authorName.trim().toLowerCase() == authorName.trim().toLowerCase()) {
        return true;
      }
      return false;
    }).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  bool _isLoadingFromDb = false;
  bool get isLoadingFromDb => _isLoadingFromDb;

  bool _disposed = false;

  bool get _isTestEnvironment {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadRemoteDatabaseData() async {
    _isLoadingFromDb = true;
    notifyListeners();

    try {
      // 1. Fetch tags from MongoDB `tags` collection
      var remoteTags = await ApiService.fetchRemoteTags();
      var remotePosts = await ApiService.fetchRemotePosts();

      // If initial fetch failed/timed out (e.g. Render cold start), retry once when not in test
      if (!_disposed && !_isTestEnvironment && remoteTags == null && remotePosts == null) {
        await Future.delayed(const Duration(seconds: 2));
        if (!_disposed) {
          remoteTags = await ApiService.fetchRemoteTags();
          remotePosts = await ApiService.fetchRemotePosts(userId: _currentUser.id);
        }
      }

      if (remoteTags != null) {
        _events = remoteTags;
        if (_selectedEventId == null || !_events.any((e) => e.id == _selectedEventId)) {
          _selectedEventId = _events.isNotEmpty ? _events.first.id : null;
        }
      }

      if (remotePosts != null && remotePosts.isNotEmpty) {
        _postsByEvent.clear();
        for (final post in remotePosts) {
          final evId = post.eventId;
          if (_postsByEvent[evId] == null) {
            _postsByEvent[evId] = [];
          }
          final isOwn = isCurrentUserPost(post);
          final resolvedVote = isOwn ? 0 : (_userVotesByPostId[post.id] ?? post.userVote);
          if (isOwn) {
            _userVotesByPostId.remove(post.id);
          } else if (resolvedVote != 0 && !_userVotesByPostId.containsKey(post.id)) {
            _userVotesByPostId[post.id] = resolvedVote;
          }
          _postsByEvent[evId]!.add(post.copyWith(userVote: resolvedVote));
        }
        _saveUserVotes();
      }
    } catch (e) {
      if (kDebugMode) print('loadRemoteDatabaseData error: $e');
    } finally {
      _isLoadingFromDb = false;
      notifyListeners();
    }
  }

  Future<void> loadCommentsForPost(String postId) async {
    try {
      final comments = await ApiService.fetchCommentsForPost(postId);
      if (comments != null) {
        _commentsByPost[postId] = comments;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('loadCommentsForPost error: $e');
    }
  }

  AppState({bool autoLoadRemote = true, bool autoRestoreSession = true}) {
    _initializeData();
    _initAchievements();
    if (autoRestoreSession) {
      loadPersistedSession();
    }
    if (autoLoadRemote) {
      loadRemoteDatabaseData();
    }
  }

  void selectFeedTab(FeedTab tab) {
    _selectedFeedTab = tab;
    notifyListeners();
  }

  void selectCategory(EventCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectEvent(String? eventId) {
    _selectedEventId = eventId;
    notifyListeners();
  }

  void setPostSortBy(PostSortBy sortBy) {
    _postSortBy = sortBy;
    notifyListeners();
  }

  void setPostTypeFilter(PostType? filter) {
    _postTypeFilter = filter;
    notifyListeners();
  }

  EventModel? get currentEvent {
    if (_selectedEventId == null) return null;
    try {
      return _events.firstWhere((e) => e.id == _selectedEventId);
    } catch (_) {
      return null;
    }
  }

  /// Returns all events the user is physically inside right now
  List<EventModel> getEventsUserIsInside(GeoPoint userLocation) {
    return _events.where((e) => e.isUserInside(userLocation)).toList();
  }

  /// Checks if user is inside any active event tag
  bool isUserInAnyTag(GeoPoint userLocation) {
    return _events.any((e) => e.isUserInside(userLocation));
  }

  /// Returns the current location event to highlight for writing reports
  EventModel? getActiveCurrentLocationEvent(GeoPoint userLocation) {
    final insideList = getEventsUserIsInside(userLocation);
    if (insideList.isNotEmpty) {
      // Prioritize selected event if inside, otherwise first inside
      if (_selectedEventId != null) {
        final found = insideList.where((e) => e.id == _selectedEventId);
        if (found.isNotEmpty) return found.first;
      }
      return insideList.first;
    }
    return null;
  }

  List<EventModel> getFilteredEvents(GeoPoint userLocation) {
    List<EventModel> list = List.from(_events);

    // Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) =>
          e.title.toLowerCase().contains(q) ||
          e.tagName.toLowerCase().contains(q) ||
          e.city.toLowerCase().contains(q) ||
          e.country.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          e.category.label.toLowerCase().contains(q)).toList();
    }

    // Category filter
    if (_selectedCategory != null) {
      list = list.where((e) => e.category == _selectedCategory).toList();
    }

    // Tab filter
    switch (_selectedFeedTab) {
      case FeedTab.trending:
        list.sort((a, b) => (b.activeContributors + b.totalPosts).compareTo(a.activeContributors + a.totalPosts));
        break;
      case FeedTab.nearby:
        list.sort((a, b) => a.distanceFromUser(userLocation).compareTo(b.distanceFromUser(userLocation)));
        break;
      case FeedTab.live:
        list = list.where((e) => e.status == EventStatus.live || e.status == EventStatus.breaking).toList();
        break;
      case FeedTab.highActivity:
        list = list.where((e) => e.isHighActivity || e.activeContributors > 1000).toList();
        break;
    }

    return list;
  }

  List<PostModel> getPostsForEvent(String eventId) {
    List<PostModel> list = List<PostModel>.from(_postsByEvent[eventId] ?? []);

    // Fallback if key differs (e.g. tagId vs eventId or MongoDB ObjectId vs local slug)
    if (list.isEmpty) {
      final ev = getEventById(eventId);
      list = allPosts.where((p) {
        if (p.eventId == eventId) return true;
        if (ev != null) {
          if (p.tagName != null &&
              (p.tagName!.toLowerCase() == ev.tagName.toLowerCase() ||
               p.tagName!.replaceAll('#', '').toLowerCase() == ev.tagName.replaceAll('#', '').toLowerCase())) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    // Filter by type
    var filtered = list;
    if (_postTypeFilter != null) {
      filtered = filtered.where((p) => p.type == _postTypeFilter).toList();
    }

    // Sort
    switch (_postSortBy) {
      case PostSortBy.mostReliable:
        filtered.sort((a, b) => b.reliabilityScore.compareTo(a.reliabilityScore));
        break;
      case PostSortBy.latest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case PostSortBy.mostUpvoted:
        filtered.sort((a, b) => b.score.compareTo(a.score));
        break;
    }

    return filtered;
  }

  List<CommentModel> getCommentsForPost(String postId) {
    return _commentsByPost[postId] ?? [];
  }

  /// STRICT REQUIREMENT: Upvote (Like) or Downvote (Dislike)
  /// ONLY permitted if the user is physically inside that tag/post's geofence radius.
  VoteResult votePost({
    required String eventId,
    required String postId,
    required int direction,
    required GeoPoint userLocation,
  }) {
    // 1. Locate target post across _postsByEvent or allPosts
    PostModel? post;
    if (_postsByEvent.containsKey(eventId)) {
      final idx = _postsByEvent[eventId]!.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        post = _postsByEvent[eventId]![idx];
      }
    }

    if (post == null) {
      for (final entry in _postsByEvent.entries) {
        final idx = entry.value.indexWhere((p) => p.id == postId);
        if (idx != -1) {
          post = entry.value[idx];
          break;
        }
      }
    }

    if (post == null) {
      return const VoteResult(allowed: false, message: 'Post not found');
    }

    // 2. Disallow author voting on their own posts
    if (isCurrentUserPost(post)) {
      return const VoteResult(
        allowed: false,
        message: 'You cannot vote on your own post.',
      );
    }

    // 3. Resolve Event boundary & check geofence
    final event = getEventById(eventId) ?? getEventForPost(post);
    final bool isInside = event != null
        ? event.isUserInside(userLocation)
        : isUserInsidePostGeofence(post, userLocation);

    if (!isInside) {
      final double distanceMeters = event != null
          ? event.distanceFromUser(userLocation)
          : GeofenceMath.distanceBetweenPoints(userLocation, post.location);
      final tagLabel = event?.tagName ?? post.tagName ?? 'the post\'s geofence';
      final radiusLabel = event?.formattedRadius ?? '2 km';
      return VoteResult(
        allowed: false,
        message: 'Only eyewitnesses physically inside $tagLabel ($radiusLabel) can verify or dispute news.',
        distanceMeters: distanceMeters,
        event: event,
      );
    }

    // 3. Update vote state
    final int currentVote = _userVotesByPostId[postId] ?? post.userVote;
    int newUpvotes = post.upvotes;
    int newDownvotes = post.downvotes;
    int newUserVote = 0;
    bool isRemoved = false;

    if (currentVote == direction) {
      // Toggle off / Undo vote: Clicking again removes that vote
      if (direction == 1) newUpvotes = (newUpvotes - 1).clamp(0, 999999);
      if (direction == -1) newDownvotes = (newDownvotes - 1).clamp(0, 999999);
      newUserVote = 0;
      _userVotesByPostId.remove(postId);
      isRemoved = true;
    } else {
      // Revert previous vote if any
      if (currentVote == 1) newUpvotes = (newUpvotes - 1).clamp(0, 999999);
      if (currentVote == -1) newDownvotes = (newDownvotes - 1).clamp(0, 999999);

      // Apply new vote
      if (direction == 1) newUpvotes += 1;
      if (direction == -1) newDownvotes += 1;
      newUserVote = direction;
      _userVotesByPostId[postId] = direction;
      isRemoved = false;

      // Gamification progress for on-site verification
      _awardActivity(
        xpGain: 20,
        verificationsDelta: 1,
      );
    }

    _saveUserVotes();

    post.upvotes = newUpvotes;
    post.downvotes = newDownvotes;
    post.userVote = newUserVote;

    final updatedPost = post.copyWith(
      upvotes: newUpvotes,
      downvotes: newDownvotes,
      userVote: newUserVote,
    );

    // Update in _postsByEvent
    for (final entry in _postsByEvent.entries) {
      final idx = entry.value.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        entry.value[idx] = updatedPost;
      }
    }

    notifyListeners();

    // 4. Trigger asynchronous sync to backend API
    ApiService.submitVote(
      postId: postId,
      direction: newUserVote,
      userId: _currentUser.id,
      latitude: userLocation.latitude,
      longitude: userLocation.longitude,
    ).then((remotePost) {
      if (remotePost != null) {
        for (final entry in _postsByEvent.entries) {
          final curIdx = entry.value.indexWhere((p) => p.id == postId);
          if (curIdx != -1) {
            entry.value[curIdx] = entry.value[curIdx].copyWith(
              upvotes: remotePost.upvotes,
              downvotes: remotePost.downvotes,
              userVote: newUserVote,
            );
          }
        }
        notifyListeners();
      }
    }).catchError((err) {
      if (kDebugMode) print('Background submitVote error: $err');
    });

    return VoteResult(
      allowed: true,
      userVote: newUserVote,
      isRemoved: isRemoved,
    );
  }

  /// Vote in an interactive poll (Strictly requires event presence)
  VoteResult votePoll({
    required String eventId,
    required String postId,
    required String optionId,
    required GeoPoint userLocation,
  }) {
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) {
      return const VoteResult(allowed: false, message: 'Tag / Event not found');
    }
    final event = _events[eventIndex];
    if (!event.isUserInside(userLocation)) {
      final double distanceMeters = event.distanceFromUser(userLocation);
      return VoteResult(
        allowed: false,
        message: 'Only eyewitnesses physically inside ${event.tagName} (${event.formattedRadius}) can participate in polls.',
        distanceMeters: distanceMeters,
        event: event,
      );
    }

    final posts = _postsByEvent[eventId];
    if (posts == null) {
      return const VoteResult(allowed: false, message: 'Post not found');
    }

    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) {
      return const VoteResult(allowed: false, message: 'Post not found');
    }

    final post = posts[index];
    if (post.pollOptions == null) {
      return const VoteResult(allowed: false, message: 'Not an active poll');
    }
    // Disallow author voting on their own poll
    if (isCurrentUserPost(post)) {
      return const VoteResult(allowed: false, message: 'You cannot participate in your own poll');
    }
    if (post.userVotedPollOptionId != null) {
      return const VoteResult(allowed: false, message: 'You have already voted in this poll');
    }

    final optIndex = post.pollOptions!.indexWhere((o) => o.id == optionId);
    if (optIndex != -1) {
      post.pollOptions![optIndex].votes++;
      final updated = post.copyWith(
        pollOptions: post.pollOptions,
        userVotedPollOptionId: optionId,
      );
      posts[index] = updated;

      _awardActivity(xpGain: 15, verificationsDelta: 1);
      notifyListeners();

      // Trigger asynchronous sync to backend API
      ApiService.submitPollVote(
        postId: postId,
        optionId: optionId,
        userId: _currentUser.id,
        latitude: userLocation.latitude,
        longitude: userLocation.longitude,
      ).then((remotePost) {
        if (remotePost != null) {
          final curIdx = posts.indexWhere((p) => p.id == postId);
          if (curIdx != -1) {
            posts[curIdx] = remotePost;
            notifyListeners();
          }
        }
      }).catchError((err) {
        if (kDebugMode) print('Background submitPollVote error: $err');
      });

      return VoteResult.success;
    }
    return const VoteResult(allowed: false, message: 'Poll option not found');
  }

  /// Add post (Strictly requires user to be physically inside the event radius)
  bool addPost({
    required String eventId,
    required PostType type,
    required String content,
    String? mediaUrl,
    String? videoThumbnailUrl,
    int? audioDurationSeconds,
    List<double>? waveform,
    List<PollOption>? pollOptions,
    required LocationService locationService,
    EventModel? event,
  }) {
    final effectiveEvent = event ?? _events.where((e) => e.id == eventId).firstOrNull ?? _events.first;
    final isInside = effectiveEvent.isUserInside(locationService.currentLocation);
    final eval = locationService.evaluateVerificationForEvent(effectiveEvent);

    if (!isInside && !eval.canPost) {
      return false; // Rejection enforced at engine level
    }

    final verification = locationService.createVerificationDetails(effectiveEvent);
    final tagLocation = effectiveEvent.country.isNotEmpty && !effectiveEvent.city.toLowerCase().contains(effectiveEvent.country.toLowerCase())
        ? '${effectiveEvent.city}, ${effectiveEvent.country}'
        : effectiveEvent.city;

    final newPost = PostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      tagName: effectiveEvent.tagName,
      authorId: _currentUser.id,
      authorName: _currentUser.name,
      authorAvatar: _currentUser.avatarUrl,
      authorTrustScore: _currentUser.trustScore,
      authorIsVerifiedJournalist: _currentUser.isJournalist,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      videoThumbnailUrl: videoThumbnailUrl,
      audioDurationSeconds: audioDurationSeconds,
      waveform: waveform,
      pollOptions: pollOptions,
      createdAt: DateTime.now(),
      location: locationService.currentLocation,
      locationDisplayName: tagLocation,
      distanceFromEpicenterMeters: eval.distanceMeters,
      verification: verification,
      upvotes: 0,
      userVote: 0,
    );

    if (_postsByEvent[eventId] == null) {
      _postsByEvent[eventId] = [];
    }
    _postsByEvent[eventId]!.insert(0, newPost);

    // Update user stats & gamification
    _awardActivity(
      xpGain: 100,
      postsDelta: 1,
      verifiedContributionsDelta: 1,
      trustScoreDelta: 1,
    );

    // Update event counter
    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex != -1) {
      final old = _events[eventIndex];
      _events[eventIndex] = EventModel(
        id: old.id,
        title: old.title,
        tagName: old.tagName,
        description: old.description,
        category: old.category,
        scope: old.scope,
        riskLevel: old.riskLevel,
        status: old.status,
        city: old.city,
        country: old.country,
        center: old.center,
        radiusMeters: old.radiusMeters,
        radiusUnit: old.radiusUnit,
        polygonVertices: old.polygonVertices,
        bannerImageUrl: old.bannerImageUrl,
        startTime: old.startTime,
        endTime: old.endTime,
        activeContributors: old.activeContributors + 1,
        totalPosts: old.totalPosts + 1,
        totalVideos: old.totalVideos + (type == PostType.video ? 1 : 0),
        verificationLevel: old.verificationLevel,
        isTrending: old.isTrending,
        isHighActivity: old.isHighActivity,
      );
    }

    notifyListeners();
    return true;
  }

  void replaceTempPost(String eventId, String tempId, PostModel serverPost) {
    if (_postsByEvent[eventId] != null) {
      final idx = _postsByEvent[eventId]!.indexWhere((p) => p.id == tempId);
      if (idx != -1) {
        _postsByEvent[eventId]![idx] = serverPost;
        notifyListeners();
      }
    }
  }

  void addPostDirectly(String eventId, PostModel post) {
    if (_postsByEvent[eventId] == null) {
      _postsByEvent[eventId] = [];
    }
    _postsByEvent[eventId]!.add(post);
    notifyListeners();
  }

  /// STRICT REQUIREMENT: "Any user, no matter the location can add comments on the posts and read any posts."
  bool addComment({
    required String postId,
    required String text,
    required EventModel event,
    required LocationService locationService,
  }) {
    final eval = locationService.evaluateVerificationForEvent(event);
    final isInside = eval.isInsideGeofence;

    final comment = CommentModel(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorName: _currentUser.name,
      authorAvatar: _currentUser.avatarUrl,
      authorTrustScore: _currentUser.trustScore,
      text: text,
      createdAt: DateTime.now(),
      isVerifiedOnSite: isInside,
      distanceMeters: eval.distanceMeters,
      location: locationService.currentLocation,
    );

    if (_commentsByPost[postId] == null) {
      _commentsByPost[postId] = [];
    }
    _commentsByPost[postId]!.insert(0, comment);

    // Increment comment count on post
    for (final posts in _postsByEvent.values) {
      final pIndex = posts.indexWhere((p) => p.id == postId);
      if (pIndex != -1) {
        posts[pIndex].commentsCount++;
        break;
      }
    }

    // Award activity for commenting
    _awardActivity(
      xpGain: 25,
      commentsDelta: 1,
    );

    // Persist comment to database asynchronously
    ApiService.submitComment(
      postId: postId,
      text: text,
      author: _currentUser,
      location: locationService.currentLocation,
      isVerifiedOnSite: isInside,
    ).then((remoteComment) {
      if (remoteComment != null) {
        final list = _commentsByPost[postId];
        if (list != null) {
          final idx = list.indexWhere((c) => c.id == comment.id);
          if (idx != -1) {
            list[idx] = remoteComment;
            notifyListeners();
          }
        }
      }
    });

    notifyListeners();
    return true;
  }

  /// STRICT REQUIREMENT: "Tags can be searched or created by anyone.
  /// When creating a tag users can select the event radius of that tag using a range slider,
  /// the range slider minimon and maximum value will change based on the type of the event (nation wide, state wide, city wide)."
  EventModel createTag({
    required String title,
    required String description,
    required EventCategory category,
    required EventScope scope,
    required double radiusValue,
    required String radiusUnit,
    required GeoPoint center,
    String? city,
    String? country,
    RiskLevel? riskLevel,
    String? bannerImageUrl,
  }) {
    // Convert to meters
    final double radiusMeters = radiusUnit == 'mi'
        ? radiusValue * 1609.344
        : radiusValue * 1000.0;

    final cleanTagName = title.startsWith('#')
        ? title
        : '#${title.replaceAll(RegExp(r'\s+'), '')}';

    final defaultBanners = {
      EventCategory.protest: 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&auto=format&fit=crop&q=80',
      EventCategory.naturalDisaster: 'https://images.unsplash.com/photo-1547683905-f686c993aae5?w=800&auto=format&fit=crop&q=80',
      EventCategory.war: 'https://images.unsplash.com/photo-1541888946425-d0fbb186c5f7?w=800&auto=format&fit=crop&q=80',
      EventCategory.fire: 'https://images.unsplash.com/photo-1541888946425-d0fbb186c5f7?w=800&auto=format&fit=crop&q=80',
      EventCategory.election: 'https://images.unsplash.com/photo-1540910419892-4a36d2c3266c?w=800&auto=format&fit=crop&q=80',
      EventCategory.accident: 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800&auto=format&fit=crop&q=80',
      EventCategory.weather: 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800&auto=format&fit=crop&q=80',
      EventCategory.publicGathering: 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800&auto=format&fit=crop&q=80',
      EventCategory.breakingNews: 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800&auto=format&fit=crop&q=80',
    };

    final newEvent = EventModel(
      id: 'tag_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      tagName: cleanTagName,
      description: description.isNotEmpty
          ? description
          : 'Community verified eyewitness tag for $title. Only reports inside the $radiusValue $radiusUnit radius are admitted.',
      category: category,
      scope: scope,
      riskLevel: riskLevel ?? RiskLevel.high,
      status: EventStatus.live,
      city: city ?? (center.label != null ? center.label!.split(',').first : 'Metro Region'),
      country: country ?? 'Global',
      center: center,
      radiusMeters: radiusMeters,
      radiusUnit: radiusUnit,
      bannerImageUrl: bannerImageUrl ?? defaultBanners[category] ?? 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&auto=format&fit=crop&q=80',
      startTime: DateTime.now(),
      activeContributors: 1,
      totalPosts: 0,
      totalVideos: 0,
      isTrending: true,
      verificationLevel: 'Forensic Eyewitness Geofence Active',
    );

    _events.insert(0, newEvent);
    _selectedEventId = newEvent.id;
    _postsByEvent[newEvent.id] = [];

    // Asynchronously persist to database via ApiService
    ApiService.createRemoteTag(
      title: title,
      tagName: cleanTagName,
      description: newEvent.description,
      category: category.label,
      scope: scope.label,
      riskLevel: newEvent.riskLevel.label,
      city: newEvent.city,
      country: newEvent.country,
      latitude: center.latitude,
      longitude: center.longitude,
      radiusMeters: radiusMeters,
      radiusUnit: radiusUnit,
      bannerImageUrl: newEvent.bannerImageUrl,
    ).then((remoteId) {
      if (remoteId != null) {
        final index = _events.indexWhere((e) => e.id == newEvent.id);
        if (index != -1) {
          final oldId = newEvent.id;
          final updatedEvent = EventModel(
            id: remoteId,
            title: newEvent.title,
            tagName: newEvent.tagName,
            description: newEvent.description,
            category: newEvent.category,
            scope: newEvent.scope,
            riskLevel: newEvent.riskLevel,
            status: newEvent.status,
            city: newEvent.city,
            country: newEvent.country,
            center: newEvent.center,
            radiusMeters: newEvent.radiusMeters,
            radiusUnit: newEvent.radiusUnit,
            polygonVertices: newEvent.polygonVertices,
            bannerImageUrl: newEvent.bannerImageUrl,
            startTime: newEvent.startTime,
            endTime: newEvent.endTime,
            activeContributors: newEvent.activeContributors,
            totalPosts: newEvent.totalPosts,
            totalVideos: newEvent.totalVideos,
            verificationLevel: newEvent.verificationLevel,
            isTrending: newEvent.isTrending,
            isHighActivity: newEvent.isHighActivity,
          );
          _events[index] = updatedEvent;
          if (_selectedEventId == oldId) {
            _selectedEventId = remoteId;
          }
          if (_postsByEvent.containsKey(oldId)) {
            _postsByEvent[remoteId] = _postsByEvent.remove(oldId)!;
          }
          notifyListeners();
        }
      }
    });

    // Award activity for tag creation
    _awardActivity(
      xpGain: 75,
      tagsDelta: 1,
    );

    _alerts.insert(
      0,
      AppAlert(
        id: 'alt_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Tag Activated: $cleanTagName',
        message: 'Your tag has been published with a $radiusValue $radiusUnit geofence. Eyewitnesses within the boundary can now submit verified reports.',
        eventId: newEvent.id,
        timestamp: DateTime.now(),
        isCritical: false,
      ),
    );

    notifyListeners();
    return newEvent;
  }

  void markAlertAsRead(String alertId) {
    final alert = _alerts.firstWhere((a) => a.id == alertId);
    alert.isRead = true;
    notifyListeners();
  }

  // ==========================================
  // Gamification & Achievement Tracking Engine
  // ==========================================

  void _initAchievements() {
    final initialAchievements = [
      const AchievementModel(
        id: 'ach_ground_reporter_1',
        title: 'Ground Reporter I',
        description: 'Publish your first verified eyewitness report.',
        category: AchievementCategory.reporting,
        tier: AchievementTier.bronze,
        icon: Icons.edit_note_rounded,
        currentProgress: 1,
        maxProgress: 1,
        isUnlocked: true,
        xpReward: 100,
        howToEarn: 'Write a post while physically located inside an active event radius.',
      ),
      const AchievementModel(
        id: 'ach_ground_reporter_2',
        title: 'Frontline Eyewitness',
        description: 'Publish 5 verified eyewitness reports from active event zones.',
        category: AchievementCategory.reporting,
        tier: AchievementTier.silver,
        icon: Icons.newspaper_rounded,
        currentProgress: 4,
        maxProgress: 5,
        isUnlocked: false,
        xpReward: 250,
        howToEarn: 'Submit 5 separate verified posts inside tag geofences.',
      ),
      const AchievementModel(
        id: 'ach_truth_guardian_1',
        title: 'Truth Verifier I',
        description: 'Verify news by liking or disliking a post from inside an event area.',
        category: AchievementCategory.verification,
        tier: AchievementTier.bronze,
        icon: Icons.verified_rounded,
        currentProgress: 14,
        maxProgress: 1,
        isUnlocked: true,
        xpReward: 80,
        howToEarn: 'Cast a like or dislike on any post while physically on-site.',
      ),
      const AchievementModel(
        id: 'ach_truth_guardian_2',
        title: 'Truth Guardian',
        description: 'Cast 15 verification votes (like/dislike) to confirm real news.',
        category: AchievementCategory.verification,
        tier: AchievementTier.silver,
        icon: Icons.shield_rounded,
        currentProgress: 14,
        maxProgress: 15,
        isUnlocked: false,
        xpReward: 200,
        howToEarn: 'Reach 15 consensus votes inside event boundaries.',
      ),
      const AchievementModel(
        id: 'ach_consensus_master',
        title: 'Consensus Sentinel',
        description: 'Cast 50 verification votes with 95%+ community consensus.',
        category: AchievementCategory.verification,
        tier: AchievementTier.gold,
        icon: Icons.balance_rounded,
        currentProgress: 14,
        maxProgress: 50,
        isUnlocked: false,
        xpReward: 500,
        howToEarn: 'Cast 50 verified votes within event areas.',
      ),
      const AchievementModel(
        id: 'ach_tag_pioneer_1',
        title: 'Event Scout I',
        description: 'Create your first verified event tag with a custom radius slider.',
        category: AchievementCategory.tagging,
        tier: AchievementTier.bronze,
        icon: Icons.tag_rounded,
        currentProgress: 2,
        maxProgress: 1,
        isUnlocked: true,
        xpReward: 120,
        howToEarn: 'Define and launch a new tag geofence in any category.',
      ),
      const AchievementModel(
        id: 'ach_tag_pioneer_2',
        title: 'Beacon Pioneer',
        description: 'Create 3 verified event tags (city-wide, state-wide, or nation-wide).',
        category: AchievementCategory.tagging,
        tier: AchievementTier.silver,
        icon: Icons.radar_rounded,
        currentProgress: 2,
        maxProgress: 3,
        isUnlocked: false,
        xpReward: 300,
        howToEarn: 'Create 3 active tags with calibrated event radius.',
      ),
      const AchievementModel(
        id: 'ach_community_voice_1',
        title: 'Active Citizen I',
        description: 'Post your first comment in an eyewitness news discussion.',
        category: AchievementCategory.community,
        tier: AchievementTier.bronze,
        icon: Icons.chat_bubble_outline_rounded,
        currentProgress: 8,
        maxProgress: 1,
        isUnlocked: true,
        xpReward: 50,
        howToEarn: 'Participate in any public post discussion from anywhere.',
      ),
      const AchievementModel(
        id: 'ach_community_voice_2',
        title: 'Voice of Reason',
        description: 'Add 15 constructive comments across verified event threads.',
        category: AchievementCategory.community,
        tier: AchievementTier.silver,
        icon: Icons.forum_rounded,
        currentProgress: 8,
        maxProgress: 15,
        isUnlocked: false,
        xpReward: 180,
        howToEarn: 'Post 15 comments across any event tags.',
      ),
      const AchievementModel(
        id: 'ach_mastery_sentinel',
        title: 'Ground Custodian',
        description: 'Achieve Level 3 Sentinel rank and over 1,000 XP in verified truth actions.',
        category: AchievementCategory.mastery,
        tier: AchievementTier.diamond,
        icon: Icons.military_tech_rounded,
        currentProgress: 680,
        maxProgress: 1000,
        isUnlocked: false,
        xpReward: 800,
        howToEarn: 'Gain 1,000 total XP by posting, verifying on-site, commenting, and creating tags.',
      ),
    ];

    _currentUser = _currentUser.copyWith(achievements: initialAchievements);
  }

  void _awardActivity({
    int xpGain = 0,
    int postsDelta = 0,
    int verificationsDelta = 0,
    int commentsDelta = 0,
    int tagsDelta = 0,
    int verifiedContributionsDelta = 0,
    int trustScoreDelta = 0,
  }) {
    final newXp = _currentUser.xp + xpGain;
    final newPosts = _currentUser.postsCreated + postsDelta;
    final newVerifications = _currentUser.verificationsDone + verificationsDelta;
    final newComments = _currentUser.commentsAdded + commentsDelta;
    final newTags = _currentUser.tagsCreated + tagsDelta;
    final newContributions = _currentUser.verifiedContributions + verifiedContributionsDelta;
    final newTrust = (_currentUser.trustScore + trustScoreDelta).clamp(0, 100);

    // Compute Level
    // Level 1: 0 - 500
    // Level 2: 500 - 1000
    // Level 3: 1000 - 1500
    // Level 4: 1500 - 2000
    // Level 5: 2000+
    int newLevel = (newXp / 500).floor() + 1;
    String newTitle = _currentUser.levelTitle;
    if (newLevel == 1) newTitle = 'Ground Observer';
    if (newLevel == 2) newTitle = 'Verified Field Scout';
    if (newLevel == 3) newTitle = 'Frontline Sentinel';
    if (newLevel == 4) newTitle = 'Senior Truth Custodian';
    if (newLevel >= 5) newTitle = 'Master Ground Guardian';

    // Update achievements progress
    final updatedAchievements = <AchievementModel>[];
    for (final ach in _currentUser.achievements) {
      int current = ach.currentProgress;
      switch (ach.id) {
        case 'ach_ground_reporter_1':
        case 'ach_ground_reporter_2':
          current = newPosts;
          break;
        case 'ach_truth_guardian_1':
        case 'ach_truth_guardian_2':
        case 'ach_consensus_master':
          current = newVerifications;
          break;
        case 'ach_tag_pioneer_1':
        case 'ach_tag_pioneer_2':
          current = newTags;
          break;
        case 'ach_community_voice_1':
        case 'ach_community_voice_2':
          current = newComments;
          break;
        case 'ach_mastery_sentinel':
          current = newXp;
          break;
      }

      final bool wasUnlocked = ach.isUnlocked;
      final bool nowUnlocked = current >= ach.maxProgress;

      if (!wasUnlocked && nowUnlocked) {
        // Trigger celebration toast!
        final unlockedAch = ach.copyWith(
          currentProgress: current,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        updatedAchievements.add(unlockedAch);
        _recentlyUnlockedAchievement = unlockedAch;

        _alerts.insert(
          0,
          AppAlert(
            id: 'ach_alert_${DateTime.now().millisecondsSinceEpoch}',
            title: '🏆 Achievement Unlocked: ${ach.title}!',
            message: 'You earned the "${ach.title}" badge and +${ach.xpReward} XP. Check your public profile.',
            eventId: _selectedEventId ?? 'delhi_protest_2026',
            timestamp: DateTime.now(),
            isCritical: false,
          ),
        );
      } else {
        updatedAchievements.add(ach.copyWith(
          currentProgress: current,
          isUnlocked: nowUnlocked || wasUnlocked,
        ));
      }
    }

    _currentUser = _currentUser.copyWith(
      xp: newXp,
      level: newLevel,
      levelTitle: newTitle,
      postsCreated: newPosts,
      verificationsDone: newVerifications,
      commentsAdded: newComments,
      tagsCreated: newTags,
      verifiedContributions: newContributions,
      trustScore: newTrust,
      achievements: updatedAchievements,
    );

    if (_isLoggedIn) {
      _savePersistedSession();
    }
  }

  void _initializeData() {
    _journalists = List.from(_seedJournalists);

    // Delhi Protest Polygon: Parliament Road, India Gate, Jantar Mantar, Connaught Place
    final delhiPolygon = [
      const GeoPoint(28.6328, 77.2195, 'Connaught Place Outer Circle'),
      const GeoPoint(28.6271, 77.2166, 'Jantar Mantar Gate'),
      const GeoPoint(28.6172, 77.2081, 'Parliament Road North'),
      const GeoPoint(28.6129, 77.2295, 'India Gate Canopy'),
      const GeoPoint(28.6225, 77.2340, 'Barakhamba Road'),
    ];

    _events = [
      EventModel(
        id: 'delhi_protest_2026',
        title: 'Farmers March & Parliament Demonstration',
        tagName: '#FarmersMarchDelhi',
        description: 'Large-scale verified gathering along Parliament Road, Jantar Mantar, and central transit arteries demanding MSP legal guarantee. Eyewitness geofence strictly active across the designated high-security polygon.',
        category: EventCategory.protest,
        scope: EventScope.cityWide,
        riskLevel: RiskLevel.high,
        status: EventStatus.live,
        city: 'New Delhi',
        country: 'India',
        center: const GeoPoint(28.6271, 77.2166, 'Jantar Mantar Epicenter'),
        radiusMeters: 2200,
        radiusUnit: 'km',
        polygonVertices: delhiPolygon,
        bannerImageUrl: 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&auto=format&fit=crop&q=80',
        startTime: DateTime.now().subtract(const Duration(hours: 14)),
        activeContributors: 3420,
        totalPosts: 814,
        totalVideos: 192,
        verificationLevel: 'Multi-Layer Level 3 Enforced (Polygon Strict)',
        isTrending: true,
        isHighActivity: true,
      ),
      EventModel(
        id: 'kerala_floods_2026',
        title: 'Wayanad Meppadi Flash Flood & Landslide Rescue',
        tagName: '#WayanadFloodRescue',
        description: 'Urgent flash floods and secondary hill debris triggered by torrential cloudburst. Emergency rescue operations underway across Meppadi and Chooralmala. Real-time eyewitness reports guide first responders.',
        category: EventCategory.naturalDisaster,
        scope: EventScope.stateWide,
        riskLevel: RiskLevel.critical,
        status: EventStatus.breaking,
        city: 'Wayanad, Kerala',
        country: 'India',
        center: const GeoPoint(11.5540, 76.1260, 'Meppadi Emergency Hub'),
        radiusMeters: 35000,
        radiusUnit: 'km',
        polygonVertices: const [],
        bannerImageUrl: 'https://images.unsplash.com/photo-1547683905-f686c993aae5?w=800&auto=format&fit=crop&q=80',
        startTime: DateTime.now().subtract(const Duration(hours: 6)),
        activeContributors: 1280,
        totalPosts: 420,
        totalVideos: 86,
        verificationLevel: 'Disaster Rapid Verification Protocol (Level 3)',
        isTrending: true,
        isHighActivity: true,
      ),
      EventModel(
        id: 'london_fire_2026',
        title: 'Paddington Commercial Complex 4-Alarm Fire',
        tagName: '#PaddingtonFire',
        description: 'Structural blaze reported on Praed Street near London Paddington station. London Fire Brigade deployed 15 appliances. Air quality monitoring and evacuation perimeter established.',
        category: EventCategory.fire,
        scope: EventScope.cityWide,
        riskLevel: RiskLevel.critical,
        status: EventStatus.live,
        city: 'London',
        country: 'United Kingdom',
        center: const GeoPoint(51.5174, -0.1764, 'Praed Street / Paddington'),
        radiusMeters: 1400,
        radiusUnit: 'km',
        polygonVertices: const [],
        bannerImageUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb186c5f7?w=800&auto=format&fit=crop&q=80',
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        activeContributors: 640,
        totalPosts: 185,
        totalVideos: 42,
        verificationLevel: 'Level 3 Enforced',
        isTrending: false,
        isHighActivity: true,
      ),
      EventModel(
        id: 'tokyo_earthquake_2026',
        title: 'Shibuya Metro Seismic Tremor & Evacuation',
        tagName: '#TokyoSeismicAlert',
        description: 'Magnitude 5.9 seismic event centered in Tokyo Bay shaking central Tokyo wards. Train lines suspended temporarily; crowd dispersal and building inspections active.',
        category: EventCategory.weather,
        scope: EventScope.cityWide,
        riskLevel: RiskLevel.high,
        status: EventStatus.active,
        city: 'Tokyo',
        country: 'Japan',
        center: const GeoPoint(35.6580, 139.7016, 'Shibuya Crossing'),
        radiusMeters: 2800,
        radiusUnit: 'km',
        polygonVertices: const [],
        bannerImageUrl: 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800&auto=format&fit=crop&q=80',
        startTime: DateTime.now().subtract(const Duration(hours: 8)),
        activeContributors: 2190,
        totalPosts: 590,
        totalVideos: 128,
        verificationLevel: 'Level 3 Enforced',
        isTrending: true,
        isHighActivity: true,
      ),
      EventModel(
        id: 'election_counting_2026',
        title: 'Central Election Counting Hall - Disputed Result',
        tagName: '#NationalVoteTabulation',
        description: 'Official vote tabulation and candidate observer presence inside the Central Counting Center. Verified party observers reporting real-time certificate tallies.',
        category: EventCategory.election,
        scope: EventScope.nationWide,
        riskLevel: RiskLevel.moderate,
        status: EventStatus.live,
        city: 'New Delhi',
        country: 'India',
        center: const GeoPoint(28.5830, 77.2280, 'Counting Complex Zone 4'),
        radiusMeters: 500000,
        radiusUnit: 'km',
        polygonVertices: const [],
        bannerImageUrl: 'https://images.unsplash.com/photo-1540910419892-4a36d2c3266c?w=800&auto=format&fit=crop&q=80',
        startTime: DateTime.now().subtract(const Duration(hours: 18)),
        activeContributors: 840,
        totalPosts: 310,
        totalVideos: 52,
        verificationLevel: 'Level 3 Enforced',
        isTrending: false,
        isHighActivity: false,
      ),
      EventModel(
        id: 'paris_strike_2026',
        title: 'Paris Transit & Gare de Lyon Demonstration',
        tagName: '#ParisTransitStrike',
        description: 'Major transport union assembly at Gare de Lyon and Place de la Bastille affecting commuter rail networks. Eyewitness verification monitors peaceful crowd marshaling.',
        category: EventCategory.protest,
        scope: EventScope.cityWide,
        riskLevel: RiskLevel.high,
        status: EventStatus.live,
        city: 'Paris',
        country: 'France',
        center: const GeoPoint(48.8566, 2.3522, 'Gare de Lyon Perimeter'),
        radiusMeters: 3100,
        radiusUnit: 'km',
        polygonVertices: const [],
        bannerImageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&auto=format&fit=crop&q=80',
        startTime: DateTime.now().subtract(const Duration(hours: 5)),
        activeContributors: 1540,
        totalPosts: 360,
        totalVideos: 74,
        verificationLevel: 'Level 3 Enforced',
        isTrending: true,
        isHighActivity: true,
      ),
      EventModel(
        id: 'sf_climate_2026',
        title: 'San Francisco Bay High-Tide Flood Defense',
        tagName: '#BayAreaClimateWatch',
        description: 'Atmospheric river and king tide convergence triggering sea wall water breaches near Embarcadero. Emergency pumps and sandbagging crews deployed.',
        category: EventCategory.naturalDisaster,
        scope: EventScope.cityWide,
        riskLevel: RiskLevel.high,
        status: EventStatus.live,
        city: 'San Francisco',
        country: 'United States',
        center: const GeoPoint(37.7749, -122.4194, 'Embarcadero Sea Wall'),
        radiusMeters: 4500,
        radiusUnit: 'km',
        polygonVertices: const [],
        bannerImageUrl: 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800&auto=format&fit=crop&q=80',
        startTime: DateTime.now().subtract(const Duration(hours: 9)),
        activeContributors: 1820,
        totalPosts: 490,
        totalVideos: 110,
        verificationLevel: 'Level 3 Enforced',
        isTrending: true,
        isHighActivity: true,
      ),
      EventModel(
        id: 'sydney_heatwave_2026',
        title: 'Greater Sydney Red Flag Bushfire Watch',
        tagName: '#SydneyBushfireWatch',
        description: 'Severe 43°C hot winds triggering elevated bushfire warnings across Blue Mountains and outer Western Sydney. Volunteer brigades staging preemptive containment lines.',
        category: EventCategory.weather,
        scope: EventScope.stateWide,
        riskLevel: RiskLevel.critical,
        status: EventStatus.breaking,
        city: 'Sydney',
        country: 'Australia',
        center: const GeoPoint(-33.8688, 151.2093, 'Western Sydney Fire Command'),
        radiusMeters: 45000,
        radiusUnit: 'km',
        polygonVertices: const [],
        bannerImageUrl: 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&auto=format&fit=crop&q=80',
        startTime: DateTime.now().subtract(const Duration(hours: 11)),
        activeContributors: 980,
        totalPosts: 270,
        totalVideos: 48,
        verificationLevel: 'Level 3 Enforced',
        isTrending: false,
        isHighActivity: true,
      ),
    ];

    // Default selected event
    _selectedEventId = _events[0].id;

    // Database-driven: All posts and comments are dynamically loaded from MongoDB.
    // Dummy posts and mock comments have been removed.
    // Seed alerts
    _alerts.addAll([
      AppAlert(
        id: 'alt_1',
        title: 'Geofence Entry Detected',
        message: 'You have entered the active Delhi Farmers Protest polygon geofence. High-precision GNSS verification active. You are authorized to submit verified ground reports.',
        eventId: 'delhi_protest_2026',
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        isCritical: false,
      ),
      AppAlert(
        id: 'alt_2',
        title: 'CRITICAL: Flash Flood Alert Issued',
        message: 'District Collectorate issued red alert for Meppadi & Chooralmala. Eyewitness contributors urged to seek elevated ground.',
        eventId: 'kerala_floods_2026',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isCritical: true,
      ),
      AppAlert(
        id: 'alt_3',
        title: 'Community Trust Milestone',
        message: 'Your eyewitness report from Tolstoy Marg reached 340+ consensus upvotes. Trust score increased to 94.',
        eventId: 'delhi_protest_2026',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isCritical: false,
      ),
    ]);
  }
}
