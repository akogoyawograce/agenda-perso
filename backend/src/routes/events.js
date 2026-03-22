const express = require('express');
const { supabase } = require('../services/supabase');
const { authMiddleware } = require('../middlewares/auth');
const router = express.Router();

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

// POST /api/events/import-preview
router.post('/import-preview', async (req, res) => {
    const { url } = req.body
    if (!url) return res.status(400).json({ error: 'URL requise' })

    try {
        const ical = require('node-ical')
        const events = await ical.async.fromURL(url)
        const result = []

        for (const key in events) {
            const event = events[key]
            if (event.type !== 'VEVENT') continue

            const startDate = event.start ? new Date(event.start) : null
            const endDate = event.end ? new Date(event.end) : null
            if (!startDate) continue

            result.push({
                title: event.summary || 'Événement importé',
                description: event.description || '',
                location: event.location || '',
                start_at: startDate.toISOString(),
                end_at: endDate ? endDate.toISOString() : null,
                date: startDate.toISOString().split('T')[0],
                time: startDate.toTimeString().slice(0, 5),
                color: '#1A73E8',
                reminders: [],
            })
        }

        if (result.length === 0) {
            return res.status(400).json({ error: 'Aucun événement trouvé dans ce lien' })
        }

        res.json(result)
    } catch (err) {
        console.error('Import iCal error:', err.message)
        res.status(400).json({ error: 'Impossible de lire ce lien iCal' })
    }
})

// POST /api/events
router.post('/', async (req, res) => {
    const { title, description, start_at, end_at, all_day,
        location, recurrence, color, category_id, reminders } = req.body;

    if (!title || !start_at) {
        return res.status(400).json({ error: 'Titre et date de début requis' });
    }

    const { data: event, error } = await supabase
        .from('events')
        .insert({
            user_id: req.user.id,
            title, description, start_at, end_at,
            all_day: all_day || false,
            location,
            recurrence: recurrence || 'none',
            color, category_id
        })
        .select()
        .single();

    if (error) return res.status(500).json({ error: error.message });

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

module.exports = router;