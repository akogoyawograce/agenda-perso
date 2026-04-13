<template>
  <div class="min-h-screen bg-gray-50">

    <!-- HEADER -->
    <header class="bg-white shadow-sm px-6 py-4 flex justify-between items-center sticky top-0 z-50">
      <h1 class="text-xl font-bold text-blue-600 flex items-center gap-2">
        📅 Agenda Personnel
      </h1>
      <div class="flex items-center gap-3">
        <button @click="router.push('/emploi-du-temps')"
          class="px-4 py-2 bg-blue-500 text-white rounded-lg text-sm font-medium hover:bg-blue-600 transition">
          🗓 Emploi du temps
        </button>
        <div class="relative">
          <button @click.stop="showExport = !showExport"
            class="px-4 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 transition">
            ⬇ Exporter
          </button>
          <div v-if="showExport"
            class="absolute right-0 mt-2 w-56 bg-white rounded-xl shadow-xl border border-gray-100 z-50">
            <div class="p-2">
              <button @click="doExport('pdf')"
                class="w-full text-left px-3 py-2 rounded-lg hover:bg-gray-50 text-sm flex items-center gap-3">
                <span>📄</span><div><p class="font-medium">Export PDF</p></div>
              </button>
              <button @click="doExport('emploi')"
                class="w-full text-left px-3 py-2 rounded-lg hover:bg-blue-50 text-sm flex items-center gap-3">
                <span>🗓</span><div><p class="font-medium text-blue-600">Emploi du temps PDF</p></div>
              </button>
              <hr class="my-1"/>
              <button @click="doExport('excel')"
                class="w-full text-left px-3 py-2 rounded-lg hover:bg-gray-50 text-sm flex items-center gap-3">
                <span>📊</span><div><p class="font-medium">Export Excel</p></div>
              </button>
              <button @click="doExport('csv')"
                class="w-full text-left px-3 py-2 rounded-lg hover:bg-gray-50 text-sm flex items-center gap-3">
                <span>📋</span><div><p class="font-medium">Export CSV</p></div>
              </button>
            </div>
          </div>
        </div>
        <button @click="showImport = true"
          class="px-4 py-2 bg-orange-500 text-white rounded-lg text-sm font-medium hover:bg-orange-600 transition">
          🔗 Importer
        </button>
        <span class="text-gray-600 text-sm hidden md:block">{{ auth.user?.full_name }}</span>
        <button @click="handleLogout" class="text-sm text-red-500 hover:text-red-700 font-medium">
          Déconnexion
        </button>
      </div>
    </header>

    <!-- Navigation Mois -->
    <div class="max-w-4xl mx-auto px-6 pt-6 flex justify-between items-center">
      <button @click="prevMonth"
        class="px-6 py-3 bg-white rounded-2xl shadow text-gray-700 hover:bg-gray-50">
        ← Précédent
      </button>
      <h2 class="text-2xl font-semibold text-gray-800">{{ monthLabel }}</h2>
      <button @click="nextMonth"
        class="px-6 py-3 bg-white rounded-2xl shadow text-gray-700 hover:bg-gray-50">
        Suivant →
      </button>
    </div>

    <!-- Calendrier -->
    <main class="max-w-4xl mx-auto p-6">
      <div class="bg-white rounded-3xl shadow overflow-hidden">
        <div class="grid grid-cols-7 bg-blue-600">
          <div v-for="day in ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim']" :key="day"
            class="text-center text-white text-sm font-medium py-4">
            {{ day }}
          </div>
        </div>
        <div class="grid grid-cols-7">
          <div v-for="(day, index) in calendarDays" :key="index"
            class="min-h-[110px] border border-gray-100 p-2 cursor-pointer hover:bg-blue-50 transition"
            :class="{
              'bg-gray-50': !day.date,
              'bg-blue-50 border-blue-200': day.date === selectedDay
            }"
            @click="day.date && selectDay(day.date)">
            <span v-if="day.date" class="text-sm font-medium inline-block mb-2"
              :class="day.isToday
                ? 'bg-blue-600 text-white rounded-full w-7 h-7 flex items-center justify-center'
                : 'text-gray-700'">
              {{ day.label }}
            </span>
            <div v-for="event in getEventsForDay(day.date)" :key="event.id"
              @click.stop="openEventDetail(event)"
              class="mt-1 text-xs px-3 py-1.5 rounded-2xl truncate text-white cursor-pointer hover:brightness-110 transition"
              :style="{ backgroundColor: event.color || '#1A73E8' }">
              {{ event.title }}
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Bouton + -->
    <button @click="showForm = true"
      class="fixed bottom-8 right-8 bg-blue-600 text-white rounded-full w-14 h-14 text-3xl shadow-lg hover:bg-blue-700 transition flex items-center justify-center z-50">
      +
    </button>

    <!-- ── MODAL DÉTAIL ÉVÉNEMENT ── -->
    <div v-if="showDetail && selectedEvent"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[60]">
      <div class="bg-white rounded-3xl shadow-2xl w-full max-w-md mx-4 overflow-hidden">

        <!-- En-tête coloré -->
        <div class="px-6 py-5 text-white relative"
          :style="{ backgroundColor: selectedEvent.color || '#1A73E8' }">
          <button @click="showDetail = false"
            class="absolute top-4 right-4 text-white opacity-70 hover:opacity-100 text-xl">✕</button>
          <h2 class="text-xl font-bold pr-8">{{ selectedEvent.title }}</h2>
          <p class="text-white/80 text-sm mt-1">
            {{ formatEventDate(selectedEvent.start_at) }}
          </p>
        </div>

        <!-- Infos -->
        <div class="p-6 space-y-4">
          <div v-if="selectedEvent.location" class="flex items-start gap-3">
            <span class="text-xl">📍</span>
            <div>
              <p class="text-xs text-gray-400">Lieu</p>
              <p class="text-gray-800 font-medium">{{ selectedEvent.location }}</p>
            </div>
          </div>

          <div class="flex items-start gap-3">
            <span class="text-xl">🕐</span>
            <div>
              <p class="text-xs text-gray-400">Horaire</p>
              <p class="text-gray-800 font-medium">
                {{ formatTime(selectedEvent.start_at) }}
                <span v-if="selectedEvent.end_at"> → {{ formatTime(selectedEvent.end_at) }}</span>
              </p>
            </div>
          </div>

          <div v-if="selectedEvent.description" class="flex items-start gap-3">
            <span class="text-xl">📝</span>
            <div>
              <p class="text-xs text-gray-400">Description</p>
              <p class="text-gray-800">{{ selectedEvent.description }}</p>
            </div>
          </div>

          <!-- Partage -->
          <div class="border-t pt-4">
            <p class="text-sm font-medium text-gray-700 mb-3">🔗 Partager cet événement</p>
            <div class="flex gap-2 flex-wrap">

              <!-- WhatsApp -->
              <button @click="shareViaWhatsapp(selectedEvent)"
                class="flex items-center gap-2 px-4 py-2 bg-green-500 text-white rounded-xl text-sm font-medium hover:bg-green-600 transition">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                </svg>
                WhatsApp
              </button>

              <!-- Google Calendar -->
              <button @click="addToGoogleCalendar(selectedEvent)"
                class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-xl text-sm font-medium hover:bg-blue-700 transition">
                📅 Google Calendar
              </button>

              <!-- Copier lien -->
              <button @click="copyEventLink(selectedEvent)"
                class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-xl text-sm font-medium hover:bg-gray-200 transition">
                🔗 Copier le lien
              </button>

              <!-- Partage natif (mobile) -->
              <button v-if="canShare" @click="nativeShare(selectedEvent)"
                class="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-xl text-sm font-medium hover:bg-purple-700 transition">
                📤 Partager
              </button>

            </div>

            <!-- Lien copié confirmation -->
            <div v-if="linkCopied"
              class="mt-3 p-3 bg-green-50 border border-green-200 rounded-xl text-sm text-green-700 flex items-center gap-2">
              ✅ Lien copié dans le presse-papier !
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="p-6 border-t flex gap-3">
          <button @click="editEvent(selectedEvent)"
            class="flex-1 py-3 bg-blue-600 text-white rounded-2xl font-semibold hover:bg-blue-700 transition flex items-center justify-center gap-2">
            ✏️ Modifier
          </button>
          <button @click="confirmDelete(selectedEvent)"
            class="flex-1 py-3 bg-red-50 text-red-600 rounded-2xl font-semibold hover:bg-red-100 transition flex items-center justify-center gap-2">
            🗑 Supprimer
          </button>
        </div>
      </div>
    </div>

    <!-- ── MODAL MODIFICATION ÉVÉNEMENT ── -->
    <div v-if="showEdit && editingEvent"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[70]">
      <div class="bg-white rounded-3xl shadow-2xl w-full max-w-md mx-4 overflow-hidden max-h-[90vh] overflow-y-auto">

        <div class="px-6 py-5 border-b flex justify-between items-center">
          <h2 class="text-xl font-bold">Modifier l'événement</h2>
          <button @click="showEdit = false" class="text-gray-400 hover:text-gray-600 text-xl">✕</button>
        </div>

        <div class="p-6 space-y-4">

          <div>
            <label class="text-sm text-gray-600 mb-1 block">Titre *</label>
            <input v-model="editingEvent.title"
              class="w-full border border-gray-300 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500" />
          </div>

          <div>
            <label class="text-sm text-gray-600 mb-1 block">📅 Date</label>
            <input v-model="editDate" type="date"
              class="w-full border border-gray-300 rounded-2xl px-4 py-3" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm text-gray-600 mb-1 block">🕐 Début</label>
              <input v-model="editTimeStart" type="time"
                class="w-full border border-gray-300 rounded-2xl px-4 py-3" />
            </div>
            <div>
              <label class="text-sm text-gray-600 mb-1 block">🕑 Fin</label>
              <input v-model="editTimeEnd" type="time"
                class="w-full border border-gray-300 rounded-2xl px-4 py-3" />
            </div>
          </div>

          <div>
            <label class="text-sm text-gray-600 mb-1 block">📍 Lieu</label>
            <input v-model="editingEvent.location"
              class="w-full border border-gray-300 rounded-2xl px-4 py-3"
              placeholder="Lieu (optionnel)" />
          </div>

          <div>
            <label class="text-sm text-gray-600 mb-1 block">Description</label>
            <textarea v-model="editingEvent.description"
              class="w-full border border-gray-300 rounded-2xl px-4 py-3 h-20 resize-none"
              placeholder="Description (optionnel)"></textarea>
          </div>

          <div>
            <label class="text-sm text-gray-600 mb-2 block">🎨 Couleur</label>
            <div class="flex gap-3">
              <div v-for="c in colorOptions" :key="c"
                @click="editingEvent.color = c"
                class="w-9 h-9 rounded-2xl cursor-pointer border-2 transition"
                :style="{ backgroundColor: c }"
                :class="editingEvent.color === c ? 'border-gray-800 scale-110' : 'border-transparent'">
              </div>
            </div>
          </div>

        </div>

        <div class="p-6 border-t flex gap-3">
          <button @click="showEdit = false"
            class="flex-1 py-3 border border-gray-300 text-gray-600 rounded-2xl hover:bg-gray-50">
            Annuler
          </button>
          <button @click="saveEdit" :disabled="editLoading"
            class="flex-1 py-3 bg-blue-600 text-white rounded-2xl font-semibold hover:bg-blue-700 disabled:opacity-70">
            {{ editLoading ? 'Sauvegarde...' : '✅ Sauvegarder' }}
          </button>
        </div>
      </div>
    </div>

    <!-- ── MODAL NOUVEL ÉVÉNEMENT ── -->
    <div v-if="showForm"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[60]">
      <div class="bg-white rounded-3xl shadow-2xl w-full max-w-md mx-4 overflow-hidden max-h-[90vh] overflow-y-auto">

        <div class="px-6 py-5 border-b">
          <h2 class="text-xl font-bold text-center">Nouvel événement</h2>
        </div>

        <div class="p-6 space-y-4">

          <div>
            <label class="text-sm text-gray-600 mb-1 block">Titre *</label>
            <input v-model="newEvent.title"
              class="w-full border border-gray-300 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Réunion importante" />
          </div>

          <div>
            <label class="text-sm text-gray-600 mb-1 block">📅 Date</label>
            <input v-model="eventDate" type="date"
              class="w-full border border-gray-300 rounded-2xl px-4 py-3" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm text-gray-600 mb-1 block">🕐 Début</label>
              <input v-model="eventTimeStart" type="time"
                class="w-full border border-gray-300 rounded-2xl px-4 py-3" />
            </div>
            <div>
              <label class="text-sm text-gray-600 mb-1 block">🕑 Fin</label>
              <input v-model="eventTimeEnd" type="time"
                class="w-full border border-gray-300 rounded-2xl px-4 py-3" />
            </div>
          </div>

          <div>
            <label class="text-sm text-gray-600 mb-1 block">📍 Lieu (optionnel)</label>
            <input v-model="newEvent.location"
              class="w-full border border-gray-300 rounded-2xl px-4 py-3"
              placeholder="Salle de réunion" />
          </div>

          <div>
            <label class="text-sm text-gray-600 mb-1 block">Description (optionnel)</label>
            <textarea v-model="newEvent.description"
              class="w-full border border-gray-300 rounded-2xl px-4 py-3 h-20 resize-none"></textarea>
          </div>

          <div>
            <label class="text-sm text-gray-600 mb-2 block">🔔 Me rappeler</label>
            <div class="flex flex-wrap gap-2">
              <button v-for="r in reminderOptions" :key="r.value"
                @click="toggleReminder(r.value)"
                class="px-4 py-2 text-sm rounded-2xl border transition"
                :class="newEvent.reminders.includes(r.value)
                  ? 'bg-blue-600 text-white border-blue-600'
                  : 'border-gray-300 hover:bg-gray-100'">
                {{ r.label }}
              </button>
            </div>
          </div>

          <div>
            <label class="text-sm text-gray-600 mb-2 block">🎨 Couleur</label>
            <div class="flex gap-3">
              <div v-for="c in colorOptions" :key="c"
                @click="newEvent.color = c"
                class="w-9 h-9 rounded-2xl cursor-pointer border-2 transition"
                :style="{ backgroundColor: c }"
                :class="newEvent.color === c ? 'border-gray-800 scale-110' : 'border-transparent'">
              </div>
            </div>
          </div>

          <div v-if="newEvent.title && eventDate && eventTimeStart"
            class="bg-blue-50 border border-blue-200 rounded-2xl px-4 py-3 text-sm text-blue-700">
            📌 <strong>{{ newEvent.title }}</strong>
            {{ newEvent.location ? '— ' + newEvent.location : '' }}
            <br/>📅 {{ formatEventSummary }}
          </div>

        </div>

        <div class="p-6 border-t flex gap-3">
          <button @click="showForm = false"
            class="flex-1 py-3 text-gray-600 border border-gray-300 rounded-2xl hover:bg-gray-50">
            Annuler
          </button>
          <button @click="createEvent" :disabled="formLoading"
            class="flex-1 py-3 bg-blue-600 text-white rounded-2xl font-semibold hover:bg-blue-700 disabled:opacity-70">
            {{ formLoading ? 'Création...' : 'Créer' }}
          </button>
        </div>
      </div>
    </div>

    <!-- ── MODAL IMPORT ── -->
    <div v-if="showImport"
      class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-[60]">
      <div class="bg-white rounded-2xl shadow-xl p-6 w-full max-w-lg mx-4">
        <h3 class="text-lg font-bold mb-2">🔗 Importer depuis un lien</h3>
        <p class="text-sm text-gray-500 mb-4">Colle un lien iCal (.ics) ou Google Calendar</p>
        <input v-model="importUrl" placeholder="https://... ou lien .ics"
          class="w-full border rounded-lg px-4 py-2 mb-3 focus:outline-none focus:ring-2 focus:ring-blue-400 text-sm" />
        <div v-if="importedEvents.length > 0" class="mb-4">
          <p class="text-sm font-medium text-gray-700 mb-2">{{ importedEvents.length }} événement(s) trouvé(s)</p>
          <div class="max-h-48 overflow-y-auto space-y-2">
            <div v-for="e in importedEvents" :key="e.title"
              class="bg-blue-50 border border-blue-200 rounded-lg px-3 py-2 text-sm">
              <p class="font-medium text-blue-800">{{ e.title }}</p>
              <p class="text-blue-600 text-xs">{{ e.date }} à {{ e.time }}</p>
            </div>
          </div>
        </div>
        <p v-if="importError" class="text-red-500 text-sm mb-3">{{ importError }}</p>
        <div class="flex gap-3">
          <button @click="showImport = false; importUrl = ''; importedEvents = []"
            class="flex-1 border border-gray-300 text-gray-600 py-2 rounded-lg hover:bg-gray-50 text-sm">
            Annuler
          </button>
          <button v-if="importedEvents.length === 0"
            @click="fetchImportPreview" :disabled="!importUrl || importLoading"
            class="flex-1 bg-orange-500 text-white py-2 rounded-lg hover:bg-orange-600 disabled:opacity-50 text-sm">
            {{ importLoading ? 'Chargement...' : 'Prévisualiser' }}
          </button>
          <button v-else @click="confirmImport" :disabled="importLoading"
            class="flex-1 bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 text-sm">
            {{ importLoading ? 'Import...' : 'Importer tout' }}
          </button>
        </div>
      </div>
    </div>

    <!-- ── CONFIRMATION SUPPRESSION ── -->
    <div v-if="showDeleteConfirm"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[80]">
      <div class="bg-white rounded-2xl shadow-xl p-6 w-full max-w-sm mx-4 text-center">
        <div class="text-4xl mb-3">🗑</div>
        <h3 class="text-lg font-bold text-gray-800 mb-2">Supprimer l'événement ?</h3>
        <p class="text-gray-500 text-sm mb-6">
          "{{ eventToDelete?.title }}" sera définitivement supprimé.
        </p>
        <div class="flex gap-3">
          <button @click="showDeleteConfirm = false"
            class="flex-1 py-2 border border-gray-300 rounded-xl text-gray-600 hover:bg-gray-50">
            Annuler
          </button>
          <button @click="deleteEvent"
            class="flex-1 py-2 bg-red-600 text-white rounded-xl hover:bg-red-700">
            Supprimer
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useEventsStore } from '@/stores/events'
import { exportPDF, exportExcel, exportCSV, exportEmploiDuTempsPDF } from '@/services/export'
import api from '@/services/api'
import dayjs from 'dayjs'
import 'dayjs/locale/fr'
dayjs.locale('fr')

