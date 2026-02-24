const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const MaintenanceLog = sequelize.define('MaintenanceLog', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true
    },
    serviceType: {
        type: DataTypes.STRING, // repair, maintenance, battery replacement, etc.
        allowNull: false
    },
    description: {
        type: DataTypes.TEXT
    },
    cost: {
        type: DataTypes.FLOAT,
        defaultValue: 0
    },
    serviceDate: {
        type: DataTypes.DATEONLY,
        allowNull: false
    },
    technicianDetails: {
        type: DataTypes.STRING
    },
    documentUrl: {
        type: DataTypes.STRING // URL to invoice/receipt
    }
});

module.exports = MaintenanceLog;
