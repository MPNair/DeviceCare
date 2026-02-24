const { Gadget } = require('../models');
const fs = require('fs');
const csv = require('csv-parser');

exports.importGadgetsFromCSV = (filePath, userId) => {
    return new Promise((resolve, reject) => {
        const gadgets = [];
        fs.createReadStream(filePath)
            .pipe(csv())
            .on('data', (row) => {
                gadgets.push({
                    ...row,
                    userId,
                    purchasePrice: parseFloat(row.purchasePrice || 0),
                    purchaseDate: row.purchaseDate || new Date().toISOString().split('T')[0]
                });
            })
            .on('end', async () => {
                try {
                    const created = await Gadget.bulkCreate(gadgets);
                    resolve(created);
                } catch (err) {
                    reject(err);
                }
            })
            .on('error', (err) => reject(err));
    });
};
