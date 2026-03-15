require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { sequelize } = require('./models');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({
    origin: '*',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(morgan('dev'));

// Basic health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date() });
});

// Import routes
const uploadRoutes = require('./routes/uploadRoutes');
const gadgetRoutes = require('./routes/gadgetRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const logRoutes = require('./routes/logRoutes');
const authRoutes = require('./routes/authRoutes');
const folderRoutes = require('./routes/folderRoutes');

app.use('/api/gadgets', gadgetRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/logs', logRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/folders', folderRoutes);
app.use('/api/upload', uploadRoutes);

// Serve static files
const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Sync database and start server
async function startServer() {
    try {
        await sequelize.authenticate();
        console.log('Database connected successfully');
        await sequelize.sync({ force: false });
        console.log('Database synced successfully');
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`Server is running on http://localhost:${PORT}`);
        });
    } catch (err) {
        console.error('Failed to start server:', err);
        process.exit(1); // Explicitly exit with 1 on failure
    }
}

startServer();
