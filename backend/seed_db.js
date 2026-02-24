const { sequelize, User, Gadget } = require('./src/models');
const bcrypt = require('bcryptjs');

async function seed() {
    try {
        console.log('Resetting database...');
        await sequelize.sync({ force: true });
        console.log('Database reset successfully.');

        const hashedPassword = await bcrypt.hash('password123', 10);

        // Create Guest User
        const guest = await User.create({
            email: 'guest@devicecare.io',
            password: hashedPassword,
            displayName: 'Guest User',
            role: 'user'
        });
        console.log('Created Guest User.');

        // Create Test2 User
        const test2 = await User.create({
            email: 'test2@test.com',
            password: hashedPassword,
            displayName: 'test2',
            role: 'user'
        });
        console.log('Created test2 User.');

        // Add gadgets for Guest
        await Gadget.create({
            name: 'Guest Phone',
            category: 'Smartphone',
            brand: 'Apple',
            model: 'iPhone 15',
            serialNumber: 'GUEST-SN1',
            purchaseDate: '2024-01-01',
            purchasePrice: 999.99,
            userId: guest.id
        });
        await Gadget.create({
            name: 'Guest Laptop',
            category: 'Laptop',
            brand: 'Dell',
            model: 'XPS 15',
            serialNumber: 'GUEST-SN2',
            purchaseDate: '2023-06-15',
            purchasePrice: 1800.00,
            userId: guest.id
        });

        // Add gadgets for Test2
        await Gadget.create({
            name: 'Test2 Console',
            category: 'Console',
            brand: 'Sony',
            model: 'PS5',
            serialNumber: 'TEST2-SN1',
            purchaseDate: '2023-11-20',
            purchasePrice: 499.99,
            userId: test2.id
        });
        await Gadget.create({
            name: 'Test2 Camera',
            category: 'Camera',
            brand: 'Sony',
            model: 'A7 IV',
            serialNumber: 'TEST2-SN2',
            purchaseDate: '2024-02-10',
            purchasePrice: 2499.00,
            userId: test2.id
        });

        console.log('Successfully seeded database with users and gadgets.');
        process.exit(0);
    } catch (error) {
        console.error('Seeding failed:', error);
        process.exit(1);
    }
}

seed();
