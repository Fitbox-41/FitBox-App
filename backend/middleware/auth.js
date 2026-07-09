const jwt = require('jsonwebtoken');

const auth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Authentication required' });
    }

    const token = authHeader.split(' ')[1];
    
    // Website uses JWT_SECRET, we must use the same
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Attach the user info from token to the request
    // Assumes token contains { id: '...userId...' } based on standard MERN practice
    req.user = decoded;
    
    next();
  } catch (error) {
    console.error('Auth error:', error.message);
    res.status(401).json({ success: false, message: 'Invalid or expired token' });
  }
};

module.exports = auth;
