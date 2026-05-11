---
stepsCompleted: ["requirements-extraction", "epics-design", "stories-creation"]
inputDocuments:
  - "docs/reference-champs-ht2-acte.md"
  - "Downloads/2_Liste_données_visas_anaco T2_20260507.xlsx"
  - "conversation analysis: schéma BDD T2 (2026-05-11)"
feature: "Intégration des actes T2 (Hors contrat)"
status: "ready-for-dev"
---

# avisbop — Intégration des actes T2

## Overview

Ce document décrit les épics et stories pour l'intégration des actes T2 "Autres actes" (anciennement "Hors contrat") dans l'application avisbop. Actuellement seuls les actes HT2 existent. Cette feature ajoute un nouveau type d'acte T2 avec ses propres natures (Concours, ISP, Fongibilité asymétrique, Marché PSC, Enveloppe limitative, Mesure transversale, Référentiel) et ses champs spécifiques, tout en partageant la structure commune (périmètre, type de contrôle, workflow 3 étapes, décision, suspension).

## Architecture décidée

- **Table `actes`** = renommage de `ht2_actes`, garde tous les champs actuels + colonne `titre` ('HT2' | 'T2') + colonne `categorie_t2` ('contrat' | 'hors_contrat') — distinct de `categorie` qui existe déjà dans la table HT2
- **Table `t2_details`** = champs spécifiques T2 (ISP, FA, Concours, contrôles RH, etc.), liée par `has_one :t2_detail`
- **Pas de table `ht2_details`** : les champs HT2 restent dans `actes`, les NULL pour les actes T2 sont acceptables
- Associations `suspensions`, `echeanciers`, `poste_lignes` inchangées
- Routes et URLs migrées vers `/actes` (pas de compatibilité `/ht2_actes` conservée)

## Requirements Inventory

### Functional Requirements

FR1: Un utilisateur peut créer un acte en choisissant le titre HT2 ou T2 depuis le modal "Nouvel acte"
FR2: Pour un acte T2, l'utilisateur choisit la catégorie : Contrat ou Hors contrat
FR3: Pour un acte T2 Hors contrat, l'utilisateur choisit la nature parmi : Concours, ISP, Fongibilité asymétrique, Marché (PSC), Enveloppe limitative, Mesure transversale, Référentiel
FR4: Le formulaire étape 1 affiche les champs communs (périmètre, type de contrôle, organisme, exercice, date de saisine, instructeur, etc.) pour tous les actes T2
FR5: Le formulaire étape 1 affiche les champs spécifiques à la nature sélectionnée (sections dynamiques)
FR6: Le formulaire étape 2 (critères de contrôle) affiche les critères adaptés à la nature T2 sélectionnée
FR7: Le formulaire étape 3 (décision) est identique à celui des actes HT2
FR8: Les actes T2 sont listés dans le tableau de bord avec indication du titre (T2) et de la nature
FR9: Les filtres de recherche permettent de filtrer par titre (HT2/T2), catégorie et nature
FR10: L'export Excel (index et historique) inclut les actes T2 avec leurs champs spécifiques
FR11: Les actes T2 peuvent être suspendus/repris avec le même mécanisme que HT2
FR12: La numérotation des actes T2 suit le même format que HT2 (avec séquence propre ou partagée, à confirmer)
FR13: L'admin peut visualiser et gérer les actes T2 dans ActiveAdmin
FR14: Les actes T2 peuvent être importés depuis Excel (mapping des champs)
FR15: Le PDF généré pour un acte T2 reflète la nature et les champs spécifiques

### Non-Functional Requirements

NFR1: Le renommage `ht2_actes` → `actes` ne doit causer aucune régression sur les actes HT2 existants
NFR2: Toutes les URLs sont migrées vers `/actes/...` — les anciennes URLs `/ht2_actes/...` ne sont pas conservées
NFR3: La migration de renommage doit être réversible (rollback possible)
NFR4: Les exports Excel doivent rester performants avec le volume combiné HT2+T2
NFR5: Le formulaire T2 doit suivre le même standard d'accessibilité DSFR que le formulaire HT2

### Additional Requirements

