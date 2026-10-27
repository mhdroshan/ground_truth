require('dotenv').config();
const mongoose = require('mongoose');
const Event = require('./models/Event');
const Post = require('./models/Post');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/groundtruth';

async function seedData() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB for seeding...');

    await Event.deleteMany({});
    await Post.deleteMany({});
    console.log('Cleared existing collections.');

    // Delhi Protest Polygon Coordinates in GeoJSON [lng, lat]
    const delhiPolygonCoords = [
      [77.2195, 28.6328], // Connaught Place
      [77.2166, 28.6271], // Jantar Mantar
      [77.2081, 28.6172], // Parliament Road
      [77.2295, 28.6129], // India Gate
      [77.2340, 28.6225], // Barakhamba
      [77.2195, 28.6328], // Closed loop
    ];

    const delhiEvent = await Event.create({
      title: 'Farmers March & Parliament Demonstration',
      description: 'Large-scale verified gathering along Parliament Road, Jantar Mantar, and central transit arteries demanding MSP legal guarantee.',
      category: 'Protest',
      riskLevel: 'HIGH RISK',
      status: 'LIVE EVENT',
      city: 'New Delhi',
      country: 'India',
      center: {
        type: 'Point',
        coordinates: [77.2166, 28.6271],
      },
      radiusMeters: 2200,
      geofencePolygon: {
        type: 'Polygon',
        coordinates: [delhiPolygonCoords],
      },
      bannerImageUrl: 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&auto=format&fit=crop&q=80',
      activeContributors: 3420,
      totalPosts: 814,
      totalVideos: 192,
      isTrending: true,
      isHighActivity: true,
    });

    const keralaEvent = await Event.create({
      title: 'Wayanad Meppadi Flash Flood & Landslide Rescue',
      description: 'Urgent flash floods and secondary hill debris triggered by torrential cloudburst. Emergency rescue operations underway across Meppadi and Chooralmala.',
      category: 'Natural Disaster',
      riskLevel: 'CRITICAL RISK',
      status: 'BREAKING',
      city: 'Wayanad, Kerala',
      country: 'India',
      center: {
        type: 'Point',
        coordinates: [76.1260, 11.5540],
      },
      radiusMeters: 3500,
      bannerImageUrl: 'https://images.unsplash.com/photo-1547683905-f686c993aae5?w=800&auto=format&fit=crop&q=80',
      activeContributors: 1280,
      totalPosts: 420,
      totalVideos: 86,
      isTrending: true,
      isHighActivity: true,
    });

    // Seed post for Delhi Event
    await Post.create({
      eventId: delhiEvent._id,
      author: {
        userId: 'auth_rajesh',
        name: 'Rajesh K. Sandhu',
        avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
        trustScore: 97,
        isVerifiedJournalist: true,
      },
      type: 'PHOTO',
      content: 'Barricades opened at Tolstoy Marg intersection after peaceful discussion between union reps and Delhi Police commissioner.',
      mediaUrl: 'https://images.unsplash.com/photo-1574786198875-49f5d09fe2d5?w=800&auto=format&fit=crop&q=80',
      location: {
        type: 'Point',
        coordinates: [77.2185, 28.6274],
      },
      locationDisplayName: '110m from Jantar Mantar Stage',
      distanceFromEpicenterMeters: 110,
      verification: {
        isGpsVerified: true,
        gpsAccuracyMeters: 3.4,
        isDeviceIntegrityVerified: true,
        deviceIntegrityProvider: 'Google Play Integrity (MEETS_STRONG_INTEGRITY)',
        isNetworkVerified: true,
        networkSignals: 'Airtel 5G NSA + 4 Local BSSID Handshakes',
        mockLocationPassed: true,
        rootJailbreakPassed: true,
        confidenceScore: 99.4,
        verificationHash: 'GT-SEC-9F2B-DELHI-01',
      },
      upvotes: 342,
      downvotes: 4,
      commentsCount: 28,
    });

    console.log('✅ Seed completed successfully with 2dsphere geofenced events and posts!');
    process.exit(0);
  } catch (err) {
    console.error('Seed error:', err);
    process.exit(1);
  }
}

seedData();
