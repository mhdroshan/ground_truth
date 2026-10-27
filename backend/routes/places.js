const express = require('express');
const router = express.Router();

const PLACES_API_KEY = process.env.GOOGLE_PLACES_API_KEY || 'AIzaSyBycwvUgtnMcL03IkDesXju5vc18IjAWqM';

// GET /api/places/autocomplete?query=Delhi
router.get('/autocomplete', async (req, res) => {
  try {
    const { query } = req.query;
    if (!query || !query.trim()) {
      return res.json({ suggestions: [] });
    }

    const response = await fetch('https://places.googleapis.com/v1/places:autocomplete', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': PLACES_API_KEY,
      },
      body: JSON.stringify({
        input: query.trim(),
      }),
    });

    const data = await response.json();
    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    const suggestions = (data.suggestions || []).map((item) => {
      const pred = item.placePrediction || {};
      return {
        placeId: pred.placeId || (pred.place ? pred.place.replace('places/', '') : ''),
        text: pred.text?.text || '',
        mainText: pred.structuredFormat?.mainText?.text || pred.text?.text || '',
        secondaryText: pred.structuredFormat?.secondaryText?.text || '',
        types: pred.types || [],
      };
    });

    res.json({ suggestions });
  } catch (err) {
    console.error('Places Autocomplete Proxy Error:', err);
    res.status(500).json({ error: 'PLACES_AUTOCOMPLETE_FAILED', message: err.message });
  }
});

// GET /api/places/details?placeId=...
router.get('/details', async (req, res) => {
  try {
    const { placeId } = req.query;
    if (!placeId) {
      return res.status(400).json({ error: 'MISSING_PLACE_ID', message: 'placeId is required' });
    }

    const cleanId = placeId.startsWith('places/') ? placeId.replace('places/', '') : placeId;
    const url = `https://places.googleapis.com/v1/places/${cleanId}?fields=id,displayName,formattedAddress,location&key=${PLACES_API_KEY}`;

    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();
    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    res.json({
      placeId: data.id,
      name: data.displayName?.text || '',
      formattedAddress: data.formattedAddress || '',
      latitude: data.location?.latitude,
      longitude: data.location?.longitude,
    });
  } catch (err) {
    console.error('Places Details Proxy Error:', err);
    res.status(500).json({ error: 'PLACES_DETAILS_FAILED', message: err.message });
  }
});

module.exports = router;
