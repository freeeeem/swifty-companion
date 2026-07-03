# Guide de démarrage — Swifty Companion (Flutter & Dart)

Ce guide décrit la marche à suivre pour démarrer le projet Swifty Companion directement sur les postes de l'école (où Flutter et les IDE sont déjà préinstallés).

---

## 🚀 1. Étape par étape : Premier démarrage à 42

### Étape 1 : Créer le projet dans votre dossier de travail
Ouvrez le terminal dans votre dossier de projet `swifty-companion` et initialisez l'application (le point `.` indique le dossier actuel) :
```bash
flutter create --org com.fortytwo --project-name swifty_companion .
```
*(Cela va générer toute l'arborescence nécessaire : dossiers iOS, Android, web, macos, et le fichier source principal `lib/main.dart`).*

### Étape 2 : Ouvrir l'IDE
Ouvrez **VS Code** ou **Android Studio** et chargez le dossier `swifty-companion`. Assurez-vous que les extensions **Flutter** et **Dart** sont bien activées.

### Étape 3 : Lancer l'application de démonstration (Le Compteur)
Pour vérifier que l'environnement de l'école est 100 % opérationnel :
1. Lancez un simulateur (iOS ou Android) ou préparez un onglet Google Chrome.
2. Lancez l'exécution depuis votre IDE (touche `F5` sur VS Code ou via le bouton "Run"), ou tapez dans le terminal :
   ```bash
   flutter run -d chrome
   ```
3. L'application par défaut (un compteur interactif) doit s'afficher à l'écran.

### Étape 4 : Tester le "Hot Reload"
1. Ouvrez le fichier `lib/main.dart`.
2. Modifiez une ligne de texte (par exemple, le titre de l'application) ou changez la couleur du thème.
3. Sauvegardez le fichier (`Cmd + S` ou `Ctrl + S`).
4. Constatez que la modification apparaît instantanément sur votre écran de test sans recompiler l'application.

---

## 🌐 2. Connexion à l'API 42 (REST & OAuth2)

L'API de 42 utilise le protocole d'authentification **OAuth2**.

### Étape 1 : Créer votre application sur l'Intra
1. Allez sur votre profil Intra 42 -> **Settings** -> **Applications** -> **New Application**.
2. Remplissez le formulaire de création (le Redirect URI peut être `http://localhost`).
3. Notez votre **UID** (Client ID) et votre **SECRET** (Client Secret).

### Étape 2 : Récupérer le Token d'accès (OAuth2 Client Credentials)
Pour interroger l'API pour un utilisateur, vous devez d'abord faire une requête `POST` pour obtenir un token d'accès temporaire :
* **URL** : `https://api.intra.42.fr/oauth/token`
* **Méthode** : `POST`
* **Body (form-data ou JSON)** :
  ```json
  {
    "grant_type": "client_credentials",
    "client_id": "VOTRE_UID",
    "client_secret": "VOTRE_SECRET"
  }
  ```
* **Réponse** : Vous recevrez un JSON contenant `"access_token": "gprd_..."`.

### Étape 3 : Récupérer les données d'un étudiant
Une fois le token obtenu, ajoutez-le dans le header de vos requêtes GET pour interroger l'API :
* **URL** : `https://api.intra.42.fr/v2/users/LOGIN_DE_L_ETUDIANT`
* **Méthode** : `GET`
* **Headers** :
  ```http
  Authorization: Bearer VOTRE_ACCESS_TOKEN
  ```

---

## 📚 3. Liens & Documentation de référence

### Apprendre Flutter & Dart
* 🔗 **[Codelab : Votre première application Flutter](https://codelabs.developers.google.com/codelabs/flutter-codelab-first)** : Le guide interactif recommandé pour comprendre le fonctionnement des Widgets, des layouts, et de la gestion d'état simple.
* 🔗 **[Dart Language Tour](https://dart.dev/language)** : Indispensable pour comprendre la syntaxe de Dart (variables, typage, programmation asynchrone avec `Future`, `async` et `await`).

### Développement réseau et UI
* 🔗 **[Codelab : Récupérer des données depuis Internet](https://docs.flutter.dev/cookbook/networking/fetch-data)** : Guide officiel pour faire des requêtes HTTP en Dart.
* 🔗 **[Package http sur pub.dev](https://pub.dev/packages/http)** : La bibliothèque HTTP standard pour Dart.
* 🔗 **[Package percent_indicator sur pub.dev](https://pub.dev/packages/flutter_percent_indicator)** : Très utile pour afficher le niveau et les compétences sous forme de barres ou de cercles de progression.
* 🔗 **[Documentation de l'API 42](https://api.intra.42.fr/apidoc)** : La doc officielle pour comprendre les endpoints (comme `/v2/users/:login`).
