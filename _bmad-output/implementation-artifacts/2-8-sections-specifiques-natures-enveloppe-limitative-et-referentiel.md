# Story 2.8: Nature-Specific Sections — "Enveloppe limitative" and "Référentiel"

Status: done

## Story

As an instructor,
I want to fill in the specific fields of a T2 acte with nature "Enveloppe limitative" or "Référentiel",
so that I can document these types of acts with their specific HR and financial data.

## Acceptance Criteria

### AC1 — Enveloppe limitative section appears when nature is selected

**Given** the instructor selects "Enveloppe limitative" from the nature dropdown in the T2 step-1 form
**When** the `toggleNatureT2` Stimulus method fires
**Then** the `#t2-section-enveloppe-limitative` div becomes visible (removes `fr-hidden`)
**And** all other nature sections remain hidden

### AC2 — Enveloppe limitative: État périmètre fields

**Given** the section is visible **AND** `acte.perimetre == 'etat'`
**When** it renders
**Then** the following fields are present (all optional unless noted):
- **Périmètre de la mesure** (`td[perimetre_mesure]`, checkbox-dropdown multi-select) — optionnel
- **Catégorie** (`td[grade]`, checkbox-dropdown multi-select) — optionnel
- **Corps** (`td[corps]`, text input) — optionnel
- **Effectifs (année N)** (`td[effectifs]`, float) — optionnel
- **Effectifs (année N+1)** (`td[effectifs_complementaire]`, float) — optionnel
- **Statut d'agents** (`td[statut_agents]`, dropdown) — optionnel
- **Montant au contrôle** (`acte[montant_ae]`, decimal) — optionnel
- **Origine de financement** (`td[origine_financement]`, checkbox-dropdown, **État only**) — optionnel
- **Montant enveloppe N-1** (`td[montant_enveloppe_n1]`, decimal) — optionnel
- **Impact maximal sans enveloppe** (`td[impact_maximal_sans_enveloppe]`, decimal) — optionnel
- **Effet de l'enveloppe** (read-only display: `impact_maximal_sans_enveloppe / montant_enveloppe_n1` as %) — affiché en lecture seule
- **Date d'effet de l'acte** (`td[date_effet_acte]`, text input) — optionnel

**État layout (screenshot 1):**
```
Row 1: [Initiales instructeur*] | [Nature: Enveloppe limitative] | [Centre financier]
Row 2: [Exercice* dropdown]     | [Date de saisine* dropdown]    | [Service ordonnateur]
Row 3: [Objet]                  | [Date d'effet de l'acte]       | [Origine de financement dropdown]
Row 4: [Périmètre de la mesure dropdown] | [Catégorie dropdown]  | [Corps text]
Row 5: [Effectifs (année N)]    | [Effectifs (année N+1)]        | [Statut d'agents dropdown]
Row 6: [Montant au contrôle]    | [Montant enveloppe N-1]
Row 7: [Impact maximal sans enveloppe] | [Effet de l'enveloppe --%  (blue block)]
Row 8: [Précisions sur l'acte (textarea)]
Footer: [Cet acte a été réalisé en période de services votés (checkbox)]
```

### AC3 — Enveloppe limitative: Organisme périmètre fields

**Given** the section is visible **AND** `acte.perimetre == 'organisme'`
**When** it renders
**Then** all fields from AC2 are present except:
- **Origine de financement** is NOT displayed (État only)

**And** the following additional fields are present (organisme-only):
- **Budget exécutoire** (`acte[budget_executoire]`, radio Oui/Non) — **obligatoire**, default Oui
- **Opération budgétaire** (`acte[operation_budgetaire]`, dropdown: Globalisée / Fléchée) — optionnel
- **Délibération en CA nécessaire** (`acte[deliberation_ca]`, radio Oui/Non) — default Non

**Organisme layout (screenshot 3):**
```
Row 1: [Initiales instructeur*] | [Nature: Enveloppe limitative] | [Organisme*]
Row 2: [Exercice* dropdown]     | [Date de saisine* dropdown]    | [Service ordonnateur]
Row 3: [Objet]                  | [Date d'effet de l'acte]       | [Périmètre de la mesure dropdown]
Row 4: [Catégorie dropdown]     | [Corps text]                   | [Effectifs (année N)]
Row 5: [Effectifs (année N+1)]  | [Statut d'agents dropdown]     | [Montant au contrôle]
Row 6: [Montant enveloppe N-1]  | [Impact maximal sans enveloppe] | [Effet de l'enveloppe --% (blue block)]
Row 7: [Budget exécutoire* Oui/Non] | [Opération budgétaire dropdown]
Row 8: [Délibération en CA nécessaire Oui/Non]
Row 9: [Précisions sur l'acte (textarea)]
Footer: [Cet acte a été réalisé en période de services votés (checkbox)]
```