const router      = useRouter()
const auth        = useAuthStore()
const eventsStore = useEventsStore()

// ── État calendrier ───────────────────────────────────────────
const currentDate = ref(dayjs())
const selectedDay = ref(dayjs().format('YYYY-MM-DD'))

// ── Modaux ────────────────────────────────────────────────────
const showForm          = ref(false)
const showExport        = ref(false)
const showImport        = ref(false)
const showDetail        = ref(false)
const showEdit          = ref(false)
const showDeleteConfirm = ref(false)

// ── Événement sélectionné ────────────────────────────────────
const selectedEvent  = ref(null)
const editingEvent   = ref(null)
const eventToDelete  = ref(null)

// ── Formulaire création ───────────────────────────────────────
const formLoading    = ref(false)
const eventDate      = ref(dayjs().format('YYYY-MM-DD'))
const eventTimeStart = ref('08:00')
const eventTimeEnd   = ref('09:00')
const newEvent = ref({
  title: '', description: '', location: '',
  color: '#1A73E8', reminders: []
})

// ── Formulaire modification ───────────────────────────────────
const editLoading    = ref(false)
const editDate       = ref('')
const editTimeStart  = ref('')
const editTimeEnd    = ref('')

// ── Partage ───────────────────────────────────────────────────
const linkCopied = ref(false)
const canShare   = computed(() => !!navigator.share)

