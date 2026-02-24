const { sequelize, Gadget } = require('./src/models');

sequelize.sync().then(async () => {
    const gadgets = await Gadget.findAll();
    console.log(`\nTotal gadgets in database: ${gadgets.length}\n`);
    gadgets.forEach(g => {
        console.log(`- ${g.name} (User: ${g.userId}, Category: ${g.category})`);
    });
    process.exit();
});
