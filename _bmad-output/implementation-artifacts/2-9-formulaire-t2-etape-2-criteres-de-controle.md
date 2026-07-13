# Story 2.9: T2 Form Step 2 — Control Criteria

Status: done

## Story

As an instructor,
I want to fill in the control criteria for a T2 acte at step 2,
so that I can document my analysis before proposing a decision.

## Acceptance Criteria

### AC1 — Step 2 renders the T2 criteria partial

**Given** I have completed step 1 of a T2 acte
**When** I navigate to `edit_acte_path(@acte, etape: 2)`
**Then** the new partial `_form_criteres_t2.html.erb` is rendered (instead of `_form_criteres` or `_form_criteres_organisme`)

### AC2 — Criteria displayed conditionally per nature and périmètre

**Given** the T2 step-2 form is displayed
**When** it renders for a given `acte.nature` and `acte.perimetre`
**Then** only the applicable criteria are shown, per the table below:

| Criterion label | Field | Stored in | Display condition |
|---|---|---|---|
| Inscription au PAP / Plan de recrutement *(nature = Annexe financière)* / Inscription au PAP *(autres natures)* | `inscription_pap` | `t2_details` | périmètre = État **AND** nature ∈ {Annexe financière, Mesure transversale, Référentiel} |
| Respect du plafond d'emplois | `respect_plafond_emplois` | `t2_details` | nature = Annexe financière |
| Respect du schéma d'emplois | `respect_schema_emplois` | `t2_details` | nature = Annexe financière **AND** `acte.t2_detail.impact_schema_emplois == true` |
| Contrôle des modalités de mise en œuvre | `controle_modalites` | `t2_details` | nature = Fongibilité asymétrique **AND** périmètre = État **AND** `current_user.statut == 'DCB'` |
| Exactitude de l'évaluation budgétaire | `consommation_credits` | `actes` | nature ∈ {Fongibilité asymétrique, Marché, Mesure transversale} |
| Respect de l'enveloppe notifiée | `respect_enveloppe` | `t2_details` | nature = ISP |
| Risque d'effet reconventionnel | `risque_reconventionnel` | `t2_details` | nature ∈ {Mesure transversale, Référentiel} |
| L'acte figure dans le dernier document de programmation *(périmètre État)* / L'acte figure dans le dernier budget *(périmètre Organisme)* | `programmation_prevue` | `actes` | nature ∉ {ISP} **AND** NOT (nature = Fongibilité asymétrique AND périmètre = Organisme) |
| Opération autorisée par les autorités de tutelle | `autorisation_tutelle` | `actes` | nature ∉ {ISP, Fongibilité asymétrique} **AND** périmètre = Organisme **AND** `acte.budget_executoire == false` |
| Programmation initiale transmise | `avis_programmation` | `actes` | nature ≠ ISP **AND** périmètre = État **AND** `services_votes == true` |
| Compatibilité avec la programmation annuelle et pluriannuelle | `programmation` | `actes` | nature ∉ {ISP} **AND** NOT (nature = FA AND périmètre = Organisme) **AND** `services_votes == false` **AND** (périmètre = État → `avis_programmation != false` ; périmètre = Organisme → `budget_executoire == true`) — bloc togglable via Stimulus `programmationBlock` target |
| Soutenabilité/Disponibilité des crédits | `soutenabilite` | `actes` | nature ≠ Annexe financière |
| Acte éligible à la gestion des services votés | `programmation` | `actes` | `services_votes == true` |

### AC3 — T2 criteria rendered as radio buttons (Oui/Non), checkboxes for top 2

**Given** a T2 criterion is applicable
**When** the form is rendered
**Then**:
- `avis_programmation` (Programmation initiale transmise) and `programmation_prevue` are rendered as `fr-checkbox-group` checkboxes at the top of the form
- All other criteria are rendered as `fr-fieldset` radio buttons (Oui/Non) using the DSFR `fr-radio-group` pattern, with `checked:` defaulting to Oui when nil

**And** `t2_detail` criteria use the `td.` form builder (via `fields_for :t2_detail_attributes`)
**And** `actes`-stored criteria use the `f.` form builder directly

> Note: `consommation_credits` is in `actes` (HT2 reuse), **not** in `t2_details` — do not create a duplicate column.

### AC3b — `avis_programmation` hides/shows the programmation block via Stimulus

