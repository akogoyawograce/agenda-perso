import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
    history: createWebHistory(),
    routes: [
        {
            path: '/settings',
            name: 'Settings',
            component: () => import('@/views/SettingsView.vue')
        },
        {
            path: '/emploi-du-temps',
            component: () => import('@/views/EmploiDuTempsView.vue'),
            meta: { requiresAuth: true }
        },
        {
            path: '/',
            redirect: '/calendar'
        },
        {
            path: '/login',
            component: () => import('@/views/LoginView.vue'),
            meta: { guest: true }
        },
        {
            path: '/calendar',
            component: () => import('@/views/CalendarView.vue'),
            meta: { requiresAuth: true }
        },
    ]
})

// Protection des routes
router.beforeEach((to) => {
    const auth = useAuthStore()
    if (to.meta.requiresAuth && !auth.isLoggedIn) return '/login'
    if (to.meta.guest && auth.isLoggedIn) return '/calendar'
})

export default router