> Note: `Précisions sur l'acte` and `services_votes` are in the **parent partial** `_form_informations_t2.html.erb`. Do NOT add them to this section partial.

### AC4 — Référentiel section appears when nature is selected

**Given** the instructor selects "Référentiel" from the nature dropdown
**When** the `toggleNatureT2` Stimulus method fires
**Then** the `#t2-section-referentiel` div becomes visible (removes `fr-hidden`)
**And** all other nature sections remain hidden

### AC5 — Référentiel: État périmètre fields

**Given** the section is visible **AND** `acte.perimetre == 'etat'`
**When** it renders
**Then** the following fields are present:
- **Périmètre de la mesure** (`td[perimetre_mesure]`, checkbox-dropdown multi-select) — optionnel
- **Catégorie** (`td[grade]`, checkbox-dropdown multi-select) — optionnel
- **Corps** (`td[corps]`, text input) — optionnel
- **Effectifs (année N)** (`td[effectifs]`, float) — optionnel
- **Effectifs (année N+1)** (`td[effectifs_complementaire]`, float) — optionnel
- **Montant au contrôle** (`acte[montant_ae]`, decimal) — optionnel
- **Impact financier N+1** (`td[impact_financier_n1]`, decimal) — optionnel
- **Déclinaison référentiel interministériel** (`td[referentiel_type]` stored as string, radio Oui/Non) — **obligatoire** (maps "Oui" → `'Interministériel'`, "Non" → `'Autre référentiel'`)
- **Date d'effet de l'acte** (`td[date_effet_acte]`, text input) — optionnel

**État layout (screenshot 2):**
```
Row 1: [Initiales instructeur*] | [Nature: Référentiel]         | [Centre financier]
Row 2: [Exercice* dropdown]     | [Date de saisine* dropdown]   | [Service ordonnateur]
Row 3: [Objet]                  | [Date d'effet de l'acte]      | [Origine de financement dropdown]
Row 4: [Périmètre de la mesure dropdown] | [Catégorie dropdown] | [Corps text]
Row 5: [Effectifs (année N)]    | [Effectifs (année N+1)]
Row 6: [Montant au contrôle]    | [Impact financier N+1]        | [Déclinaison référentiel interministériel: Oui (○) Non (●)]
Row 7: [Précisions sur l'acte (textarea)]
Footer: [Cet acte a été réalisé en période de services votés (checkbox)]
```

> Note from screenshot: "Origine de financement" appears in Row 3 for État — this is the same field used in other État sections. Include it for Référentiel État périmètre.

### AC6 — Référentiel: Organisme périmètre fields

**Given** the section is visible **AND** `acte.perimetre == 'organisme'`
**When** it renders
**Then** all fields from AC5 are present (no Origine de financement)
**And** the following additional fields are present (organisme-only):
- **Déclinaison autre référentiel** (`td[referentiel_type]` stored as `'Autre référentiel'`/`'Interministériel'`, radio Oui/Non) — **obligatoire** (same field, same semantic, different label)
- **Budget exécutoire** (`acte[budget_executoire]`, radio Oui/Non) — **obligatoire**, default Oui
- **Opération budgétaire** (`acte[operation_budgetaire]`, dropdown: Globalisée / Fléchée) — optionnel
- **Délibération en CA nécessaire** (`acte[deliberation_ca]`, radio Oui/Non) — default Non

**Organisme layout (screenshot 4):**
```
Row 1: [Initiales instructeur*] | [Nature: Référentiel]          | [Organisme*]
Row 2: [Exercice* dropdown]     | [Date de saisine* dropdown]    | [Service ordonnateur]
Row 3: [Objet]                  | [Date d'effet de l'acte]       | [Périmètre de la mesure dropdown]
Row 4: [Catégorie dropdown]     | [Corps text]                   | [Effectifs (année N)]
Row 5: [Effectifs (année N+1)]  | [Montant au contrôle]          | [Impact financier N+1]
Row 6: [Déclinaison autre référentiel: Oui (○) Non (●)] | [Budget exécutoire* Oui (●) Non (○)] | [Opération budgétaire dropdown]
Row 7: [Délibération en CA nécessaire Oui (○) Non (●)]
Row 8: [Précisions sur l'acte (textarea)]
Footer: [Cet acte a été réalisé en période de services votés (checkbox)]
```

### AC7 — Effet de l'enveloppe — real-time calculation (Enveloppe limitative only)

