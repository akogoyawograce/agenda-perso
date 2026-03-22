<template>
  <div class="min-h-screen bg-gray-50" @click="showExport = false">

    <!-- Header -->
    <header class="bg-white shadow-sm px-6 py-4 flex justify-between items-center">
      <h1 class="text-xl font-bold text-blue-600">📅 Agenda Personnel</h1>
      <div class="flex items-center gap-3 flex-wrap">

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
              <p class="text-xs text-gray-400 px-3 py-1 font-medium uppercase">
                Exporter les événements
              </p>
              <button @click="doExport('pdf')"
                class="w-full text-left px-3 py-2 rounded-lg hover:bg-gray-50 text-sm flex items-center gap-3">
                <span>📄</span>
                <div>
                  <p class="font-medium">Export PDF</p>
                  <p class="text-xs text-gray-400">Liste des événements</p>
                </div>
              </button>
              <button @click="doExport('emploi')"
                class="w-full text-left px-3 py-2 rounded-lg hover:bg-blue-50 text-sm flex items-center gap-3">
                <span>🗓</span>
                <div>
                  <p class="font-medium text-blue-600">Emploi du temps PDF</p>
                  <p class="text-xs text-gray-400">Vue semaine A4 paysage</p>
                </div>
              </button>
              <hr class="my-1"/>
              <button @click="doExport('excel')"
                class="w-full text-left px-3 py-2 rounded-lg hover:bg-gray-50 text-sm flex items-center gap-3">
                <span>📊</span>
                <div>
                  <p class="font-medium">Export Excel</p>
                  <p class="text-xs text-gray-400">Fichier .xlsx</p>
                </div>
              </button>
              <button @click="doExport('csv')"
                class="w-full text-left px-3 py-2 rounded-lg hover:bg-gray-50 text-sm flex items-center gap-3">
                <span>📋</span>
                <div>
                  <p class="font-medium">Export CSV</p>
                  <p class="text-xs text-gray-400">Compatible Excel, Sheets</p>
                </div>
              </button>
            </div>
          </div>
        </div>

        <button @click="showImport = true"
          class="px-4 py-2 bg-orange-500 text-white rounded-lg text-sm font-medium hover:bg-orange-600 transition">
          🔗 Importer un lien
        </button>

        <span class="text-gray-600 text-sm hidden md:block">{{ auth.user?.full_name }}</span>
        <button @click="handleLogout"
          class="text-sm text-red-500 hover:text-red-700 font-medium">
          Déconnexion
        </button>
      </div>
    </header>

    <!-- Calendrier -->
    <main class="max-w-4xl mx-auto p-6">

      <div class="flex justify-between items-center mb-6">
        <button @click="prevMonth"
          class="px-4 py-2 bg-white rounded-lg shadow text-gray-600 hover:bg-gray-50">
          ← Précédent
        </button>
        <h2 class="text-lg font-semibold text-gray-800">{{ monthLabel }}</h2>
        <button @click="nextMonth"
          class="px-4 py-2 bg-white rounded-lg shadow text-gray-600 hover:bg-gray-50">
          Suivant →
        </button>
      </div>

      <div class="bg-white rounded-2xl shadow overflow-hidden">
        <div class="grid grid-cols-7 bg-blue-600">
          <div v-for="day in ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim']" :key="day"
            class="text-center text-white text-sm font-medium py-3">
            {{ day }}
          </div>
        </div>
        <div class="grid grid-cols-7">
          <div v-for="(day, index) in calendarDays" :key="index"
            @click="day.date && selectDay(day.date)"
            class="min-h-24 border border-gray-100 p-2 cursor-pointer hover:bg-blue-50 transition"
            :class="{
              'bg-gray-50': !day.date,
              'bg-blue-50 border-blue-200': day.date === selectedDay,
            }">
            <span v-if="day.date" class="text-sm font-medium"
              :class="day.isToday
                ? 'bg-blue-600 text-white rounded-full w-7 h-7 flex items-center justify-center'
                : 'text-gray-700'">
              {{ day.label }}
            </span>
            <div v-for="event in getEventsForDay(day.date)" :key="event.id"
              class="mt-1 text-xs px-2 py-1 rounded-full truncate text-white"
              :style="{ backgroundColor: event.color || '#1A73E8' }">
              {{ event.title }}
            </div>
          </div>
        </div>
      </div>

      <button @click="showForm = true"
        class="fixed bottom-8 right-8 bg-blue-600 text-white rounded-full w-14 h-14 text-3xl shadow-lg hover:bg-blue-700 transition">
        +
      </button>

    </main>

    <!-- Modal nouvel événement -->
    <div v-if="showForm"
      class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50">
      <div class="bg-white rounded-2xl shadow-xl p-6 w-full max-w-md mx-4">
        <h3 class="text-lg font-bold text-gray-800 mb-4">Nouvel événement</h3>
        <div class="space-y-3">

          <input v-model="newEvent.title" placeholder="Titre de l'événement *"
            class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />

          <div>
            <label class="text-sm text-gray-600 mb-1 block">📅 Date</label>
            <input v-model="eventDate" type="date"
              class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />
          </div>

          <div class="flex gap-3">
            <div class="flex-1">
              <label class="text-sm text-gray-600 mb-1 block">🕐 Début</label>
              <input v-model="eventTimeStart" type="time"
                class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />
            </div>
            <div class="flex-1">
              <label class="text-sm text-gray-600 mb-1 block">🕑 Fin</label>
              <input v-model="eventTimeEnd" type="time"
                class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />
            </div>
          </div>

          <input v-model="newEvent.location" placeholder="📍 Lieu (optionnel)"
            class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />

          <textarea v-model="newEvent.description" placeholder="Description (optionnel)"
            class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400 h-16 resize-none" />

          <div>
            <label class="text-sm text-gray-600 mb-1 block">🔔 Me rappeler</label>
            <div class="flex gap-3 flex-wrap">
              <label v-for="r in reminderOptions" :key="r.value"
                class="flex items-center gap-1 text-sm cursor-pointer bg-gray-50 border rounded-lg px-3 py-1"
                :class="newEvent.reminders.includes(r.value)
                  ? 'border-blue-400 bg-blue-50 text-blue-600'
                  : 'border-gray-200'">
                <input type="checkbox" :value="r.value" v-model="newEvent.reminders" class="hidden" />
                {{ r.label }}
              </label>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <label class="text-sm text-gray-600">🎨 Couleur :</label>
            <div class="flex gap-2">
              <div v-for="c in colorOptions" :key="c"
                @click="newEvent.color = c"
                class="w-7 h-7 rounded-full cursor-pointer border-2 transition"
                :style="{ backgroundColor: c }"
                :class="newEvent.color === c ? 'border-gray-800 scale-110' : 'border-transparent'">
              </div>
            </div>
          </div>

          <div v-if="newEvent.title && eventDate && eventTimeStart"
            class="bg-blue-50 border border-blue-200 rounded-lg px-4 py-3 text-sm text-blue-700">
            📌 <strong>{{ newEvent.title }}</strong>
            {{ newEvent.location ? '— ' + newEvent.location : '' }}
            <br/>📅 {{ formatEventSummary }}
          </div>

        </div>

        <p v-if="formError" class="text-red-500 text-sm mt-2">{{ formError }}</p>

        <div class="flex gap-3 mt-4">
          <button @click="showForm = false"
            class="flex-1 border border-gray-300 text-gray-600 py-2 rounded-lg hover:bg-gray-50">
            Annuler
          </button>
          <button @click="createEvent" :disabled="formLoading"
            class="flex-1 bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50">
            {{ formLoading ? 'Création...' : 'Créer' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal import depuis lien -->
    <div v-if="showImport"
      class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50">
      <div class="bg-white rounded-2xl shadow-xl p-6 w-full max-w-lg mx-4">
        <h3 class="text-lg font-bold text-gray-800 mb-2">🔗 Importer depuis un lien</h3>
        <p class="text-sm text-gray-500 mb-4">
          Colle un lien iCal (.ics) ou Google Calendar
        </p>

        <input v-model="importUrl"
          placeholder="https://... ou lien .ics"
          class="w-full border rounded-lg px-4 py-2 mb-3 focus:outline-none focus:ring-2 focus:ring-blue-400 text-sm" />

        <div v-if="importedEvents.length > 0" class="mb-4">
          <p class="text-sm font-medium text-gray-700 mb-2">
            {{ importedEvents.length }} événement(s) trouvé(s) :
          </p>
          <div class="max-h-48 overflow-y-auto space-y-2">
            <div v-for="e in importedEvents" :key="e.title"
              class="bg-blue-50 border border-blue-200 rounded-lg px-3 py-2 text-sm">
              <p class="font-medium text-blue-800">{{ e.title }}</p>
              <p class="text-blue-600 text-xs">{{ e.date }} à {{ e.time }}</p>
              <p v-if="e.location" class="text-blue-500 text-xs">📍 {{ e.location }}</p>
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
            @click="fetchImportPreview"
            :disabled="!importUrl || importLoading"
            class="flex-1 bg-orange-500 text-white py-2 rounded-lg hover:bg-orange-600 disabled:opacity-50 text-sm">
            {{ importLoading ? 'Chargement...' : 'Prévisualiser' }}
          </button>
          <button v-else
            @click="confirmImport"
            :disabled="importLoading"
            class="flex-1 bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 text-sm">
            {{ importLoading ? 'Import...' : 'Importer tout' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Popup alarme -->
    <div v-if="showAlarm && activeAlarm"
      class="fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50">
      <div class="bg-white rounded-2xl shadow-2xl p-8 w-full max-w-sm mx-4 text-center animate-bounce">
        <div class="text-5xl mb-4">⏰</div>
        <h2 class="text-2xl font-bold text-gray-800 mb-2">
          {{ activeAlarm.warning ? 'Dans 5 minutes !' : "C'est l'heure !" }}
        </h2>
        <p class="text-lg text-blue-600 font-semibold mb-1">{{ activeAlarm.title }}</p>
        <p v-if="activeAlarm.description" class="text-gray-500 text-sm mb-4">
          {{ activeAlarm.description }}
        </p>
        <p class="text-gray-400 text-sm mb-6">
          {{ dayjs(activeAlarm.start_at).format('HH:mm') }}
        </p>
        <button @click="dismissAlarm"
          class="w-full bg-blue-600 text-white py-3 rounded-xl font-semibold hover:bg-blue-700 transition">
          OK, j'ai vu !
        </button>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useEventsStore } from '@/stores/events'
import { startAlarmWatcher, stopAlarmWatcher, requestNotificationPermission } from '@/services/alarm'
import { exportPDF, exportExcel, exportCSV, exportEmploiDuTempsPDF } from '@/services/export'
import api from '@/services/api'
import dayjs from 'dayjs'
import 'dayjs/locale/fr'
dayjs.locale('fr')

const router      = useRouter()
const auth        = useAuthStore()
const eventsStore = useEventsStore()

const currentDate    = ref(dayjs())
const selectedDay    = ref(dayjs().format('YYYY-MM-DD'))
const showForm       = ref(false)
const formError      = ref('')
const formLoading    = ref(false)
const activeAlarm    = ref(null)
const showAlarm      = ref(false)
const showExport     = ref(false)
const showImport     = ref(false)
const importUrl      = ref('')
const importedEvents = ref([])
const importError    = ref('')
const importLoading  = ref(false)

const eventDate      = ref(dayjs().format('YYYY-MM-DD'))
const eventTimeStart = ref('08:00')
const eventTimeEnd   = ref('09:00')

const newEvent = ref({
  title: '', description: '', location: '',
  color: '#1A73E8', reminders: []
})

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

const formatEventSummary = computed(() => {
  if (!eventDate.value || !eventTimeStart.value) return ''
  const date = dayjs(`${eventDate.value} ${eventTimeStart.value}`)
  const end  = eventTimeEnd.value
    ? dayjs(`${eventDate.value} ${eventTimeEnd.value}`)
    : null
  let str = date.format('dddd D MMMM YYYY [à] HH[h]mm')
  if (end) str += ` → ${end.format('HH[h]mm')}`
  return str
})

const monthLabel = computed(() =>
  currentDate.value.format('MMMM YYYY')
)

const calendarDays = computed(() => {
  const start = currentDate.value.startOf('month')
  const end   = currentDate.value.endOf('month')
  const days  = []
  const today = dayjs().format('YYYY-MM-DD')
  let startDay = start.day() === 0 ? 6 : start.day() - 1
  for (let i = 0; i < startDay; i++) days.push({ date: null, label: '' })
  for (let d = start; d.isBefore(end) || d.isSame(end, 'day'); d = d.add(1, 'day')) {
    const dateStr = d.format('YYYY-MM-DD')
    days.push({ date: dateStr, label: d.date(), isToday: dateStr === today })
  }
  return days
})

function getEventsForDay(date) {
  if (!date) return []
  return eventsStore.eventsByDay[date] || []
}

function selectDay(date) {
  selectedDay.value = date
  eventDate.value   = date
  showForm.value    = true
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

async function createEvent() {
  if (!newEvent.value.title || !eventDate.value || !eventTimeStart.value) {
    formError.value = 'Titre, date et heure requis'
    return
  }
  formLoading.value = true
  formError.value   = ''
  try {
    const start_at = new Date(`${eventDate.value}T${eventTimeStart.value}`).toISOString()
    const end_at   = eventTimeEnd.value
      ? new Date(`${eventDate.value}T${eventTimeEnd.value}`).toISOString()
      : null
    await eventsStore.createEvent({ ...newEvent.value, start_at, end_at })
    showForm.value       = false
    newEvent.value       = { title: '', description: '', location: '', color: '#1A73E8', reminders: [] }
    eventTimeStart.value = '08:00'
    eventTimeEnd.value   = '09:00'
  } catch (err) {
    formError.value = err.response?.data?.error || 'Erreur lors de la création'
  } finally {
    formLoading.value = false
  }
}

function doExport(type) {
  showExport.value = false
  const allEvents  = eventsStore.events
  if (allEvents.length === 0) {
    alert('Aucun événement à exporter pour ce mois')
    return
  }
  if (type === 'pdf')    exportPDF(allEvents)
  if (type === 'excel')  exportExcel(allEvents)
  if (type === 'csv')    exportCSV(allEvents)
  if (type === 'emploi') exportEmploiDuTempsPDF(allEvents, currentDate.value.toDate())
}

async function fetchImportPreview() {
  importError.value   = ''
  importLoading.value = true
  try {
    const { data } = await api.post('/events/import-preview', { url: importUrl.value })
    importedEvents.value = data
  } catch (err) {
    importError.value = "Impossible de lire ce lien. Vérifie qu'il s'agit d'un lien iCal valide (.ics)"
  } finally {
    importLoading.value = false
  }
}

async function confirmImport() {
  importLoading.value = true
  try {
    for (const event of importedEvents.value) {
      await eventsStore.createEvent(event)
    }
    showImport.value     = false
    importUrl.value      = ''
    importedEvents.value = []
    await loadEvents()
  } catch (err) {
    importError.value = "Erreur lors de l'import"
  } finally {
    importLoading.value = false
  }
}

function dismissAlarm() {
  showAlarm.value   = false
  activeAlarm.value = null
}

function handleLogout() {
  stopAlarmWatcher()
  auth.logout()
  router.push('/login')
}

onMounted(async () => {
  await loadEvents()
  await requestNotificationPermission()
  startAlarmWatcher((event) => {
    activeAlarm.value = event
    showAlarm.value   = true
  })
})

onUnmounted(() => stopAlarmWatcher())
</script>