- Le modal "Nouvel acte" existant doit être étendu avec le sélecteur HT2/T2
- Le controller `ht2_actes_controller.rb` sera renommé `actes_controller.rb`
- Le modèle `Ht2Acte` sera renommé `Acte` (ou alias conservé pour compatibilité)
- Les routes devront être mises à jour
- ActiveAdmin : `admin/ht2_actes.rb` → `admin/actes.rb`
- Le Stimulus controller `acte_form_controller.js` devra gérer la logique conditionnelle T2
- Les vues partielles HT2 existantes devront être réutilisées/étendues pour T2

### FR Coverage Map

| FR | Epic | Story |
|----|------|-------|
| FR1 | E1 | 1.3 |
| FR2 | E1 | 1.3 |
| FR3 | E1 | 1.3 |
| FR4 | E2 | 2.1 |
| FR5 | E2 | 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8 |
| FR6 | E2 | 2.9 |
| FR7 | E2 | 2.10 |
| FR8 | E3 | 3.1 |
| FR9 | E3 | 3.2 |
| FR10 | E3 | 3.3 |
| FR11 | E2 | 2.11 |
| FR12 | E1 | 1.4 |
| FR13 | E3 | 3.4 |
| FR14 | E4 | 4.1 |
| FR15 | E4 | 4.2 |

---

## Epic List

- **Epic 1 — Fondations BDD et modèle** : Renommage de la table, migration, modèle `Acte`, routes, controller
- **Epic 2 — Formulaire de saisie T2** : Wizard 3 étapes pour les actes T2, champs communs + sections par nature
- **Epic 3 — Liste, filtres et exports** : Tableau de bord, filtres, exports Excel incluant T2
- **Epic 4 — Fonctions avancées** : Import Excel T2, génération PDF T2, ActiveAdmin

---

## Epic 1: Fondations BDD et modèle

Mettre en place la structure de données et le modèle Rails pour supporter les actes T2, sans régression sur les actes HT2 existants.

### Story 1.1: Renommer la table `ht2_actes` en `actes`

En tant que développeuse,
Je veux renommer la table `ht2_actes` en `actes` et ajouter les colonnes `titre` et `categorie`,
Afin que la table puisse accueillir à la fois les actes HT2 et T2.

**Acceptance Criteria:**

**Given** la table `ht2_actes` existe avec des données
**When** la migration est exécutée
**Then** la table est renommée `actes`
**And** une colonne `titre` string est ajoutée avec valeur par défaut `'HT2'`
**And** une colonne `categorie_t2` string est ajoutée (nullable, pour T2 uniquement : 'contrat' | 'hors_contrat') — nommée `categorie_t2` pour ne pas entrer en conflit avec la colonne `categorie` déjà existante
**And** tous les enregistrements HT2 existants ont `titre = 'HT2'` et `categorie_t2 = NULL`
**And** `db:rollback` remet l'état initial sans perte de données

---

### Story 1.2: Créer la table `t2_details`

En tant que développeuse,
Je veux créer la table `t2_details` avec tous les champs spécifiques aux actes T2,
Afin de stocker les données métier propres aux différentes natures T2.

**Acceptance Criteria:**

**Given** la migration est exécutée
**When** la table `t2_details` est créée
**Then** elle contient les colonnes suivantes :

*Identification*
- `acte_id` (references, foreign key → actes)

*Section Annexe financière (concours / RH)*
- `effectifs` (float) — liste principale
- `effectifs_complementaire` (float)
- `corps` (string)
- `grade` (string[], array PostgreSQL)
- `date_arrete_concours` (date)
- `date_effet_acte` (string)
- `impact_schema_emplois` (boolean)
- `impact_autre_cbcm` (boolean)

*Section ISP*
- `isp_cercle1` (boolean)
- `isp_cercle1_natures` (string[], array)
- `isp_cercle1_montant` (decimal)
- `isp_cercle1_enveloppe_sgg` (decimal)
- `isp_cercle1_consommation` (decimal)
- `isp_cercle2` (boolean)
- `isp_cercle2_natures` (string[], array)
- `isp_cercle2_montant` (decimal)
- `isp_cercle2_enveloppe_sgg` (decimal)
- `isp_cercle2_consommation` (decimal)

