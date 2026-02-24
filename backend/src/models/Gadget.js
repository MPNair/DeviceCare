const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Gadget = sequelize.define('Gadget', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false
    },
    category: {
        type: DataTypes.STRING, // smartphone, laptop, camera, smartwatch, console, etc.
        allowNull: false
    },
    brand: {
        type: DataTypes.STRING
    },
    model: {
        type: DataTypes.STRING
    },
    serialNumber: {
        type: DataTypes.STRING
    },
    purchaseDate: {
        type: DataTypes.DATEONLY,
        allowNull: false
    },
    purchasePrice: {
        type: DataTypes.FLOAT,
        allowNull: false
    },
    warrantyExpiryDate: {
        type: DataTypes.DATEONLY
    },
    conditionScore: {
        type: DataTypes.INTEGER, // 1-10
        defaultValue: 10
    },
    status: {
        type: DataTypes.ENUM('active', 'repair', 'sold', 'discarded'),
        defaultValue: 'active'
    },
    imageUrls: {
        type: DataTypes.JSON, // Array of strings
        defaultValue: []
    },
    currentEstimatedValue: {
        type: DataTypes.FLOAT
    },
    depreciationAdjustedValue: {
        type: DataTypes.FLOAT
    },
    folderId: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'Folders',
            key: 'id'
        }
    },
    storageCapacity: {
        type: DataTypes.STRING
    },
    color: {
        type: DataTypes.STRING
    },
    purchaseStore: {
        type: DataTypes.STRING
    },
    technicalSpecs: {
        type: DataTypes.JSON,
        defaultValue: {}
    },
    description: {
        type: DataTypes.TEXT
    },
    documents: {
        type: DataTypes.JSON, // Array of {name: string, url: string, folderId?: string}
        defaultValue: []
    },
    warrantyPeriod: {
        type: DataTypes.INTEGER // in months
    },
    tags: {
        type: DataTypes.JSON, // Array of strings
        defaultValue: []
    },
    customFields: {
        type: DataTypes.JSON, // Key-value object
        defaultValue: {}
    },
    ownershipStatus: {
        type: DataTypes.STRING // Owned, Leased, Rent, etc.
    },
    room: {
        type: DataTypes.STRING
    },
    userId: {
        type: DataTypes.STRING,
        allowNull: true,
        references: {
            model: 'Users',
            key: 'id'
        }
    }
});

module.exports = Gadget;
