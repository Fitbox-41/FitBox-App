const express = require('express');
const auth = require('../middleware/auth');
const Run = require('../models/Run');

const router = express.Router();

// Get user's runs
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const runs = await Run.find({ userId }).sort({ startedAt: -1 });
    res.json({ success: true, runs });
  } catch (error) {
    console.error('Runs fetch error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Save a new run
router.post('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const runData = req.body;
    
    const run = new Run({
      userId,
      ...runData
    });
    
    await run.save();
    res.status(201).json({ success: true, run });
  } catch (error) {
    console.error('Run save error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
