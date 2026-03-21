const cron = require('node-cron');
const { supabase } = require('./supabase');
const { sendPushNotification } = require('./onesignal');

function startScheduler() {
    console.log('⏰ Scheduler démarré — vérification toutes les minutes');

    cron.schedule('* * * * *', async () => {
        const now = new Date();
        const inOneMin = new Date(now.getTime() + 60000);

        // Chercher les rappels non envoyés dans la prochaine minute
        const { data: reminders, error } = await supabase
            .from('reminders')
            .select(`
        id, offset_min,
        events (
          title,
          profiles ( onesignal_player_id )
        )
      `)
            .eq('sent', false)
            .gte('remind_at', now.toISOString())
            .lte('remind_at', inOneMin.toISOString());

        if (error) { console.error('Scheduler error:', error); return; }
        if (!reminders || reminders.length === 0) return;

        console.log(`📬 ${reminders.length} rappel(s) à envoyer`);

        for (const reminder of reminders) {
            const playerId = reminder.events?.profiles?.onesignal_player_id;

            if (!playerId) {
                console.log('⚠️ Pas de player_id pour ce rappel — ignoré');
                continue;
            }

            const offsetLabel = reminder.offset_min >= 60
                ? `${reminder.offset_min / 60}h`
                : `${reminder.offset_min} min`;

            await sendPushNotification(
                playerId,
                '⏰ Rappel : ' + reminder.events.title,
                `Commence dans ${offsetLabel}`,
                { event_id: reminder.events.id }
            );

            // Marquer comme envoyé
            await supabase
                .from('reminders')
                .update({ sent: true })
                .eq('id', reminder.id);
        }
    });
}

module.exports = { startScheduler };