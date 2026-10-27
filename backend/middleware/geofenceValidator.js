const Post = require('../models/Post');
const Tag = require('../models/Tag');

/**
 * Server-Side Multi-Layer Location & Geofence Validator
 * If target post or tag has an active geofence/radius, verifies submission coordinates.
 */
module.exports = async function validateGeofence(req, res, next) {
  try {
    const { postId, tagId: paramTagId, eventId: paramEventId } = req.params;
    const { latitude, longitude, gpsAccuracy, mockLocationDetected, deviceRooted, tagId: bodyTagId, eventId: bodyEventId } = req.body;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        error: 'MISSING_COORDINATES',
        message: 'Physical GPS coordinates [latitude, longitude] are required for ground truth verification.',
      });
    }

    // 1. Anti-Spoofing & OS Integrity Check
    if (mockLocationDetected) {
      return res.status(403).json({
        error: 'MOCK_GPS_DETECTED',
        message: 'Security Alert: Mock location provider flagged. Submission blocked.',
      });
    }

    if (deviceRooted) {
      return res.status(403).json({
        error: 'COMPROMISED_ENVIRONMENT',
        message: 'Hardware attestation check failed. Tampered or rooted OS detected.',
      });
    }

    if (gpsAccuracy > 15.0) {
      return res.status(403).json({
        error: 'INSUFFICIENT_ACCURACY',
        message: `GNSS accuracy of ${gpsAccuracy}m exceeds forensic 15m threshold.`,
      });
    }

    const point = [parseFloat(longitude), parseFloat(latitude)]; // GeoJSON order: [lng, lat]

    // Validate against parent Tag / Event boundary if present
    const targetTagId = paramTagId || paramEventId || bodyTagId || bodyEventId;
    if (targetTagId) {
      let targetTag;
      if (typeof targetTagId === 'string' && targetTagId.match(/^[0-9a-fA-F]{24}$/)) {
        targetTag = await Tag.findById(targetTagId);
      }
      if (!targetTag) {
        targetTag = await Tag.findOne({
          $or: [
            { tagName: targetTagId },
            { tagName: targetTagId.startsWith('#') ? targetTagId : `#${targetTagId}` },
            { title: targetTagId },
          ],
        });
      }

      if (targetTag && targetTag.center && targetTag.center.coordinates) {
        if (targetTag.geofencePolygon && targetTag.geofencePolygon.coordinates && targetTag.geofencePolygon.coordinates.length > 0) {
          const match = await Tag.findOne({
            _id: targetTag._id,
            geofencePolygon: {
              $geoIntersects: {
                $geometry: {
                  type: 'Point',
                  coordinates: point,
                },
              },
            },
          });
          if (!match) {
            return res.status(403).json({
              error: 'OUTSIDE_GEOFENCE',
              message: `Access Denied: You are outside the verified boundary for ${targetTag.tagName || targetTag.title}.`,
            });
          }
        } else if (targetTag.radiusMeters) {
          const earthRadiusMeters = 6371000.0;
          const centerLng = targetTag.center.coordinates[0];
          const centerLat = targetTag.center.coordinates[1];

          const dLat = (latitude - centerLat) * Math.PI / 180;
          const dLon = (longitude - centerLng) * Math.PI / 180;
          const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                    Math.cos(centerLat * Math.PI / 180) * Math.cos(latitude * Math.PI / 180) *
                    Math.sin(dLon/2) * Math.sin(dLon/2);
          const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
          const distanceMeters = earthRadiusMeters * c;

          if (distanceMeters > targetTag.radiusMeters) {
            return res.status(403).json({
              error: 'OUTSIDE_GEOFENCE',
              message: `Access Denied: You are outside the verified radius (${targetTag.radiusMeters}m) for ${targetTag.tagName || targetTag.title}.`,
            });
          }
        }
        req.targetTag = targetTag;
      }
    }

    // If validating for a specific post (e.g. comments or updates)
    if (postId) {
      if (typeof postId === 'string' && postId.match(/^[0-9a-fA-F]{24}$/)) {
        const parentPost = await Post.findById(postId);
        if (parentPost) {
          req.parentPost = parentPost;
        }
      }
    }

    req.point = point;
    next();
  } catch (err) {
    console.error('Geofence validation error:', err);
    res.status(500).json({ error: 'INTERNAL_ERROR', message: err.message });
  }
};
