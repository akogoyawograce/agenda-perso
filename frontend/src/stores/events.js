import { defineStore } from 'pinia'
import api from '@/services/api'

export const useEventsStore = defineStore('events', {
    state: () => ({
        events: [],
        loading: false,
        error: null,
    }),

    getters: {
        eventsByDay: (state) => {
            return state.events.reduce((acc, event) => {
                const day = event.start_at.split('T')[0]
                if (!acc[day]) acc[day] = []
                acc[day].push(event)
                return acc
            }, {})
        },
    },

    actions: {
        async fetchMonth(year, month) {
            this.loading = true
            const m = String(month).padStart(2, '0')
            const { data } = await api.get(`/events?month=${year}-${m}`)
            this.events = data
            this.loading = false
        },

        async createEvent(payload) {
            const { data } = await api.post('/events', payload)
            this.events.push(data)
            return data
        },

        async deleteEvent(id) {
            await api.delete(`/events/${id}`)
            this.events = this.events.filter(e => e.id !== id)
        },
    },
})