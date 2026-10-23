# Cahier des charges détaillé

## Application de Gestion de Tontine

*Version 2.0 — 8 octobre 2026 — Projet dédié, groupe de 2 étudiants*

Ce document est le cahier des charges complet et détaillé de l'application de gestion de tontine. Chaque fonctionnalité est décrite avec ses règles de gestion précises et organisée par module, avec un niveau de priorité (Essentielle / Importante / Optionnelle-avancée). Il guide le développement fonctionnalité par fonctionnalité.

> [!IMPORTANT]
> **Écarts techniques actés depuis la v2.0** (le README fait foi en cas de différence) :
> - Java **25** (au lieu de 21), Spring Boot **4.1.1**, MySQL **8.4** (au lieu de 8.0).
> - Mots de passe locaux dans le fichier **`.env`**, lu par Docker Compose et par Spring (`spring.config.import`), au lieu de `application-local.properties` (section 5.5.5).
> - Pas de tableau Kanban : l'avancement est suivi dans `PROGRESS.md`.
> - Fusion des Pull Requests sans approbation obligatoire ; la fusion `dev` → `main` se fait ensemble au point hebdomadaire.
> - Le calendrier de la section 7.3 est décalé (Vague 0 terminée mi-octobre 2026).
> - Le principe « l'application ne fait jamais transiter l'argent » (section 1.2) est en cours de réexamen.

## Historique des versions

| **Version** | **Date** | **Changements** |
| --- | --- | --- |
| 1.0 | Juillet 2026 | Version initiale. |
| 2.0 | 8 octobre 2026 | Renvois entre modules corrigés ; règles de gestion contradictoires résolues ; ajout des membres gérés sans compte, de la récupération de compte, de la remise de cagnotte et des sorties de membres ; nouvelle entité Echeance ; section technique (5.5) ; calendrier recalculé pour 2 développeurs à partir du 12 octobre 2026. |

> [!NOTE] Ce qui change dans la version 2.0
> Les corrections sont signalées dans le texte par la mention **[v2]**, pour que chaque membre de l'équipe repère rapidement ce qui a bougé.

| **Sujet** | **Avant (v1)** | **Maintenant (v2)** |
| --- | --- | --- |
| Démarrage des cycles | Un cycle ne démarre que si le précédent est clôturé : un seul mauvais payeur bloque toute la tontine. | Les cycles s'ouvrent selon le calendrier. La clôture est une opération comptable séparée, et les impayés deviennent des dettes reportées. |
| Nombre de cycles | Fixe, mais modifié par les retraits : contradiction. | Égal aux membres actifs au démarrage, moins les membres sortis avant leur tour. |
| Membre déjà bénéficiaire qui part | Non traité. | Retrait impossible tant qu'il doit des échéances ; en cas d'exclusion, la dette reste visible et documentée. |
| Bénéficiaire non à jour | « Ne peut pas recevoir », sans suite prévue. | Contrôle 3 jours avant son tour, puis trois issues possibles : compensation, dérogation motivée ou permutation. |
| Remise de la cagnotte | Non tracée. | Enregistrée (entité Versement) et confirmée par le bénéficiaire. |
| Montant attendu d'un cycle | Ambigu (le bénéficiaire cotise-t-il ?). | Somme des échéances du cycle ; tous les membres cotisent, bénéficiaire compris. |
| Retards et pénalités | Pénalité liée à une cotisation, qui n'existe justement pas en cas de retard. | Nouvelle entité Echeance (ce que chaque membre doit pour chaque cycle) ; pénalités et litiges s'y rattachent. |
| Membres sans compte | Impossible : seuls les utilisateurs inscrits peuvent être invités. | Membre géré par l'organisateur, rattachable plus tard à un compte. |
| Mot de passe oublié | Non prévu. | Lien par e-mail ou code à usage unique généré par un organisateur. |
| Paramètres après démarrage | Modifiables « avec accord de tous », sans mécanisme prévu. | Figés ; pour changer, on relance un nouveau tour. |
| Aspects techniques | Absents. | Section 5.5 : sécurité par groupe, tâches planifiées, transactions, migrations, tests, fichiers. |
| Renvois entre modules | Plusieurs numéros erronés. | Corrigés. |

## Sommaire des modules

| **N°** | **Module** | **Priorité** |
| --- | --- | --- |
| 1 | Page d'accueil et navigation générale | Essentielle |
| 2 | Comptes, identité et rôles | Essentielle |
| 3 | Création et paramétrage des groupes de tontine | Essentielle |
| 4 | Adhésion et gestion des membres | Essentielle |
| 5 | Cycles, ordre de passage et remise de la cagnotte | Essentielle |
| 6 | Cotisations et paiements | Essentielle |
| 7 | Pénalités et gestion des retards | Importante |
| 8 | Tableau de bord et suivi | Essentielle |
| 9 | Notifications et rappels | Importante |
| 10 | Permutation et échange de tours | Importante |
| 11 | Litiges et contestations | Importante |
| 12 | Rapports, relevés et exports | Importante |
| 13 | Journal d'activité et traçabilité | Importante |
| 14 | Messagerie interne au groupe | Optionnelle |
| 15 | Simulateur de tontine | Optionnelle |
| 16 | Intégration Mobile Money | Optionnelle / avancée |
| 17 | Caisse de solidarité (variante) | Optionnelle / avancée |

## 1. Présentation générale du projet

### 1.1 Contexte

La tontine est un système d'épargne collective informelle très répandu au Bénin et en Afrique de l'Ouest. Un groupe de personnes cotise régulièrement un montant fixe et, à chaque cycle, un membre différent reçoit l'intégralité de la cagnotte selon un ordre de passage convenu à l'avance. Ce système repose sur la confiance entre membres et sur un suivi manuel (cahier, mémoire, messages informels). Il en résulte des erreurs de calcul, des oublis de paiement, des conflits sur qui a payé ou non, et une absence totale de traçabilité en cas de désaccord.

### 1.2 Objectif du projet

Développer une application web qui digitalise la gestion d'une ou plusieurs tontines : création du groupe, gestion des membres et de l'ordre de passage, suivi des cotisations et des cycles, calcul automatique du bénéficiaire, gestion des retards et pénalités, traçabilité des remises de cagnotte et résolution formelle des litiges. L'objectif est une visibilité complète et partagée sur l'état du groupe, pour restaurer la confiance et réduire les erreurs humaines.

L'application **ne fait jamais transiter l'argent** : les membres continuent de cotiser en espèces ou en Mobile Money entre eux, et l'application sert de registre fiable et d'outil d'arbitrage.

### 1.3 Public cible

- Organisateurs de tontines familiales, associatives ou entre collègues souhaitant un suivi fiable.
- Membres de tontines souhaitant consulter leur historique et leur situation sans dépendre uniquement de l'organisateur.
- Groupes de taille petite à moyenne (5 à 30 membres), le cas d'usage le plus courant au Bénin.
- **[v2]** Groupes dont certains membres n'ont pas de smartphone ou ne souhaitent pas créer de compte : l'organisateur les gère pour eux (membres gérés, module 4).

### 1.4 Périmètre du document

Ce cahier des charges couvre l'ensemble des fonctionnalités envisagées, classées par priorité. L'équipe de deux développeurs avance fonctionnalité par fonctionnalité en respectant l'ordre de dépendance technique (section 7). Les modules optionnels ne sont développés que si le temps le permet : l'essentiel est la solidité des modules essentiels et importants.

## 2. Acteurs et rôles du système

