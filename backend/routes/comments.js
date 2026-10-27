const express = require('express');
const router = express.Router({ mergeParams: true });
const Comment = require('../models/Comment');
const Post = require('../models/Post');
const validateGeofence = require('../middleware/geofenceValidator');

// GET /api/posts/:postId/comments
router.get('/', async (req, res) => {
  try {
    const { postId } = req.params;
    if (!postId || !postId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.json({ success: true, count: 0, data: [] });
    }
    const comments = await Comment.find({ postId }).sort({ createdAt: 1 });
    res.json({ success: true, count: comments.length, data: comments });
  } catch (err) {
    res.status(500).json({ error: 'FETCH_COMMENTS_FAILED', message: err.message });
  }
});

// POST /api/posts/:postId/comments (Location-gated!)
router.post('/', validateGeofence, async (req, res) => {
  try {
    const { postId } = req.params;
    if (!postId || !postId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ error: 'INVALID_POST_ID', message: 'Valid MongoDB Post ID required' });
    }
    const { text, author } = req.body;

    const comment = new Comment({
      postId,
      author: author || {
        userId: 'user_dev_01',
        name: 'Verified Eyewitness',
        avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
        trustScore: 94,
      },
      text,
      isVerifiedOnSite: true,
      location: {
        type: 'Point',
        coordinates: req.point || [77.2185, 28.6274],
      },
    });

    await comment.save();
    await Post.findByIdAndUpdate(postId, { $inc: { commentsCount: 1 } });

    res.status(201).json({ success: true, data: comment });
  } catch (err) {
    res.status(500).json({ error: 'CREATE_COMMENT_FAILED', message: err.message });
  }
});

module.exports = router;
