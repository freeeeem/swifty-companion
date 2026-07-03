# Swifty Companion

Swifty Companion est un projet de l'école 42 consistant à développer une application mobile permettant de rechercher et d'afficher le profil détaillé de n'importe quel étudiant de 42 en interrogeant l'API officielle.

Cette version du projet est développée avec **Flutter & Dart**.

---

## 📱 Fonctionnalités à implémenter

* 🔍 **Recherche** : Recherche d'un étudiant par son login.
* 👤 **Profil détaillé** : Affichage de la photo, du nom, du courriel, du téléphone, de la localisation, du nombre de points de correction et du wallet.
* 📊 **Compétences (Skills)** : Liste des compétences de l'étudiant avec barres de progression visuelles.
* 📁 **Projets** : Historique des projets terminés, en cours ou échoués avec leur note finale.
* 🔐 **Authentification** : Gestion sécurisée des tokens via l'API 42 (OAuth2).

---

## 🚀 Démarrage rapide

Toutes les étapes pas-à-pas pour démarrer votre environnement à l'école et lancer l'application se trouvent dans le fichier :
* 🔗 **[RESOURCES.md](file:///Users/livio/Desktop/42/Outercore/swifty-companion/RESOURCES.md)**

### Commandes principales :

1. **Initialiser le projet** :
   ```bash
   flutter create --org com.fortytwo --project-name swifty_companion .
   ```
2. **Lancer en mode développement** (sur Google Chrome) :
   ```bash
   flutter run -d chrome
   ```

---

## 🛠️ Technologies utilisées

* **Framework** : [Flutter](https://flutter.dev)
* **Langage** : [Dart](https://dart.dev)
* **API externe** : [API 42 (v2)](https://api.intra.42.fr/apidoc)