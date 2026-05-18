# Story 2.7: Nature-Specific Section — "Mesure transversale"

Status: done

## Story

As an instructor,
I want to fill in the specific fields of a T2 acte with nature "Mesure transversale",
so that I can document the cross-cutting HR and financial impact of the measure.

## Acceptance Criteria

### AC1 — Mesure transversale section appears when nature is selected

**Given** the instructor selects "Mesure transversale" from the nature dropdown in the T2 step-1 form
**When** the `toggleNatureT2` Stimulus method fires
**Then** the `#t2-section-mesure-transversale` div becomes visible (removes `fr-hidden`)
**And** all other nature sections remain hidden

### AC2 — État périmètre: fields displayed

**Given** the section is visible **AND** `acte.perimetre == 'etat'`
**When** it renders
**Then** the following fields are present (all optional):
- **Périmètre de la mesure** (`td[perimetre_mesure]`, checkbox-dropdown multi-select) — optionnel
- **Catégorie** (`td[grade]`, checkbox-dropdown multi-select, same `grade` field as Annexe financière) — optionnel
- **Corps** (`td[corps]`, text input) — optionnel
- **Effectifs (année N)** (`td[effectifs]`, float — same field as Annexe financière) — optionnel
- **Effectifs (année N+1)** (`td[effectifs_complementaire]`, float — same field as Annexe financière) — optionnel
- **Statut d'agents** (`td[statut_agents]`, dropdown) — optionnel
- **Montant au contrôle** (`acte[montant_ae]`, decimal) — optionnel
- **Impact financier N+1** (`td[impact_financier_n1]`, decimal) — optionnel
- **Origine de financement** (`td[origine_financement]`, checkbox-dropdown, État only) — optionnel
- **Date d'effet de l'acte** (`td[date_effet_acte]`, text input) — optionnel

**And** "Opération budgétaire" is NOT displayed for périmètre État
**And** "Origine de financement" is NOT displayed for périmètre Organisme

### AC3 — Organisme périmètre: adds Budget exécutoire, Opération budgétaire, Délibération en CA

**Given** the section is visible **AND** `acte.perimetre == 'organisme'`
**When** it renders
**Then** all fields from AC2 are present (with Organisme label replacing État where applicable)
**And** the following additional fields are present:
- **Budget exécutoire** (`acte[budget_executoire]`, radio Oui/Non) — **obligatoire**, default Oui
- **Opération budgétaire** (`acte[operation_budgetaire]`, dropdown: Globalisée / Fléchée) — optionnel
- **Délibération en CA nécessaire** (`acte[deliberation_ca]`, radio Oui/Non) — default Non

**And** the organisme field (nom_organisme) is in the parent partial, not in this section

### AC4 — Screenshot layout matches

**État layout (screenshot 1):**
```
Row 1: [Initiales instructeur*] | [Nature: Mesure transversale] | [Centre financier]
Row 2: [Exercice* dropdown]     | [Date de saisine* dropdown]   | [Service ordonnateur]
Row 3: [Objet]                  | [Date d'effet de l'acte]      | [Origine de financement dropdown]
Row 4: [Périmètre de la mesure dropdown] | [Catégorie dropdown]         | [Corps text]
Row 5: [Effectifs (année N)]    | [Effectifs (année N+1)]       | [Statut d'agents dropdown]
Row 6: [Montant au contrôle]    | [Impact financier N+1]
Row 7: [Précisions sur l'acte (textarea)]
Footer: [Cet acte a été réalisé en période de services votés (checkbox)]
```

**Organisme layout (screenshot 2):**
```
Row 1: [Initiales instructeur*] | [Nature: Mesure transversale] | [Organisme*]
Row 2: [Exercice* dropdown]     | [Date de saisine* dropdown]   | [Service ordonnateur]
Row 3: [Objet]                  | [Date d'effet de l'acte]      | [Périmètre de la mesure dropdown]
Row 4: [Catégorie dropdown]     | [Corps text]                  | [Effectifs (année N)]
Row 5: [Effectifs (année N+1)]  | [Statut d'agents dropdown]    | [Montant au contrôle]
Row 6: [Impact financier N+1]   | [Budget exécutoire* Oui/Non]  | [Opération budgétaire dropdown]
Row 7: [Délibération en CA nécessaire Oui/Non]
Row 8: [Précisions sur l'acte (textarea)]
Footer: [Cet acte a été réalisé en période de services votés (checkbox)]
```

