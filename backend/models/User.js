const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  handle: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true },
  avatarUrl: {
    type: String,
    default: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
  },
  trustScore: { type: Number, default: 90, min: 0, max: 100 },
  verifiedContributions: { type: Number, default: 0 },
  accuracyRating: { type: Number, default: 99.0 },
  helpfulVotes: { type: Number, default: 0 },
  tier: { type: String, default: 'Tier 1 Verified Senior Eyewitness' },
  deviceModel: { type: String, default: 'Pixel 9 Pro (Hardware Keystore Attested)' },
  hasAttestationKey: { type: Boolean, default: true },
  role: { type: String, default: 'eyewitness', enum: ['eyewitness', 'journalist', 'admin'] },
  xp: { type: Number, default: 500 },
  level: { type: Number, default: 2 },
  levelTitle: { type: String, default: 'Verified Field Scout' },
  postsCreated: { type: Number, default: 0 },
  verificationsDone: { type: Number, default: 0 },
  commentsAdded: { type: Number, default: 0 },
  tagsCreated: { type: Number, default: 0 },
}, { timestamps: true });

// Pre-save hook to hash password if modified
UserSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (err) {
    next(err);
  }
});

// Method to verify password
UserSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Method to strip sensitive fields
UserSchema.methods.toPublicJSON = function () {
  const user = this.toObject();
  delete user.password;
  delete user.__v;
  return user;
};

module.exports = mongoose.model('User', UserSchema);
