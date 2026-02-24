const { User, Gadget } = require('./src/models');

async function verifyUpdate() {
    try {
        const user = await User.findOne({ where: { email: 'guest@devicecare.io' } });
        if (!user) {
            console.error('Guest user not found');
            process.exit(1);
        }

        // Find a gadget for this user
        const gadget = await Gadget.findOne({ where: { userId: user.id } });
        if (!gadget) {
            console.error('No gadgets found for guest user, creating one...');
            const newGadget = await Gadget.create({
                name: 'Update Test Device',
                category: 'Phone',
                brand: 'TestBrand',
                model: 'T1',
                purchaseDate: '2024-01-01',
                purchasePrice: 500,
                userId: user.id
            });
            return performUpdate(newGadget, user.id);
        }

        return performUpdate(gadget, user.id);
    } catch (error) {
        console.error('Verification failed:', error);
        process.exit(1);
    }
}

async function performUpdate(gadget, userId) {
    try {
        console.log(`Initial gadget name: ${gadget.name}`);
        const newName = `Updated ${gadget.name} at ${new Date().toLocaleTimeString()}`;

        const [updatedRows] = await Gadget.update(
            { name: newName },
            { where: { id: gadget.id, userId: userId } }
        );

        if (updatedRows === 0) {
            console.error('Failed to update gadget: No rows affected.');
            process.exit(1);
        }

        const updatedGadget = await Gadget.findByPk(gadget.id);
        console.log(`Updated gadget name: ${updatedGadget.name}`);

        if (updatedGadget.name === newName) {
            console.log('Update verification SUCCESSFUL!');
            process.exit(0);
        } else {
            console.error('Update verification FAILED: Name mismatch.');
            process.exit(1);
        }
    } catch (error) {
        console.error('Update operation failed:', error);
        process.exit(1);
    }
}

verifyUpdate();