**Given** the instructor fills `Montant enveloppe N-1` and/or `Impact maximal sans enveloppe`
**When** either value changes
**Then** the "Effet de l'enveloppe" read-only display updates in real time as:
`effet = impact_maximal_sans_enveloppe / montant_enveloppe_n1 * 100` (formatted as `--%` when values missing, else `XX.XX%`)

> This calculation only applies to Enveloppe limitative. The display block is a blue-highlighted read-only box (matching ISP "Reste" pattern). The Stimulus controller already has `changeNumber` and `numberFormat` — add a new `calculateEffetEnveloppe` method or a targeted value listener.

### AC8 — Data saved correctly — Enveloppe limitative

**Given** the form is submitted with Enveloppe limitative fields filled
**When** the controller processes params
**Then** the following are saved in `t2_details`:
- `td.perimetre_mesure` (string[], array PostgreSQL)
- `td.grade` (string[], array PostgreSQL)
- `td.corps` (string)
- `td.effectifs` (float)
- `td.effectifs_complementaire` (float)
- `td.statut_agents` (string)
- `td.montant_enveloppe_n1` (decimal)
- `td.impact_maximal_sans_enveloppe` (decimal)
- `td.origine_financement` (string[], array, État only)
- `td.date_effet_acte` (string)

**And** the following are saved in `actes`:
- `acte.montant_ae` (float)
- `acte.operation_budgetaire` (string, organisme only)
- `acte.budget_executoire` (boolean, organisme only — default true)
- `acte.deliberation_ca` (boolean, organisme only — default false)

**And** `T2_DETAIL_FIELDS_BY_NATURE['Enveloppe limitative']` must be updated from `[]` to list the relevant `t2_detail` fields

### AC9 — Data saved correctly — Référentiel

**Given** the form is submitted with Référentiel fields filled
**When** the controller processes params
**Then** the following are saved in `t2_details`:
- `td.perimetre_mesure` (string[], array PostgreSQL)
- `td.grade` (string[], array PostgreSQL)
- `td.corps` (string)
- `td.effectifs` (float)
- `td.effectifs_complementaire` (float)
- `td.impact_financier_n1` (decimal)
- `td.referentiel_type` (string: `'Interministériel'` or `'Autre référentiel'`)
- `td.origine_financement` (string[], array, État only)
- `td.date_effet_acte` (string)

**And** the following are saved in `actes`:
- `acte.montant_ae` (float)
- `acte.operation_budgetaire` (string, organisme only)
- `acte.budget_executoire` (boolean, organisme only — default true)
- `acte.deliberation_ca` (boolean, organisme only — default false)

**And** `T2_DETAIL_FIELDS_BY_NATURE['Référentiel']` must be updated from `[]` to list the relevant `t2_detail` fields

### AC10 — No regression

**Given** an acte with `titre = 'HT2'`
**Then** neither the Enveloppe limitative nor the Référentiel section appears

**Given** a different T2 nature is selected (e.g. Marché, Mesure transversale)
**Then** both sections are hidden and the appropriate section shows

## Tasks / Subtasks

- [x] **Task 1: Implement `_enveloppe_limitative.html.erb` partial** (AC: 1, 2, 3, 7)
  - [x] Replace placeholder in `app/views/actes/t2_sections/_enveloppe_limitative.html.erb`
  - [x] All t2_detail fields use `td.` builder, acte fields use `f.`
  - [x] Date d'effet de l'acte — `td.text_field :date_effet_acte`, `id: "el_date_effet_acte"`
  - [x] Origine de financement — checkbox-dropdown, État only (`unless is_organisme`), `id: "el_origine_financement_hidden"`, values: `['Enveloppe catégorielle', 'Financement interministériel', 'Reventilation sous plafond']`
  - [x] Périmètre de la mesure — checkbox-dropdown, `id: "el_perimetre_mesure_hidden"`, values: `['Application au stock', 'Application au flux', 'Reclassement']`
  - [x] Catégorie (grade) — checkbox-dropdown, `id: "el_grade_hidden"`, individual checkbox IDs suffixed `_el`
  - [x] Corps — `td.text_field :corps`, `id: "el_corps"`
  - [x] Effectifs N — `td.number_field :effectifs`, `id: "el_effectifs"`
  - [x] Effectifs N+1 — `td.number_field :effectifs_complementaire`, `id: "el_effectifs_complementaire"`
  - [x] Statut d'agents — `td.select :statut_agents`, `id: "el_statut_agents"`, values: `['Contractuel', 'Titulaire', 'Tous statuts confondus']`
  - [x] Montant au contrôle — `f.number_field :montant_ae`, `id: "el_montant_ae"`, no `acte-form-target: "montantAe"`
  - [x] Montant enveloppe N-1 — `td.number_field :montant_enveloppe_n1`, `id: "el_montant_enveloppe_n1"`, with `data: { action: "input->acte-form#calculateEffetEnveloppe" }`
  - [x] Impact maximal sans enveloppe — `td.number_field :impact_maximal_sans_enveloppe`, `id: "el_impact_maximal_sans_enveloppe"`, with `data: { action: "input->acte-form#calculateEffetEnveloppe" }`
  - [x] Effet de l'enveloppe — read-only display block (blue box), `id: "el_effet_enveloppe"`, shows `--%` by default
  - [x] Organisme-only block (copy Mesure transversale pattern, suffix IDs `_el`): Budget exécutoire radio, Opération budgétaire dropdown, Délibération en CA radio

