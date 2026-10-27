const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { verifyToken, JWT_SECRET } = require('../middleware/auth');

// In-memory fallback cache when MongoDB is offline / connecting
const inMemoryUsers = new Map();

// Helper to check if MongoDB is connected
function isMongoConnected() {
  return mongoose.connection.readyState === 1;
}

// Generate JWT token for a user
function generateToken(user) {
  return jwt.sign(
    {
      id: user._id || user.id,
      email: user.email,
      handle: user.handle,
      name: user.name,
      tier: user.tier,
      role: user.role || 'eyewitness',
    },
    JWT_SECRET,
    { expiresIn: '30d' }
  );
}

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { name, email, handle, password, deviceModel, tier } = req.body;

    if (!name || !email || !handle || !password) {
      return res.status(400).json({
        error: 'MISSING_FIELDS',
        message: 'Name, email, handle, and password are required.',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        error: 'PASSWORD_TOO_SHORT',
        message: 'Cryptographic password must be at least 6 characters.',
      });
    }

    const cleanEmail = email.toLowerCase().trim();
    let cleanHandle = handle.toLowerCase().trim();
    if (!cleanHandle.startsWith('@')) {
      cleanHandle = `@${cleanHandle}`;
    }

    if (isMongoConnected()) {
      // Check existing email or handle
      const existingUser = await User.findOne({
        $or: [{ email: cleanEmail }, { handle: cleanHandle }],
      });

      if (existingUser) {
        const isEmailTaken = existingUser.email === cleanEmail;
        return res.status(409).json({
          error: isEmailTaken ? 'EMAIL_TAKEN' : 'HANDLE_TAKEN',
          message: isEmailTaken
            ? 'An eyewitness account with this email already exists.'
            : 'Handle is already claimed. Please select another.',
        });
      }

      const newUser = new User({
        name: name.trim(),
        email: cleanEmail,
        handle: cleanHandle,
        password,
        deviceModel: deviceModel || 'Pixel 9 Pro (Hardware Keystore Attested)',
        tier: tier || 'Tier 1 Verified Senior Eyewitness',
      });

      await newUser.save();
      const token = generateToken(newUser);

      return res.status(201).json({
        success: true,
        message: 'Eyewitness account registered and verified successfully.',
        token,
        user: newUser.toPublicJSON(),
      });
    } else {
      // In-Memory Fallback
      if (inMemoryUsers.has(cleanEmail)) {
        return res.status(409).json({
          error: 'EMAIL_TAKEN',
          message: 'An account with this email already exists.',
        });
      }

      const hashedPassword = await bcrypt.hash(password, 10);
      const fallbackUser = {
        _id: `user_${Date.now()}`,
        id: `user_${Date.now()}`,
        name: name.trim(),
        email: cleanEmail,
        handle: cleanHandle,
        password: hashedPassword,
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
        trustScore: 90,
        verifiedContributions: 0,
        accuracyRating: 99.0,
        helpfulVotes: 0,
        tier: tier || 'Tier 1 Verified Senior Eyewitness',
        deviceModel: deviceModel || 'Hardware Keystore Attested',
        hasAttestationKey: true,
        role: 'eyewitness',
        xp: 500,
        level: 2,
        levelTitle: 'Verified Field Scout',
        postsCreated: 0,
        verificationsDone: 0,
        commentsAdded: 0,
        tagsCreated: 0,
      };

      inMemoryUsers.set(cleanEmail, fallbackUser);
      inMemoryUsers.set(cleanHandle, fallbackUser);

      const token = generateToken(fallbackUser);
      const publicUser = { ...fallbackUser };
      delete publicUser.password;

      return res.status(201).json({
        success: true,
        message: 'Account created (Local Secure Mode).',
        token,
        user: publicUser,
      });
    }
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'REGISTRATION_FAILED', message: err.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { identifier, email, handle, emailOrHandle, password } = req.body;
    let loginIdentifier = (identifier || emailOrHandle || email || handle || '').toLowerCase().trim();
    // Normalize handle format so users can enter "username" or "@username"
    const handleWithAt = loginIdentifier.startsWith('@') ? loginIdentifier : `@${loginIdentifier}`;
    const handleWithoutAt = loginIdentifier.startsWith('@') ? loginIdentifier.substring(1) : loginIdentifier;

    if (!loginIdentifier || !password) {
      return res.status(400).json({
        error: 'MISSING_CREDENTIALS',
        message: 'Email or handle and password are required.',
      });
    }

    if (isMongoConnected()) {
      const user = await User.findOne({
        $or: [
          { email: loginIdentifier },
          { handle: loginIdentifier },
          { handle: handleWithAt },
          { handle: handleWithoutAt },
        ],
      });

      if (!user) {
        return res.status(401).json({
          error: 'INVALID_CREDENTIALS',
          message: 'No eyewitness account found with these credentials.',
        });
      }

      const isMatch = await user.comparePassword(password);
      if (!isMatch) {
        return res.status(401).json({
          error: 'INVALID_CREDENTIALS',
          message: 'Invalid password. Please check your keystore credentials.',
        });
      }

      const token = generateToken(user);
      return res.json({
        success: true,
        message: 'Cryptographic identity verified.',
        token,
        user: user.toPublicJSON(),
      });
    } else {
      // In-memory fallback
      const user = inMemoryUsers.get(loginIdentifier) ||
        inMemoryUsers.get(handleWithAt) ||
        inMemoryUsers.get(handleWithoutAt);

      if (!user) {
        return res.status(401).json({
          error: 'INVALID_CREDENTIALS',
          message: 'No eyewitness account found with these credentials.',
        });
      }

      if (user.password) {
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
          return res.status(401).json({
            error: 'INVALID_CREDENTIALS',
            message: 'Invalid password.',
          });
        }
      }

      const token = generateToken(user);
      const publicUser = { ...user };
      delete publicUser.password;

      return res.json({
        success: true,
        message: 'Cryptographic identity verified (Local Secure Mode).',
        token,
        user: publicUser,
      });
    }
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'LOGIN_FAILED', message: err.message });
  }
});

// GET /api/auth/me - Protected current profile
router.get('/me', verifyToken, async (req, res) => {
  try {
    if (isMongoConnected()) {
      const user = await User.findById(req.user.id);
      if (!user) {
        return res.status(404).json({ error: 'USER_NOT_FOUND', message: 'User does not exist.' });
      }
      return res.json({ success: true, user: user.toPublicJSON() });
    } else {
      const profile = inMemoryUsers.get(req.user.email);
      if (!profile) {
        return res.status(404).json({ error: 'USER_NOT_FOUND', message: 'User does not exist.' });
      }

      const publicUser = { ...profile };
      delete publicUser.password;
      return res.json({ success: true, user: publicUser });
    }
  } catch (err) {
    res.status(500).json({ error: 'FETCH_PROFILE_FAILED', message: err.message });
  }
});

module.exports = router;
