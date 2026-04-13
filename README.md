# Agenda Perso

Une application complète de gestion d'agenda personnel comprenant un Backend (API), et deux interfaces utilisateur : un Frontend Web (Vue.js) et une application Mobile (Flutter).

## Structure du Projet

- `backend/` : API REST en Node.js fournissant les données et la logique métier.
- `frontend/` : Application Web développée avec Vue 3 et Vite.
- `mobile/` : Application Mobile cross-platform développée en Flutter.

---

## 🚀 Backend

L'API est construite avec **Node.js** et **Express**, intégrant **Supabase** pour la base de données et l'authentification.

### Technologies Principales
- **Framework** : Node.js, Express.js
- **Base de données & Auth** : Supabase
- **Validation** : Zod
- **Tâches planifiées** : Node-cron
- **Notifications** : OneSignal
- **Email & PDF** : Nodemailer, PDFKit

### Installation & Lancement
```bash
cd backend
npm install
npm start
# ou pour le développement
npm run dev
```
*(Assurez-vous de configurer les variables d'environnement nécessaires dans un fichier `.env`)*

---

## 💻 Frontend (Web)

Une interface d'administration ou un client web développé avec les dernières technologies **Vue.js**.

### Technologies Principales
- **Framework** : Vue 3 (Composition API), Vite
- **Gestion d'état** : Pinia
- **Routage** : Vue Router
- **Style** : Tailwind CSS
- **Requêtes HTTP** : Axios
- **Utilitaires** : jsPDF, xlsx (Exportation de données), Day.js

### Installation & Lancement
```bash
cd frontend
npm install
npm run dev
```
*(L'application sera accessible sur le port proposé par Vite)*

---

## 📱 Application Mobile

Application mobile pour iOS et Android conçue avec **Flutter**, offrant la consultation, les notifications et l'exportation de données hors connexion.

### Technologies Principales
- **Framework** : Flutter
- **Architecture & État** : Riverpod, GoRouter
- **Requêtes HTTP** : Dio
- **Stockage Local** : Hive, Flutter Secure Storage
- **Notifications** : OneSignal Flutter, Flutter Local Notifications
- **Composants Pro** : Table Calendar
- **Utilitaires** : PDF, Printing, Excel, Share Plus

### Installation & Lancement
```bash
cd mobile
flutter pub get
flutter run
```

---

## 🔒 Sécurité et Fonctionnalités

- **Authentification** : Gestion des utilisateurs centralisée.
- **Notifications Push** : Alertes push via OneSignal (Mobile & Web).
- **Exports multi-formats** : Génération de PDF et Fichiers Excel depuis le Web et le Mobile.
- **Stockage Sécurisé** : Persistance sécurisée des données de l'utilisateur.

---
*Ce projet est une solution complète (Full-Stack) visant à offrir une expérience fluide pour la gestion de l'emploi du temps et des tâches personnelles.*
