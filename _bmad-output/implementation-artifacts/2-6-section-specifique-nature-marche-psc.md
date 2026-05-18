# Story 2.6: Nature-Specific Section — "Marché (PSC)"

Status: done

## Story

As an instructor,
I want to fill in the specific fields of a T2 acte with nature "Marché",
so that I can document the market submitted for visa control.

## Acceptance Criteria

### AC1 — Marché section appears when nature is selected

**Given** the instructor selects "Marché" from the nature dropdown in the T2 step-1 form
**When** the `toggleNatureT2` Stimulus method fires
**Then** the `#t2-section-marche` div becomes visible (removes `fr-hidden`)
**And** all other nature sections remain hidden
**And** `#t2-deliberation-ca-row` remains hidden (the shared `deliberation_ca` row in the parent is being retired — each nature partial now owns its own `deliberation_ca` block; see architectural note below)

### AC2 — État périmètre: Montant au contrôle (required) + Bénéficiaire

**Given** the section is visible **AND** `acte.perimetre == 'etat'`
**When** it renders
**Then** the following fields are present:
- **Montant au contrôle** (`acte[montant_ae]`, decimal, `step: 0.01`) — **obligatoire** (required: true, asterisk in label)
- **Bénéficiaire** (`acte[beneficiaire]`, text input) — optionnel

**Given** `acte.perimetre == 'organisme'`
**Then** Montant au contrôle is NOT required (no asterisk) per the organisme screenshot

### AC3 — Organisme périmètre: specific fields

**Given** the section is visible **AND** `acte.perimetre == 'organisme'`
**When** it renders
**Then** the following fields are present:
- **Montant au contrôle** (`acte[montant_ae]`, decimal, `step: 0.01`) — optionnel (no asterisk)
- **Bénéficiaire** (`acte[beneficiaire]`, text input) — optionnel
- **Budget exécutoire** (`acte[budget_executoire]`, radio Oui/Non) — **obligatoire**, default Oui
- **Opération budgétaire** (`acte[operation_budgetaire]`, dropdown: Globalisée / Fléchée, prompt "Sélectionner une option") — optionnel
- **Délibération en CA nécessaire** (`acte[deliberation_ca]`, radio Oui/Non) — default Non

**Given** `acte.perimetre == 'etat'`
**Then** Budget exécutoire, Opération budgétaire and Délibération en CA are NOT displayed

### AC4 — Data saved to actes table

**Given** the form is submitted with Marché fields filled
**When** the controller processes params
**Then** the following are saved in `actes`:
- `acte.montant_ae` (float) — all périmètres
- `acte.beneficiaire` (string) — all périmètres
- `acte.budget_executoire` (boolean, organisme only — default true)
- `acte.operation_budgetaire` (string, organisme only)
- `acte.deliberation_ca` (boolean, organisme only — default false)
**And** `t2_detail` fields are NOT used for this nature (all saved in `actes`)
**And** `clear_irrelevant_t2_detail_fields` nullifies all t2_detail fields for nature Marché (empty list → all cleared)

### AC5 — No regression on other natures / HT2

**Given** an acte with `titre = 'HT2'`
**Then** the Marché section does not appear

**Given** a different T2 nature is selected (e.g. ISP, Fongibilité asymétrique)
**Then** the Marché section is hidden and the appropriate other section shows

## Tasks / Subtasks

- [x] **Task 1: Implement `_marche.html.erb` partial** (AC: 1, 2, 3)
  - [x] Replace placeholder in `app/views/actes/t2_sections/_marche.html.erb`
  - [x] Row 1 (état): Montant au contrôle (required) + Bénéficiaire
  - [x] Row 1 (organisme): Montant au contrôle (optional) + Bénéficiaire
  - [x] Row 2 (organisme only): Budget exécutoire radio Oui/Non (default Oui) + Opération budgétaire dropdown (Globalisée / Fléchée)
  - [x] Row 3 (organisme only): Délibération en CA radio Oui/Non (default Non) — simple radio, no sub-fields
  - [x] Use `acte.perimetre == 'organisme'` ERB conditionals
  - [x] Note: `Précisions sur l'acte` and `services_votes` checkbox are in parent partial — do NOT add them here

