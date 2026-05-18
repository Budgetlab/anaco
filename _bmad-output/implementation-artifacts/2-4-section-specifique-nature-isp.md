# Story 2.4: Nature-Specific Section — "ISP"

Status: done

## Story

As an instructor,
I want to fill in the specific fields of a T2 acte with nature "ISP",
so that I can document the indemnités spéciales de participation by circle (Cercle 1 and Cercle 2).

## Acceptance Criteria

### AC1 — ISP section appears when nature is selected

**Given** the instructor selects "ISP" from the nature dropdown in the T2 step-1 form
**When** the `toggleNatureT2` Stimulus method fires
**Then** the `#t2-section-isp` div becomes visible (removes `fr-hidden`)
**And** all other nature sections remain hidden
**And** `#t2-deliberation-ca-row` remains hidden (ISP is not "Annexe financière")

### AC2 — ISP section fields displayed

**Given** the ISP section is visible
**When** it renders
**Then** the following fields are present inside `#t2-section-isp`:
- **Date d'effet de l'acte** (`t2_detail[date_effet_acte]`, text field) — optionnel

**And** the following **Cercle 1** fields are present:
- **Cercle 1** radio Oui/Non (`t2_detail[isp_cercle1]`, boolean) — obligatoire, **default Oui** (checked)
- When Cercle 1 = Oui (Stimulus conditional reveal):
  - **Nature des ISP** (`t2_detail[isp_cercle1_natures][]`, checkbox-dropdown multi-select) — optionnel
  - **Montant au contrôle** (`t2_detail[isp_cercle1_montant]`, decimal input) — obligatoire si Cercle 1 présent
  - **Montant annuel de l'enveloppe SGG** (`t2_detail[isp_cercle1_enveloppe_sgg]`, decimal input) — obligatoire si Cercle 1 présent
  - **Consommation à date de l'enveloppe** (`t2_detail[isp_cercle1_consommation]`, decimal input) — optionnel
  - **Reste à consommer** (calculated read-only display: `enveloppe_sgg - consommation`) — updated in real-time via Stimulus

**And** the following **Cercle 2** fields are present:
- **Cercle 2** radio Oui/Non (`t2_detail[isp_cercle2]`, boolean) — obligatoire, **default Non**
- When Cercle 2 = Oui (Stimulus conditional reveal):
  - **Nature des ISP** (`t2_detail[isp_cercle2_natures][]`, checkbox-dropdown multi-select) — optionnel
  - **Montant au contrôle** (`t2_detail[isp_cercle2_montant]`, decimal input) — obligatoire si Cercle 2 présent
  - **Montant annuel de l'enveloppe SGG** (`t2_detail[isp_cercle2_enveloppe_sgg]`, decimal input) — obligatoire si Cercle 2 présent
  - **Consommation à date de l'enveloppe** (`t2_detail[isp_cercle2_consommation]`, decimal input) — optionnel
  - **Reste à consommer** (calculated read-only display: `enveloppe_sgg - consommation`) — updated in real-time via Stimulus

### AC3 — "Reste à consommer" real-time calculation

**Given** the Cercle fields are visible
**When** the instructor inputs or changes `enveloppe_sgg` or `consommation`
**Then** the "Reste à consommer" value is updated immediately (= `enveloppe_sgg - consommation`, displayed as `--€` when blank)
**And** the calculation runs independently for Cercle 1 and Cercle 2

### AC4 — Default values on page load

**Given** the ISP section is rendered for a new acte
**When** the page loads
**Then** Cercle 1 defaults to **Oui** — its sub-fields are visible
**And** Cercle 2 defaults to **Non** — its sub-fields are hidden

### AC5 — Data saved to t2_details

**Given** the form is submitted with ISP fields filled
**When** the controller processes params
**Then** `t2_detail` nested attributes for ISP fields are saved via `accepts_nested_attributes_for :t2_detail`:
  - `isp_cercle1` (boolean), `isp_cercle1_natures` (string[]), `isp_cercle1_montant` (decimal), `isp_cercle1_enveloppe_sgg` (decimal), `isp_cercle1_consommation` (decimal)
  - `isp_cercle2` (boolean), `isp_cercle2_natures` (string[]), `isp_cercle2_montant` (decimal), `isp_cercle2_enveloppe_sgg` (decimal), `isp_cercle2_consommation` (decimal)
  - `date_effet_acte` (string)
