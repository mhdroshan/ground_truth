const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const User = require('../models/User');
const Post = require('../models/Post');
const { optionalAuth } = require('../middleware/auth');

// Seed journalists dictionary for instant rich profile lookup
const SEED_JOURNALISTS = {
  auth_rajesh: {
    _id: 'auth_rajesh',
    id: 'auth_rajesh',
    name: 'Rajesh K. Sandhu',
    handle: '@rajesh_sandhu',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    trustScore: 97,
    tier: 'Senior Ground Reporter',
    organization: 'The Ground Wire',
    location: 'New Delhi, India',
    followersCount: 18400,
    followingCount: 32,
    verifiedContributions: 142,
    accuracyRating: 98.6,
    helpfulVotes: 1840,
    role: 'journalist',
    deviceModel: 'Pixel 9 Pro (Hardware Keystore Attested)',
    hasAttestationKey: true,
    bio: 'Covering grassroots demonstrations, civil assemblies and public policy with live telemetry verification.',
    xp: 2400,
    level: 5,
    levelTitle: 'Lead Field Correspondent',
    postsCreated: 14,
    verificationsDone: 210,
    commentsAdded: 84,
    tagsCreated: 6,
  },
  auth_ananya: {
    _id: 'auth_ananya',
    id: 'auth_ananya',
    name: 'Ananya Sharma',
    handle: '@ananya_reports',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
    trustScore: 95,
    tier: 'Investigative Eyewitness',
    organization: 'Civic Dispatch',
    location: 'New Delhi, India',
    followersCount: 26500,
    followingCount: 45,
    verifiedContributions: 210,
    accuracyRating: 99.2,
    helpfulVotes: 2650,
    role: 'journalist',
    deviceModel: 'Samsung Galaxy S24 Ultra (Hardware Attested)',
    hasAttestationKey: true,
    bio: 'Fact-checking breaking incidents with forensic device attestation and verified media hashes.',
    xp: 3200,
    level: 7,
    levelTitle: 'Senior Verification Specialist',
    postsCreated: 26,
    verificationsDone: 340,
    commentsAdded: 112,
    tagsCreated: 9,
  },
  auth_rahul_k: {
    _id: 'auth_rahul_k',
    id: 'auth_rahul_k',
    name: 'Dr. Rahul Mathew',
    handle: '@dr_rahul_mathew',
    avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&auto=format&fit=crop&q=80',
    trustScore: 98,
    tier: 'Disaster Response Specialist',
    organization: 'Kerala Emergency Network',
    location: 'Wayanad, India',
    followersCount: 12300,
    followingCount: 18,
    verifiedContributions: 88,
    accuracyRating: 99.4,
    helpfulVotes: 1230,
    role: 'journalist',
    deviceModel: 'iPhone 16 Pro (Secure Enclave Attested)',
    hasAttestationKey: true,
    bio: 'Medical officer and first responder coordinating live ground logistics during cloudbursts and landslides.',
    xp: 1800,
    level: 4,
    levelTitle: 'Emergency Field Specialist',
    postsCreated: 9,
    verificationsDone: 154,
    commentsAdded: 45,
    tagsCreated: 4,
  },
  auth_meera: {
    _id: 'auth_meera',
    id: 'auth_meera',
    name: 'Meera Nambiar',
    handle: '@meera_field',
    avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&auto=format&fit=crop&q=80',
    trustScore: 92,
    tier: 'Public Welfare Observer',
    organization: 'Truth Watch India',
    location: 'New Delhi, India',
    followersCount: 9400,
    followingCount: 28,
    verifiedContributions: 64,
    accuracyRating: 97.9,
    helpfulVotes: 940,
    role: 'journalist',
    deviceModel: 'Pixel 8 Pro (Hardware Keystore)',
    hasAttestationKey: true,
    bio: 'Reporting on emergency medical camps, aid distribution, and civic logistics.',
    xp: 1400,
    level: 3,
    levelTitle: 'Verified Community Observer',
    postsCreated: 7,
    verificationsDone: 98,
    commentsAdded: 62,
    tagsCreated: 3,
  },
  auth_kenji: {
    _id: 'auth_kenji',
    id: 'auth_kenji',
    name: 'Kenji Sato',
    handle: '@kenji_tokyo_eye',
    avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
    trustScore: 94,
    tier: 'Urban Seismic & Transit Lead',
    organization: 'Disaster Pulse Japan',
    location: 'Tokyo, Japan',
    followersCount: 34200,
    followingCount: 52,
    verifiedContributions: 312,
    accuracyRating: 98.9,
    helpfulVotes: 3420,
    role: 'journalist',
    deviceModel: 'Sony Xperia 1 VI (Keystore Attested)',
    hasAttestationKey: true,
    bio: 'Real-time seismic tremor and transit infrastructure verification across the Tokyo Metropolitan area.',
    xp: 4100,
    level: 9,
    levelTitle: 'Master Telemetry Witness',
    postsCreated: 31,
    verificationsDone: 420,
    commentsAdded: 156,
    tagsCreated: 12,
  },
  auth_elena: {
    _id: 'auth_elena',
    id: 'auth_elena',
    name: 'Elena Rostova',
    handle: '@elena_fielddesk',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    trustScore: 91,
    tier: 'European Field Correspondent',
    organization: 'Global Observer Desk',
    location: 'London, UK',
    followersCount: 41000,
    followingCount: 67,
    verifiedContributions: 420,
    accuracyRating: 98.4,
    helpfulVotes: 4100,
    role: 'journalist',
    deviceModel: 'iPhone 15 Pro (Secure Enclave)',
    hasAttestationKey: true,
    bio: 'Covering structural emergencies, major transit strikes and city-wide public demonstrations.',
    xp: 4500,
    level: 9,
    levelTitle: 'Master Telemetry Witness',
    postsCreated: 42,
    verificationsDone: 512,
    commentsAdded: 189,
    tagsCreated: 15,
  },
};