| **Rôle** | **Description** | **Permissions principales** |
| --- | --- | --- |
| Organisateur | Créateur d'un groupe de tontine. Un même utilisateur peut être organisateur de plusieurs groupes. | Créer, modifier et clôturer un groupe ; valider les adhésions ; définir l'ordre de passage ; enregistrer et valider les cotisations ; enregistrer la remise de la cagnotte ; gérer les pénalités ; résoudre les litiges ; gérer les membres sans compte ; générer un code de réinitialisation pour un membre. |
| Co-organisateur | Membre désigné par l'organisateur pour partager la gestion d'un groupe. | Mêmes permissions que l'organisateur sur le groupe, sauf suppression du groupe et désignation des rôles. Arbitre les litiges dans lesquels l'organisateur est partie. |
| Trésorier (optionnel) | Membre désigné responsable de la validation des paiements, distinct de l'organisateur si le groupe le souhaite. | Enregistrer et valider les cotisations ; enregistrer la remise de la cagnotte. |
| Membre | Participant simple d'un groupe, disposant d'un compte. | Consulter le groupe, son historique et ses échéances ; déclarer un paiement (si le groupe l'autorise) ; confirmer la réception de la cagnotte ; demander une permutation ; ouvrir un litige. |
| **[v2]** Membre géré | Participant sans compte, créé et géré par l'organisateur. | Aucun accès à l'application. Ses paiements et remises sont enregistrés par l'organisateur ou le trésorier. Il peut être rattaché plus tard à un compte. |
| Administrateur système (hors périmètre MVP) | Rôle technique de supervision globale, distinct de la gestion d'un groupe. | Supervision technique, gestion des comptes en cas de problème. |

**[v2] Règles de gestion des rôles**

- Un rôle est toujours relatif à un groupe précis, jamais global à l'application.
- Tout groupe actif a exactement un organisateur. Celui-ci peut transférer son rôle à un autre membre disposant d'un compte, ce transfert étant journalisé.
- Un membre géré ne peut avoir que le rôle Membre.

## 3. Modules fonctionnels détaillés

### Module 1 — Page d'accueil et navigation générale

**Priorité : Essentielle**

*Offrir un point d'entrée clair : pour un visiteur qui découvre le concept, comme pour un utilisateur connecté qui doit accéder immédiatement à l'essentiel.*

#### Fonctionnalités détaillées

- **Page d'accueil publique (visiteur non connecté)**
  - Présentation courte du principe : gérer une tontine sans cahier ni calcul manuel, et sans que l'application ne touche à l'argent.
  - Explication simplifiée en quelques étapes (créer un groupe, ajouter des membres, suivre les cotisations).
  - Boutons « Créer un compte » et « Se connecter », visibles sans faire défiler la page.
  - Aperçu visuel simple du tableau de bord, pour donner confiance avant l'inscription.
- **Redirection après connexion**
  - Une fois connecté, l'utilisateur est redirigé vers son tableau de bord multi-groupes (module 8), jamais vers la page publique.
  - Un utilisateur non connecté qui tente d'accéder à une page protégée est redirigé vers la connexion, puis vers la page demandée.
- **Navigation commune**
  - Menu principal sur toutes les pages une fois connecté : groupes, notifications, profil, déconnexion.
  - Fil d'Ariane ou titre de page indiquant toujours le groupe et la section en cours.
- **[v2] Pages d'erreur**
  - Pages en français pour « accès refusé », « page introuvable » et « erreur inattendue », avec un lien de retour au tableau de bord. Aucun message technique brut.

#### Règles de gestion

- La page publique n'affiche jamais de donnée réelle d'un groupe ou d'un utilisateur.
- La redirection post-connexion est systématique.

### Module 2 — Comptes, identité et rôles

**Priorité : Essentielle**

*Permettre à chaque utilisateur de créer un compte sécurisé, de le récupérer en cas d'oubli, et de recevoir les rôles adéquats dans chaque groupe.*

#### Fonctionnalités détaillées

- **Inscription**
  - Formulaire : nom, prénom, numéro de téléphone (identifiant principal), mot de passe, e-mail (optionnel).
  - **[v2]** Vérification du format béninois : depuis la migration de fin 2024, les numéros comptent 10 chiffres commençant par 01 (+229 01 XX XX XX XX). Le numéro est enregistré sous une forme normalisée unique (ex. : +2290197000000). Format à confirmer par l'équipe en Vague 0.
  - Mot de passe haché (BCrypt), jamais stocké en clair ; longueur minimale de 8 caractères.
  - **[v2]** Si un membre géré existe déjà avec ce numéro dans un ou plusieurs groupes, l'utilisateur est informé après inscription et peut demander le rattachement (voir module 4).
- **Connexion et session**
  - Connexion par numéro de téléphone et mot de passe.
  - Session sécurisée (Spring Security), déconnexion explicite.
  - Message d'erreur générique en cas d'échec, sans révéler si le numéro ou le mot de passe est erroné.
  - **[v2]** Après 5 échecs consécutifs, la connexion à ce compte est suspendue 15 minutes.
- **[v2] Récupération du compte (mot de passe oublié)**
  - Si l'utilisateur a renseigné un e-mail et que l'envoi d'e-mails est configuré : lien de réinitialisation valable 1 heure.
  - Sinon, réinitialisation assistée : un organisateur d'un groupe dont l'utilisateur est membre génère un code à usage unique valable 24 heures, qu'il transmet en main propre ou par message. L'utilisateur saisit son numéro, le code, puis choisit un nouveau mot de passe.
  - L'organisateur ne voit et ne choisit jamais le mot de passe : il ne transmet qu'un code temporaire.
- **Gestion du profil**
  - Modification du nom, du téléphone (avec vérification d'unicité) et du mot de passe (ancien mot de passe exigé).
  - Liste des groupes de l'utilisateur, avec son rôle dans chacun.
- **Attribution des rôles**
  - L'organisateur désigne co-organisateur et trésorier parmi les membres disposant d'un compte.
  - Un même utilisateur peut être organisateur d'un groupe et simple membre d'un autre.

#### Règles de gestion

- Un numéro de téléphone (forme normalisée) ne peut être associé qu'à un seul compte.
- La suppression d'un compte n'est autorisée que si l'utilisateur n'est organisateur d'aucun groupe actif et n'a aucune échéance due. **[v2]** Ses données financières passées sont conservées et anonymisées (nom remplacé par « Ancien membre »), jamais supprimées.
- **[v2]** Un code de réinitialisation est stocké haché, utilisable une seule fois, et limité à 3 codes par compte et par 24 heures. Chaque génération est journalisée (module 13) et signalée à l'utilisateur à sa prochaine connexion.

### Module 3 — Création et paramétrage des groupes de tontine

**Priorité : Essentielle**

*Permettre à un organisateur de définir précisément les règles d'un groupe avant d'y ajouter des membres.*

#### Fonctionnalités détaillées

- **Création d'un groupe**
  - Nom, description libre.
  - Montant de la cotisation en FCFA (nombre entier), identique pour tous les membres.
  - Fréquence : journalière, hebdomadaire ou mensuelle.
  - Date de démarrage du premier cycle (aujourd'hui ou plus tard).
  - Nombre maximal de membres (optionnel).
  - **[v2]** Un code d'invitation unique est généré automatiquement (module 4).
- **Règlement interne du groupe**
  - Texte libre décrivant les règles convenues entre membres (absences, seuil d'exclusion, restitution en cas de départ…).
  - Activation ou non des pénalités de retard, avec leur configuration (module 7).
  - Activation ou non de la permutation de tours (module 10).
  - **[v2]** Autorisation ou non, pour les membres, de déclarer eux-mêmes leurs paiements (module 6).
- **Démarrage du groupe**
  - **[v2]** Action explicite « Démarrer la tontine » par l'organisateur, qui fige les paramètres et génère tous les cycles et toutes les échéances (module 5).
- **Modification et clôture**
  - Les paramètres sont modifiables tant que le groupe n'a pas démarré (statut Brouillon).
  - Un groupe en brouillon peut être supprimé. Un groupe démarré ne peut plus être supprimé, seulement clôturé.
  - Clôture du groupe une fois tous les cycles clôturés, avec archivage consultable.
  - **[v2]** « Relancer un nouveau tour » : crée un nouveau groupe en brouillon pré-rempli avec les paramètres et les membres actifs du groupe terminé, à ajuster avant démarrage.

#### Règles de gestion

- **[v2]** Après démarrage, le montant, la fréquence, la date de démarrage et l'ordre de passage sont figés (seule exception : la permutation, module 10). Pour changer ces paramètres, le groupe termine son tour et l'organisateur en relance un nouveau. Cette règle remplace « sauf accord explicite de tous les membres », qui n'avait pas de mécanisme pour être appliquée.
- **[v2]** Le règlement interne reste modifiable après démarrage. Chaque modification est journalisée et notifiée à tous les membres.
- Le démarrage n'est possible que si au moins 3 membres sont actifs et que l'ordre de passage est complet.

### Module 4 — Adhésion et gestion des membres

**Priorité : Essentielle**

*Encadrer l'entrée, la sortie et l'organisation des membres, avec un vrai processus de validation et des règles claires pour les départs.*

#### Fonctionnalités détaillées

- **Invitation et demande d'adhésion**
  - L'organisateur invite un utilisateur existant par son numéro de téléphone.
  - Un utilisateur peut demander à rejoindre un groupe grâce au code d'invitation ; la demande est soumise à validation.
  - L'organisateur accepte ou refuse chaque demande.
- **[v2] Membres gérés (sans compte)**
  - L'organisateur ajoute un membre avec un nom et, de préférence, un numéro de téléphone.
  - Si une personne crée plus tard un compte avec ce numéro, elle peut demander le rattachement. Après acceptation par l'organisateur, l'adhésion est liée à son compte et tout l'historique est conservé.
- **Définition de l'ordre de passage**
  - Mode manuel : l'organisateur classe les membres.
  - Mode aléatoire : tirage au sort automatique, avec résultat affiché à tous les membres et journalisé.
  - L'ordre est figé au démarrage, sauf via la permutation (module 10).
- **[v2] Départ d'un membre avant d'avoir été bénéficiaire**
  - Un membre peut demander son retrait ; l'organisateur valide et documente le motif.
  - Ses échéances des cycles non encore ouverts sont annulées. Son cycle de bénéficiaire est supprimé, les cycles planifiés suivants sont renumérotés et avancés d'une période, et les échéances de tous les membres pour le cycle supprimé sont annulées.
  - Le montant de ses cotisations déjà versées est calculé et affiché comme « à restituer ». La restitution effective, selon le règlement interne, est enregistrée par l'organisateur (Versement de type Restitution, module 5).
- **[v2] Départ d'un membre après avoir été bénéficiaire**
  - Le retrait volontaire est impossible tant qu'il reste des échéances dues : il a reçu la cagnotte et reste redevable jusqu'à la fin du tour.
  - En cas de non-paiement répété (seuil défini dans le règlement interne), l'organisateur peut l'exclure, avec motif obligatoire. Ses échéances restantes **ne sont pas annulées** : elles restent dues, visibles de tous les membres et figurent dans son relevé (module 12), utilisable comme preuve.
  - L'application documente la dette mais ne peut pas la recouvrer. Les cycles suivants sont collectés sur les échéances effectivement payées, et le manque est visible sur chaque carte de cycle.
- **Exclusion d'un membre n'ayant pas encore bénéficié**
  - Même effet qu'un retrait (voir plus haut), avec motif obligatoire journalisé.

#### Règles de gestion

- **[v2]** Les adhésions sont closes au démarrage : aucun nouveau membre ne peut rejoindre un groupe démarré. Il rejoindra le tour suivant.
- **[v2]** Le nombre de cycles est égal au nombre de membres actifs au démarrage, diminué d'une unité pour chaque membre sorti avant d'avoir été bénéficiaire. Un membre sorti après avoir bénéficié ne change pas le nombre de cycles.
- La règle sur le bénéficiaire non à jour est désormais traitée au module 5.

### Module 5 — Cycles, ordre de passage et remise de la cagnotte

**Priorité : Essentielle**

*Automatiser la création et le suivi des cycles, et tracer la remise effective de la cagnotte, moment où la confiance est la plus fragile.*

#### Fonctionnalités détaillées

- **[v2] Génération du calendrier au démarrage**
  - Au démarrage, tous les cycles sont créés (statut Planifié), chacun avec son bénéficiaire selon l'ordre de passage (module 4), sa date de début et sa date de fin.
  - Calcul des dates : cycle n = date de démarrage + (n − 1) périodes. En fréquence mensuelle, on garde le même jour du mois, ramené au dernier jour pour les mois plus courts.
  - Pour chaque cycle, une échéance est créée pour chaque membre actif, y compris le bénéficiaire : montant dû = montant de cotisation, date limite = date de fin du cycle.
- **[v2] Ouverture automatique des cycles**
  - Chaque cycle passe En cours à sa date de début, par une tâche planifiée quotidienne, **indépendamment de la clôture du cycle précédent**.
- **Calcul et affichage du bénéficiaire**
  - Le bénéficiaire de chaque cycle découle de l'ordre de passage.
  - Le prochain bénéficiaire est affiché en permanence à tous les membres.
- **[v2] Contrôle préalable du bénéficiaire**
  - Trois jours avant l'ouverture de son cycle, si le futur bénéficiaire a des échéances non soldées dans le groupe, l'organisateur et lui-même sont notifiés.
  - Avant la remise de la cagnotte, l'organisateur choisit l'une de ces options, motivée et journalisée :
    - **Compensation** : les sommes dues sont déduites de la cagnotte remise et affectées à ses échéances en retard (cotisations de mode « Compensation »).
    - **Dérogation** : remise intégrale, la dette reste due.
    - **Permutation** avec un membre à jour, si elle est validée avant l'ouverture du cycle (module 10).
- **[v2] Remise de la cagnotte**
  - L'organisateur ou le trésorier enregistre chaque remise : montant, date, mode (espèces, Mobile Money…).
  - Le bénéficiaire confirme la réception depuis son compte. Pour un membre géré, l'organisateur coche « réception confirmée par le bénéficiaire » ; cette mention est journalisée.
  - Plusieurs remises sont possibles pour un même cycle (complément remis quand les retardataires paient).
- **Clôture d'un cycle**
  - **[v2]** Clôture automatique quand la date de fin est atteinte, que toutes les échéances sont soldées, que la cagnotte est entièrement remise et confirmée, et qu'aucun litige n'est ouvert.
  - **[v2]** Sinon, le cycle passe En attente de clôture. À partir de la date de fin, l'organisateur peut le clôturer manuellement (si aucun litige n'est ouvert) : les échéances impayées restent dues comme dettes reportées et continuent de générer des pénalités si elles sont activées.
  - À la clôture, un récapitulatif est généré : montant attendu, montant collecté, montant remis, payeurs à temps, retards, dettes restantes.
- **Fin du tour**
  - Lorsque tous les cycles sont clôturés, le groupe peut être clôturé. Les dettes éventuellement restantes sont listées dans le rapport final et restent visibles.
  - L'organisateur peut relancer un nouveau tour (module 3).

#### Règles de gestion

- **[v2]** Montant attendu d'un cycle = somme des échéances non annulées de ce cycle. Tous les membres cotisent, bénéficiaire compris (à rappeler dans le règlement interne).
- **[v2]** L'ouverture d'un cycle ne dépend jamais de la clôture du précédent. Cette règle remplace « un nouveau cycle ne peut démarrer que si le précédent est clôturé », qui bloquait toute la tontine au premier impayé.
- Un litige ouvert bloque la clôture du cycle concerné, et uniquement de celui-ci.
- Le bénéficiaire d'un cycle ne peut plus changer une fois le cycle En cours.
- **[v2]** Le total remis pour un cycle ne peut pas dépasser le total des cotisations validées du cycle, augmenté des pénalités payées qui lui sont affectées (module 7).

### Module 6 — Cotisations et paiements

**Priorité : Essentielle**

*Enregistrer précisément qui a payé, combien, quand et comment, pour chaque échéance.*

#### Fonctionnalités détaillées

- **Enregistrement d'une cotisation**
  - **[v2]** Chaque cotisation est affectée à une échéance précise (donc à un membre et à un cycle).
  - Champs : montant, date de paiement, mode (espèces, Mobile Money, virement, compensation), preuve de paiement optionnelle (capture d'écran, reçu).
  - Enregistrée par l'organisateur ou le trésorier : elle est validée immédiatement.
- **[v2] Déclaration par un membre**
  - Si le groupe l'autorise, un membre déclare lui-même son paiement (avec preuve de préférence). La déclaration est en attente de validation.
  - L'organisateur ou le trésorier la valide, ou la rejette avec un motif. Seules les cotisations validées comptent dans les soldes.
- **Paiements partiels**
  - Plusieurs cotisations peuvent régler une même échéance ; le reste dû est affiché clairement.
  - **[v2]** Le statut de l'échéance (à payer, partiel, soldée) est calculé par le service à chaque cotisation validée ou annulée. « En retard » est déduit : non soldée et date limite dépassée.
- **[v2] Paiement supérieur au montant dû**
  - L'excédent est réparti automatiquement sur les autres échéances du même membre dans le même groupe : d'abord les plus anciennes non soldées (dettes), puis les suivantes (avance). Chaque affectation crée une cotisation distincte, toutes reliées par une même référence de paiement.
- **[v2] Corrections**
  - Une cotisation validée n'est jamais modifiée ni supprimée : elle est annulée avec un motif, puis une nouvelle cotisation correcte est enregistrée.

#### Règles de gestion

- Une cotisation ne peut être enregistrée que sur l'échéance d'un cycle en cours ou passé, sauf affectation automatique d'un excédent (avance).
- **[v2]** Le total validé d'une échéance ne peut jamais dépasser son montant dû : au-delà, la règle de l'excédent s'applique.
- **[v2]** Les contrôles sont faits côté serveur, dans une transaction, avec verrouillage optimiste (section 5.5).

### Module 7 — Pénalités et gestion des retards

**Priorité : Importante**

*Formaliser et automatiser une règle souvent appliquée de façon informelle et inégale : la pénalité de retard.*

#### Fonctionnalités détaillées

- **Configuration de la pénalité**
  - Activation à la création du groupe (ou plus tard, sans effet rétroactif).
  - **[v2]** Deux modes clairement définis :
    - **Montant fixe par jour** de retard (ex. : 100 FCFA par jour).
    - **Pourcentage** du montant de cotisation, appliqué une seule fois dès que le retard est constaté (ex. : 10 %).
  - Nombre de jours de grâce avant application.
  - **[v2]** Plafond optionnel par échéance, pour éviter qu'une pénalité journalière ne grossisse sans limite.
- **Calcul et application automatique**
  - **[v2]** Une tâche planifiée quotidienne calcule la pénalité de chaque échéance non soldée dont la date limite plus les jours de grâce est dépassée. La pénalité est rattachée à l'échéance (une au maximum par échéance) et recalculée chaque jour jusqu'au solde de l'échéance, puis figée.
  - La pénalité est affichée séparément de la cotisation dans l'historique du membre.
- **[v2] Paiement et destination de la pénalité**
  - L'organisateur ou le trésorier enregistre le paiement d'une pénalité (date, mode).
  - Par défaut, une pénalité payée est ajoutée à la cagnotte du cycle concerné : elle compense le bénéficiaire pour le retard subi. Si la caisse de solidarité (module 17) est active, elle y est versée à la place.
- **Exonération manuelle**
  - L'organisateur peut annuler une pénalité (ex. : panne du réseau Mobile Money), avec motif obligatoire journalisé.

#### Règles de gestion

- Une pénalité ne s'applique jamais rétroactivement : activée en cours de tour, elle ne concerne que les échéances dont la date limite est postérieure à l'activation.
- Le cumul des pénalités d'un membre est visible par lui et par l'organisateur, jamais caché.

### Module 8 — Tableau de bord et suivi

**Priorité : Essentielle**

*Donner une visibilité immédiate et partagée de l'état du groupe, sans que personne n'ait à recalculer quoi que ce soit.*

#### Fonctionnalités détaillées

- **Tableau de bord organisateur**
  - Cycle en cours : statut de l'échéance de chaque membre, montant collecté sur le montant attendu.
  - Indicateur des membres en retard et des dettes reportées.
  - **[v2]** Actions en attente : déclarations de paiement à valider, remise de cagnotte à enregistrer, contrôle préalable d'un bénéficiaire, litiges ouverts.
  - Aperçu des cycles à venir et de leur bénéficiaire.
- **Tableau de bord membre**
  - Statut personnel sur le cycle en cours (soldé, partiel, en retard).
  - Date prévue de son tour de bénéficiaire.
  - Historique synthétique : total versé, pénalités, dettes éventuelles, cagnotte reçue.
  - **[v2]** Remise de cagnotte à confirmer, le cas échéant.
- **Vue d'ensemble multi-groupes**
  - Pour un utilisateur membre de plusieurs groupes, la page d'accueil récapitule l'état de chacun.

#### Règles de gestion

- **[v2]** Tous les montants affichés (collecté, attendu, restant dû) sont calculés à partir des échéances et des cotisations validées, jamais saisis à la main.
- L'historique est paginé.

### Module 9 — Notifications et rappels

**Priorité : Importante**

*Réduire les oublis de paiement, cause la plus fréquente de conflit dans une tontine réelle.*

#### Fonctionnalités détaillées

- **Rappels avant échéance**
  - Notification automatique (in-app, et par e-mail si disponible) un à deux jours avant la date limite, aux membres dont l'échéance n'est pas soldée.
- **Notification de bénéficiaire à venir**
  - Le futur bénéficiaire est notifié à l'avance pour s'organiser.
- **Notification d'événements du groupe**
  - Adhésion validée, exclusion, clôture d'un cycle, modification du règlement.
  - **[v2]** Déclaration de paiement à valider (organisateur, trésorier) ; déclaration validée ou rejetée (membre) ; contrôle préalable d'un bénéficiaire non à jour ; remise de cagnotte à confirmer ; litige ouvert ou tranché ; code de réinitialisation généré pour le compte.

#### Règles de gestion

- Chaque notification est consultable dans le centre de notifications in-app, même si l'envoi par e-mail échoue.
- **[v2]** Une même notification n'est jamais envoyée deux fois pour le même événement : les tâches planifiées vérifient ce qui a déjà été envoyé.

### Module 10 — Permutation et échange de tours

**Priorité : Importante**

*Gérer un cas fréquent : un membre ne peut pas assumer son tour à la date prévue et souhaite l'échanger avec un autre membre volontaire.*

#### Fonctionnalités détaillées

- **Demande de permutation**
  - Un membre propose d'échanger son tour avec celui d'un autre membre, pour deux cycles encore planifiés.
  - Le membre ciblé est notifié et accepte ou refuse explicitement. Pour un membre géré, l'organisateur répond en son nom, et cette mention est journalisée.
- **Validation finale**
  - Une fois les deux membres d'accord, l'organisateur valide la permutation, qui échange les bénéficiaires des deux cycles.

#### Règles de gestion

- Une permutation n'est possible que si le groupe l'autorise et pour deux cycles planifiés, jamais pour un cycle en cours ou clôturé.
- **[v2]** Aucun des deux membres ne doit avoir déjà été bénéficiaire.
- **[v2]** Une demande non aboutie expire automatiquement à l'ouverture du premier des deux cycles concernés.
- **[v2]** La permutation ne modifie que les bénéficiaires : les échéances restent inchangées, puisque tous les membres cotisent à chaque cycle.
- Toute permutation validée est journalisée avec les deux membres concernés et la date.

### Module 11 — Litiges et contestations

**Priorité : Importante**

*Offrir un mécanisme formel de résolution de désaccord, au lieu de laisser les conflits se régler hors de l'application.*

#### Fonctionnalités détaillées

- **Signalement d'un litige**
  - **[v2]** Un membre peut contester :
    - une échéance (« j'ai payé, mais rien n'est enregistré ») ;
    - une cotisation enregistrée (montant ou date erronés) ;
    - une remise de cagnotte (« je n'ai pas reçu ce montant »).
  - Description du désaccord et pièce justificative éventuelle.
- **Traitement**
  - L'arbitre consulte le litige, peut demander des précisions, puis tranche : contestation acceptée, rejet motivé ou ajustement.
  - **[v2]** Un ajustement ne modifie jamais une donnée existante : il passe par l'annulation d'une cotisation ou d'une remise et par l'enregistrement d'une nouvelle.

#### Règles de gestion

- Un litige non résolu bloque la clôture du cycle concerné.
- Toute décision est conservée avec sa justification dans le journal d'activité, consultable par tous les membres.
- **[v2] Conflit d'intérêts** : si l'organisateur est lui-même partie au litige (il a enregistré ou reçu la somme contestée), l'arbitrage revient au co-organisateur s'il existe. Sinon, l'organisateur tranche, mais sa décision est marquée « décision de l'organisateur, partie au litige », et le plaignant peut y ajouter son désaccord, visible de tous les membres.

### Module 12 — Rapports, relevés et exports

**Priorité : Importante**

*Permettre à chaque utilisateur de sortir ses données de l'application (preuve, archivage, partage).*

#### Fonctionnalités détaillées

- **Relevé individuel**
  - Export PDF du relevé d'un membre pour un groupe : échéances, cotisations, pénalités, cagnotte reçue, dettes restantes, dates et statuts.
- **Rapport de groupe**
  - Export PDF ou tableau récapitulatif pour l'organisateur : bilan cycle par cycle (attendu, collecté, remis), taux de ponctualité par membre, dettes restantes, litiges.

#### Règles de gestion

- **[v2]** Chaque export indique sa date de génération et le nom de l'application, pour pouvoir servir de preuve datée.

### Module 13 — Journal d'activité et traçabilité

**Priorité : Importante**

*Restaurer la confiance, valeur centrale de la tontine, par une traçabilité complète de toutes les actions sensibles.*

#### Fonctionnalités détaillées

- **Journalisation automatique**
  - Chaque action significative est horodatée et associée à son auteur : création de groupe, démarrage, validation d'adhésion, rattachement d'un membre géré, enregistrement, validation, rejet ou annulation de cotisation, remise de cagnotte et sa confirmation, pénalité exonérée, exclusion, retrait, permutation, litige et décision, modification du règlement, génération d'un code de réinitialisation.
  - **[v2]** Les actions automatiques (ouverture de cycle, calcul de pénalité) sont journalisées avec l'auteur « Système ».
- **Consultation**
  - Le journal d'un groupe est consultable par tous ses membres, en lecture seule. Cette transparence remplace la confiance informelle du cahier papier.

#### Règles de gestion

- Aucune entrée du journal ne peut être modifiée ni supprimée, y compris par l'organisateur.
- **[v2]** Le journal est alimenté par un service unique (JournalService) appelé par tous les autres modules ; aucune fonctionnalité d'écriture ou de suppression n'est exposée.

### Module 14 — Messagerie interne au groupe

**Priorité : Optionnelle**

*Centraliser la communication liée à la tontine, aujourd'hui dispersée sur WhatsApp ou à l'oral.*

#### Fonctionnalités détaillées

- **Fil de discussion de groupe**
  - Chaque groupe dispose d'un fil de messages simple, visible par tous ses membres disposant d'un compte, pour les annonces ou questions liées à la tontine.

### Module 15 — Simulateur de tontine

**Priorité : Optionnelle**

*Aider un futur organisateur à définir des paramètres réalistes avant de créer son groupe.*

#### Fonctionnalités détaillées

- **Simulation avant création**
  - L'utilisateur saisit un nombre de membres, un montant de cotisation, une fréquence et une date de démarrage.
  - Le simulateur affiche la durée totale du tour, le montant reçu par chaque bénéficiaire et le calendrier prévisionnel des cycles.
  - **[v2]** Le calcul du calendrier est un composant réutilisé tel quel par le module 5 : il est écrit une seule fois.

### Module 16 — Intégration Mobile Money

**Priorité : Optionnelle / avancée**

*Automatiser la détection des paiements réels effectués via les services de Mobile Money les plus utilisés au Bénin.*

#### Fonctionnalités détaillées

- **Enregistrement facilité**
  - Selon l'accès à une API de paiement (MTN MoMo, Moov Money, Celtiis Cash), tenter une réconciliation automatique entre un paiement reçu et une échéance attendue.

#### Règles de gestion

- Ce module dépend de l'accès réel à une API de paiement, souvent limité pour un projet étudiant : il est traité en dernier, après la solidité complète des modules essentiels et importants.

### Module 17 — Caisse de solidarité (variante avancée)

**Priorité : Optionnelle / avancée**

*Modéliser une variante répandue où une petite part de chaque cotisation alimente un fonds commun d'urgence non redistribué à chaque cycle.*

#### Fonctionnalités détaillées

- **Fonds de solidarité**
  - Un pourcentage configurable de chaque cotisation validée est affecté à une caisse commune distincte de la cagnotte.
  - **[v2]** Les pénalités payées y sont versées lorsque la caisse est active (module 7).
  - L'organisateur enregistre les sorties de fonds (ex. : aide à un membre en difficulté), avec motif obligatoire.

#### Règles de gestion

- **[v2]** Activer la caisse fait partie des paramètres figés au démarrage, puisqu'elle change le montant de la cagnotte remise à chaque bénéficiaire.

## 4. Modèle de données complet

Entités et relations couvrant l'ensemble des modules essentiels et importants. Les entités des modules optionnels sont présentées à part et s'ajoutent sans remettre en cause le schéma de base.

### 4.1 Entités principales

| **Entité** | **Champs clés** | **Description** |
| --- | --- | --- |
| Utilisateur | id, nom, prenom, telephone (unique, normalisé), motDePasseHache, email, dateCreation, anonymise | Compte unique, base de toute identité dans le système. |
| **[v2]** ReinitialisationMotDePasse | id, utilisateurId, codeHache, genereParId, dateExpiration, utilise | Code ou lien de récupération de compte, à usage unique. |
| GroupeTontine | id, nom, description, montantCotisation, frequence, dateDebut, nombreMaxMembres, reglementInterne, statut, codeInvitation, declarationMembreAutorisee, permutationAutorisee, penaliteActive, typePenalite, valeurPenalite, joursGrace, plafondPenalite, groupeOrigineId, version | Un groupe de tontine et ses règles. groupeOrigineId relie un tour relancé au précédent. |
| Adhesion | id, groupeId, utilisateurId (nullable), nomMembreGere, telephoneMembreGere, role, ordrePassage, statut, dateAdhesion, dateSortie, motifSortie | Lien entre une personne et un groupe. utilisateurId vide = membre géré sans compte. |
| DemandeAdhesion | id, utilisateurId, groupeId, type, statut, dateDemande, dateDecision | Demande d'adhésion par code, ou demande de rattachement d'un membre géré à un compte. |
| Cycle | id, groupeId, numeroCycle, beneficiaireAdhesionId, dateDebut, dateFin, statut, dateCloture, version | Un cycle de cotisation et son bénéficiaire. Montants attendu et collecté calculés, non stockés. |
| **[v2]** Echeance | id, cycleId, adhesionId, montantDu, dateLimite, statut, version | Ce qu'un membre doit pour un cycle. Base des retards, pénalités et litiges. |
| Cotisation | id, echeanceId, montant, datePaiement, modePaiement, referencePaiement, statut, declareeParId, valideeParId, dateValidation, motif, pieceJointeId, version | Un paiement (ou une part de paiement) affecté à une échéance. |
| **[v2]** PieceJointe | id, nomFichier, typeMime, taille, contenu, ajouteeParId, dateAjout | Preuve de paiement ou justificatif de litige, stocké en base. |
| Penalite | id, echeanceId (unique), montant, dateCalcul, statut, datePaiement, motifExoneration | Pénalité de retard liée à une échéance. |
| **[v2]** Versement | id, groupeId, adhesionId, cycleId (nullable), type, montant, dateVersement, modeVersement, enregistreParId, confirmeParBeneficiaire, dateConfirmation, statut, motifAnnulation | Argent remis par le groupe à un membre : remise de cagnotte ou restitution après départ. |
| EchangeTour | id, groupeId, adhesionDemandeurId, adhesionCibleId, cycleDemandeurId, cycleCibleId, statut, dateDemande, dateReponseCible, dateValidationOrganisateur | Demande de permutation entre deux membres. |
| Litige | id, cycleId, adhesionConcerneeId, cotisationId (nullable), versementId (nullable), ouvertParId, arbitreId, description, pieceJointeId, statut, resolution, desaccordPlaignant, dateOuverture, dateResolution | Contestation formelle sur une échéance, une cotisation ou une remise. |
| JournalActivite | id, groupeId, auteurId (nullable = Système), action, typeEntite, entiteId, details, dateAction | Trace immuable de toute action sensible. |
| Notification | id, utilisateurId, groupeId, type, contenu, lien, lu, dateEnvoi, emailEnvoye, cleEvenement | Notification adressée à un utilisateur. cleEvenement empêche les doublons. |

### 4.2 Valeurs possibles des statuts et types

| **Champ** | **Valeurs** |
| --- | --- |
| GroupeTontine.statut | BROUILLON, EN_COURS, CLOTURE |
| GroupeTontine.frequence | JOURNALIERE, HEBDOMADAIRE, MENSUELLE |
| GroupeTontine.typePenalite | FIXE_PAR_JOUR, POURCENTAGE |
| Adhesion.role | ORGANISATEUR, CO_ORGANISATEUR, TRESORIER, MEMBRE |
| Adhesion.statut | ACTIVE, RETIREE, EXCLUE |
| DemandeAdhesion.type / statut | ADHESION, RATTACHEMENT / EN_ATTENTE, ACCEPTEE, REFUSEE |
| Cycle.statut | PLANIFIE, EN_COURS, EN_ATTENTE_CLOTURE, CLOTURE |
| Echeance.statut | A_PAYER, PARTIEL, SOLDEE, ANNULEE (« en retard » est calculé, non stocké) |
| Cotisation.modePaiement | ESPECES, MOBILE_MONEY, VIREMENT, COMPENSATION |
| Cotisation.statut | EN_ATTENTE_VALIDATION, VALIDEE, REJETEE, ANNULEE |
| Penalite.statut | DUE, PAYEE, EXONEREE |
| Versement.type / statut | REMISE_CAGNOTTE, RESTITUTION / ENREGISTRE, ANNULE |
| EchangeTour.statut | EN_ATTENTE_CIBLE, EN_ATTENTE_ORGANISATEUR, VALIDEE, REFUSEE, EXPIREE |
| Litige.statut | OUVERT, EN_ATTENTE_PRECISIONS, ACCEPTE, REJETE, AJUSTE |

### 4.3 Entités des modules optionnels

| **Entité** | **Champs clés** | **Module associé** |
| --- | --- | --- |
| MessageGroupe | id, groupeId, auteurId, contenu, dateEnvoi | Module 14 — Messagerie |
| CaisseSolidarite | id, groupeId, pourcentageAffecte | Module 17 — Caisse de solidarité (solde calculé à partir des mouvements) |
| MouvementCaisse | id, caisseId, montant, type (ENTREE / SORTIE), origine (COTISATION / PENALITE / AIDE), motif, date, enregistreParId | Module 17 — Caisse de solidarité |

### 4.4 Relations (description textuelle)

- Un Utilisateur peut avoir plusieurs Adhesion (une par groupe). Une Adhesion sans Utilisateur représente un membre géré.
- Un GroupeTontine a plusieurs Adhesion et plusieurs Cycle.
- Un Cycle a un bénéficiaire (une Adhesion) et plusieurs Echeance, une par membre.
- **[v2]** Une Echeance appartient à un Cycle et à une Adhesion ; elle a zéro ou plusieurs Cotisation et zéro ou une Penalite.
- **[v2]** Un Versement relie un GroupeTontine à l'Adhesion qui reçoit l'argent, et au Cycle concerné pour une remise de cagnotte.
- Un EchangeTour référence deux Adhesion et deux Cycle.
- **[v2]** Un Litige référence un Cycle et l'Adhesion concernée, avec éventuellement la Cotisation ou le Versement contesté.
- Le JournalActivite référence un GroupeTontine et son auteur, et désigne l'élément concerné par un couple typeEntite / entiteId sans clé étrangère, ce qui garantit qu'il reste consultable même si l'élément d'origine évolue.

### 4.5 [v2] Conventions de données

- **Montants** : nombres entiers en FCFA (type Java `long`, colonne BIGINT). Jamais de `double` ni de `float` pour de l'argent.
- **Dates** : `LocalDate` pour les dates métier (début, fin, date limite) ; `LocalDateTime` pour les horodatages, toujours dans le fuseau Africa/Porto-Novo.
- **Énumérations** : stockées en texte (`@Enumerated(EnumType.STRING)`), jamais en numéro d'ordre.
- **Données dérivées** : le montant collecté d'un cycle, le statut « en retard », le solde d'une caisse ou le total dû d'un membre sont calculés, jamais saisis. Seul Echeance.statut est stocké, et il est mis à jour par le service dans la même transaction que la cotisation qui le modifie.
- **Aucune suppression physique** des données financières (Echeance, Cotisation, Penalite, Versement, JournalActivite) : on annule avec un motif.
- **Verrouillage optimiste** (`@Version`) sur GroupeTontine, Cycle, Echeance et Cotisation.

## 5. Exigences non fonctionnelles

### 5.1 Sécurité

- Mots de passe stockés uniquement sous forme hachée (BCrypt via Spring Security).
- Contrôle d'accès strict : un membre ne peut jamais consulter ni modifier les données d'un groupe auquel il n'appartient pas.
- **[v2]** Ce contrôle s'appuie sur l'identifiant du groupe vérifié côté serveur à chaque requête : changer un identifiant dans l'adresse ne doit jamais donner accès aux données d'un autre groupe (voir 5.5.1).
- Séparation des permissions selon le rôle dans le groupe, à chaque action sensible.
- **[v2]** Protection CSRF de Spring Security conservée (active par défaut avec les formulaires Thymeleaf).

### 5.2 Ergonomie et accessibilité

- Interface utilisable sur smartphone en priorité.
- Formulaires courts et vocabulaire simple : « tour », « cotisation », « bénéficiaire », « échéance », plutôt que des termes informatiques.
- Messages d'erreur clairs et en français, jamais de message technique brut.

### 5.3 Fiabilité des données

- Aucune suppression physique des cotisations ou de l'historique : toute correction se fait par une nouvelle entrée documentée.
- Toutes les opérations financières sont contrôlées côté serveur (cohérence avec le cycle, l'échéance et le groupe) avant d'être enregistrées.

### 5.4 Performance

- Le tableau de bord d'un groupe reste rapide même avec plusieurs dizaines de cycles : historique paginé (`Pageable` de Spring Data).

### 5.5 [v2] Architecture et choix techniques

Cette section fixe les choix techniques transverses, à mettre en place dès la Vague 0 pour éviter que chacun les réinvente à sa manière.

#### 5.5.1 Contrôle d'accès par groupe

Les rôles étant relatifs à un groupe, les rôles globaux de Spring Security (`hasRole`) ne suffisent pas. On crée un composant unique, appelé dans les annotations de sécurité des services :

```
@Service("securiteGroupe")
public class SecuriteGroupe {
    public boolean estMembre(Long groupeId) { ... }
    public boolean estGestionnaire(Long groupeId) { ... }   // organisateur ou co-organisateur
    public boolean peutValiderPaiements(Long groupeId) { ... } // + trésorier
}

@PreAuthorize("@securiteGroupe.peutValiderPaiements(#groupeId)")
public void validerCotisation(Long groupeId, Long cotisationId) { ... }
```

- Activer `@EnableMethodSecurity`.
- Le service vérifie aussi que l'élément manipulé (cotisation, cycle…) appartient bien au groupe indiqué.
- Un refus d'accès affiche la page « accès refusé » du module 1.

#### 5.5.2 Tâches planifiées

Activer `@EnableScheduling`. Toutes les tâches s'exécutent dans le fuseau Africa/Porto-Novo et sont **idempotentes** : relancées deux fois le même jour, elles ne produisent pas de doublon.

| **Tâche** | **Heure** | **Rôle** | **Module** |
| --- | --- | --- | --- |
| Ouverture des cycles | 00:05 | Passe En cours les cycles dont la date de début est atteinte. | 5 |
| Clôture automatique | 00:15 | Clôture les cycles remplissant toutes les conditions ; passe les autres En attente de clôture. | 5 |
| Calcul des pénalités | 01:00 | Calcule ou met à jour les pénalités des échéances en retard. | 7 |
| Expiration des permutations | 00:10 | Expire les demandes dont le premier cycle s'ouvre. | 10 |
| Contrôle préalable des bénéficiaires | 07:30 | Signale les bénéficiaires non à jour à J-3. | 5, 9 |
| Rappels d'échéance | 08:00 | Notifie les membres dont l'échéance arrive à J-2 ou J-1. | 9 |

- La date du jour est obtenue via un `Clock` injecté, jamais par `LocalDate.now()` en dur, pour pouvoir tester les calculs à n'importe quelle date.

#### 5.5.3 Transactions et concurrence

- Chaque opération métier (valider une cotisation, enregistrer une remise, appliquer une permutation…) est une méthode de service annotée `@Transactional`.
- Le verrouillage optimiste (`@Version`) empêche deux validations simultanées de produire un solde faux ; en cas de conflit, l'utilisateur voit un message invitant à recharger la page.

#### 5.5.4 Base de données et migrations

- Schéma géré par **Flyway** (`src/main/resources/db/migration/V1__schema_initial.sql`, puis V2, V3…), avec `spring.jpa.hibernate.ddl-auto=validate`.
- Raison : avec deux développeurs, `ddl-auto=update` fait diverger les bases de chacun sans laisser de trace. Une migration versionnée sur Git garantit le même schéma partout.
- Le script V1 contient le schéma complet des modules essentiels et importants, figé en Vague 0.

#### 5.5.5 Configuration et secrets

- Le fichier `application.properties` est versionné, mais ne contient aucun secret : il lit des variables d'environnement (`spring.datasource.password=${DB_PASSWORD}`).
- Un profil `local` (`application-local.properties`, ignoré par Git) porte les valeurs propres à chaque machine. Ce schéma remplace celui du guide de mise en place, qui ignorait `application.properties` entier et empêchait l'application de démarrer chez un nouveau membre.

#### 5.5.6 Fichiers joints

- Preuves et justificatifs stockés en base (entité PieceJointe), et non sur le disque. Les hébergeurs gratuits ont un disque éphémère : un fichier écrit sur le disque y disparaît à chaque redéploiement.
- Formats acceptés : JPG, PNG, PDF ; taille maximale 2 Mo par fichier. Le type est vérifié côté serveur.

#### 5.5.7 Gestion des erreurs

- Une exception métier unique (`RegleMetierException`), levée par les services avec un message en français destiné à l'utilisateur.
- Un `@ControllerAdvice` transforme ces exceptions en message affiché sur la page, et les erreurs inattendues en page d'erreur générique (le détail technique va dans les logs, jamais à l'écran).

#### 5.5.8 Tests automatisés

- Tests unitaires **JUnit 5 + Mockito** obligatoires pour la logique de calcul : génération du calendrier, bénéficiaires, statut des échéances, répartition des excédents, pénalités, permutations, sorties de membres.
- Tests de dépôt avec `@DataJpaTest` pour les requêtes personnalisées.
- Ces tests s'ajoutent à la Definition of Done pour les modules 4, 5, 6, 7 et 10 : la PR n'est validée que si `mvn test` passe.

#### 5.5.9 Bibliothèques complémentaires

- Export PDF : **OpenPDF** (licence LGPL/MPL), plutôt qu'iText 7 dont la licence AGPL impose des obligations en cas de diffusion.
- E-mail : Spring Boot Starter Mail, désactivable par configuration. L'application doit fonctionner entièrement sans e-mail.

#### 5.5.10 Déploiement

- Railway propose MySQL directement. Render propose surtout PostgreSQL : à vérifier avant de le retenir avec MySQL.
- Variables d'environnement de la plateforme pour tous les secrets ; profil `prod`.

## 6. Charte graphique et identité visuelle

Cette charte fixe les bases visuelles à respecter dès les premières fonctionnalités développées (dès le module 1), pour garantir une cohérence visuelle tout au long du projet plutôt que de la corriger après coup.

### 6.1 Palette de couleurs

| **Couleur** | **Usage** | **Signification recherchée** |
| --- | --- | --- |
| Vert tontine (couleur primaire) | Actions principales, éléments de marque, en-têtes, boutons d'action | Confiance, argent, croissance |
| Or bronze (couleur d'accent) | Mise en avant secondaire, montants, badges de réussite | Prospérité, ancrage culturel local |
| Gris neutre | Texte courant, structure, éléments non prioritaires | Sobriété, lisibilité |
| Vert de statut (succès) | Échéance soldée, action validée | Confirmation claire |
| Rouge corail de statut (alerte) | Échéance en retard, litige ouvert, action requise | Attention sans agressivité visuelle |

> [!WARNING] Règle d'accessibilité non négociable
> Un statut n'est jamais codé uniquement par la couleur. Chaque statut est toujours accompagné d'une icône et/ou d'un mot explicite, pour rester lisible par les personnes daltoniennes — un enjeu particulièrement sensible sur un outil qui affiche des statuts financiers.

### 6.2 Typographie

- Police sans-serif claire, optimisée pour l'écran, lisible sur smartphone en 3G/4G.
- Hiérarchie à trois niveaux : titre de section, texte courant, légende.
- Vocabulaire de l'interface en français simple (voir 5.2).

### 6.3 Principes d'interface

- Poids visuel minimal : icônes simples plutôt qu'illustrations chargées.
- Mobile-first systématique.
- Iconographie chaleureuse et communautaire (cercles, mains, motifs de rotation) plutôt qu'un vocabulaire de banque ou de fintech.
- Contraste suffisant sur tous les écrans, y compris pour les badges de statut.

### 6.4 Exemple de composant type : la carte de cycle

- Nom du groupe en titre, avec un badge indiquant le numéro du cycle en cours (couleur primaire).
- Barre de progression du montant collecté par rapport au montant attendu.
- Un badge par membre indiquant le statut de son échéance, combinant toujours une icône et un mot : coche verte « à jour » ou horloge corail « en retard ».
- **[v2]** Mention de l'état de la remise : « cagnotte à remettre », « remise, en attente de confirmation » ou « remise confirmée ».

## 7. Organisation, feuille de route et calendrier

### 7.1 [v2] Organisation à deux développeurs

- L'équipe compte deux développeurs, notés A et B. Chacun développe **un module par semaine**, en parallèle de l'autre, sur sa propre branche `feature/*`.
- Les modules sont répartis sur deux pistes : la **chaîne principale** (les modules qui dépendent les uns des autres) et un **module parallèle** indépendant.
- La chaîne principale **alterne** entre A et B d'une semaine à l'autre, pour que les deux développeurs maîtrisent le cœur métier (sécurité, cycles, cotisations), et pas seulement l'un des deux.
- **Point hebdomadaire de fin de semaine** (par exemple le dimanche) :
  - Démonstration des deux modules, revue des deux Pull Requests selon la Definition of Done.
  - Intégration dans `dev` : on fusionne la première PR, puis le second développeur met sa branche à jour avec `dev` et on fusionne la seconde.
  - Lancement de l'application et de `mvn test` sur `dev` après intégration.
  - Mise à jour de PROGRESS.md et du tableau Kanban, attribution des modules de la semaine suivante.

> [!TIP] Règle en cas de retard
> Si un module de la chaîne principale déborde, c'est le module parallèle de la semaine suivante qui est décalé (ou abandonné s'il est optionnel), jamais la chaîne principale. Le développeur libéré vient en renfort sur la chaîne.

### 7.2 [v2] Vague 0 — Mise en place (8 au 11 octobre 2026)

À réaliser à deux cette semaine, avant tout développement de module :

- Dépôt GitHub, branches `main` et `dev`, protection de `main` et `dev` (fusion uniquement par Pull Request).
- Projet Spring Boot (Java 21, Maven) avec les dépendances de départ, plus Flyway.
- Structure des packages, `docker-compose.yml` (MySQL 8.0), configuration selon 5.5.5.
- Modèle de données complet relu ensemble, puis migration Flyway V1 et entités JPA correspondantes.
- Composants transverses : `SecuriteGroupe` (squelette), `RegleMetierException` et `@ControllerAdvice`, `Clock` injectable.
- Gabarit Thymeleaf commun (en-tête, menu, pied de page) et feuille de style avec les couleurs de la charte.
- Tableau Kanban rempli selon le calendrier, README, PROGRESS.md.
- Premier déploiement de test (page d'accueil vide) pour valider la chaîne de déploiement.

### 7.3 [v2] Calendrier prévisionnel

| **Sem.** | **Période** | **Chaîne principale** | **Module parallèle** |
| --- | --- | --- | --- |
| 0 | 8–11 oct. 2026 | Vague 0 — mise en place (A + B) | — |
| 1 | 12–18 oct. 2026 | A : Module 2 — Comptes, identité et rôles | B : Module 1 — Accueil et navigation |
| 2 | 19–25 oct. 2026 | B : Module 3 — Groupes de tontine | A : Module 13 — Journal d'activité |
| 3 | 26 oct.–1er nov. 2026 | A : Module 4 — Adhésion et membres | B : Module 15 — Simulateur (calcul du calendrier) |
| 4 | 2–8 nov. 2026 | B : Module 5 — Cycles et remise de cagnotte | A : Module 14 — Messagerie interne |
| 5 | 9–15 nov. 2026 | A : Module 6 — Cotisations et paiements | B : Module 10 — Permutation de tours |
| 6 | 16–22 nov. 2026 | B : Module 8 — Tableau de bord | A : Module 7 — Pénalités et retards |
| 7 | 23–29 nov. 2026 | A : Module 11 — Litiges et contestations | B : Module 9 — Notifications et rappels |
| 8 | 30 nov.–6 déc. 2026 | B : Module 12 — Rapports et exports | A : Module 17 — Caisse de solidarité |
| 9 | 7–13 déc. 2026 | A : Tests de bout en bout, corrections, déploiement | B : Module 16 — Mobile Money (si une API est accessible, sinon renfort) |
| 10 | 14–20 déc. 2026 | A + B : Stabilisation, données de démonstration, préparation de la soutenance | — |

**Pourquoi cet ordre**

- Chaque module de la chaîne principale ne démarre qu'une fois sa dépendance intégrée au point de la semaine précédente : 2 → 3 → 4 → 5 → 6 → 8.
- Les modules parallèles ne dépendent que de ce qui est déjà dans `dev` : le Journal (13) n'a besoin que des entités, le Simulateur (15) ne dépend de rien et fournit le calcul du calendrier au module 5, la Permutation (10) arrive après les cycles (5), les Pénalités (7) et le Tableau de bord (8) après les cotisations (6), les Notifications (9) après les pénalités (7).
- Le Journal (13) est placé tôt : tous les modules suivants l'appellent dès leur développement.
- Les modules optionnels 14, 15 et 17 occupent des semaines où aucun module important n'est encore développable faute de dépendance. Ce sont eux qui sautent en premier en cas de retard.

> [!NOTE] Repères clés
> Démarrage : lundi 12 octobre 2026 — MVP (Vague 1 complète) : dimanche 22 novembre 2026, ce qui ouvre la Phase 0 de tests avec des tontines pilotes — Modules essentiels et importants terminés : dimanche 6 décembre 2026 — Fin des développements et stabilisation : dimanche 20 décembre 2026.

> [!WARNING] Point de vigilance
> Un module par semaine et par personne en parallèle des cours est un rythme exigeant. Les modules 2, 5 et 6 sont les plus lourds. Les semaines 9 et 10 servent de marge : si le retard dépasse cette marge, on réduit le périmètre (modules optionnels) plutôt que la qualité des modules essentiels.

### 7.4 Vague 4 — Monétisation (freemium)

Contrairement aux vagues précédentes, cette vague ne démarre pas selon un ordre de dépendance technique mais selon une condition de validation d'usage. Elle est volontairement absente du calendrier prévisionnel.

> [!TIP] Condition de déclenchement
> À ne démarrer qu'une fois qu'au moins 3 groupes pilotes réels ont complété au moins un tour complet de tontine via l'application. Développer cette vague plus tôt risquerait de brider artificiellement les groupes pilotes par les limites du palier gratuit, avant même d'avoir validé l'usage du produit.

- Entité Abonnement et plan par défaut Gratuit pour tout utilisateur.
- Limites du palier Gratuit (nombre de groupes organisés, taille maximale d'un groupe), à fixer à partir des données réelles des groupes pilotes.
- Fonctionnalités réservées au palier Pro sur les modules 9 (Notifications), 10 (Permutation de tours) et 12 (Rapports et exports).
- Intégration d'un agrégateur de paiement local (FedaPay ou Kkiapay) pour l'encaissement de l'abonnement Pro, ce qui suppose au préalable une structure juridique pour ouvrir un compte marchand.
- Logique d'expiration et de passage en lecture seule des groupes excédentaires en fin d'abonnement, sans jamais supprimer de données (section 5.3).

*Le palier B2B (marque blanche, déploiement dédié pour associations, coopératives, PME) reste hors périmètre : il suppose un chantier multi-tenant distinct, à ne considérer qu'après validation de la Vague 4.*

> [!TIP] Rappel de méthode
> Chaque fonctionnalité est découpée si besoin lors de sa mise au backlog Kanban (voir le guide de mise en place), et validée au point hebdomadaire avant d'attribuer la suivante. Rien n'est développé avant que le schéma de données (Vague 0) soit figé et compris des deux développeurs.