**And** the `t2_detail` record is created if it does not exist; updated if it does

### AC6 — No regression on HT2 and other T2 natures

**Given** an acte with `titre = 'HT2'`
**When** any form is accessed
**Then** the ISP section does not appear

**Given** the instructor selects a different T2 nature (e.g. Annexe financière, Marché)
**When** the nature dropdown changes
**Then** the ISP section is hidden and the appropriate other section shows

## Tasks / Subtasks

- [x] **Task 1: Extend `acte_params` to permit ISP t2_detail fields** (AC: 5)
  - [x] In `actes_controller.rb` `acte_params`, extend `t2_detail_attributes` to include: `:isp_cercle1`, `:isp_cercle2`, `:isp_cercle1_montant`, `:isp_cercle1_enveloppe_sgg`, `:isp_cercle1_consommation`, `:isp_cercle2_montant`, `:isp_cercle2_enveloppe_sgg`, `:isp_cercle2_consommation`, `isp_cercle1_natures: []`, `isp_cercle2_natures: []`

- [x] **Task 2: Implement `_isp.html.erb` partial** (AC: 1, 2, 3, 4)
  - [x] Replace the placeholder in `app/views/actes/t2_sections/_isp.html.erb`
  - [x] Add `date_effet_acte` text field (shared with `_annexe_financiere`, use `td.text_field`)
  - [x] Add Cercle 1 section: radio Oui/Non (default Oui), conditional reveal via `conditional-field` Stimulus controller
  - [x] Add Cercle 1 sub-fields: `isp_cercle1_natures` (checkbox-dropdown), `isp_cercle1_montant`, `isp_cercle1_enveloppe_sgg`, `isp_cercle1_consommation`, "Reste à consommer" display
  - [x] Add Cercle 2 section: radio Oui/Non (default Non), conditional reveal
  - [x] Add Cercle 2 sub-fields: `isp_cercle2_natures`, `isp_cercle2_montant`, `isp_cercle2_enveloppe_sgg`, `isp_cercle2_consommation`, "Reste à consommer" display
  - [x] Wire real-time "Reste à consommer" via Stimulus actions on `isp_cercleX_enveloppe_sgg` and `isp_cercleX_consommation` inputs

- [x] **Task 3: Add Stimulus `isp-calculator` actions to `acte_form_controller.js`** (AC: 3)
  - [x] Add `calculateIspReste(event)` method that reads `enveloppe_sgg` - `consommation` and updates display
  - [x] Wire to both Cercle 1 and Cercle 2 inputs via `data-action="input->acte-form#calculateIspReste"`
  - [x] Handle blank/nil values gracefully (display `--€`)

- [x] **Task 4: Write controller/integration tests** (AC: 5, 6)
  - [x] Test: `new T2 ISP renders isp section with cercle1 and cercle2 fields`
  - [x] Test: `create T2 ISP saves t2_detail isp fields` — persistance de tous les champs ISP
  - [x] Test: `new T2 ISP does not show deliberation_ca row (no regression)`
  - [x] Test: `HT2 create is unaffected (no ISP regression)` — already covered, add ISP-specific assertion

## Dev Notes

### Screenshot analysis — ISP form layout

From the screenshot provided by user (ISP nature selected):

**Row: Date d'effet de l'acte** — field at row level (outside Cercles), optionnel.

**Cercle 1 block:**
- Header: `Cercle 1` (bold)
- Radio: **Oui** (filled circle = checked, default) / Non
- Row: `Nature des ISP` (dropdown) | `Montant au contrôle*` (text input)
- Row: `Montant annuel de l'enveloppe SGG*` | `Consommation à date de l'enveloppe` | `Reste à consommer` (blue card showing `--€`)

**Cercle 2 block:**
- Header: `Cercle 2` (bold)
- Radio: Oui / **Non** (filled circle = checked, default)
- Sub-fields (hidden when Non)
- `Précisions sur l'acte` (textarea) — this is already in the parent `_form_informations_t2.html.erb`, not in the ISP partial

**Footer:**
- `Cet acte a été réalisé en période de services votés` (checkbox) — in parent partial, not in ISP partial

