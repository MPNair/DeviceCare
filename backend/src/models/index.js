const sequelize = require('../config/database');
const User = require('./User');
const Gadget = require('./Gadget');
const Folder = require('./Folder');
const MaintenanceLog = require('./MaintenanceLog');

// One-to-Many: User -> Gadget
User.hasMany(Gadget, { foreignKey: 'userId', as: 'gadgets' });
Gadget.belongsTo(User, { foreignKey: 'userId' });

// One-to-Many: User -> Folder
User.hasMany(Folder, { foreignKey: 'userId', as: 'folders' });
Folder.belongsTo(User, { foreignKey: 'userId' });

// One-to-Many: Folder -> Folder (Hierarchy)
Folder.hasMany(Folder, { foreignKey: 'parentId', as: 'subFolders', onDelete: 'CASCADE' });
Folder.belongsTo(Folder, { foreignKey: 'parentId', as: 'parent' });

// One-to-Many: Folder -> Gadget
Folder.hasMany(Gadget, { foreignKey: 'folderId', as: 'gadgets', onDelete: 'SET NULL' });
Gadget.belongsTo(Folder, { foreignKey: 'folderId', as: 'folder' });

// One-to-Many: Gadget -> MaintenanceLog
Gadget.hasMany(MaintenanceLog, { foreignKey: 'gadgetId', as: 'logs' });
MaintenanceLog.belongsTo(Gadget, { foreignKey: 'gadgetId' });

module.exports = {
    sequelize,
    User,
    Gadget,
    Folder,
    MaintenanceLog
};
