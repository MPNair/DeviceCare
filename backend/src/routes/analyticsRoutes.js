const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/dashboard', authenticate, analyticsController.getUserAnalytics);

module.exports = router;