### `isp_cercle1` / `isp_cercle2` — radio with defaults

```erb
<%# Cercle 1 — default Oui %>
<fieldset class="fr-fieldset fr-mb-0" aria-labelledby="cercle1-legend" data-controller="conditional-field">
  <legend class="fr-fieldset__legend--regular fr-fieldset__legend" id="cercle1-legend">
    <strong>Cercle 1</strong>
  </legend>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <%= td.radio_button :isp_cercle1, true, id: "isp_cercle1_oui",
          checked: td.object.isp_cercle1 == true || td.object.isp_cercle1.nil?,
          data: { action: "change->conditional-field#toggle", conditional_field_target: "checkbox" } %>
      <label class="fr-label" for="isp_cercle1_oui">Oui</label>
    </div>
  </div>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <%= td.radio_button :isp_cercle1, false, id: "isp_cercle1_non",
          data: { action: "change->conditional-field#toggle", conditional_field_target: "checkbox" } %>
      <label class="fr-label" for="isp_cercle1_non">Non</label>
    </div>
  </div>
</fieldset>
```

Cercle 2 mirrors the pattern but with `isp_cercle2 == false || nil?` defaulting to **Non**:
```erb
checked: td.object.isp_cercle2 == true  <%# Oui only checked if explicitly true %>
checked: td.object.isp_cercle2 == false || td.object.isp_cercle2.nil?  <%# Non default %>
```

### conditional-field Stimulus pattern

The `conditional-field` controller is already registered (see `_form_informations_t2.html.erb` lines 158–207 and `_annexe_financiere.html.erb`). The wrapper div needs `data-controller="conditional-field"`. Sub-fields use `data-conditional-field-target="field"` with `fr-hidden` class when the radio defaults to Non.

```erb
<div class="fr-col-12 <%= 'fr-hidden' unless td.object.isp_cercle1 == true || td.object.isp_cercle1.nil? %>"
     data-conditional-field-target="field">
  <%# sub-fields %>
</div>
```

For Cercle 2 (default Non):
```erb
<div class="fr-col-12 <%= 'fr-hidden' unless td.object.isp_cercle2 == true %>"
     data-conditional-field-target="field">
```

### `isp_cercleX_natures` — checkbox-dropdown (same pattern as `grade`)

The `checkbox-dropdown` Stimulus controller is already registered (`app/javascript/controllers/checkbox_dropdown_controller.js`). The ISP nature options (from epic/screenshot) include options like "Indemnité de résidence", "NBI", "SFT", etc. — pending confirmation from user. Use a `hidden_field` that submits CSV; controller splits to array. The controller preprocessor in `acte_params` already handles `grade` as a CSV→array. **ISP natures arrays** will need similar preprocessing or submit as native checkbox array.

**Recommended approach:** use individual checkboxes with `name="acte[t2_detail_attributes][isp_cercle1_natures][]"` (native Rails array), avoiding the CSV approach (simpler, no preprocessor needed). The checkbox-dropdown controller works the same way — it just needs the `hidden` target value to be a comma-separated string that the controller reads back into checkbox states.

Actually, since the existing `grade` approach uses a hidden field + CSV preprocessing, stay consistent: use the same pattern for `isp_cercle1_natures` and `isp_cercle2_natures`. Add preprocessing in `acte_params` similar to the `grade` preprocessor:

```ruby
t2 = params.dig(:acte, :t2_detail_attributes)
if t2
  if t2[:grade].is_a?(String)
    t2[:grade] = t2[:grade].split(',').map(&:strip).reject(&:blank?)
  end
  if t2[:isp_cercle1_natures].is_a?(String)
    t2[:isp_cercle1_natures] = t2[:isp_cercle1_natures].split(',').map(&:strip).reject(&:blank?)
  end
  if t2[:isp_cercle2_natures].is_a?(String)
    t2[:isp_cercle2_natures] = t2[:isp_cercle2_natures].split(',').map(&:strip).reject(&:blank?)
  end
end
```

### ISP nature options for dropdown

