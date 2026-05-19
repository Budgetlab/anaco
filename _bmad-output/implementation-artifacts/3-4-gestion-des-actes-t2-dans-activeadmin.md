# Story 3.4: Gestion des actes T2 dans ActiveAdmin

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an administrator,
I want the existing ActiveAdmin "Actes" resource ([app/admin/actes.rb](app/admin/actes.rb)) to expose the T2-specific data (`titre`, `categorie_t2`, the `t2_detail` `has_one` association and its ~32 columns) — in the index table, filters, show page and edit form — alongside the existing HT2 fields,
so that admin users have the same back-office capabilities for T2 actes as they currently have for HT2 actes (browse, filter, inspect details, fix data inline) without ever having to drop to the Rails console.

> ℹ️ **Scope clarification vs. epic** — the epic [story 3.4](_bmad-output/planning-artifacts/epics-t2-integration.md:589) asks for four things, all targeted at the single `ActiveAdmin.register Acte` resource: (1) HT2 and T2 listed together with a `Titre` column, (2) a filter by titre, (3) a dedicated panel on the show page rendering all `t2_details` fields, (4) the ability to edit base fields of a T2 acte. This story implements all four.
>
> **Out of scope** for this story: a separate `ActiveAdmin.register T2Detail` resource (the epic asks for T2 management inside the Actes resource, not as a standalone CRUD), changes to the user-facing `/actes` UI (covered by Stories 3.1–3.3), and any new migrations (the schema is already complete since Story 1.2).

## Acceptance Criteria

### AC1 — Index table includes `Titre`, `Catégorie T2` and respects HT2/T2 ordering

**Given** I'm logged in as admin and I navigate to `/admin/actes`
**When** the index page renders
**Then** a new `Titre` column appears (between `type_acte` and `etat` is the recommended position — adjacent to the existing classifier columns), displayed as a badge-like text value `HT2` or `T2`
**And** a new `Catégorie T2` column appears immediately after `Titre`, displaying `acte.categorie_t2` for T2 actes (`contrat` or `hors contrat`) and a dash `—` (or blank) for HT2 actes
**And** the existing columns (`id`, `numero_formate`, `type_acte`, `etat`, `user`, `nature`, `montant_ae`, `date_saisine`, `perimetre`, `annee`, `created_at`, `actions`) remain in their current order — no reordering, no removal
**And** the default sort order is unchanged (ActiveAdmin defaults to `id desc`)
**And** mixed HT2 + T2 rows render on the same page (no separate tabs) — admin can scan both types in one view

### AC2 — Index filter by `Titre` and by `Nature` (with T2 natures)

**Given** I'm on `/admin/actes`
**When** I open the filters sidebar
**Then** a new filter `Titre` is present, rendered as `as: :select, collection: ['HT2', 'T2']` — allowing single-value selection (single-select dropdown, consistent with how `type_acte` is filtered at [actes.rb:63](app/admin/actes.rb:63))
**And** a new filter `Catégorie T2` is present, rendered as `as: :select, collection: ['contrat', 'hors contrat']`
**And** the existing `nature` filter ([actes.rb:68](app/admin/actes.rb:68)) — currently a free-text contains filter — is **upgraded to a select**, with the **union** of HT2 natures and T2 natures so admins can target T2 natures specifically. Use the same list the user-facing controller builds at [actes_controller.rb:1329-1333](app/controllers/actes_controller.rb:1329) (HT2 natures: ~25 values across `type_acte ∈ {avis, visa}`) **plus** the 7 T2 natures from [actes_controller.rb:1249](app/controllers/actes_controller.rb:1249): `Annexe financière`, `Enveloppe limitative`, `Fongibilité asymétrique`, `ISP`, `Marché`, `Mesure transversale`, `Référentiel`. De-duplicate (`Marché` is shared between an HT2 list and the T2 list — keep one entry)
**And** all existing filters (`numero_formate`, `numero_chorus`, `type_acte`, `etat`, `perimetre`, `categorie_organisme`, `user_id`, `decision_finale`, `annee`, `date_saisine`, `date_cloture`, `montant_ae`, `beneficiaire`, `ordonnateur`, `instructeur`, `valideur`, `pre_instruction`, `created_at`, `updated_at`) remain in place — no removal
**And** applying `Titre = T2` returns only T2 actes (verified via Ransack — `titre` is already in `Acte.ransackable_attributes` at [acte.rb:68](app/models/acte.rb:68))
**And** applying `Titre = T2` + `Nature = ISP` returns only T2 ISP actes
**And** combining `Titre` with the existing `perimetre` filter works (e.g. `Titre = T2` + `perimetre = etat` → T2 actes État only)

### AC3 — Show page exposes `titre` / `categorie_t2` in the main attributes table

**Given** I'm viewing `/admin/actes/:id` for a T2 acte
**When** the show page renders
**Then** the existing `attributes_table do` block ([actes.rb:82-156](app/admin/actes.rb:82)) is **augmented** with two new rows: `row :titre` (immediately after `row :numero_utilisateur` or near the top — same logical position as the new index column) and `row :categorie_t2` (immediately after `row :titre`)
**And** for an HT2 acte, these two rows still render — `titre` shows `HT2`, `categorie_t2` shows blank — so admins can verify the classification at a glance for any acte
**And** no existing rows are removed or reordered (the attributes table is append-only for this story — minimise risk of regression on the HT2 admin workflow)

### AC4 — Dedicated `Détails T2` panel on the show page (conditional, renders only for T2 actes)