> Note: `Précisions sur l'acte` and `services_votes` are in the **parent partial** `_form_informations_t2.html.erb`. Do NOT add them to this section partial.

### AC5 — Data saved correctly

**Given** the form is submitted with Mesure transversale fields filled
**When** the controller processes params
**Then** the following are saved in `t2_details`:
- `td.perimetre_mesure` (string[], array PostgreSQL)
- `td.grade` (string[], array PostgreSQL) — shared field with Annexe financière
- `td.corps` (string)
- `td.effectifs` (float) — shared with Annexe financière
- `td.effectifs_complementaire` (float) — shared with Annexe financière
- `td.statut_agents` (string)
- `td.impact_financier_n1` (decimal)
- `td.origine_financement` (string[], array PostgreSQL)
- `td.date_effet_acte` (string)

**And** the following are saved in `actes`:
- `acte.montant_ae` (float) — same as Marché/FA pattern
- `acte.operation_budgetaire` (string, organisme only)
- `acte.budget_executoire` (boolean, organisme only — default true)
- `acte.deliberation_ca` (boolean, organisme only — default false)

**And** `T2_DETAIL_FIELDS_BY_NATURE['Mesure transversale']` must be updated to list the relevant `t2_detail` fields so `clear_irrelevant_t2_detail_fields` preserves them
**And** `t2_detail_attributes` in `acte_params` must be extended to permit the new fields

### AC6 — No regression

**Given** an acte with `titre = 'HT2'`
**Then** the Mesure transversale section does not appear

**Given** a different T2 nature is selected (e.g. Marché, ISP)
**Then** the Mesure transversale section is hidden and the appropriate section shows

## Tasks / Subtasks

- [x] **Task 1: Implement `_mesure_transversale.html.erb` partial** (AC: 1, 2, 3, 4)
  - [x] Replace placeholder in `app/views/actes/t2_sections/_mesure_transversale.html.erb`
  - [x] All fields use `td.` builder for t2_detail fields, `f.` for acte fields
  - [x] Date d'effet de l'acte — text input via `td.text_field :date_effet_acte` (unique id: `mt_date_effet_acte`)
  - [x] Origine de financement — `checkbox-dropdown` controller, `td.hidden_field :origine_financement` + checkboxes, **État only** (`<% if !is_organisme %>`)
  - [x] Périmètre de la mesure — `checkbox-dropdown` controller, `td.hidden_field :perimetre_mesure` + checkboxes
  - [x] Grade (Catégorie) — `checkbox-dropdown` controller, `td.hidden_field :grade` + checkboxes (unique ids suffixed `_mt` to avoid collision with `_annexe_financiere`)
  - [x] Corps — `td.text_field :corps` (unique id: `mt_corps`)
  - [x] Effectifs (année N) — `td.number_field :effectifs` (unique id: `mt_effectifs`)
  - [x] Effectifs (année N+1) — `td.number_field :effectifs_complementaire` (unique id: `mt_effectifs_complementaire`)
  - [x] Statut d'agents — `td.select :statut_agents`, classic `fr-select` dropdown, values: `['Contractuel', 'Titulaire', 'Tous statuts confondus']`, prompt: "Sélectionner une option"
  - [x] Montant au contrôle — `f.number_field :montant_ae` (unique id: `mt_montant_ae`, no `required`, no `acte-form-target: "montantAe"` — see Dev Notes)
  - [x] Impact financier N+1 — `td.number_field :impact_financier_n1` (unique id: `mt_impact_financier_n1`)
  - [x] Organisme-only block: Budget exécutoire radio, Opération budgétaire dropdown, Délibération en CA radio — reuse Marché patterns, suffix IDs `_mt`
  - [x] Use `acte.perimetre == 'organisme'` ERB conditionals