*Section Fongibilité asymétrique*
- `fa_technique` (boolean)
- `enveloppe_abondee` (string)
- `accord_rffim` (boolean)
- `sollicitation_db` (string)
- `avis_cbcm` (boolean)

*Section Mesure transversale*
- `perimetre_mesure` (string[], array)
- `statut_agents` (string)
- `impact_financier_n1` (decimal)
- `origine_financement` (string[], array) — cases à cocher, partagé avec Enveloppe limitative

*Section Enveloppe limitative*
- `montant_enveloppe_n1` (decimal) — montant enveloppe N-1
- `impact_maximal_sans_enveloppe` (decimal)
- (origine_financement partagé avec Mesure transversale ci-dessus)

*Section Référentiel*
- `referentiel_type` (string) # 'interministeriel' | 'autre'

*Contrôles RH communs T2 (étape 2)*
- `inscription_pap` (boolean)
- `respect_plafond_emplois` (boolean)
- `respect_schema_emplois` (boolean)
- `controle_modalites` (boolean)
- `consommation_credits` (boolean) — réutilise la sémantique du critère HT2 "Exactitude de l'évaluation de la consommation des crédits"
- `respect_enveloppe` (boolean)
- `risque_reconventionnel` (boolean)

**And** un index unique sur `acte_id` est créé

---

### Story 1.3: Mettre à jour le modèle `Acte` (renommé depuis `Ht2Acte`)

En tant que développeuse,
Je veux renommer le modèle `Ht2Acte` en `Acte` avec toutes ses associations et validations,
Afin que le code Rails reflète la nouvelle structure.

**Acceptance Criteria:**

**Given** le modèle `Ht2Acte` existe dans `app/models/ht2_acte.rb`
**When** le refactoring est effectué
**Then** le fichier est renommé `app/models/acte.rb` avec la classe `Acte`
**And** le modèle a `has_one :t2_detail, dependent: :destroy`
**And** la validation `titre` accepte uniquement `['HT2', 'T2']`
**And** la validation `categorie_t2` accepte `['contrat', 'hors_contrat', nil]`
**And** toutes les associations existantes (`suspensions`, `echeanciers`, `poste_lignes`, `user`, etc.) sont préservées
**And** un alias `Ht2Acte = Acte` est ajouté pour compatibilité temporaire avec ActiveAdmin
**And** les specs du modèle passent sans modification (ou sont mis à jour)

---

### Story 1.4: Mettre à jour le controller, les routes et les vues

En tant que développeuse,
Je veux mettre à jour le controller `ht2_actes_controller.rb`, les routes et les références dans les vues,
Afin que l'application utilise le nouveau modèle `Acte` sans régression.

**Acceptance Criteria:**

**Given** le controller et les routes référencent `Ht2Acte` et `ht2_actes`
**When** le refactoring est effectué
**Then** le controller est renommé `actes_controller.rb` avec la classe `ActesController`
**And** les routes utilisent `/actes` (plus de `/ht2_actes`) — toutes les URLs sont mises à jour
**And** le dossier `app/views/ht2_actes/` est renommé `app/views/actes/`
**And** `app/admin/ht2_actes.rb` est renommé `app/admin/actes.rb`
**And** toutes les références `Ht2Acte` / `ht2_acte` / `ht2_actes` dans le code sont remplacées par `Acte` / `acte` / `actes`
**And** les tests d'intégration existants passent

---

## Epic 2: Formulaire de saisie T2

Créer le wizard 3 étapes pour la saisie des actes T2, avec les champs communs et les sections dynamiques par nature.

### Story 2.1: Étendre le modal "Nouvel acte" avec le sélecteur T2

En tant qu'instructeur,
Je veux choisir entre HT2 et T2 dans le modal de création d'un nouvel acte,
Afin de démarrer la saisie du bon type d'acte.

**Acceptance Criteria:**

