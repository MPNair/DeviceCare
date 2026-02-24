const { User } = require('./src/models');
const sequelize = require('./src/config/database');

async function viewUsers() {
    try {
        await sequelize.authenticate();
        console.log('\n=== DATABASE CONNECTION SUCCESSFUL ===\n');

        const users = await User.findAll();
        
        console.log(`Total Users: ${users.length}\n`);
        
        users.forEach((user, index) => {
            console.log(`\n--- User ${index + 1} ---`);
            console.log(`ID: ${user.id}`);
            console.log(`Email: ${user.email}`);
            console.log(`Display Name: ${user.displayName}`);
            console.log(`Firebase ID: ${user.firebaseId}`);
            console.log(`Password Hash: ${user.password ? user.password.substring(0, 50) + '...' : 'NULL'}`);
            console.log(`Role: ${user.role}`);
            console.log(`Created At: ${user.createdAt}`);
            console.log(`Updated At: ${user.updatedAt}`);
        });

        console.log('\n=== END OF USER DATA ===\n');
        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

viewUsers();
