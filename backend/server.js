const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const walletRoutes = require('./routes/wallet');
const runsRoutes = require('./routes/runs');
const territoriesRoutes = require('./routes/territories');

const app = express();

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/wallet', walletRoutes);
app.use('/api/runs', runsRoutes);
app.use('/api/territories', territoriesRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'FitBox App Backend' });
});

const PORT = process.env.PORT || 4000;

mongoose.connect(process.env.MONGODB_URI, {
  // Add mongoose options if necessary
}).then(() => {
  console.log('Connected to MongoDB Atlas');
  app.listen(PORT, () => {
    console.log(`FitBox App Backend running on port ${PORT}`);
  });
}).catch((err) => {
  console.error('MongoDB connection error:', err);
});