**Given** je clique sur "Nouvel acte" dans le tableau de bord
**When** le modal s'ouvre
**Then** je vois le sélecteur "Titre" : HT2 / T2 (boutons radio, en haut du modal, HT2 sélectionné par défaut)
**And** le sélecteur "Périmètre" est toujours présent : État / Organisme
**And** le sélecteur "Type de contrôle" est toujours présent : Avis / Visa (les deux options disponibles quel que soit le périmètre, pour HT2 comme pour T2)
**And** le bloc "État de l'acte" (En instruction / En pré-instruction) est toujours présent et inchangé
**And** si Titre = T2, un sélecteur "Catégorie" apparaît : Contrat / Hors contrat (correspond au champ `categorie_t2`)
**And** si Titre = HT2, le sélecteur "Catégorie" n'est pas affiché
**And** la validation du modal permet de continuer vers le formulaire étape 1 une fois tous les champs obligatoires remplis

Note : La catégorie "Contrat" pour T2 est hors périmètre de cette feature (future itération).

---

### Story 2.2: Formulaire T2 étape 1 — Champs communs

En tant qu'instructeur,
Je veux saisir les informations communes d'un acte T2 Hors contrat à l'étape 1,
Afin d'identifier l'acte et déclencher les délais de traitement.

**Acceptance Criteria:**

**Given** j'ai sélectionné T2 / Hors contrat dans le modal
**When** le formulaire étape 1 s'affiche
**Then** le périmètre, le type de contrôle et la catégorie T2 choisis dans le modal sont affichés en lecture seule (non modifiables à cette étape)
**And** les champs de saisie suivants sont présents :
- Nature de l'acte (liste déroulante, valeur stockée entre parenthèses non incluse) — obligatoire, options filtrées selon périmètre et profil :
  - Si périmètre = État **ET** profil = DCB : liste complète (Annexe financière, Enveloppe limitative, Fongibilité asymétrique, ISP, Marché, Mesure transversale, Référentiel)
  - Si périmètre = État **ET** profil = CBR : Fongibilité asymétrique uniquement
  - Si périmètre = Organisme (tous profils) : Annexe financière, Enveloppe limitative, Fongibilité asymétrique, Marché, Mesure transversale, Référentiel (ISP exclu)
- Si périmètre = État : Centre financier (`centre_financier_code`) — obligatoire selon nature
- Si périmètre = Organisme : Nom de l'organisme (`nom_organisme`) — obligatoire
- Exercice — obligatoire
- Date de saisine — obligatoire (sauf pré-instruction)
- Instructeur — obligatoire
- Service ordonnateur — optionnel
- Objet — optionnel
- Précisions sur l'acte — optionnel
- Services votés (case à cocher)
- Si périmètre = Organisme uniquement :
  - Budget exécutoire (`budget_executoire`, case à cocher)
  - Délibération en CA nécessaire (`deliberation_ca`, case à cocher, décochée par défaut) — si coché : affichage de `numero_deliberation_ca`, `date_deliberation_ca`, `observations_deliberation_ca`

