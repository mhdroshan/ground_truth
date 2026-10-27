const mongoose = require('mongoose');

const CommentSchema = new mongoose.Schema({
  postId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Post',
    required: true,
    index: true,
  },
  author: {
    userId: { type: String, required: true },
    name: { type: String, required: true },
    avatar: { type: String, required: true },
    trustScore: { type: Number, required: true },
  },
  text: { type: String, required: true },
  isVerifiedOnSite: { type: Boolean, default: true },
  distanceMeters: { type: Number, default: 0 },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [lng, lat]
      required: true,
    },
  },
}, { timestamps: true });

CommentSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Comment', CommentSchema);
