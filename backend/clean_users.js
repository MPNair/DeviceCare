const { sequelize, User } = require('./src/models');

async function cleanUsers() {
    try {
        console.log('Deleting users with null email...');
        const deletedCount = await User.destroy({
            where: {
                email: null
            }
        });
        console.log(`Deleted ${deletedCount} invalid users.`);
        process.exit(0);
    } catch (error) {
        console.error('Error cleaning users:', error);
        process.exit(1);
    }
}

cleanUsers();
