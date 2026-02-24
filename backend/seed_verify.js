require('dotenv').config();
const { sequelize, Gadget, User } = require('./src/models');

async function verifyAndSeed() {
    try {
        await sequelize.authenticate();
        console.log('Connection has been established successfully.');

        // 1. Ensure User Exists
        const [user, created] = await User.findOrCreate({
            where: { id: 'default-user-id' },
            defaults: {
                firebaseId: 'mock-firebase-id',
                email: 'guest@devicecare.io',
                password: '$2a$10$X.v.d.l.p.h.u.r.t.w.o.r.d.', // Mock bcrypt hash
                displayName: 'Guest User'
            }
        });
        console.log(`User ${user.id} ${created ? 'created' : 'already exists'}.`);

        // 2. Add Sample Gadgets
        const sampleGadgets = [
            {
                name: 'iPhone 15 Pro',
                category: 'Smartphone',
                brand: 'Apple',
                model: 'Pro Max',
                purchasePrice: 1199.00,
                purchaseDate: new Date(),
                warrantyExpiryDate: new Date(new Date().setFullYear(new Date().getFullYear() + 1)),
                conditionScore: 10,
                status: 'active',
                userId: 'default-user-id',
                storageCapacity: '256GB',
                color: 'Natural Titanium',
                serialNumber: `SN-${Date.now()}-1`
            },
            {
                name: 'Dell XPS 15',
                category: 'Laptop',
                brand: 'Dell',
                model: '9530',
                purchasePrice: 2400.00,
                purchaseDate: new Date('2023-01-01'),
                warrantyExpiryDate: new Date('2025-01-01'),
                conditionScore: 8,
                status: 'active',
                userId: 'default-user-id',
                storageCapacity: '1TB',
                color: 'Platinum Silver',
                serialNumber: `SN-${Date.now()}-2`
            }
        ];

        for (const data of sampleGadgets) {
            try {
                const gadget = await Gadget.create(data);
                console.log(`Created gadget: ${gadget.name} (ID: ${gadget.id})`);
            } catch (error) {
                console.error(`Failed to create ${data.name}:`, error.message);
            }
        }

        // 3. Verify Database Content
        const allGadgets = await Gadget.findAll({ where: { userId: 'default-user-id' } });
        console.log('\n--- Database Verification ---');
        console.log(`Total Gadgets: ${allGadgets.length}`);
        allGadgets.forEach(g => {
            console.log(`- ${g.name} (${g.category}) - Value: $${g.currentEstimatedValue || 'N/A'}`);
        });

    } catch (error) {
        console.error('Unable to connect to the database:', error);
    } finally {
        await sequelize.close();
    }
}

verifyAndSeed();