- [x] **Task 2: Update `T2_DETAIL_FIELDS_BY_NATURE` and `acte_params`** (AC: 5)
  - [x] In `app/controllers/actes_controller.rb`, update `'Mesure transversale' => []` to list t2_detail fields
  - [x] In `acte_params` `t2_detail_attributes`, add the missing fields: `:statut_agents, :impact_financier_n1`, and arrays `perimetre_mesure: [], origine_financement: []`
  - [x] Fields already permitted in `t2_detail_attributes`: `:corps, :date_effet_acte, :effectifs, :effectifs_complementaire`, `grade: []` — confirmed, no duplicate added
  - [x] Fields saved on `actes` (`:montant_ae, :operation_budgetaire, :budget_executoire, :deliberation_ca`) are already in `acte_params` — no change needed

- [x] **Task 3: Handle array params conversion in `acte_params`** (AC: 5)
  - [x] Add conversion for `perimetre_mesure` and `origine_financement` in `acte_params`

- [x] **Task 4: Write controller/integration tests** (AC: 2, 3, 5, 6)
  - [x] Test: `new T2 Mesure transversale état renders section without organisme-only fields`
  - [x] Test: `new T2 Mesure transversale organisme renders budget_executoire, operation_budgetaire, deliberation_ca`
  - [x] Test: `create T2 Mesure transversale état saves t2_detail fields and montant_ae`
  - [x] Test: `create T2 Mesure transversale organisme saves all fields including budget_executoire`
  - [x] Test: `new T2 Mesure transversale section is present but hidden when nature = Marché` (AC6 regression)
  - [x] Test: `new HT2 does not include mesure_transversale section` (AC6 regression)

## Dev Notes

### Field storage split

| Field | Model | Column | Type |
|-------|-------|--------|------|
| `perimetre_mesure` | `t2_detail` | `perimetre_mesure` | `string[], array` |
| `grade` (= Catégorie) | `t2_detail` | `grade` | `string[], array` |
| `corps` | `t2_detail` | `corps` | `string` |
| `effectifs` | `t2_detail` | `effectifs` | `float` |
| `effectifs_complementaire` | `t2_detail` | `effectifs_complementaire` | `float` |
| `statut_agents` | `t2_detail` | `statut_agents` | `string` |
| `impact_financier_n1` | `t2_detail` | `impact_financier_n1` | `decimal` |
| `origine_financement` | `t2_detail` | `origine_financement` | `string[], array` |
| `date_effet_acte` | `t2_detail` | `date_effet_acte` | `string` |
| `montant_ae` | `acte` | `montant_ae` | `float` |
| `operation_budgetaire` | `acte` | `operation_budgetaire` | `string` |
| `budget_executoire` | `acte` | `budget_executoire` | `boolean` |
| `deliberation_ca` | `acte` | `deliberation_ca` | `boolean` |

All columns exist in `db/schema.rb` — **no migration needed**.

### `T2_DETAIL_FIELDS_BY_NATURE` — MUST be updated

Current (line 1139 of `actes_controller.rb`):
```ruby
'Mesure transversale' => [],
```

Must become:
```ruby
'Mesure transversale' => %i[perimetre_mesure grade corps effectifs effectifs_complementaire statut_agents impact_financier_n1 origine_financement date_effet_acte],
```

Without this update, `clear_irrelevant_t2_detail_fields` will **wipe all t2_detail fields** when the acte has nature Mesure transversale, causing silent data loss. This is a critical fix.

### `acte_params` — fields to add in `t2_detail_attributes`

