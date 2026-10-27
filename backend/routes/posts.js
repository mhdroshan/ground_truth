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

    const reqUserId = req.query.userId || req.headers['x-user-id'] || 'user_dev_01';
    const allTags = await Tag.find({}, '_id tagName');
    const tagMap = new Map();
    allTags.forEach(t => tagMap.set(t._id.toString(), t.tagName));

    const formattedPosts = posts.map(p => {
      const obj = p.toObject();
      if (!obj.tagName && (obj.tagId || obj.eventId)) {
        obj.tagName = tagMap.get(obj.tagId?.toString()) || tagMap.get(obj.eventId?.toString());
      }
      const isAuthor = obj.author && (
        obj.author.userId === reqUserId ||
        ((reqUserId === 'user_dev_01' || reqUserId === 'guest_user') &&
         (obj.author.userId === 'user_dev_01' || obj.author.userId === 'guest_user'))
      );
      if (isAuthor) {
        obj.userVote = 0;
      } else if (obj.voters && Array.isArray(obj.voters)) {
        const myVote = obj.voters.find(v => v.userId === reqUserId || (reqUserId !== 'user_dev_01' && v.userId === 'user_dev_01'));
        obj.userVote = myVote ? myVote.direction : 0;
      } else {
        obj.userVote = 0;
      }
      return obj;
    });

    res.json({ success: true, count: formattedPosts.length, data: formattedPosts });
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
    const reqUserId = req.query.userId || req.headers['x-user-id'] || 'user_dev_01';
    const obj = post.toObject();
    const isAuthor = obj.author && (
      obj.author.userId === reqUserId ||
      ((reqUserId === 'user_dev_01' || reqUserId === 'guest_user') &&
       (obj.author.userId === 'user_dev_01' || obj.author.userId === 'guest_user'))
    );
    if (isAuthor) {
      obj.userVote = 0;
    } else if (obj.voters && Array.isArray(obj.voters)) {
      const myVote = obj.voters.find(v => v.userId === reqUserId || (reqUserId !== 'user_dev_01' && v.userId === 'user_dev_01'));
      obj.userVote = myVote ? myVote.direction : 0;
    } else {
      obj.userVote = 0;
    }
    res.json({ success: true, data: obj });
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
      pollOptions: (type && type.toUpperCase() === 'POLL' && Array.isArray(pollOptions))
        ? pollOptions.map((opt, idx) => ({
            id: opt.id || `opt_${idx + 1}`,
            text: typeof opt === 'string' ? opt : (opt.text || ''),
            votes: typeof opt.votes === 'number' ? opt.votes : 0,
          }))
        : undefined,
      location: {
        type: 'Point',
        coordinates: [lng, lat],
      },
      locationDisplayName: (() => {
        const tagLoc = req.targetTag
          ? (req.targetTag.country && !req.targetTag.city.toLowerCase().includes(req.targetTag.country.toLowerCase())
              ? `${req.targetTag.city}, ${req.targetTag.country}`
              : req.targetTag.city)
          : null;
        if (locationDisplayName &&
            !locationDisplayName.toLowerCase().includes('physical location') &&
            !locationDisplayName.toLowerCase().includes('verification')) {
          return locationDisplayName;
        }
        return tagLoc || 'Verified Location';
      })(),
      distanceFromEpicenterMeters: 0,
      verification: {
        isGpsVerified: true,
        gpsAccuracyMeters: gpsAccuracy,
        confidenceScore,
        verificationHash,
        verifiedAt: new Date(),
      },
      upvotes: 0,
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

