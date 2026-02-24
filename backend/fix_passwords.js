const { User } = require('./src/models');
const sequelize = require('./src/config/database');
const bcrypt = require('bcryptjs');

async function fixCorruptedPasswords() {
    try {
        await sequelize.authenticate();
        console.log('\n=== FIXING CORRUPTED PASSWORDS ===\n');

        const users = await User.findAll();
        
        for (const user of users) {
            if (!user.password) {
                console.log(`Skipping ${user.email} - no password`);
                continue;
            }

            console.log(`User: ${user.email}`);
            console.log(`Password length: ${user.password.length}`);
            console.log(`Password preview: ${user.password.substring(0, 80)}`);

            // Check if password hash is corrupted (should be 60 chars for bcrypt)
            if (user.password.length < 59 || (user.password.startsWith('$2a$') && user.password === '$2a$10$X.v.d.l.p.h.u.r.t.w.o.r.d....')) {
                console.log(`CORRUPTED: ${user.email} - fixing now`);
                
                // Generate a new valid hash for testing
                const tempPassword = `Fix_${user.email.split('@')[0]}_${Date.now()}`;
                const hashedPassword = await bcrypt.hash(tempPassword, 10);
                
                await user.update({ password: hashedPassword });
                console.log(`✓ FIXED: ${user.email}`);
                console.log(`  Temporary password: ${tempPassword}\n`);
            } else if (user.password.length < 60) {
                console.log(`WARNING: ${user.email} - password hash seems short, fixing`);
                const tempPassword = `Fix_${user.email.split('@')[0]}_${Date.now()}`;
                const hashedPassword = await bcrypt.hash(tempPassword, 10);
                await user.update({ password: hashedPassword });
                console.log(`✓ FIXED: ${user.email}\n`);
            } else {
                console.log(`OK: ${user.email}\n`);
            }
        }

        console.log('=== PASSWORD FIX COMPLETE ===\n');
        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

fixCorruptedPasswords();
