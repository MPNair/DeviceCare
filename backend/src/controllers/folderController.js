const { Folder, Gadget } = require('../models');

exports.createFolder = async (req, res) => {
    try {
        const { name, description, folderType, parentId } = req.body;
        const userId = req.user.id;

        const folder = await Folder.create({
            name,
            description,
            folderType,
            parentId,
            userId
        });

        res.status(201).json(folder);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
};

exports.getAllFolders = async (req, res) => {
    try {
        const userId = req.user.id;
        const folders = await Folder.findAll({
            where: { userId },
            include: [
                { model: Folder, as: 'subFolders' },
                { model: Gadget, as: 'gadgets' }
            ]
        });
        res.json(folders);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

exports.getFolderById = async (req, res) => {
    try {
        const folder = await Folder.findOne({
            where: { id: req.params.id, userId: req.user.id },
            include: [
                { model: Folder, as: 'subFolders' },
                { model: Gadget, as: 'gadgets' }
            ]
        });
        if (!folder) return res.status(404).json({ error: 'Folder not found' });
        res.json(folder);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

exports.updateFolder = async (req, res) => {
    try {
        const folder = await Folder.findOne({
            where: { id: req.params.id, userId: req.user.id }
        });
        if (!folder) return res.status(404).json({ error: 'Folder not found' });

        await folder.update(req.body);
        res.json(folder);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
};

exports.deleteFolder = async (req, res) => {
    try {
        const folder = await Folder.findOne({
            where: { id: req.params.id, userId: req.user.id }
        });
        if (!folder) return res.status(404).json({ error: 'Folder not found' });

        await folder.destroy();
        res.status(204).send();
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};