// POST /api/posts/:id/poll-vote - Submit verified eyewitness vote on poll (Requires on-site geofence)
router.post('/:id/poll-vote', validateGeofence, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(404).json({ error: 'NOT_FOUND', message: 'Post not found' });
    }
    const { optionId, userId } = req.body;
    if (!optionId) {
      return res.status(400).json({ error: 'MISSING_OPTION', message: 'optionId is required' });
    }

    const post = req.parentPost || await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ error: 'NOT_FOUND', message: 'Post not found' });

    if (post.type !== 'POLL' || !post.pollOptions || post.pollOptions.length === 0) {
      return res.status(400).json({ error: 'NOT_A_POLL', message: 'This post is not an active poll' });
    }

    const voterId = userId || 'user_dev_01';
    const isAuthor = post.author && (
      post.author.userId === voterId ||
      ((voterId === 'user_dev_01' || voterId === 'guest_user') &&
       (post.author.userId === 'user_dev_01' || post.author.userId === 'guest_user'))
    );
    if (isAuthor) {
      return res.status(403).json({ error: 'CANNOT_VOTE_OWN_POST', message: 'You cannot participate in your own poll' });
    }
    if (post.pollVoters && post.pollVoters.some(v => v.userId === voterId)) {
      return res.status(400).json({ error: 'ALREADY_VOTED', message: 'You have already participated in this poll' });
    }

    const option = post.pollOptions.find(o => o.id === optionId);
    if (!option) {
      return res.status(404).json({ error: 'OPTION_NOT_FOUND', message: 'Poll option not found' });
    }

    option.votes = (option.votes || 0) + 1;
    if (!post.pollVoters) post.pollVoters = [];
    post.pollVoters.push({ userId: voterId, optionId });

    await post.save();
    console.log(`✅ Stored poll vote on post ${post._id} for option ${optionId} by ${voterId}`);

    res.json({
      success: true,
      data: post,
      userVotedOptionId: optionId,
    });
  } catch (err) {
    console.error('Poll vote error:', err);
    res.status(500).json({ error: 'POLL_VOTE_FAILED', message: err.message });
  }
});

// POST /api/posts/:id/vote - Verified upvote/downvote with geofence validation
router.post('/:id/vote', validateGeofence, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(404).json({ error: 'NOT_FOUND', message: 'Post not found' });
    }
    const { direction = 0 } = req.body;
    const userId = req.body.userId || req.headers['x-user-id'] || 'user_dev_01';
    const post = req.parentPost || await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ error: 'NOT_FOUND', message: 'Post not found' });

    const isAuthor = post.author && (
      post.author.userId === userId ||
      ((userId === 'user_dev_01' || userId === 'guest_user') &&
       (post.author.userId === 'user_dev_01' || post.author.userId === 'guest_user'))
    );
    if (isAuthor) {
      return res.status(403).json({ error: 'CANNOT_VOTE_OWN_POST', message: 'You cannot vote on your own post' });
    }

    if (!post.voters) {
      post.voters = [];
    }

    const existingVoterIndex = post.voters.findIndex(v => v.userId === userId);
    let prevDirection = 0;
    if (existingVoterIndex !== -1) {
      prevDirection = post.voters[existingVoterIndex].direction;
    }

    let finalDirection = direction;

    // RULE: If the user already upvoted or downvoted this post, clicking again removes that vote.
    // Also if direction === 0, remove that vote.
    if (direction === prevDirection || direction === 0) {
      // Toggle off / remove vote
      if (prevDirection === 1) {
        post.upvotes = Math.max(0, (post.upvotes || 0) - 1);
      } else if (prevDirection === -1) {
        post.downvotes = Math.max(0, (post.downvotes || 0) - 1);
      }
      if (existingVoterIndex !== -1) {
        post.voters.splice(existingVoterIndex, 1);
      }
      finalDirection = 0;
    } else {
      // Revert previous vote impact if any
      if (prevDirection === 1) {
        post.upvotes = Math.max(0, (post.upvotes || 0) - 1);
      } else if (prevDirection === -1) {
        post.downvotes = Math.max(0, (post.downvotes || 0) - 1);
      }

      // Apply new direction
      if (direction === 1) {
        post.upvotes = (post.upvotes || 0) + 1;
        if (existingVoterIndex !== -1) {
          post.voters[existingVoterIndex].direction = 1;
        } else {
          post.voters.push({ userId, direction: 1 });
        }
        finalDirection = 1;
      } else if (direction === -1) {
        post.downvotes = (post.downvotes || 0) + 1;
        if (existingVoterIndex !== -1) {
          post.voters[existingVoterIndex].direction = -1;
        } else {
          post.voters.push({ userId, direction: -1 });
        }
        finalDirection = -1;
      }
    }

    await post.save();
    console.log(`✅ Stored post vote on ${post._id} by ${userId}. Requested: ${direction}, Final: ${finalDirection}, upvotes: ${post.upvotes}, downvotes: ${post.downvotes}`);

    const postObj = post.toObject();
    postObj.userVote = finalDirection;

    res.json({ success: true, data: postObj, userVote: finalDirection });
  } catch (err) {
    console.error('Post vote error:', err);
    res.status(500).json({ error: 'VOTE_FAILED', message: err.message });
  }
});

module.exports = router;