- [x] **Task 2: Implement `_referentiel.html.erb` partial** (AC: 4, 5, 6)
  - [x] Replace placeholder in `app/views/actes/t2_sections/_referentiel.html.erb`
  - [x] Date d'effet de l'acte — `td.text_field :date_effet_acte`, `id: "ref_date_effet_acte"`
  - [x] Origine de financement — checkbox-dropdown, État only, `id: "ref_origine_financement_hidden"`, same values as other sections
  - [x] Périmètre de la mesure — checkbox-dropdown, `id: "ref_perimetre_mesure_hidden"`, IDs suffixed `_ref`
  - [x] Catégorie (grade) — checkbox-dropdown, `id: "ref_grade_hidden"`, IDs suffixed `_ref`
  - [x] Corps — `td.text_field :corps`, `id: "ref_corps"`
  - [x] Effectifs N — `td.number_field :effectifs`, `id: "ref_effectifs"`
  - [x] Effectifs N+1 — `td.number_field :effectifs_complementaire`, `id: "ref_effectifs_complementaire"`
  - [x] Montant au contrôle — `f.number_field :montant_ae`, `id: "ref_montant_ae"`, no `acte-form-target: "montantAe"`
  - [x] Impact financier N+1 — `td.number_field :impact_financier_n1`, `id: "ref_impact_financier_n1"`
  - [x] Déclinaison référentiel interministériel (État) / Déclinaison autre référentiel (Organisme) — `td.radio_button :referentiel_type` directement avec valeurs `'Interministériel'`/`'Autre référentiel'`, IDs `ref_referentiel_type_interministeriel`/`ref_referentiel_type_autre`
  - [x] Organisme-only block (copy Mesure transversale pattern, suffix IDs `_ref`): Budget exécutoire radio, Opération budgétaire dropdown, Délibération en CA radio

- [x] **Task 3: Add `calculateEffetEnveloppe` to Stimulus controller** (AC: 7)
  - [x] In `app/javascript/controllers/acte_form_controller.js`, add method `calculateEffetEnveloppe()` using `getElementById` (safe, no new targets needed)
  - [x] Wire `data: { action: "input->acte-form#calculateEffetEnveloppe" }` on both montant fields in the partial
  - [x] Called in `connect()` for edit form pre-population (element-existence guard prevents errors)

- [x] **Task 4: Update `T2_DETAIL_FIELDS_BY_NATURE` and `acte_params`** (AC: 8, 9)
  - [x] Updated `'Enveloppe limitative'` and `'Référentiel'` in `T2_DETAIL_FIELDS_BY_NATURE`
  - [x] Added `:montant_enveloppe_n1, :impact_maximal_sans_enveloppe, :referentiel_type` to `t2_detail_attributes` in `acte_params`

- [x] **Task 5: Update model validation for `budget_executoire`** (AC: 3, 6)
  - [x] Extended validation in `app/models/acte.rb` to include `'Enveloppe limitative'` and `'Référentiel'`

- [x] **Task 6: Write controller/integration tests** (AC: 1–10)
  - [x] `new T2 Enveloppe limitative état renders section with correct fields`
  - [x] `new T2 Enveloppe limitative organisme renders budget_executoire, operation_budgetaire, deliberation_ca`
  - [x] `create T2 Enveloppe limitative état saves t2_detail fields and montant_ae`
  - [x] `create T2 Enveloppe limitative organisme saves all fields including budget_executoire`
  - [x] `new T2 Référentiel état renders section with correct fields`
  - [x] `new T2 Référentiel organisme renders budget_executoire, operation_budgetaire, deliberation_ca`
  - [x] `create T2 Référentiel état saves t2_detail fields including referentiel_type`
  - [x] `create T2 Référentiel organisme saves all fields including budget_executoire`
  - [x] `new T2 Enveloppe limitative section is present but hidden when nature = Marché` (AC10 regression)
  - [x] `new HT2 does not include enveloppe_limitative or referentiel sections` (AC10 regression)

