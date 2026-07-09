const mongoose = require('mongoose');

// Serverless-friendly connection. On Vercel each invocation may reuse a warm
// container, so we avoid opening a new connection when one is already live
// (mirrors the website backend's readyState guard).
async function connectDB() {
  if (mongoose.connection.readyState >= 1) {
    return;
  }
  await mongoose.connect(process.env.MONGO_URI, {
    serverSelectionTimeoutMS: 5000,
  });
}

module.exports = connectDB;