- [x] **Task 2: Migrate `deliberation_ca` block out of parent form** (architectural refactor)
  - [x] Move the full `deliberation_ca` block (lines 142–193 of `_form_informations_t2.html.erb`) into `_annexe_financiere.html.erb`, scoped to `acte.perimetre == 'organisme'` (preserving `conditional-field` controller for sub-fields)
  - [x] Remove `#t2-deliberation-ca-row` div entirely from `_form_informations_t2.html.erb`
  - [x] Remove the `deliberationRow` toggle logic from `acte_form_controller.js` (lines 892–898)

- [x] **Task 3: Verify `T2_DETAIL_FIELDS_BY_NATURE` for Marché** (AC: 4)
  - [x] In `actes_controller.rb`, confirm `'Marché' => []` is already correct (line 1138) — no t2_detail fields for this nature
  - [x] No change needed if already empty array

- [x] **Task 4: Write controller/integration tests** (AC: 2, 3, 4, 5)
  - [x] Test: `new T2 Marché état renders montant_ae required and beneficiaire` — assert montant_ae input required, beneficiaire input present, budget_executoire absent
  - [x] Test: `new T2 Marché organisme renders budget_executoire, operation_budgetaire, deliberation_ca` — assert budget_executoire_oui/non present, operation_budgetaire present, deliberation_ca present, montant_ae present (not required)
  - [x] Test: `create T2 Marché état saves montant_ae and beneficiaire` — full persistence test, t2_detail nil
  - [x] Test: `create T2 Marché organisme saves budget_executoire, operation_budgetaire, deliberation_ca` — persistence test
  - [x] Test: `new T2 Marché does not show section when nature = ISP` — AC5 regression test
  - [x] Test: `new HT2 does not show Marché section` — AC5 regression test

## Dev Notes

### Screenshot analysis — Marché (PSC) form layout

Two perimetre variants from screenshots provided:

**État layout:**
```
Row 1: [Initiales instructeur*] | [Nature: Marché (dropdown)]   | [Centre financier]
Row 2: [Exercice* dropdown]     | [Date de saisine* dropdown]   | [Service ordonnateur]
Row 3: [Objet]                  | [Montant au contrôle*]         | [Bénéficiaire]
Row 4: [Précisions sur l'acte (textarea)]
Footer: [Cet acte a été réalisé en période de services votés (checkbox)]
```

**Organisme layout:**
```
Row 1: [Initiales instructeur*] | [Nature: Marché (dropdown)]   | [Organisme*]
Row 2: [Exercice* dropdown]     | [Date de saisine* dropdown]   | [Service ordonnateur]
Row 3: [Objet]                  | [Montant au contrôle]          | [Bénéficiaire]
Row 4: [Budget exécutoire* Oui•/Non] | [Opération budgétaire dropdown]
Row 5: [Délibération en CA nécessaire Oui/Non•]
Row 6: [Précisions sur l'acte (textarea)]
Footer: [Cet acte a été réalisé en période de services votés (checkbox)]
```

> Note: `Précisions sur l'acte` and `services_votes` are in the **parent partial** `_form_informations_t2.html.erb` — do not add them to the section partial.
> Note: `t2-deliberation-ca-row` in the parent is only toggled for "Annexe financière" (acte_form_controller.js line 892–898). For Marché, `deliberation_ca` must be inside the `_marche.html.erb` partial itself.

### Fields are on `actes` table — no `t2_detail` used

All Marché-specific fields are already on the `actes` table:
- `beneficiaire` (string) — `db/schema.rb` line 24 ✓
- `montant_ae` (float) — `db/schema.rb` line 51 ✓ (already permitted in `acte_params` line 1175)
- `budget_executoire` (boolean, default: true) — `db/schema.rb` line 25 ✓
- `operation_budgetaire` (string) — `db/schema.rb` line 67 ✓
- `deliberation_ca` (boolean, default: false) — `db/schema.rb` line 41 ✓

All are already permitted in `acte_params` (line 1175–1185 of `actes_controller.rb`). **No controller changes needed.**

### `T2_DETAIL_FIELDS_BY_NATURE` — already correct, no change needed

Current (line 1138 of `actes_controller.rb`):
```ruby
'Marché' => [],
```

This is already correct — `clear_irrelevant_t2_detail_fields` will nullify all t2_detail fields when nature is Marché.

### `acte_params` — no changes needed

All five fields (`montant_ae`, `beneficiaire`, `budget_executoire`, `operation_budgetaire`, `deliberation_ca`) are already in `acte_params` at `actes_controller.rb` lines 1175–1185.

### `montant_ae` — same as Fongibilité asymétrique pattern

