# Swifty Companion

Application **Flutter** multiplateforme (Android, iOS, macOS, Linux, Windows, Web)
qui se connecte à l'**API de l'école 42** (Intra) via **OAuth2** pour afficher le
profil d'un étudiant, consulter ses projets et ses compétences, rechercher
d'autres étudiants et gérer des créneaux de correction.

> Nom du package Dart : `little_42_companion`

---

## ✨ Fonctionnalités

- **Connexion OAuth2 avec 42** — flux `flutter_web_auth_2` + rafraîchissement
  automatique du token (refresh token) et reprise de session au démarrage.
- **Profil personnel** (`/v2/me`) — niveau & progression, wallet, points de
  correction, campus, emplacement de cluster (pastille en ligne / hors ligne).
- **Compétences** — radar chart des skills du cursus `42cursus`.
- **Projets** — liste filtrable (statut, recherche, « Valides »), dernier projet
  noté, dépliage « voir les N autres ».
- **Recherche d'étudiants** — recherche partielle par login (`search[login]`),
  puis chargement du profil complet au clic.
- **Créneaux de correction** (`/v2/slots`) — création, consultation et
  suppression de créneaux de soutenance.

---

## 🚀 Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK `^3.12.2`).
- Une application enregistrée sur l'Intra 42
  (**Settings → API → Applications**) pour obtenir `CLIENT_ID` et
  `CLIENT_SECRET`, ainsi qu'une **Redirect URI** autorisée.

## 🔧 Installation

```bash
# 1. Récupérer les dépendances
flutter pub get

# 2. Configurer les identifiants 42
cp .env.example .env
# puis éditez .env et renseignez CLIENT_ID / CLIENT_SECRET

# 3. Lancer (choisir la plateforme)
flutter run                # appareil/émulateur par défaut
flutter run -d chrome      # web
flutter run -d macos       # desktop macOS
```

Le fichier `.env` est **ignoré par git** (voir `.gitignore`) et chargé au
démarrage via `flutter_dotenv`. Il ne doit **jamais** être commité.

### Configuration OAuth

| Plateforme | Redirect URI attendue                              |
| ---------- | -------------------------------------------------- |
| Web        | `<origine>/auth.html` (défaut : `${Uri.base.origin}/auth.html`) |
| Mobile/desktop | `mycompanion://oauth-callback` (schéma d'URL personnalisé) |

Pensez à déclarer la même **Redirect URI** dans les réglages de votre
application Intra 42.

---

## 🧱 Architecture

```
lib/
├── main.dart                  # Point d'entrée, chargement .env + session
├── auth_service.dart          # OAuth2, tokens, appels API 42, retry (401/429/5xx)
├── login.dart                 # Écran de connexion « Se connecter avec 42 »
├── home.dart                  # Navigation par onglets (Profil / Recherche / Créneaux)
├── theme.dart                 # Design system : AppColors, AppText, AppTheme
├── models/
│   ├── user_profile.dart      # UserProfile, ProjectItem, UserCandidate
│   └── correction_models.dart # CorrectionSlot
└── widgets/
    ├── profile_tab.dart
    ├── profile_card.dart
    ├── projects_card.dart
    ├── skills_radar_chart.dart
    ├── search_tab.dart
    ├── slots_tab.dart
    └── slot_proposal_dialog.dart
```

**Dépendances principales**

| Paquet                  | Rôle                                        |
| ----------------------- | ------------------------------------------- |
| `http`                  | Appels à l'API Intra 42                     |
| `flutter_web_auth_2`    | Flux OAuth2 (ouverture du navigateur)       |
| `shared_preferences`    | Persistance locale des tokens & préférences |
| `flutter_dotenv`        | Chargement des identifiants depuis `.env`   |

---

## 🧪 Tests & qualité

```bash
flutter analyze     # Analyse statique (lints flutter_lints)
flutter test        # Tests unitaires & widgets
```

Le projet vise **zéro warning** à l'analyse et une couverture de tests sur les
modèles et les widgets clés (profil, recherche, radar de compétences, physique
de défilement des créneaux).

---

## 📝 Notes

- Le fichier `DEADLINES.md` documente le *Pace System* de 42 et sert de
  référence pour d'éventuels calculs de deadlines.

