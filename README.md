# Tontine App

Application web de gestion de tontines. Elle remplace le cahier et le suivi manuel par un outil partagé : création de groupes, gestion des membres et de l'ordre de passage, suivi des cycles et des cotisations, pénalités de retard, résolution des litiges et journal d'activité. Chaque membre voit qui a cotisé, qui reçoit la cagnotte et quand, pour éviter les erreurs, les oublis et les conflits.

Projet réalisé dans le cadre du cours de Java.

## Technologies

| Élément | Choix |
| --- | --- |
| Langage | Java 25 |
| Framework | Spring Boot 4.1.1 |
| Pages web | Thymeleaf |
| Sécurité | Spring Security |
| Base de données | MySQL 8.4 (via Docker) |
| Accès aux données | Spring Data JPA / Hibernate |
| Migrations de la base | Flyway |
| Build | Maven (via le Maven Wrapper) |

## Prérequis

- **Java 25** : vérifier avec `java -version`. Sinon, installer Eclipse Temurin 25 depuis [adoptium.net](https://adoptium.net).
- **Docker Desktop** : vérifier avec `docker --version`.
- **Git** : vérifier avec `git --version`.

Maven n'a **pas** besoin d'être installé : le projet contient le Maven Wrapper (`mvnw` / `mvnw.cmd`), qui télécharge automatiquement la bonne version au premier lancement.

## Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/VignonCK/tontine-app.git
cd tontine-app
```

### 2. Créer son fichier `.env`

Les mots de passe de la base locale sont stockés dans un fichier `.env`, propre à chaque machine et **jamais envoyé sur GitHub**.

```bash
# Invite de commandes (cmd)
copy .env.example .env

# PowerShell
Copy-Item .env.example .env
```

Ouvrir ensuite `.env` et remplacer les valeurs `CHANGEZ_MOI` par vos propres mots de passe. Utiliser uniquement des lettres et des chiffres, sans `$`, `#`, guillemets ni espaces.

> Les mots de passe sont appliqués **à la création de la base**, au premier lancement de Docker. Les choisir avant l'étape suivante.

### 3. Démarrer la base de données

Lancer **Docker Desktop** et attendre l'indicateur *Engine running*, puis :

```bash
docker compose up -d
```

Le premier lancement télécharge MySQL et peut prendre plusieurs minutes. Pour vérifier que la base est prête :

```bash
docker compose ps
docker compose logs --tail 30 mysql
```

Le conteneur `tontine-mysql` doit être `Up`, et les logs doivent se terminer par `ready for connections`.

## Lancer l'application

```bash
# PowerShell
.\mvnw.cmd spring-boot:run

# Invite de commandes (cmd)
mvnw.cmd spring-boot:run

# Mac / Linux
./mvnw spring-boot:run
```

L'application est prête quand le terminal affiche `Started TontineAppApplication`. Elle est accessible sur **http://localhost:8080**.

Pour l'arrêter : **Ctrl + C** dans le terminal.

### Commandes utiles pour la base

| Action | Commande |
| --- | --- |
| Démarrer la base | `docker compose up -d` |
| Arrêter la base (données conservées) | `docker compose down` |
| Voir l'état | `docker compose ps` |
| Voir les logs | `docker compose logs --tail 30 mysql` |
| Supprimer la base **et toutes ses données** | `docker compose down -v` |

## Structure du projet

```
tontine-app/
├── src/main/java/com/tontine/    Code Java (entity, repository, service, controller)
├── src/main/resources/
│   ├── application.properties    Configuration (sans aucun secret)
│   ├── db/migration/             Scripts Flyway de création de la base
│   ├── templates/                Pages Thymeleaf
│   └── static/                   CSS, images, JavaScript
├── src/test/java/                Tests automatisés
├── docker-compose.yml            Base MySQL locale
├── .env.example                  Modèle du fichier .env
└── pom.xml                       Dépendances Maven
```

## Règles de travail

### Branches

| Branche | Rôle |
| --- | --- |
| `main` | Version stable, utilisée pour les démonstrations. Ne reçoit que du code venant de `dev`. |
| `dev` | Intégration des fonctionnalités terminées. Branche par défaut. |
| `feature/<module>-<nom>` | Développement d'une fonctionnalité. Exemple : `feature/2-inscription`. |

`main` et `dev` sont protégées : on ne peut pas y pousser directement, tout passe par une Pull Request.

### Démarrer une fonctionnalité

```bash
git checkout dev
git pull
git checkout -b feature/<module>-<nom>
```

### Convention de commits

Format : `type: description courte`, en français.

| Type | Utilisation |
| --- | --- |
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `refactor` | Réorganisation du code sans changement de comportement |
| `docs` | Documentation |
| `test` | Ajout ou modification de tests |

### Pull Requests

- Chaque fonctionnalité terminée fait l'objet d'une Pull Request vers `dev`.
- Avant d'ouvrir une PR : l'application démarre sans erreur, aucun mot de passe n'est présent dans le code, et la fonctionnalité a été testée.
- La fusion de `dev` vers `main` se fait ensemble, au point hebdomadaire.

### Règles de sécurité

- Ne **jamais** commiter le fichier `.env` ni aucun mot de passe.
- Ne **jamais** utiliser `git push --force`.

## Problèmes fréquents

| Message | Cause | Solution |
| --- | --- | --- |
| `failed to connect to the docker API` | Docker Desktop n'est pas lancé | Lancer Docker Desktop et attendre *Engine running* |
| `port is already allocated` | Un autre MySQL utilise déjà le port 3306 (WAMP, XAMPP…) | Arrêter l'autre MySQL |
| `Access denied for user 'tontine'` | Mots de passe de `.env` modifiés après la création de la base | `docker compose down -v` puis `docker compose up -d` (**efface les données locales**) |
| `mvnw.cmd n'est pas reconnu` dans PowerShell | Préfixe manquant | Taper `.\mvnw.cmd` |

## Équipe

- GBAGUIDI Emmanuela
- KANLINHANON Vignon 