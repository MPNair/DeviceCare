const sequelize = require('./src/config/database');

async function verify() {
    try {
        const [results] = await sequelize.query("PRAGMA table_info(Gadgets)");
        const columns = results.map(r => r.name);
        console.log('Gadgets Columns:', columns);

        if (columns.includes('documents')) {
            console.log('Verification SUCCESS: documents column found.');
        } else {
            console.log('Verification FAILED: documents column NOT found.');
        }

        const [folderResults] = await sequelize.query("PRAGMA table_info(Folders)");
        console.log('Folders Columns:', folderResults.map(r => r.name));

        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

verify();
