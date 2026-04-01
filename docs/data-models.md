# Data Models — Avisbop

## Overview

Avisbop uses PostgreSQL with Active Record. The schema contains 28 application tables plus infrastructure tables for Active Storage, Action Text, SolidQueue, and Active Admin. The `unaccent` extension is enabled for accent-insensitive search.

**Schema Version:** Rails 8.1 (latest migration: `2026_02_02_090257`)

---

## Entity Relationship Summary

```
Ministere 1──* Programme *──1 Mission
                  │
         ┌────────┼────────────┐
         │        │            │
      1──* Bop  1──* Schema  1──* CentreFinancier
         │        │                    │
      1──* Avi  1──* GestionSchema    *──* Ht2Acte (HABTM)
                    │                    │
                 1──* Transfert         *──* Organisme (HABTM)
                                        │
                              ┌─────────┼──────────┐
                              │         │          │
                           1──* Suspension  1──* Echeancier  1──* PosteLigne
```

---

## Core Tables

### 1. users

**Purpose:** Regular application users authenticated via Devise.

| Column | Type | Constraints |
|--------|------|-------------|
| email | string | unique, default: "" |
| encrypted_password | string | |
| reset_password_token | string | unique |
| reset_password_sent_at | datetime | |
| remember_created_at | datetime | |
| nom | string | |
| statut | string | |

**Associations:** has_many :bops, :avis, :programmes, :gestion_schemas, :schemas, :ht2_actes, :organismes. Also has_many :consulted_bops (as DCB).

**Key Methods:** `import(file)`, `programmes_with_schemas(annee)`, `bops_with_avis(annee, phase)`, `taux_de_remplissage(annee, phase)`, `taux_de_lecture(annee, phase)`, `programmes_access`.

---

### 2. admin_users

**Purpose:** Back-office admin users for Active Admin.

| Column | Type | Constraints |
|--------|------|-------------|
| email | string | unique |
| encrypted_password | string | |

**Authentication:** Devise (database_authenticatable, recoverable, rememberable, validatable).

---

### 3. ministeres

**Purpose:** Government ministries/departments.

| Column | Type |
|--------|------|
| nom | string |

**Associations:** has_many :programmes.

**Key Methods:** Aggregation methods for budget totals across all programmes by vision (RPROG/CBCM) and profil (T2/HT2). Custom Ransack ransacker with `unaccent()` for French diacritics.

---

### 4. missions

**Purpose:** Government budget missions.

| Column | Type |
|--------|------|
| nom | string |

**Associations:** has_many :programmes.

**Key Methods:** Same aggregation pattern as Ministere. Custom Ransack ransacker with `unaccent()`.

---

### 5. programmes

**Purpose:** Budget programs, the central organizational entity.

| Column | Type | Notes |
|--------|------|-------|
| numero | string | Changed from integer |
| nom | string | |
| dotation | string | |
| deconcentre | boolean | |
| date_inactivite | date | |
| statut | string | default: "Actif" |
| ministere_id | FK | |
| mission_id | FK | |
| user_id | FK | |

**Associations:** belongs_to :ministere, :mission, :user. has_many :bops, :schemas, :gestion_schemas, :centre_financiers. has_many :avis (through :bops), :ht2_actes (through :centre_financiers).

**Scopes:** `active` (statut: 'Actif'), `accessible` (Actif OR Inactif), `active_year(annee)`.

**Key Methods:** `last_schema(annee)`, `last_schema_valid(annee)`, `avis_remplis_annee(annee)`, `bops_actifs(annee)`, `import(file)`.

---

### 6. bops

**Purpose:** Budget Operating Programs (BOPs).

| Column | Type | Notes |
|--------|------|-------|
| code | string | |
| ministere | string | |
| nom_programme | string | |
| numero_programme | integer | |
| dotation | string | |
| deconcentre | boolean | default: false |
| programme_id | FK | |
| user_id | FK | |
| dcb_id | FK | References User (Cabinet Director) |

**Associations:** belongs_to :user, :dcb (User), :programme. has_many :avis, :centre_financiers.

**Key Methods:** `import(file)` with complex matching logic.

---

### 7. avis

**Purpose:** Financial opinions/notices on BOPs.