**Given** `avis_programmation` is displayed (nature ≠ ISP AND périmètre = État AND services_votes = true)
**When** the checkbox is unchecked
**Then** the "Compatibilité avec la programmation annuelle et pluriannuelle" block is hidden (via `toggleAvisProgrammation` in `acte_form_controller.js`)
**When** the checkbox is checked again
**Then** the block is shown again

**Implementation**: `avis_programmation` checkbox has `data: { action: "change->acte-form#toggleAvisProgrammation" }` and the `programmation` block div has `data-acte-form-target="programmationBlock"` with initial `fr-hidden` class unless `services_votes == true || avis_programmation == true`.

### AC4 — Tableur and Observations available

**Given** the step-2 form is displayed
**Then** the spreadsheet widget (`sheet_data`) is present
**And** the rich-text `commentaire_disponibilite_credits` observations field is present (identical to HT2 step 2)

### AC5 — `etape2_complete?` updated for T2

**Given** an acte with `titre == 'T2'`
**When** `etape2_complete?(acte)` is called
**Then** it returns `true` (T2 step 2 has no mandatory criteria — all checkboxes are optional booleans with nil defaults meaning "not evaluated yet")

> The HT2 logic (`disponibilite_credits.nil?`) does not apply to T2. T2 step 2 is always navigable. The simplest approach: return `true` for T2 actes.

### AC6 — `edit.html.erb` renders T2 step-2 partial

**Given** `@acte.titre == 'T2'`
**When** `@etape == 2`
**Then** `_form_criteres_t2` is rendered instead of `_form_criteres` or `_form_criteres_organisme`

### AC7 — `acte_params` permits T2 criteria fields

**Given** the T2 step-2 form is submitted
**When** the controller processes the params
**Then** the following are permitted in `t2_detail_attributes`:
- `:inscription_pap, :respect_plafond_emplois, :respect_schema_emplois, :controle_modalites, :respect_enveloppe, :risque_reconventionnel`

**And** these are already permitted for `actes` (no change needed): `:consommation_credits, :programmation_prevue, :autorisation_tutelle, :avis_programmation, :programmation, :soutenabilite`

### AC8 — `T2_DETAIL_FIELDS_BY_NATURE` preserves criteria fields

**Given** `clear_irrelevant_t2_detail_fields` runs on save
**Then** the 6 T2 criteria fields (`inscription_pap`, `respect_plafond_emplois`, `respect_schema_emplois`, `controle_modalites`, `respect_enveloppe`, `risque_reconventionnel`) are **preserved** for all natures

> These are step-2 criteria fields, not nature-specific step-1 fields. The cleanest approach: add all 6 to a constant `T2_CRITERIA_FIELDS` that is excluded from `ALL_T2_DETAIL_NATURE_FIELDS`, or add all 6 to every nature's allowed list in `T2_DETAIL_FIELDS_BY_NATURE`. **Preferred**: create a separate constant and exclude them from `fields_to_nil` in `clear_irrelevant_t2_detail_fields`.

### AC9 — No regression on HT2

**Given** an acte with `titre == 'HT2'`
**When** accessing step 2
**Then** `_form_criteres` or `_form_criteres_organisme` is rendered (unchanged)
**And** `etape2_complete?` logic for HT2 is unchanged

## Tasks / Subtasks

- [x] **Task 1: Create `_form_criteres_t2.html.erb` partial** (AC: 1, 2, 3, 3b, 4)
  - [x] Create `app/views/actes/_form_criteres_t2.html.erb`
  - [x] Use `form_with(model: @acte)` with `hidden_field_tag :etape, 3` (same as HT2 step-2 partials)
  - [x] Wrap form in `data-controller="acte-form"` div
  - [x] For each criterion in AC2 table, conditionally render based on `@acte.nature`, `@acte.perimetre`, and `current_user.statut`
  - [x] `avis_programmation` and `programmation_prevue`: rendered as `fr-checkbox-group` at the top
  - [x] `avis_programmation`: has `data: { action: "change->acte-form#toggleAvisProgrammation" }` to toggle the programmation block
  - [x] All other criteria: rendered as `fr-fieldset` Oui/Non radio buttons (`fr-radio-group` pattern)
  - [x] `t2_detail` criteria: use `fields_for(:t2_detail_attributes, @acte.t2_detail)` block with `td.radio_button`
  - [x] `actes` criteria: use `f.radio_button` directly
  - [x] Programmation block: `data-acte-form-target="programmationBlock"`, initially hidden unless `services_votes == true || avis_programmation == true`
  - [x] Tooltip `controle_modalites_info` on "Contrôle des modalités de mise en œuvre"
  - [x] Tooltip `programmation_t2_fa_info` (FA) / `programmation_t2_info` (autres) on "Compatibilité avec la programmation annuelle et pluriannuelle"
  - [x] Include tableur widget
  - [x] Include Observations rich-text field
  - [x] Include submit button "Enregistrer et continuer"

