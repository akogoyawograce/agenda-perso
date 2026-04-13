<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-md mx-auto bg-white rounded-3xl shadow-sm p-8">

      <div class="flex items-center justify-between mb-8">
        <h1 class="text-2xl font-bold text-gray-800">⚙️ Paramètres</h1>
        <button @click="router.back()" 
          class="text-gray-400 hover:text-gray-600 transition">
          ✕
        </button>
      </div>

      <!-- Nom complet -->
      <div class="mb-8">
        <label class="block text-sm font-medium text-gray-600 mb-2">Nom complet</label>
        <input
          v-model="fullName"
          type="text"
          class="w-full px-5 py-3 border border-gray-300 rounded-2xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-lg"
          placeholder="Votre nom"
        />
      </div>

      <!-- Email quotidien -->
      <div class="flex items-center justify-between bg-gray-50 p-5 rounded-2xl mb-4">
        <div class="flex items-center gap-4">
          <div class="w-11 h-11 bg-blue-100 rounded-2xl flex items-center justify-center text-2xl">
            ✉️
          </div>
          <div>
            <p class="font-semibold text-gray-800">Email quotidien</p>
            <p class="text-sm text-gray-500">Recevoir mon programme à 7h</p>
          </div>
        </div>
        <label class="relative inline-flex items-center cursor-pointer">
          <input type="checkbox" v-model="receiveDailyEmail" class="sr-only peer" />
          <div class="w-12 h-6 bg-gray-300 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-0.5 after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
        </label>
      </div>

      <!-- Partage public -->
      <div class="flex items-center justify-between bg-gray-50 p-5 rounded-2xl mb-10">
        <div class="flex items-center gap-4">
          <div class="w-11 h-11 bg-green-100 rounded-2xl flex items-center justify-center text-2xl">
            🔗
          </div>
          <div>
            <p class="font-semibold text-gray-800">Partage public</p>
            <p class="text-sm text-gray-500">Lien de consultation externe</p>
          </div>
        </div>
        <label class="relative inline-flex items-center cursor-pointer">
          <input type="checkbox" v-model="sharePublic" class="sr-only peer" />
          <div class="w-12 h-6 bg-gray-300 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-0.5 after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-600"></div>
        </label>
      </div>

      <!-- Bouton Enregistrer -->
      <button
        @click="saveSettings"
        :disabled="saving"
        class="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white py-4 rounded-2xl font-semibold text-lg transition flex items-center justify-center gap-2">
        <span v-if="saving" class="animate-spin">⟳</span>
        {{ saving ? 'Enregistrement...' : 'Enregistrer les modifications' }}
      </button>

      <button
        @click="router.back()"
        class="w-full mt-4 text-gray-500 py-3 text-sm font-medium">
        Fermer
      </button>

    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'

const router = useRouter()
const authStore = useAuthStore()

const fullName = ref('')
const receiveDailyEmail = ref(true)
const sharePublic = ref(false)
const saving = ref(false)

onMounted(async () => {
  fullName.value = authStore.user?.full_name || ''

  // Charger les préférences actuelles
  try {
    const { data } = await api.get('/profiles/me')
    if (data) {
      receiveDailyEmail.value = data.receive_daily_email ?? true
      // sharePublic.value = data.share_public ?? false
    }
  } catch (e) {
    console.warn("Impossible de charger les préférences du profil")
  }
})

const saveSettings = async () => {
  saving.value = true

  try {
    await api.patch('/profiles/me', {
      full_name: fullName.value.trim(),
      receive_daily_email: receiveDailyEmail.value,
      // share_public: sharePublic.value   // à activer plus tard
    })

    // Mise à jour du store local
    authStore.user.full_name = fullName.value

    alert("✅ Paramètres enregistrés avec succès !")
    router.push('/calendar')

  } catch (error) {
    console.error(error)
    const msg = error.response?.data?.error || "Erreur lors de la sauvegarde"
    alert("❌ " + msg)
  } finally {
    saving.value = false
  }
}
</script>