Currently permitted at lines 1190–1196:
```ruby
t2_detail_attributes: [:id,
  :type_acte_t2, :effectifs, :effectifs_complementaire, :corps, :date_arrete_concours,
  :date_effet_acte, :impact_schema_emplois, :impact_autre_cbcm,
  :isp_cercle1, :isp_cercle1_montant, :isp_cercle1_enveloppe_sgg, :isp_cercle1_consommation,
  :isp_cercle2, :isp_cercle2_montant, :isp_cercle2_enveloppe_sgg, :isp_cercle2_consommation,
  :fa_technique, :accord_rffim, :sollicitation_db, :enveloppe_abondee,
  grade: [], isp_cercle1_natures: [], isp_cercle2_natures: []]
```

Must add: `:statut_agents, :impact_financier_n1` as scalars, and `perimetre_mesure: [], origine_financement: []` as arrays.

Already present (no duplication needed): `:effectifs, :effectifs_complementaire, :corps, :date_effet_acte, grade: []`.

### `checkbox-dropdown` controller — for `perimetre_mesure`, `grade`, `origine_financement`

Pattern from `_isp.html.erb` (isp_cercle1_natures):
```erb
<% current_values = td.object.perimetre_mesure || [] %>
<div data-controller="checkbox-dropdown" style="position: relative;">
  <label class="fr-label">Périmètre de la mesure</label>
  <%= td.hidden_field :perimetre_mesure, id: "mt_perimetre_mesure_hidden",
      data: { checkbox_dropdown_target: "hidden" },
      value: current_values.join(",") %>
  <button type="button" class="fr-select w-100" ...>
    <span data-checkbox-dropdown-target="label" data-placeholder="Sélectionner une option">
      <%= current_values.any? ? current_values.join(", ") : "Sélectionner une option" %>
    </span>
  </button>
  <div class="fr-hidden" data-checkbox-dropdown-target="menu" ...>
    <% ["Option1", "Option2", ...].each do |val| %>
      <div class="fr-checkbox-group">
        <input type="checkbox" id="mt_perimetre_mesure_<%= val.parameterize %>"
               value="<%= val %>" <%= 'checked' if current_values.include?(val) %>
               data-checkbox-dropdown-target="checkbox"
               data-action="change->checkbox-dropdown#change">
        <label class="fr-label" for="mt_perimetre_mesure_<%= val.parameterize %>"><%= val %></label>
      </div>
    <% end %>
  </div>
</div>
```

The `checkbox-dropdown` JS controller (already installed at `app/javascript/controllers/checkbox_dropdown_controller.js`) reads from checkboxes and writes to the hidden field as a comma-separated string. The `acte_params` conversion (Task 3) splits that string back to array.

### Values for dropdowns and checkboxes

**Périmètre de la mesure** — checkbox-dropdown (multi-select), values: `['Application au stock', 'Application au flux', 'Reclassement']`

**Grade / Catégorie** — checkbox-dropdown (multi-select), values: `['A+', 'A', 'B', 'C']`. Reuse the same values list as Annexe financière. Suffix all IDs with `_mt` to avoid DOM collision.

**Statut d'agents** — classic single-value `<select>` (not checkbox-dropdown), values: `['Contractuel', 'Titulaire', 'Tous statuts confondus']`. Column is `string` — store as a single value.

**Origine de financement** — checkbox-dropdown (multi-select, array column), values: `['Enveloppe catégorielle', 'Financement interministériel', 'Reventilation sous plafond']`. **Displayed for périmètre État only.**

### `montant_ae` — on `actes` table, NOT using `acte-form-target: "montantAe"`

As per Story 2.6 correction (H2 in completion notes): `acte_form_target: "montantAe"` causes incorrect negative-amount logic to apply. For Mesure transversale (like Marché), do NOT add that target:

```erb
<%= f.number_field :montant_ae, value: acte.montant_ae, id: "mt_montant_ae", class: "fr-input", step: "0.01",
                   data: { action: "input->acte-form#changeNumber", acte_form_number_field: true } %>
```

No `required` attribute — all fields are optional for this nature.

### ID collision prevention — use `_mt` suffix