// In-memory follow sets for tracking follows in both DB and memory
// Map of targetUserId -> Set of follower user IDs
const followersMap = new Map();
// Seed default follows for seed journalists
followersMap.set('auth_rajesh', new Set(['seed_guest_user']));
followersMap.set('auth_ananya', new Set(['seed_guest_user']));
followersMap.set('auth_rahul_k', new Set(['seed_guest_user']));
followersMap.set('auth_meera', new Set(['seed_guest_user']));

function isMongoConnected() {
  return mongoose.connection.readyState === 1;
}

// GET /api/users - List and search users
router.get('/', optionalAuth, async (req, res) => {
  try {
    const { search, limit = 20 } = req.query;
    let users = [];

    if (isMongoConnected()) {
      let query = {};
      if (search) {
        query = {
          $or: [
            { name: { $regex: search, $options: 'i' } },
            { handle: { $regex: search, $options: 'i' } },
          ],
        };
      }
      const dbUsers = await User.find(query).limit(parseInt(limit));
      users = dbUsers.map((u) => u.toPublicJSON());
    }

    // Only return real users from database or registered eyewitnesses

    // Annotate whether caller follows each user
    const callerId = req.user?.id || req.query.followerId;
    if (callerId) {
      users = users.map((u) => {
        const uId = u._id || u.id;
        const followers = followersMap.get(uId) || new Set(u.followers || []);
        return {
          ...u,
          isFollowed: followers.has(callerId),
        };
      });
    }

    res.json({ success: true, count: users.length, data: users });
  } catch (err) {
    res.status(500).json({ error: 'FETCH_USERS_FAILED', message: err.message });
  }
});

