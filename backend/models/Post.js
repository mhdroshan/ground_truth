const mongoose = require('mongoose');

const PollOptionSchema = new mongoose.Schema({
  id: { type: String, required: true },
  text: { type: String, required: true },
  votes: { type: Number, default: 0 },
});

const PostSchema = new mongoose.Schema({
  tagId: { type: String, index: true },
  eventId: { type: String, index: true },
  title: { type: String, trim: true },
  tagName: { type: String, trim: true },

  // Author details
  author: {
    userId: { type: String, required: true },
    name: { type: String, required: true },
    avatar: { type: String, default: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80' },
    trustScore: { type: Number, default: 90 },
    isVerifiedJournalist: { type: Boolean, default: false },
  },
  type: {
    type: String,
    enum: ['TEXT', 'PHOTO', 'VIDEO', 'VOICE_NOTE', 'POLL'],
    default: 'TEXT',
  },
  content: { type: String, required: true },
  mediaUrl: { type: String },
  videoThumbnailUrl: { type: String },
  audioDurationSeconds: { type: Number },
  waveform: [{ type: Number }],
  pollOptions: [PollOptionSchema],
  
  // Exact Ground Coordinate [lng, lat]
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true,
    },
  },
  locationDisplayName: { type: String, default: 'Verified Location' },
  distanceFromEpicenterMeters: { type: Number, default: 0 },

  // Verification Metadata
  verification: {
    isGpsVerified: { type: Boolean, default: true },
    gpsAccuracyMeters: { type: Number, default: 3.5 },
    confidenceScore: { type: Number, default: 98.5 },
    verificationHash: { type: String, required: true },
    verifiedAt: { type: Date, default: Date.now },
  },

  upvotes: { type: Number, default: 0 },
  downvotes: { type: Number, default: 0 },
  voters: [{
    userId: String,
    direction: Number, // 1 for up, -1 for down
  }],
  pollVoters: [{
    userId: String,
    optionId: String,
  }],
  commentsCount: { type: Number, default: 0 },
}, { timestamps: true });

PostSchema.index({ location: '2dsphere' });
PostSchema.index({ createdAt: -1 });
PostSchema.index({ tagId: 1, createdAt: -1 });
PostSchema.index({ eventId: 1, createdAt: -1 });

module.exports = mongoose.model('Post', PostSchema);
