const { User, Gadget } = require('./src/models');

async function addSampleGadgets() {
    try {
        const users = await User.findAll();
        for (const user of users) {
            console.log(`Adding gadgets for user: ${user.email}`);

            await Gadget.create({
                name: `Sample Phone - ${user.displayName || user.email}`,
                category: 'Smartphone',
                brand: 'SampleBrand',
                model: 'X10',
                serialNumber: `SN-${user.id.substring(0, 4)}-1`,
                purchaseDate: '2023-01-01',
                purchasePrice: 999.99,
                userId: user.id
            });

            await Gadget.create({
                name: `Sample Laptop - ${user.displayName || user.email}`,
                category: 'Laptop',
                brand: 'SampleTech',
                model: 'Pro 15',
                serialNumber: `SN-${user.id.substring(0, 4)}-2`,
                purchaseDate: '2023-05-10',
                purchasePrice: 1499.00,
                userId: user.id
            });

            console.log(`Successfully added 2 gadgets for ${user.email}`);
        }
        process.exit();
    } catch (error) {
        console.error('Error adding sample gadgets:', error);
        if (error.errors) {
            error.errors.forEach(e => console.error(`Field: ${e.path}, Message: ${e.message}`));
        }
        process.exit(1);
    }
}

addSampleGadgets();