## Dev Notes

### Field storage split

#### Enveloppe limitative

| Field | Model | Column | Type |
|-------|-------|--------|------|
| `perimetre_mesure` | `t2_detail` | `perimetre_mesure` | `string[], array` |
| `grade` (= Catégorie) | `t2_detail` | `grade` | `string[], array` |
| `corps` | `t2_detail` | `corps` | `string` |
| `effectifs` | `t2_detail` | `effectifs` | `float` |
| `effectifs_complementaire` | `t2_detail` | `effectifs_complementaire` | `float` |
| `statut_agents` | `t2_detail` | `statut_agents` | `string` |
| `montant_enveloppe_n1` | `t2_detail` | `montant_enveloppe_n1` | `decimal` |
| `impact_maximal_sans_enveloppe` | `t2_detail` | `impact_maximal_sans_enveloppe` | `decimal` |
| `origine_financement` | `t2_detail` | `origine_financement` | `string[], array` |
| `date_effet_acte` | `t2_detail` | `date_effet_acte` | `string` |
| `montant_ae` | `acte` | `montant_ae` | `float` |
| `operation_budgetaire` | `acte` | `operation_budgetaire` | `string` |
| `budget_executoire` | `acte` | `budget_executoire` | `boolean` |
| `deliberation_ca` | `acte` | `deliberation_ca` | `boolean` |

#### Référentiel

| Field | Model | Column | Type |
|-------|-------|--------|------|
| `perimetre_mesure` | `t2_detail` | `perimetre_mesure` | `string[], array` |
| `grade` | `t2_detail` | `grade` | `string[], array` |
| `corps` | `t2_detail` | `corps` | `string` |
| `effectifs` | `t2_detail` | `effectifs` | `float` |
| `effectifs_complementaire` | `t2_detail` | `effectifs_complementaire` | `float` |
| `impact_financier_n1` | `t2_detail` | `impact_financier_n1` | `decimal` |
| `referentiel_type` | `t2_detail` | `referentiel_type` | `string` |
| `origine_financement` | `t2_detail` | `origine_financement` | `string[], array` |
| `date_effet_acte` | `t2_detail` | `date_effet_acte` | `string` |
| `montant_ae` | `acte` | `montant_ae` | `float` |
| `operation_budgetaire` | `acte` | `operation_budgetaire` | `string` |
| `budget_executoire` | `acte` | `budget_executoire` | `boolean` |
| `deliberation_ca` | `acte` | `deliberation_ca` | `boolean` |

All columns already exist in `db/schema.rb` lines 503–545 — **no migration needed**.

### `T2_DETAIL_FIELDS_BY_NATURE` — MUST be updated

Current state (lines 1136, 1140 of `actes_controller.rb`):
```ruby
'Enveloppe limitative' => [],
'Référentiel'          => []
```

Must become:
```ruby
'Enveloppe limitative' => %i[perimetre_mesure grade corps effectifs effectifs_complementaire statut_agents montant_enveloppe_n1 impact_maximal_sans_enveloppe origine_financement date_effet_acte],
'Référentiel'          => %i[perimetre_mesure grade corps effectifs effectifs_complementaire impact_financier_n1 referentiel_type origine_financement date_effet_acte],
```

Without this, `clear_irrelevant_t2_detail_fields` will **silently wipe all t2_detail data** for these natures on save. Critical fix.

### `acte_params` — fields to add in `t2_detail_attributes`

Currently permitted at lines 1192–1200 (after Story 2.7):
```ruby
t2_detail_attributes: [:id,
  :type_acte_t2, :effectifs, :effectifs_complementaire, :corps, :date_arrete_concours,
  :date_effet_acte, :impact_schema_emplois, :impact_autre_cbcm,
  :isp_cercle1, :isp_cercle1_montant, :isp_cercle1_enveloppe_sgg, :isp_cercle1_consommation,
  :isp_cercle2, :isp_cercle2_montant, :isp_cercle2_enveloppe_sgg, :isp_cercle2_consommation,
  :fa_technique, :accord_rffim, :sollicitation_db, :enveloppe_abondee,
  :statut_agents, :impact_financier_n1,
  grade: [], isp_cercle1_natures: [], isp_cercle2_natures: [],
  perimetre_mesure: [], origine_financement: []]
```

Must add: `:montant_enveloppe_n1, :impact_maximal_sans_enveloppe, :referentiel_type` as scalars.

Already present (no duplication): `:effectifs, :effectifs_complementaire, :corps, :date_effet_acte, :statut_agents, :impact_financier_n1, grade: [], perimetre_mesure: [], origine_financement: []`.