| Column | Type | Notes |
|--------|------|-------|
| phase | string | "debut de gestion", "services votes", "execution" |
| statut | string | |
| etat | string | Auto-set via callback |
| date_envoi | date | |
| date_reception | date | |
| annee | integer | |
| duree_prevision | integer | default: 12 |
| is_delai | boolean | |
| is_crg1 | boolean | |
| ae_i, ae_f | float | Initial/final AE allocations |
| cp_i, cp_f | float | Initial/final CP |
| t2_i, t2_f | float | Initial/final T2 |
| etpt_i, etpt_f | float | Initial/final ETPT |
| commentaire | string | |
| bop_id | FK | |
| user_id | FK | |

**Callbacks:** `before_save :set_etat_avis` — sets state to "Brouillon" if required fields are missing.

**Key Methods:** `import(file)` (services votes), `import_execution(file)`, `numero_avis_services_votes`.

---

### 8. ht2_actes (Core Business Entity)

**Purpose:** HT2 financial acts — the most complex model with 65+ columns.

| Column | Type | Notes |
|--------|------|-------|
| type_acte | string | "avis", "visa", "TF" |
| etat | string | State machine with 8 valid states |
| perimetre | string | "etat" or "organisme" |
| annee | integer | |
| numero_formate | string | e.g., "25-0001" |
| numero_utilisateur | integer | |
| date_chorus | date | |
| date_cloture | date | |
| date_limite | date | Computed deadline |
| delai_traitement | integer | Computed processing delay |
| montant_ae | float | |
| montant_global | float | |
| centre_financier_code | string | Primary CF reference |
| type_montant | string | default: "TTC" |
| type_engagement | string | |
| nom_organisme | string | |
| categorie_organisme | string | |
| instructeur | string | |
| ordonnateur | string | |
| valideur | string | |
| beneficiaire | string | |
| objet | string | |
| nature | string | |
| categorie | string | |
| operation_budgetaire | string | |
| disponibilite_credits | boolean | |
| conformite | boolean | default: true |
| soutenabilite | boolean | default: true |
| proposition_decision | string | |
| decision_finale | string | |
| pre_instruction | boolean | |
| type_observations | string[] | default: [] |
| sheet_data | jsonb | default: {"data" => []} |
| pdf_generation_status | string | default: "none" |
| ... | | (40+ additional fields) |

**State Machine Constants:**
```ruby
VALID_ETATS = [
  "en pre-instruction",
  "en cours d'instruction",
  "suspendu",
  "a suspendre",
  "a valider",
  "a cloturer",
  "cloture apres pre-instruction",
  "cloture"
]
```

**Scopes:** `en_attente_validation`, `en_cours_instruction`, `en_pre_instruction`, `suspendus`, `a_cloturer`, `clotures`, `non_clotures`, `annee_courante`, `perimetre_etat`, `perimetre_organisme`, `actifs_annee_courante`.

**Associations:** belongs_to :user. HABTM :centre_financiers, :organismes. has_many :suspensions, :echeanciers, :poste_lignes. has_many_attached :pdf_files. has_rich_text :commentaire_disponibilite_credits.

**Callbacks (9 total):** `strip_organisme_and_cf_fields`, `upcase_centre_financier_code`, `set_etat_acte` (state transitions), `set_numero_utilisateur`, `calculate_date_limite_if_needed`, `associate_centre_financier_if_needed`, `associate_organisme_if_needed`, `calculate_delai_traitement_if_needed`, `purge_pdf_files_on_update`.

**Key Methods:** `import(file)`, `echeance_courte` (count near-deadline acts), `count_current_with_long_delay`, `duree_moyenne_suspensions`, `delai_moyen_traitement`.

---

### 9. suspensions

**Purpose:** Act suspension/interruption tracking.

| Column | Type | Constraints |
|--------|------|-------------|
| ht2_acte_id | FK | |
| date_suspension | date | presence: true |
| date_reprise | date | |
| motif | string | presence: true |
| observations | text | |
| commentaire_reprise | string | |

---

### 10. echeanciers

**Purpose:** Payment schedules for acts.

| Column | Type |
|--------|------|
| ht2_acte_id | FK |
| annee | integer |
| montant_ae | float |
| montant_cp | float |

---

### 11. poste_lignes

