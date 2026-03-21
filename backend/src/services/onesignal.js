async function sendPushNotification(playerId, title, body, data = {}) {
    try {
        const response = await fetch('https://onesignal.com/api/v1/notifications', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Basic ${process.env.ONESIGNAL_API_KEY}`,
            },
            body: JSON.stringify({
                app_id: process.env.ONESIGNAL_APP_ID,
                include_player_ids: [playerId],
                headings: { fr: title, en: title },
                contents: { fr: body, en: body },
                data,
            }),
        });

        const result = await response.json();
        console.log('✅ Notification envoyée:', result.id);
        return result;
    } catch (err) {
        console.error('❌ Erreur OneSignal:', err.message);
    }
}

module.exports = { sendPushNotification };