Use `f.number_field :montant_ae` (not `td.`), same as in `_fongibilite_asymetrique.html.erb`:
```erb
<%= f.number_field :montant_ae, value: acte.montant_ae, id: "montant_ae", class: "fr-input", step: "0.01",
                   data: { acte_form_target: "montantAe", action: "input->acte-form#changeNumber", acte_form_number_field: true } %>
```
For état: add `required: true`. For organisme: omit `required`.

### `beneficiaire` — text field on `actes`

```erb
<div class="fr-input-group">
  <label for="acte_beneficiaire" class="fr-label">Bénéficiaire</label>
  <%= f.text_field :beneficiaire, id: "acte_beneficiaire", class: "fr-input", value: acte.beneficiaire %>
</div>
```

### `budget_executoire` — radio Oui/Non, default Oui (organisme only)

Same pattern as in `_annexe_financiere.html.erb` lines 129–147:
```erb
<fieldset class="fr-fieldset fr-mb-0" aria-labelledby="budget-executoire-legend">
  <legend class="fr-fieldset__legend--regular fr-fieldset__legend" id="budget-executoire-legend">
    Budget exécutoire*
  </legend>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <%= f.radio_button :budget_executoire, true, id: "budget_executoire_oui",
                         checked: acte.budget_executoire == true || acte.budget_executoire.nil? %>
      <label class="fr-label" for="budget_executoire_oui">Oui</label>
    </div>
  </div>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <%= f.radio_button :budget_executoire, false, id: "budget_executoire_non" %>
      <label class="fr-label" for="budget_executoire_non">Non</label>
    </div>
  </div>
</fieldset>
```

### `operation_budgetaire` — dropdown (organisme only)

Options confirmed: **Globalisée** and **Fléchée** (same as in `_form_informations_organisme`).

```erb
<div class="fr-select-group">
  <label for="acte_operation_budgetaire" class="fr-label">Opération budgétaire</label>
  <%= f.select :operation_budgetaire,
               options_for_select(
                 [['Globalisée', 'Globalisée'], ['Fléchée', 'Fléchée']],
                 acte.operation_budgetaire
               ),
               { prompt: 'Sélectionner une option' },
               { id: "acte_operation_budgetaire", class: "fr-select" } %>
</div>
```

### Architectural decision — `deliberation_ca` moves from parent to each section partial

**Decision**: The `#t2-deliberation-ca-row` block currently in `_form_informations_t2.html.erb` (lines 142–193) must be removed from the parent and moved into each nature partial that needs it, adapted to that nature's specific behaviour.

**Rationale**: Each nature needs a different variant — Annexe financière shows sub-fields (numero, date, observations) when Oui is selected; Marché shows only the radio with no sub-fields. Centralising this in the parent was a simplification that doesn't scale.

**Impact on this story (2.6)**:
- This story's dev must remove `#t2-deliberation-ca-row` from `_form_informations_t2.html.erb` and add a simplified `deliberation_ca` radio (no sub-fields) inside `_marche.html.erb` for organisme
- The Stimulus JS toggling of `#t2-deliberation-ca-row` (line 892–898 of `acte_form_controller.js`) must be removed

**Impact on Story 2.3 (Annexe financière — already done)**:
- Story 2.3 will need a follow-up task: move the full `deliberation_ca` block (with `conditional-field` controller, numero/date/observations sub-fields) from the parent into `_annexe_financiere.html.erb`
- This can be done as part of this story's implementation to avoid leaving the parent in an inconsistent state, or tracked as a separate cleanup

### `deliberation_ca` — radio Oui/Non, default Non (organisme only, inside the partial, no sub-fields for Marché)

No `conditional-field` controller needed for Marché per screenshot — only the Oui/Non radio, no sub-fields revealed on Oui.

```erb
<fieldset class="fr-fieldset fr-mb-0" aria-labelledby="deliberation-ca-marche-legend">
  <legend class="fr-fieldset__legend--regular fr-fieldset__legend" id="deliberation-ca-marche-legend">
    Délibération en CA nécessaire
  </legend>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <%= f.radio_button :deliberation_ca, true, id: "deliberation_ca_oui" %>
      <label class="fr-label" for="deliberation_ca_oui">Oui</label>
    </div>
  </div>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <%= f.radio_button :deliberation_ca, false, id: "deliberation_ca_non",
                         checked: acte.deliberation_ca == false || acte.deliberation_ca.nil? %>
      <label class="fr-label" for="deliberation_ca_non">Non</label>
    </div>
  </div>
</fieldset>
```