// ── Import ────────────────────────────────────────────────────
const importUrl      = ref('')
const importedEvents = ref([])
const importError    = ref('')
const importLoading  = ref(false)

const reminderOptions = [
  { label: '5 min',  value: 5    },
  { label: '15 min', value: 15   },
  { label: '1h',     value: 60   },
  { label: '1 jour', value: 1440 },
]

const colorOptions = [
  '#1A73E8', '#E8711A', '#0F966E',
  '#E8001A', '#9C27B0', '#FF9800',
]

// ── Computed ──────────────────────────────────────────────────
const monthLabel = computed(() => currentDate.value.format('MMMM YYYY'))

const formatEventSummary = computed(() => {
  if (!eventDate.value || !eventTimeStart.value) return ''
  const d = dayjs(`${eventDate.value} ${eventTimeStart.value}`)
  const e = eventTimeEnd.value ? dayjs(`${eventDate.value} ${eventTimeEnd.value}`) : null
  let str = d.format('dddd D MMMM YYYY [à] HH[h]mm')
  if (e) str += ` → ${e.format('HH[h]mm')}`
  return str
})

const calendarDays = computed(() => {
  const start   = currentDate.value.startOf('month')
  const end     = currentDate.value.endOf('month')
  const days    = []
  const today   = dayjs().format('YYYY-MM-DD')
  let startDay  = start.day() === 0 ? 6 : start.day() - 1
  for (let i = 0; i < startDay; i++) days.push({ date: null, label: '' })
  for (let d = start; d.isBefore(end) || d.isSame(end, 'day'); d = d.add(1, 'day')) {
    const dateStr = d.format('YYYY-MM-DD')
    days.push({ date: dateStr, label: d.date(), isToday: dateStr === today })
  }
  return days
})