From the screenshot: the dropdown label is "Nature des ISP" with a "Sélectionner une option" prompt. The exact options are not visible in the screenshot. Use a reasonable set based on context or ask the user. **Placeholder options until confirmed:**
```
ISOE, NBI, Indemnité de résidence, SFT, Indemnité de technicité
```
> Note: confirm with user if a specific enumerated list exists.

### "Reste à consommer" — Stimulus real-time calculation

Add a method to `acte_form_controller.js`:

```javascript
calculateIspReste(event) {
  const cercle = event.target.dataset.ispCercle  // "1" or "2"
  const enveloppeFld = document.getElementById(`isp_cercle${cercle}_enveloppe_sgg`)
  const consomFld    = document.getElementById(`isp_cercle${cercle}_consommation`)
  const resteEl      = document.getElementById(`isp_cercle${cercle}_reste`)

  if (!resteEl) return

  const env   = this.numberFormat(enveloppeFld?.value) || 0
  const conso = this.numberFormat(consomFld?.value) || 0

  if (!enveloppeFld?.value && !consomFld?.value) {
    resteEl.textContent = '--€'
  } else {
    const reste = env - conso
    resteEl.textContent = reste.toLocaleString('fr-FR') + ' €'
  }
}
```

Wire to inputs with:
```erb
data: { action: "input->acte-form#calculateIspReste", isp_cercle: "1" }
```

The `numberFormat` helper already exists in `acte_form_controller.js` (handles ` `, comma→dot conversion).

Display element:
```erb
<div id="t2-section-isp-cercle1-reste" class="fr-callout fr-callout--blue-ecume fr-py-1w">
  <p class="fr-callout__text fr-text--sm">
    Reste à consommer<br>
    <strong id="isp_cercle1_reste">--€</strong>
  </p>
</div>
```

On page load with existing values, re-calculate in `connect()` — or simply set the initial value server-side as ERB:

```erb
<%
  reste1 = td.object.isp_cercle1_enveloppe_sgg.present? ?
    (td.object.isp_cercle1_enveloppe_sgg.to_f - td.object.isp_cercle1_consommation.to_f) : nil
%>
<strong id="isp_cercle1_reste">
  <%= reste1 ? "#{reste1.to_f.to_s} €" : "--€" %>
</strong>
```

### `acte_params` — t2_detail_attributes extension

Current permit (line 1152):
```ruby
t2_detail_attributes: [:id, :type_acte_t2, :effectifs, :effectifs_complementaire, :corps, :date_arrete_concours, :date_effet_acte, :impact_schema_emplois, :impact_autre_cbcm, grade: []]
```

Must be extended to:
```ruby
t2_detail_attributes: [
  :id,
  # Annexe financière fields (existing)
  :type_acte_t2, :effectifs, :effectifs_complementaire, :corps, :date_arrete_concours,
  :date_effet_acte, :impact_schema_emplois, :impact_autre_cbcm,
  # ISP fields (new)
  :isp_cercle1, :isp_cercle1_montant, :isp_cercle1_enveloppe_sgg, :isp_cercle1_consommation,
  :isp_cercle2, :isp_cercle2_montant, :isp_cercle2_enveloppe_sgg, :isp_cercle2_consommation,
  grade: [],
  isp_cercle1_natures: [],
  isp_cercle2_natures: []
]
```

**No model or migration changes needed** — all ISP columns already exist in `t2_details` (see `db/migrate/20260512092104_create_t2_details.rb` lines 19–32 and `db/schema.rb`).

### Database columns confirmed (no migration needed)

From `db/migrate/20260512092104_create_t2_details.rb` and `db/schema.rb`:
- `t.boolean :isp_cercle1`
- `t.string  :isp_cercle1_natures, array: true, default: []`
- `t.decimal :isp_cercle1_montant`
- `t.decimal :isp_cercle1_enveloppe_sgg`
- `t.decimal :isp_cercle1_consommation`
- `t.boolean :isp_cercle2`
- `t.string  :isp_cercle2_natures, array: true, default: []`
- `t.decimal :isp_cercle2_montant`
- `t.decimal :isp_cercle2_enveloppe_sgg`
- `t.decimal :isp_cercle2_consommation`

**`db/schema.rb` does NOT need to be modified** — columns already exist.

### ISP is excluded for périmètre = Organisme

