const { Gadget, MaintenanceLog, Folder } = require('../models');
const { calculateCurrentValue } = require('../utils/depreciationEngine');
const csvImporter = require('../utils/csvImporter');
const path = require('path');

exports.createGadget = async (req, res) => {
    try {
        const gadgetData = {
            ...req.body,
            userId: req.user.id // Set from authenticated user
        };
        const gadget = await Gadget.create(gadgetData);
        res.status(201).json(gadget);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.importCSV = async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
        const results = await csvImporter.importGadgetsFromCSV(req.file.path, req.user.id);
        res.json({ message: `${results.length} gadgets imported successfully` });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.getAllGadgets = async (req, res) => {
    try {
        const gadgets = await Gadget.findAll({
            where: { userId: req.user.id },
            include: [{ model: MaintenanceLog, as: 'logs' }]
        });

        // Add current value estimation to each gadget
        const gadgetsWithEstimation = gadgets.map(g => {
            const gJson = g.toJSON();
            gJson.currentEstimatedValue = calculateCurrentValue(gJson, gJson.logs || []);
            return gJson;
        });

        res.json(gadgetsWithEstimation);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.getGadgetById = async (req, res) => {
    try {
        const gadget = await Gadget.findOne({
            where: { id: req.params.id, userId: req.user.id },
            include: [{ model: MaintenanceLog, as: 'logs' }]
        });

        if (!gadget) return res.status(404).json({ error: 'Gadget not found' });

        const gadgetJson = gadget.toJSON();
        gadgetJson.currentEstimatedValue = calculateCurrentValue(gadgetJson, gadgetJson.logs || []);

        res.json(gadgetJson);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.updateGadget = async (req, res) => {
    try {
        const { userId, ...updateData } = req.body; // Prevent updating userId
        const [updated] = await Gadget.update(updateData, {
            where: { id: req.params.id, userId: req.user.id }
        });
        if (updated) {
            const updatedGadget = await Gadget.findByPk(req.params.id);
            return res.json(updatedGadget);
        }
        res.status(404).json({ error: 'Gadget not found or unauthorized' });
    } catch (error) {
        console.error('Gadget update error:', error);
        if (error.errors) {
            error.errors.forEach(e => console.error(`Field: ${e.path}, Message: ${e.message}`));
        }
        res.status(400).json({ error: error.message });
    }
};

exports.deleteGadget = async (req, res) => {
    try {
        const deleted = await Gadget.destroy({
            where: { id: req.params.id, userId: req.user.id }
        });
        if (deleted) return res.status(204).send();
        throw new Error('Gadget not found');
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