// ── Helpers formatage ─────────────────────────────────────────
function formatEventDate(dt) {
  return dayjs(dt).format('dddd D MMMM YYYY')
}
function formatTime(dt) {
  return dayjs(dt).format('HH:mm')
}

// ── Calendrier ────────────────────────────────────────────────
function getEventsForDay(date) {
  if (!date) return []
  return eventsStore.eventsByDay?.[date] || []
}

function selectDay(date) {
  selectedDay.value    = date
  eventDate.value      = date
  showForm.value       = true
}

function prevMonth() {
  currentDate.value = currentDate.value.subtract(1, 'month')
  loadEvents()
}
function nextMonth() {
  currentDate.value = currentDate.value.add(1, 'month')
  loadEvents()
}

async function loadEvents() {
  await eventsStore.fetchMonth(
    currentDate.value.year(),
    currentDate.value.month() + 1
  )
}

// ── Détail événement ──────────────────────────────────────────
function openEventDetail(event) {
  selectedEvent.value = event
  showDetail.value    = true
  linkCopied.value    = false
}

// ── Modification ──────────────────────────────────────────────
function editEvent(event) {
  editingEvent.value = { ...event }
  const start = dayjs(event.start_at)
  const end   = event.end_at ? dayjs(event.end_at) : null
  editDate.value      = start.format('YYYY-MM-DD')
  editTimeStart.value = start.format('HH:mm')
  editTimeEnd.value   = end ? end.format('HH:mm') : ''
  showDetail.value    = false
  showEdit.value      = true
}

