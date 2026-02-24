#!/usr/bin/env node

const { User } = require('./src/models');
const sequelize = require('./src/config/database');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function question(prompt) {
    return new Promise(resolve => rl.question(prompt, resolve));
}

async function showMenu() {
    console.clear();
    console.log('\n╔════════════════════════════════════════╗');
    console.log('║   DeviceCare Database Management Tool   ║');
    console.log('╚════════════════════════════════════════╝\n');
    console.log('1. View all users');
    console.log('2. Search user by email');
    console.log('3. View user statistics');
    console.log('4. Export user data to JSON');
    console.log('5. Check password hash validity');
    console.log('6. Exit\n');

    const choice = await question('Select option (1-6): ');
    return choice;
}

async function viewAllUsers() {
    try {
        const users = await User.findAll();
        
        console.log('\n\n═════════════════════════════════════════════════════════════\n');
        console.log(`Total Users: ${users.length}\n`);
        
        users.forEach((user, index) => {
            console.log(`\n${index + 1}. ${user.email}`);
            console.log(`   ID: ${user.id}`);
            console.log(`   Name: ${user.displayName || 'N/A'}`);
            console.log(`   Role: ${user.role}`);
            console.log(`   Password: ${user.password ? '✓ Set' : '✗ Not Set'}`);
            console.log(`   Firebase: ${user.firebaseId || 'None'}`);
            console.log(`   Created: ${user.createdAt.toLocaleString()}`);
            console.log(`   Updated: ${user.updatedAt.toLocaleString()}`);
        });
        
        console.log('\n═════════════════════════════════════════════════════════════\n');
    } catch (error) {
        console.error('Error:', error.message);
    }
}

async function searchUser() {
    const email = await question('\nEnter email to search: ');
    
    try {
        const user = await User.findOne({ where: { email } });
        
        if (!user) {
            console.log(`\n✗ User not found: ${email}\n`);
            return;
        }
        
        console.log('\n\n═══════════════════════════════════════════════════════════════\n');
        console.log(`✓ User Found: ${user.email}\n`);
        console.log(`ID: ${user.id}`);
        console.log(`Display Name: ${user.displayName}`);
        console.log(`Email: ${user.email}`);
        console.log(`Role: ${user.role}`);
        console.log(`Firebase ID: ${user.firebaseId || 'None'}`);
        console.log(`Password Hash: ${user.password ? user.password.substring(0, 50) + '...' : 'NULL'}`);
        console.log(`Password Hash Length: ${user.password ? user.password.length : 0} chars`);
        console.log(`Hash Valid: ${user.password && (user.password.startsWith('$2a$') || user.password.startsWith('$2b$')) && user.password.length === 60 ? '✓ Yes' : '✗ No'}`);
        console.log(`Created: ${user.createdAt.toLocaleString()}`);
        console.log(`Updated: ${user.updatedAt.toLocaleString()}`);
        console.log('\n═══════════════════════════════════════════════════════════════\n');
    } catch (error) {
        console.error('Error:', error.message);
    }
}

async function showStatistics() {
    try {
        const users = await User.findAll();
        
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
        
        console.log('\n\n═════════════════════════════════════════════════════════════\n');
        console.log('Database Statistics:\n');
        console.log(`Total Users: ${stats.totalUsers}`);
        console.log(`With Password: ${stats.withPassword}`);
        console.log(`Without Password: ${stats.withoutPassword}`);
        console.log(`With Firebase ID: ${stats.withFirebase}`);
        console.log(`\nRole Distribution:`);
        console.log(`  - Admins: ${stats.admins}`);
        console.log(`  - Regular Users: ${stats.regularUsers}`);
        console.log(`\nPassword Hash Status:`);
        console.log(`  - Valid Hashes: ${stats.validHashes} ✓`);
        console.log(`  - Corrupted Hashes: ${stats.corruptedHashes} ${stats.corruptedHashes > 0 ? '✗ (Run fix_passwords.js)' : '✓'}`);
        console.log('\n═════════════════════════════════════════════════════════════\n');
    } catch (error) {
        console.error('Error:', error.message);
    }
}

async function exportData() {
    try {
        const users = await User.findAll();
        const data = users.map(u => ({
            id: u.id,
            email: u.email,
            displayName: u.displayName,
            role: u.role,
            hasPassword: !!u.password,
            passwordHashLength: u.password ? u.password.length : null,
            hasFirebaseId: !!u.firebaseId,
            createdAt: u.createdAt.toISOString(),
            updatedAt: u.updatedAt.toISOString()
        }));
        
        const fs = require('fs');
        const filename = `user_data_${new Date().toISOString().slice(0,10)}.json`;
        fs.writeFileSync(filename, JSON.stringify(data, null, 2));
        
        console.log(`\n✓ Data exported to: ${filename}\n`);
    } catch (error) {
        console.error('Error:', error.message);
    }
}

async function checkHashValidity() {
    try {
        const users = await User.findAll();
        
        console.log('\n\n═════════════════════════════════════════════════════════════\n');
        console.log('Password Hash Validity Check:\n');
        
        let hasIssues = false;
        users.forEach((user, index) => {
            const hashValid = user.password && 
                             (user.password.startsWith('$2a$') || user.password.startsWith('$2b$')) && 
                             user.password.length === 60;
            
            const status = hashValid ? '✓' : '✗';
            console.log(`${index + 1}. ${user.email}: ${status}`);
            
            if (!hashValid && user.password) {
                console.log(`   └─ Hash Length: ${user.password.length} (expected 60)`);
                console.log(`   └─ Hash Start: ${user.password.substring(0, 15)}...`);
                hasIssues = true;
            }
        });
        
        if (hasIssues) {
            console.log('\n⚠ Issues found! Run: node fix_passwords.js');
        } else {
            console.log('\n✓ All password hashes are valid!');
        }
        
        console.log('\n═════════════════════════════════════════════════════════════\n');
    } catch (error) {
        console.error('Error:', error.message);
    }
}

async function main() {
    try {
        await sequelize.authenticate();
        
        let running = true;
        while (running) {
            const choice = await showMenu();
            
            switch(choice) {
                case '1':
                    await viewAllUsers();
                    break;
                case '2':
                    await searchUser();
                    break;
                case '3':
                    await showStatistics();
                    break;
                case '4':
                    await exportData();
                    break;
                case '5':
                    await checkHashValidity();
                    break;
                case '6':
                    running = false;
                    console.log('Goodbye!\n');
                    break;
                default:
                    console.log('Invalid option. Please try again.');
            }
            
            if (running) {
                await question('Press Enter to continue...');
            }
        }
        
        rl.close();
        process.exit(0);
    } catch (error) {
        console.error('Fatal Error:', error.message);
        rl.close();
        process.exit(1);
    }
}

main();