**And** la sélection de la nature affiche/masque une section de champs spécifiques (stories 2.3 à 2.8)
**And** le numéro d'acte est généré automatiquement à la sauvegarde
**And** la date limite de traitement est calculée automatiquement (J+15 dès qu'un instructeur est saisi)

---

### Story 2.3: Section spécifique — Nature "Annexe financière"

En tant qu'instructeur,
Je veux saisir les champs spécifiques d'un acte T2 de nature "Annexe financière",
Afin de documenter les informations RH nécessaires au contrôle (concours, recrutements).

**Acceptance Criteria:**

**Given** j'ai sélectionné la nature "Annexe financière" à l'étape 1
**When** la section Annexe financière apparaît
**Then** les champs suivants sont affichés :
- Type d'engagement (Initial / Complémentaire) — obligatoire (uniquement pour cette nature)
- Effectifs (décimal, liste principale) — obligatoire
- Effectifs liste complémentaire (décimal) — optionnel
- Grade(s) (multi-select) — optionnel
- Corps (champ libre) — optionnel
- Date de l'arrêté autorisant l'ouverture du concours (date) — optionnel
- Date d'effet de l'acte (champ libre) — optionnel
- Impact sur le schéma d'emplois (case à cocher) — obligatoire
- Si périmètre = État : Impact autre CBCM (`impact_autre_cbcm`, case à cocher) — obligatoire
- Si périmètre = Organisme : Impact autre CBR (`impact_autre_cbcm`, même champ, case à cocher) — obligatoire

**And** ces données sont sauvegardées dans la table `t2_details`

---

### Story 2.4: Section spécifique — Nature "ISP"

En tant qu'instructeur,
Je veux saisir les champs spécifiques d'un acte T2 de nature "ISP",
Afin de documenter les indemnités spéciales de participation par cercle.

**Acceptance Criteria:**

**Given** j'ai sélectionné la nature "ISP" à l'étape 1
**When** la section ISP apparaît
**Then** les champs suivants sont affichés :
- Date d'effet de l'acte (champ libre) — optionnel

**And** les champs Cercle 1 sont affichés :
- Case "Cercle 1 présent" — obligatoire
- Si coché : Nature(s) des ISP (cases à cocher) — optionnel
- Si coché : Montant au contrôle (décimal) — obligatoire si cercle présent
- Si coché : Montant annuel enveloppe SGG (décimal) — obligatoire si cercle présent
- Si coché : Consommation à date (décimal) — optionnel
- Reste à consommer : calculé automatiquement (enveloppe - consommation)

**And** les mêmes champs existent pour Cercle 2
**And** les calculs "Reste à consommer" sont mis à jour en temps réel (Stimulus)
**And** ces données sont sauvegardées dans `t2_details`

---

### Story 2.5: Section spécifique — Nature "Fongibilité asymétrique"

En tant qu'instructeur,
Je veux saisir les champs spécifiques d'un acte T2 de nature "Fongibilité asymétrique",
Afin de documenter les autorisations préalables requises.

**Acceptance Criteria:**

**Given** j'ai sélectionné la nature "Fongibilité asymétrique"
**When** la section FA apparaît
**Then** les champs suivants sont affichés :
- Montant au contrôle (`montant_ae`, décimal) — obligatoire
- Si périmètre = État : N° CHORUS (`numero_chorus`, champ libre) — optionnel
- FA Technique (`fa_technique`, case à cocher) — obligatoire
- Si périmètre = Organisme : Enveloppe budgétaire abondée (`enveloppe_abondee`, liste déroulante) — optionnel
- Si périmètre = État et statut user = DCB : Accord RFFIM/RPROG préalable (`accord_rffim`, case à cocher) — obligatoire
- Si périmètre = État et statut user = DCB : Sollicitation DB/BS préalable (`sollicitation_db`, liste déroulante) — obligatoire
- Si périmètre = État et statut user = CBR : Avis CBCM (`avis_cbcm`, case à cocher) — obligatoire

**And** ces données sont sauvegardées dans `t2_details`

---

### Story 2.6: Section spécifique — Nature "Marché (PSC)"

En tant qu'instructeur,
Je veux saisir les champs spécifiques d'un acte T2 de nature "Marché (PSC)",
Afin de documenter les informations du marché soumis au visa.

**Acceptance Criteria:**

**Given** j'ai sélectionné la nature "Marché (PSC)"
**When** la section Marché apparaît
**Then** les champs suivants sont affichés :
- Montant au contrôle (`montant_ae`, décimal) — obligatoire
- Si périmètre = Organisme : Opération budgétaire (`operation_budgetaire`, liste déroulante) — optionnel
- Bénéficiaire (`beneficiaire`, champ libre) — optionnel

**And** ces données sont sauvegardées dans les champs correspondants de `actes`

---

### Story 2.7: Section spécifique — Nature "Mesure transversale"

En tant qu'instructeur,
Je veux saisir les champs spécifiques d'un acte T2 de nature "Mesure transversale",
Afin de documenter l'impact RH et financier de la mesure.

**Acceptance Criteria:**

**Given** j'ai sélectionné la nature "Mesure transversale"
**When** la section Mesure transversale apparaît
**Then** les champs suivants sont affichés :
- Périmètre de la mesure (`perimetre_mesure`, multi-select liste déroulante) — optionnel
- Grade(s) (`grade`, multi-select, même champ que Annexe financière) — optionnel
- Corps (champ libre) — optionnel
- Effectifs année N (champ libre) — optionnel
- Effectifs année N+1 (champ libre) — optionnel
- Statut d'agents (`statut_agents`, liste déroulante) — optionnel
- Montant au contrôle (`montant_ae`) — optionnel
- Impact financier N+1 (`impact_financier_n1`) — optionnel
- Origine de financement (`origine_financement`, cases à cocher) — optionnel
- Date d'effet de l'acte (`date_effet_acte`, champ libre) — optionnel
- Si périmètre = Organisme : Opération budgétaire (`operation_budgetaire`, liste déroulante) — optionnel

**And** ces données sont sauvegardées dans `t2_details` (sauf `montant_ae` et `operation_budgetaire` dans `actes`)

---

### Story 2.8: Sections spécifiques — Natures "Enveloppe limitative" et "Référentiel"

En tant qu'instructeur,
Je veux saisir les champs spécifiques des natures "Enveloppe limitative" et "Référentiel",
Afin de documenter ces types d'actes moins complexes.

**Acceptance Criteria:**

**Given** j'ai sélectionné "Enveloppe limitative"
**When** la section apparaît
**Then** les champs suivants sont affichés :
- Périmètre de la mesure (`perimetre_mesure`, multi-select liste déroulante) — optionnel
- Grade(s) (`grade`, multi-select, même champ que Annexe financière) — optionnel
- Corps (champ libre) — optionnel
- Effectifs année N (champ libre) — optionnel
- Effectifs année N+1 (champ libre) — optionnel
- Statut d'agents (`statut_agents`, liste déroulante) — optionnel
- Montant au contrôle (`montant_ae`) — optionnel
- Si périmètre = État : Origine de financement (`origine_financement`, cases à cocher) — optionnel
- Montant enveloppe N-1 (`montant_enveloppe_n1`, montant) — optionnel
- Impact maximal sans enveloppe (`impact_maximal_sans_enveloppe`, montant) — optionnel
- Effet de l'enveloppe (% calculé automatiquement : impact / enveloppe N-1) — affiché en lecture seule
- Date d'effet de l'acte (`date_effet_acte`, champ libre) — optionnel

**Given** j'ai sélectionné "Référentiel"
**When** la section apparaît
**Then** les champs suivants sont affichés :
- Type (`referentiel_type` : Interministériel / Autre référentiel) — obligatoire
- Périmètre de la mesure (`perimetre_mesure`, multi-select liste déroulante) — optionnel
- Grade(s) (`grade`, multi-select) — optionnel
- Corps (champ libre) — optionnel
- Effectifs année N (champ libre) — optionnel
- Effectifs année N+1 (champ libre) — optionnel
- Montant au contrôle (`montant_ae`) — optionnel
- Impact financier N+1 (`impact_financier_n1`) — optionnel
- Origine de financement (`origine_financement`, cases à cocher) — optionnel
- Date d'effet de l'acte (`date_effet_acte`, champ libre) — optionnel

---

### Story 2.9: Formulaire T2 étape 2 — Critères de contrôle

En tant qu'instructeur,
Je veux renseigner les critères de contrôle d'un acte T2 à l'étape 2,
Afin de documenter mon analyse avant de proposer une décision.

**Acceptance Criteria:**

**Given** j'ai complété l'étape 1 d'un acte T2
**When** j'accède à l'étape 2
**Then** les critères suivants sont affichés sous forme de cases à cocher (boolean), chacun selon ses conditions d'affichage :

| Critère | Champ | Condition d'affichage |
|---------|-------|-----------------------|
| Inscription au PAP / Plan de recrutement | `inscription_pap` (`t2_details`) | périmètre = État **ET** nature ∈ {Annexe financière, Mesure transversale, Référentiel} |
| Respect du plafond d'emplois | `respect_plafond_emplois` (`t2_details`) | nature = Annexe financière |
| Respect du schéma d'emplois | `respect_schema_emplois` (`t2_details`) | nature = Annexe financière **ET** `impact_schema_emplois` = true (coché en étape 1) |
| Contrôle des modalités de mise en œuvre | `controle_modalites` (`t2_details`) | nature = Fongibilité asymétrique **ET** périmètre = État **ET** profil user = DCB |
| Exactitude de l'évaluation de la consommation des crédits | `consommation_credits` (`t2_details`) | nature ∈ {Fongibilité asymétrique, Marché, Mesure transversale} |
| Respect de l'enveloppe notifiée | `respect_enveloppe` (`t2_details`) | nature = ISP |
| Risque d'effet reconventionnel | `risque_reconventionnel` (`t2_details`) | nature ∈ {Mesure transversale, Référentiel} |
| L'acte figure dans le dernier document de programmation | `programmation_prevue` (`actes`) | nature ∉ {ISP} **ET** NOT (nature = Fongibilité asymétrique **ET** périmètre = Organisme) |
| Opération autorisée par les autorités de tutelle | `autorisation_tutelle` (`actes`) | nature ∉ {ISP, Fongibilité asymétrique} **ET** périmètre = Organisme **ET** `budget_executoire` = false |
| Programmation initiale transmise | `avis_programmation` (`actes`) | nature ≠ ISP **ET** périmètre = État |
| Compatibilité avec la programmation annuelle et pluriannuelle | `programmation` (`actes`) | nature ∉ {ISP} **ET** NOT (nature = Fongibilité asymétrique **ET** périmètre = Organisme) **ET** (`services_votes` = false) **ET** (périmètre = État → `avis_programmation` cochée ; périmètre = Organisme → `budget_executoire` = true) |
| Soutenabilité des crédits | `soutenabilite` (`actes`) | nature ≠ Annexe financière |
| Acte éligible à la gestion des services votés | `programmation` (`actes`) | `services_votes` = true |

**And** les critères sauvegardés dans `t2_details` sont : `inscription_pap`, `respect_plafond_emplois`, `respect_schema_emplois`, `controle_modalites`, `consommation_credits`, `respect_enveloppe`, `risque_reconventionnel`
**And** les critères sauvegardés dans `actes` réutilisent les colonnes HT2 existantes : `programmation_prevue`, `autorisation_tutelle`, `avis_programmation`, `programmation`, `soutenabilite`
**And** un champ "Observations et pièces justificatives" (texte + PJ) est disponible
**And** un champ "Tableur" (upload fichier) est disponible

---

### Story 2.10: Formulaire T2 étape 3 — Décision

En tant qu'instructeur / valideur,
Je veux accéder à l'étape 3 de décision d'un acte T2,
Afin de saisir la proposition et la décision finale de contrôle.

**Acceptance Criteria:**

**Given** j'accède à l'étape 3 d'un acte T2
**When** la page s'affiche
**Then** les champs sont identiques à ceux du formulaire HT2 étape 3 :
- Proposition de décision de contrôle (liste déroulante) — obligatoire
- Commentaire interne sur la décision — optionnel
- Proposition d'observation à l'ordonnateur — optionnel
- Type d'observations — optionnel
- Initiales du valideur — obligatoire pour validation
- Décision finale — obligatoire pour clôture
- Date de clôture

**And** le workflow de statut (en instruction → proposé → validé → clôturé) fonctionne identiquement à HT2
**And** les données sont sauvegardées dans la table `actes`

---

### Story 2.11: Suspension et reprise d'un acte T2

En tant qu'instructeur,
Je veux pouvoir suspendre et reprendre un acte T2,
Afin de gérer les interruptions du délai de traitement.

**Acceptance Criteria:**

**Given** un acte T2 est en cours d'instruction
**When** je clique sur "Suspendre"
**Then** le formulaire de suspension s'affiche (date, motif, observations) — identique à HT2
**And** la suspension est enregistrée dans la table `suspensions` avec `acte_id`
**And** la reprise fonctionne de la même manière

---

## Epic 3: Liste, filtres et exports

Intégrer les actes T2 dans le tableau de bord, les filtres de recherche et les exports Excel.

### Story 3.1: Affichage des actes T2 dans le tableau de bord

En tant qu'instructeur,
Je veux voir les actes T2 dans mon tableau de bord aux côtés des actes HT2,
Afin d'avoir une vue consolidée de tous mes actes.

**Acceptance Criteria:**

**Given** des actes HT2 et T2 existent dans la base
**When** j'accède au tableau de bord
**Then** les actes T2 apparaissent dans la liste
**And** une colonne "Titre" (ou badge) indique HT2 ou T2
**And** le tri et la pagination fonctionnent sur l'ensemble HT2+T2

---

### Story 3.2: Filtres de recherche incluant T2

En tant qu'instructeur,
Je veux filtrer les actes par titre et nature,
Afin de retrouver rapidement les actes T2 ou HT2 qui m'intéressent.

**Acceptance Criteria:**

**Given** je suis sur le tableau de bord
**When** j'utilise les filtres
**Then** un filtre "Titre" permet de sélectionner HT2, T2 ou les deux
**And** un filtre "Nature" (conditionnel à T2) liste les 7 natures T2
**And** les filtres existants (périmètre, type de contrôle, état, exercice, etc.) s'appliquent à HT2 et T2
**And** les filtres Ransack sont mis à jour pour inclure les nouveaux champs

---

### Story 3.3: Export Excel incluant les actes T2

En tant qu'instructeur / admin,
Je veux exporter les actes T2 dans les fichiers Excel (index et historique),
Afin d'analyser les données T2 avec les mêmes outils que HT2.

**Acceptance Criteria:**

**Given** des actes T2 existent
**When** je génère l'export Excel (index ou historique)
**Then** l'export contient un onglet "HT2" avec uniquement les actes HT2 (colonnes identiques à l'export actuel)
**And** l'export contient un onglet "T2" avec uniquement les actes T2, incluant les colonnes communes + les champs `t2_details` clés
**And** l'export `admin_backup.xlsx.axlsx` inclut également un onglet `t2_details`

