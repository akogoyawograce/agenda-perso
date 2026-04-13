require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const eventsRoutes = require('./routes/events');
const categoriesRoutes = require('./routes/categories');
const notificationsRoutes = require('./routes/notifications');
const profilesRoutes = require('./routes/profiles');
const shareRoutes = require('./routes/share');
require('./services/scheduler');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({ origin: '*' }));
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/events', eventsRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/profiles', profilesRoutes);
app.use('/api/share', shareRoutes);

app.get('/health', (req, res) => {
    res.json({ status: 'OK' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Serveur démarré sur http://localhost:${PORT}`);
});
