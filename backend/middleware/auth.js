const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'groundtruth_super_secret_cryptographic_key_2026';

/**
 * Authentication Middleware
 * Validates the JWT Bearer token in the Authorization header.
 */
function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({
      error: 'AUTH_TOKEN_MISSING',
      message: 'Authorization token required. Access restricted to verified eyewitnesses.',
    });
  }

  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({
      error: 'INVALID_TOKEN',
      message: 'Session token expired or signature invalid. Please log in again.',
    });
  }
}

/**
 * Optional Authentication Middleware
 * Attaches user if valid token is provided, but allows unauthenticated requests to continue.
 */
function optionalAuth(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return next();

  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
  } catch (_) {
    // Ignore invalid token in optional auth
  }
  next();
}

module.exports = {
  verifyToken,
  optionalAuth,
  JWT_SECRET,
};