Several t2_detail fields (`corps`, `effectifs`, `effectifs_complementaire`, `grade`) are shared with Annexe financière. Both partials are rendered in the same DOM (hidden/shown by Stimulus). All IDs in this partial must have a `_mt` suffix:
- `id: "mt_corps"` (not `"acte_t2_detail_corps"`)
- `id: "mt_effectifs"` (not `"acte_t2_detail_effectifs"`)
- `id: "mt_effectifs_complementaire"`
- Hidden fields for grade/perimetre_mesure/origine_financement: `mt_grade_hidden`, `mt_perimetre_mesure_hidden`, `mt_origine_financement_hidden`
- Individual checkbox IDs: `mt_grade_<value>`, etc.
- Radio button IDs for budget_executoire: `budget_executoire_mt_oui`, `budget_executoire_mt_non`
- Radio button IDs for deliberation_ca: `deliberation_ca_mt_oui`, `deliberation_ca_mt_non`

This follows the pattern established in Story 2.6 for Marché (`_marche` suffix).

### Stimulus JS — no changes needed

`toggleNatureT2` already maps `'Mesure transversale': 't2-section-mesure-transversale'` (line 872 of `acte_form_controller.js`). The section wrapper is already in place in `_form_informations_t2.html.erb` (line 132–134).

No new JS methods needed — no real-time calculations for this nature.

### Organisme-only fields — exact Marché pattern

For Budget exécutoire, Opération budgétaire, and Délibération en CA — copy the pattern from `_marche.html.erb` exactly, only replacing IDs (`_marche` → `_mt`). The `deliberation_ca` here is simple Oui/Non with no sub-fields, same as Marché.

```erb
<% if is_organisme %>
  <%# Budget exécutoire + Opération budgétaire %>
  <%# Délibération en CA %>
<% end %>
```

### `date_effet_acte` — unique ID required

Both this partial and Annexe financière + ISP use `td.text_field :date_effet_acte`. Use `id: "mt_date_effet_acte"` to avoid DOM collision.

### Section wrapper in parent form — already wired

`_form_informations_t2.html.erb` line 132–134:
```erb
<div id="t2-section-mesure-transversale" class="fr-hidden" data-acte-form-target="natureT2Section" aria-live="polite">
  <%= render 'actes/t2_sections/mesure_transversale', f: f, td: td, acte: @acte %>
</div>
```

No change needed to the parent partial.

### Tests — fixtures available

From Story 2.6 notes:
- `users(:two)` — statut: CBR
- `users(:three)` — statut: DCB
- `users(:one)` — statut: admin (treated as DCB)

Mesure transversale is available for both État (DCB) and Organisme (all profiles). Test both périmètres.

### Project Structure Notes

- Views: `app/views/actes/t2_sections/` — one partial per nature, replace placeholder
- Section partial receives `f:, td:, acte:` locals — `f:` for acte fields, `td:` for t2_detail fields
- DSFR components: `fr-fieldset`, `fr-radio-group`, `fr-input-group`, `fr-select-group`, `fr-grid-row fr-grid-row--gutters`, `fr-col-12 fr-col-lg-4`
- `checkbox-dropdown` controller: already installed, used in ISP for natures multi-select

### References