> Important: The parent form's `#t2-deliberation-ca-row` is wired only for "Annexe financière" in `acte_form_controller.js` line 892. Do NOT rely on it for Marché. The `deliberation_ca` radio is inside `_marche.html.erb`.

### Partial layout — ERB skeleton

The partial is called by `_form_informations_t2.html.erb` line 128:
```erb
<div id="t2-section-marche" class="fr-hidden" data-acte-form-target="natureT2Section" aria-live="polite">
  <%= render 'actes/t2_sections/marche', f: f, td: td, acte: @acte %>
</div>
```

ERB structure:
```erb
<%# locals: (f:, td:, acte:) %>
<% is_organisme = acte.perimetre == 'organisme' %>
<% is_etat = acte.perimetre == 'etat' %>

<div class="fr-grid-row fr-grid-row--gutters">
  <%# Montant au contrôle (all périmètres, required for état only) %>
  <%# Bénéficiaire (all périmètres) %>
</div>

<% if is_organisme %>
  <div class="fr-grid-row fr-grid-row--gutters">
    <%# Budget exécutoire radio %>
    <%# Opération budgétaire dropdown %>
  </div>

  <div class="fr-grid-row fr-grid-row--gutters">
    <%# Délibération en CA radio %>
  </div>
<% end %>
```

### No Stimulus changes needed

- `toggleNatureT2` already maps 'Marché' → `t2-section-marche` (line 871 of `acte_form_controller.js`)
- No new JS methods needed (no real-time calculations for this nature)
- `#t2-deliberation-ca-row` in parent is NOT activated for Marché — this is intentional

### No migration needed

All columns already exist on `actes` table. No new `t2_details` columns needed.

### Tests — user fixtures available

- `users(:two)` — statut: CBR
- `users(:three)` — statut: DCB
- `users(:one)` — statut: admin (treated as DCB for nature list)

For organisme tests, pass `perimetre: 'organisme'` in params. Marché is available for both état (DCB) and organisme (all profiles).

### Files to create

- `app/views/actes/t2_sections/_marche.html.erb` — replace placeholder with full section

### Files to modify

- `app/views/actes/_form_informations_t2.html.erb` — remove `#t2-deliberation-ca-row` block (lines 142–193); keep section wrappers untouched
- `app/views/actes/t2_sections/_annexe_financiere.html.erb` — add the full `deliberation_ca` block (with `conditional-field` sub-fields) for organisme périmètre
- `app/javascript/controllers/acte_form_controller.js` — remove `deliberationRow` toggle logic (lines 892–898)
- `test/controllers/actes_controller_test.rb` — add Marché tests; verify Annexe financière `deliberation_ca` test still passes after refactor

### Files NOT touched

- `app/controllers/actes_controller.rb` — no changes needed (T2_DETAIL_FIELDS_BY_NATURE already correct, acte_params already complete)
- `db/schema.rb` — no migration needed
- `app/models/acte.rb` — no changes needed
- `app/models/t2_detail.rb` — no changes needed

### Existing patterns to reuse

| Pattern | Where |
|---------|-------|
| Radio Oui/Non with default Oui | `_annexe_financiere.html.erb` lines 129–147 (`budget_executoire`) |
| Radio Oui/Non with default Non | `_form_informations_t2.html.erb` lines 152–166 (`deliberation_ca`) — this block will be moved to `_annexe_financiere.html.erb` as part of Task 2 |
| Dropdown `fr-select` with prompt | `_annexe_financiere.html.erb` lines 5–9 (`type_acte_t2`) |
| `acte.perimetre == 'organisme'` conditional | `_annexe_financiere.html.erb` lines 127–148 |
| `f.number_field :montant_ae, step: "0.01"` | `_fongibilite_asymetrique.html.erb` line 11 |
| `f.text_field :beneficiaire` | `acte_params` permitted at line 1176 |
| `fr-grid-row fr-grid-row--gutters` | Used in all partials |
| `fr-col-12 fr-col-lg-4` | Column pattern throughout |

### Project Structure Notes

- Views: `app/views/actes/t2_sections/` — one partial per nature
- Section partial receives `f:, td:, acte:` locals (wired in `_form_informations_t2.html.erb` line 128)
- `f:` = form builder for `acte` — use for all Marché fields (`montant_ae`, `beneficiaire`, `budget_executoire`, `operation_budgetaire`, `deliberation_ca`)
- `td:` = fields_for builder for `t2_detail` — NOT used for this nature
- DSFR components: `fr-fieldset`, `fr-radio-group`, `fr-input-group`, `fr-select-group`, `fr-grid-row fr-grid-row--gutters`, `fr-col-12 fr-col-lg-4`

