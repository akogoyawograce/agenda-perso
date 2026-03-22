<template>
  <div class="min-h-screen bg-gray-50 flex items-center justify-center">
    <div class="bg-white p-8 rounded-2xl shadow-md w-full max-w-md">

      <h1 class="text-2xl font-bold text-center text-blue-600 mb-2">📅 Agenda Personnel</h1>
      <p class="text-center text-gray-500 mb-6">{{ isLogin ? 'Connexion' : 'Créer un compte' }}</p>

      <form @submit.prevent="handleSubmit" class="space-y-4">
        <div v-if="!isLogin">
          <label class="block text-sm text-gray-600 mb-1">Nom complet</label>
          <input v-model="form.full_name" type="text" placeholder="Yawo Grace"
            class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />
        </div>

        <div>
          <label class="block text-sm text-gray-600 mb-1">Email</label>
          <input v-model="form.email" type="email" placeholder="email@example.com"
            class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />
        </div>

        <div>
          <label class="block text-sm text-gray-600 mb-1">Mot de passe</label>
          <input v-model="form.password" type="password" placeholder="••••••••"
            class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />
        </div>

        <p v-if="error" class="text-red-500 text-sm">{{ error }}</p>

        <button type="submit" :disabled="loading"
          class="w-full bg-blue-600 text-white py-2 rounded-lg font-medium hover:bg-blue-700 transition disabled:opacity-50">
          {{ loading ? 'Chargement...' : isLogin ? 'Se connecter' : "S'inscrire" }}
        </button>
      </form>

      <p class="text-center text-sm text-gray-500 mt-4">
        {{ isLogin ? 'Pas encore de compte ?' : 'Déjà un compte ?' }}
        <button @click="isLogin = !isLogin" class="text-blue-600 font-medium ml-1">
          {{ isLogin ? "S'inscrire" : 'Se connecter' }}
        </button>
      </p>

    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router  = useRouter()
const auth    = useAuthStore()
const isLogin = ref(true)
const loading = ref(false)
const error   = ref('')

const form = reactive({ email: '', password: '', full_name: '' })

async function handleSubmit() {
  error.value   = ''
  loading.value = true
  try {
    if (isLogin.value) {
      await auth.login(form.email, form.password)
    } else {
      await auth.register(form.email, form.password, form.full_name)
    }
    router.push('/calendar')
  } catch (err) {
    error.value = err.response?.data?.error || 'Une erreur est survenue'
  } finally {
    loading.value = false
  }
}
</script>