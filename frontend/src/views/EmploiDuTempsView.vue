<template>
  <div class="min-h-screen bg-gray-50">

    <!-- Header -->
    <header class="bg-white shadow-sm px-6 py-4 flex justify-between items-center">
      <div class="flex items-center gap-4">
        <button @click="router.push('/calendar')"
          class="text-gray-500 hover:text-blue-600 transition">
          ← Retour
        </button>
        <h1 class="text-xl font-bold text-blue-600">🗓 Emploi du temps</h1>
      </div>
      <div class="flex items-center gap-3">
        <button @click="exportWeekPDF"
          class="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700">
          📄 Exporter PDF
        </button>
        <button @click="exportWeekExcel"
          class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700">
          📊 Exporter Excel
        </button>
      </div>
    </header>

    <!-- Navigation semaine -->
    <div class="max-w-7xl mx-auto px-4 py-4">
      <div class="flex justify-between items-center mb-4">
        <button @click="prevWeek"
          class="px-4 py-2 bg-white rounded-lg shadow text-gray-600 hover:bg-gray-50">
          ← Semaine précédente
        </button>
        <div class="text-center">
          <h2 class="text-lg font-semibold text-gray-800">
            Semaine du {{ weekLabel }}
          </h2>
          <p class="text-sm text-gray-400">{{ weekRange }}</p>
        </div>
        <button @click="nextWeek"
          class="px-4 py-2 bg-white rounded-lg shadow text-gray-600 hover:bg-gray-50">
          Semaine suivante →
        </button>
      </div>

      <!-- Grille emploi du temps -->
      <div class="bg-white rounded-2xl shadow overflow-hidden">

        <!-- En-tête jours -->
        <div class="grid gap-0" :style="gridStyle">
          <div class="bg-gray-100 border-r border-b border-gray-200 p-3 text-center">
            <span class="text-xs text-gray-400 font-medium">HEURE</span>
          </div>
          <div v-for="day in weekDays" :key="day.date"
            class="border-r border-b border-gray-200 p-3 text-center"
            :class="day.isToday ? 'bg-blue-600' : 'bg-gray-50'">
            <p class="text-xs font-medium"
              :class="day.isToday ? 'text-white' : 'text-gray-500'">
              {{ day.dayName }}
            </p>
            <p class="text-lg font-bold"
              :class="day.isToday ? 'text-white' : 'text-gray-800'">
              {{ day.dayNum }}
            </p>
            <p class="text-xs"
              :class="day.isToday ? 'text-blue-200' : 'text-gray-400'">
              {{ day.month }}
            </p>
          </div>
        </div>

        <!-- Lignes horaires -->
        <div v-for="hour in hours" :key="hour"
          class="grid gap-0 border-b border-gray-100"
          :style="gridStyle">

          <!-- Colonne heure -->
          <div class="border-r border-gray-200 p-2 text-center bg-gray-50">
            <span class="text-xs font-medium text-gray-500">
              {{ String(hour).padStart(2, '0') }}:00
            </span>
          </div>

          <!-- Colonne par jour — CLIQUABLE -->
          <div v-for="day in weekDays" :key="day.date"
            class="border-r border-gray-100 min-h-14 p-1 relative cursor-pointer hover:bg-yellow-50 transition group"
            :class="day.isToday ? 'bg-blue-50/30' : ''"
            @click="openAddEvent(day.date, hour)">

            <!-- Événements existants -->
            <div v-for="event in getEventsAt(day.date, hour)" :key="event.id"
              @click.stop
              class="rounded-lg px-2 py-1 mb-1 text-xs hover:opacity-80 transition"
              :style="{ backgroundColor: event.color || '#1A73E8' }">
              <p class="font-semibold text-white truncate">{{ event.title }}</p>
              <p class="text-white/80">
                {{ formatHour(event.start_at) }}
                {{ event.end_at ? '→ ' + formatHour(event.end_at) : '' }}
              </p>
              <p v-if="event.location" class="text-white/70 truncate">
                📍 {{ event.location }}
              </p>
            </div>

            <!-- Indicateur + au hover -->
            <div class="hidden group-hover:flex absolute inset-0 items-center justify-center pointer-events-none">
              <span class="text-gray-300 text-2xl font-light">+</span>
            </div>
          </div>
        </div>

      </div>

      <!-- Légende événements de la semaine -->
      <div class="mt-4 bg-white rounded-xl shadow p-4">
        <p class="text-sm font-medium text-gray-700 mb-3">
          Événements cette semaine ({{ weekEvents.length }})
        </p>
        <div v-if="weekEvents.length === 0"
          class="text-center text-gray-400 py-4">
          Aucun événement — cliquez sur une case pour en ajouter un
        </div>
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2">
          <div v-for="event in weekEvents" :key="event.id"
            class="flex items-start gap-3 p-3 rounded-lg border border-gray-100">
            <div class="w-3 h-3 rounded-full mt-1 flex-shrink-0"
              :style="{ backgroundColor: event.color || '#1A73E8' }">
            </div>
            <div class="flex-1 min-w-0">
              <p class="font-medium text-gray-800 text-sm truncate">
                {{ event.title }}
              </p>
              <p class="text-xs text-gray-500">
                {{ formatFullDate(event.start_at) }}
                {{ event.location ? '• ' + event.location : '' }}
              </p>
            </div>
          </div>
        </div>
      </div>

    </div>

    <!-- ── Modal ajout événement ── -->
    <div v-if="showAddForm"
      class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50">
      <div class="bg-white rounded-2xl shadow-xl p-6 w-full max-w-md mx-4">

        <h3 class="text-lg font-bold text-gray-800 mb-1">Nouvel événement</h3>
        <p class="text-sm text-blue-500 mb-4 font-medium">
          📅 {{ formatSlotLabel }}
        </p>

        <div class="space-y-3">

          <!-- Titre -->
          <input v-model="newEvent.title"
            placeholder="Titre de l'événement *"
            class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />

          <!-- Heures -->
          <div class="flex gap-3">
            <div class="flex-1">
              <label class="text-xs text-gray-500 mb-1 block">🕐 Heure début</label>
              <input v-model="newEvent.startTime" type="time"
                class="w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />
            </div>
            <div class="flex-1">
              <label class="text-xs text-gray-500 mb-1 block">🕑 Heure fin</label>
              <input v-model="newEvent.endTime" type="time"
                class="w-full border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />
            </div>
          </div>

          <!-- Lieu -->
          <input v-model="newEvent.location"
            placeholder="📍 Lieu (optionnel)"
            class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400" />

          <!-- Description -->
          <textarea v-model="newEvent.description"
            placeholder="Description (optionnel)"
            class="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400 h-16 resize-none" />

          <!-- Couleurs -->
          <div class="flex items-center gap-3">
            <label class="text-sm text-gray-600">🎨 Couleur :</label>
            <div class="flex gap-2">
              <div v-for="c in colorOptions" :key="c"
                @click="newEvent.color = c"
                class="w-7 h-7 rounded-full cursor-pointer border-2 transition"
                :style="{ backgroundColor: c }"
                :class="newEvent.color === c
                  ? 'border-gray-800 scale-110'
                  : 'border-transparent'">
              </div>
            </div>
          </div>

          <!-- Résumé -->
          <div v-if="newEvent.title"
            class="bg-blue-50 border border-blue-200 rounded-lg px-4 py-2 text-sm text-blue-700">
            📌 <strong>{{ newEvent.title }}</strong>
            {{ newEvent.location ? '— ' + newEvent.location : '' }}
            <br/>
            {{ formatSlotLabel }} · {{ newEvent.startTime }} → {{ newEvent.endTime }}
          </div>

        </div>

        <p v-if="addError" class="text-red-500 text-sm mt-2">{{ addError }}</p>

        <div class="flex gap-3 mt-4">
          <button @click="showAddForm = false"
            class="flex-1 border border-gray-300 text-gray-600 py-2 rounded-lg hover:bg-gray-50">
            Annuler
          </button>
          <button @click="saveNewEvent" :disabled="addLoading"
            class="flex-1 bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50">
            {{ addLoading ? 'Création...' : 'Créer' }}
          </button>
        </div>

      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useEventsStore } from '@/stores/events'