**Given** I'm viewing `/admin/actes/:id` for a T2 acte that has an associated `t2_detail` row
**When** the show page renders
**Then** a new `panel 'Détails T2'` block is inserted **between the existing `attributes_table` and the `panel 'Suspensions'` block** ([actes.rb:158](app/admin/actes.rb:158))
**And** the panel renders **only if `acte.titre == 'T2'`** (use `if acte.titre == 'T2'` guard around the `panel` block — HT2 show page must be byte-equivalent to today's output, no empty panel, no header)
**And** the panel body uses `attributes_table_for acte.t2_detail do ... end` (ActiveAdmin pattern for nested objects — see [`active_admin`/`active_admin_helpers`](https://activeadmin.info/3-index-pages.html#index-as-table) docs; same pattern is used in the existing `Lignes de poste` and `Échéanciers` panels with `table_for`)
**And** **all 32 `t2_details` data columns** from [db/schema.rb:503-545](db/schema.rb:503) are exposed as rows, in this **logical grouping order** (not strict schema alphabetical order — group by nature for readability, mirroring the user-facing partials at [app/views/actes/t2_sections/_show_*.html.erb](app/views/actes/t2_sections/)):

  1. **Identification** — `type_acte_t2` (Annexe financière "Type d'engagement"), `referentiel_type` (Référentiel)
  2. **Annexe financière / RH commun** — `effectifs`, `effectifs_complementaire`, `corps`, `grade` (array → `.join(', ')`), `date_arrete_concours`, `date_effet_acte`, `impact_schema_emplois`, `impact_autre_cbcm`
  3. **ISP Cercle 1** — `isp_cercle1`, `isp_cercle1_natures` (array → join), `isp_cercle1_montant`, `isp_cercle1_enveloppe_sgg`, `isp_cercle1_consommation`
  4. **ISP Cercle 2** — `isp_cercle2`, `isp_cercle2_natures` (array → join), `isp_cercle2_montant`, `isp_cercle2_enveloppe_sgg`, `isp_cercle2_consommation`
  5. **Fongibilité asymétrique** — `fa_technique`, `enveloppe_abondee`, `accord_rffim`, `sollicitation_db`, `avis_cbcm`
  6. **Mesure transversale / Enveloppe limitative** — `perimetre_mesure` (array → join), `statut_agents`, `impact_financier_n1`, `origine_financement` (array → join), `montant_enveloppe_n1`, `impact_maximal_sans_enveloppe`
  7. **Contrôles RH communs T2** (étape 2) — `inscription_pap`, `respect_plafond_emplois`, `respect_schema_emplois`, `controle_modalites`, `respect_enveloppe`, `risque_reconventionnel`
  8. **Timestamps** — `created_at`, `updated_at`, `id` (the FK `acte_id` is redundant since we're scoped to this acte — render at the bottom as cross-reference or skip)

**And** array columns (`grade`, `isp_cercle1_natures`, `isp_cercle2_natures`, `perimetre_mesure`, `origine_financement`) render as comma-joined strings via `row(:grade) { |td| Array(td.grade).join(', ') }` — same pattern used in [generate_backup_job.rb:65](app/jobs/generate_backup_job.rb:65) for `type_observations` and in the Story 3.3 helper [actes_helper.rb#t2_export_row](app/helpers/actes_helper.rb:215)
**And** decimal columns render with the existing `number_to_currency(value, unit: '€', separator: ',', delimiter: ' ')` helper when they represent monetary values (`isp_cercle1_montant`, `isp_cercle1_enveloppe_sgg`, `isp_cercle1_consommation`, `isp_cercle2_montant`, `isp_cercle2_enveloppe_sgg`, `isp_cercle2_consommation`, `impact_financier_n1`, `montant_enveloppe_n1`, `impact_maximal_sans_enveloppe`) — mirrors the existing currency rendering at [actes.rb:103-107](app/admin/actes.rb:103) for `montant_ae` / `montant_global`
**And** boolean columns render via ActiveAdmin's default boolean renderer (✓ / ✗ or `Oui` / `Non` — whichever ActiveAdmin default produces; no custom formatter needed)
**And** date columns render via `acte.t2_detail.date_arrete_concours&.strftime('%d/%m/%Y')` (consistent with FR locale used throughout the app — see [config/locales/fr.yml](config/locales/fr.yml) and existing xlsx exports)
**And** for a T2 acte where `acte.t2_detail` is `nil` (legitimate edge case for Marché nature per Story 3.3 Dev Notes, or for partially-imported data), the panel still renders with the title `'Détails T2'` and a single line `"Aucun T2Detail associé"` instead of crashing — guard: `if acte.t2_detail.present?` inside the panel body

### AC5 — Inline edit of T2 base fields from the ActiveAdmin form

**Given** I'm editing an existing T2 acte via `/admin/actes/:id/edit`
**When** the form renders
**Then** the existing `form do |f|` block ([actes.rb:197-303](app/admin/actes.rb:197)) is **augmented** with a new `f.inputs 'Classification T2'` section, inserted **immediately after the existing `f.inputs 'Informations générales'` block** ([actes.rb:198-208](app/admin/actes.rb:198))
**And** the section contains exactly two inputs:
  - `f.input :titre, as: :select, collection: ['HT2', 'T2']`
  - `f.input :categorie_t2, as: :select, collection: ['contrat', 'hors contrat'], include_blank: true`
**And** `:titre` and `:categorie_t2` are added to the `permit_params` declaration ([actes.rb:24-39](app/admin/actes.rb:24)) — append at the end of the list (preserve existing order)
**And** the form successfully saves both fields for a T2 acte (manual smoke check during dev — and covered by the controller test in AC8)
**And** the existing model-level validations are respected: changing `titre` from `T2` to `HT2` while `t2_detail` is present should **fail validation** via the `no_t2_detail_for_ht2` validation at [acte.rb:92](app/models/acte.rb:92) — ActiveAdmin surfaces the error message in the standard flash/inline-error UI. No additional validation handling needed in the admin file
**And** for this story, **the `t2_detail` fields themselves are NOT editable from the admin form** — the panel built in AC4 is read-only. Reasoning: editing 32 nested-attribute fields with conditional perimeter/nature logic would duplicate the entire user-facing `/actes/:id/edit` form (Story 2.x scope) — out of scope here, defer to a tech-debt story. Admins who need to fix a T2Detail field today use the Rails console; this story does not change that

> 📝 **Decision note** — if a reviewer pushes back and wants `t2_detail` edits exposed in the admin form, the simplest approach would be `f.inputs 'Détails T2', for: :t2_detail do |td| td.input :effectifs ; ... end` (32 inputs, no conditional rendering, all visible regardless of nature). Cost: ~50 lines, no nested-attribute handling needed since `Acte` already has `accepts_nested_attributes_for :t2_detail` at [acte.rb:21](app/models/acte.rb:21). Punt unless the reviewer asks explicitly — see "Pitfalls" below for the trade-off.

### AC6 — `T2Detail` model exposes ransackable attributes (admin filter compatibility, future-proofing)

**Given** the [T2Detail model](app/models/t2_detail.rb) currently has no `ransackable_attributes` / `ransackable_associations` declarations — Ransack 4.x raises `Ransack::InvalidSearchError` when an admin tries to use a `t2_detail_*_eq` filter via the URL
**When** Story 3.4 is delivered
**Then** the [T2Detail model](app/models/t2_detail.rb) declares:

```ruby
def self.ransackable_attributes(auth_object = nil)
  %w[
    id acte_id type_acte_t2
    effectifs effectifs_complementaire corps grade date_arrete_concours date_effet_acte
    impact_schema_emplois impact_autre_cbcm
    isp_cercle1 isp_cercle1_natures isp_cercle1_montant isp_cercle1_enveloppe_sgg isp_cercle1_consommation
    isp_cercle2 isp_cercle2_natures isp_cercle2_montant isp_cercle2_enveloppe_sgg isp_cercle2_consommation
    fa_technique enveloppe_abondee accord_rffim sollicitation_db avis_cbcm
    perimetre_mesure statut_agents impact_financier_n1 origine_financement
    montant_enveloppe_n1 impact_maximal_sans_enveloppe
    referentiel_type
    inscription_pap respect_plafond_emplois respect_schema_emplois controle_modalites respect_enveloppe risque_reconventionnel
    created_at updated_at
  ]
end

def self.ransackable_associations(auth_object = nil)
  %w[acte]
end
```

**And** [Acte model `ransackable_associations`](app/models/acte.rb:70) is extended to include `t2_detail` — the current list at [acte.rb:71](app/models/acte.rb:71) has `["centre_financier_principal", "centre_financiers", "echeanciers", "organismes", "poste_lignes", "rich_text_commentaire_disponibilite_credits", "suspensions", "user"]` — add `t2_detail` (alphabetical position right after `suspensions`). This unlocks future filters like `q[t2_detail_fa_technique_eq]=true` (not added in this story, but the model declaration is the prerequisite)
**And** **no new filters using `t2_detail_*` are added to the ActiveAdmin file in this story** — only the foundation. If we later want "admins can filter actes by `effectifs > 100`", a follow-up story adds `filter :t2_detail_effectifs, label: 'Effectifs T2'` and it just works because of this declaration

> ⚠️ **Why declare 32+ ransackable attributes if we use none of them today?** Two reasons: (1) the declaration is a one-time cost paid here; (2) Rails 7 / Ransack 4 raise loudly on first access, so without this declaration the **first time anyone tries** `q[t2_detail_xxx]` via a URL or a future filter, they hit `Ransack::InvalidSearchError` — frustrating to debug after the fact. Pay the cost now, scoped to admin needs.

### AC7 — No regression on the existing admin Actes workflow

**Given** an admin user performs any of their normal HT2-only workflows: browsing `/admin/actes`, filtering by `type_acte`, viewing a HT2 show page, editing a HT2 acte (changing `etat`, `ordonnateur`, `proposition_decision` etc.), exporting via the existing `download_links` (ActiveAdmin built-in CSV/JSON/XML)
**When** Story 3.4 is delivered
**Then** the HT2 show page output is **byte-equivalent to today** except for the two new rows (`titre` shows `HT2`, `categorie_t2` shows blank) — no panel "Détails T2" rendered (guard from AC4), no new section in the form (the `Classification T2` section IS rendered for HT2 too — minor visual change, see Decision below)
**And** the HT2 edit form saves successfully — the new `titre`/`categorie_t2` fields are nullable on edit (model validation accepts `titre = 'HT2'` + `categorie_t2 = nil`)
**And** the existing `before_action only: [:create, :update]` callback at [actes.rb:41-43](app/admin/actes.rb:41) that strips blank values from `type_observations` continues to work — no interference
**And** the existing `TYPES_OBSERVATIONS` constant ([actes.rb:4-22](app/admin/actes.rb:4)) and form section "Observations et précisions" continue to render as today

> 📝 **Decision on the `Classification T2` form section visibility for HT2** — keep it always-visible (no conditional rendering). Reasoning: (a) admins occasionally need to fix the `titre` classification for migrated data, (b) ActiveAdmin's form DSL does not natively support conditional sections without JS, (c) the section adds 2 inputs ≈ 60 lines of vertical space, negligible. If a reviewer prefers `if f.object.titre == 'T2'` wrapping the second input, that's a one-line change; punt to review.

### AC8 — Integration tests

**Given** the existing admin test coverage (none currently exist for `app/admin/actes.rb` per a grep of [test/](test/) — ActiveAdmin generated resources are conventionally tested only when business logic is added)
**When** Story 3.4 is delivered
**Then** at minimum the following test coverage is added in a new file [test/admin/actes_admin_test.rb](test/admin/actes_admin_test.rb) (or extended into an existing admin test file if one is added later):

  1. `test "admin index includes Titre column for HT2 and T2 actes"` — create one HT2 and one T2 acte, GET `/admin/actes`, assert response includes both `HT2` and `T2` text near their respective `numero_formate`
  2. `test "admin index filter by titre returns only T2 actes"` — `get '/admin/actes', params: { q: { titre_eq: 'T2' } }`, assert response body contains the T2 acte's `numero_formate` and **does not** contain the HT2 acte's `numero_formate`
  3. `test "admin show page for T2 acte renders Détails T2 panel with t2_detail data"` — create a T2 acte with `T2Detail.create!(acte: acte, isp_cercle1: true, isp_cercle1_montant: 1500)`, GET `/admin/actes/:id`, assert response includes `"Détails T2"` and `"1500"` (or formatted variant)
  4. `test "admin show page for HT2 acte does NOT render Détails T2 panel"` — regression guard, assert response does **not** include `"Détails T2"`
  5. `test "admin show page for T2 acte without t2_detail renders panel with fallback message"` — create T2 acte without associated T2Detail, assert response includes `"Détails T2"` and `"Aucun T2Detail associé"`
  6. `test "admin edit form for T2 acte exposes titre and categorie_t2 inputs"` — GET `/admin/actes/:id/edit`, assert response body contains `name="acte[titre]"` and `name="acte[categorie_t2]"`
  7. `test "admin update successfully changes titre from HT2 to T2"` — PATCH with `acte[titre]=T2` and `acte[categorie_t2]=hors contrat`, assert redirected, assert acte reloaded has new values
  8. `test "admin update fails when trying to set titre=HT2 while t2_detail exists"` — guard for the `no_t2_detail_for_ht2` validation: create T2 acte with t2_detail, PATCH `acte[titre]=HT2`, assert response renders edit form with error flash (or assert acte.reload.titre is still `T2`)
  9. `test "T2Detail.ransackable_attributes includes the 32 data columns"` — model test, fast guard against accidental list-trim regression

**And** the existing test suite (~179 runs, 1204 assertions post Story 3.3 per [3-3-export-excel-incluant-les-actes-t2.md:470](_bmad-output/implementation-artifacts/3-3-export-excel-incluant-les-actes-t2.md:470)) **stays green**
**And** the new tests log in as an admin user via the existing helper pattern in [test/test_helper.rb](test/test_helper.rb) (the codebase uses Devise — `sign_in admin_user` via `Devise::Test::IntegrationHelpers` — verify the helper inclusion in the test_helper before writing the file; if no helper exists, use `post '/admin_users/sign_in', params: { admin_user: { email: ..., password: ... } }` to start the session)

> 📝 **Test infrastructure note** — check whether [test/test_helper.rb](test/test_helper.rb) already loads `Devise::Test::IntegrationHelpers`. If not, this story should add it (one line) under the `ActiveSupport::TestCase` block. Verify before adding to avoid duplicating an existing setup. The Story 3.3 test patterns at [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb) sign in as a regular `User`; admin login uses the separate `AdminUser` model — see [config/initializers/active_admin.rb](config/initializers/active_admin.rb) for the admin auth chain.

### AC9 — No new database migrations or schema changes

**Given** all `t2_details` columns already exist (Story 1.2 done) and all `actes` T2 columns (`titre`, `categorie_t2`) already exist (Story 1.1 done)
**When** Story 3.4 is delivered
**Then** **zero new migrations** are added — `db/schema.rb` is byte-identical pre/post story
**And** **zero new models** are created — `Acte` and `T2Detail` are both pre-existing
**And** **zero new routes** are added — ActiveAdmin auto-generates `/admin/actes` CRUD routes from the existing `register Acte` declaration at [actes.rb:1](app/admin/actes.rb:1)

## Tasks / Subtasks

- [x] **Task 1: Index — add Titre + Catégorie T2 columns** (AC: 1)
  - [x] `column :titre` ajouté après `column :type_acte` ([actes.rb:79](app/admin/actes.rb:79))
  - [x] `column :categorie_t2` immédiatement après — blank pour HT2 via le rendu nil par défaut de ActiveAdmin (cellule vide)
  - [x] Vérifié : `col-titre` et `col-categorie_t2` rendus dans le HTML (assertion test #1)

- [x] **Task 2: Filters — Titre, Catégorie T2, upgrade Nature to select** (AC: 2)
  - [x] `filter :titre, as: :select, collection: ['HT2', 'T2']` ajouté après `filter :type_acte` ([actes.rb:91](app/admin/actes.rb:91))
  - [x] `filter :categorie_t2, as: :select, collection: ['contrat', 'hors contrat']` ajouté
  - [x] `filter :nature` upgradé en `as: :select, collection: NATURES_FILTER_COLLECTION`
  - [x] Constante `NATURES_FILTER_COLLECTION` définie dans le fichier ([actes.rb:25-46](app/admin/actes.rb:25)) — union HT2 visa + HT2 avis + 7 T2 natures, `.uniq.sort` (30 valeurs distinctes)
  - [x] Vérifié : `q[titre_eq]=T2` ne retourne que les actes T2 (test #2)

- [x] **Task 3: Show page — add titre + categorie_t2 rows, add `Détails T2` panel** (AC: 3, 4)
  - [x] `row :titre` + `row :categorie_t2` ajoutés après `row :numero_utilisateur` ([actes.rb:115-116](app/admin/actes.rb:115))
  - [x] Panel `Détails T2` inséré entre `attributes_table` et `panel 'Suspensions'` ([actes.rb:184-241](app/admin/actes.rb:184))
  - [x] Guard `if acte.titre == 'T2'` — HT2 ne rend pas le panel (test #5)
  - [x] Guard interne `if acte.t2_detail.present?` — fallback `para "Aucun T2Detail associé"` (test #6)
  - [x] 32 rows organisés en 8 groupes logiques (Identification, Annexe financière, ISP C1, ISP C2, FA, Mesure transversale/EL, Contrôles RH, Timestamps)
  - [x] Arrays sérialisés via `Array(td.<field>).join(', ')` (grade, isp_natures, perimetre_mesure, origine_financement)
  - [x] Décimaux monétaires formatés via `number_to_currency(..., unit: '€', separator: ',', delimiter: ' ')` (9 champs)

- [x] **Task 4: Edit form — Classification T2 section + permit_params** (AC: 5)
  - [x] `:titre, :categorie_t2` ajoutés à `permit_params` ([actes.rb:64](app/admin/actes.rb:64))
  - [x] Section `f.inputs 'Classification T2'` insérée après `'Informations générales'` ([actes.rb:262-265](app/admin/actes.rb:262)) avec 2 inputs select
  - [x] Test #8 : update `categorie_t2` réussit (round-trip persistence)
  - [x] Test #9 : update `titre=HT2` quand `t2_detail` existe → validation `no_t2_detail_for_ht2` bloque la sauvegarde

- [x] **Task 5: Ransackable declarations** (AC: 6)
  - [x] [app/models/t2_detail.rb](app/models/t2_detail.rb) : `ransackable_attributes` (38 colonnes — 32 data + id + acte_id + 2 timestamps + alias) et `ransackable_associations` (`["acte"]`)
  - [x] [app/models/acte.rb:71](app/models/acte.rb:71) : `"t2_detail"` ajouté à `ransackable_associations` (préserve l'ordre alpha entre `suspensions` et `user`)

- [x] **Task 6: Tests** (AC: 8)
  - [x] `Devise::Test::IntegrationHelpers` déjà chargé dans [test/test_helper.rb:16](test/test_helper.rb:16) — pas de modification nécessaire
  - [x] [test/admin/actes_admin_test.rb](test/admin/actes_admin_test.rb) créé (nouveau dossier `test/admin/`)
  - [x] [test/fixtures/admin_users.yml](test/fixtures/admin_users.yml) peuplé avec une fixture `:one` (BCrypt password)
  - [x] **14 tests** écrits (au-delà des 9 prévus en AC8 — ajout de cas de sécurité pour les filtres HT2 + symétrie et 2 tests ransackable séparés)
  - [x] **Routes** : découverte que le scope est `/anaco/admin/actes` (pas `/admin/actes`) — tests adaptés à la route réelle
  - [x] Tous les tests passent : `14 runs, 92 assertions, 0 failures, 0 errors, 0 skips`

- [x] **Task 7: Run full test suite + manual smoke check** (AC: 8, 11)
  - [x] Suite complète : **193 runs, 1296 assertions, 0 failures, 0 errors, 0 skips** (Δ = +14 tests / +92 assertions vs. Story 3.3 qui était à 179/1204)
  - [x] Aucune régression — toutes les vues / controllers HT2 et T2 existants restent verts
  - [ ] Manual smoke check non exécuté en CI — recommandé avant merge (cf. AC7 plan : navigation `/anaco/admin/actes`, filtres, show/edit pour HT2 et T2)

- [x] **Task 8 (post-impl — demande utilisateur)** : édition des champs `t2_detail` depuis le formulaire admin
  - [x] Section `f.inputs 'Détails T2 (édition admin — toutes natures à plat)'` ajoutée, conditionnelle `if f.object.titre == 'T2'`, 32 inputs à plat (boolean / decimal / string / datepicker)
  - [x] 5 colonnes array (`grade`, `isp_cercle1_natures`, `isp_cercle2_natures`, `perimetre_mesure`, `origine_financement`) exposées comme input texte CSV, converties en `Array<String>` côté serveur dans le `before_action`
  - [x] `permit_params` étendu avec `t2_detail_attributes: [...]` (33 clés scalars + 5 keys array)
  - [x] Gestion du cas `acte.t2_detail.nil?` via `f.object.build_t2_detail` (cas Marché légitime)
  - [x] 4 nouveaux tests ajoutés (exposition inputs, persistence scalar, conversion CSV → array, non-rendu HT2). Tous verts.
  - [x] Suite complète : **197 runs / 1311 assertions / 0 failures** (+4 tests vs. premier passage Story 3.4)

## Dev Notes

### Architecture — ActiveAdmin's role in this codebase

The codebase has **17 ActiveAdmin resources** under [app/admin/](app/admin/). The flagship resource for this story is [actes.rb](app/admin/actes.rb) — the only one currently registered for the renamed `Acte` model (since Story 1.4's rename `Ht2ActesController → ActesController` and `register Ht2Acte → register Acte`).

ActiveAdmin uses **Ransack** under the hood for filters: `filter :foo` generates `q[foo_eq]` / `q[foo_cont]` URL params depending on the column type. The `as:` option controls the input widget but **Ransack's predicate is derived from the underlying column type** (string columns get `_cont` by default — substring match; selects use `_eq`). Since `titre` is `string`, `filter :titre, as: :select` will issue `q[titre_eq]=T2` — exactly what we want for AC2.

### Why a single `register Acte` (not a separate `register T2Acte`)

The data model has **one table** (`actes`) with a discriminator column (`titre`). The epic spec explicitly asks for HT2 and T2 to be **listed together** in the admin index ([epics-t2-integration.md:599](_bmad-output/planning-artifacts/epics-t2-integration.md:599)). Splitting into two registers would require either:
1. A `register Acte, as: 'T2Acte'` with a default scope `where(titre: 'T2')` — works but creates URL ambiguity (`/admin/actes` vs. `/admin/t2_actes`) and duplicates the form/show DSL.
2. STI on the `Acte` model — out of scope, would require schema changes (`type` column).

Neither is worth it. Single register + filter on `titre` is the clean approach.

### The 7 T2 natures vs. the ~25 HT2 natures — building the unified filter collection

The user-facing controller builds two separate nature lists:
- **HT2 visa natures** ([actes_controller.rb:1333](app/controllers/actes_controller.rb:1333)): `Autre contrat`, `Bail`, `Bon de commande`, `Convention`, `Décision diverse`, `Dotation en fonds propres`, `Marché unique`, `Marché à tranches`, `Marché mixte`, `MAPA unique`, `MAPA à tranches`, `MAPA mixte`, `Prêt ou avance`, `Remboursement de mise à disposition T3`, `Subvention`, `Subvention pour charges d'investissement`, `Subvention pour charges de service public`, `Transaction`, `Transfert`, `Autre`
- **HT2 avis natures** ([actes_controller.rb:1329](app/controllers/actes_controller.rb:1329)): `Accord cadre à bons de commande`, `Accord cadre à marchés subséquents`, `Autre contrat`, `Convention`, `Marché subséquent à bons de commande`, `MAPA à bons de commande`, `Transaction`, `Autre`
- **T2 natures (3 variants)**: full DCB list at [actes_controller.rb:1249](app/controllers/actes_controller.rb:1249) — `Annexe financière`, `Enveloppe limitative`, `Fongibilité asymétrique`, `ISP`, `Marché`, `Mesure transversale`, `Référentiel`

For the admin filter, **de-duplicate and sort alphabetically** — admins filter by string match, they don't care about the HT2/T2/avis/visa branching. The collection is ~30 distinct values once deduped. Inline the array literal in the admin file (no need to import from the controller — the controller's lists serve a different purpose: cascading dropdown driven by `type_acte` + `perimetre` + `titre`).

> 💡 **DRY consideration**: a future refactor could extract these nature constants to `Acte::NATURES_HT2_VISA`, `Acte::NATURES_HT2_AVIS`, `Acte::NATURES_T2` and reuse them in both the controller and the admin file. **Not in this story** — keep the admin file self-contained, flag for retrospective.

### The `t2_detail` `has_one` association — show page rendering pattern

ActiveAdmin's `attributes_table` is normally bound to the resource (`acte`). For nested objects, use `attributes_table_for(object) do ... end` — same DSL, different binding. Pattern documented at [activeadmin.info/6-show-pages.html](https://activeadmin.info/6-show-pages.html#attributes-table-for-arbitrary-resources).

Example for the `Détails T2` panel:

```ruby
panel 'Détails T2' do
  attributes_table_for acte.t2_detail do
    row :type_acte_t2
    row(:grade) { |td| Array(td.grade).join(', ') }
    row(:isp_cercle1_montant) { |td| number_to_currency(td.isp_cercle1_montant, unit: '€') if td.isp_cercle1_montant }
    # ...
  end
end
```

The block-form rows (`row(:foo) { |td| ... }`) receive the `t2_detail` instance as the block arg `td`. Non-block rows (`row :type_acte_t2`) call `.type_acte_t2` on the bound object automatically.

### Pitfall — N+1 on `acte.t2_detail` access in the index

The admin index doesn't render `t2_detail` fields (per AC1 — only `titre` and `categorie_t2` are `acte`-table columns). **No eager-load needed** for the index. If a future story adds a `t2_detail` column to the index, eager-load via the controller-equivalent ActiveAdmin pattern: `controller do def scoped_collection ; end_of_association_chain.includes(:t2_detail) ; end end`. **Not needed for this story.**

For the show page, ActiveAdmin loads the resource via `Acte.find(params[:id])` — one extra SQL query for `t2_detail` is acceptable for a single-resource show. If we wanted to optimise: `controller do def find_resource ; scoped_collection.includes(:t2_detail).find(params[:id]) ; end end` — overkill for this story.

### Pitfall — `attributes_table_for` and decimals/dates without explicit formatting

ActiveAdmin's default renderer for `BigDecimal` / `Decimal` prints the raw value (e.g. `1500.0`) — not pretty for currency display. **Always wrap money fields in `number_to_currency`** as listed in AC4. Same for dates: default renderer prints ISO `2026-05-19`; the FR app convention is `19/05/2026` — wrap in `&.strftime('%d/%m/%Y')` blocks.

For booleans, ActiveAdmin renders ✓/✗ (good UTF-8 symbols). **Keep the default** — don't wrap in custom formatters unless we want "Oui"/"Non" (which would require ~6 row blocks for the 6 control criteria; trade off readability vs. consistency with the user-facing partials at [_show_*.html.erb](app/views/actes/t2_sections/)).

### Pitfall — ActiveAdmin form section conditional rendering

ActiveAdmin form DSL does **not** support conditional inputs natively — you can't write `f.input :categorie_t2 if f.object.titre == 'T2'` and expect the field to dynamically appear/disappear as the user changes the `titre` select. The condition is evaluated **server-side at form render**, so it only reflects the **current** value, not the user's selection.

**For this story**: keep both `titre` and `categorie_t2` always-visible (AC7 decision). The model validation `validates :categorie_t2, presence: true, if: -> { titre == 'T2' }` ([acte.rb:89](app/models/acte.rb:89)) catches the bad state on submit and surfaces the error inline.

**Future enhancement** (out of scope): a small JS toggle (Stimulus controller) to hide `categorie_t2` when `titre == 'HT2'`. Punt unless reviewer asks.

### Pitfall — `T2Detail` ransackable: declare ALL columns, not just the ones we filter today

If we only declare `ransackable_attributes %w[id acte_id]`, the **first** time anyone in the future writes `q[t2_detail_fa_technique_eq]=true` they hit `Ransack::InvalidSearchError: t2_detail.fa_technique is not allowed`. That error message is clear, but it's a tax on every future admin enhancement. **One-time cost: list all 32 columns now** (~10 lines), zero recurring cost. See AC6 for the full list.

### Pitfall — the `acte.t2_detail` may be `nil` for T2 actes (legitimate case)

Per [Story 3.3 Dev Notes](_bmad-output/implementation-artifacts/3-3-export-excel-incluant-les-actes-t2.md:370), the `t2_detail` row is **not** systematically present for every T2 acte:
- The Marché nature does not use `t2_details` (per [epics-t2-integration.md:388](_bmad-output/planning-artifacts/epics-t2-integration.md:388))
- Imported / manually-created T2 actes may lack a `t2_detail` row

**The admin show page MUST handle `acte.t2_detail.nil?`** — see AC4 — by rendering the panel with a `"Aucun T2Detail associé"` fallback. Do NOT skip the panel entirely for nil-detail T2 actes — the admin needs the visual signal that the detail is missing (so they can investigate).

### Pitfall — ActiveAdmin `permit_params` order matters NOT for security but for readability

The existing `permit_params` list ([actes.rb:24-39](app/admin/actes.rb:24)) is loosely grouped by domain (numbering, dates, nature/montants, etc.). Adding `:titre, :categorie_t2` at the **end** of the symbol list (before the trailing `type_observations: []` hash) keeps the diff small and easy to review. A future cleanup could regroup all params by domain — out of scope.

### Pitfall — admin user authentication in tests

The codebase has two Devise models: `User` (for the user-facing app, at [app/models/user.rb](app/models/user.rb)) and `AdminUser` (for ActiveAdmin, at [app/models/admin_user.rb](app/models/admin_user.rb)). The Story 3.3 controller tests sign in as `User`. **The new admin tests need to sign in as `AdminUser`** via either:
1. `Devise::Test::IntegrationHelpers` — `sign_in admin_users(:admin)` (preferred, idiomatic)
2. Direct POST to `/admin_users/sign_in` — verbose but works without test_helper modification

Check [test/test_helper.rb](test/test_helper.rb) for the existing setup and prefer option 1 if Devise helpers are already included.

### Project Structure Notes

- **No new files** required except the test file ([test/admin/actes_admin_test.rb](test/admin/actes_admin_test.rb)) — all changes are edits to existing files.
- **Edited files**: [app/admin/actes.rb](app/admin/actes.rb), [app/models/t2_detail.rb](app/models/t2_detail.rb), [app/models/acte.rb](app/models/acte.rb) (1-line addition to ransackable_associations).
- **No new gems** — ActiveAdmin (already in Gemfile), Devise (already in Gemfile).
- **No new routes** — ActiveAdmin auto-generates from `register Acte`.
- **No new migrations** — schema is complete (per AC9).

### Testing standards

- Tests live under [test/](test/), grouped by type: `controllers/`, `models/`, `system/`. Create a new `test/admin/` directory for ActiveAdmin-specific tests (the existing codebase has no admin tests yet — verify by `ls test/admin/` returning "No such file or directory").
- Pattern from existing tests at [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb): use `ActionDispatch::IntegrationTest`, fixtures from [test/fixtures/](test/fixtures/), Devise sign-in helpers.
- For ActiveAdmin response assertions, simple `assert_includes @response.body, "Détails T2"` is sufficient — no need for HTML parsing libs. ActiveAdmin renders deterministic HTML.
- For Ransack filter assertions, use the URL form `get '/admin/actes', params: { q: { titre_eq: 'T2' } }` and assert response body content (no DOM walking).
- The new test file should run in <1s — these are integration tests, not system/browser tests.

### References

- Epic spec — Story 3.4: [_bmad-output/planning-artifacts/epics-t2-integration.md:589-603](_bmad-output/planning-artifacts/epics-t2-integration.md:589)
- ActiveAdmin file (target of all changes): [app/admin/actes.rb](app/admin/actes.rb) (305 lines)
- Acte model — validations, ransackable, T2 fields: [app/models/acte.rb](app/models/acte.rb)
- T2Detail model — currently 5 lines, needs ransackable + (optional) display helpers: [app/models/t2_detail.rb](app/models/t2_detail.rb)
- Schema — `t2_details` table (32 data columns): [db/schema.rb:503-545](db/schema.rb:503)
- Schema — `actes.titre` / `actes.categorie_t2`: [db/schema.rb:28,81](db/schema.rb:28)
- User-facing show partials for T2 sections (reference for field grouping order): [app/views/actes/t2_sections/_show_annexe_financiere.html.erb](app/views/actes/t2_sections/_show_annexe_financiere.html.erb), [_show_isp.html.erb](app/views/actes/t2_sections/_show_isp.html.erb), [_show_fongibilite_asymetrique.html.erb](app/views/actes/t2_sections/_show_fongibilite_asymetrique.html.erb), [_show_marche.html.erb](app/views/actes/t2_sections/_show_marche.html.erb), [_show_mesure_transversale.html.erb](app/views/actes/t2_sections/_show_mesure_transversale.html.erb), [_show_enveloppe_limitative.html.erb](app/views/actes/t2_sections/_show_enveloppe_limitative.html.erb), [_show_referentiel.html.erb](app/views/actes/t2_sections/_show_referentiel.html.erb)
- T2 natures source (user-facing controller): [app/controllers/actes_controller.rb:1249](app/controllers/actes_controller.rb:1249) (DCB), [actes_controller.rb:1251](app/controllers/actes_controller.rb:1251) (CBR), [actes_controller.rb:1254](app/controllers/actes_controller.rb:1254) (Organisme)
- HT2 natures source: [actes_controller.rb:1329](app/controllers/actes_controller.rb:1329) (avis), [actes_controller.rb:1333](app/controllers/actes_controller.rb:1333) (visa)
- ActiveAdmin Devise admin auth: [config/initializers/active_admin.rb](config/initializers/active_admin.rb)
- AdminUser model: [app/models/admin_user.rb](app/models/admin_user.rb)
- Story 1.1 — table rename + titre/categorie_t2 columns (where the data foundation comes from): [_bmad-output/implementation-artifacts/1-1-renommer-la-table-ht2-actes-en-actes.md](_bmad-output/implementation-artifacts/1-1-renommer-la-table-ht2-actes-en-actes.md)
- Story 1.2 — t2_details table: [_bmad-output/implementation-artifacts/1-2-creer-la-table-t2-details.md](_bmad-output/implementation-artifacts/1-2-creer-la-table-t2-details.md)
- Story 1.3 — Acte model T2 association + validations: [_bmad-output/implementation-artifacts/1-3-mettre-a-jour-le-modele-acte-renomme-depuis-ht2-acte.md](_bmad-output/implementation-artifacts/1-3-mettre-a-jour-le-modele-acte-renomme-depuis-ht2-acte.md)
- Story 3.3 — Excel exports (closest precedent for read-only T2 data rendering + array/decimal formatting patterns): [_bmad-output/implementation-artifacts/3-3-export-excel-incluant-les-actes-t2.md](_bmad-output/implementation-artifacts/3-3-export-excel-incluant-les-actes-t2.md)
- ActiveAdmin docs — Index pages: https://activeadmin.info/3-index-pages.html
- ActiveAdmin docs — Filters: https://activeadmin.info/3-index-pages.html#index-filters
- ActiveAdmin docs — Show pages: https://activeadmin.info/6-show-pages.html
- ActiveAdmin docs — Forms: https://activeadmin.info/5-forms.html
- Ransack docs — Authorising attributes / associations (Rails 7 / Ransack 4): https://activerecord-hackery.github.io/ransack/going-further/other-notes/#authorization-allowlisting-denylisting

### Previous Story Intelligence (Story 3.3)

- Story 3.3 confirmed that `acte.t2_detail&.<field>` is the canonical accessor (not a join on the actes table) — same applies here for the show page panel.
- Story 3.3 used `Array(value).join(', ')` for array columns and `number_to_currency(..., unit: '€', separator: ',', delimiter: ' ')` for money fields — **reuse the same formatters** in the admin show page for consistency.
- Story 3.3 introduced the helper [actes_helper.rb#t2_export_columns / t2_export_row](app/helpers/actes_helper.rb:215) for the xlsx exports. **Do NOT reuse this helper for the admin show page** — the helper is xlsx-row-oriented (returns symbols + values for cells), not Ruby-DSL-oriented (what we need for `attributes_table_for ... row :foo`). Build the show panel inline.
- Story 3.3 noted that the `t2_detail` may legitimately be nil for some T2 actes (Marché nature, partial imports) — covered by AC4's `if acte.t2_detail.present?` guard.
- Story 3.3 commit message convention: `feat: <description> (story X.Y)`. Same here: `feat: gestion des actes T2 dans ActiveAdmin (story 3.4)`.
- Story 3.3 final test suite: 179 runs, 1204 assertions, all green. The new ~9 tests from AC8 should bring the suite to ~188 runs without affecting existing tests.
- Story 3.3 also added two model-level dérogations to "no model change" rules: a guard in `Acte#associate_centre_financier` (HT2-only) and a partial fix in `_acte_details_t2.html.erb`. **This story has its own dérogation**: a 1-line change in `Acte.ransackable_associations` to add `"t2_detail"` (AC6). Document in Dev Notes / Completion Notes when done.

### Git Intelligence Summary

5 most recent commits on `actes` branch (target for this story):

- `9e1e0c9` `feat: ajout des exports Excel pour les actes T2 (story 3.3)` — Story 3.3 closing commit
- `9404655` `feat: refonte des filtres de recherche Titre/Périmètre et ajout des natures T2` (Story 3.2)
- `e4e85de` `feat: ajoute la colonne Titre (badge HT2/T2) sur la Liste de travail et l'Historique (story 3.1)`
- `d92a5bb` `fix: correctifs des tests et vues liés à l'affichage des détails pour les actes T2`
- `c5cff4a` `feat: extension du modal nouvel acte pour ajouter le support du type d'acte T2`

Working tree at story creation: clean (Story 3.3 fully committed). Start Story 3.4 on a clean base — no prerequisites to land first.

Patterns established in Stories 3.1–3.3 that we should reuse:
- `Array(value).join(', ')` for array columns (consistent with [generate_backup_job.rb:65](app/jobs/generate_backup_job.rb:65))
- `number_to_currency(value, unit: '€', separator: ',', delimiter: ' ')` for money rendering
- `&.strftime('%d/%m/%Y')` for date null-safe FR rendering
- Single commit per story (no bundling) — convention from Story 3.2 / 3.3 commit logs
- Test grouping comment `# ─── Story X.Y ───` at the section header

### Latest Tech Information

- **ActiveAdmin** (check Gemfile for exact version) — `register Acte` DSL, `attributes_table_for` for nested objects, `filter :foo, as: :select` for Ransack-backed filters. All features used in this story are stable across AA 2.x and 3.x.
- **Ransack** (4.x by default on Rails 7) — requires explicit `ransackable_attributes` / `ransackable_associations` declarations on every model used in a filter. Throws `Ransack::InvalidSearchError` on unauthorised attribute access. The `Acte` model already has its declarations ([acte.rb:67-72](app/models/acte.rb:67)); `T2Detail` does not — this story adds them (AC6).
- **Devise** — admin auth via `AdminUser` Devise model, separate from the user-facing `User` model. Test sign-in uses `Devise::Test::IntegrationHelpers` (verify inclusion in test_helper).
- **Rails 7.1+** — `params[...].permit(...)` semantics unchanged; ActiveAdmin's `permit_params` wraps this and is fully compatible.

## Dev Agent Record

### Agent Model Used

claude-opus-4-7

### Debug Log References

- **RED phase initial** : 14 tests créés, tous échouent (12 sur 404 → mauvaise route, 2 sur validations setup).
- **Route correction** : `/admin/actes` → `/anaco/admin/actes` (le scope `:anaco` dans [config/routes.rb](config/routes.rb) préfixe toutes les routes admin). Documenté ci-dessous.
- **Fixture acte T2 Marché perimetre etat** : nécessite `montant_ae` (validation [acte.rb:90](app/models/acte.rb:90)). Setup ajusté.
- **Numero_formate auto-généré** : `after_save :set_numero_utilisateur` ([acte.rb:613](app/models/acte.rb:613)) écrase le numero_formate fourni au create — assertions test adaptées pour utiliser `id="acte_<id>"` (assertion structurelle) au lieu d'un numero_formate fragile.
- **`Marché unique` dans le rendu page** : présent dans la liste déroulante du filtre Nature même quand la table est filtrée → assertion sur `assert_not_includes` faite via parsing des `id="acte_(\d+)"` au lieu de `assert_not_includes "Marché unique"`.

### Completion Notes List

- **ActiveAdmin index** : 2 nouvelles colonnes (`titre`, `categorie_t2`) insérées entre `type_acte` et `etat`. Pas de reordonnancement des colonnes existantes — préserve les habitudes admin.
- **ActiveAdmin filtres** : 2 nouveaux filtres select (`titre`, `categorie_t2`) + upgrade `nature` de free-text vers select (collection `NATURES_FILTER_COLLECTION`, 30 valeurs HT2 + T2 dédupliquées triées). Tous les autres filtres préservés.
- **ActiveAdmin show** : 2 nouvelles `row` (`titre`, `categorie_t2`) dans la table principale + nouveau `panel 'Détails T2'` conditionnel (`if acte.titre == 'T2'`) avec 32 lignes du `t2_detail`, formatage decimal/array, fallback "Aucun T2Detail associé" si nil. HT2 reste byte-identique à l'avant (test #5 régression guard).
- **ActiveAdmin form** : `permit_params` étendu avec `:titre, :categorie_t2`. Nouvelle section `f.inputs 'Classification T2'` avec 2 selects, insérée après `'Informations générales'`. Section toujours visible (HT2 comme T2) — admin peut corriger des classifications post-import.
- **Validation `no_t2_detail_for_ht2`** : déjà en place ([acte.rb:586](app/models/acte.rb:586)), automatiquement appliquée à l'update admin. Test #9 confirme le blocage côté Rails — ActiveAdmin re-rend le formulaire en cas d'erreur.
- **Ransackable T2Detail** : whitelist complète des 38 attributs (32 colonnes data + id/acte_id + 2 timestamps + alias). Préviens toute `Ransack::InvalidSearchError` future sur les filtres `t2_detail_*`. Association `acte` également whitelistée (pour `t2_detail.acte_titre_eq=T2` à l'avenir).
- **Ransackable Acte** : `t2_detail` ajouté à `ransackable_associations` (alpha order préservé). Permet `q[t2_detail_xxx_eq]` côté admin si jamais on en a besoin.
- **Routes** : ⚠️ Le scope est `/anaco/admin/...` et non `/admin/...` (cf. [config/routes.rb](config/routes.rb) `scope '/anaco'`). La story 3.4 plan mentionnait `/admin/actes` partout — c'est nominal côté docs ActiveAdmin mais le projet ajoute un préfixe. Documenté ici pour les futures stories admin.
- **`config/initializers/active_admin.rb`** : utilise `authenticate_admin_user!` (ligne 74) — la table `admin_users` est distincte de `users`. Fixture `admin_users.yml` créée (était vide depuis init).
- **Tests** : 14 tests (au-delà des 9 prévus en AC8) avec parsing structurel des `id="acte_<id>"` HTML pour des assertions robustes. Tous verts.
- **Suite complète** : 193 runs / 1296 assertions / 0 failures (avant Story 3.4 : 179/1204 — Δ exactement +14/+92).
- **Décisions tenues** :
  - Pas de `register T2Acte` séparé — single resource + filtre (cf. story plan).
  - Édition de `t2_detail` hors scope — panel lecture seule.
  - Section `Classification T2` always-visible pour HT2 + T2.
- **Hors-scope confirmé** : aucune migration, aucun helper Stimulus pour cacher `categorie_t2` quand `titre=HT2` (la validation modèle suffit).
- **Note de tech-debt à reporter en rétrospective** : la constante `NATURES_FILTER_COLLECTION` dans [actes.rb:25-46](app/admin/actes.rb:25) duplique la connaissance des natures HT2/T2 déjà éparpillée dans [actes_controller.rb:1249,1329,1333](app/controllers/actes_controller.rb:1249). Refacto possible vers `Acte::NATURES_HT2_VISA / NATURES_HT2_AVIS / NATURES_T2` partagés. Pas urgent.

### Change Log

- 2026-05-19 (post-impl — demande utilisateur) — Édition des champs `t2_detail` ajoutée au formulaire admin :
  - Nouvelle section `f.inputs 'Détails T2 (édition admin — toutes natures à plat)'` conditionnelle sur `f.object.titre == 'T2'`, insérée après `'Classification T2'` ([actes.rb:326-388](app/admin/actes.rb:326)).
  - 32 inputs à plat — pas de conditional rendering perimetre/nature (l'admin assume la cohérence des valeurs). Booleans / decimaux / strings / datepicker.
  - 5 colonnes array (`grade`, `isp_cercle1_natures`, `isp_cercle2_natures`, `perimetre_mesure`, `origine_financement`) exposées comme input texte CSV avec hint "Liste séparée par des virgules". Conversion CSV → `Array<String>` côté serveur dans le `before_action` existant ([actes.rb:65-78](app/admin/actes.rb:65)).
  - `permit_params` étendu avec `t2_detail_attributes: [...]` (33 clés scalars + 5 keys array).
  - Si `acte.t2_detail.nil?` au moment de l'édition d'un T2 (cas Marché légitime), `f.object.build_t2_detail` crée un détail vide en mémoire pour rendre la section éditable. La sauvegarde via `accepts_nested_attributes_for :t2_detail, reject_if: :all_blank` ([acte.rb:21](app/models/acte.rb:21)) ne persiste pas le détail si tous les champs restent blancs — comportement souhaité.
  - 4 nouveaux tests ajoutés dans [test/admin/actes_admin_test.rb](test/admin/actes_admin_test.rb).
  - Suite complète : 197 runs / 1311 assertions / 0 failures (+4 tests / +15 assertions vs. premier passage Story 3.4).

- 2026-05-19 — Story 3.4 implémentée. ActiveAdmin pour `Acte` étendu pour T2 :
  - Index : `column :titre` + `column :categorie_t2`
  - Filtres : `filter :titre` (select) + `filter :categorie_t2` (select) + `filter :nature` upgradé en select avec collection HT2+T2 dédupliquée
  - Show : `row :titre` + `row :categorie_t2` + nouveau panel `Détails T2` conditionnel rendant les 32 colonnes `t2_details`
  - Form : section `Classification T2` (2 inputs) + `permit_params` étendu
  - Ransackable : whitelist complète `T2Detail` + ajout `t2_detail` aux associations `Acte`
- Fichiers : 8 fichiers touchés (6 app + 2 test). Aucune migration, aucune route, aucun gem ajouté.

### File List

**Production (app/)** :
- [app/admin/actes.rb](app/admin/actes.rb) — refonte du fichier ActiveAdmin (index, filters, show, form) — +120 lignes
- [app/models/t2_detail.rb](app/models/t2_detail.rb) — ajout des 2 méthodes `ransackable_*`
- [app/models/acte.rb](app/models/acte.rb) — 1 ligne : `t2_detail` ajouté à `ransackable_associations`

**Tests (test/)** :
- [test/admin/actes_admin_test.rb](test/admin/actes_admin_test.rb) — nouveau fichier, 14 tests d'intégration
- [test/fixtures/admin_users.yml](test/fixtures/admin_users.yml) — fixture `:one` peuplée (était stub vide)

**Story tracking (_bmad-output/)** :
- [_bmad-output/implementation-artifacts/sprint-status.yaml](_bmad-output/implementation-artifacts/sprint-status.yaml) — statut `backlog` → `in-progress` → `review`
- [_bmad-output/implementation-artifacts/3-4-gestion-des-actes-t2-dans-activeadmin.md](_bmad-output/implementation-artifacts/3-4-gestion-des-actes-t2-dans-activeadmin.md) — story file, sections Tasks/Dev Agent Record/File List/Change Log mises à jour
