const express = require('express');
const jwt = require('jsonwebtoken');
const { supabase } = require('../services/supabase');
const router = express.Router();

// POST /api/auth/register
router.post('/register', async (req, res) => {
    const { email, password, full_name } = req.body;

    if (!email || !password || !full_name) {
        return res.status(400).json({ error: 'Tous les champs sont requis' });
    }

    // Créer l'utilisateur dans Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
    });

    if (authError) return res.status(400).json({ error: authError.message });

    // Créer le profil dans la table profiles
    const { error: profileError } = await supabase
        .from('profiles')
        .insert({ id: authData.user.id, full_name });

    if (profileError) return res.status(400).json({ error: profileError.message });

    // Générer le JWT
    const token = jwt.sign(
        { id: authData.user.id, email },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
    );

    res.status(201).json({ token, user: { id: authData.user.id, email, full_name } });
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email et mot de passe requis' });
    }

    // Vérifier les identifiants via Supabase Auth
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) return res.status(401).json({ error: 'Identifiants incorrects' });

    // Récupérer le profil
    const { data: profile } = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', data.user.id)
        .single();

    // Générer le JWT
    const token = jwt.sign(
        { id: data.user.id, email },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
    );

    res.json({ token, user: { id: data.user.id, email, full_name: profile?.full_name } });
});

module.exports = router;