import { exportEmploiDuTempsPDF } from '@/services/export'
import api from '@/services/api'
import * as XLSX from 'xlsx'
import dayjs from 'dayjs'
import isoWeek from 'dayjs/plugin/isoWeek'
import isSameOrAfter from 'dayjs/plugin/isSameOrAfter'
import isSameOrBefore from 'dayjs/plugin/isSameOrBefore'
import 'dayjs/locale/fr'

dayjs.extend(isoWeek)
dayjs.extend(isSameOrAfter)
dayjs.extend(isSameOrBefore)
dayjs.locale('fr')

const router      = useRouter()
const eventsStore = useEventsStore()
const currentWeek = ref(dayjs().startOf('isoWeek'))

// ── Grille ────────────────────────────────────────────────────────────────
const hours    = Array.from({ length: 16 }, (_, i) => i + 6)
const gridStyle = computed(() => ({
  gridTemplateColumns: `80px repeat(7, 1fr)`
}))

// ── Jours de la semaine ───────────────────────────────────────────────────
const weekDays = computed(() =>
  Array.from({ length: 7 }, (_, i) => {
    const day = currentWeek.value.add(i, 'day')
    return {
      date:    day.format('YYYY-MM-DD'),
      dayName: day.format('ddd').toUpperCase(),
      dayNum:  day.date(),
      month:   day.format('MMM'),
      isToday: day.isSame(dayjs(), 'day'),
    }
  })
)