### ID collision prevention — use `_el` and `_ref` suffixes

Multiple t2_detail fields (`corps`, `effectifs`, `effectifs_complementaire`, `grade`, `perimetre_mesure`, `origine_financement`, `date_effet_acte`) are shared across several nature partials. All IDs must be suffixed to avoid DOM collision:

**Enveloppe limitative** — suffix `_el`:
- `id: "el_date_effet_acte"`, `id: "el_corps"`, `id: "el_effectifs"`, `id: "el_effectifs_complementaire"`
- Hidden: `"el_origine_financement_hidden"`, `"el_perimetre_mesure_hidden"`, `"el_grade_hidden"`
- Checkboxes: `"el_origine_financement_<val>"`, `"el_perimetre_mesure_<val>"`, `"el_grade_<val>"`
- Radios: `"budget_executoire_el_oui"`, `"budget_executoire_el_non"`, `"deliberation_ca_el_oui"`, `"deliberation_ca_el_non"`
- Calculation fields: `"el_montant_enveloppe_n1"`, `"el_impact_maximal_sans_enveloppe"`, `"el_effet_enveloppe"`

**Référentiel** — suffix `_ref`:
- `id: "ref_date_effet_acte"`, `id: "ref_corps"`, `id: "ref_effectifs"`, `id: "ref_effectifs_complementaire"`
- Hidden: `"ref_origine_financement_hidden"`, `"ref_perimetre_mesure_hidden"`, `"ref_grade_hidden"`
- Checkboxes: `"ref_grade_<val>"`, etc.
- Radios: `"budget_executoire_ref_oui"`, `"budget_executoire_ref_non"`, `"deliberation_ca_ref_oui"`, `"deliberation_ca_ref_non"`
- Référentiel type radio: `"ref_referentiel_type_oui"`, `"ref_referentiel_type_non"`

### `referentiel_type` — radio to string value mapping

The screenshot shows "Déclinaison référentiel interministériel: Oui / Non" (État) and "Déclinaison autre référentiel: Oui / Non" (Organisme). Both map to the same `td.referentiel_type` string column.

**Pattern — use a hidden field + radio buttons:**
```erb
<%= td.hidden_field :referentiel_type, id: "ref_referentiel_type_hidden", value: td.object.referentiel_type %>
<% is_interministeriel = td.object.referentiel_type == 'Interministériel' %>

<fieldset class="fr-fieldset fr-mb-0">
  <legend class="fr-fieldset__legend--regular fr-fieldset__legend">
    <%= is_organisme ? "Déclinaison autre référentiel" : "Déclinaison référentiel interministériel" %>
  </legend>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <input type="radio" id="ref_referentiel_type_oui" name="acte[t2_detail_attributes][referentiel_type_radio]"
             value="Interministériel" <%= "checked" if is_interministeriel %>
             data-action="change->acte-form#syncReferentielType">
      <label class="fr-label" for="ref_referentiel_type_oui">Oui</label>
    </div>
  </div>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <input type="radio" id="ref_referentiel_type_non" name="acte[t2_detail_attributes][referentiel_type_radio]"
             value="Autre référentiel" <%= "checked" unless is_interministeriel %>
             data-action="change->acte-form#syncReferentielType">
      <label class="fr-label" for="ref_referentiel_type_non">Non</label>
    </div>
  </div>
</fieldset>
```

The `syncReferentielType` Stimulus method copies the selected radio value to the hidden `ref_referentiel_type_hidden` field. Alternatively, use `td.radio_button :referentiel_type, 'Interministériel'` and `td.radio_button :referentiel_type, 'Autre référentiel'` directly — Rails will submit the selected value without a hidden field trick.

**Simplest approach** (preferred): use `td.radio_button` directly with values `'Interministériel'`/`'Autre référentiel'`:
```erb
<div class="fr-radio-group">
  <%= td.radio_button :referentiel_type, 'Interministériel', id: "ref_referentiel_type_interministeriel",
                      checked: td.object.referentiel_type == 'Interministériel' %>
  <label class="fr-label" for="ref_referentiel_type_interministeriel">Oui</label>
</div>
<div class="fr-radio-group">
  <%= td.radio_button :referentiel_type, 'Autre référentiel', id: "ref_referentiel_type_autre",
                      checked: td.object.referentiel_type != 'Interministériel' %>
  <label class="fr-label" for="ref_referentiel_type_autre">Non</label>
</div>
```
No JS needed. `referentiel_type` is already a plain string column — no conversion needed in `acte_params`.

### `calculateEffetEnveloppe` — Stimulus method

Add to `acte_form_controller.js`. The ISP section already has `updateReste` for similar per-cercle calculations (lines ~818–862). Follow that pattern:

