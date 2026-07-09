const express = require('express');
const auth = require('../middleware/auth');
const Territory = require('../models/Territory');

const router = express.Router();

// Get territories for a given week
router.get('/:weekOf', auth, async (req, res) => {
  try {
    const { weekOf } = req.params;
    const territories = await Territory.find({ weekOf });
    res.json({ success: true, territories });
  } catch (error) {
    console.error('Territories fetch error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Claim a territory
router.post('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const territoryData = req.body;
    
    const territory = new Territory({
      userId,
      ...territoryData
    });
    
    await territory.save();
    res.status(201).json({ success: true, territory });
  } catch (error) {
    console.error('Territory save error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