**Purpose:** Budget line items within acts.

| Column | Type |
|--------|------|
| ht2_acte_id | FK |
| numero | string |
| numero_tf | string |
| centre_financier_code | string |
| code_activite | string |
| activite | string |
| action | string |
| sous_action | string |
| montant | float |
| compte_budgetaire | string |
| domaine_fonctionnel | string |
| axe_ministeriel | string |
| fonds | string |
| groupe_marchandises | string |
| flux | string |

---

### 12. centre_financiers

**Purpose:** Financial centers managing budget execution.

| Column | Type | Notes |
|--------|------|-------|
| code | string | |
| statut | string | default: "Actif" |
| deconcentre | boolean | default: false |
| bop_id | FK | optional |
| programme_id | FK | optional |

**Scopes:** `non_valide`, `actif`.

**Associations:** HABTM :ht2_actes. has_many :ht2_actes_principaux (via code primary key).

---

### 13. organismes

**Purpose:** External organizations subject to financial control.

| Column | Type | Constraints |
|--------|------|-------------|
| nom | string | presence: true |
| acronyme | string | |
| statut | string | "actif"/"inactif" |
| id_opera | integer | unique, nullable |
| user_id | FK | |

**Scopes:** `actif`, `inactif`.

**Key Methods:** `import(file)`.

---

### 14. schemas

**Purpose:** End-of-management budget planning schemas.

| Column | Type |
|--------|------|
| programme_id | FK |
| user_id | FK |
| annee | integer |
| statut | string |

**Associations:** has_many :gestion_schemas. has_one_attached :document_pdf.

**Key Methods:** `incomplete?`, `complete?`, `first_of_year?`.

---

### 15. gestion_schemas

**Purpose:** Schema management with 55+ financial columns for budget planning.

| Column | Type | Notes |
|--------|------|-------|
| schema_id | FK | |
| programme_id | FK | |
| user_id | FK | |
| annee | integer | |
| vision | string | "RPROG" or "CBCM" |
| profil | string | "HT2" or "T2" |
| commentaire | text | |
| ressources_ae/cp | float | |
| depenses_ae/cp | float | |
| mer_ae/cp | float | |
| surgel_ae/cp | float | |
| fongibilite_ae/cp | float | |
| decret_ae/cp | float | |
| credits_lfg_ae/cp | float | |
| reports_ae/cp | float | |
| charges_a_payer_ae/cp | float | |
| ... | | (40+ financial fields) |

**Scopes:** `cbcm_t2`, `cbcm_ht2`, `rprog_t2`, `rprog_ht2`.

**Callbacks:** `before_save :set_nil_values_to_zero`, `before_save :set_fongibilite`.

**Key Methods:** `solde_total_ae/cp`, `prevision_solde_budgetaire_ae/cp`, `transferts_entrant_ae/cp`, `transferts_sortant_ae/cp`, `step`.

---

### 16. transferts

**Purpose:** Budget transfers between programs.

| Column | Type |
|--------|------|
| gestion_schema_id | FK |
| programme_id | FK |
| nature | string | "entrant" or "sortant" |
| montant_ae | float |
| montant_cp | float |

**Scopes:** `entrant`, `sortant`.

---

## Join Tables

| Table | Purpose |
|-------|---------|
| centre_financiers_ht2_actes | HABTM: CentreFinancier <-> Ht2Acte |
| ht2_actes_organismes | HABTM: Ht2Acte <-> Organisme |

---

## Infrastructure Tables

| Table | Purpose |
|-------|---------|
| action_text_rich_texts | Rich text content (ActionText) |
| active_admin_comments | Admin interface comments |
| active_storage_blobs | File storage metadata |
| active_storage_attachments | File-record associations |
| active_storage_variant_records | Image variant tracking |
| solid_queue_* (11 tables) | Background job queue system |

---

## Import Functionality

Models with spreadsheet import: Avi (2 modes), Bop, CentreFinancier, Programme, User, Organisme, Ht2Acte. All use the `roo` gem for Excel/CSV parsing.

## Recent Evolution (2026)

Focus on organisms/perimeter management: added Organismes table, perimetre field on ht2_actes, join table for HABTM relationship, deliberation tracking fields, and conformity/soutenabilite checks.