async function saveEdit() {
  if (!editingEvent.value.title) return
  editLoading.value = true
  try {
    const start_at = new Date(`${editDate.value}T${editTimeStart.value}`).toISOString()
    const end_at   = editTimeEnd.value
      ? new Date(`${editDate.value}T${editTimeEnd.value}`).toISOString()
      : null

    await api.put(`/events/${editingEvent.value.id}`, {
      title:       editingEvent.value.title,
      description: editingEvent.value.description,
      location:    editingEvent.value.location,
      color:       editingEvent.value.color,
      start_at, end_at,
    })

    showEdit.value = false
    await loadEvents()
  } catch (err) {
    alert('Erreur lors de la modification')
  } finally {
    editLoading.value = false
  }
}

// ── Suppression ───────────────────────────────────────────────
function confirmDelete(event) {
  eventToDelete.value    = event
  showDeleteConfirm.value = true
  showDetail.value        = false
}

async function deleteEvent() {
  try {
    await eventsStore.deleteEvent(eventToDelete.value.id)
    showDeleteConfirm.value = false
    eventToDelete.value     = null
    await loadEvents()
  } catch (err) {
    alert('Erreur lors de la suppression')
  }
}

// ── Partage ───────────────────────────────────────────────────
function buildEventText(event) {
  const start = dayjs(event.start_at).format('dddd D MMMM YYYY à HH:mm')
  let text = `📅 ${event.title}\n🕐 ${start}`
  if (event.location) text += `\n📍 ${event.location}`
  if (event.description) text += `\n📝 ${event.description}`
  return text
}

