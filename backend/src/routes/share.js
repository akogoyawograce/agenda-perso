// backend/src/routes/share.js
const express = require('express');
const router = express.Router();
const { supabase } = require('../services/supabase');
const { authMiddleware } = require('../middlewares/auth');
const crypto = require('crypto');

// Générer un token aléatoire
function generateToken() {
    return crypto.randomBytes(16).toString('hex');
}

// POST /api/share/generate → Générer un lien public
router.post('/generate', authMiddleware, async (req, res) => {
    const token = generateToken();
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 jours

    const { error } = await supabase
        .from('shared_calendars')
        .insert({
            user_id: req.user.id,
            token,
            expires_at: expiresAt
        });

    if (error) return res.status(500).json({ error: error.message });

    const publicUrl = `${process.env.FRONTEND_URL || 'http://localhost:5173'}/public/${token}`;

    res.json({
        success: true,
        token,
        publicUrl,
        message: 'Lien de partage généré avec succès'
    });
});

// GET /api/share/public/:token → Récupérer les événements publics (sans authentification)
router.get('/public/:token', async (req, res) => {
    const { token } = req.params;

    const { data: share, error } = await supabase
        .from('shared_calendars')
        .select('user_id, expires_at, is_active')
        .eq('token', token)
        .single();

    if (error || !share || !share.is_active || new Date(share.expires_at) < new Date()) {
        return res.status(404).json({ error: 'Lien de partage invalide ou expiré' });
    }

    // Récupérer les événements de l'utilisateur
    const { data: events } = await supabase
        .from('events')
        .select('id, title, start_at, end_at, location, description, color')
        .eq('user_id', share.user_id)
        .order('start_at');

    res.json({ events });
});

module.exports = router;