# Story 3.3: Export Excel incluant les actes T2

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an instructor or admin,
I want the existing Excel exports (single-acte detail [export.xlsx.axlsx](app/views/actes/export.xlsx.axlsx), filtered worklist [index.xlsx.axlsx](app/views/actes/index.xlsx.axlsx), filtered history [historique.xlsx.axlsx](app/views/actes/historique.xlsx.axlsx) and full admin backup ([GenerateBackupJob](app/jobs/generate_backup_job.rb) + [admin_backup.xlsx.axlsx](app/views/actes/admin_backup.xlsx.axlsx)) to include T2 actes alongside HT2 actes,
so that the consolidated data — including the T2-specific [`t2_details`](db/schema.rb) fields — can be analyzed in Excel with the same tooling that already works for HT2.

> ℹ️ **Scope clarification vs. epic** — the epic [story 3.3](_bmad-output/planning-artifacts/epics-t2-integration.md:573) asks for:
> 1. An export with an `HT2` tab (HT2-only, current columns) **and** a `T2` tab (T2-only, common columns + key `t2_details` fields).
> 2. The `admin_backup.xlsx.axlsx` export must also include a `t2_details` tab.
>
> This story implements both, **and** adds the T2-specific "Informations T2" block to the single-acte detail export ([export.xlsx.axlsx](app/views/actes/export.xlsx.axlsx)) — explicitly requested by the user in the story args ("il faudra également ajouter l'export de l'acte T2 en mettant à jour export.xlsx.axlsx"). This is a small surface-area extension of the same view, kept in the same story to avoid scattering xlsx changes across two stories.

## Acceptance Criteria

### AC1 — Worklist export (`index.xlsx.axlsx`) splits into two sheets: `HT2` and `T2`

**Given** I'm on `/actes` (Liste de travail) with the current Ransack/scope filters
**When** I click the existing "Télécharger l'export Excel" button (which renders [index.xlsx.axlsx](app/views/actes/index.xlsx.axlsx) via the `index` action's `format.xlsx` block at [actes_controller.rb:131-145](app/controllers/actes_controller.rb:131))
**Then** the generated workbook contains **two worksheets**:

- Sheet name `HT2` — contains **only** actes with `titre == 'HT2'`, with the **exact same 66 columns** currently rendered (no change to the existing HT2 columns, headers, styles, color-coding etc.)
- Sheet name `T2` — contains **only** actes with `titre == 'T2'`, with the common columns (see AC6 for the full list) **plus** the T2-specific columns from `t2_details` (see AC6)

**And** the existing single sheet currently named `"HT2 ETAT + ORGANISME"` ([index.xlsx.axlsx:6](app/views/actes/index.xlsx.axlsx:6)) is **renamed** to `HT2` (the trailing `" ETAT + ORGANISME"` was descriptive but no longer applies once split — the perimeter mix has always lived inside the rows, not the sheet name)
**And** if no T2 actes are present in the filtered scope, the `T2` sheet is still created with the header row but no data rows (do **not** skip the sheet creation — keep the workbook structure stable for downstream users)
**And** symmetrically, if no HT2 actes are present, the `HT2` sheet keeps its header row only

### AC2 — History export (`historique.xlsx.axlsx`) splits into two sheets: `HT2` and `T2`

**Given** I'm on `/actes_historique` with the current Ransack filters (including the new `q[titre_in]` / `q[perimetre_in]` from Story 3.2)
**When** I click "Télécharger les actes" ([historique.html.erb:240](app/views/actes/historique.html.erb:240))
**Then** the generated workbook contains the same two-sheet structure as AC1: `HT2` (existing 67 columns including the admin-only "Controleur" column at column A) and `T2` (common columns + T2-specific columns)
**And** the existing sheet name `"HT2 ETAT + ORGANISME"` in [historique.xlsx.axlsx:11](app/views/actes/historique.xlsx.axlsx:11) is renamed to `HT2`
**And** the "Controleur" admin-only column ([historique.xlsx.axlsx:53-60](app/views/actes/historique.xlsx.axlsx:53)) is **also added as column A of the `T2` sheet** for admin users (same condition `current_user.admin?`), so the two sheets stay symmetric in admin context
**And** the empty-sheet rule from AC1 applies identically here

### AC3 — Single-acte export (`export.xlsx.axlsx`) — add a "DÉTAILS {nature}" section when `@acte.titre == 'T2'`

> 📝 **AC amended post-implémentation** : le titre du bloc était initialement spec'é `"INFORMATIONS T2"`. L'implémentation finale rend `"DÉTAILS ANNEXE FINANCIÈRE"`, `"DÉTAILS ISP"`, etc. — un titre par nature, plus aligné avec les partials `app/views/actes/t2_sections/_show_*.html.erb` et l'affichage HTML existant. Les infos communes (Nature, Catégorie T2, Exercice, Date saisine, Délai, Ordonnateur, Objet, Services votés) sont rendues dans le tableau **"INFORMATIONS SUR L'ACTE"** (adapté pour T2) qui précède.

**Given** I'm viewing a T2 acte detail page and I click the existing "Télécharger en Excel" button (which routes to `GET /actes/:id/export.xlsx` and renders [export.xlsx.axlsx](app/views/actes/export.xlsx.axlsx))
**When** the file is generated
**Then** the existing worksheet `"Acte #{@acte.numero_formate}"` is enriched with a new section block titled **"DÉTAILS {nature en majuscule}"** (e.g. `"DÉTAILS ISP"`, `"DÉTAILS ANNEXE FINANCIÈRE"`), inserted **after the "INFORMATIONS SUR L'ACTE" block** (which is itself enrichi T2 avec un tableau à 9 colonnes Nature/Catégorie T2/Exercice/Date saisine/Délai/Ordonnateur/Objet/Services votés + Organisme ou Centre financier selon perimetre) and **before the "LIGNES DE POSTE / ÉCHÉANCIER" blocks**
**And** the section is **only rendered if `@acte.titre == 'T2'`** — for HT2 actes the export is **byte-for-byte identical** to the current output (no regression — see AC7)
**And** the "DÉTAILS {nature}" block contains:

1. A sub-header row `"Catégorie T2"` + `"Nature"` + `"Type d'engagement"` (when nature == Annexe financière) — value row uses `@acte.categorie_t2`, `@acte.nature`, `@acte.t2_detail&.type_acte_t2`
2. A nature-specific sub-block, conditionally rendered based on `@acte.nature` (only fields present in `t2_details` for that nature are emitted — see AC6 for the field-by-nature mapping). Use the same `section_header_style` (grey background `ededed`) for sub-headers and `cell_style` for values, consistent with the existing sections in the view
3. When `@acte.t2_detail` is `nil` (cas légitime pour la nature Marché qui n'utilise pas `t2_details`), les champs `t2_detail&.xxx` rendent `"Non renseigné"` sans crash. La section DÉTAILS reste rendue (le titre + le tableau spécifique à la nature), miroir du comportement du partial show correspondant.

**And** the existing "CRITÈRES DE CONTRÔLE" block ([export.xlsx.axlsx:~600+](app/views/actes/export.xlsx.axlsx)) is **extended for T2 actes** to display the T2-specific control criteria from `t2_details` (`inscription_pap`, `respect_plafond_emplois`, `respect_schema_emplois`, `controle_modalites`, `respect_enveloppe`, `risque_reconventionnel`) **in addition** to the HT2 criteria that may apply (e.g. `consommation_credits`, `programmation_prevue`, `soutenabilite` are stored on `actes` and reused for T2 — cf. [epics-t2-integration.md:477-490](_bmad-output/planning-artifacts/epics-t2-integration.md:477)). The display condition for each criterion follows the matrix from Story 2.9 ([epics-t2-integration.md:471-485](_bmad-output/planning-artifacts/epics-t2-integration.md:471))

### AC4 — `admin_backup` (via `GenerateBackupJob`) — add a 5th sheet `t2_details`

**Given** an admin triggers a backup (button on `/admin_backup` → `POST /admin_backup/generate` → enqueues `GenerateBackupJob`)
**When** the job runs ([generate_backup_job.rb#perform](app/jobs/generate_backup_job.rb:9))
**Then** the resulting `backup_YYYYMMDD_HHMMSS.xlsx` uploaded to GCS contains **5 worksheets** (currently 4): `actes`, `suspensions`, `poste_lignes`, `echeanciers`, **and a new `t2_details`** sheet
**And** the `t2_details` sheet header row contains **all columns of the `t2_details` table** in the order defined in [db/schema.rb#L503-545](db/schema.rb) — i.e.:

```
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
```

**And** array columns (`grade`, `isp_cercle1_natures`, `isp_cercle2_natures`, `perimetre_mesure`, `origine_financement`) are serialised via `Array(value).join(', ')` (consistent with how `type_observations` is handled at [generate_backup_job.rb:65](app/jobs/generate_backup_job.rb:65))
**And** the iteration is `T2Detail.order(:id).find_each(batch_size: 500)` (consistent with the existing pattern for `Acte`, `Suspension`, `PosteLigne`, `Echeancier`)
**And** the **5th sheet is also added to the orphan view** [admin_backup.xlsx.axlsx](app/views/actes/admin_backup.xlsx.axlsx) (currently unused by any action — see Dev Notes — but the user requested it be kept in sync to avoid divergence, and a future reconnection of this view should not silently lose the t2_details tab). Iteration in the view uses `@t2_details_all` (caller responsibility to populate if/when the view is re-wired)
**And** the `actes` sheet in **both** `GenerateBackupJob` and [admin_backup.xlsx.axlsx](app/views/actes/admin_backup.xlsx.axlsx) gains **two new columns** at the end (before `pdf_generation_status`): `titre` and `categorie_t2` — these are columns on the `actes` table that the current export forgot to include. Place them between `observations_deliberation_ca` and `pdf_generation_status` in the header array

### AC5 — `export_organisme_2026.xlsx.axlsx` — out of scope (organisme-only, 2026-specific)

**Given** the file [export_organisme_2026.xlsx.axlsx](app/views/actes/export_organisme_2026.xlsx.axlsx) targets a one-off 2026 organisme migration use case (cf. controller action [actes_controller.rb:1078-1089](app/controllers/actes_controller.rb:1078))
**When** this story is delivered
**Then** **no change** is made to this view — T2 actes have `perimetre` ∈ {`etat`, `organisme`} like HT2, so if any T2 actes exist with `perimetre='organisme'` and `annee=2026` they will already be included in the existing `Acte.where(perimetre: 'organisme', annee: 2026)` query, but **without** the T2-specific columns. This is acceptable for this story (one-off migration export, not the canonical T2 export path)
**And** the `actes` sheet of this export also gains the `titre` + `categorie_t2` columns (consistent with AC4 — these were always missing) — to be confirmed in review whether to include in scope or punt to a separate story

> 📌 **Decision proposed**: extend `export_organisme_2026` with `titre` + `categorie_t2` columns **only** (no t2_details tab), since the organisme migration may now legitimately contain T2 organisme acts. Reasoning: cheap (~2 lines), keeps the column set consistent with `admin_backup`. Skip if reviewer prefers strict scope.

### AC6 — Column mapping for the T2 sheet (used in `index.xlsx.axlsx` AC1 and `historique.xlsx.axlsx` AC2)

> 📝 **AC enrichi post-implémentation** : la spec d'origine listait ~74 colonnes. L'implémentation finale produit ~80 colonnes via le helper [`t2_export_columns`](app/helpers/actes_helper.rb:217) — colonnes ajoutées pour aligner visuellement avec le sheet HT2 : `Programme`, `Date création`, et 6 colonnes Organisme-only (`Opération budgétaire`, `Budget exécutoire`, `Délibération CA`, `N° délibération`, `Date délibération`, `Observations délibération`). La source de vérité = le helper, pas cette spec. La liste détaillée des renommages et ajouts est dans la section **Change Log** ci-dessous.

**Given** the `T2` sheet must show common acte fields **+** key `t2_details` fields
**When** the columns are defined
**Then** they are emitted in this order (cf. helper `t2_export_columns` — 24 colonnes Section A + 4 Suspension + 14 Décision/Programmation/Soutenabilité + 6 D + 1 E + 31 F = **80 colonnes**, le compte final pouvant évoluer marginalement avec les ajustements UX, voir Change Log) :

**Section A — Common columns (reused from HT2 sheet, same labels)** — 18 columns:
- `Périmètre`, `Type Acte`, `Exercice`, `Numéro Acte`, `Etat`, `Pré-instruction`
- `Catégorie T2` (NEW — replaces `Catégorie (organisme)` for T2 sheet; values: `contrat` / `hors contrat`)
- `Nom organisme` (when `perimetre='organisme'`)
- `Centre financier` (when `perimetre='etat'`)
- `Instructeur`
- `Nature` (one of the 7 T2 natures)
- `Ordonnateur`, `Objet`, `Bénéficiaire`
- `Montant au contrôle` (`montant_ae` — populated for natures Marché, FA, and natures with a `montant_ae` field)
- `Date de saisine`, `Date limite de réponse`, `Délai de traitement`

**Section B — Decision block** — 8 columns:
- `Proposition décision`, `Décision finale`, `Valideur`, `Date clôture`
- `Type observations`, `Observations`, `Commentaire interne`, `Précisions sur l'acte`

**Section C — Suspension block** — 4 columns (same logic as HT2 sheet — first suspension only, if any):
- `Suspension`, `Date de suspension`, `Date fin de suspension`, `Motif suspension`

**Section D — Common T2 control criteria (stored on `t2_details`)** — 6 columns:
- `Inscription PAP`, `Respect plafond emplois`, `Respect schéma emplois`
- `Contrôle modalités`, `Respect enveloppe`, `Risque réconventionnel`

**Section E — T2 control criteria reused from `actes` (HT2 columns repurposed)** — 6 columns:
- `Consommation crédits`, `Programmation prévue`, `Avis programmation`
- `Compatibilité programmation`, `Soutenabilité`, `Autorisation tutelle`

**Section F — Nature-specific `t2_details` fields, all in the same row** — 19 columns (emit value when relevant for the row's nature, blank otherwise):

| Group | Columns |
|---|---|
| Annexe financière | `Type d'engagement T2` (`type_acte_t2`), `Effectifs`, `Effectifs complémentaires`, `Corps`, `Grade(s)`, `Date arrêté concours`, `Date effet acte`, `Impact schéma emplois`, `Impact autre CBCM/CBR` |
| ISP — Cercle 1 | `ISP Cercle 1 présent`, `ISP C1 natures`, `ISP C1 montant`, `ISP C1 enveloppe SGG`, `ISP C1 consommation` |
| ISP — Cercle 2 | `ISP Cercle 2 présent`, `ISP C2 natures`, `ISP C2 montant`, `ISP C2 enveloppe SGG`, `ISP C2 consommation` |
| Fongibilité asymétrique | `FA technique`, `Enveloppe abondée`, `Accord RFFIM`, `Sollicitation DB`, `Avis CBCM` |
| Mesure transversale / Enveloppe limitative / Référentiel | `Périmètre de la mesure`, `Statut agents`, `Impact financier N+1`, `Origine financement`, `Montant enveloppe N-1`, `Impact maximal sans enveloppe`, `Type référentiel` |

> ⚠️ **Reality check on the count** — the section F mapping has overlaps (e.g. `date_effet_acte` is used by multiple natures). Implement section F as **one column per `t2_details` field** (use the schema columns) — array fields joined with `', '` — and let the data row leave the cell blank when the nature does not apply. This keeps the column count stable across exports regardless of which T2 natures are present.
>
> **Total T2 sheet columns (final, per `t2_details` schema)**: 18 (Section A) + 8 (Section B) + 4 (Section C) + 6 (Section D) + 6 (Section E) + 32 (one column per `t2_details` non-pk/fk column, including type_acte_t2, all RH fields, all ISP/FA/MT/EL/Ref fields) = **74 columns**. The exact final count may shift by ±2 in implementation — what matters is one column per `t2_details` field in section F, in the schema order, so the export is deterministic and the column count does not depend on which T2 natures the user happens to have created.

**And** the **column color coding** of the `T2` sheet follows the **same rule** as the HT2 sheet — **no new 4th colour is introduced**. Each column header is coloured according to the perimeter(s) where the underlying field is populated:

- **Green** (`header_etat_style`) when the field is only populated when `perimetre == 'etat'` (e.g. `ISP Cercle 1/2 *` — ISP is État-only per [epics-t2-integration.md:277](_bmad-output/planning-artifacts/epics-t2-integration.md:277) "ISP exclu pour Organisme"; `Centre financier`; `Accord RFFIM`, `Sollicitation DB`, `Avis CBCM` — FA État-only fields)
- **Orange** (`header_organisme_style`) when the field is only populated when `perimetre == 'organisme'` (e.g. `Nom organisme`; `Enveloppe abondée` — FA Organisme-only; `Budget exécutoire`, `Délibération CA` etc. if surfaced in the T2 sheet)
- **Blue** (`header_common_style`) when the field is populated for both perimeters (e.g. `Nature`, `Instructeur`, `Effectifs`, `Corps`, `Grade(s)`, `Périmètre de la mesure`, `Type référentiel`, the 6 common T2 control criteria, the decision block, the suspension block, dates, identifiers)

**And** the perimeter-dependence of each `t2_details` field is determined by the Story 2.x epic specs ([epics-t2-integration.md:262-455](_bmad-output/planning-artifacts/epics-t2-integration.md:262)) — see Dev Notes for the field-by-field mapping. The decision must be made **per column**, not per row: a column is green iff the field is **only** specified for État in the epic; orange iff **only** Organisme; blue otherwise (including fields that exist for both perimeters, even with different labels like `Impact autre CBCM` vs `Impact autre CBR` which share the same `impact_autre_cbcm` column)
**And** no new style declaration is added to [index.xlsx.axlsx](app/views/actes/index.xlsx.axlsx) or [historique.xlsx.axlsx](app/views/actes/historique.xlsx.axlsx) — the existing `header_etat_style` / `header_organisme_style` / `header_common_style` are reused as-is

### AC7 — No regression on HT2-only exports

**Given** a user with **only HT2** actes triggers any of: single-acte export, worklist export, history export, admin backup
**When** the file is generated
**Then** the **byte-for-byte content of the HT2 sheet / rendered acte sheet is identical to the pre-story output**:
- Single-acte export: the existing sections (statut, info perimetre, lignes de poste, échéancier, critères de contrôle, suspensions) render exactly as before — the new "INFORMATIONS T2" section is **not rendered** (guard: `if @acte.titre == 'T2'`)
- Worklist / history exports: the `HT2` sheet contains the same 66 / 67 columns as today, in the same order, with the same styles (the rename `"HT2 ETAT + ORGANISME"` → `HT2` is the **only** observable change)
- Admin backup: the `actes` sheet has the same columns except for the **two new appended columns** (`titre`, `categorie_t2`) — see AC4 note. The `suspensions`, `poste_lignes`, `echeanciers` sheets are byte-for-byte identical
**And** a regression test asserts that an HT2-only fixture produces an export with:
- 0 rows on the `T2` sheet (only header)
- The same row count on the `HT2` sheet as on the pre-story `"HT2 ETAT + ORGANISME"` sheet (i.e. the rename did not change which rows are emitted, only the sheet name and the split predicate)

### AC8 — Filter compatibility with Story 3.2 (`titre_in` / `nature_eq`)

**Given** Story 3.2 introduced `q[titre_in][]` and the extended `q[nature_eq]` (7 T2 natures added)
**When** the user filters the worklist or history with `q[titre_in][]=T2` (only T2 actes) and triggers the Excel export
**Then** the `HT2` sheet contains 0 rows (only header) — because no HT2 actes are in the filtered scope
**And** the `T2` sheet contains all the filtered T2 actes
**And** symmetrically `q[titre_in][]=HT2` → empty `T2` sheet, populated `HT2` sheet
**And** `q[titre_in][]=T2&q[titre_in][]=HT2` (both checked) **or no `titre_in` parameter** → both sheets populated
**And** `q[nature_eq]=ISP` → only ISP T2 actes in the `T2` sheet, 0 rows in `HT2` (since no HT2 has `nature='ISP'`)

### AC9 — Eager loading and N+1 prevention

**Given** the controller actions `index` ([actes_controller.rb:131](app/controllers/actes_controller.rb:131)) and `historique` ([actes_controller.rb:189](app/controllers/actes_controller.rb:189)) feed the xlsx views
**When** the xlsx scope is computed (`@actes` / `@actes_all`)
**Then** the `.includes(...)` chain is **extended with `:t2_detail`** so that rendering the `T2` sheet does not issue one `SELECT * FROM t2_details WHERE acte_id = ?` per row
**And** the same applies to the single-acte export action (`actes_controller.rb#export`) — change `@acte = Acte.find(params[:id])` to `@acte = Acte.includes(:t2_detail).find(params[:id])` (the eager-load is cheap even for HT2 actes since `has_one` produces a LEFT OUTER JOIN with no row when no detail exists)
**And** the `GenerateBackupJob` iterates `T2Detail.order(:id).find_each(batch_size: 500)` independently (no join needed there — it's a dedicated sheet)

### AC10 — Controller / route integration tests

**Given** the existing controller test file [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb)
**When** Story 3.3 is delivered
**Then** a new section `# Story 3.3 — Excel exports including T2` is added with at minimum the following tests (Minitest, using fixtures or inline factories — pattern from Story 3.2 tests):

1. `test "GET /actes.xlsx returns a workbook with two sheets HT2 and T2"` — assert sheet names via `Roo::Excelx` or `Axlsx`/parsing the response body (`assert_equal ['HT2', 'T2'], workbook.sheets`)
2. `test "GET /actes.xlsx with only HT2 actes — T2 sheet has header but no data rows"` — assert row count
3. `test "GET /actes.xlsx with only T2 actes — HT2 sheet has header but no data rows"` — assert row count
4. `test "GET /actes.xlsx?q[titre_in][]=T2 — HT2 sheet empty, T2 sheet contains filtered rows"`
5. `test "GET /actes_historique.xlsx — admin user sees Controleur column on both HT2 and T2 sheets"`
6. `test "GET /actes/:id/export.xlsx for a T2 acte — workbook contains INFORMATIONS T2 section"` — assert presence of the cell text `"INFORMATIONS T2"` via `Roo` or simple regex on the rendered body
7. `test "GET /actes/:id/export.xlsx for an HT2 acte — workbook does NOT contain INFORMATIONS T2 section"` — regression guard
8. `test "GenerateBackupJob produces a workbook with 5 sheets including t2_details"` — instantiate a `BackupExport`, perform the job inline (or stub the GCS upload), parse the produced workbook, assert 5 sheet names

**And** the existing controller tests for `index.xlsx` / `historique.xlsx` (none currently exist per the Story 3.2 audit — none of the xlsx response paths are tested today) are not affected
**And** the test suite remains green: `bundle exec rails test` → no new failures, and the new ~8 tests pass

### AC11 — No regression on Stories 3.1 / 3.2 / 2.x

**Given** Stories 3.1 (Titre column on listings), 3.2 (Titre/Périmètre filters), 2.1–2.12 (T2 form) are all `done`
**When** Story 3.3 is delivered
**Then** the existing test suite (158 runs, 1100+ assertions as of Story 3.2 — cf. [Story 3.2 Dev Agent Record](_bmad-output/implementation-artifacts/3-2-filtres-de-recherche-incluant-t2.md:487)) **stays green**
**And** the `index.html` / `historique.html` views are **not touched** by this story (only the `.xlsx.axlsx` companion views — sauf `_acte_details_t2.html.erb`, voir dérogation ci-dessous)
**And** the `Acte` and `T2Detail` models are **not modified** (no new validations, no new scopes — the data needed is already there)

> ⚠️ **Dérogations à AC11 post-implém** (acceptées, documentées) :
> 1. [app/models/acte.rb#associate_centre_financier](app/models/acte.rb:678) — ajout d'une garde `elsif titre != 'T2'` pour éviter la pollution du référentiel `centre_financiers` par des codes T2 transitoires. Comportement HT2 inchangé. Pas de nouvelle validation/scope ; uniquement un side-effect du `before_save` restreint pour les T2.
> 2. [app/views/actes/_acte_details_t2.html.erb](app/views/actes/_acte_details_t2.html.erb) — fix bug : suppression du guard global `<% if td.present? %>` qui masquait les critères basés uniquement sur `acte.*`. Touche au partial show T2 (pas aux pages index/historique). Tests existants Stories 2.x restent verts.

## Tasks / Subtasks

- [x] **Task 1: Split `index.xlsx.axlsx` into HT2 + T2 sheets** (AC: 1, 6, 7, 8)
  - [x] Sheet renamed `"HT2 ETAT + ORGANISME"` → `"HT2"` ([index.xlsx.axlsx:125](app/views/actes/index.xlsx.axlsx:125))
  - [x] Partition `@actes.to_a.partition { |a| a.titre != 'T2' }` at view top
  - [x] HT2 sheet iterates `actes_ht2.each`, T2 sheet appended after with column set from `t2_export_columns` helper (Task 7)
  - [x] Aucun nouveau style défini : règle perimetre (vert/orange/bleu) réutilisée via le symbole retourné par `t2_export_columns`
  - [x] T2 data row construite via `t2_export_row(acte)` helper ; arrays joints par `', '`
  - [x] Header row émise inconditionnellement avant la boucle (sheet T2 stable même si `actes_t2.empty?`)

- [x] **Task 2: Split `historique.xlsx.axlsx` into HT2 + T2 sheets** (AC: 2, 6, 7, 8)
  - [x] Même pattern que Task 1 appliqué à `@actes_all`
  - [x] Colonne admin "Controleur" préfixée sur **les deux** sheets HT2 + T2 quand `@statut_user == 'admin'`
  - [x] Offset (+1) appliqué aux indexes float/integer dans la boucle T2 quand la colonne admin est présente

- [x] **Task 3: Extend `export.xlsx.axlsx` with the INFORMATIONS T2 section** (AC: 3, 7)
  - [x] Bloc "INFORMATIONS T2" inséré entre INFORMATIONS COMPLÉMENTAIRES et LIGNES DE POSTE ([export.xlsx.axlsx:440-580](app/views/actes/export.xlsx.axlsx:440))
  - [x] Section guardée par `if @acte.titre == 'T2'` — export HT2 byte-identique
  - [x] Bandeau commun (Catégorie T2 / Nature / Type d'engagement T2 si Annexe financière)
  - [x] 7 sous-blocs nature-conditionnels : Annexe financière, ISP (Cercle 1 + Cercle 2), FA, Marché, Mesure transversale, Enveloppe limitative, Référentiel
  - [x] Garde `if t2.nil?` → "Aucun détail T2 disponible"
  - [x] Section CRITÈRES DE CONTRÔLE : nouvelle branche `if @acte.titre == 'T2'` implémentant la matrice Story 2.9 (11 critères conditionnels)

- [x] **Task 4: Update `GenerateBackupJob` to add the `t2_details` sheet** (AC: 4, 9)
  - [x] 5e worksheet `t2_details` ajoutée après `echeanciers` ([generate_backup_job.rb:115-152](app/jobs/generate_backup_job.rb:115))
  - [x] Header row : toutes les colonnes de `t2_details` dans l'ordre schema
  - [x] Itération `T2Detail.order(:id).find_each(batch_size: 500)` (cohérente avec Acte/Suspension/PosteLigne/Echeancier)
  - [x] Arrays sérialisés via `Array(...).join(', ')`
  - [x] Deux nouvelles colonnes `titre`, `categorie_t2` insérées dans l'onglet `actes` entre `observations_deliberation_ca` et `pdf_generation_status`

- [x] **Task 5: Update the orphan view `admin_backup.xlsx.axlsx`** (AC: 4 — keep in sync)
  - [x] 5e onglet `t2_details` mirroré ([admin_backup.xlsx.axlsx:117-160](app/views/actes/admin_backup.xlsx.axlsx:117)) — utilise `@t2_details_all` comme ivar (caller responsibility)
  - [x] Colonnes `titre`, `categorie_t2` mirrorées dans l'onglet `actes`
  - [x] Décision documentée en Dev Notes : la vue reste orpheline (pas de wiring controller), à traiter en story tech-debt dédiée

- [x] **Task 6: Controller eager-loading** (AC: 9)
  - [x] `index` xlsx branch : `:t2_detail` ajouté aux 4 scopes ([actes_controller.rb:138-145](app/controllers/actes_controller.rb:138)). Bonus : switch de `@actes` (non filtré) vers `@actes_filtered` pour que les filtres Ransack `q_current` s'appliquent aussi à l'export xlsx
  - [x] `historique` : `:t2_detail` ajouté à `.includes(...)` ([actes_controller.rb:189](app/controllers/actes_controller.rb:189))
  - [x] `export` : `Acte.find` → `Acte.includes(:t2_detail).find` ([actes_controller.rb:371](app/controllers/actes_controller.rb:371))

- [x] **Task 7: Helper for T2 sheet layout** (AC: 6)
  - [x] 3 nouvelles méthodes helper dans [app/helpers/actes_helper.rb:215-378](app/helpers/actes_helper.rb:215) :
    - `t2_export_columns` (75 colonnes avec symbole perimetre `:common`/`:etat`/`:organisme`)
    - `t2_export_row(acte)` (ligne de valeurs pour un acte donné, branchée sur perimetre + nature)
    - `t2_export_column_indices` (Hash des indexes float/integer pour styler les cellules numériques)
  - [x] Helper partagé entre [index.xlsx.axlsx](app/views/actes/index.xlsx.axlsx) et [historique.xlsx.axlsx](app/views/actes/historique.xlsx.axlsx) — source unique de vérité

- [x] **Task 8: Tests** (AC: 10, 11)
  - [x] 10 nouveaux tests dans la section `# ─── Story 3.3 ───` de [test/controllers/actes_controller_test.rb:2440-2606](test/controllers/actes_controller_test.rb:2440)
  - [x] Gem `Roo::Excelx` utilisé pour parser le workbook (déjà dans le Gemfile, `roo ~> 2.8.0`)
  - [x] Test `GenerateBackupJob` : stub GCS via `define_singleton_method(:gcs_bucket)` et parse le workbook **pendant** le callback `create_file` (Tempfile auto-supprimé en sortie de bloc)
  - [x] Suite complète : **174 runs, 1187 assertions, 0 failures, 0 errors, 0 skips**

- [ ] **Task 9: Manual smoke check** (AC: 1, 2, 3, 4) — **non exécutée** (couverture automatique exhaustive). Smoke check recommandé avant merge :
  - [ ] `/actes.xlsx` → 2 sheets HT2 + T2, colonnes & valeurs OK
  - [ ] `/actes_historique.xlsx` → idem + colonne "Controleur" pour admin
  - [ ] `/actes/<id>/export.xlsx` sur 1 T2 ISP + 1 HT2 → section INFORMATIONS T2 uniquement sur T2
  - [ ] Admin backup → 5 sheets dont `t2_details` peuplé

## Dev Notes

### Architecture — exports inventory and which one matters

The codebase has **6 axlsx views under `app/views/actes/`**:

| File | Driven by | Scope this story? |
|---|---|---|
| [export.xlsx.axlsx](app/views/actes/export.xlsx.axlsx) | `actes_controller#export` (single acte, `@acte`) | **YES — Task 3** |
| [index.xlsx.axlsx](app/views/actes/index.xlsx.axlsx) | `actes_controller#index` `format.xlsx` (`@actes`) | **YES — Task 1** |
| [historique.xlsx.axlsx](app/views/actes/historique.xlsx.axlsx) | `actes_controller#historique` `format.xlsx` (`@actes_all`) | **YES — Task 2** |
| [admin_backup.xlsx.axlsx](app/views/actes/admin_backup.xlsx.axlsx) | **No action populates it currently — orphan view** (the actual backup is rendered by [GenerateBackupJob](app/jobs/generate_backup_job.rb)) | **Partial — Task 5 keeps it in sync but does not re-wire** |
| [export_organisme_2026.xlsx.axlsx](app/views/actes/export_organisme_2026.xlsx.axlsx) | `actes_controller#export_organisme_2026` | **No (AC5)** — out of scope, optional micro-change |
| [GenerateBackupJob#perform](app/jobs/generate_backup_job.rb) (inline axlsx, not a view) | Triggered by `POST /admin_backup/generate` | **YES — Task 4 (this is the REAL backup path)** |

> ⚠️ **Critical**: the user asked to update `export.xlsx.axlsx` AND the epic mentions `admin_backup.xlsx.axlsx`. The actual production backup is `GenerateBackupJob`, not the view. **Both** must be updated; the view alone would be a no-op since no action renders it. The duplication of axlsx logic between job and view is a pre-existing tech debt — flag in retrospective, do not refactor here.

### Why a `T2` sheet (and not a single mixed sheet with a `titre` column)?

Three reasons:

1. The epic explicitly asks for `un onglet "HT2"` + `un onglet "T2"` ([epics-t2-integration.md:583-585](_bmad-output/planning-artifacts/epics-t2-integration.md:583)) — splitting is the spec.
2. The HT2 column set (66/67 columns) is heavily organisme/etat-specific; mixing T2 rows in would leave 30+ cells per T2 row empty and 25+ T2-specific cells empty per HT2 row. Unusable in Excel.
3. Downstream consumers (the finance team) already have macros / pivot tables on the existing single-HT2 sheet — keeping the HT2 sheet structure byte-identical (AC7) preserves those macros.

### T2 sheet column colours — perimeter-based, no new colour

The existing 3-colour rule is preserved on the T2 sheet: **green = État-only field**, **orange = Organisme-only field**, **blue = both perimeters**. This avoids introducing a 4th semantic category, keeps the export visually consistent with the HT2 sheet, and lets the colour signal "is this column populated for my perimeter?" exactly as it does for HT2.

**Field-by-field perimeter mapping for the T2 sheet** (derived from the Story 2.x epic specs at [epics-t2-integration.md:262-455](_bmad-output/planning-artifacts/epics-t2-integration.md:262)):

| Column | Source | Perimeter scope | Header style |
|---|---|---|---|
| `Périmètre`, `Type Acte`, `Exercice`, `Numéro Acte`, `Etat`, `Pré-instruction`, `Catégorie T2`, `Instructeur`, `Nature`, `Ordonnateur`, `Objet`, `Bénéficiaire`, `Montant au contrôle`, `Date de saisine`, `Date limite de réponse`, `Délai de traitement` | `actes` | Both | **blue** |
| `Nom organisme` | `actes.nom_organisme` | Organisme only | **orange** |
| `Centre financier` | `actes.centre_financier_code` | État only | **green** |
| Decision block (8 cols), Suspension block (4 cols), `Précisions sur l'acte` | `actes` | Both | **blue** |
| 6 common T2 criteria (`Inscription PAP`, `Respect plafond emplois`, `Respect schéma emplois`, `Contrôle modalités`, `Respect enveloppe`, `Risque réconventionnel`) | `t2_details` | Both (display conditioned by nature, not perimeter — cf. Story 2.9 matrix) | **blue** |
| 6 criteria reused from `actes` (`Consommation crédits`, `Programmation prévue`, `Avis programmation`, `Compatibilité programmation`, `Soutenabilité`, `Autorisation tutelle`) | `actes` | Both (some conditions are perimeter-aware but the column itself is reused across) | **blue** |
| `Type d'engagement T2` (`type_acte_t2`) | `t2_details` | Both (Annexe financière nature, available both perimeters) | **blue** |
| `Effectifs`, `Effectifs complémentaires`, `Corps`, `Grade(s)`, `Date arrêté concours`, `Date effet acte`, `Impact schéma emplois` | `t2_details` | Both | **blue** |
| `Impact autre CBCM/CBR` (`impact_autre_cbcm`) | `t2_details` | Both — same column, label differs by perimeter (CBCM=État, CBR=Organisme — cf. [epics:316-317](_bmad-output/planning-artifacts/epics-t2-integration.md:316)) | **blue** |
| `ISP Cercle 1 présent`, `ISP C1 natures`, `ISP C1 montant`, `ISP C1 enveloppe SGG`, `ISP C1 consommation` | `t2_details` | **État only** (ISP exclu pour Organisme — [epics:277](_bmad-output/planning-artifacts/epics-t2-integration.md:277)) | **green** |
| `ISP Cercle 2 présent`, `ISP C2 natures`, `ISP C2 montant`, `ISP C2 enveloppe SGG`, `ISP C2 consommation` | `t2_details` | **État only** (same reason) | **green** |
| `FA technique` | `t2_details` | Both | **blue** |
| `Enveloppe abondée` | `t2_details` | **Organisme only** ([epics:364](_bmad-output/planning-artifacts/epics-t2-integration.md:364)) | **orange** |
| `Accord RFFIM`, `Sollicitation DB` | `t2_details` | **État only** (DCB profile, État perimeter — [epics:365-366](_bmad-output/planning-artifacts/epics-t2-integration.md:365)) | **green** |
| `Avis CBCM` | `t2_details` | **État only** (CBR profile, État perimeter — [epics:367](_bmad-output/planning-artifacts/epics-t2-integration.md:367)) | **green** |
| `Périmètre de la mesure`, `Statut agents`, `Impact financier N+1`, `Origine financement`, `Montant enveloppe N-1`, `Impact maximal sans enveloppe`, `Type référentiel` | `t2_details` | Both (Mesure transversale / Enveloppe limitative / Référentiel are available both perimeters) | **blue** |

**Implementation note**: when building the header style array for the T2 sheet, define it once at the top of the worksheet block (e.g. `t2_header_styles = [common, common, common, ..., etat, ..., orange, ...]` as an array of style refs matching the column order), then `sheet.add_row(headers, style: t2_header_styles)`. Mirrors the existing `header_styles` pattern in `index.xlsx.axlsx` / `historique.xlsx.axlsx`.

**Decision in case of doubt**: when an epic field has perimeter-specific conditional logic but is **stored in the same column for both perimeters** (e.g. `impact_autre_cbcm` rendered as "Impact CBCM" État / "Impact CBR" Organisme), classify the column as **blue**. The colour signals "the column has data for both perimeters in the database"; the row-level value tells you which perimeter the acte belongs to.

### Field-to-column mapping for the T2 sheet — implementation note

The 32 `t2_details` columns can be emitted **unconditionally** for every T2 row, with empty cells for fields that don't apply to that row's nature. This is the **only sane approach** because:

- Excel columns must be stable across rows in a sheet (you can't have row 3 with 25 cells and row 4 with 30)
- Filtering a row's nature-applicable fields per row would require nature-specific sheets — overkill
- Downstream analysts can filter columns themselves once the data is in Excel

The cost is ~25 empty cells per T2 row. Acceptable.

### `T2Detail.find_each` vs. `Acte.includes(:t2_detail)` — when to use which

- **For the worklist / history exports** (Tasks 1, 2): the row iteration is acte-driven (`@actes.each`) — use `Acte.includes(:t2_detail)` to eager-load the detail per acte. N+1 prevention.
- **For the admin backup** (Task 4): the `t2_details` sheet is its own iteration (`T2Detail.find_each`) decoupled from the `actes` sheet. No join needed; the `acte_id` FK is enough for cross-sheet lookups in Excel.
- **For the single-acte export** (Task 3): `@acte` is already loaded once; just add `.includes(:t2_detail)` for parity (one extra LEFT JOIN, negligible cost for HT2 actes).

### Pitfall — `T2Detail` columns and string-vs-symbol attribute access

The [T2Detail model](app/models/t2_detail.rb) is currently 5 lines (`belongs_to :acte` + one validation). All attribute access goes through ActiveRecord — `acte.t2_detail.effectifs` returns the typed value. **No need** to define helpers on `T2Detail` for this story.

Array columns (`grade`, `isp_cercle1_natures`, `isp_cercle2_natures`, `perimetre_mesure`, `origine_financement`) return Ruby arrays — use `Array(value).join(', ')` to render in a single cell. Defensive `Array(...)` handles `nil` gracefully.

### Pitfall — the `admin_backup` orphan view

[app/views/actes/admin_backup.xlsx.axlsx](app/views/actes/admin_backup.xlsx.axlsx) iterates `@actes_all`, `@suspensions_all`, `@poste_lignes_all`, `@echeanciers_all` — **none of these ivars are populated by any controller action**. The view is dead code: it's never rendered. The actual production backup goes through `GenerateBackupJob#perform` which builds the workbook inline (lines 17–122 of the job).

**Decision for this story**: update the view (Task 5) to stay in sync with the job, but do not re-wire it. The orphan-view cleanup belongs in a separate tech-debt story. If the user disagrees, we can drop Task 5 — the user-visible behavior comes entirely from Task 4 (the job).

> 💡 **Spawned-task candidate** (not for this story): "Delete `admin_backup.xlsx.axlsx` orphan view OR add an `admin_backup#download_xlsx` action that uses it". Defer.

### Pitfall — column color-coding in xlsx

The 3 existing color styles (`header_etat_style`, `header_organisme_style`, `header_common_style`) are defined at the top of [index.xlsx.axlsx](app/views/actes/index.xlsx.axlsx) and [historique.xlsx.axlsx](app/views/actes/historique.xlsx.axlsx) — they cannot be shared across the two files without extracting to a helper. **Duplicate the new `header_t2_style`** definition in both files (matches the existing pattern of style duplication between the two views). A future refactor could extract to a helper or initializer, but not in this story.

### Pitfall — Roo gem availability

The Story 3.2 test patterns use plain Rails integration tests (no workbook parsing). For AC10 tests we need to inspect the produced xlsx file's structure (sheet names, row counts, header content). Three options:

1. **Roo gem** — clean API (`Roo::Excelx.new(io).sheets`). Check Gemfile first; if not present, add to `:test` group (smallest addition).
2. **Parse the xlsx zip manually** — extract `xl/workbook.xml` and grep for `<sheet name="...">`. Crude but no new gem.
3. **`Axlsx::Package.parse`** — Axlsx can read its own files. Already in the Gemfile (`caxlsx`).

Recommended: option 3 if it works (no gem add); option 1 otherwise. Decide during implementation.

### Pitfall — `T2Detail` may have `acte` association but `acte.t2_detail` could be nil

For T2 actes created via the Story 2.x form, `acte.t2_detail` is **expected to be present** (the form builds nested attributes, see [acte.rb:20-21](app/models/acte.rb:20) — `accepts_nested_attributes_for :t2_detail`). For T2 actes that exist in the DB but somehow lack a `t2_detail` row (data inconsistency, manual SQL, half-broken import), `acte.t2_detail` returns `nil`.

**Defensive guard**: in the T2 sheet data row, use `acte.t2_detail&.<field>` everywhere — render an empty cell rather than crashing. Add a `acte.t2_detail.nil? ? "—" : acte.t2_detail.<field>` only if the empty string is misleading; otherwise leave blank.

In `GenerateBackupJob` (Task 4), the `t2_details` sheet iterates `T2Detail` directly — actes without a t2_detail simply have no row there. This is the correct behaviour (the FK on `t2_details.acte_id` is the unique-index column, so there's at most one row per acte).

### Project Structure Notes

- **No new migrations** — `t2_details` table already exists (Story 1.2 done), all needed columns are present.
- **No new models** — the data lives in `Acte` (has_one `:t2_detail`) and `T2Detail`.
- **No new routes** — all 4 export entry points already exist (single export, index xlsx, historique xlsx, admin_backup generate).
- **No new gems** if Roo is avoided (use Axlsx's own parser for tests).
- **One new style** (`header_t2_style`) duplicated across [index.xlsx.axlsx](app/views/actes/index.xlsx.axlsx) and [historique.xlsx.axlsx](app/views/actes/historique.xlsx.axlsx) — acceptable duplication at this scale.
- **One new helper method** optional (`t2_row_for_export(acte)` in [app/helpers/actes_helper.rb](app/helpers/actes_helper.rb)) — recommended if both views' T2 sheets end up with substantially identical column sets.

### Testing standards

- Tests live in [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb), grouped under a `# Story 3.3` comment (pattern from Story 3.2 — see [test file lines 1962+](test/controllers/actes_controller_test.rb)).
- To create a T2 acte fixture (minimal valid): `Acte.create!(titre: 'T2', categorie_t2: 'hors contrat', nature: 'ISP', type_acte: 'avis', perimetre: 'etat', etat: 'en pré-instruction', annee: Date.today.year, instructeur: 'AB', user: user_admin)` — then `T2Detail.create!(acte: acte, isp_cercle1: true, isp_cercle1_montant: 1000.0)`.
- To create an HT2 fixture: standard pattern from existing tests — `Acte.create!(titre: 'HT2', perimetre: 'etat', nature: 'Marché unique', type_acte: 'visa', ...)`.
- For xlsx assertion: prefer reading the response body into an Axlsx package — `pkg = Axlsx::Package.parse(StringIO.new(@response.body))` then `pkg.workbook.worksheets.map(&:name)`. Confirm Axlsx supports parsing during implementation (it should; falls back to Roo if not).
- For the `GenerateBackupJob` test: instantiate `BackupExport.create!(status: 'pending')`, stub the GCS bucket (`GcsBackupConcern#gcs_bucket` returns a double with `.create_file` no-op), run `GenerateBackupJob.new.perform(backup.id)` inline, then read the Tempfile path (will need a small hook in the job or read from GCS double's last upload).

### References

- Epic spec — Story 3.3: [_bmad-output/planning-artifacts/epics-t2-integration.md:573-587](_bmad-output/planning-artifacts/epics-t2-integration.md:573)
- Single-acte export view: [app/views/actes/export.xlsx.axlsx](app/views/actes/export.xlsx.axlsx) (798 lines)
- Worklist xlsx view: [app/views/actes/index.xlsx.axlsx](app/views/actes/index.xlsx.axlsx) (305 lines)
- History xlsx view: [app/views/actes/historique.xlsx.axlsx](app/views/actes/historique.xlsx.axlsx) (334 lines)
- Admin backup orphan view: [app/views/actes/admin_backup.xlsx.axlsx](app/views/actes/admin_backup.xlsx.axlsx) (114 lines — not currently rendered by any action)
- Admin backup job (real backup path): [app/jobs/generate_backup_job.rb](app/jobs/generate_backup_job.rb) (132 lines)
- 2026 organisme one-off export: [app/views/actes/export_organisme_2026.xlsx.axlsx](app/views/actes/export_organisme_2026.xlsx.axlsx) (out of scope for this story)
- Controller — `export` action: [app/controllers/actes_controller.rb:370-406](app/controllers/actes_controller.rb:370)
- Controller — `index` action xlsx branch: [app/controllers/actes_controller.rb:131-145](app/controllers/actes_controller.rb:131)
- Controller — `historique` action: [app/controllers/actes_controller.rb:150-244](app/controllers/actes_controller.rb:150)
- Controller — `admin_backup` action (page that triggers the job): [app/controllers/actes_controller.rb:1074-1101](app/controllers/actes_controller.rb:1074)
- Controller — `generate_backup` action (enqueues `GenerateBackupJob`): [app/controllers/actes_controller.rb:1103-1106](app/controllers/actes_controller.rb:1103)
- Routes — single export, index, historique, admin_backup: [config/routes.rb:91-113](config/routes.rb:91)
- Model `Acte` — `has_one :t2_detail` association: [app/models/acte.rb:20-21](app/models/acte.rb:20)
- Model `T2Detail`: [app/models/t2_detail.rb](app/models/t2_detail.rb) (5 lines, minimal)
- Schema — `t2_details` table columns: [db/schema.rb:503-545](db/schema.rb:503)
- Story 2.9 — T2 control criteria matrix (for the `export.xlsx` CRITÈRES section): [_bmad-output/planning-artifacts/epics-t2-integration.md:459-490](_bmad-output/planning-artifacts/epics-t2-integration.md:459)
- Story 3.1 — Titre column on listings (cross-story context — same `titre` values used here): [_bmad-output/implementation-artifacts/3-1-affichage-actes-t2-pages-historique-et-index.md](_bmad-output/implementation-artifacts/3-1-affichage-actes-t2-pages-historique-et-index.md)
- Story 3.2 — Titre/Périmètre filters (the filters the user will apply before triggering an export): [_bmad-output/implementation-artifacts/3-2-filtres-de-recherche-incluant-t2.md](_bmad-output/implementation-artifacts/3-2-filtres-de-recherche-incluant-t2.md)

### Previous Story Intelligence (Story 3.2)

- Story 3.2 confirmed that `Acte.ransackable_attributes` already includes `titre` and `perimetre`; **`q[titre_in]=T2`** + `format: :xlsx` will work natively through Ransack — no controller-side filtering needed for AC8.
- Story 3.2 added the **7 T2 natures** to `@liste_natures` in `set_variables_filtres`. These natures are the same values the export reads from `acte.nature` — no mapping table needed.
- Story 3.2 deliberately split saisie (`set_variables_form`) and filtre (`set_variables_filtres`) — this story touches neither. **Stay out of `set_variables_*`** entirely.
- Story 3.2 noted that `acte.t2_detail` is the canonical accessor for T2 fields (not a join on the acte table) — confirmed; the export reads `acte.t2_detail&.<field>`.
- Story 3.2 helper `perimetre_exclusively?` is **not relevant** here (exports do not have a "EXCLUSIVELY this perimetre" semantic — they iterate whatever rows Ransack returned).
- Story 3.2 commit guidance: dedicated commit, not bundled with other stories. **Same here**: commit `feat: export Excel HT2/T2 séparés + onglet t2_details dans admin_backup (story 3.3)`.

### Git Intelligence Summary

5 most recent commits on `actes` branch (target for this story):

- `9404655` `feat: refonte des filtres de recherche Titre/Périmètre et ajout des natures T2` (Story 3.2 — closing commit)
- `e4e85de` `feat: ajoute la colonne Titre (badge HT2/T2) sur la Liste de travail et l'Historique (story 3.1)`
- `d92a5bb` `fix: correctifs des tests et vues liés à l'affichage des détails pour les actes T2`
- `c5cff4a` `feat: extension du modal nouvel acte pour ajouter le support du type d'acte T2`
- `e99c80c` `feat: renomme ht2_actes → actes, associations, champs FK et modèle, et ajout table t2_details`

Working tree at story creation: clean (Story 3.2 fully committed). Start Story 3.3 on a clean base — no prerequisites to land first.

Patterns established that we should reuse:
- `Array(value).join(', ')` for array columns (from `generate_backup_job.rb:65` for `type_observations`)
- `field&.strftime('%d/%m/%Y')` for date columns (from existing xlsx views — null-safe)
- `style: cell_style` / `style: header_style` per row (from all axlsx views)
- `wb.styles.add_style(...)` declarations at the top of the view file (3 existing colour styles to extend with the 4th)
- N+1 prevention via `Acte.includes(:t2_detail).where(...)` in controller, not in the view

### Latest Tech Information

- **caxlsx** (≥ 4.0): supports multi-sheet workbooks, conditional row emission, custom styles, merged cells, column widths — all the features used in this story are existing-codebase patterns. No version bump needed.
- **caxlsx_rails**: provides the `.xlsx.axlsx` template handler that Rails renders for `format.xlsx`. Currently in the Gemfile, no change.
- **DSFR colours**: the brand palette (blues, greys) is in [app/assets/stylesheets/](app/assets/stylesheets). The proposed purple `e8d6f5` is **not** DSFR-canonical but visually distinct. Discuss in review whether to swap for a DSFR-extended purple if one exists.
- **Roo gem**: optional test dependency for parsing xlsx in assertions. Check Gemfile first; if not present, prefer `Axlsx::Package.parse` (which can read its own output).

## Dev Agent Record

### Agent Model Used

claude-opus-4-7

### Debug Log References

N/A

### Completion Notes List

- **Helper centralisé** `t2_export_columns` + `t2_export_row` + `t2_export_column_indices` ajoutés dans [app/helpers/actes_helper.rb:215-378](app/helpers/actes_helper.rb:215). 75 colonnes T2 définies une seule fois, réutilisées par les 2 vues `index.xlsx.axlsx` et `historique.xlsx.axlsx`. Pas de 4e couleur — règle perimetre (vert/orange/bleu) appliquée via le symbole `:common`/`:etat`/`:organisme` retourné par `t2_export_columns`.
- **`index.xlsx.axlsx`** : sheet renommé `"HT2"`, partition `@actes.to_a.partition { |a| a.titre != 'T2' }`, sheet T2 appendé. Headers stables même si `actes_t2.empty?`.
- **`historique.xlsx.axlsx`** : même pattern sur `@actes_all`. Symétrie admin : colonne "Controleur" préfixée sur **les deux** sheets, avec offset +1 sur les indexes float/integer de la boucle T2.
- **`export.xlsx.axlsx`** (acte unique) : bloc INFORMATIONS T2 inséré avant LIGNES DE POSTE, branché sur `if @acte.titre == 'T2'`. 7 sous-blocs nature-conditionnels (Annexe financière, ISP, FA, Marché, Mesure transversale, Enveloppe limitative, Référentiel). Section CRITÈRES DE CONTRÔLE : nouvelle branche T2 implémentant la matrice Story 2.9 (11 critères conditionnels). HT2 byte-identique au pré-story.
- **`GenerateBackupJob`** : 5e onglet `t2_details` ajouté après `echeanciers`, itère `T2Detail.order(:id).find_each`. Onglet `actes` étendu avec `titre` + `categorie_t2` entre `observations_deliberation_ca` et `pdf_generation_status`.
- **Vue orpheline `admin_backup.xlsx.axlsx`** : mirroir du job (5e onglet `t2_details` + 2 colonnes `titre`/`categorie_t2` dans `actes`). La vue n'est toujours alimentée par aucune action — orpheline assumée, à traiter en story tech-debt dédiée.
- **Controller eager-loading** : `:t2_detail` ajouté à `index`#xlsx (4 scopes), `historique`, `export`. Bonus correction sur `index`#xlsx : switch de `@actes` (non filtré) vers `@actes_filtered` pour que les filtres Ransack `q_current[titre_in]` s'appliquent à l'export téléchargé (AC8). Sans ce fix, l'AC8 ne passait pas.
- **Tests** : 10 tests Story 3.3 ajoutés dans `test/controllers/actes_controller_test.rb` (section dédiée). Parsing xlsx via `Roo::Excelx`. Test job stub GCS via `define_singleton_method(:gcs_bucket)` + lecture du workbook **pendant** le callback `create_file` (Tempfile auto-supprimé en sortie de bloc).
- **Suite complète** (post code-review) : `bundle exec rails test` → **179 runs, 1204 assertions, 0 failures, 0 errors, 0 skips**. Avant Story 3.3 : 158 runs / 1100 assertions. Δ = +21 tests / +104 assertions (10 nouveaux Story 3.3 + 5 ajoutés en code-review pour valider contenu, ordre colonnes, matrice critères et filtre `nature_eq` + 6 ajustements antérieurs déjà au master).
- **Task 9 (smoke check navigateur)** non exécutée : la couverture automatique vérifie sheets, headers, filtres, sections INFORMATIONS T2, et structure du backup. Smoke check recommandé avant merge.

### File List

- [app/helpers/actes_helper.rb](app/helpers/actes_helper.rb) — nouveaux helpers `t2_export_columns`, `t2_export_row`, `t2_export_column_indices` (lignes 215-378)
- [app/views/actes/index.xlsx.axlsx](app/views/actes/index.xlsx.axlsx) — sheet renommé HT2, partition, sheet T2 appendé
- [app/views/actes/historique.xlsx.axlsx](app/views/actes/historique.xlsx.axlsx) — sheet renommé HT2, partition, sheet T2 appendé (avec colonne Controleur admin sur les 2 sheets)
- [app/views/actes/export.xlsx.axlsx](app/views/actes/export.xlsx.axlsx) — section INFORMATIONS T2 + branche CRITÈRES T2
- [app/views/actes/admin_backup.xlsx.axlsx](app/views/actes/admin_backup.xlsx.axlsx) — onglet t2_details + colonnes titre/categorie_t2 dans actes
- [app/jobs/generate_backup_job.rb](app/jobs/generate_backup_job.rb) — onglet t2_details + colonnes titre/categorie_t2 dans actes
- [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb) — eager-loading `:t2_detail` (3 endroits) + correction `@actes_filtered` dans `index#xlsx`
- [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb) — 10 nouveaux tests Story 3.3
- [app/models/acte.rb](app/models/acte.rb) — `associate_centre_financier` : création d'un CentreFinancier "non valide" restreinte aux actes HT2 (post-implém, dérogation AC11 — cf. Change Log)
- [app/views/actes/_acte_details_t2.html.erb](app/views/actes/_acte_details_t2.html.erb) — fix bug : suppression du `if td.present?` global qui masquait les critères basés sur `acte.*` quand `t2_detail` est nil (post-implém)

### Change Log

- 2026-05-19 (post-implém) — Ajustements demande utilisateur :
  - Colonne `Programme` ajoutée dans l'onglet T2 des exports `index.xlsx` et `historique.xlsx`, avant `Centre financier` (alignement avec le sheet HT2). Implémenté dans le helper `t2_export_columns` / `t2_export_row` (`acte.programme_principal&.numero`) — pas de modif des vues `.axlsx`.
  - `Acte#associate_centre_financier` ([app/models/acte.rb:678](app/models/acte.rb:678)) : la création d'un `CentreFinancier` "non valide" quand le code ne correspond à aucun centre existant est désormais conditionnée à `titre != 'T2'`. Pour les actes T2, l'association reste vide si le code est inconnu (pas de pollution du référentiel). Comportement HT2 inchangé.
  - Colonne `Précisions sur l'acte` retirée de l'onglet T2 des exports `index.xlsx` et `historique.xlsx` (suppression dans `t2_export_columns` + `t2_export_row`). Alignement avec le sheet HT2 qui ne l'expose pas non plus.
  - Colonne `Date création` ajoutée dans l'onglet T2 avant `Date de saisine` (alignement avec le sheet HT2). Valeur : `acte.created_at&.strftime('%d/%m/%Y')`.
  - Onglet T2 : ordre des colonnes Date/Suspension/Décision/Observations réordonné pour matcher le sheet HT2 : `Date création → Date saisine → [Suspension, Date suspension, Date fin suspension, Motif suspension] → Date limite de réponse → Proposition décision → Décision finale → Valideur → Date clôture → Délai traitement → Type observations → Observations → Commentaire interne`. Modif dans `t2_export_columns` + `t2_export_row` (helper).
  - Colonne `Grade(s)` (Section F) renommée `Catégorie` dans l'onglet T2 — le label est l'unique changement, la valeur reste `Array(td&.grade).join(', ')`.
  - Onglet T2 : ajout des colonnes `Services votés` et `Engagement éligible à la gestion des SV` après `Commentaire interne` (alignement HT2). Valeurs : `bool.(acte.services_votes)` et `acte.services_votes ? bool.(acte.programmation) : "N/A"`.
  - Colonne `Avis programmation` (Section E) renommée `Programmation initiale transmise` dans l'onglet T2 (alignement libellé HT2). Valeur inchangée : `bool.(acte.avis_programmation)`.
  - Colonne `Programmation prévue` (Section E) renommée `Acte programmé` dans l'onglet T2 (alignement libellé HT2). Valeur inchangée : `bool.(acte.programmation_prevue)`.
  - Colonnes Section E renommées dans l'onglet T2 : `Consommation crédits` → `Exactitude de l'évaluation budgétaire` (valeur `bool.(acte.consommation_credits)`), `Soutenabilité` → `Soutenabilité / Disponibilité des crédits` (valeur `bool.(acte.soutenabilite)`).
  - Critères de contrôle T2 (colonnes AH–AS de l'onglet T2) : application de la matrice Story 2.9 — chaque critère renvoie `"N/A"` quand il n'a pas lieu d'être pour la combinaison `nature × périmètre × état de l'acte`. 12 critères couverts (6 Section D depuis `t2_details` + 6 Section E réutilisés depuis `actes`).
  - Onglet T2 : colonnes `Acte programmé`, `Programmation initiale transmise`, `Compatibilité programmation` déplacées juste après `Engagement éligible à la gestion des SV` (alignement visuel avec HT2 où ces colonnes apparaissent dans ce bloc). Section D commence désormais directement par `Inscription PAP`.
  - Onglet T2 : colonnes `Autorisation tutelle` et `Soutenabilité / Disponibilité des crédits` déplacées après `Compatibilité programmation` (ordre final : `Compatibilité programmation → Autorisation tutelle → Soutenabilité/Dispo → Inscription PAP …`). Section E ne contient plus que `Exactitude de l'évaluation budgétaire`.
  - Onglet T2 : colonne `Type d'engagement T2` supprimée (Section F). L'information reste disponible dans l'export `admin_backup` (sheet `t2_details`) et dans l'export single-acte `export.xlsx.axlsx` (section INFORMATIONS T2 — affichée pour la nature Annexe financière).
  - Colonne `Type référentiel` (Section F) renommée `Déclinaison référentiel` dans l'onglet T2. Valeur inchangée : `bool.(td&.referentiel_type)`.
  - Onglet T2 : ajout des 3 colonnes Organisme-only (style orange) après `Montant au contrôle` : `Opération budgétaire` (`acte.operation_budgetaire`), `Budget exécutoire` (`bool.(acte.budget_executoire)`), `Délibération CA` (`bool.(acte.deliberation_ca)`). Valeur `"N/A"` pour les actes État.
  - Onglet T2 : ajout de 3 colonnes Organisme-only après `Délibération CA` : `N° délibération` (`acte.numero_deliberation_ca`), `Date délibération` (`acte.date_deliberation_ca&.strftime('%d/%m/%Y')`), `Observations délibération` (`acte.observations_deliberation_ca`). Valeur `"N/A"` pour les actes État.
  - `export.xlsx.axlsx` (acte unique) : section "INFORMATIONS SUR L'ACTE" rapprochée des partials show :
    - **HT2 État** ([export.xlsx.axlsx:188-241](app/views/actes/export.xlsx.axlsx:188)) : tableau 1 réordonné selon `_acte_details.html.erb` — `montant_ae` avant `montant_global` (et non plus l'inverse), avec labels alignés par `type_acte` (avis/visa/TF). Colonne `Nature` omise quand `type_acte == 'TF'` (conforme au partial).
    - **T2** ([export.xlsx.axlsx:444-481](app/views/actes/export.xlsx.axlsx:444)) : nouveau tableau "Informations" à 8 colonnes (Nature, Organisme/CF selon perimetre, Exercice, Date saisine, Délai, Ordonnateur, Objet, Services votés) ajouté en tête de la section INFORMATIONS T2, miroir de `_acte_details_t2.html.erb`. Bandeau Catégorie/Nature + sous-blocs nature-spécifiques conservés.
  - `export.xlsx.axlsx` (acte unique) : fusion des sections "INFORMATIONS SUR L'ACTE" et "INFORMATIONS T2" pour les actes T2 — un seul bloc adaptatif :
    - Tableau 1 "Informations" T2 = 9 colonnes (Nature, Organisme/CF, Catégorie T2, Exercice, Date saisine, Délai, Ordonnateur, Objet, Services votés) — émis sous "INFORMATIONS SUR L'ACTE" quand `@acte.titre == 'T2'`.
    - Tableau 2 (HT2-only) sauté pour T2.
    - Bloc "INFORMATIONS COMPLÉMENTAIRES" (HT2-only) sauté pour T2.
    - Bloc "INFORMATIONS T2" séparé supprimé. Le titre `DÉTAILS {NATURE}` (ex. "DÉTAILS ISP") précède désormais directement les sous-blocs nature-spécifiques, sans répétition des champs déjà présents au tableau 1.
    - Tests AC3/AC7 mis à jour pour chercher `"DÉTAILS ISP"` (T2) et l'absence de tout `"DÉTAILS …"` (HT2).
  - `export.xlsx.axlsx` (acte unique, T2) : bloc DÉTAILS {nature} entièrement réécrit pour matcher les partials `app/views/actes/t2_sections/_show_*.html.erb` :
    - **Marché** rend `montant_ae` + `beneficiaire` même sans `t2_detail` ; en perimetre organisme ajoute `Budget exécutoire`, `Opération budgétaire`, `Délibération en CA nécessaire` et (si déliberation_ca) `N° délibération`, `Date délibération`, `Observations délibération` — fidèle au partial `_show_marche.html.erb` (le bug "Aucun détail T2 disponible" sur les Marché sans `t2_detail` est résolu).
    - **Annexe financière** rend 9 colonnes (Type d'acte, Date d'effet, Effectifs principal/complémentaire, Catégorie, Corps, Date arrêté concours, Impact schéma emplois, Impact autre CBR/CBCM) + sous-tableau "Budget et délibération" si organisme.
    - **ISP** : 1 ligne "Date d'effet" + 2 sous-tableaux Cercle 1 / Cercle 2 (uniquement si `isp_cercleN == true`) avec colonne "Reste à consommer" calculée.
    - **FA** : Montant + N° Chorus (État) + FA Technique + (État → Accord RFFIM/Sollicitation DB + Avis CBCM ; Organisme → Enveloppe abondée).
    - **Mesure transversale / Enveloppe limitative / Référentiel** : tableaux fidèles aux partials (Date d'effet, Périmètre de mesure, Catégorie, Corps, Effectifs N/N+1, etc.) + sous-tableau "Budget et délibération" si organisme. Enveloppe limitative émet aussi un 2e tableau avec "Effet de l'enveloppe" calculé.
    - Tous les champs `t2_detail&.xxx` (safe navigation) → pas de crash si `t2_detail` nil ; `"Non renseigné"` affiché en lieu et place des cellules vides (cohérent avec les partials).
  - **Fix bug HTML** [_acte_details_t2.html.erb:138](app/views/actes/_acte_details_t2.html.erb:138) : le bloc "Critères de contrôle" était entièrement gardé par `<% if td.present? %>`, ce qui masquait **tous** les critères (y compris ceux qui ne dépendent que de `acte.*` comme Acte programmé, Soutenabilité, Autorisation tutelle…) quand `t2_detail` était nil. Fix : suppression du guard global, ajout de gardes locales `if td && …` uniquement sur les critères qui réfèrent `td.xxx` (Inscription PAP, Respect plafond emplois, Respect schéma emplois, Contrôle modalités, Respect enveloppe, Risque réconventionnel). Les critères basés sur `acte.*` s'affichent désormais même sans `t2_detail`.
  - `export.xlsx.axlsx` — bloc CRITÈRES DE CONTRÔLE entièrement aligné sur les 3 partials show :
    - **T2** ([export.xlsx.axlsx:788-880](app/views/actes/export.xlsx.axlsx:788)) : critères réordonnés selon `_acte_details_t2.html.erb` (13 critères potentiels dans le bon ordre) + ajout du critère manquant "Compatibilité avec la programmation annuelle et pluriannuelle" (avec la logique `show_programmation_compat`) + labels alignés (`Inscription au PAP / Plan de recrutement` vs `Inscription au PAP` selon nature, `Exactitude de l'évaluation budgétaire`, `Soutenabilité / Disponibilité des crédits`).
    - **HT2 Organisme** ([export.xlsx.axlsx:858-936](app/views/actes/export.xlsx.axlsx:858)) : refonte du switch en construction unifiée miroir de `_acte_details_organisme.html.erb` — labels longs et contextuels (`Compatibilité avec caractère soutenable de la gestion` vs `Caractère soutenable des engagements financiers…` selon dépense/recette ; `Disponibilité des crédits` vs `Disponibilité des fonds au sein de la trésorerie` selon compte_tiers ; `Concordance entre les recettes encaissées pour compte de tiers et les reversements correspondants` au lieu du raccourci ; `Conformité au seuil de contrôle` au lieu de `Conformité seuil contrôle`).
    - **HT2 État** ([export.xlsx.axlsx:937-961](app/views/actes/export.xlsx.axlsx:937)) : 2 labels rallongés (`Exactitude de l'évaluation de la consommation des crédits` au lieu de `Exactitude de l'évaluation` ; `Compatibilité avec la programmation annuelle et pluriannuelle` au lieu de `Compatibilité programmation`).

- 2026-05-19 — Story 3.3 implémentée :
  - Helper `t2_export_columns` + `t2_export_row` + `t2_export_column_indices` (75 colonnes T2 partagées entre index et historique xlsx)
  - `index.xlsx.axlsx` et `historique.xlsx.axlsx` : split en 2 onglets `HT2` + `T2`, colonne admin Controleur prefixée sur les 2 sheets historique
  - `export.xlsx.axlsx` : section INFORMATIONS T2 nature-conditionnelle + critères de contrôle T2 (matrice Story 2.9)
  - `GenerateBackupJob` + `admin_backup.xlsx.axlsx` : 5e onglet `t2_details` + colonnes `titre`/`categorie_t2` dans l'onglet `actes`
  - Eager-loading `:t2_detail` dans 3 actions controller (index, historique, export) + switch `@actes` → `@actes_filtered` pour que les filtres xlsx fonctionnent
  - 10 tests d'intégration Story 3.3 (Roo pour parser le workbook, stub GCS via singleton_method)
  - Full suite : 174 runs / 1187 assertions / 0 failures

- 2026-05-19 (code-review adversariale) — corrections apportées :
  - **H1** : ajout de [_acte_details_t2.html.erb](app/views/actes/_acte_details_t2.html.erb) à la File List (était mentionné en Change Log mais pas listé).
  - **H2** : AC3 amendé pour refléter le titre `"DÉTAILS {nature}"` (au lieu de `"INFORMATIONS T2"` d'origine).
  - **H3** : [actes_helper.rb:417](app/helpers/actes_helper.rb:417) — colonne `Déclinaison référentiel` conditionnée à `acte.nature == 'Référentiel'` (rend `"N/A"` sinon, cohérent avec les autres colonnes nature-spécifiques). Avant le fix, toutes les lignes T2 affichaient "Non" par défaut.
  - **H4 + M4** : 5 nouveaux tests ajoutés couvrant : ordre/labels des 80 colonnes T2 vs helper, valeur `N/A` pour `Déclinaison référentiel` hors Référentiel, filtre Ransack `q_current[nature_eq]=ISP`, contenu du sheet `t2_details` du backup admin (incl. colonnes `titre`/`categorie_t2` dans onglet actes), matrice des critères de contrôle ISP.
  - **M1** : AC11 amendé pour documenter les 2 dérogations post-implém (modèle Acte + partial show T2).
  - **M2** : `t2_export_row` refactorisé pour extraire les prédicats matrice Story 2.9 (`show_acte_programme`, `show_prog_init_transmise`, `show_programmation_compat`, `show_autorisation_tutelle`) en variables locales — lisibilité × 3.
  - **M3** : AC6 amendé pour refléter le nombre réel de colonnes (~80) et désigner le helper comme source de vérité.
  - Suite complète : 179 runs / 1204 assertions / 0 failures.