function shareViaWhatsapp(event) {
  const text = encodeURIComponent(buildEventText(event))
  window.open(`https://wa.me/?text=${text}`, '_blank')
}

function addToGoogleCalendar(event) {
  const start  = dayjs(event.start_at).format('YYYYMMDDTHHmmss')
  const end    = event.end_at
    ? dayjs(event.end_at).format('YYYYMMDDTHHmmss')
    : dayjs(event.start_at).add(1, 'hour').format('YYYYMMDDTHHmmss')
  const title  = encodeURIComponent(event.title)
  const loc    = encodeURIComponent(event.location || '')
  const desc   = encodeURIComponent(event.description || '')
  const url    = `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${title}&dates=${start}/${end}&location=${loc}&details=${desc}`
  window.open(url, '_blank')
}

async function copyEventLink(event) {
  const text = buildEventText(event)
  try {
    await navigator.clipboard.writeText(text)
    linkCopied.value = true
    setTimeout(() => { linkCopied.value = false }, 3000)
  } catch (err) {
    alert('Impossible de copier')
  }
}

async function nativeShare(event) {
  try {
    await navigator.share({
      title: event.title,
      text:  buildEventText(event),
    })
  } catch (err) {
    console.log('Partage annulé')
  }
}

// ── Création événement ────────────────────────────────────────
function toggleReminder(val) {
  const idx = newEvent.value.reminders.indexOf(val)
  if (idx === -1) newEvent.value.reminders.push(val)
  else newEvent.value.reminders.splice(idx, 1)
}

