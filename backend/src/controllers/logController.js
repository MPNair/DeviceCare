const { MaintenanceLog, Gadget } = require('../models');

exports.createLog = async (req, res) => {
    try {
        const log = await MaintenanceLog.create({
            ...req.body,
            gadgetId: req.params.gadgetId
        });
        res.status(201).json(log);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.getLogsByGadget = async (req, res) => {
    try {
        const logs = await MaintenanceLog.findAll({
            where: { gadgetId: req.params.gadgetId },
            order: [['serviceDate', 'DESC']]
        });
        res.json(logs);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.deleteLog = async (req, res) => {
    try {
        const deleted = await MaintenanceLog.destroy({
            where: { id: req.params.id }
        });
        if (deleted) return res.status(204).send();
        throw new Error('Log not found');
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
