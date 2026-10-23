-- =====================================================================
-- V1 : schéma initial de Tontine App (cahier des charges, section 4.1)
-- Modules essentiels et importants uniquement (pas ceux de la section 4.3).
--
-- Conventions (section 4.5) :
-- - montants en BIGINT (FCFA entiers) ;
-- - dates métier en DATE, horodatages en DATETIME (fuseau Africa/Porto-Novo) ;
-- - statuts et types en VARCHAR, valeurs contrôlées par CHECK (section 4.2,
--   plus cycle ANNULE et groupe SUPPRIME : aucune suppression physique) ;
-- - colonne version (verrouillage optimiste) sur groupe_tontine, cycle,
--   echeance et cotisation ;
-- - aucune suppression en cascade : les données financières ne sont
--   jamais supprimées physiquement.
-- =====================================================================


-- Compte utilisateur : base de toute identité dans le système.
CREATE TABLE utilisateur (
    id                  BIGINT       NOT NULL AUTO_INCREMENT,
    nom                 VARCHAR(100) NOT NULL,
    prenom              VARCHAR(100) NOT NULL,
    telephone           VARCHAR(20)  NOT NULL,   -- forme normalisée, ex. +2290197000000
    mot_de_passe_hache  VARCHAR(100) NOT NULL,   -- BCrypt, jamais en clair
    email               VARCHAR(255) NULL,
    date_creation       DATETIME     NOT NULL,
    anonymise           BOOLEAN      NOT NULL DEFAULT FALSE,
    nb_echecs_connexion INT          NOT NULL DEFAULT 0,  -- échecs consécutifs (5 = blocage)
    bloque_jusqu_a      DATETIME     NULL,                -- connexion suspendue jusqu'à cette heure
    CONSTRAINT pk_utilisateur PRIMARY KEY (id),
    CONSTRAINT uk_utilisateur_telephone UNIQUE (telephone)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Code ou lien de récupération de compte, à usage unique.
CREATE TABLE reinitialisation_mot_de_passe (
    id               BIGINT       NOT NULL AUTO_INCREMENT,
    utilisateur_id   BIGINT       NOT NULL,
    code_hache       VARCHAR(100) NOT NULL,
    genere_par_id    BIGINT       NULL,          -- organisateur ; vide = lien envoyé par e-mail
    date_creation    DATETIME     NOT NULL,      -- sert à la limite de 3 codes par 24 h
    date_expiration  DATETIME     NOT NULL,
    utilise          BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_reinitialisation_mot_de_passe PRIMARY KEY (id),
    CONSTRAINT fk_reinit_utilisateur FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id),
    CONSTRAINT fk_reinit_genere_par  FOREIGN KEY (genere_par_id)  REFERENCES utilisateur (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Fichier joint (preuve de paiement, justificatif de litige), stocké en base.
CREATE TABLE piece_jointe (
    id              BIGINT       NOT NULL AUTO_INCREMENT,
    nom_fichier     VARCHAR(255) NOT NULL,
    type_mime       VARCHAR(100) NOT NULL,
    taille          BIGINT       NOT NULL,       -- en octets (2 Mo maximum, contrôlé par le service)
    contenu         MEDIUMBLOB   NOT NULL,       -- jusqu'à 16 Mo
    ajoutee_par_id  BIGINT       NOT NULL,
    date_ajout      DATETIME     NOT NULL,
    CONSTRAINT pk_piece_jointe PRIMARY KEY (id),
    CONSTRAINT fk_piece_jointe_ajoutee_par FOREIGN KEY (ajoutee_par_id) REFERENCES utilisateur (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Groupe de tontine et ses règles (cotisation, fréquence, pénalités...).
CREATE TABLE groupe_tontine (
    id                            BIGINT       NOT NULL AUTO_INCREMENT,
    nom                           VARCHAR(100) NOT NULL,
    description                   TEXT         NULL,
    montant_cotisation            BIGINT       NOT NULL,
    frequence                     VARCHAR(20)  NOT NULL,
    date_debut                    DATE         NOT NULL,
    nombre_max_membres            INT          NULL,      -- optionnel
    reglement_interne             TEXT         NULL,
    statut                        VARCHAR(20)  NOT NULL,  -- SUPPRIME : brouillon supprimé (journal conservé)
    code_invitation               VARCHAR(20)  NOT NULL,
    declaration_membre_autorisee  BOOLEAN      NOT NULL DEFAULT FALSE,
    permutation_autorisee         BOOLEAN      NOT NULL DEFAULT FALSE,
    penalite_active               BOOLEAN      NOT NULL DEFAULT FALSE,
    date_activation_penalite      DATE         NULL,      -- pas d'effet rétroactif avant cette date
    type_penalite                 VARCHAR(20)  NULL,
    valeur_penalite               BIGINT       NULL,      -- FCFA par jour, ou pourcentage entier
    jours_grace                   INT          NOT NULL DEFAULT 0,
    plafond_penalite              BIGINT       NULL,      -- optionnel, par échéance
    groupe_origine_id             BIGINT       NULL,      -- tour précédent, en cas de relance
    version                       BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_groupe_tontine PRIMARY KEY (id),
    CONSTRAINT uk_groupe_tontine_code_invitation UNIQUE (code_invitation),
    CONSTRAINT fk_groupe_tontine_origine FOREIGN KEY (groupe_origine_id) REFERENCES groupe_tontine (id),
    CONSTRAINT ck_groupe_tontine_statut CHECK (statut IN ('BROUILLON', 'EN_COURS', 'CLOTURE', 'SUPPRIME')),
    CONSTRAINT ck_groupe_tontine_frequence CHECK (frequence IN ('JOURNALIERE', 'HEBDOMADAIRE', 'MENSUELLE')),
    CONSTRAINT ck_groupe_tontine_type_penalite CHECK (type_penalite IN ('FIXE_PAR_JOUR', 'POURCENTAGE')),
    CONSTRAINT ck_groupe_tontine_montant CHECK (montant_cotisation > 0),
    CONSTRAINT ck_groupe_tontine_penalite_positive CHECK (
        valeur_penalite >= 0 AND plafond_penalite >= 0 AND jours_grace >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Lien entre une personne et un groupe. utilisateur_id vide = membre géré sans compte.
CREATE TABLE adhesion (
    id                     BIGINT       NOT NULL AUTO_INCREMENT,
    groupe_id              BIGINT       NOT NULL,
    utilisateur_id         BIGINT       NULL,
    nom_membre_gere        VARCHAR(200) NULL,
    telephone_membre_gere  VARCHAR(20)  NULL,
    role                   VARCHAR(20)  NOT NULL,
    ordre_passage          INT          NULL,      -- défini avant le démarrage
    statut                 VARCHAR(20)  NOT NULL,
    date_adhesion          DATE         NOT NULL,
    date_sortie            DATE         NULL,
    motif_sortie           VARCHAR(500) NULL,
    CONSTRAINT pk_adhesion PRIMARY KEY (id),
    CONSTRAINT uk_adhesion_groupe_utilisateur UNIQUE (groupe_id, utilisateur_id),  -- une adhésion par groupe
    CONSTRAINT fk_adhesion_groupe      FOREIGN KEY (groupe_id)      REFERENCES groupe_tontine (id),
    CONSTRAINT fk_adhesion_utilisateur FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id),
    CONSTRAINT ck_adhesion_role CHECK (role IN ('ORGANISATEUR', 'CO_ORGANISATEUR', 'TRESORIER', 'MEMBRE')),
    CONSTRAINT ck_adhesion_statut CHECK (statut IN ('ACTIVE', 'RETIREE', 'EXCLUE')),
    -- un membre géré doit au moins avoir un nom
    CONSTRAINT ck_adhesion_identite CHECK (utilisateur_id IS NOT NULL OR nom_membre_gere IS NOT NULL)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Demande d'adhésion par code, ou de rattachement d'un membre géré à un compte.
CREATE TABLE demande_adhesion (
    id              BIGINT      NOT NULL AUTO_INCREMENT,
    utilisateur_id  BIGINT      NOT NULL,
    groupe_id       BIGINT      NOT NULL,
    adhesion_id     BIGINT      NULL,          -- membre géré à rattacher (type RATTACHEMENT)
    type            VARCHAR(20) NOT NULL,
    statut          VARCHAR(20) NOT NULL,
    date_demande    DATETIME    NOT NULL,
    date_decision   DATETIME    NULL,
    CONSTRAINT pk_demande_adhesion PRIMARY KEY (id),
    CONSTRAINT fk_demande_adhesion_utilisateur FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id),
    CONSTRAINT fk_demande_adhesion_groupe      FOREIGN KEY (groupe_id)      REFERENCES groupe_tontine (id),
    CONSTRAINT fk_demande_adhesion_adhesion    FOREIGN KEY (adhesion_id)    REFERENCES adhesion (id),
    CONSTRAINT ck_demande_adhesion_type CHECK (type IN ('ADHESION', 'RATTACHEMENT')),
    CONSTRAINT ck_demande_adhesion_statut CHECK (statut IN ('EN_ATTENTE', 'ACCEPTEE', 'REFUSEE')),
    -- adhésion à rattacher : obligatoire pour un rattachement, vide pour une adhésion
    CONSTRAINT ck_demande_adhesion_cible CHECK (
        (type = 'RATTACHEMENT' AND adhesion_id IS NOT NULL) OR (type = 'ADHESION' AND adhesion_id IS NULL))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Cycle de cotisation et son bénéficiaire. Montants attendu et collecté calculés, non stockés.
CREATE TABLE cycle (
    id                        BIGINT      NOT NULL AUTO_INCREMENT,
    groupe_id                 BIGINT      NOT NULL,
    numero_cycle              INT         NOT NULL,  -- pas unique : les cycles annulés gardent leur numéro
    beneficiaire_adhesion_id  BIGINT      NOT NULL,
    date_debut                DATE        NOT NULL,
    date_fin                  DATE        NOT NULL,
    statut                    VARCHAR(20) NOT NULL,  -- ANNULE : cycle d'un membre sorti avant son tour
    date_cloture              DATETIME    NULL,
    version                   BIGINT      NOT NULL DEFAULT 0,
    CONSTRAINT pk_cycle PRIMARY KEY (id),
    CONSTRAINT fk_cycle_groupe       FOREIGN KEY (groupe_id)                REFERENCES groupe_tontine (id),
    CONSTRAINT fk_cycle_beneficiaire FOREIGN KEY (beneficiaire_adhesion_id) REFERENCES adhesion (id),
    CONSTRAINT ck_cycle_statut CHECK (statut IN ('PLANIFIE', 'EN_COURS', 'EN_ATTENTE_CLOTURE', 'CLOTURE', 'ANNULE')),
    CONSTRAINT ck_cycle_dates CHECK (date_fin >= date_debut)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Ce qu'un membre doit pour un cycle. « En retard » est calculé, non stocké.
CREATE TABLE echeance (
    id           BIGINT      NOT NULL AUTO_INCREMENT,
    cycle_id     BIGINT      NOT NULL,
    adhesion_id  BIGINT      NOT NULL,
    montant_du   BIGINT      NOT NULL,
    date_limite  DATE        NOT NULL,
    statut       VARCHAR(20) NOT NULL,
    version      BIGINT      NOT NULL DEFAULT 0,
    CONSTRAINT pk_echeance PRIMARY KEY (id),
    CONSTRAINT uk_echeance_cycle_adhesion UNIQUE (cycle_id, adhesion_id),  -- une échéance par membre et par cycle
    CONSTRAINT fk_echeance_cycle    FOREIGN KEY (cycle_id)    REFERENCES cycle (id),
    CONSTRAINT fk_echeance_adhesion FOREIGN KEY (adhesion_id) REFERENCES adhesion (id),
    CONSTRAINT ck_echeance_statut CHECK (statut IN ('A_PAYER', 'PARTIEL', 'SOLDEE', 'ANNULEE')),
    CONSTRAINT ck_echeance_montant CHECK (montant_du >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Paiement (ou part de paiement) affecté à une échéance. Jamais modifié : annulé avec un motif.
CREATE TABLE cotisation (
    id                  BIGINT       NOT NULL AUTO_INCREMENT,
    echeance_id         BIGINT       NOT NULL,
    montant             BIGINT       NOT NULL,
    date_paiement       DATE         NOT NULL,
    date_enregistrement DATETIME     NOT NULL,  -- saisie dans l'application (peut suivre le paiement)
    mode_paiement       VARCHAR(20)  NOT NULL,
    reference_paiement  VARCHAR(100) NULL,      -- relie les parts d'un même paiement (excédent réparti)
    statut              VARCHAR(30)  NOT NULL,
    declaree_par_id     BIGINT       NOT NULL,
    validee_par_id      BIGINT       NULL,
    date_validation     DATETIME     NULL,
    motif               VARCHAR(500) NULL,      -- motif de rejet ou d'annulation
    piece_jointe_id     BIGINT       NULL,
    version             BIGINT       NOT NULL DEFAULT 0,
    CONSTRAINT pk_cotisation PRIMARY KEY (id),
    CONSTRAINT fk_cotisation_echeance     FOREIGN KEY (echeance_id)     REFERENCES echeance (id),
    CONSTRAINT fk_cotisation_declaree_par FOREIGN KEY (declaree_par_id) REFERENCES utilisateur (id),
    CONSTRAINT fk_cotisation_validee_par  FOREIGN KEY (validee_par_id)  REFERENCES utilisateur (id),
    CONSTRAINT fk_cotisation_piece_jointe FOREIGN KEY (piece_jointe_id) REFERENCES piece_jointe (id),
    CONSTRAINT ck_cotisation_mode CHECK (mode_paiement IN ('ESPECES', 'MOBILE_MONEY', 'VIREMENT', 'COMPENSATION')),
    CONSTRAINT ck_cotisation_statut CHECK (statut IN ('EN_ATTENTE_VALIDATION', 'VALIDEE', 'REJETEE', 'ANNULEE')),
    CONSTRAINT ck_cotisation_montant CHECK (montant > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE INDEX idx_cotisation_reference ON cotisation (reference_paiement);


-- Pénalité de retard liée à une échéance (une au maximum par échéance).
CREATE TABLE penalite (
    id                 BIGINT       NOT NULL AUTO_INCREMENT,
    echeance_id        BIGINT       NOT NULL,
    montant            BIGINT       NOT NULL,
    date_calcul        DATE         NOT NULL,     -- dernier calcul par la tâche quotidienne
    statut             VARCHAR(20)  NOT NULL,
    date_paiement      DATE         NULL,
    mode_paiement      VARCHAR(20)  NULL,         -- renseigné au paiement
    motif_exoneration  VARCHAR(500) NULL,
    CONSTRAINT pk_penalite PRIMARY KEY (id),
    CONSTRAINT uk_penalite_echeance UNIQUE (echeance_id),  -- une pénalité par échéance
    CONSTRAINT fk_penalite_echeance FOREIGN KEY (echeance_id) REFERENCES echeance (id),
    CONSTRAINT ck_penalite_statut CHECK (statut IN ('DUE', 'PAYEE', 'EXONEREE')),
    CONSTRAINT ck_penalite_mode CHECK (mode_paiement IN ('ESPECES', 'MOBILE_MONEY', 'VIREMENT', 'COMPENSATION')),
    CONSTRAINT ck_penalite_montant CHECK (montant >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Argent remis par le groupe à un membre : remise de cagnotte ou restitution après départ.
CREATE TABLE versement (
    id                         BIGINT       NOT NULL AUTO_INCREMENT,
    groupe_id                  BIGINT       NOT NULL,
    adhesion_id                BIGINT       NOT NULL,   -- membre qui reçoit l'argent
    cycle_id                   BIGINT       NULL,       -- obligatoire pour une remise de cagnotte
    type                       VARCHAR(20)  NOT NULL,
    montant                    BIGINT       NOT NULL,
    date_versement             DATE         NOT NULL,
    mode_versement             VARCHAR(20)  NOT NULL,
    enregistre_par_id          BIGINT       NOT NULL,
    confirme_par_beneficiaire  BOOLEAN      NOT NULL DEFAULT FALSE,
    date_confirmation          DATETIME     NULL,
    statut                     VARCHAR(20)  NOT NULL,
    motif_annulation           VARCHAR(500) NULL,
    CONSTRAINT pk_versement PRIMARY KEY (id),
    CONSTRAINT fk_versement_groupe         FOREIGN KEY (groupe_id)         REFERENCES groupe_tontine (id),
    CONSTRAINT fk_versement_adhesion       FOREIGN KEY (adhesion_id)       REFERENCES adhesion (id),
    CONSTRAINT fk_versement_cycle          FOREIGN KEY (cycle_id)          REFERENCES cycle (id),
    CONSTRAINT fk_versement_enregistre_par FOREIGN KEY (enregistre_par_id) REFERENCES utilisateur (id),
    CONSTRAINT ck_versement_type CHECK (type IN ('REMISE_CAGNOTTE', 'RESTITUTION')),
    CONSTRAINT ck_versement_statut CHECK (statut IN ('ENREGISTRE', 'ANNULE')),
    CONSTRAINT ck_versement_mode CHECK (mode_versement IN ('ESPECES', 'MOBILE_MONEY', 'VIREMENT')),
    CONSTRAINT ck_versement_montant CHECK (montant > 0),
    CONSTRAINT ck_versement_cycle CHECK (type <> 'REMISE_CAGNOTTE' OR cycle_id IS NOT NULL)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Demande de permutation de tours entre deux membres.
CREATE TABLE echange_tour (
    id                            BIGINT      NOT NULL AUTO_INCREMENT,
    groupe_id                     BIGINT      NOT NULL,
    adhesion_demandeur_id         BIGINT      NOT NULL,
    adhesion_cible_id             BIGINT      NOT NULL,
    cycle_demandeur_id            BIGINT      NOT NULL,
    cycle_cible_id                BIGINT      NOT NULL,
    statut                        VARCHAR(30) NOT NULL,
    date_demande                  DATETIME    NOT NULL,
    date_reponse_cible            DATETIME    NULL,
    date_validation_organisateur  DATETIME    NULL,
    CONSTRAINT pk_echange_tour PRIMARY KEY (id),
    CONSTRAINT fk_echange_tour_groupe             FOREIGN KEY (groupe_id)             REFERENCES groupe_tontine (id),
    CONSTRAINT fk_echange_tour_adhesion_demandeur FOREIGN KEY (adhesion_demandeur_id) REFERENCES adhesion (id),
    CONSTRAINT fk_echange_tour_adhesion_cible     FOREIGN KEY (adhesion_cible_id)     REFERENCES adhesion (id),
    CONSTRAINT fk_echange_tour_cycle_demandeur    FOREIGN KEY (cycle_demandeur_id)    REFERENCES cycle (id),
    CONSTRAINT fk_echange_tour_cycle_cible        FOREIGN KEY (cycle_cible_id)        REFERENCES cycle (id),
    CONSTRAINT ck_echange_tour_statut CHECK (statut IN ('EN_ATTENTE_CIBLE', 'EN_ATTENTE_ORGANISATEUR', 'VALIDEE', 'REFUSEE', 'EXPIREE')),
    CONSTRAINT ck_echange_tour_distincts CHECK (adhesion_demandeur_id <> adhesion_cible_id AND cycle_demandeur_id <> cycle_cible_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Contestation formelle sur une échéance, une cotisation ou une remise de cagnotte.
CREATE TABLE litige (
    id                     BIGINT      NOT NULL AUTO_INCREMENT,
    cycle_id               BIGINT      NOT NULL,
    adhesion_concernee_id  BIGINT      NOT NULL,
    cotisation_id          BIGINT      NULL,       -- cotisation contestée, le cas échéant
    versement_id           BIGINT      NULL,       -- remise contestée, le cas échéant
    ouvert_par_id          BIGINT      NOT NULL,
    arbitre_id             BIGINT      NULL,
    description            TEXT        NOT NULL,
    piece_jointe_id        BIGINT      NULL,
    statut                 VARCHAR(30) NOT NULL,
    resolution             TEXT        NULL,
    desaccord_plaignant    TEXT        NULL,       -- si l'organisateur, partie au litige, a tranché
    date_ouverture         DATETIME    NOT NULL,
    date_resolution        DATETIME    NULL,
    CONSTRAINT pk_litige PRIMARY KEY (id),
    CONSTRAINT fk_litige_cycle              FOREIGN KEY (cycle_id)              REFERENCES cycle (id),
    CONSTRAINT fk_litige_adhesion_concernee FOREIGN KEY (adhesion_concernee_id) REFERENCES adhesion (id),
    CONSTRAINT fk_litige_cotisation         FOREIGN KEY (cotisation_id)         REFERENCES cotisation (id),
    CONSTRAINT fk_litige_versement          FOREIGN KEY (versement_id)          REFERENCES versement (id),
    CONSTRAINT fk_litige_ouvert_par         FOREIGN KEY (ouvert_par_id)         REFERENCES utilisateur (id),
    CONSTRAINT fk_litige_arbitre            FOREIGN KEY (arbitre_id)            REFERENCES utilisateur (id),
    CONSTRAINT fk_litige_piece_jointe       FOREIGN KEY (piece_jointe_id)       REFERENCES piece_jointe (id),
    CONSTRAINT ck_litige_statut CHECK (statut IN ('OUVERT', 'EN_ATTENTE_PRECISIONS', 'ACCEPTE', 'REJETE', 'AJUSTE'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;


-- Trace immuable des actions sensibles. L'élément concerné est désigné par
-- type_entite / entite_id, sans clé étrangère (section 4.4).
CREATE TABLE journal_activite (
    id           BIGINT      NOT NULL AUTO_INCREMENT,
    groupe_id    BIGINT      NOT NULL,
    auteur_id    BIGINT      NULL,          -- vide = « Système »
    action       VARCHAR(50) NOT NULL,
    type_entite  VARCHAR(50) NULL,
    entite_id    BIGINT      NULL,
    details      TEXT        NULL,
    date_action  DATETIME    NOT NULL,
    CONSTRAINT pk_journal_activite PRIMARY KEY (id),
    CONSTRAINT fk_journal_activite_groupe FOREIGN KEY (groupe_id) REFERENCES groupe_tontine (id),
    CONSTRAINT fk_journal_activite_auteur FOREIGN KEY (auteur_id) REFERENCES utilisateur (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- Consultation du journal d'un groupe, du plus récent au plus ancien
CREATE INDEX idx_journal_activite_groupe_date ON journal_activite (groupe_id, date_action);


-- Notification adressée à un utilisateur. cle_evenement empêche les doublons.
CREATE TABLE notification (
    id              BIGINT       NOT NULL AUTO_INCREMENT,
    utilisateur_id  BIGINT       NOT NULL,
    groupe_id       BIGINT       NULL,      -- vide pour une notification liée au compte
    type            VARCHAR(50)  NOT NULL,  -- valeurs non fixées par le cahier
    contenu         VARCHAR(500) NOT NULL,
    lien            VARCHAR(255) NULL,
    lu              BOOLEAN      NOT NULL DEFAULT FALSE,
    date_envoi      DATETIME     NOT NULL,
    email_envoye    BOOLEAN      NOT NULL DEFAULT FALSE,
    cle_evenement   VARCHAR(150) NULL,
    CONSTRAINT pk_notification PRIMARY KEY (id),
    -- un même événement n'est notifié qu'une fois à un même utilisateur
    CONSTRAINT uk_notification_utilisateur_cle UNIQUE (utilisateur_id, cle_evenement),
    CONSTRAINT fk_notification_utilisateur FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id),
    CONSTRAINT fk_notification_groupe      FOREIGN KEY (groupe_id)      REFERENCES groupe_tontine (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;