async function createEvent() {
  if (!newEvent.value.title) { alert('Le titre est obligatoire'); return }
  formLoading.value = true
  try {
    const start_at = new Date(`${eventDate.value}T${eventTimeStart.value}`).toISOString()
    const end_at   = eventTimeEnd.value
      ? new Date(`${eventDate.value}T${eventTimeEnd.value}`).toISOString()
      : null
    await eventsStore.createEvent({ ...newEvent.value, start_at, end_at })
    showForm.value = false
    newEvent.value = { title: '', description: '', location: '', color: '#1A73E8', reminders: [] }
    await loadEvents()
  } catch (err) {
    alert("Erreur lors de la création")
  } finally {
    formLoading.value = false
  }
}

// ── Export ────────────────────────────────────────────────────
function doExport(type) {
  showExport.value = false
  const events = eventsStore.events
  if (events.length === 0) { alert('Aucun événement à exporter'); return }
  if (type === 'pdf')    exportPDF(events)
  if (type === 'excel')  exportExcel(events)
  if (type === 'csv')    exportCSV(events)
  if (type === 'emploi') exportEmploiDuTempsPDF(events, currentDate.value.toDate())
}

// ── Import iCal ───────────────────────────────────────────────
async function fetchImportPreview() {
  importError.value = ''; importLoading.value = true
  try {
    const { data } = await api.post('/events/import-preview', { url: importUrl.value })
    importedEvents.value = data
  } catch {
    importError.value = "Impossible de lire ce lien iCal"
  } finally {
    importLoading.value = false
  }
}

async function confirmImport() {
  importLoading.value = true
  try {
    for (const e of importedEvents.value) await eventsStore.createEvent(e)
    showImport.value = false; importUrl.value = ''; importedEvents.value = []
    await loadEvents()
  } catch {
    importError.value = "Erreur lors de l'import"
  } finally {
    importLoading.value = false
  }
}

// ── Logout ────────────────────────────────────────────────────
function handleLogout() {
  auth.logout()
  router.push('/login')
}

// ── Fermer export au clic extérieur ──────────────────────────
function closeExport() { showExport.value = false }
onMounted(() => { loadEvents(); document.addEventListener('click', closeExport) })
onUnmounted(() => { document.removeEventListener('click', closeExport) })
</script>