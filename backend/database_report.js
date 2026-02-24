const { User } = require('./src/models');
const sequelize = require('./src/config/database');
const fs = require('fs');

async function generateReport() {
    try {
        await sequelize.authenticate();
        console.log('\n╔════════════════════════════════════════╗');
        console.log('║  Database Status Report                 ║');
        console.log('╚════════════════════════════════════════╝\n');

        const users = await User.findAll();
        
        // Statistics
        const stats = {
            totalUsers: users.length,
            withPassword: users.filter(u => u.password).length,
            withoutPassword: users.filter(u => !u.password).length,
            withFirebase: users.filter(u => u.firebaseId).length,
            admins: users.filter(u => u.role === 'admin').length,
            regularUsers: users.filter(u => u.role === 'user').length,
            validHashes: users.filter(u => u.password && u.password.length === 60).length,
            corruptedHashes: users.filter(u => u.password && u.password.length !== 60).length
        };

        console.log('📊 DATABASE STATISTICS\n');
        console.log(`Total Users: ${stats.totalUsers}`);
        console.log(`With Password: ${stats.withPassword}`);
        console.log(`Without Password: ${stats.withoutPassword}`);
        console.log(`With Firebase ID: ${stats.withFirebase}`);
        console.log(`Admins: ${stats.admins}`);
        console.log(`Regular Users: ${stats.regularUsers}`);
        console.log(`\n🔐 PASSWORD HASH STATUS\n`);
        console.log(`Valid Hashes (60 chars): ${stats.validHashes} ✓`);
        console.log(`Corrupted Hashes: ${stats.corruptedHashes} ${stats.corruptedHashes > 0 ? '✗' : '✓'}`);

        console.log('\n\n📋 DETAILED USER DATA\n');
        console.log('═'.repeat(70));

        users.forEach((user, index) => {
            const hashValid = user.password && 
                             (user.password.startsWith('$2a$') || user.password.startsWith('$2b$')) && 
                             user.password.length === 60;
            
            console.log(`\n${index + 1}. ${user.email}`);
            console.log(`   ID: ${user.id}`);
            console.log(`   Name: ${user.displayName || 'N/A'}`);
            console.log(`   Role: ${user.role}`);
            console.log(`   Firebase: ${user.firebaseId || 'None'}`);
            console.log(`   Password: ${user.password ? '✓ Set' : '✗ Not Set'}`);
            if (user.password) {
                console.log(`   Hash Length: ${user.password.length} chars (${hashValid ? '✓ Valid' : '✗ Corrupted'})`);
                console.log(`   Hash Preview: ${user.password.substring(0, 40)}...`);
            }
            console.log(`   Created: ${user.createdAt.toLocaleString()}`);
            console.log(`   Updated: ${user.updatedAt.toLocaleString()}`);
        });

        console.log('\n' + '═'.repeat(70));
        console.log('\n✓ Report generated successfully\n');

        // Export to JSON file
        const report = {
            generatedAt: new Date().toISOString(),
            statistics: stats,
            users: users.map(u => ({
                email: u.email,
                id: u.id,
                displayName: u.displayName,
                role: u.role,
                firebaseId: u.firebaseId,
                hasPassword: !!u.password,
                passwordHashLength: u.password ? u.password.length : null,
                passwordHashValid: u.password ? 
                    (u.password.startsWith('$2a$') || u.password.startsWith('$2b$')) && u.password.length === 60
                    : false,
                createdAt: u.createdAt.toISOString(),
                updatedAt: u.updatedAt.toISOString()
            }))
        };

        const reportFile = 'database_report.json';
        fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
        console.log(`📄 Report also saved to: ${reportFile}\n`);

        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

generateReport();
