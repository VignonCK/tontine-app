# Modèle de données

Schéma créé par la migration Flyway `src/main/resources/db/migration/V1__schema_initial.sql`, d'après la section 4 du cahier des charges. Il couvre les modules essentiels et importants ; les tables des modules optionnels (section 4.3) viendront dans des migrations suivantes.

Conventions (section 4.5) : montants en `BIGINT` (FCFA entiers), dates métier en `DATE`, horodatages en `DATETIME`, statuts en `VARCHAR` contrôlés par des contraintes `CHECK`, colonne `version` sur `groupe_tontine`, `cycle`, `echeance` et `cotisation`. Aucune suppression en cascade.

## Compléments au cahier des charges

Choix faits lors de la création du schéma, pour combler des manques du cahier (à reporter dans la section 4) :

| Ajout | Raison |
| --- | --- |
| `groupe_tontine.date_activation_penalite` | La règle « pas d'effet rétroactif » (module 7) a besoin de la date d'activation. |
| Statut `ANNULE` pour `cycle` | Le cycle d'un membre sorti avant son tour (module 4) est annulé et non supprimé : ses échéances, données financières, ne doivent jamais être supprimées. |
| Statut `SUPPRIME` pour `groupe_tontine` | Un brouillon supprimé (module 3) garde son journal d'activité, qui est immuable. |
| `demande_adhesion.adhesion_id` | Désigne le membre géré à rattacher (module 4) ; obligatoire pour un rattachement, vide pour une adhésion. |
| `penalite.mode_paiement` | Le paiement d'une pénalité enregistre sa date et son mode (module 7). |
| Valeurs de `versement.mode_versement` : `ESPECES`, `MOBILE_MONEY`, `VIREMENT` | Le cahier ne fixe pas ces valeurs ; `COMPENSATION` est exclu, car une compensation est une déduction de la cagnotte et non une remise d'argent. |
| `cotisation.date_enregistrement` | Moment de la saisie dans l'application, distinct de la date de paiement déclarée. |
| `utilisateur.nb_echecs_connexion`, `utilisateur.bloque_jusqu_a` | Suspension de 15 minutes après 5 échecs (module 2), conservée même si l'application redémarre. |
| `reinitialisation_mot_de_passe.date_creation` | Limite de 3 codes par compte et par 24 heures (module 2). |

## Diagramme

Pour garder le diagramme lisible, seules les clés et quelques colonnes importantes sont montrées ; la liste complète est dans le script SQL.

```mermaid
erDiagram
    utilisateur ||--o{ adhesion : "a"
    utilisateur ||--o{ reinitialisation_mot_de_passe : "reçoit"
    utilisateur |o--o{ reinitialisation_mot_de_passe : "génère"
    utilisateur ||--o{ demande_adhesion : "envoie"
    utilisateur ||--o{ notification : "reçoit"
    utilisateur ||--o{ piece_jointe : "ajoute"
    utilisateur |o--o{ journal_activite : "est auteur de"

    groupe_tontine |o--o{ groupe_tontine : "relance"
    groupe_tontine ||--o{ adhesion : "regroupe"
    groupe_tontine ||--o{ demande_adhesion : "reçoit"
    groupe_tontine ||--o{ cycle : "comprend"
    groupe_tontine ||--o{ versement : "verse"
    groupe_tontine ||--o{ echange_tour : "concerne"
    groupe_tontine ||--o{ journal_activite : "trace"
    groupe_tontine |o--o{ notification : "concerne"

    adhesion ||--o{ cycle : "est bénéficiaire de"
    adhesion ||--o{ echeance : "doit"
    adhesion ||--o{ versement : "reçoit"
    adhesion ||--o{ echange_tour : "demande / est ciblée"
    adhesion ||--o{ litige : "est concernée par"
    adhesion |o--o{ demande_adhesion : "est visée par un rattachement"

    cycle ||--o{ echeance : "génère"
    cycle |o--o{ versement : "remise de cagnotte"
    cycle ||--o{ echange_tour : "est échangé"
    cycle ||--o{ litige : "porte"

    echeance ||--o{ cotisation : "est réglée par"
    echeance ||--o| penalite : "peut avoir"

    cotisation |o--o{ litige : "est contestée"
    versement |o--o{ litige : "est contesté"
    piece_jointe |o--o{ cotisation : "prouve"
    piece_jointe |o--o{ litige : "justifie"

    utilisateur {
        bigint id PK
        varchar telephone UK "forme normalisée"
        varchar mot_de_passe_hache
        boolean anonymise
        int nb_echecs_connexion
        datetime bloque_jusqu_a
    }
    reinitialisation_mot_de_passe {
        bigint id PK
        bigint utilisateur_id FK
        bigint genere_par_id FK "vide = e-mail"
        datetime date_expiration
        boolean utilise
    }
    groupe_tontine {
        bigint id PK
        bigint montant_cotisation
        varchar frequence
        varchar statut
        varchar code_invitation UK
        date date_activation_penalite
        bigint groupe_origine_id FK
        bigint version
    }
    adhesion {
        bigint id PK
        bigint groupe_id FK
        bigint utilisateur_id FK "vide = membre géré"
        varchar role
        int ordre_passage
        varchar statut
    }
    demande_adhesion {
        bigint id PK
        bigint utilisateur_id FK
        bigint groupe_id FK
        bigint adhesion_id FK "rattachement uniquement"
        varchar type
        varchar statut
    }
    cycle {
        bigint id PK
        bigint groupe_id FK
        int numero_cycle
        bigint beneficiaire_adhesion_id FK
        date date_debut
        date date_fin
        varchar statut
        bigint version
    }
    echeance {
        bigint id PK
        bigint cycle_id FK
        bigint adhesion_id FK
        bigint montant_du
        date date_limite
        varchar statut
        bigint version
    }
    cotisation {
        bigint id PK
        bigint echeance_id FK
        bigint montant
        date date_paiement
        datetime date_enregistrement
        varchar mode_paiement
        varchar reference_paiement
        varchar statut
        bigint version
    }
    piece_jointe {
        bigint id PK
        varchar type_mime
        mediumblob contenu
    }
    penalite {
        bigint id PK
        bigint echeance_id FK,UK
        bigint montant
        varchar statut
        varchar mode_paiement
    }
    versement {
        bigint id PK
        bigint groupe_id FK
        bigint adhesion_id FK
        bigint cycle_id FK
        varchar type
        bigint montant
        varchar mode_versement
        varchar statut
    }
    echange_tour {
        bigint id PK
        bigint adhesion_demandeur_id FK
        bigint adhesion_cible_id FK
        bigint cycle_demandeur_id FK
        bigint cycle_cible_id FK
        varchar statut
    }
    litige {
        bigint id PK
        bigint cycle_id FK
        bigint adhesion_concernee_id FK
        bigint cotisation_id FK
        bigint versement_id FK
        bigint arbitre_id FK
        varchar statut
    }
    journal_activite {
        bigint id PK
        bigint groupe_id FK
        bigint auteur_id FK "vide = Système"
        varchar type_entite
        bigint entite_id "sans clé étrangère"
        datetime date_action
    }
    notification {
        bigint id PK
        bigint utilisateur_id FK
        bigint groupe_id FK
        varchar cle_evenement "unique par utilisateur"
        boolean lu
    }
```

