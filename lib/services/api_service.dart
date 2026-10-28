import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/comment_model.dart';
import '../models/event_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../utils/geofence_math.dart';

class ApiService {
  // Remote production backend URL hosted on Render
  static String baseUrl = 'https://ground-truth-yyir.onrender.com/api';

  static Future<bool> isBackendConnected() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['database'] == 'CONNECTED';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all active posts directly from the database
  static Future<List<PostModel>?> fetchRemotePosts({String? userId}) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }
      final uri = Uri.parse('$baseUrl/posts').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await http
          .get(
            uri,
            headers: {
              if (userId != null && userId.isNotEmpty) 'x-user-id': userId,
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> list = body['data'] ?? [];
        return list.map((item) => PostModel.fromJson(item, currentUserId: userId)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend fetchRemotePosts failed: $e');
      }
    }
    return null;
  }

  /// Fetch comments for a specific post from the database
  static Future<List<CommentModel>?> fetchCommentsForPost(String postId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/posts/$postId/comments'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> list = body['data'] ?? [];
        return list.map((item) => CommentModel.fromJson(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend fetchCommentsForPost failed: $e');
      }
    }
    return null;
  }

  /// Submit comment to the database
  static Future<CommentModel?> submitComment({
    required String postId,
    required String text,
    required UserModel author,
    required GeoPoint location,
    required bool isVerifiedOnSite,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/posts/$postId/comments'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'text': text,
              'author': {
                'userId': author.id,
                'name': author.name,
                'avatar': author.avatarUrl,
                'trustScore': author.trustScore,
              },
              'latitude': location.latitude,
              'longitude': location.longitude,
              'gpsAccuracy': 3.5,
              'mockLocationDetected': false,
              'deviceRooted': false,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 201) {
        final body = json.decode(response.body);
        if (body['data'] != null) {
          return CommentModel.fromJson(body['data']);
        }
      }
    } catch (e) {
      if (kDebugMode) print('ApiService submitComment error: $e');
    }
    return null;
  }

  /// Fetch all active tags directly from the MongoDB tags collection
  static Future<List<EventModel>?> fetchRemoteTags() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/tags'))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> list = body['data'] ?? [];
        return list.map((item) => EventModel.fromJson(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend fetchRemoteTags failed: $e');
      }
    }
    return null;
  }

  /// Create remote tag in MongoDB `tags` collection
  static Future<String?> createRemoteTag({
    required String title,
    required String? tagName,
    required String description,
    required String category,
    required String scope,
    required String riskLevel,
    required String city,
    required String country,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    String radiusUnit = 'km',
    String? bannerImageUrl,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/tags'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'title': title,
              'tagName': tagName,
              'description': description,
              'category': category,
              'scope': scope,
              'riskLevel': riskLevel,
              'city': city,
              'country': country,
              'latitude': latitude,
              'longitude': longitude,
              'radiusMeters': radiusMeters,
              'radiusUnit': radiusUnit,
              ...?bannerImageUrl != null ? {'bannerImageUrl': bannerImageUrl} : null,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['_id'];
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiService createRemoteTag error: $e');
      }
    }
    return null;
  }

  /// Submit verified post to database and return created PostModel with MongoDB _id
  static Future<PostModel?> submitVerifiedPost({
    required String eventId,
    required PostModel post,
    required double latitude,
    required double longitude,
    required double gpsAccuracy,
    required bool mockLocationDetected,
    required bool deviceRooted,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tagId': eventId,
          'eventId': eventId,
          'title': post.title ?? 'Verified Eyewitness Report',
          'tagName': post.tagName,
          'type': post.type.name.toUpperCase(),
          'content': post.content,
          'mediaUrl': post.mediaUrl,
          'videoThumbnailUrl': post.videoThumbnailUrl,
          'audioDurationSeconds': post.audioDurationSeconds,
          'waveform': post.waveform,
          'pollOptions': post.pollOptions?.map((o) => o.toJson()).toList(),
          'locationDisplayName': post.locationDisplayName,
          'latitude': latitude,
          'longitude': longitude,
          'gpsAccuracy': gpsAccuracy,
          'mockLocationDetected': mockLocationDetected,
          'deviceRooted': deviceRooted,
          'confidenceScore': post.verification.confidenceScore,
          'author': {
            'userId': post.authorId,
            'name': post.authorName,
            'avatar': post.authorAvatar,
            'trustScore': post.authorTrustScore,
            'isVerifiedJournalist': post.authorIsVerifiedJournalist,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return PostModel.fromJson(body['data']);
        }
      } else {
        if (kDebugMode) {
          print('Backend submitVerifiedPost failed: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('ApiService submitVerifiedPost error: $e');
    }
    return null;
  }

  /// Submit verified poll vote to database with geofence validation
  static Future<PostModel?> submitPollVote({
    required String postId,
    required String optionId,
    required String userId,
    required double latitude,
    required double longitude,
    double gpsAccuracy = 3.5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/poll-vote'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'optionId': optionId,
          'userId': userId,
          'latitude': latitude,
          'longitude': longitude,
          'gpsAccuracy': gpsAccuracy,
          'mockLocationDetected': false,
          'deviceRooted': false,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final updatedPost = PostModel.fromJson(body['data']);
          return updatedPost.copyWith(
            userVotedPollOptionId: body['userVotedOptionId']?.toString() ?? optionId,
          );
        }
      } else {
        if (kDebugMode) {
          print('ApiService submitPollVote failed: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('ApiService submitPollVote error: $e');
    }
    return null;
  }

  /// Submit verified upvote/downvote to database with geofence validation
  static Future<PostModel?> submitVote({
    required String postId,
    required int direction,
    required String userId,
    required double latitude,
    required double longitude,
    double gpsAccuracy = 3.5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/vote'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': userId,
        },
        body: json.encode({
          'direction': direction,
          'userId': userId,
          'latitude': latitude,
          'longitude': longitude,
          'gpsAccuracy': gpsAccuracy,
          'mockLocationDetected': false,
          'deviceRooted': false,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final updatedPost = PostModel.fromJson(body['data'], currentUserId: userId);
          final serverVote = (body['userVote'] as num?)?.toInt() ??
              (body['data']['userVote'] as num?)?.toInt() ??
              direction;
          return updatedPost.copyWith(
            userVote: serverVote,
          );
        }
      } else {
        if (kDebugMode) {
          print('ApiService submitVote failed: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('ApiService submitVote error: $e');
    }
    return null;
  }

  // --- Authentication Methods ---

  static Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'identifier': identifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 25));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = UserModel.fromJson(data['user']);
        final token = data['token'] as String?;
        return AuthResponse(
          success: true,
          token: token,
          user: user,
          message: data['message'] ?? 'Login successful',
        );
      } else {
        return AuthResponse(
          success: false,
          error: data['message'] ?? data['error'] ?? 'Authentication failed',
        );
      }
    } catch (e) {
      if (kDebugMode) print('ApiService login exception: $e');
      return AuthResponse(
        success: false,
        error: 'Unable to reach authentication server. Falling back to secure device keystore.',
      );
    }
  }

  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String handle,
    required String password,
    String? deviceModel,
    String? tier,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'name': name,
              'email': email,
              'handle': handle,
              'password': password,
              'deviceModel': deviceModel,
              'tier': tier,
            }),
          )
          .timeout(const Duration(seconds: 25));

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final user = UserModel.fromJson(data['user']);
        final token = data['token'] as String?;
        return AuthResponse(
          success: true,
          token: token,
          user: user,
          message: data['message'] ?? 'Registration successful',
        );
      } else {
        return AuthResponse(
          success: false,
          error: data['message'] ?? data['error'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      if (kDebugMode) print('ApiService register exception: $e');
      return AuthResponse(
        success: false,
        error: 'Unable to connect to verification server. Falling back to local hardware profile.',
      );
    }
  }


  static Future<UserModel?> fetchCurrentUser(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          return UserModel.fromJson(data['user']);
        }
      }
    } catch (e) {
      if (kDebugMode) print('ApiService fetchCurrentUser error: $e');
    }
    return null;
  }

  /// Update user profile details
  static Future<AuthResponse> updateUserProfile({
    required String userId,
    String? token,
    String? name,
    String? email,
    String? handle,
    String? avatarUrl,
    String? bio,
    String? location,
    String? organization,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (email != null) payload['email'] = email;
    if (handle != null) payload['handle'] = handle;
    if (avatarUrl != null) payload['avatarUrl'] = avatarUrl;
    if (bio != null) payload['bio'] = bio;
    if (location != null) payload['location'] = location;
    if (organization != null) payload['organization'] = organization;

    final endpoints = [
      '$baseUrl/users/$userId',
      'http://localhost:5001/api/users/$userId',
    ];

    for (final url in endpoints) {
      try {
        final res = await http
            .put(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
                'x-user-id': userId,
              },
              body: json.encode(payload),
            )
            .timeout(const Duration(seconds: 10));

        final body = json.decode(res.body);
        if (res.statusCode == 200 && body['success'] == true) {
          final user = body['user'] != null ? UserModel.fromJson(body['user']) : null;
          return AuthResponse(
            success: true,
            user: user,
            message: body['message']?.toString() ?? 'Profile updated successfully.',
          );
        } else if (body['message'] != null || body['error'] != null) {
          return AuthResponse(
            success: false,
            error: body['message']?.toString() ?? body['error']?.toString() ?? 'Update failed',
          );
        }
      } catch (e) {
        if (kDebugMode) print('ApiService updateUserProfile error for $url: $e');
      }
    }

    return const AuthResponse(
      success: false,
      error: 'Could not connect to server. Saved locally.',
    );
  }

  /// Fetch user profile by ID or handle
  static Future<UserModel?> fetchUserProfile(
    String userId, {
    String? token,
    String? followerId,
  }) async {
    final query = followerId != null ? '?followerId=$followerId' : '';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    // Try primary baseUrl, fallback to local if needed
    final urls = [
      '$baseUrl/users/$userId$query',
      'http://localhost:5001/api/users/$userId$query',
    ];

    for (final url in urls) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['user'] != null) {
            return UserModel.fromJson(data['user']);
          }
        }
      } catch (e) {
        if (kDebugMode) print('fetchUserProfile error for $url: $e');
      }
    }
    return null;
  }

  /// Toggle follow state for a user
  static Future<Map<String, dynamic>?> toggleFollowUser({
    required String targetUserId,
    String? token,
    String? followerId,
    String? followerName,
  }) async {
    final bodyMap = <String, dynamic>{};
    if (followerId != null) bodyMap['followerId'] = followerId;
    if (followerName != null) bodyMap['followerName'] = followerName;
    final body = json.encode(bodyMap);
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final urls = [
      '$baseUrl/users/$targetUserId/follow',
      'http://localhost:5001/api/users/$targetUserId/follow',
    ];

    for (final url in urls) {
      try {
        final response = await http
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
      } catch (e) {
        if (kDebugMode) print('toggleFollowUser error for $url: $e');
      }
    }
    return null;
  }

  /// Fetch all posts authored by a user
  static Future<List<PostModel>?> fetchUserPosts(String userId) async {
    final urls = [
      '$baseUrl/users/$userId/posts',
      'http://localhost:5001/api/users/$userId/posts',
    ];

    for (final url in urls) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> list = data['data'] ?? [];
          return list.map((item) => PostModel.fromJson(item)).toList();
        }
      } catch (e) {
        if (kDebugMode) print('fetchUserPosts error for $url: $e');
      }
    }
    return null;
  }

  /// Search users by name or handle
  static Future<List<UserModel>?> searchUsers(
    String query, {
    String? token,
    String? followerId,
  }) async {
    final enc = Uri.encodeComponent(query.trim());
    final followerParam = followerId != null ? '&followerId=$followerId' : '';
    final urls = [
      '$baseUrl/users?search=$enc$followerParam',
      'http://localhost:5001/api/users?search=$enc$followerParam',
    ];

    for (final url in urls) {
      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> list = data['data'] ?? [];
          return list.map((item) => UserModel.fromJson(item)).toList();
        }
      } catch (e) {
        if (kDebugMode) print('searchUsers error for $url: $e');
      }
    }
    return null;
  }
}

class AuthResponse {
  final bool success;
  final String? token;
  final UserModel? user;
  final String? message;
  final String? error;

  const AuthResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
    this.error,
  });
}