- [x] **Task 2: Update `edit.html.erb` to render T2 step-2 partial** (AC: 6)
  - [x] In `app/views/actes/edit.html.erb` `when 2` block, added T2 branch before organisme/état check

- [x] **Task 3: Update `etape2_complete?` for T2** (AC: 5, 9)
  - [x] Added `return true if acte.titre == 'T2'` at top of `etape2_complete?` in `actes_helper.rb`

- [x] **Task 4: Add T2 criteria fields to `acte_params`** (AC: 7)
  - [x] Added `:inscription_pap, :respect_plafond_emplois, :respect_schema_emplois, :controle_modalites, :respect_enveloppe, :risque_reconventionnel` to `t2_detail_attributes`

- [x] **Task 5: Preserve T2 criteria fields in `clear_irrelevant_t2_detail_fields`** (AC: 8)
  - [x] Added `T2_CRITERIA_FIELDS` constant
  - [x] `clear_irrelevant_t2_detail_fields` now subtracts `T2_CRITERIA_FIELDS` from `fields_to_nil`

- [x] **Task 6: Write controller/integration tests** (AC: 1–9)
  - [x] `edit T2 Annexe financière état step 2 renders inscription_pap, respect_plafond, respect_schema`
  - [x] `edit T2 Annexe financière état step 2 does not render respect_schema when impact_schema_emplois false`
  - [x] `edit T2 Fongibilité asymétrique état DCB step 2 renders controle_modalites`
  - [x] `edit T2 ISP step 2 renders respect_enveloppe and no programmation_prevue`
  - [x] `edit T2 Mesure transversale état step 2 renders risque_reconventionnel and inscription_pap`
  - [x] `edit T2 Marché organisme step 2 does not render autorisation_tutelle when budget_executoire true`
  - [x] `edit T2 Marché organisme step 2 renders autorisation_tutelle when budget_executoire false`
  - [x] `update T2 Annexe financière saves inscription_pap and respect_plafond_emplois in t2_details`
  - [x] `update T2 Fongibilité asymétrique saves consommation_credits in actes`
  - [x] `clear_irrelevant_t2_detail_fields does not nil T2 criteria fields on nature change`
  - [x] `HT2 step 2 still uses form_criteres (regression check)`
  - [x] `etape2_complete? returns true for T2 acte — step 3 link enabled in sidemenu`

## Dev Notes

### Key architectural decisions

#### T2 criteria vs. HT2 criteria — mixed format

`avis_programmation` (Programmation initiale transmise) and `programmation_prevue` are checkboxes at the top. All other criteria use Oui/Non radio buttons (same DSFR `fr-fieldset` / `fr-radio-group` pattern as HT2), with `checked:` logic defaulting to Oui when `nil`.

> `avis_programmation` condition was refined: nature ≠ ISP AND périmètre = État AND **services_votes == true** (services votés context only — the "Programmation initiale transmise" checkbox is shown to indicate whether the programmation document was transmitted, which is only relevant in the SV path).

#### `_form_criteres_t2.html.erb` — use `fields_for` for t2_detail criteria

The parent form is `form_with(model: @acte)`. For `t2_detail` criteria fields, use nested `fields_for`:

```erb
<%= form_with(model: @acte) do |f| %>
  <%= hidden_field_tag :etape, 3 %>
  <%= f.fields_for :t2_detail_attributes, @acte.t2_detail do |td| %>
    <%# Use td.check_box for t2_detail criteria %>
  <% end %>
  <%# Use f.check_box for actes criteria %>
<% end %>
```

This matches the exact pattern used in `_form_informations_t2.html.erb` (step 1).

#### `T2_CRITERIA_FIELDS` constant — must be excluded from `clear_irrelevant_t2_detail_fields`

