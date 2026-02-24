const express = require('express');
const router = express.Router();
const logController = require('../controllers/logController');
const { authenticate } = require('../middleware/authMiddleware');

router.post('/:gadgetId/logs', authenticate, logController.createLog);
router.get('/:gadgetId/logs', authenticate, logController.getLogsByGadget);
router.delete('/logs/:id', authenticate, logController.deleteLog);

module.exports = router;
