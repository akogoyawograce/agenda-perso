const express = require('express');
const { supabase } = require('../services/supabase');
const { authMiddleware } = require('../middlewares/auth');
const router = express.Router();

// POST /api/notifications/register
router.post('/register', authMiddleware, async (req, res) => {
    const { player_id } = req.body;
    if (!player_id) return res.status(400).json({ error: 'player_id requis' });

    const { error } = await supabase
        .from('profiles')
        .update({ onesignal_player_id: player_id })
        .eq('id', req.user.id);

    if (error) return res.status(500).json({ error: error.message });
    res.json({ success: true });
});

module.exports = router;