The 6 criteria fields are **not nature-dependent** — they apply based on context (périmètre + nature + user statut + step-1 values). The `clear_irrelevant_t2_detail_fields` method runs on every save and would nil them out on step-1 saves if they're in `ALL_T2_DETAIL_NATURE_FIELDS`.

**Solution**: declare `T2_CRITERIA_FIELDS` separately and subtract it from `fields_to_nil` in `clear_irrelevant_t2_detail_fields`. Do **not** add them to `T2_DETAIL_FIELDS_BY_NATURE` (that would couple step-1 and step-2 logic).

```ruby
T2_CRITERIA_FIELDS = %i[
  inscription_pap respect_plafond_emplois respect_schema_emplois
  controle_modalites respect_enveloppe risque_reconventionnel
].freeze

def clear_irrelevant_t2_detail_fields(acte)
  return true unless acte.titre == 'T2' && acte.t2_detail.present?

  allowed = T2_DETAIL_FIELDS_BY_NATURE.fetch(acte.nature, [])
  fields_to_nil = ALL_T2_DETAIL_NATURE_FIELDS - allowed - T2_CRITERIA_FIELDS
  # ...
end
```

#### Label variants — `programmation_prevue` and `inscription_pap`

Two criteria have label variants depending on context:

**`programmation_prevue`**:
- périmètre = État → "L'acte figure dans le dernier document de programmation"
- périmètre = Organisme → "L'acte figure dans le dernier budget"

```erb
<% label = @acte.perimetre == 'organisme' ? "L'acte figure dans le dernier budget." : "L'acte figure dans le dernier document de programmation." %>
<%= f.check_box :programmation_prevue, id: "t2_programmation_prevue" %>
<label class="fr-label" for="t2_programmation_prevue"><%= label %></label>
```

**`inscription_pap`**:
- nature = Annexe financière → "Inscription au PAP / Plan de recrutement"
- autres natures éligibles (Mesure transversale, Référentiel) → "Inscription au PAP"

```erb
<% label = @acte.nature == 'Annexe financière' ? "Inscription au PAP / Plan de recrutement" : "Inscription au PAP" %>
<%= td.check_box :inscription_pap, id: "t2_inscription_pap" %>
<label class="fr-label" for="t2_inscription_pap"><%= label %></label>
```

#### `avis_cbcm` field — NOT a step-2 criterion for T2