From Epic 2.2 AC and `actes_controller.rb` nature list filtering: ISP is only available when `perimetre = 'etat'`. The section will therefore never render for organisme périmètre — no conditional rendering needed inside the partial. The nature dropdown itself prevents selection.

### `id:` attribute conventions for ISP fields

Use descriptive IDs to avoid conflicts with other sections (Annexe financière also uses `date_effet_acte`):
- The `date_effet_acte` field is shared across multiple natures. Each partial uses `td.text_field :date_effet_acte` — since only one section is visible at a time (Stimulus), having a duplicate `id="date_effet_acte"` in hidden partials is technically acceptable. If needed, use `id: "isp_date_effet_acte"` for disambiguation.
- ISP-specific fields: `id: "isp_cercle1_montant"`, `id: "isp_cercle1_enveloppe_sgg"`, etc.

### Layout from screenshot

```
Row 1: [Date d'effet de l'acte (fr-col-lg-4)]

--- Cercle 1 ---
Row 2: [Cercle 1 header + radio Oui•/Non (fr-col-lg-4)] | [Nature des ISP dropdown (fr-col-lg-4)] | [Montant au contrôle* (fr-col-lg-4)]

Row 3: [Montant annuel enveloppe SGG* (fr-col-lg-4)] | [Conso à date enveloppe (fr-col-lg-4)] | [Reste à consommer card (fr-col-lg-4)]

--- Cercle 2 ---
Row 4: [Cercle 2 header + radio Oui/Non• (fr-col-lg-4)]
(sub-fields hidden when Non)
```

Use `fr-grid-row fr-grid-row--gutters` for each row. Cercle headers use `<strong>` or `<h3 class="fr-h6">`. The "Reste à consommer" is rendered as a callout card (blue background per screenshot) inside `fr-col-lg-4`.

### Pattern: `conditional-field` controller with fieldset trigger

The `conditional-field` Stimulus controller was introduced in Story 2.3 (see `_form_informations_t2.html.erb` lines 159–206). The controller must be on the **wrapper div**, not on the fieldset. The radio buttons must have `data-conditional-field-target="checkbox"` AND `data-action="change->conditional-field#toggle"`. Each sub-field container needs `data-conditional-field-target="field"`.

**Important**: the wrapper `data-controller="conditional-field"` must contain BOTH the trigger (radio fieldset) AND the target fields. This means the Cercle 1 block is a single `fr-grid-row` with `data-controller="conditional-field"` wrapping the radio + the sub-fields.

### Files to create

- `app/views/actes/t2_sections/_isp.html.erb` — replace placeholder with full ISP section

### Files to modify

- `app/controllers/actes_controller.rb` — extend `t2_detail_attributes` in `acte_params` to add ISP fields
- `app/javascript/controllers/acte_form_controller.js` — add `calculateIspReste` method
- `test/controllers/actes_controller_test.rb` — add ISP-specific tests

### Files NOT touched

- `db/schema.rb` — no migration needed (ISP columns already in `t2_details`)
- `db/migrate/20260512092104_create_t2_details.rb` — already has ISP columns
- `app/models/acte.rb` — `accepts_nested_attributes_for :t2_detail` already added in Story 2.3
- `app/models/t2_detail.rb` — no new validations needed for ISP fields
- `app/views/actes/_form_informations_t2.html.erb` — ISP section wrapper already in place (`#t2-section-isp`)
- All HT2 forms

### Existing patterns to reuse

| Pattern | Where |
|---------|-------|
| `conditional-field` Stimulus reveal | `_form_informations_t2.html.erb` lines 158–207 (deliberation_ca), `_annexe_financiere.html.erb` (no explicit use, but controller exists) |
| `checkbox-dropdown` for multi-select | `_annexe_financiere.html.erb` lines 34–65 (grade field) |
| Radio Oui/Non fieldset | `_annexe_financiere.html.erb` lines 75–94 (impact_autre_cbcm), lines 97–116 (impact_schema_emplois) |
| `numberFormat` helper | `acte_form_controller.js` line 76 |
| CSV→array preprocessor in `acte_params` | `actes_controller.rb` lines 1132–1135 (grade) |
| `fr-callout` card | Used in `_form_informations_t2.html.erb` line 3–11 |
| `accepts_nested_attributes_for :t2_detail` | `app/models/acte.rb` — already in place |
| `fields_for :t2_detail` | `_form_informations_t2.html.erb` line 110 — already wraps all section partials |
| `td.object.field.nil?` default pattern | `_annexe_financiere.html.erb` lines 88–89 |

