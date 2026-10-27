const express = require('express');
const router = express.Router();
const Tag = require('../models/Tag');

// GET /api/tags - List tags with optional search, category, and sorting
router.get('/', async (req, res) => {
  try {
    const { category, search, tab } = req.query;
    let query = {};

    if (category) {
      query.category = category;
    }

    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { tagName: { $regex: search, $options: 'i' } },
        { city: { $regex: search, $options: 'i' } },
        { country: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    let sort = { createdAt: -1 };
    if (tab === 'trending') {
      sort = { activeContributors: -1, totalPosts: -1 };
    } else if (tab === 'live') {
      query.status = { $in: ['LIVE EVENT', 'BREAKING'] };
    } else if (tab === 'highActivity') {
      query.$or = [{ isHighActivity: true }, { activeContributors: { $gt: 100 } }];
    }

    const tags = await Tag.find(query).sort(sort).limit(100);
    res.json({ success: true, count: tags.length, data: tags });
  } catch (err) {
    res.status(500).json({ error: 'QUERY_TAGS_FAILED', message: err.message });
  }
});

// GET /api/tags/nearby - Geospatial $nearSphere query
router.get('/nearby', async (req, res) => {
  try {
    const { lat, lng, maxDistanceMeters = 50000 } = req.query;
    if (!lat || !lng) {
      return res.status(400).json({ error: 'MISSING_COORDINATES', message: 'lat and lng required' });
    }

    const tags = await Tag.find({
      center: {
        $nearSphere: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)],
          },
          $maxDistance: parseInt(maxDistanceMeters),
        },
      },
    }).limit(50);

    res.json({ success: true, count: tags.length, data: tags });
  } catch (err) {
    res.status(500).json({ error: 'NEARBY_TAGS_FAILED', message: err.message });
  }
});

// GET /api/tags/:id - Get single tag by id or tagName
router.get('/:id', async (req, res) => {
  try {
    const idOrName = req.params.id;
    let tag;
    if (idOrName.match(/^[0-9a-fA-F]{24}$/)) {
      tag = await Tag.findById(idOrName);
    }
    if (!tag) {
      tag = await Tag.findOne({
        $or: [
          { tagName: idOrName },
          { tagName: idOrName.startsWith('#') ? idOrName : `#${idOrName}` },
          { title: idOrName },
        ],
      });
    }

    if (!tag) return res.status(404).json({ error: 'NOT_FOUND', message: 'Tag not found' });
    res.json({ success: true, data: tag });
  } catch (err) {
    res.status(500).json({ error: 'FETCH_TAG_FAILED', message: err.message });
  }
});

// POST /api/tags - Create new event tag in MongoDB `tags` collection
router.post('/', async (req, res) => {
  try {
    const {
      title,
      tagName,
      description,
      category = 'Breaking News',
      scope = 'City Wide',
      riskLevel = 'HIGH RISK',
      status = 'LIVE EVENT',
      city,
      country,
      bannerImageUrl,
      latitude,
      longitude,
      radiusMeters = 2000,
      radiusUnit = 'km',
      polygonVertices,
    } = req.body;

    if (!title) {
      return res.status(400).json({ error: 'MISSING_TITLE', message: 'Title / Tag Name is required' });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ error: 'INVALID_COORDINATES', message: 'Valid latitude and longitude are required' });
    }

    const cleanTitle = title.trim();
    const formattedTagName = tagName
      ? (tagName.startsWith('#') ? tagName.trim() : `#${tagName.trim().replace(/\s+/g, '')}`)
      : (cleanTitle.startsWith('#') ? cleanTitle : `#${cleanTitle.replace(/\s+/g, '')}`);

    const defaultBanners = {
      'Protest': 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&auto=format&fit=crop&q=80',
      'Natural Disaster': 'https://images.unsplash.com/photo-1547683905-f686c993aae5?w=800&auto=format&fit=crop&q=80',
      'War / Conflict': 'https://images.unsplash.com/photo-1541888946425-d0fbb186c5f7?w=800&auto=format&fit=crop&q=80',
      'Fire Emergency': 'https://images.unsplash.com/photo-1541888946425-d0fbb186c5f7?w=800&auto=format&fit=crop&q=80',
      'Election': 'https://images.unsplash.com/photo-1540910419892-4a36d2c3266c?w=800&auto=format&fit=crop&q=80',
      'Accident': 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800&auto=format&fit=crop&q=80',
      'Crime': 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800&auto=format&fit=crop&q=80',
      'Extreme Weather': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800&auto=format&fit=crop&q=80',
      'Public Gathering': 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800&auto=format&fit=crop&q=80',
      'Breaking News': 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800&auto=format&fit=crop&q=80',
    };

    let geofencePolygonData;
    if (polygonVertices && Array.isArray(polygonVertices) && polygonVertices.length >= 3) {
      const ring = polygonVertices.map(v => [v.longitude || v.lng, v.latitude || v.lat]);
      if (ring[0][0] !== ring[ring.length - 1][0] || ring[0][1] !== ring[ring.length - 1][1]) {
        ring.push(ring[0]);
      }
      geofencePolygonData = {
        type: 'Polygon',
        coordinates: [ring],
      };
    }

    // Check if tag already exists by tagName
    let existingTag = await Tag.findOne({ tagName: formattedTagName });
    if (existingTag) {
      existingTag.title = cleanTitle;
      existingTag.description = description ? description.trim() : existingTag.description;
      existingTag.category = category;
      existingTag.scope = scope;
      existingTag.center = { type: 'Point', coordinates: [lng, lat] };
      existingTag.radiusMeters = parseFloat(radiusMeters) || existingTag.radiusMeters;
      if (city) existingTag.city = city;
      if (bannerImageUrl) existingTag.bannerImageUrl = bannerImageUrl;
      await existingTag.save();
      return res.status(200).json({ success: true, data: existingTag, updated: true });
    }

    const newTag = new Tag({
      title: cleanTitle,
      tagName: formattedTagName,
      description: description ? description.trim() : `Community verified eyewitness tag for ${cleanTitle}.`,
      category,
      scope: scope || 'City Wide',
      riskLevel: riskLevel || 'HIGH RISK',
      status: status || 'LIVE EVENT',
      city: city || 'Metro Region',
      country: country || 'Verified Ground',
      bannerImageUrl: bannerImageUrl || defaultBanners[category] || defaultBanners['Breaking News'],
      center: {
        type: 'Point',
        coordinates: [lng, lat],
      },
      radiusMeters: parseFloat(radiusMeters) || 2000,
      radiusUnit: radiusUnit || 'km',
      geofencePolygon: geofencePolygonData,
      activeContributors: 1,
      totalPosts: 0,
      totalVideos: 0,
      isTrending: true,
      verificationLevel: 'Multi-Layer Level 3 Enforced',
      startTime: new Date(),
    });

    await newTag.save();
    console.log(`✅ Stored tag in MongoDB [tags]: ${newTag.tagName} (${newTag._id})`);
    res.status(201).json({ success: true, data: newTag });
  } catch (err) {
    console.error('Create tag error:', err);
    res.status(500).json({ error: 'CREATE_TAG_FAILED', message: err.message });
  }
});

module.exports = router;
