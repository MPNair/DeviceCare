const { Gadget, Folder } = require('../models');
const ExcelJS = require('exceljs');

exports.exportToExcel = async (req, res) => {
    try {
        const userId = req.user.id;

        // Fetch all data
        const gadgets = await Gadget.findAll({ where: { userId } });
        const folders = await Folder.findAll({ where: { userId } });

        const workbook = new ExcelJS.Workbook();

        // 1. Gadgets Sheet
        const gadgetSheet = workbook.addWorksheet('Gadgets');
        gadgetSheet.columns = [
            { header: 'ID', key: 'id', width: 36 },
            { header: 'Name', key: 'name', width: 20 },
            { header: 'Category', key: 'category', width: 15 },
            { header: 'Brand', key: 'brand', width: 15 },
            { header: 'Model', key: 'model', width: 20 },
            { header: 'Serial Number', key: 'serialNumber', width: 20 },
            { header: 'Purchase Date', key: 'purchaseDate', width: 15 },
            { header: 'Purchase Price', key: 'purchasePrice', width: 15 },
            { header: 'Condition', key: 'conditionScore', width: 10 },
            { header: 'Status', key: 'status', width: 10 },
            { header: 'Room', key: 'room', width: 15 },
            { header: 'Ownership', key: 'ownershipStatus', width: 15 },
            { header: 'Description', key: 'description', width: 30 }
        ];

        gadgets.forEach(g => {
            gadgetSheet.addRow(g.toJSON());
        });

        // 2. Folders Sheet
        const folderSheet = workbook.addWorksheet('Folders');
        folderSheet.columns = [
            { header: 'ID', key: 'id', width: 36 },
            { header: 'Name', key: 'name', width: 20 },
            { header: 'Type', key: 'folderType', width: 15 },
            { header: 'Parent ID', key: 'parentId', width: 36 },
            { header: 'Description', key: 'description', width: 30 }
        ];

        folders.forEach(f => {
            folderSheet.addRow(f.toJSON());
        });

        // Styling headers
        [gadgetSheet, folderSheet].forEach(sheet => {
            sheet.getRow(1).font = { bold: true };
            sheet.getRow(1).fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FFE0E0E0' }
            };
        });

        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', 'attachment; filename=DeviceCare_Export.xlsx');

        await workbook.xlsx.write(res);
        res.end();

    } catch (error) {
        console.error('Export Error:', error);
        res.status(500).json({ error: 'Failed to generate export' });
    }
};