- Epic spec — Story 2.7: [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 393–416
- Previous story (2.6 Marché, done): [_bmad-output/implementation-artifacts/2-6-section-specifique-nature-marche-psc.md](_bmad-output/implementation-artifacts/2-6-section-specifique-nature-marche-psc.md)
- Section placeholder: [app/views/actes/t2_sections/_mesure_transversale.html.erb](app/views/actes/t2_sections/_mesure_transversale.html.erb)
- Marché partial (organisme-only fields pattern): [app/views/actes/t2_sections/_marche.html.erb](app/views/actes/t2_sections/_marche.html.erb)
- ISP partial (checkbox-dropdown pattern): [app/views/actes/t2_sections/_isp.html.erb](app/views/actes/t2_sections/_isp.html.erb)
- Checkbox-dropdown controller: [app/javascript/controllers/checkbox_dropdown_controller.js](app/javascript/controllers/checkbox_dropdown_controller.js)
- T2 form parent (section wiring): [app/views/actes/_form_informations_t2.html.erb](app/views/actes/_form_informations_t2.html.erb) lines 132–134
- Controller `T2_DETAIL_FIELDS_BY_NATURE` (line 1139 — MUST update): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb#L1139)
- Controller `acte_params` t2_detail_attributes (lines 1190–1196 — MUST extend): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb#L1190)
- DB schema (column verification): [db/schema.rb](db/schema.rb) lines 503–545
- Existing tests pattern: [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `_mesure_transversale.html.erb` implémenté : 3 checkbox-dropdowns (`perimetre_mesure`, `grade`/Catégorie, `origine_financement` État seulement), `fr-select` classique pour `statut_agents`, champs numériques `effectifs`/`effectifs_complementaire`/`impact_financier_n1` via `td.`, `montant_ae` via `f.` (sans `acte-form-target: "montantAe"`). Bloc organisme-only : Budget exécutoire radio, Opération budgétaire dropdown, Délibération en CA radio — IDs suffixés `_mt` pour éviter collision DOM avec Annexe financière.
- `T2_DETAIL_FIELDS_BY_NATURE['Mesure transversale']` mis à jour : `[]` → liste complète des 9 champs `t2_detail`. Sans ce fix, `clear_irrelevant_t2_detail_fields` aurait silencieusement effacé toutes les données Mesure transversale.
- `acte_params` étendu : ajout de `:statut_agents, :impact_financier_n1` en scalaires et `perimetre_mesure: [], origine_financement: []` en arrays dans `t2_detail_attributes`.
- Conversions string→array ajoutées pour `perimetre_mesure` et `origine_financement` (même pattern que `grade` existant).
- 6 tests ajoutés dans `actes_controller_test.rb` : rendu état (présence des champs t2_detail, origine_financement présente, pas de champs organisme), rendu organisme (budget_executoire, operation_budgetaire Globalisée/Fléchée, deliberation_ca, origine_financement absente), persistance état (t2_detail sauvegardé avec arrays, montant_ae sur acte), persistance organisme (budget_executoire false, operation_budgetaire Globalisée, deliberation_ca true), régression Marché (section MT cachée), régression HT2 (section MT absente).
- Suite complète post-implémentation : **47 runs / 450 assertions / 0 failures / 0 errors**.

### Senior Developer Review (AI) — 2026-05-13

**Issues corrigés :**

- **[H1] Validation `budget_executoire` étendue à Mesure transversale** (`app/models/acte.rb:91`) — la condition `if:` couvrait uniquement `nature == 'Marché'` ; AC3 le déclare obligatoire pour MT organisme aussi. Étendue à `['Marché', 'Mesure transversale']`.
- **[H2] Test create état : assertions sur valeurs par défaut ajoutées** (`actes_controller_test.rb`) — `budget_executoire == true` et `deliberation_ca == false` (valeurs DB par défaut) maintenant assertés, aligné avec le pattern du test Marché.
- **[M1] Layout refactorisé en rows distinctes** (`_mesure_transversale.html.erb`) — restructuré de 1 grand `fr-grid-row` en 4–5 rows séparées : (1) date_effet + origine_financement, (2) périmètre + grade + corps, (3) effectifs + statut, (4) montant + impact + budget_executoire organisme, (5) opération budgétaire + délibération CA. Aligné avec les screenshots AC4.
- **[M2] Test organisme render complété** — assertions `perimetre_mesure`, `grade`, `impact_financier_n1`, `montant_ae` présents pour organisme (AC3 : "all fields from AC2").
- **[M3] Test create organisme : assertion `perimetre_mesure == []` ajoutée** — valide le comportement des colonnes array PostgreSQL quand le champ n'est pas soumis.

**Suite post-review : 47 runs / 461 assertions / 0 failures / 0 errors.**

### File List

- `app/views/actes/t2_sections/_mesure_transversale.html.erb`
- `app/controllers/actes_controller.rb`
- `app/models/acte.rb`
- `test/controllers/actes_controller_test.rb`