// GET /api/users/:id - Fetch profile for a specific user
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const targetId = req.params.id;
    const callerId = req.user?.id || req.query.followerId;

    let userObj = null;

    // Check seed journalists first
    if (SEED_JOURNALISTS[targetId]) {
      userObj = { ...SEED_JOURNALISTS[targetId] };
    }

    // Check MongoDB if not found or to get freshest DB user
    if (isMongoConnected()) {
      let query;
      if (mongoose.Types.ObjectId.isValid(targetId)) {
        query = { _id: targetId };
      } else {
        const handleClean = targetId.startsWith('@') ? targetId : `@${targetId}`;
        query = { $or: [{ _id: targetId }, { handle: targetId }, { handle: handleClean }] };
      }

      try {
        const dbUser = await User.findOne(query);
        if (dbUser) {
          userObj = dbUser.toPublicJSON();
        }
      } catch (_) {}
    }

    // If still not found, check if posts exist by this author to construct profile
    if (!userObj && isMongoConnected()) {
      const samplePost = await Post.findOne({ 'author.userId': targetId });
      if (samplePost) {
        userObj = {
          _id: targetId,
          id: targetId,
          name: samplePost.author.name || 'Verified Eyewitness',
          handle: `@${(samplePost.author.name || 'witness').toLowerCase().replace(/\s+/g, '_')}`,
          avatarUrl: samplePost.author.avatar || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
          trustScore: samplePost.author.trustScore || 90,
          tier: samplePost.author.isVerifiedJournalist ? 'Verified Field Reporter' : 'Tier 1 Verified Senior Eyewitness',
          deviceModel: 'Hardware Keystore Attested',
          hasAttestationKey: true,
          bio: 'Active GroundTruth field contributor.',
          followersCount: 124,
          followingCount: 38,
          accuracyRating: 98.5,
          helpfulVotes: 45,
          xp: 650,
          level: 2,
          levelTitle: 'Verified Field Scout',
        };
      }
    }

    if (!userObj) {
      return res.status(404).json({ error: 'USER_NOT_FOUND', message: 'Eyewitness profile not found.' });
    }

    // Compute live followers count & isFollowed
    const uId = userObj._id || userObj.id;
    const dynamicFollowers = followersMap.get(uId) || new Set(userObj.followers || []);
    userObj.followersCount = Math.max(userObj.followersCount || 0, dynamicFollowers.size);
    userObj.isFollowed = callerId ? dynamicFollowers.has(callerId) : false;

    // Count posts in DB
    if (isMongoConnected()) {
      const postsCount = await Post.countDocuments({ 'author.userId': uId });
      if (postsCount > 0) {
        userObj.postsCreated = postsCount;
      }
    }

    res.json({ success: true, user: userObj });
  } catch (err) {
    res.status(500).json({ error: 'FETCH_PROFILE_FAILED', message: err.message });
  }
});