```javascript
calculateEffetEnveloppe() {
    const envelN1El = document.getElementById('el_montant_enveloppe_n1')
    const impactEl = document.getElementById('el_impact_maximal_sans_enveloppe')
    const effetEl = document.getElementById('el_effet_enveloppe')
    if (!envelN1El || !impactEl || !effetEl) return
    const enveloppe = this.numberFormat(envelN1El.value)
    const impact = this.numberFormat(impactEl.value)
    if (!enveloppe || enveloppe === 0) {
        effetEl.textContent = '--%'
        return
    }
    const effet = (impact / enveloppe * 100).toFixed(2)
    effetEl.textContent = effet + '%'
}
```

Wire it in the partial via `data: { action: "input->acte-form#calculateEffetEnveloppe" }` on both montant fields. Also call on connect for edit form pre-population: in `connect()`, call `this.calculateEffetEnveloppe()` (already safe — it checks for element existence).

### `montant_ae` — no `acte-form-target: "montantAe"`

As established in Story 2.6 (Marché) and confirmed in Story 2.7 (Mesure transversale): **do NOT add** `acte_form_target: "montantAe"` to the `montant_ae` field in these section partials. That target triggers incorrect negative-amount logic that only applies to HT2. Pattern to follow:

```erb
<%= f.number_field :montant_ae, value: acte.montant_ae, id: "el_montant_ae", class: "fr-input", step: "0.01",
                   data: { action: "input->acte-form#changeNumber", acte_form_number_field: true } %>
```

### `checkbox-dropdown` controller pattern

Reuse the exact pattern from `_mesure_transversale.html.erb` (fully implemented). Key points:
- `data-controller="checkbox-dropdown"` on the wrapping div
- `td.hidden_field :field_name` with `data: { checkbox_dropdown_target: "hidden" }`, `value: current_values.join(",")`
- Button with `data-action="click->checkbox-dropdown#toggle"`
- Menu div with `data-checkbox-dropdown-target="menu"`
- Each checkbox: `data-checkbox-dropdown-target="checkbox"`, `data-action="change->checkbox-dropdown#change"`

The `acte_params` conversion already handles `perimetre_mesure`, `grade`, `origine_financement` (split on comma). No new conversion needed.

### Section wiring — already in parent partial

Both sections are already wired in `_form_informations_t2.html.erb`:
```erb
<div id="t2-section-enveloppe-limitative" class="fr-hidden" data-acte-form-target="natureT2Section" aria-live="polite">
  <%= render 'actes/t2_sections/enveloppe_limitative', f: f, td: td, acte: @acte %>
</div>
...
<div id="t2-section-referentiel" class="fr-hidden" data-acte-form-target="natureT2Section" aria-live="polite">
  <%= render 'actes/t2_sections/referentiel', f: f, td: td, acte: @acte %>
</div>
```

And `toggleNatureT2` in `acte_form_controller.js` (lines 866–873) already maps both natures to their section IDs. **No changes needed to parent partial or JS mapping.**

### Organisme-only fields — exact Mesure transversale pattern

For Budget exécutoire, Opération budgétaire, Délibération en CA — copy `_mesure_transversale.html.erb` rows 4–5 exactly, replacing `_mt` suffix with `_el` or `_ref`. Same `is_organisme` ERB guard. Same defaults (budget_executoire: true, deliberation_ca: false).

### Tests — fixtures and patterns

- `users(:three)` (statut: DCB) — use for both État and Organisme (DCB can access all natures for both périmètres)
- `users(:two)` (statut: CBR) — DCB only for État natures; CBR can access Enveloppe limitative and Référentiel for Organisme périmètre
- Pattern from `actes_controller_test.rb` lines 841–951 — directly reusable for new tests
- Both natures available for État (DCB) and Organisme (all profiles) — confirm in `set_variables_form` (line 1218)

### `date_effet_acte` — unique IDs required

Multiple partials use `td.text_field :date_effet_acte`. Use `"el_date_effet_acte"` and `"ref_date_effet_acte"` to avoid DOM collision with other visible/hidden partials.

### Project Structure Notes

- Views: `app/views/actes/t2_sections/` — replace two placeholder files: `_enveloppe_limitative.html.erb`, `_referentiel.html.erb`
- Section partials receive `f:, td:, acte:` locals — `f:` for acte fields, `td:` for t2_detail fields
- DSFR components: `fr-fieldset`, `fr-radio-group`, `fr-input-group`, `fr-select-group`, `fr-grid-row fr-grid-row--gutters`, `fr-col-12 fr-col-lg-4`
- No new partials, no new routes, no new migrations

