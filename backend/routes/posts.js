const express = require('express');
const mongoose = require('mongoose');
const router = express.Router({ mergeParams: true });
const Post = require('../models/Post');
const Tag = require('../models/Tag');
const validateGeofence = require('../middleware/geofenceValidator');

// GET /api/posts - Get all posts with optional filtering
router.get('/', async (req, res) => {
  try {
    const { search, type, tab, sortBy = 'mostReliable', eventId, tagId } = req.query;
    let query = {};

    const targetTagId = tagId || eventId || req.params.tagId || req.params.eventId;
    if (targetTagId) {
      query.$or = [{ tagId: targetTagId }, { eventId: targetTagId }];
    }

    if (type) {
      query.type = type.toUpperCase();
    }

    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { tagName: { $regex: search, $options: 'i' } },
        { content: { $regex: search, $options: 'i' } },
      ];
    }

    let sort = { createdAt: -1 };
    if (tab === 'trending') {
      sort = { upvotes: -1, commentsCount: -1 };
    }

    let posts = await Post.find(query).sort(sort).limit(100);

    if (sortBy === 'mostUpvoted') {
      posts.sort((a, b) => (b.upvotes - b.downvotes) - (a.upvotes - a.downvotes));
    } else if (sortBy === 'mostReliable') {
      posts.sort((a, b) => {
        const scoreA = ((a.upvotes * 1.5) - (a.downvotes * 2.0)) + ((a.author?.trustScore || 80) * 0.4) + ((a.verification?.confidenceScore || 90) * 0.4);
        const scoreB = ((b.upvotes * 1.5) - (b.downvotes * 2.0)) + ((b.author?.trustScore || 80) * 0.4) + ((b.verification?.confidenceScore || 90) * 0.4);
        return scoreB - scoreA;
      });
    }

    res.json({ success: true, count: posts.length, data: posts });
  } catch (err) {
    res.status(500).json({ error: 'FETCH_POSTS_FAILED', message: err.message });
  }
});

// GET /api/posts/nearby - MongoDB $nearSphere query
router.get('/nearby', async (req, res) => {
  try {
    const { lat, lng, maxDistanceMeters = 50000 } = req.query;
    if (!lat || !lng) {
      return res.status(400).json({ error: 'MISSING_COORDINATES', message: 'lat and lng required' });
    }

    const posts = await Post.find({
      location: {
        $nearSphere: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)],
          },
          $maxDistance: parseInt(maxDistanceMeters),
        },
      },
    }).limit(50);

    res.json({ success: true, count: posts.length, data: posts });
  } catch (err) {
    res.status(500).json({ error: 'NEARBY_QUERY_FAILED', message: err.message });
  }
});

// GET /api/posts/:id - Get single post details
router.get('/:id', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(404).json({ error: 'NOT_FOUND', message: 'Post not found' });
    }
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ error: 'NOT_FOUND', message: 'Post not found' });
    res.json({ success: true, data: post });
  } catch (err) {
    res.status(500).json({ error: 'FETCH_FAILED', message: err.message });
  }
});

// POST /api/posts - Create new verified post
router.post('/', validateGeofence, async (req, res) => {
  try {
    const {
      tagId,
      eventId,
      title,
      tagName,
      type = 'TEXT',
      content,
      mediaUrl,
      videoThumbnailUrl,
      audioDurationSeconds,
      waveform,
      pollOptions,
      author,
      locationDisplayName,
      latitude,
      longitude,
      gpsAccuracy = 4.2,
      confidenceScore = 99.1,
    } = req.body;

    const lat = parseFloat(latitude !== undefined ? latitude : (req.point ? req.point[1] : 28.6271));
    const lng = parseFloat(longitude !== undefined ? longitude : (req.point ? req.point[0] : 77.2185));

    const parentTagId = tagId || eventId || req.params.tagId || req.params.eventId;
    const parentTagName = tagName || (req.targetTag ? req.targetTag.tagName : undefined);
    const parentTitle = title || (req.targetTag ? req.targetTag.title : 'Verified Eyewitness Report');

    const verificationHash = `GT-SEC-${Date.now().toString(16).toUpperCase()}-${Math.random().toString(36).substring(2, 8).toUpperCase()}-V8`;

    const newPost = new Post({
      tagId: parentTagId,
      eventId: parentTagId,
      title: parentTitle ? parentTitle.trim() : 'Verified Eyewitness Report',
      tagName: parentTagName ? (parentTagName.startsWith('#') ? parentTagName : `#${parentTagName.replace(/\s+/g, '')}`) : undefined,
      author: author ? {
        userId: author.userId || 'user_dev_01',
        name: author.name || 'Verified Eyewitness',
        avatar: author.avatar || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
        trustScore: typeof author.trustScore === 'number' ? author.trustScore : 90,
        isVerifiedJournalist: Boolean(author.isVerifiedJournalist),
      } : {
        userId: 'user_dev_01',
        name: 'Verified Eyewitness',
        avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
        trustScore: 94,
        isVerifiedJournalist: false,
      },
      type: type ? type.toUpperCase() : 'TEXT',
      content: content || parentTitle || 'Verified field report from ground coordinates.',
      mediaUrl,
      videoThumbnailUrl,
      audioDurationSeconds,
      waveform,
      pollOptions,
      location: {
        type: 'Point',
        coordinates: [lng, lat],
      },
      locationDisplayName: locationDisplayName || 'On-Site Verification Point',
      distanceFromEpicenterMeters: 0,
      verification: {
        isGpsVerified: true,
        gpsAccuracyMeters: gpsAccuracy,
        confidenceScore,
        verificationHash,
        verifiedAt: new Date(),
      },
      upvotes: 1,
    });

    await newPost.save();
    console.log(`✅ Stored post in MongoDB [posts]: ${newPost._id} for tag: ${parentTagId}`);

    if (parentTagId && mongoose.Types.ObjectId.isValid(parentTagId)) {
      await Tag.findByIdAndUpdate(parentTagId, { $inc: { totalPosts: 1 } }).catch(() => {});
    }

    res.status(201).json({ success: true, data: newPost });
  } catch (err) {
    console.error('Create post error:', err);
    res.status(500).json({ error: 'CREATE_POST_FAILED', message: err.message });
  }
});

// POST /api/posts/:id/vote
router.post('/:id/vote', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(404).json({ error: 'NOT_FOUND', message: 'Post not found' });
    }
    const { direction, userId } = req.body; // 1 for up, -1 for down, 0 for none
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ error: 'NOT_FOUND', message: 'Post not found' });

    if (direction === 1) {
      post.upvotes += 1;
    } else if (direction === -1) {
      post.downvotes += 1;
    }
    await post.save();
    res.json({ success: true, data: post });
  } catch (err) {
    res.status(500).json({ error: 'VOTE_FAILED', message: err.message });
  }
});

module.exports = router;