---

### Story 3.4: Gestion des actes T2 dans ActiveAdmin

En tant qu'administrateur,
Je veux gérer les actes T2 dans l'interface ActiveAdmin,
Afin d'avoir les mêmes capacités d'administration que pour les actes HT2.

**Acceptance Criteria:**

**Given** je suis connecté en tant qu'admin
**When** j'accède à la section "Actes" dans ActiveAdmin
**Then** les actes HT2 et T2 sont listés avec une colonne "Titre"
**And** je peux filtrer par titre dans ActiveAdmin
**And** la fiche d'un acte T2 affiche les champs `t2_details` dans un panneau dédié
**And** je peux éditer les champs de base d'un acte T2

---

## Epic 4: Fonctions avancées

Import Excel T2 et génération de PDF pour les actes T2.

### Story 4.1: Import Excel des actes T2

En tant qu'administrateur,
Je veux importer des actes T2 depuis un fichier Excel,
Afin de migrer des données existantes ou d'effectuer des imports en masse.

**Acceptance Criteria:**

**Given** je dispose d'un fichier Excel au format T2
**When** je lance l'import
**Then** les colonnes communes (périmètre, type_acte, nature, organisme, etc.) sont mappées vers la table `actes`
**And** les colonnes spécifiques T2 sont mappées vers `t2_details`
**And** la colonne `titre` est automatiquement définie à `'T2'`
**And** les erreurs de validation sont reportées ligne par ligne
**And** un rapport d'import est affiché (succès / échecs)

---

### Story 4.2: Génération PDF pour les actes T2

En tant qu'instructeur,
Je veux générer un PDF pour un acte T2,
Afin de produire le document officiel de contrôle.

**Acceptance Criteria:**

**Given** un acte T2 est en cours d'instruction ou clôturé
**When** je clique sur "Générer PDF"
**Then** le PDF est généré avec le titre "T2 — [Nature de l'acte]"
**And** les sections affichées correspondent à la nature de l'acte (seuls les champs renseignés apparaissent)
**And** les champs communs (organisme, objet, décision, observations) sont présents
**And** le PDF est attaché à l'acte et téléchargeable

---

*Document créé le 2026-05-11 par John (PM Agent) en collaboration avec Alexandra.*
*Prêt pour revue et implémentation par l'agent Dev.*
