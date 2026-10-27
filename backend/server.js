require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');

const tagRoutes = require('./routes/tags');
const postRoutes = require('./routes/posts');
const commentRoutes = require('./routes/comments');
const placesRoutes = require('./routes/places');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');

const app = express();
const PORT = process.env.PORT || 5001;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/groundtruth';

// Middleware with 50MB payload support for photos/media
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(morgan('dev'));

// Core Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tags', tagRoutes);
app.use('/api/tags/:tagId/posts', postRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/posts/:postId/comments', commentRoutes);
app.use('/api/places', placesRoutes);

// Backward-compatibility aliases for legacy /events endpoints -> mapped directly to tags/posts
app.use('/api/events/:eventId/posts/:postId/comments', commentRoutes);
app.use('/api/events/:eventId/posts', postRoutes);
app.use('/api/events', tagRoutes);

// Health check & Telemetry
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'GroundTruth Verification Engine API',
    database: mongoose.connection.readyState === 1 ? 'CONNECTED' : 'DISCONNECTED',
    geospatialEngine: 'MongoDB 2dsphere v2',
    timestamp: new Date(),
  });
});

// Start Server
app.listen(PORT, () => {
  console.log(`🚀 GroundTruth Backend API running on http://localhost:${PORT}`);
  console.log(`📍 Health endpoint: http://localhost:${PORT}/api/health`);
});

// Connect to MongoDB asynchronously
async function connectDb() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB successfully!');
  } catch (err) {
    console.warn('⚠️ MongoDB not connected yet (retrying or offline):', err.message);
  }
}
connectDb();
