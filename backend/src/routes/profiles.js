// backend/src/routes/profiles.js
const express = require('express');
const router = express.Router();
const { supabase } = require('../services/supabase');
const { authMiddleware } = require('../middlewares/auth');

// GET /api/profiles/me - Récupérer son propre profil
router.get('/me', authMiddleware, async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('profiles')
            .select('full_name, email, receive_daily_email, timezone')
            .eq('id', req.user.id)
            .single();

        if (error) {
            console.error('Get profile error:', error);
            return res.status(500).json({ error: 'Impossible de récupérer le profil' });
        }

        res.json(data || {});
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// PATCH /api/profiles/me - Mettre à jour son profil
router.patch('/me', authMiddleware, async (req, res) => {
    const { full_name, receive_daily_email } = req.body;

    try {
        const { error } = await supabase
            .from('profiles')
            .update({
                full_name: full_name ? full_name.trim() : null,
                receive_daily_email: receive_daily_email ?? true,
                updated_at: new Date().toISOString()
            })
            .eq('id', req.user.id);

        if (error) {
            console.error('Update profile error:', error);
            return res.status(500).json({ error: 'Erreur lors de la mise à jour du profil' });
        }

        res.json({ success: true, message: 'Profil mis à jour avec succès' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erreur serveur lors de la mise à jour' });
    }
});

module.exports = router;