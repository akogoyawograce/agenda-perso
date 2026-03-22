// Service d'alarme côté frontend
// Vérifie toutes les minutes si un événement commence bientôt

import { useEventsStore } from '@/stores/events'
import dayjs from 'dayjs'

let alarmInterval = null
const alreadyTriggered = new Set() // évite les doublons

// Génère un son d'alarme avec l'API Web Audio
function playAlarmSound() {
    const ctx = new (window.AudioContext || window.webkitAudioContext)()

        // 3 bips successifs
        ;[0, 0.3, 0.6].forEach(delay => {
            const oscillator = ctx.createOscillator()
            const gainNode = ctx.createGain()

            oscillator.connect(gainNode)
            gainNode.connect(ctx.destination)

            oscillator.type = 'sine'
            oscillator.frequency.setValueAtTime(880, ctx.currentTime + delay)
            gainNode.gain.setValueAtTime(0.5, ctx.currentTime + delay)
            gainNode.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + delay + 0.25)

            oscillator.start(ctx.currentTime + delay)
            oscillator.stop(ctx.currentTime + delay + 0.25)
        })
}

// Affiche une notification visuelle dans le navigateur
function showBrowserNotification(title, body) {
    if (Notification.permission === 'granted') {
        new Notification(title, {
            body,
            icon: '/favicon.ico',
        })
    }
}

// Demander la permission de notification au démarrage
export async function requestNotificationPermission() {
    if ('Notification' in window && Notification.permission === 'default') {
        await Notification.requestPermission()
    }
}

// Démarrer la surveillance des événements
export function startAlarmWatcher(onAlarm) {
    if (alarmInterval) clearInterval(alarmInterval)

    alarmInterval = setInterval(() => {
        const store = useEventsStore()
        const now = dayjs()

        store.events.forEach(event => {
            const eventTime = dayjs(event.start_at)
            const diffMin = eventTime.diff(now, 'minute')
            const key = `${event.id}-${diffMin}`

            // Déclencher à exactement 0 minute (l'heure est arrivée)
            if (diffMin === 0 && !alreadyTriggered.has(key)) {
                alreadyTriggered.add(key)
                playAlarmSound()
                showBrowserNotification(
                    '⏰ ' + event.title,
                    "C'est l'heure de votre événement !"
                )
                if (onAlarm) onAlarm(event)
            }

            // Avertissement 5 minutes avant
            if (diffMin === 5 && !alreadyTriggered.has(key)) {
                alreadyTriggered.add(key)
                showBrowserNotification(
                    '🔔 Dans 5 minutes : ' + event.title,
                    'Votre événement commence bientôt'
                )
                if (onAlarm) onAlarm({ ...event, warning: true })
            }
        })
    }, 60000) // toutes les 60 secondes
}

export function stopAlarmWatcher() {
    if (alarmInterval) clearInterval(alarmInterval)
}