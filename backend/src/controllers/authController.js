const { User, Gadget } = require('../models');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const ensureSampleGadget = async (userId) => {
    const count = await Gadget.count({ where: { userId } });
    if (count === 0) {
        await Gadget.create({
            name: "Sample iPhone 13",
            category: "smartphone",
            brand: "Apple",
            model: "iPhone 13",
            serialNumber: "SMPL-IP13-DEBUG",
            purchaseDate: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000), // 1 year ago
            purchasePrice: 799.00,
            conditionScore: 9,
            status: "active",
            userId: userId,
            imageUrls: ["https://images.unsplash.com/photo-1632661674596-df8be070a5c5?q=80&w=1000&auto=format&fit=crop"],
            description: "A sample iPhone 13 generated for testing marketplace compliance and re-commerce links.",
            customFields: { "Storage": "128GB", "Battery Health": "98%" }
        });
    }
};

const register = async (req, res) => {
    try {
        const { email, password, name } = req.body;

        const existingUser = await User.findOne({ where: { email } });
        if (existingUser) {
            return res.status(400).json({ error: 'Email already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const user = await User.create({
            email,
            password: hashedPassword,
            displayName: name,
            firebaseId: `local_${Date.now()}` // Placeholder for hybrid compatibility
        });

        const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET || 'dev_secret', { expiresIn: '7d' });
        const refreshToken = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'dev_secret', { expiresIn: '30d' });

        await ensureSampleGadget(user.id);

        res.status(201).json({
            user: { id: user.id, email: user.email, name: user.displayName },
            token,
            refreshToken,
            expiresIn: 7 * 24 * 60 * 60 // 7 days in seconds
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await User.findOne({ where: { email } });
        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        if (!user.password) {
            return res.status(401).json({ error: 'Account uses external auth (Google/Firebase)' });
        }

        // Validate password hash format before comparison
        if (!user.password.startsWith('$2a$') && !user.password.startsWith('$2b$')) {
            return res.status(401).json({ error: 'Invalid credentials - corrupted password hash' });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET || 'dev_secret', { expiresIn: '7d' });
        const refreshToken = jwt.sign({ id: user.id }, process.env.JWT_SECRET || 'dev_secret', { expiresIn: '30d' });

        await ensureSampleGadget(user.id);

        res.json({
            user: { id: user.id, email: user.email, name: user.displayName },
            token,
            refreshToken,
            expiresIn: 7 * 24 * 60 * 60 // 7 days in seconds
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

const refreshToken = async (req, res) => {
    try {
        const { refreshToken: token } = req.body;

        if (!token) {
            return res.status(401).json({ error: 'Refresh token required' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret');
        const user = await User.findByPk(decoded.id);

        if (!user) {
            return res.status(401).json({ error: 'User not found' });
        }

        const newToken = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET || 'dev_secret', { expiresIn: '7d' });

        res.json({
            token: newToken,
            expiresIn: 7 * 24 * 60 * 60 // 7 days in seconds
        });
    } catch (error) {
        return res.status(401).json({ error: 'Invalid or expired refresh token' });
    }
};

const changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({ error: 'Current and new password are required' });
        }
        if (newPassword.length < 6) {
            return res.status(400).json({ error: 'New password must be at least 6 characters' });
        }

        const user = await User.findByPk(req.user.id);
        if (!user) return res.status(404).json({ error: 'User not found' });

        if (!user.password || (!user.password.startsWith('$2a$') && !user.password.startsWith('$2b$'))) {
            return res.status(400).json({ error: 'Account does not have a local password set' });
        }

        const isMatch = await bcrypt.compare(currentPassword, user.password);
        if (!isMatch) {
            return res.status(401).json({ error: 'Current password is incorrect' });
        }

        user.password = await bcrypt.hash(newPassword, 10);
        await user.save();

        res.json({ message: 'Password updated successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

module.exports = { register, login, refreshToken, changePassword };