### Project Structure Notes

- Views: `app/views/actes/t2_sections/` — one partial per nature
- ISP section partial receives `f:, td:, acte:` locals (already wired in `_form_informations_t2.html.erb` line 133)
- Stimulus: `acte_form_controller.js` is the single controller for the T2 form
- DSFR: `fr-fieldset`, `fr-radio-group`, `fr-input-group`, `fr-select-group`, `fr-grid-row fr-grid-row--gutters`, `fr-col-12 fr-col-lg-4`, `fr-callout fr-callout--blue-ecume`

### References

- Epic spec — Story 2.4: [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 323–347
- Previous story (2.3, done): [_bmad-output/implementation-artifacts/2-3-section-specifique-nature-annexe-financiere.md](_bmad-output/implementation-artifacts/2-3-section-specifique-nature-annexe-financiere.md)
- ISP placeholder (current): [app/views/actes/t2_sections/_isp.html.erb](app/views/actes/t2_sections/_isp.html.erb)
- Annexe financière partial (model implementation): [app/views/actes/t2_sections/_annexe_financiere.html.erb](app/views/actes/t2_sections/_annexe_financiere.html.erb)
- T2 form partial (section wiring): [app/views/actes/_form_informations_t2.html.erb](app/views/actes/_form_informations_t2.html.erb) lines 130–134
- Controller `acte_params` (extend): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb#L1152)
- T2Detail model: [app/models/t2_detail.rb](app/models/t2_detail.rb)
- Migration (ISP columns confirmed): [db/migrate/20260512092104_create_t2_details.rb](db/migrate/20260512092104_create_t2_details.rb) lines 19–32
- Stimulus controller (calculateIspReste): [app/javascript/controllers/acte_form_controller.js](app/javascript/controllers/acte_form_controller.js)
- checkbox-dropdown controller: [app/javascript/controllers/checkbox_dropdown_controller.js](app/javascript/controllers/checkbox_dropdown_controller.js)
- Existing tests: [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `acte_params` étendu : `t2_detail_attributes` inclut désormais `:isp_cercle1`, `:isp_cercle2`, `:isp_cercle1_montant`, `:isp_cercle1_enveloppe_sgg`, `:isp_cercle1_consommation`, `:isp_cercle2_montant`, `:isp_cercle2_enveloppe_sgg`, `:isp_cercle2_consommation`, `isp_cercle1_natures: []`, `isp_cercle2_natures: []`.
- Préprocesseur CSV→array ajouté pour `isp_cercle1_natures` et `isp_cercle2_natures` (même pattern que `grade`).
- `_isp.html.erb` implémenté : Cercle 1 (default Oui, sous-champs visibles) + Cercle 2 (default Non, sous-champs cachés), `conditional-field` Stimulus pour le reveal, `checkbox-dropdown` pour les natures ISP (options : ISOE, NBI, SFT, Indemnité de résidence, Indemnité de technicité), "Reste à consommer" calculé server-side au rendu initial et mis à jour en temps réel via `calculateIspReste`.
- `calculateIspReste(event)` ajouté à `acte_form_controller.js` : lit `dataset.ispCercle` ("1" ou "2") pour identifier le cercle, calcule `enveloppe_sgg - consommation`, affiche `--€` si les deux champs sont vides.
- 3 nouveaux tests dans `actes_controller_test.rb` : rendu des champs ISP, persistance complète des données (isp_cercle1/2, natures CSV→array, montants décimaux), non-régression deliberation_ca pour ISP.
- Suite complète : **54 runs / 228 assertions / 0 failures / 0 errors**.
- Note : les options de la liste "Nature des ISP" sont des placeholders (ISOE, NBI, SFT, Indemnité de résidence, Indemnité de technicité) — à confirmer avec les utilisateurs métier.

### File List

- `app/controllers/actes_controller.rb`
- `app/views/actes/t2_sections/_isp.html.erb`
- `app/javascript/controllers/acte_form_controller.js`
- `test/controllers/actes_controller_test.rb`
