const bcrypt = require('bcryptjs');
const { sequelize, User, Folder, Gadget } = require('./src/models');
const { Op } = require('sequelize');

const todayStr = new Date().toISOString().split('T')[0];

const gadgetsInput = [
  {
    name: 'Dell XPS 15',
    category: 'Laptop',
    folderName: 'Work Devices',
    room: 'Office Desk',
    brand: 'Dell',
    model: 'XPS 15 9520',
    storageCapacity: '1TB SSD',
    color: 'Platinum Silver',
    serialNumber: '7JH92X3PQL4D',
    purchasePrice: 210000,
    purchaseDate: '2025-11-05',
    warrantyMonths: 24,
    purchaseStore: 'Dell Official Store',
    ownershipStatus: 'First Hand',
    conditionScore: 9,
    tags: ['work', 'primary', 'high-performance'],
    technicalSpecs: {
      processor: 'Intel Core i7 12th Gen',
      ram: '16GB',
      display: '15.6 inch OLED',
      gpu: 'NVIDIA RTX 3050 Ti',
    },
    description:
      'Primary workstation laptop used for development and productivity.',
  },
  {
    name: 'iPad Air',
    category: 'Tablet',
    folderName: 'Study Devices',
    room: 'Living Room',
    brand: 'Apple',
    model: 'iPad Air (5th Gen, M1)',
    storageCapacity: '256GB',
    color: 'Blue',
    serialNumber: 'DMPZQ2A9K6Y7',
    purchasePrice: 77900,
    purchaseDate: '2025-10-18',
    warrantyMonths: 12,
    purchaseStore: 'Flipkart',
    ownershipStatus: 'First Hand',
    conditionScore: 9,
    tags: ['study', 'media', 'portable'],
    technicalSpecs: {
      chipset: 'Apple M1',
      display: '10.9 inch Liquid Retina',
      connectivity: 'Wi-Fi',
      accessories: 'Apple Pencil support',
    },
    description: 'Tablet for reading, note-taking, and online coursework.',
  },
  {
    name: 'Apple Watch Series 8',
    category: 'Smartwatch',
    folderName: 'Wearables',
    room: 'Bedroom',
    brand: 'Apple',
    model: 'Watch Series 8 GPS 45mm',
    storageCapacity: '32GB',
    color: 'Midnight',
    serialNumber: 'W8QJ92PLM4X7',
    purchasePrice: 45900,
    purchaseDate: '2025-09-22',
    warrantyMonths: 12,
    purchaseStore: 'Croma',
    ownershipStatus: 'First Hand',
    conditionScore: 8,
    tags: ['wearable', 'fitness', 'health'],
    technicalSpecs: {
      display: 'Always-On Retina',
      sensors: ['ECG', 'SpO2', 'Temperature'],
      batteryLife: 'Up to 18 hours',
    },
    description:
      'Daily wearable used for fitness tracking and health monitoring.',
  },
  {
    name: 'OnePlus 11 5G',
    category: 'Smartphone',
    folderName: 'Personal Devices',
    room: 'Bedroom',
    brand: 'OnePlus',
    model: 'OnePlus 11 5G',
    storageCapacity: '256GB',
    color: 'Eternal Green',
    serialNumber: 'OP11GQ92XPL7',
    purchasePrice: 61999,
    purchaseDate: '2025-02-27',
    warrantyMonths: 12,
    purchaseStore: 'OnePlus Store India',
    ownershipStatus: 'First Hand',
    conditionScore: 9,
    tags: ['personal', 'smartphone', 'daily-use'],
    technicalSpecs: {
      chipset: 'Snapdragon 8 Gen 2',
      ram: '16GB',
      battery: '5000mAh',
      display: '6.7 inch AMOLED',
    },
    description:
      'Primary personal smartphone used for communication, media, and apps.',
  },
  {
    name: 'ASUS ROG Zephyrus G14',
    category: 'Laptop',
    folderName: 'Gaming Devices',
    room: 'Study Room',
    brand: 'ASUS',
    model: 'ROG Zephyrus G14 (2023)',
    storageCapacity: '1TB SSD',
    color: 'Moonlight White',
    serialNumber: 'ASG14X9PL82Q',
    purchasePrice: 185000,
    purchaseDate: '2025-02-25',
    warrantyMonths: 12,
    purchaseStore: 'ASUS Exclusive Store',
    ownershipStatus: 'First Hand',
    conditionScore: 9,
    tags: ['gaming', 'laptop', 'high-performance'],
    technicalSpecs: {
      processor: 'AMD Ryzen 9',
      ram: '32GB',
      gpu: 'NVIDIA RTX 4060',
      display: '14 inch QHD 165Hz',
    },
    description:
      'High-performance gaming and development laptop for study room setup.',
  },
  {
    name: 'Samsung Galaxy Tab S8',
    category: 'Tablet',
    folderName: 'Study Devices',
    room: 'Living Room',
    brand: 'Samsung',
    model: 'Galaxy Tab S8',
    storageCapacity: '256GB',
    color: 'Graphite',
    serialNumber: 'SGS8TQPL92X1',
    purchasePrice: 70999,
    purchaseDate: '2025-02-20',
    warrantyMonths: 12,
    purchaseStore: 'Samsung Smart Plaza',
    ownershipStatus: 'First Hand',
    conditionScore: 8,
    tags: ['study', 'tablet', 'notes'],
    technicalSpecs: {
      display: '11 inch LTPS TFT',
      chipset: 'Snapdragon 8 Gen 1',
      ram: '8GB',
      accessories: 'S Pen included',
    },
    description:
      'Tablet for classes, reading, and digital note-taking in daily study use.',
  },
];

