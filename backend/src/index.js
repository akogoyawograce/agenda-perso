require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const eventsRoutes = require('./routes/events');
const categoriesRoutes = require('./routes/categories');
const notificationsRoutes = require('./routes/notifications');
const { startScheduler } = require('./services/scheduler');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({
    origin: function (origin, callback) {
        // Autoriser localhost sur tous les ports + l'URL frontend
        if (!origin ||
            origin.includes('localhost') ||
            origin === process.env.FRONTEND_URL) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    }
}));
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/events', eventsRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/notifications', notificationsRoutes);

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', message: 'API fonctionne !' });
});

// Démarrer le scheduler de rappels
startScheduler();

app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Serveur démarré sur http://0.0.0.0:${PORT}`);
});