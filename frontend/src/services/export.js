import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'
import * as XLSX from 'xlsx'
import { saveAs } from 'file-saver'
import dayjs from 'dayjs'
import 'dayjs/locale/fr'
dayjs.locale('fr')

// ── Formatage des données ─────────────────────────────────────────────────
function formatEvents(events) {
    return events.map(e => ({
        titre: e.title,
        date: dayjs(e.start_at).format('DD/MM/YYYY'),
        heure_debut: dayjs(e.start_at).format('HH:mm'),
        heure_fin: e.end_at ? dayjs(e.end_at).format('HH:mm') : '-',
        lieu: e.location || '-',
        description: e.description || '-',
        categorie: e.categories?.name || '-',
        recurrence: e.recurrence === 'none' ? '-' : e.recurrence,
    }))
}

// ── Export PDF ────────────────────────────────────────────────────────────
export function exportPDF(events, title = 'Mon Agenda') {
    const doc = new jsPDF()
    const data = formatEvents(events)

    // En-tête
    doc.setFontSize(20)
    doc.setTextColor(26, 115, 232)
    doc.text(title, 14, 20)
    doc.setFontSize(10)
    doc.setTextColor(100)
    doc.text(`Exporté le ${dayjs().format('DD MMMM YYYY à HH:mm')}`, 14, 28)
    doc.text(`${events.length} événement(s)`, 14, 34)

    // Tableau
    autoTable(doc, {
        startY: 40,
        head: [['Titre', 'Date', 'Début', 'Fin', 'Lieu', 'Description']],
        body: data.map(e => [
            e.titre, e.date, e.heure_debut,
            e.heure_fin, e.lieu, e.description
        ]),
        headStyles: {
            fillColor: [26, 115, 232],
            textColor: 255,
            fontStyle: 'bold',
        },
        alternateRowStyles: {
            fillColor: [240, 244, 255],
        },
        styles: { fontSize: 9, cellPadding: 4 },
        columnStyles: {
            0: { cellWidth: 35 },
            5: { cellWidth: 50 },
        },
    })

    // Pied de page
    const pageCount = doc.internal.getNumberOfPages()
    for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i)
        doc.setFontSize(8)
        doc.setTextColor(150)
        doc.text(
            `Page ${i} / ${pageCount} — Agenda Personnel`,
            doc.internal.pageSize.width / 2, doc.internal.pageSize.height - 10,
            { align: 'center' }
        )
    }

    doc.save(`agenda-${dayjs().format('YYYY-MM-DD')}.pdf`)
}

// ── Export PDF Emploi du temps (vue semaine) ──────────────────────────────
export function exportEmploiDuTempsPDF(events, weekStart) {
    const doc = new jsPDF({ orientation: 'landscape' })

    const start = dayjs(weekStart).startOf('week')
    const days = Array.from({ length: 7 }, (_, i) => start.add(i, 'day'))

    doc.setFontSize(16)
    doc.setTextColor(26, 115, 232)
    doc.text('Emploi du temps — Semaine du ' +
        start.format('D MMMM YYYY'), 14, 15)

    const hours = Array.from({ length: 14 }, (_, i) => `${i + 7}h00`)

    const body = hours.map(hour => {
        const h = parseInt(hour)
        return [
            hour,
            ...days.map(day => {
                const dayEvents = events.filter(e => {
                    const d = dayjs(e.start_at)
                    return d.isSame(day, 'day') && d.hour() === h
                })
                return dayEvents.map(e => e.title).join('\n') || ''
            })
        ]
    })

    autoTable(doc, {
        startY: 22,
        head: [['Heure', ...days.map(d => d.format('ddd D/MM'))]],
        body,
        headStyles: {
            fillColor: [26, 115, 232],
            textColor: 255,
            fontStyle: 'bold',
            halign: 'center',
        },
        styles: { fontSize: 8, cellPadding: 3, halign: 'center' },
        columnStyles: { 0: { cellWidth: 15, fontStyle: 'bold' } },
        alternateRowStyles: { fillColor: [248, 250, 255] },
    })

    doc.save(`emploi-du-temps-${start.format('YYYY-MM-DD')}.pdf`)
}

// ── Export Excel ──────────────────────────────────────────────────────────
export function exportExcel(events, title = 'Mon Agenda') {
    const data = formatEvents(events)

    const wsData = [
        ['Titre', 'Date', 'Heure début', 'Heure fin', 'Lieu', 'Description', 'Catégorie', 'Récurrence'],
        ...data.map(e => [
            e.titre, e.date, e.heure_debut,
            e.heure_fin, e.lieu, e.description,
            e.categorie, e.recurrence
        ])
    ]

    const ws = XLSX.utils.aoa_to_sheet(wsData)

    // Style en-tête (largeurs colonnes)
    ws['!cols'] = [
        { wch: 30 }, { wch: 12 }, { wch: 12 },
        { wch: 12 }, { wch: 20 }, { wch: 40 },
        { wch: 15 }, { wch: 12 },
    ]

    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'Événements')

    // Onglet stats
    const statsData = [
        ['Statistiques', ''],
        ['Total événements', events.length],
        ['Exporté le', dayjs().format('DD/MM/YYYY HH:mm')],
        ['Période', `${dayjs(events[0]?.start_at).format('DD/MM/YYYY')} → ${dayjs(events[events.length - 1]?.start_at).format('DD/MM/YYYY')}`],
    ]
    const wsStats = XLSX.utils.aoa_to_sheet(statsData)
    XLSX.utils.book_append_sheet(wb, wsStats, 'Statistiques')

    XLSX.writeFile(wb, `agenda-${dayjs().format('YYYY-MM-DD')}.xlsx`)
}

// ── Export CSV ────────────────────────────────────────────────────────────
export function exportCSV(events) {
    const data = formatEvents(events)
    const headers = 'Titre,Date,Heure début,Heure fin,Lieu,Description,Catégorie\n'
    const rows = data.map(e =>
        `"${e.titre}","${e.date}","${e.heure_debut}","${e.heure_fin}","${e.lieu}","${e.description}","${e.categorie}"`
    ).join('\n')

    const blob = new Blob(['\ufeff' + headers + rows],
        { type: 'text/csv;charset=utf-8;' })
    saveAs(blob, `agenda-${dayjs().format('YYYY-MM-DD')}.csv`)
}