function addMonths(dateString, months) {
  const date = new Date(dateString);
  date.setMonth(date.getMonth() + months);
  return date.toISOString().split('T')[0];
}

async function seedTest5() {
  try {
    await sequelize.authenticate();

    const defaultPassword = 'Test5@12345';
    const hash = await bcrypt.hash(defaultPassword, 10);

    const [defaultUser] = await User.findOrCreate({
      where: { email: 'test5@test.com' },
      defaults: {
        email: 'test5@test.com',
        password: hash,
        displayName: 'test5',
        role: 'user',
      },
    });

    const targetUsers = await User.findAll({
      where: {
        [Op.or]: [
          { email: { [Op.in]: ['test5', 'test5@test.com'] } },
          { displayName: 'test5' },
        ],
      },
    });

    const uniqueUsers = Array.from(
      new Map(targetUsers.concat(defaultUser).map((u) => [u.id, u])).values(),
    );

    for (const user of uniqueUsers) {
      if (!user.password) {
        await user.update({ password: hash });
      }

      for (const item of gadgetsInput) {
        const [folder] = await Folder.findOrCreate({
          where: {
            userId: user.id,
            name: item.folderName,
            parentId: null,
          },
          defaults: {
            userId: user.id,
            name: item.folderName,
            folderType: 'custom',
            description: `${item.folderName} collection for test5 account`,
          },
        });

        const payload = {
          userId: user.id,
          folderId: folder.id,
          name: item.name,
          category: item.category,
          room: item.room,
          brand: item.brand,
          model: item.model,
          storageCapacity: item.storageCapacity,
          color: item.color,
          serialNumber: item.serialNumber,
          purchasePrice: item.purchasePrice,
          purchaseDate: item.purchaseDate,
          warrantyPeriod: item.warrantyMonths,
          warrantyExpiryDate: addMonths(item.purchaseDate, item.warrantyMonths),
          purchaseStore: item.purchaseStore,
          ownershipStatus: item.ownershipStatus,
          conditionScore: item.conditionScore,
          status: 'active',
          tags: item.tags,
          technicalSpecs: item.technicalSpecs,
          description: item.description,
          documents: [
            {
              name: 'Purchase Invoice',
              url: `${item.name.toLowerCase().replace(/\s+/g, '_')}_invoice.pdf`,
            },
            {
              name: 'Warranty Card',
              url: `${item.name.toLowerCase().replace(/\s+/g, '_')}_warranty.pdf`,
            },
          ],
          customFields: {
            nextMaintenanceDate: todayStr,
            maintenanceIntervalDays: 180,
            assignedTo: 'test5',
            verificationNote:
              'Set to today for immediate notification verification in app',
          },
        };

        const existing = await Gadget.findOne({
          where: { userId: user.id, serialNumber: item.serialNumber },
        });

        if (existing) {
          await existing.update(payload);
        } else {
          await Gadget.create(payload);
        }
      }

      const count = await Gadget.count({ where: { userId: user.id } });
      console.log(
        `Seeded user ${user.email || user.id} (${user.id}) -> total gadgets: ${count}`,
      );
    }

    console.log('✅ test5 account seeded successfully.');
    console.log(`Primary email: test5@test.com`);
    console.log(`Password set for test5 identities: ${defaultPassword}`);
    console.log(`Maintenance reminder test date set to: ${todayStr}`);

    await sequelize.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Failed to seed test5 account:', error);
    try {
      await sequelize.close();
    } catch (_) {}
    process.exit(1);
  }
}

seedTest5();
