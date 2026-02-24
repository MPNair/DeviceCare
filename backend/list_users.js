const { User } = require('./src/models');

async function listUsers() {
    try {
        const users = await User.findAll();
        console.log('Existing users:');
        users.forEach(u => console.log(`- ${u.email} (ID: ${u.id})`));
        process.exit();
    } catch (error) {
        console.error('Error listing users:', error);
        process.exit(1);
    }
}

listUsers();