// PUT /api/users/:id - Update user profile information
router.put('/:id', optionalAuth, async (req, res) => {
  try {
    const targetId = req.params.id;
    const { name, handle, email, avatarUrl, bio, location, organization } = req.body;

    // Check seed journalists if modifying a seed account
    if (SEED_JOURNALISTS[targetId]) {
      if (name) SEED_JOURNALISTS[targetId].name = name.trim();
      if (handle) {
        let cleanHandle = handle.trim().toLowerCase();
        if (!cleanHandle.startsWith('@')) cleanHandle = `@${cleanHandle}`;
        SEED_JOURNALISTS[targetId].handle = cleanHandle;
      }
      if (avatarUrl) SEED_JOURNALISTS[targetId].avatarUrl = avatarUrl;
      if (bio !== undefined) SEED_JOURNALISTS[targetId].bio = bio;
      if (location !== undefined) SEED_JOURNALISTS[targetId].location = location;
      if (organization !== undefined) SEED_JOURNALISTS[targetId].organization = organization;

      return res.json({
        success: true,
        message: 'Profile updated successfully.',
        user: SEED_JOURNALISTS[targetId],
      });
    }

    if (isMongoConnected()) {
      let query;
      if (mongoose.Types.ObjectId.isValid(targetId)) {
        query = { _id: targetId };
      } else {
        query = { $or: [{ _id: targetId }, { handle: targetId }] };
      }

      const updates = {};
      if (name) updates.name = name.trim();
      if (handle) {
        let cleanHandle = handle.trim().toLowerCase();
        if (!cleanHandle.startsWith('@')) cleanHandle = `@${cleanHandle}`;
        updates.handle = cleanHandle;
      }
      if (email) updates.email = email.trim().toLowerCase();
      if (avatarUrl) updates.avatarUrl = avatarUrl;
      if (bio !== undefined) updates.bio = bio;
      if (location !== undefined) updates.location = location;
      if (organization !== undefined) updates.organization = organization;

      const updatedUser = await User.findOneAndUpdate(query, { $set: updates }, { new: true });
      if (updatedUser) {
        // Also update posts authored by this user
        try {
          const postUpdates = {};
          if (name) postUpdates['author.name'] = name.trim();
          if (avatarUrl) postUpdates['author.avatar'] = avatarUrl;
          if (Object.keys(postUpdates).length > 0) {
            await Post.updateMany(
              {
                $or: [
                  { 'author.userId': updatedUser._id.toString() },
                  { 'author.id': updatedUser._id.toString() },
                ],
              },
              { $set: postUpdates }
            );
          }
        } catch (_) {}

        return res.json({
          success: true,
          message: 'Profile updated successfully.',
          user: updatedUser.toPublicJSON(),
        });
      }
    }

    // In-memory or fallback
    return res.json({
      success: true,
      message: 'Profile updated successfully (local).',
      user: {
        _id: targetId,
        id: targetId,
        name: name || 'Eyewitness',
        handle: handle || '@eyewitness',
        email: email || '',
        avatarUrl: avatarUrl || '',
        bio: bio || '',
        location: location || '',
        organization: organization || '',
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'UPDATE_PROFILE_FAILED', message: err.message });
  }
});

// POST /api/users/:id/follow - Toggle follow status
router.post('/:id/follow', optionalAuth, async (req, res) => {
  try {
    const targetId = req.params.id;
    const callerId = req.user?.id || req.body.followerId || 'guest_user';
    const callerName = req.user?.name || req.body.followerName || 'Eyewitness';

    if (callerId === targetId) {
      return res.status(400).json({ error: 'CANNOT_FOLLOW_SELF', message: 'You cannot follow yourself.' });
    }

    if (!followersMap.has(targetId)) {
      followersMap.set(targetId, new Set());
    }

    const set = followersMap.get(targetId);
    let isFollowing = false;

    if (set.has(callerId)) {
      // Unfollow
      set.delete(callerId);
      isFollowing = false;
    } else {
      // Follow
      set.add(callerId);
      isFollowing = true;
    }

    let followersCount = set.size;

    // Update seed journalist followersCount if applicable
    if (SEED_JOURNALISTS[targetId]) {
      SEED_JOURNALISTS[targetId].followersCount += isFollowing ? 1 : -1;
      followersCount = SEED_JOURNALISTS[targetId].followersCount;
    }

    // If MongoDB connected, update User documents
    if (isMongoConnected()) {
      try {
        if (mongoose.Types.ObjectId.isValid(targetId)) {
          if (isFollowing) {
            await User.findByIdAndUpdate(targetId, {
              $addToSet: { followers: callerId },
              $inc: { followersCount: 1 },
            });
          } else {
            await User.findByIdAndUpdate(targetId, {
              $pull: { followers: callerId },
              $inc: { followersCount: -1 },
            });
          }
        }

        if (mongoose.Types.ObjectId.isValid(callerId)) {
          if (isFollowing) {
            await User.findByIdAndUpdate(callerId, {
              $addToSet: { following: targetId },
              $inc: { followingCount: 1 },
            });
          } else {
            await User.findByIdAndUpdate(callerId, {
              $pull: { following: targetId },
              $inc: { followingCount: -1 },
            });
          }
        }
      } catch (dbErr) {
        console.warn('DB update during follow failed, memory state active:', dbErr.message);
      }
    }

    res.json({
      success: true,
      message: isFollowing ? `You are now following this contributor.` : `Unfollowed contributor.`,
      isFollowing,
      followersCount,
      targetId,
    });
  } catch (err) {
    res.status(500).json({ error: 'FOLLOW_FAILED', message: err.message });
  }
});

// GET /api/users/:id/posts - Fetch all posts authored by a user
router.get('/:id/posts', async (req, res) => {
  try {
    const targetId = req.params.id;

    if (isMongoConnected()) {
      const posts = await Post.find({
        $or: [
          { 'author.userId': targetId },
          { 'author.id': targetId },
        ],
      }).sort({ createdAt: -1 });

      return res.json({ success: true, count: posts.length, data: posts });
    }

    return res.json({ success: true, count: 0, data: [] });
  } catch (err) {
    res.status(500).json({ error: 'FETCH_USER_POSTS_FAILED', message: err.message });
  }
});

module.exports = router;
