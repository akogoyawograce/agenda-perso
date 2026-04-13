// backend/src/services/mailer.js
const nodemailer = require('nodemailer');
const PDFDocument = require('pdfkit');

const transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: parseInt(process.env.EMAIL_PORT),
    secure: false,
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

async function generateDailyPDF(user, events) {
    return new Promise((resolve) => {
        const doc = new PDFDocument({ margin: 50 });
        const buffers = [];

        doc.on('data', buffers.push.bind(buffers));
        doc.on('end', () => resolve(Buffer.concat(buffers)));

        // En-tête
        doc.fontSize(20).text('📅 Votre programme du jour', { align: 'center' });
        doc.moveDown();
        doc.fontSize(14).text(`Bonjour ${user.full_name || 'Utilisateur'},`);
        doc.text(`Voici votre agenda du ${new Date().toLocaleDateString('fr-FR')}`);
        doc.moveDown(2);

        if (events.length === 0) {
            doc.fontSize(16).text('🌿 Aucune tâche aujourd’hui. Profitez de votre journée !', { align: 'center' });
        } else {
            doc.fontSize(16).text(`Vous avez ${events.length} événement(s) aujourd’hui :`);
            doc.moveDown();

            events.sort((a, b) => new Date(a.start_at) - new Date(b.start_at));

            events.forEach((event, index) => {
                const start = new Date(event.start_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
                const end = event.end_at
                    ? new Date(event.end_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })
                    : '';

                doc.fontSize(12)
                    .text(`${index + 1}. ${start} ${end ? `- ${end}` : ''} → ${event.title}`);

                if (event.location) doc.text(`   📍 Lieu : ${event.location}`);
                if (event.description) doc.text(`   📝 ${event.description}`);
                doc.moveDown(0.5);
            });
        }

        doc.end();
    });
}

async function sendDailyEmail(user, events) {
    try {
        const pdfBuffer = await generateDailyPDF(user, events);

        await transporter.sendMail({
            from: process.env.EMAIL_FROM,
            to: user.email,
            subject: `📅 Votre programme du ${new Date().toLocaleDateString('fr-FR')}`,
            text: `Bonjour ${user.full_name || ''},\nVoici votre agenda du jour en pièce jointe.`,
            attachments: [{
                filename: `agenda_${new Date().toISOString().split('T')[0]}.pdf`,
                content: pdfBuffer,
                contentType: 'application/pdf'
            }]
        });

        console.log(`✅ Email envoyé à ${user.email}`);
    } catch (error) {
        console.error(`❌ Erreur envoi email à ${user.email}:`, error.message);
    }
}

module.exports = { sendDailyEmail, generateDailyPDF };