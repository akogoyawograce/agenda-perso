// backend/src/services/scheduler.js
const cron = require('node-cron');
const { supabase } = require('./supabase');
const { sendPushNotification } = require('./onesignal');
const { sendDailyEmail } = require('./mailer');

// CRON des rappels push (toutes les minutes)
cron.schedule('* * * * *', async () => {
    const now = new Date();
    const inOneMin = new Date(now.getTime() + 60000);

    const { data: reminders, error } = await supabase
        .from('reminders')
        .select(`
      id, offset_min,
      events (
        id, title, description,
        profiles ( onesignal_player_id )
      )
    `)
        .eq('sent', false)
        .gte('remind_at', now.toISOString())
        .lte('remind_at', inOneMin.toISOString());

    if (error) {
        console.error('Scheduler reminders error:', error);
        return;
    }

    for (const reminder of reminders || []) {
        const playerId = reminder.events?.profiles?.onesignal_player_id;
        if (!playerId) continue;

        const offsetLabel = reminder.offset_min >= 60
            ? `${Math.floor(reminder.offset_min / 60)}h`
            : `${reminder.offset_min} min`;

        await sendPushNotification(
            playerId,
            '⏰ Rappel : ' + reminder.events.title,
            `Commence dans ${offsetLabel}`,
            { event_id: reminder.events.id }
        );

        await supabase.from('reminders').update({ sent: true }).eq('id', reminder.id);
    }
});

// CRON email quotidien à 7h00 (heure serveur)
cron.schedule('0 7 * * *', async () => {
    console.log('📧 Lancement du job email quotidien...');

    const { data: users, error } = await supabase
        .from('profiles')
        .select('id, full_name, email, receive_daily_email')
        .eq('receive_daily_email', true);

    if (error || !users) {
        console.error('Erreur récupération users pour email:', error);
        return;
    }

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date(todayStart);
    todayEnd.setHours(23, 59, 59, 999);

    for (const user of users) {
        if (!user.email) continue;

        const { data: events } = await supabase
            .from('events')
            .select('*')
            .eq('user_id', user.id)
            .gte('start_at', todayStart.toISOString())
            .lte('start_at', todayEnd.toISOString())
            .order('start_at', { ascending: true });

        await sendDailyEmail(user, events || []);
    }
});

console.log('✅ Scheduler démarré : rappels push + email quotidien à 7h00');