`avis_cbcm` is stored in `t2_details` (it's a step-1 field for FA Organisme CBR, Story 2.5). It is **not** in the step-2 criteria table. Do not render it in `_form_criteres_t2.html.erb`.

#### `programmation` (actes) — two labels, Stimulus-toggled visibility

`programmation` appears as "Acte éligible à la gestion des services votés" when `services_votes == true` (always visible, rendered outside the `programmationBlock`). In the non-SV path, it appears as "Compatibilité avec la programmation annuelle et pluriannuelle" inside a `data-acte-form-target="programmationBlock"` div that mirrors `_form_criteres.html.erb` — hidden when `avis_programmation` is unchecked, shown when checked.

The block's initial server-rendered visibility: `fr-hidden unless @acte.services_votes == true || @acte.avis_programmation != false`.

Tooltip is context-dependent:
- nature = Fongibilité asymétrique → `programmation_t2_fa_info`: "La FA doit notamment être compatible avec la prévision d'atterrissage de fin de gestion."
- autres natures → `programmation_t2_info`: "En fonction du dernier document de programmation disponible (DPGECP/CRG)."

#### `respect_schema_emplois` — depends on step-1 value

Condition: nature = Annexe financière **AND** `@acte.t2_detail.impact_schema_emplois == true`. This is a server-side rendered condition — no Stimulus required. Just wrap in `<% if @acte.t2_detail&.impact_schema_emplois == true %>`.

#### Radio buttons pattern — all criteria except top 2 checkboxes

All criteria except `avis_programmation` and `programmation_prevue` use Oui/Non radio buttons. ID naming uses `_true`/`_false` suffixes (e.g. `t2_inscription_pap_true`, `t2_inscription_pap_false`). The `checked:` attribute defaults to Oui when the field is `nil`:

```erb
<%= td.radio_button :inscription_pap, true, id: "t2_inscription_pap_true",
    checked: @acte.t2_detail&.inscription_pap.nil? || @acte.t2_detail&.inscription_pap == true %>
```

#### Tooltip on "Contrôle des modalités de mise en œuvre"

Uses `controle_modalites_info` in `_tooltip.html.erb`: "Vérifier la compatibilité avec les instructions données par la DB (exemple : période au cours de la gestion, positionnement en centrale/déconcentré, répartition des crédits CAS/HCAS)."

### Field storage reference table

| Field | Model | Column | Type | Step-2 condition |
|---|---|---|---|---|
| `inscription_pap` | `t2_detail` | `inscription_pap` | `boolean` | périmètre=État, nature ∈ {AF, MT, Ref} |
| `respect_plafond_emplois` | `t2_detail` | `respect_plafond_emplois` | `boolean` | nature = AF |
| `respect_schema_emplois` | `t2_detail` | `respect_schema_emplois` | `boolean` | nature = AF AND impact_schema_emplois=true |
| `controle_modalites` | `t2_detail` | `controle_modalites` | `boolean` | nature = FA, périmètre=État, statut=DCB |
| `respect_enveloppe` | `t2_detail` | `respect_enveloppe` | `boolean` | nature = ISP |
| `risque_reconventionnel` | `t2_detail` | `risque_reconventionnel` | `boolean` | nature ∈ {MT, Ref} |
| `consommation_credits` *(label: "Exactitude de l'évaluation budgétaire")* | `acte` | `consommation_credits` | `boolean` | nature ∈ {FA, Marché, MT} |
| `programmation_prevue` | `acte` | `programmation_prevue` | `boolean` | nature ∉ {ISP}, NOT (FA AND organisme) |
| `autorisation_tutelle` | `acte` | `autorisation_tutelle` | `boolean` | nature ∉ {ISP, FA}, organisme, budget_executoire=false |
| `avis_programmation` | `acte` | `avis_programmation` | `boolean` | nature ≠ ISP, périmètre=État |
| `programmation` | `acte` | `programmation` | `boolean` | complex condition (see above) |
| `soutenabilite` | `acte` | `soutenabilite` | `boolean` | nature ≠ AF |

All `t2_detail` columns already exist in `db/schema.rb` lines 507–539 — **no migration needed**.

### Files to touch

- `app/views/actes/_form_criteres_t2.html.erb` — **new file**
- `app/views/actes/edit.html.erb` — add T2 branch in `when 2` (line ~109)
- `app/helpers/actes_helper.rb` — update `etape2_complete?` (line ~177)
- `app/controllers/actes_controller.rb` — add `T2_CRITERIA_FIELDS` constant, update `clear_irrelevant_t2_detail_fields`, extend `acte_params` `t2_detail_attributes`
- `test/controllers/actes_controller_test.rb` — add 12 tests

### DSFR patterns to follow

- Checkbox: `fr-checkbox-group` with `fr-mb-2w` (copy from `_form_criteres.html.erb` lines 8–12)
- Radio (if used): `fr-fieldset` / `fr-fieldset__element--inline` / `fr-radio-group` (copy from `_form_criteres.html.erb` lines 26–42)
- Grid layout: `fr-grid-row fr-grid-row--gutters` / `fr-col-12 fr-col-lg-12` or `fr-col-12 fr-col-lg-6`
- Section title: `<h2>Contrôle des critères</h2>` (identical to HT2 step 2)

### Tests — fixture setup

```ruby
# Create T2 acte for step-2 tests
acte = current_user.actes.create!(
  titre: 'T2', perimetre: 'etat', nature: 'Annexe financière',
  etat: "en cours d'instruction", instructeur: 'AB',
  annee: Date.today.year, categorie_t2: 'hors_contrat'
)
acte.create_t2_detail!(impact_schema_emplois: true)

# GET edit step 2
get edit_acte_path(acte, etape: 2)
assert_response :success
assert_select "#t2-form-criteres"  # or whatever id/structure you add
```

Use `users(:three)` (statut: DCB) for État tests. Use `users(:two)` (statut: CBR) to test CBR exclusions (e.g., `controle_modalites` should NOT appear for CBR).

For update tests, PATCH `acte_path(acte)` with `etape: 2` and assert `acte.t2_detail.reload.inscription_pap == true`.

### `etape2_complete?` — T2 always returns true

T2 step 2 has no mandatory fields. All criteria are optional booleans. Returning `true` for T2 allows navigation to step 3 as soon as step 1 is done, which is the correct UX. The sidemenu in `edit.html.erb` (lines 79–95) uses `etape2_complete?` to show/hide the step-3 link — T2 should always show it.

### Previous story patterns (Story 2.8)

- `fields_for :t2_detail_attributes, @acte.t2_detail do |td|` — standard nested form builder
- `td.check_box :field_name` — checkbox for boolean t2_detail field
- DSFR checkbox: wrap in `<div class="fr-checkbox-group fr-mb-2w">` with matching `<label class="fr-label" for="...">` 
- ID naming: use descriptive IDs like `"t2_inscription_pap"` to avoid collision with potential HT2 fields

### References

- Epic spec — Story 2.9: [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 459–493
- Previous story (2.8, done): [_bmad-output/implementation-artifacts/2-8-sections-specifiques-natures-enveloppe-limitative-et-referentiel.md](_bmad-output/implementation-artifacts/2-8-sections-specifiques-natures-enveloppe-limitative-et-referentiel.md)
- HT2 état step-2 partial: [app/views/actes/_form_criteres.html.erb](app/views/actes/_form_criteres.html.erb)
- HT2 organisme step-2 partial: [app/views/actes/_form_criteres_organisme.html.erb](app/views/actes/_form_criteres_organisme.html.erb)
- Edit view step routing (line 109): [app/views/actes/edit.html.erb](app/views/actes/edit.html.erb:109)
- `etape2_complete?` helper (line 177): [app/helpers/actes_helper.rb](app/helpers/actes_helper.rb:177)
- `T2_DETAIL_FIELDS_BY_NATURE` (line 1126): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb:1126)
- `clear_irrelevant_t2_detail_fields` (line 1145): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb:1145)
- `acte_params` t2_detail_attributes (line 1192): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb:1192)
- DB schema — t2_details columns (lines 503–545): [db/schema.rb](db/schema.rb:503)
- Existing tests (pattern to replicate): [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb:953)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Partial `_form_criteres_t2.html.erb` créé : critères affichés conditionnellement via ERB (nature, périmètre, statut user, valeurs étape 1). `avis_programmation` et `programmation_prevue` en checkboxes en haut ; tous les autres critères en radio Oui/Non (`fr-fieldset` / `fr-radio-group`). `fields_for :t2_detail_attributes` pour les 6 champs t2_detail, `f.radio_button` pour les champs actes. Labels contextuels : `programmation_prevue` (État vs Organisme), `inscription_pap` (AF vs autres), soutenabilité renommée "Soutenabilité/Disponibilité des crédits". Tableur et observations identiques à HT2.
- `avis_programmation` câblé avec `change->acte-form#toggleAvisProgrammation` — unchecking masque le bloc "Compatibilité avec la programmation annuelle et pluriannuelle" (même comportement que `_form_criteres.html.erb`). Bloc `programmationBlock` initialement masqué si `services_votes != true && avis_programmation == false`.
- Tooltips ajoutés : `controle_modalites_info` sur "Contrôle des modalités de mise en œuvre" ; `programmation_t2_fa_info` / `programmation_t2_info` (conditionnel selon nature) sur "Compatibilité avec la programmation annuelle et pluriannuelle".
- `app/views/actes/_tooltip.html.erb` mis à jour : 3 nouvelles entrées (`controle_modalites_info`, `programmation_t2_fa_info`, `programmation_t2_info`).
- `edit.html.erb` mis à jour : branche T2 ajoutée en premier dans le `when 2` pour rendre `_form_criteres_t2` avant les vérifications organisme/état.
- `etape2_complete?` : retour `true` immédiat pour T2 — step 3 toujours accessible dans le sidemenu dès la fin de l'étape 1.
- `T2_CRITERIA_FIELDS` constant ajoutée dans `actes_controller.rb` — les 6 champs de critères exclus de `clear_irrelevant_t2_detail_fields` pour ne pas être effacés lors des saves étape 1 (changement de nature).
- `acte_params` étendu avec les 6 champs t2_detail de critères.
- 12 tests ajoutés. Suite complète post-implémentation : **69 runs / 726 assertions / 0 failures / 0 errors**.

### File List

- `app/views/actes/_form_criteres_t2.html.erb` (new)
- `app/views/actes/_tooltip.html.erb`
- `app/views/actes/edit.html.erb`
- `app/helpers/actes_helper.rb`
- `app/controllers/actes_controller.rb`
- `test/controllers/actes_controller_test.rb`
