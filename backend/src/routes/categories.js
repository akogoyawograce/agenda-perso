const express = require('express');
const { supabase } = require('../services/supabase');
const { authMiddleware } = require('../middlewares/auth');
const router = express.Router();

router.use(authMiddleware);

// GET /api/categories
router.get('/', async (req, res) => {
    const { data, error } = await supabase
        .from('categories')
        .select('*')
        .eq('user_id', req.user.id)
        .order('name');

    if (error) return res.status(500).json({ error: error.message });
    res.json(data);
});

// POST /api/categories
router.post('/', async (req, res) => {
    const { name, color, icon } = req.body;
    if (!name) return res.status(400).json({ error: 'Nom requis' });

    const { data, error } = await supabase
        .from('categories')
        .insert({ user_id: req.user.id, name, color: color || '#1A73E8', icon })
        .select()
        .single();

    if (error) return res.status(500).json({ error: error.message });
    res.status(201).json(data);
});

// PUT /api/categories/:id
router.put('/:id', async (req, res) => {
    const { name, color, icon } = req.body;

    const { data, error } = await supabase
        .from('categories')
        .update({ name, color, icon })
        .eq('id', req.params.id)
        .eq('user_id', req.user.id)
        .select()
        .single();

    if (error) return res.status(500).json({ error: error.message });
    res.json(data);
});

// DELETE /api/categories/:id
router.delete('/:id', async (req, res) => {
    const { error } = await supabase
        .from('categories')
        .delete()
        .eq('id', req.params.id)
        .eq('user_id', req.user.id);

    if (error) return res.status(500).json({ error: error.message });
    res.json({ success: true });
});

module.exports = router;