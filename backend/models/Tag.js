const mongoose = require('mongoose');

const TagSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true },
  tagName: { type: String, required: true, trim: true, unique: true },
  description: { type: String, required: true },
  scope: {
    type: String,
    enum: ['Hyper-Local', 'City-Wide', 'State-Wide', 'Nation-Wide', 'Global', 'City Wide', 'State Wide', 'Nation Wide'],
    default: 'City Wide',
  },
  category: {
    type: String,
    enum: [
      'Protest',
      'Natural Disaster',
      'War / Conflict',
      'Fire Emergency',
      'Election',
      'Accident',
      'Crime',
      'Extreme Weather',
      'Public Gathering',
      'Breaking News',
    ],
    required: true,
  },
  riskLevel: {
    type: String,
    enum: ['CRITICAL RISK', 'HIGH RISK', 'MODERATE RISK', 'LOW RISK'],
    default: 'HIGH RISK',
  },
  status: {
    type: String,
    enum: ['LIVE EVENT', 'BREAKING', 'ACTIVE', 'MONITORING', 'CONCLUDED'],
    default: 'LIVE EVENT',
  },
  city: { type: String, required: true, default: 'Metro Region' },
  country: { type: String, required: true, default: 'Global' },
  bannerImageUrl: { type: String },
  
  // Center Coordinate of Tag Epicenter [lng, lat]
  center: {
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

  radiusMeters: { type: Number, default: 2000 },
  radiusUnit: { type: String, default: 'km' },

  // MongoDB 2dsphere GeoJSON Polygon for Irregular Boundaries
  geofencePolygon: {
    type: {
      type: String,
      enum: ['Polygon'],
    },
    coordinates: {
      type: [[[Number]]], // Array of linear rings of [lng, lat]
    },
  },

  activeContributors: { type: Number, default: 1 },
  totalPosts: { type: Number, default: 0 },
  totalVideos: { type: Number, default: 0 },
  verificationLevel: {
    type: String,
    default: 'Multi-Layer Level 3 Enforced',
  },
  isTrending: { type: Boolean, default: false },
  isHighActivity: { type: Boolean, default: false },
  startTime: { type: Date, default: Date.now },
  endTime: { type: Date },
}, { timestamps: true });

// Geospatial 2dsphere indexes for real-time proximity and polygon containment queries
TagSchema.index({ center: '2dsphere' });
TagSchema.index({ geofencePolygon: '2dsphere' });
TagSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Tag', TagSchema, 'tags');