## Les tables

- **utilisateur** : un compte, identifié par son numéro de téléphone normalisé (unique) ; il compte les échecs de connexion pour suspendre le compte 15 minutes après 5 échecs, et ses données sont anonymisées, jamais effacées, à la suppression.
- **reinitialisation_mot_de_passe** : un code ou lien de récupération à usage unique, stocké haché, généré par l'utilisateur lui-même (e-mail) ou par un organisateur.
- **groupe_tontine** : un groupe et toutes ses règles (cotisation, fréquence, pénalités, permutations) ; `date_activation_penalite` évite toute pénalité rétroactive, un brouillon supprimé passe au statut `SUPPRIME` (son journal est conservé) et `groupe_origine_id` relie un tour relancé au précédent.
- **adhesion** : la place d'une personne dans un groupe, avec son rôle et son ordre de passage ; sans `utilisateur_id`, c'est un membre géré sans compte.
- **demande_adhesion** : une demande pour rejoindre un groupe par son code, ou pour rattacher à un compte le membre géré désigné par `adhesion_id`, en attente de la décision de l'organisateur.
- **cycle** : un tour de cotisation avec ses dates et son bénéficiaire ; les montants attendu et collecté sont calculés, pas stockés, et le cycle d'un membre sorti avant son tour passe au statut `ANNULE` au lieu d'être supprimé.
- **echeance** : ce qu'un membre doit pour un cycle (une seule par membre et par cycle) ; c'est la base des paiements, des retards, des pénalités et des litiges.
- **cotisation** : un paiement, ou une part de paiement, affecté à une échéance, avec sa date de paiement et le moment de sa saisie dans l'application ; jamais modifié ni supprimé, seulement annulé avec un motif.
- **piece_jointe** : un fichier (preuve de paiement, justificatif) stocké en base, car le disque des hébergeurs gratuits est effacé à chaque redéploiement.
- **penalite** : la pénalité de retard d'une échéance (une au maximum), recalculée chaque jour jusqu'au solde de l'échéance, avec la date et le mode de son paiement.
- **versement** : de l'argent remis par le groupe à un membre (en espèces, par Mobile Money ou par virement), soit la cagnotte d'un cycle, soit une restitution après un départ.
- **echange_tour** : une demande de permutation entre deux membres et deux cycles, qui passe par l'accord du membre ciblé puis de l'organisateur.
- **litige** : une contestation portant sur une échéance (cycle + membre), une cotisation ou une remise de cagnotte, avec sa résolution.
- **journal_activite** : la trace immuable des actions sensibles d'un groupe ; l'élément concerné est désigné par `type_entite` / `entite_id`, sans clé étrangère, pour rester lisible même si l'élément évolue.
- **notification** : un message adressé à un utilisateur ; `cle_evenement` empêche d'envoyer deux fois la même notification au même utilisateur.
