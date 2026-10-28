import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groundtruth/models/event_model.dart';
import 'package:groundtruth/models/post_model.dart';
import 'package:groundtruth/providers/app_state.dart';
import 'package:groundtruth/providers/location_service.dart';
import 'package:groundtruth/utils/geofence_math.dart';
import 'package:groundtruth/widgets/post/poll_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  void close({bool force = false}) {}
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  int contentLength = 0;
  @override
  bool persistentConnection = false;
  @override
  bool bufferOutput = true;
  @override
  void add(List<int> data) {}
  @override
  void write(Object? obj) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  static final _body = utf8.encode('{"success": true, "data": {"id": "post_poll_1", "type": "POLL", "pollOptions": [{"id": "opt_yes", "text": "Yes", "votes": 1}, {"id": "opt_no", "text": "No", "votes": 0}], "userVotedOptionId": "opt_yes"}}');

  @override
  int get statusCode => 200;
  @override
  bool get isRedirect => false;
  @override
  String get reasonPhrase => 'OK';
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  bool get persistentConnection => false;
  @override
  int get contentLength => _body.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_body).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUp(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('Poll Model & JSON isolation tests', () {
    test('PostModel.fromJson does not assign first voter to an unrelated user', () {
      final json = {
        'id': 'post_poll_1',
        'type': 'POLL',
        'content': 'Is the bridge open?',
        'pollOptions': [
          {'id': 'opt_1', 'text': 'Yes', 'votes': 1},
          {'id': 'opt_2', 'text': 'No', 'votes': 0},
        ],
        'pollVoters': [
          {'userId': 'user_alice', 'optionId': 'opt_1'},
        ],
      };

      // Unrelated user Bob
      final postBob = PostModel.fromJson(json, currentUserId: 'user_bob');
      expect(postBob.userVotedPollOptionId, isNull);

      // Alice itself
      final postAlice = PostModel.fromJson(json, currentUserId: 'user_alice');
      expect(postAlice.userVotedPollOptionId, equals('opt_1'));
    });
  });

  group('Poll Voting AppState tests', () {
    test('Voting works, is changeable anytime, and restricts users outside geofence', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState(autoLoadRemote: false);

      final event = appState.events.first;
      final eventLocation = event.center;

      final pollPost = PostModel(
        id: 'post_poll_1',
        eventId: event.id,
        title: event.tagName,
        authorId: 'user_dev_01', // Created by currentUser
        authorName: 'Local Reporter',
        authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
        authorTrustScore: 90,
        type: PostType.poll,
        content: 'Is the roadblock cleared?',
        createdAt: DateTime.now(),
        location: eventLocation,
        locationDisplayName: 'Verified Location',
        distanceFromEpicenterMeters: 0,
        verification: VerificationDetails(
          isGpsVerified: true,
          gpsAccuracyMeters: 3.5,
          isDeviceIntegrityVerified: true,
          deviceIntegrityProvider: 'Apple App Attest',
          isNetworkVerified: true,
          networkSignals: 'Cell Tower',
          mockLocationPassed: true,
          rootJailbreakPassed: true,
          confidenceScore: 99.0,
          verificationHash: 'hash_test',
          verifiedAt: DateTime.now(),
        ),
        pollOptions: [
          PollOption(id: 'opt_yes', text: 'Yes', votes: 0),
          PollOption(id: 'opt_no', text: 'No', votes: 0),
        ],
      );

      appState.addPostDirectly(event.id, pollPost);

      // User inside geofence (at epicenter)
      final insideLocation = eventLocation;
      // User outside geofence (far away: latitude + 2.0 degrees is ~220km away)
      final outsideLocation = GeoPoint(eventLocation.latitude + 2.0, eventLocation.longitude);

      // 1. Outside user attempts to vote -> BLOCKED
      final outsideRes = appState.votePoll(
        eventId: event.id,
        postId: pollPost.id,
        optionId: 'opt_yes',
        userLocation: outsideLocation,
      );
      expect(outsideRes.allowed, isFalse);
      expect(outsideRes.message, contains('Only eyewitnesses physically inside'));

      // 2. On-site user (even if creator) votes for 'opt_yes' -> ALLOWED
      final firstVoteRes = appState.votePoll(
        eventId: event.id,
        postId: pollPost.id,
        optionId: 'opt_yes',
        userLocation: insideLocation,
      );
      expect(firstVoteRes.allowed, isTrue);
      expect(firstVoteRes.isChanged, isFalse);

      final postAfterFirst = appState.getPostsForEvent(event.id).firstWhere((p) => p.id == pollPost.id);
      expect(postAfterFirst.userVotedPollOptionId, equals('opt_yes'));
      expect(postAfterFirst.pollOptions![0].votes, equals(1));
      expect(postAfterFirst.pollOptions![1].votes, equals(0));

      // 3. User changes vote anytime to 'opt_no' -> ALLOWED & VOTES RECALCULATED
      final changeVoteRes = appState.votePoll(
        eventId: event.id,
        postId: pollPost.id,
        optionId: 'opt_no',
        userLocation: insideLocation,
      );
      expect(changeVoteRes.allowed, isTrue);
      expect(changeVoteRes.isChanged, isTrue);

      final postAfterChange = appState.getPostsForEvent(event.id).firstWhere((p) => p.id == pollPost.id);
      expect(postAfterChange.userVotedPollOptionId, equals('opt_no'));
      expect(postAfterChange.pollOptions![0].votes, equals(0)); // decremented
      expect(postAfterChange.pollOptions![1].votes, equals(1)); // incremented
    });
  });

  group('PollWidget UI tests', () {
    testWidgets('Renders view-only results for users outside geofence', (tester) async {
      final options = [
        PollOption(id: 'opt_a', text: 'Option A', votes: 3),
        PollOption(id: 'opt_b', text: 'Option B', votes: 1),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PollWidget(
              options: options,
              isInsideGeofence: false, // Outside geofence
              userVotedOptionId: null,
              onVote: (_) {},
            ),
          ),
        ),
      );

      // Should show results badge and percentages
      expect(find.text('Results Only (Outside Geofence)'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Physical boundary restricted • View results only'), findsOneWidget);
    });

    testWidgets('Allows on-site user to vote and change vote', (tester) async {
      String? votedOption;
      final options = [
        PollOption(id: 'opt_a', text: 'Option A', votes: 0),
        PollOption(id: 'opt_b', text: 'Option B', votes: 0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PollWidget(
                  options: options,
                  isInsideGeofence: true,
                  userVotedOptionId: votedOption,
                  onVote: (optId) {
                    setState(() {
                      votedOption = optId;
                      for (final o in options) {
                        if (o.id == optId) o.votes = 1;
                        else o.votes = 0;
                      }
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Before voting
      expect(find.text('On-Site Eyewitness Vote'), findsOneWidget);
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);

      // Tap Option A
      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(votedOption, equals('opt_a'));
      expect(find.text('Voted (Change Anytime)'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Now tap Option B to change vote anytime
      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      expect(votedOption, equals('opt_b'));
      expect(find.text('Voted (Change Anytime)'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}