const weekLabel = computed(() =>
  currentWeek.value.format('D MMMM YYYY')
)

const weekRange = computed(() => {
  const end = currentWeek.value.add(6, 'day')
  return `${currentWeek.value.format('D MMM')} → ${end.format('D MMM YYYY')}`
})

const weekEvents = computed(() => {
  const start = currentWeek.value
  const end   = currentWeek.value.add(6, 'day')
  return eventsStore.events.filter(e => {
    const d = dayjs(e.start_at)
    return d.isSameOrAfter(start, 'day') && d.isSameOrBefore(end, 'day')
  }).sort((a, b) => dayjs(a.start_at).diff(dayjs(b.start_at)))
})

function getEventsAt(date, hour) {
  return eventsStore.events.filter(e => {
    const d = dayjs(e.start_at).local()
    return d.format('YYYY-MM-DD') === date && d.hour() === hour
  })
}

function formatHour(dt)     { return dayjs(dt).format('HH:mm') }
function formatFullDate(dt) { return dayjs(dt).format('ddd D MMM à HH:mm') }

// ── Navigation semaines ───────────────────────────────────────────────────
function prevWeek() {
  currentWeek.value = currentWeek.value.subtract(1, 'week')
  loadWeekEvents()
}
function nextWeek() {
  currentWeek.value = currentWeek.value.add(1, 'week')
  loadWeekEvents()
}
async function loadWeekEvents() {
  await eventsStore.fetchMonth(
    currentWeek.value.year(),
    currentWeek.value.month() + 1
  )
}

// ── Export ────────────────────────────────────────────────────────────────
function exportWeekPDF() {
  if (weekEvents.value.length === 0) {
    alert('Aucun événement cette semaine à exporter')
    return
  }
  exportEmploiDuTempsPDF(weekEvents.value, currentWeek.value.toDate())
}

function exportWeekExcel() {
  if (weekEvents.value.length === 0) {
    alert('Aucun événement cette semaine à exporter')
    return
  }
  const wsData = [
    ['Emploi du temps — Semaine du ' + weekLabel.value],
    [],
    ['Jour','Date','Heure début','Heure fin','Titre','Lieu','Description'],
    ...weekEvents.value.map(e => [
      dayjs(e.start_at).format('dddd'),
      dayjs(e.start_at).format('DD/MM/YYYY'),
      dayjs(e.start_at).format('HH:mm'),
      e.end_at ? dayjs(e.end_at).format('HH:mm') : '-',
      e.title, e.location || '-', e.description || '-',
    ])
  ]
  const ws = XLSX.utils.aoa_to_sheet(wsData)
  ws['!cols'] = [
    {wch:12},{wch:12},{wch:12},{wch:12},{wch:30},{wch:20},{wch:40}
  ]
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, 'Emploi du temps')
  XLSX.writeFile(wb, `emploi-du-temps-${currentWeek.value.format('YYYY-MM-DD')}.xlsx`)
}

// ── Ajout d'événement depuis la grille ────────────────────────────────────
const showAddForm  = ref(false)
const addLoading   = ref(false)
const addError     = ref('')
const selectedSlot = ref({ date: '', hour: 8 })

const colorOptions = [
  '#1A73E8','#E8711A','#0F966E',
  '#E8001A','#9C27B0','#FF9800',
]

const newEvent = ref({
  title: '', location: '', description: '',
  startTime: '08:00', endTime: '09:00', color: '#1A73E8'
})

const formatSlotLabel = computed(() => {
  if (!selectedSlot.value.date) return ''
  return dayjs(selectedSlot.value.date).format('dddd D MMMM YYYY')
})

function openAddEvent(date, hour) {
  selectedSlot.value = { date, hour }
  newEvent.value = {
    title: '', location: '', description: '',
    startTime: `${String(hour).padStart(2,'0')}:00`,
    endTime:   `${String(hour + 1).padStart(2,'0')}:00`,
    color: '#1A73E8'
  }
  addError.value    = ''
  showAddForm.value = true
}

async function saveNewEvent() {
  if (!newEvent.value.title) {
    addError.value = 'Le titre est requis'
    return
  }
  addLoading.value = true
  addError.value   = ''
  try {
    const start_at = new Date(
      `${selectedSlot.value.date}T${newEvent.value.startTime}`
    ).toISOString()
    const end_at = new Date(
      `${selectedSlot.value.date}T${newEvent.value.endTime}`
    ).toISOString()

    await api.post('/events', {
      title:       newEvent.value.title,
      description: newEvent.value.description,
      location:    newEvent.value.location,
      color:       newEvent.value.color,
      start_at, end_at,
      reminders:   [],
    })

    showAddForm.value = false
    await loadWeekEvents()
  } catch (e) {
    addError.value = 'Erreur lors de la création'
  } finally {
    addLoading.value = false
  }
}

onMounted(loadWeekEvents)
</script>