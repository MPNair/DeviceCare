const express = require('express');
const router = express.Router();
const folderController = require('../controllers/folderController');
const { authenticate } = require('../middleware/authMiddleware');

router.post('/', authenticate, folderController.createFolder);
router.get('/', authenticate, folderController.getAllFolders);
router.get('/:id', authenticate, folderController.getFolderById);
router.put('/:id', authenticate, folderController.updateFolder);
router.delete('/:id', authenticate, folderController.deleteFolder);

module.exports = router;
