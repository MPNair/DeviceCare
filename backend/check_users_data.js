const { sequelize, User } = require('./src/models');

async function checkUsers() {
    try {
        const users = await User.findAll();
        console.log('All users in DB:');
        users.forEach(u => {
            console.log(`- ID: ${u.id}, Email: ${u.email}, DisplayName: ${u.displayName}`);
        });
        process.exit(0);
    } catch (error) {
        console.error('Error checking users:', error);
        process.exit(1);
    }
}

checkUsers();
