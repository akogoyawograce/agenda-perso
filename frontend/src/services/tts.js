// frontend/src/services/tts.js
/**
 * Service Text-to-Speech pour le navigateur (Web Speech API)
 * Utilisé dans EmploiDuTempsView.vue et CalendarView.vue
 */

export function speakDailyProgram(userName, events) {
    if (!('speechSynthesis' in window)) {
        console.warn("❌ Votre navigateur ne supporte pas la synthèse vocale");
        alert("Votre navigateur ne supporte pas la lecture vocale.");
        return;
    }

    const utterance = new SpeechSynthesisUtterance();
    utterance.lang = 'fr-FR';
    utterance.rate = 0.92;      // un peu plus naturel
    utterance.pitch = 1.05;
    utterance.volume = 1.0;

    let text = '';

    if (events.length === 0) {
        text = `Bonjour ${userName || 'cher utilisateur'}, vous n'avez aucun événement aujourd'hui. Bonne journée !`;
    } else {
        text = `Bonjour ${userName || 'cher utilisateur'}, vous avez ${events.length} événement`;
        if (events.length > 1) text += 's';
        text += " aujourd'hui. ";

        // Tri par heure
        events.sort((a, b) => new Date(a.start_at) - new Date(b.start_at));

        events.forEach((event) => {
            const startTime = new Date(event.start_at).toLocaleTimeString('fr-FR', {
                hour: '2-digit',
                minute: '2-digit'
            });

            text += `À ${startTime} : ${event.title}. `;

            if (event.location) {
                text += `Lieu : ${event.location}. `;
            }
        });
    }

    utterance.text = text;
    window.speechSynthesis.cancel(); // Arrête toute lecture en cours
    window.speechSynthesis.speak(utterance);

    console.log("🗣️ Lecture vocale lancée :", text);
}

// Fonction utilitaire pour lire n'importe quel texte
export function speak(text) {
    if (!('speechSynthesis' in window)) return;
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'fr-FR';
    window.speechSynthesis.speak(utterance);
}