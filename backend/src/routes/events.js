const express = require('express');
const { supabase } = require('../services/supabase');
const { authMiddleware } = require('../middlewares/auth');
const router = express.Router();

// Toutes les routes nécessitent d'être connecté
router.use(authMiddleware);

// GET /api/events?month=2026-03
router.get('/', async (req, res) => {
    const { month } = req.query;
    let query = supabase
        .from('events')
        .select('*, categories(name, color, icon)')
        .eq('user_id', req.user.id)
        .order('start_at', { ascending: true });

    if (month) {
        const start = new Date(`${month}-01`);
        const end = new Date(start.getFullYear(), start.getMonth() + 1, 0);
        query = query
            .gte('start_at', start.toISOString())
            .lte('start_at', end.toISOString());
    }

    const { data, error } = await query;
    if (error) return res.status(500).json({ error: error.message });
    res.json(data);
});

// POST /api/events
router.post('/', async (req, res) => {
    const { title, description, start_at, end_at, all_day,
        location, recurrence, color, category_id, reminders } = req.body;

    if (!title || !start_at) {
        return res.status(400).json({ error: 'Titre et date de début requis' });
    }

    // Créer l'événement
    const { data: event, error } = await supabase
        .from('events')
        .insert({
            user_id: req.user.id,
            title, description, start_at, end_at,
            all_day: all_day || false,
            location, recurrence: recurrence || 'none',
            color, category_id
        })
        .select()
        .single();

    if (error) return res.status(500).json({ error: error.message });

    // Créer les rappels si fournis [5, 15, 60, 1440]
    if (reminders && reminders.length > 0) {
        const reminderRows = reminders.map(offset_min => ({
            event_id: event.id,
            offset_min,
            remind_at: new Date(new Date(start_at).getTime() - offset_min * 60000).toISOString()
        }));

        await supabase.from('reminders').insert(reminderRows);
    }

    res.status(201).json(event);
});

// PUT /api/events/:id
router.put('/:id', async (req, res) => {
    const { id } = req.params;
    const { title, description, start_at, end_at,
        all_day, location, recurrence, color, category_id } = req.body;

    const { data, error } = await supabase
        .from('events')
        .update({
            title, description, start_at, end_at,
            all_day, location, recurrence, color,
            category_id, updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .eq('user_id', req.user.id)
        .select()
        .single();

    if (error) return res.status(500).json({ error: error.message });
    if (!data) return res.status(404).json({ error: 'Événement non trouvé' });
    res.json(data);
});

// DELETE /api/events/:id
router.delete('/:id', async (req, res) => {
    const { id } = req.params;

    const { error } = await supabase
        .from('events')
        .delete()
        .eq('id', id)
        .eq('user_id', req.user.id);

    if (error) return res.status(500).json({ error: error.message });
    res.json({ success: true, message: 'Événement supprimé' });
});

// GET /api/events/search?q=...
router.get('/search', async (req, res) => {
    const { q } = req.query;
    if (!q) return res.status(400).json({ error: 'Paramètre q requis' });

    const { data, error } = await supabase
        .from('events')
        .select('*, categories(name, color)')
        .eq('user_id', req.user.id)
        .ilike('title', `%${q}%`);

    if (error) return res.status(500).json({ error: error.message });
    res.json(data);
});

module.exports = router;