### References

- Epic spec — Story 2.8: [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 419–456
- Previous story (2.7 Mesure transversale, done): [_bmad-output/implementation-artifacts/2-7-section-specifique-nature-mesure-transversale.md](_bmad-output/implementation-artifacts/2-7-section-specifique-nature-mesure-transversale.md)
- Enveloppe limitative placeholder: [app/views/actes/t2_sections/_enveloppe_limitative.html.erb](app/views/actes/t2_sections/_enveloppe_limitative.html.erb)
- Référentiel placeholder: [app/views/actes/t2_sections/_referentiel.html.erb](app/views/actes/t2_sections/_referentiel.html.erb)
- Mesure transversale partial (primary pattern reference): [app/views/actes/t2_sections/_mesure_transversale.html.erb](app/views/actes/t2_sections/_mesure_transversale.html.erb)
- Parent T2 form (section wiring): [app/views/actes/_form_informations_t2.html.erb](app/views/actes/_form_informations_t2.html.erb) lines 116–138
- Stimulus controller (toggleNatureT2, calculateEffetEnveloppe target): [app/javascript/controllers/acte_form_controller.js](app/javascript/controllers/acte_form_controller.js) lines 865–889
- Controller `T2_DETAIL_FIELDS_BY_NATURE` (lines 1136, 1140 — MUST update): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb#L1136)
- Controller `acte_params` t2_detail_attributes (lines 1192–1200 — MUST extend): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb#L1192)
- DB schema (column verification — all columns present): [db/schema.rb](db/schema.rb) lines 503–545
- Model validation for budget_executoire (line 91 — MUST extend): [app/models/acte.rb](app/models/acte.rb#L91)
- Existing tests (pattern to replicate): [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb) lines 841–951

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `_enveloppe_limitative.html.erb` implémenté : 2 checkbox-dropdowns (`perimetre_mesure`, `grade`/Catégorie), checkbox-dropdown `origine_financement` État seulement, `fr-select` classique pour `statut_agents`, champs numériques `effectifs`/`effectifs_complementaire`/`montant_enveloppe_n1`/`impact_maximal_sans_enveloppe` via `td.`, `montant_ae` via `f.` (sans `acte-form-target: "montantAe"`), bloc "Effet de l'enveloppe" bleu read-only (`id: el_effet_enveloppe`). Bloc organisme-only : Budget exécutoire radio, Opération budgétaire dropdown, Délibération en CA radio — IDs suffixés `_el`.
- `_referentiel.html.erb` implémenté : mêmes checkbox-dropdowns (`perimetre_mesure`, `grade`, `origine_financement` État seulement), champs numériques `effectifs`/`effectifs_complementaire`/`impact_financier_n1` via `td.`, `montant_ae` via `f.`, radio `referentiel_type` via `td.radio_button` directement avec valeurs `'Interministériel'`/`'Autre référentiel'` — label conditionnel selon périmètre ("Déclinaison référentiel interministériel" vs "Déclinaison autre référentiel"). Bloc organisme-only identique à EL, IDs suffixés `_ref`.
- `calculateEffetEnveloppe()` ajouté dans `acte_form_controller.js` : accès par `getElementById` (pas de nouveaux targets Stimulus), appelé dans `connect()` pour pre-population edit. Calcule `impact / enveloppe * 100`, affiche `--%` si enveloppe absente ou nulle.
- `T2_DETAIL_FIELDS_BY_NATURE` mis à jour : `'Enveloppe limitative'` et `'Référentiel'` passent de `[]` à la liste complète des champs t2_detail respectifs. Sans ce fix, `clear_irrelevant_t2_detail_fields` aurait silencieusement effacé toutes les données.
- `acte_params` étendu : ajout de `:montant_enveloppe_n1, :impact_maximal_sans_enveloppe, :referentiel_type` dans `t2_detail_attributes`.
- Validation `budget_executoire` étendue à `'Enveloppe limitative'` et `'Référentiel'` dans `acte.rb` — cohérent avec AC3/AC6.
- 10 tests ajoutés : rendu état/organisme × 2 natures (4 tests render), persistance état/organisme × 2 natures (4 tests create), 2 tests de régression (section cachée pour Marché, absente pour HT2).
- Suite complète post-implémentation : **57 runs / 654 assertions / 0 failures / 0 errors**.

### File List

- `app/views/actes/t2_sections/_enveloppe_limitative.html.erb`
- `app/views/actes/t2_sections/_referentiel.html.erb`
- `app/javascript/controllers/acte_form_controller.js`
- `app/controllers/actes_controller.rb`
- `app/models/acte.rb`
- `test/controllers/actes_controller_test.rb`