### References

- Epic spec — Story 2.6: [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 373–389
- Previous story (2.5 Fongibilité asymétrique, done): [_bmad-output/implementation-artifacts/2-5-section-specifique-nature-fongibilite-asymetrique.md](_bmad-output/implementation-artifacts/2-5-section-specifique-nature-fongibilite-asymetrique.md)
- Section placeholder (current): [app/views/actes/t2_sections/_marche.html.erb](app/views/actes/t2_sections/_marche.html.erb)
- Annexe financière partial (budget_executoire radio pattern): [app/views/actes/t2_sections/_annexe_financiere.html.erb](app/views/actes/t2_sections/_annexe_financiere.html.erb) lines 127–148
- T2 form parent (section wiring, deliberation_ca_row scoped to Annexe fin.): [app/views/actes/_form_informations_t2.html.erb](app/views/actes/_form_informations_t2.html.erb) lines 128–130, 142–193
- Stimulus toggleNatureT2 mapping: [app/javascript/controllers/acte_form_controller.js](app/javascript/controllers/acte_form_controller.js#L865)
- Controller `T2_DETAIL_FIELDS_BY_NATURE`: [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb#L1126)
- Controller `acte_params` (all fields already permitted): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb#L1175)
- DB schema (column verification): [db/schema.rb](db/schema.rb) lines 24–67
- Existing tests: [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `_marche.html.erb` implémenté : Row 1 (tous périmètres) — Montant au contrôle (`required` uniquement pour état) + Bénéficiaire. Row 2 (organisme) — Budget exécutoire radio Oui/Non (défaut Oui) + Opération budgétaire dropdown (Globalisée/Fléchée). Row 3 (organisme) — Délibération en CA radio Oui/Non (défaut Non, sans sous-champs). Tous les champs sur la table `actes` via `f:`, `td:` non utilisé.
- Refactoring `deliberation_ca` : bloc complet (avec `conditional-field`, sous-champs numero/date/observations) déplacé du parent `_form_informations_t2.html.erb` vers `_annexe_financiere.html.erb` (périmètre organisme). `#t2-deliberation-ca-row` supprimé du parent. Toggle JS (`deliberationRow`, lignes 892–898 d'`acte_form_controller.js`) supprimé.
- `T2_DETAIL_FIELDS_BY_NATURE['Marché'] => []` confirmé sans changement — `clear_irrelevant_t2_detail_fields` nullifie tous les champs t2_detail pour cette nature.
- 7 tests ajoutés dans `actes_controller_test.rb` : rendu état (montant_ae required, bénéficiaire, pas de champs organisme), rendu organisme (budget_executoire, operation_budgetaire Globalisée/Fléchée, deliberation_ca, montant_ae non-required), persistance état (montant_ae + bénéficiaire, t2_detail nil), persistance organisme (budget_executoire false, operation_budgetaire Fléchée, deliberation_ca true, t2_detail nil), régression ISP (marche caché), régression HT2 (marche absent), régression Annexe financière organisme (deliberation_ca toujours rendu après refactoring).
- Suite complète post-implémentation : **41 runs / 356 assertions / 0 failures / 0 errors**.
- Code review (2026-05-13) — corrections appliquées : IDs radio suffixés `_marche` dans `_marche.html.erb` pour éviter collision DOM avec `_annexe_financiere` (H1) ; `acte_form_target: "montantAe"` retiré du champ `montant_ae` Marché — logique retrait-négatif non applicable à cette nature (H2) ; validations modèle ajoutées pour `montant_ae` (requis état/Marché) et `budget_executoire` (inclusion organisme/Marché) dans `acte.rb` (M2) ; tests mis à jour avec nouveaux IDs suffixés, assertion ISP superflue retirée du test AC5, assertions de non-persistence des champs organisme ajoutées au test état (M1, M3). Suite : **41 runs / 356 assertions / 0 failures / 0 errors**.

### File List

- `app/views/actes/t2_sections/_marche.html.erb`
- `app/views/actes/t2_sections/_annexe_financiere.html.erb`
- `app/views/actes/_form_informations_t2.html.erb`
- `app/javascript/controllers/acte_form_controller.js`
- `app/models/acte.rb`
- `test/controllers/actes_controller_test.rb`
