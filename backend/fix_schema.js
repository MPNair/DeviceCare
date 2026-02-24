const { sequelize } = require('./src/models');

async function fixSchema() {
    try {
        await sequelize.authenticate();
        console.log('Database connected.');

        // --- Fix Gadgets Table ---
        const [gadgetColumns] = await sequelize.query("PRAGMA table_info(Gadgets)");
        const gCols = gadgetColumns.map(r => r.name);

        const gadgetsToAdd = [
            { name: 'description', type: 'TEXT' },
            { name: 'warrantyPeriod', type: 'INTEGER' },
            { name: 'tags', type: "JSON DEFAULT '[]'" },
            { name: 'customFields', type: "JSON DEFAULT '{}'" },
            { name: 'ownershipStatus', type: 'STRING' },
            { name: 'room', type: 'STRING' },
            { name: 'imageUrls', type: "JSON DEFAULT '[]'" },
            { name: 'documents', type: "JSON DEFAULT '[]'" },
            { name: 'currentEstimatedValue', type: 'FLOAT' },
            { name: 'depreciationAdjustedValue', type: 'FLOAT' },
            { name: 'folderId', type: 'UUID' },
            { name: 'storageCapacity', type: 'STRING' },
            { name: 'color', type: 'STRING' },
            { name: 'purchaseStore', type: 'STRING' },
            { name: 'technicalSpecs', type: "JSON DEFAULT '{}'" }
        ];

        for (const col of gadgetsToAdd) {
            if (!gCols.includes(col.name)) {
                console.log(`Adding ${col.name} column to Gadgets...`);
                await sequelize.query(`ALTER TABLE Gadgets ADD COLUMN ${col.name} ${col.type}`);
            }
        }

        // --- Fix Folders Table ---
        const [folderColumns] = await sequelize.query("PRAGMA table_info(Folders)");
        const fCols = folderColumns.map(r => r.name);

        const foldersToAdd = [
            { name: 'description', type: 'TEXT' },
            { name: 'folderType', type: "STRING DEFAULT 'custom'" },
            { name: 'parentId', type: 'UUID' }
        ];

        for (const col of foldersToAdd) {
            if (!fCols.includes(col.name)) {
                console.log(`Adding ${col.name} column to Folders...`);
                await sequelize.query(`ALTER TABLE Folders ADD COLUMN ${col.name} ${col.type}`);
            }
        }

        // --- Fix MaintenanceLogs Table ---
        const [logColumns] = await sequelize.query("PRAGMA table_info(MaintenanceLogs)");
        const lCols = logColumns.map(r => r.name);

        const logsToAdd = [
            { name: 'description', type: 'TEXT' },
            { name: 'cost', type: 'FLOAT DEFAULT 0' },
            { name: 'technicianDetails', type: 'STRING' },
            { name: 'documentUrl', type: 'STRING' }
        ];

        for (const col of logsToAdd) {
            if (!lCols.includes(col.name)) {
                console.log(`Adding ${col.name} column to MaintenanceLogs...`);
                await sequelize.query(`ALTER TABLE MaintenanceLogs ADD COLUMN ${col.name} ${col.type}`);
            }
        }

        console.log('Schema fix completed successfully.');
        process.exit(0);
    } catch (error) {
        console.error('Failed to fix schema:', error);
        process.exit(1);
    }
}

fixSchema();
