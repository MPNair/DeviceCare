const express = require('express');
const router = express.Router();
const gadgetController = require('../controllers/gadgetController');
const { authenticate } = require('../middleware/authMiddleware');
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });

const exportController = require('../controllers/exportController');

router.get('/export', authenticate, exportController.exportToExcel);
router.post('/import', authenticate, upload.single('file'), gadgetController.importCSV);
router.post('/', authenticate, gadgetController.createGadget);
router.get('/', authenticate, gadgetController.getAllGadgets);
router.get('/:id', authenticate, gadgetController.getGadgetById);
router.put('/:id', authenticate, gadgetController.updateGadget);
router.delete('/:id', authenticate, gadgetController.deleteGadget);

module.exports = router;
