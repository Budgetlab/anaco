# Story 2.3: Nature-Specific Section — "Annexe financière"

Status: done

## Story

As an instructor,
I want to fill in the specific fields of a T2 acte with nature "Annexe financière",
so that I can document the HR information needed for control (concours, recruitments).

## Acceptance Criteria

### AC1 — Annexe financière section appears when nature is selected

**Given** the instructor selects "Annexe financière" from the nature dropdown in the T2 step-1 form
**When** the `toggleNatureT2` Stimulus method fires
**Then** the `#t2-section-annexe-financiere` div (currently an empty placeholder) becomes visible (removes `fr-hidden`)
**And** all other nature sections remain hidden

### AC2 — Annexe financière fields displayed

**Given** the Annexe financière section is visible
**When** it renders
**Then** the following fields are present inside `#t2-section-annexe-financiere`:
- **Type d'acte** (`t2_detail[type_acte_t2]`, dropdown: Initial / Complémentaire) — obligatoire, uniquement pour cette nature. Colonne dédiée `t2_details.type_acte_t2` (ne pollue pas `actes.type_engagement` réservé au flux HT2)
- **Effectifs (liste principale)** (`t2_detail[effectifs]`, decimal input) — obligatoire
- **Effectifs (liste complémentaire)** (`t2_detail[effectifs_complementaire]`, decimal input) — optionnel
- **Catégorie(s)** (`t2_detail[grade][]`, multi-select) — optionnel
- **Corps** (`t2_detail[corps]`, text) — optionnel
- **Date de l'arrêté autorisant l'ouverture du concours** (`t2_detail[date_arrete_concours]`, flatpickr date) — optionnel
- **Date d'effet de l'acte** (`t2_detail[date_effet_acte]`, text) — optionnel
- **Impact sur schéma d'emplois** (`t2_detail[impact_schema_emplois]`, radio Oui/Non) — obligatoire
- If périmètre = État: **Impact autre CBCM** (`t2_detail[impact_autre_cbcm]`, radio Oui/Non) — obligatoire
- If périmètre = Organisme: **Impact autre CBR** (`t2_detail[impact_autre_cbcm]`, same column, radio Oui/Non) — obligatoire (label changes, column is the same)

### AC3 — Périmètre = Organisme: budget_executoire and deliberation_ca added in this section

**Given** the T2 form is displayed with périmètre = Organisme
**And** the Annexe financière section is shown
**When** it renders inside `#t2-section-annexe-financiere`
**Then** **Budget exécutoire** (`budget_executoire`, radio Oui/Non, default Oui) is displayed — obligatoire
**And** **Délibération en CA nécessaire** (`deliberation_ca`, radio Oui/Non, default Non) is displayed — with conditional reveal:
  - If Oui: show **N° de délibération** (`numero_deliberation_ca`, text), **Date de délibération** (`date_deliberation_ca`, flatpickr), **Observations sur la délibération** (`observations_deliberation_ca`, textarea)
  - If Non: those three fields are hidden
**And** these fields are NOT shown for périmètre = État

### AC4 — Data saved to t2_details (and actes for budget_executoire / deliberation_ca)

**Given** the form is submitted with Annexe financière fields filled
**When** the controller processes params
**Then** `t2_detail` nested attributes (`type_acte_t2`, `effectifs`, `effectifs_complementaire`, `grade`, `corps`, `date_arrete_concours`, `date_effet_acte`, `impact_schema_emplois`, `impact_autre_cbcm`) are saved to the `t2_details` table via `accepts_nested_attributes_for :t2_detail`
**And** `budget_executoire` and `deliberation_ca` (and their sub-fields) are saved to the `actes` table (they are columns on `actes`, already permitted in `acte_params`)
**And** if `t2_detail` does not yet exist for this acte, it is created; if it exists, it is updated

### AC5 — No regression on HT2 and other T2 natures

**Given** an acte with `titre = 'HT2'`
**When** any form is accessed
**Then** the HT2 behaviour is unchanged — no Annexe financière T2 section appears

**Given** the instructor selects a different T2 nature (e.g. ISP, Marché)
**When** the nature dropdown changes
**Then** the Annexe financière section is hidden and the appropriate other section shows

## Tasks / Subtasks

- [x] **Task 1: Add `accepts_nested_attributes_for :t2_detail` to `Acte` model and permit `t2_detail_attributes` in `acte_params`** (AC: 4)
  - [x] In `app/models/acte.rb`, add: `accepts_nested_attributes_for :t2_detail, update_only: true, reject_if: :all_blank`
  - [x] In `actes_controller.rb` `acte_params`, added `t2_detail_attributes: [:id, :type_acte_t2, :effectifs, :effectifs_complementaire, :corps, :date_arrete_concours, :date_effet_acte, :impact_schema_emplois, :impact_autre_cbcm, grade: []]` + grade string→array preprocessor
  - [x] Migration `CreateT2Details` enrichie de la colonne `type_acte_t2` (string) — rollback + ajout in-place + replay (branche non partagée). Validation `inclusion: { in: %w[Initial Complémentaire], allow_nil: true }` ajoutée dans `T2Detail` model.

- [x] **Task 2: Ensure T2Detail record is built/found before form render** (AC: 4)
  - [x] In `new` action: `@acte.build_t2_detail if titre == 'T2'`
  - [x] In `edit` action: `@acte.build_t2_detail if @acte.titre == 'T2' && @acte.t2_detail.nil?`

- [x] **Task 3: Replace the Annexe financière placeholder in `_form_informations_t2.html.erb`** (AC: 1, 2, 3)
  - [x] Placeholder remplacé par la section complète avec `f.fields_for :t2_detail`
  - [x] Layout : Type d'engagement + Date d'effet | Effectifs + Budget exécutoire (organisme) | Catégorie(s) + Corps | Date arrêté + Impact schéma emplois + Impact autre CBCM/CBR | Délibération CA + sous-champs (organisme, conditional-field)
  - [x] `aria-live="polite"` conservé sur le div section

- [x] **Task 4: Add `date_effet_acte` field inside section** (AC: 2)
  - [x] `date_effet_acte` ajouté en text_field (champ libre) dans la première ligne

- [x] **Task 5: Write controller/integration tests** (AC: 4, 5)
  - [x] Test: `new T2 Annexe financière renders fields_for t2_detail with effectifs`
  - [x] Test: `new T2 Annexe financière etat does not show budget_executoire or deliberation_ca`
  - [x] Test: `new T2 Annexe financière organisme shows budget_executoire and deliberation_ca`
  - [x] Test: `create T2 Annexe financière saves t2_detail fields` — persistance t2_details (AC4)
  - [x] Test: `create T2 organisme Annexe financière saves budget_executoire and deliberation_ca`
  - [x] Test: `HT2 create is unaffected by T2 changes` — non-régression AC5
  - [x] `bin/rails test` — 51 runs / 185 assertions / 0 failures / 0 errors ✅ (post-revue)

- [x] **Task 6 (Code review fix): Remplacer `type_engagement` par `t2_detail.type_acte_t2`** (AC: 2)
  - [x] Migration `CreateT2Details` enrichie de `t.string :type_acte_t2` (rollback + édition in-place + replay)
  - [x] Modèle `T2Detail` : validation `inclusion: %w[Initial Complémentaire], allow_nil: true`
  - [x] Vue `_annexe_financiere.html.erb` : `td.select :type_acte_t2` (label "Type d'acte*") au lieu de `f.select :type_engagement`
  - [x] Controller `acte_params` : `:type_acte_t2` ajouté dans `t2_detail_attributes`
  - [x] Tests mis à jour + assertions ajoutées sur `grade`, `date_arrete_concours`, `date_effet_acte`, `date_deliberation_ca`, `observations_deliberation_ca` (H3 / M5)
  - [x] Assertion `assert_nil acte.type_engagement` pour T2 (non-pollution du champ HT2)

## Dev Notes

### Screenshot context (provided by user)

Two screenshots provided showing the Annexe financière form for both périmètres:

**État périmètre layout:**
- Row 1: Initiales de l'instructeur* | Nature d'acte (Annexe financière) | Centre financier
- Row 2: Exercice* (2026) | Date de saisine* | Service ordonnateur
- Row 3: Objet | Type d'engagement* (Initial dropdown) | Date d'effet de l'acte ⓘ
- Row 4: Effectifs (liste principale)* | Effectifs (liste complémentaire) | Catégorie(s) (dropdown)
- Row 5: Corps | Date de l'arrêté autorisant l'ouverture du concours (dropdown) | Impact sur schéma d'emplois* (radio Oui•/Non)
- Row 6: Impact autre CBCM* (radio Oui/Non•)
- Full width: Précisions sur l'acte (textarea)
- Checkbox: Cet acte a été réalisé en période de services votés

**Organisme périmètre layout:**
- Row 1: Initiales de l'instructeur* | Nature d'acte (Annexe financière) | Organisme*
- Row 2: Exercice* (2026) | Date de saisine* | Service ordonnateur
- Row 3: Objet | Type d'acte* (Initial dropdown) | Date d'effet de l'acte ⓘ
- Row 4: Effectifs (liste principale)* | Effectifs (liste complémentaire) | Budget exécutoire* (radio **Oui•**/Non) ← default Oui
- Row 5: Catégorie(s) (dropdown) | Corps
- Row 6: Date de l'arrêté autorisant l'ouverture du concours (dropdown) | Impact sur schéma d'emplois ⓘ (radio Oui/Non•) | Impact autre CBCM/CBR (radio Oui/Non•)
- Row 7: Délibération en CA nécessaire ⓘ (radio **Oui•**/Non) ← screenshot shows Oui selected | N° de délibération (text) | Date de délibération (dropdown)
- Full width: Observations sur la délibération (textarea)
- Full width: Précisions sur l'acte (textarea)
- Checkbox: Cet acte a été réalisé en période de services votés

> Note: the screenshot shows "Délibération en CA nécessaire" defaulting to **Oui**, but the epic spec (Story 2.2, AC) says default is **false** (Non). Use **default Non** as specified in the epic — the screenshot may reflect an existing record. The `deliberation_ca` column has `default: false` in the DB schema. See AC3.

### "Type d'acte" — colonne `t2_details.type_acte_t2` (dédiée au flux T2)

**⚠️ Décision post-revue (2026-05-13)** : le champ "Type d'acte" (Initial / Complémentaire) du formulaire T2 Annexe financière est mappé sur une **nouvelle colonne dédiée** `t2_details.type_acte_t2`, et **non** sur `actes.type_engagement` (réservé au flux HT2 avec ses propres valeurs : "Engagement initial", "Affectation initiale", "Retrait d'engagement", "Retrait"). Cela évite toute confusion sémantique entre deux flux fonctionnels distincts qui partagent un libellé d'affichage proche.

- Colonne `t2_details.type_acte_t2` (string), ajoutée dans la migration `CreateT2Details` (rollback + édition in-place).
- Validation `T2Detail` : `validates :type_acte_t2, inclusion: { in: %w[Initial Complémentaire], allow_nil: true }`.
- Valeurs en base = valeurs affichées : `"Initial"` et `"Complémentaire"` (cohérent avec ce qu'on voit dans le dropdown DSFR).
- Permit : `t2_detail_attributes: [:id, :type_acte_t2, ...]`.

### `t2_detail` nested fields — fields_for pattern

```erb
<%= f.fields_for :t2_detail, @acte.t2_detail do |td| %>
  <%= td.number_field :effectifs, class: "fr-input", step: "0.01" %>
  ...
<% end %>
```

The `accepts_nested_attributes_for` on `Acte` will handle create/update automatically. The `id` field must be permitted so Rails can match existing records.

### budget_executoire — radio with default Oui for T2 Organisme

The HT2 organisme form (lines 162–179 of `_form_informations_organisme.html.erb`) uses radio with `checked: @acte.budget_executoire == true || @acte.budget_executoire.nil?`. The DB column `budget_executoire` has `default: true`. Use the same radio pattern for T2 Organisme. The column is already on `actes` and permitted in `acte_params`.

```erb
<fieldset class="fr-fieldset fr-mb-0" aria-labelledby="budget-executoire-legend">
  <legend class="fr-fieldset__legend--regular fr-fieldset__legend" id="budget-executoire-legend">
    Budget exécutoire*
  </legend>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <%= f.radio_button :budget_executoire, true, id: "budget_executoire_oui",
          checked: @acte.budget_executoire == true || @acte.budget_executoire.nil? %>
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

### deliberation_ca — conditional reveal using existing `conditional-field` Stimulus controller

The `conditional-field` controller is already registered (used in `_form_informations_organisme.html.erb` lines 247–288). Copy that pattern exactly:

```erb
<div class="fr-grid-row fr-grid-row--gutters" data-controller="conditional-field">
  <div class="fr-col-12 fr-col-lg-4">
    <fieldset class="fr-fieldset fr-mb-0" aria-labelledby="deliberation-ca-legend">
      <legend ...>Délibération en CA nécessaire</legend>
      <%= f.radio_button :deliberation_ca, true, id: "deliberation_ca_oui",
          data: { action: "change->conditional-field#toggle", conditional_field_target: "checkbox" } %>
      <label ...>Oui</label>
      <%= f.radio_button :deliberation_ca, false, id: "deliberation_ca_non",
          checked: @acte.deliberation_ca == false || @acte.deliberation_ca.nil?,
          data: { action: "change->conditional-field#toggle", conditional_field_target: "checkbox" } %>
      <label ...>Non</label>
    </fieldset>
  </div>
  <div class="fr-col-12 fr-col-lg-4 <%= 'fr-hidden' unless @acte.deliberation_ca %>"
       data-conditional-field-target="field">
    <%# N° de délibération %>
  </div>
  <div class="fr-col-12 fr-col-lg-4 <%= 'fr-hidden' unless @acte.deliberation_ca %>"
       data-conditional-field-target="field">
    <%# Date de délibération (flatpickr) %>
  </div>
  <div class="fr-col-12 fr-col-lg-12 <%= 'fr-hidden' unless @acte.deliberation_ca %>"
       data-conditional-field-target="field">
    <%# Observations sur la délibération %>
  </div>
</div>
```

### Catégorie(s) — dropdown à checkboxes (colonne `grade`)

Le champ affiché sous le label "Catégorie(s)" est mappé sur la colonne **`grade`** (`string[], default: []`) dans `t2_details`. Implémenté comme un dropdown à checkboxes via le Stimulus controller `checkbox-dropdown` (`app/javascript/controllers/checkbox_dropdown_controller.js`). Options fixes : A+, A, B, C. Un `hidden_field` porte la valeur soumise au format CSV (`"A+,B"`), converti en array par le préprocesseur controller existant. Ce champ est optionnel.

### impact_schema_emplois / impact_autre_cbcm — radio pattern

Both are boolean fields in `t2_details`. Default to **Non** for new actes (nil → Non). Use `checked: td.object.field == false || td.object.field.nil?` on the Non radio button.

```erb
<fieldset class="fr-fieldset fr-mb-0" aria-labelledby="impact-schema-legend">
  <legend ...>Impact sur schéma d'emplois*</legend>
  <%= td.radio_button :impact_schema_emplois, true, id: "impact_schema_emplois_oui" %>
  <label ...>Oui</label>
  <%= td.radio_button :impact_schema_emplois, false, id: "impact_schema_emplois_non",
      checked: td.object.impact_schema_emplois == false || td.object.impact_schema_emplois.nil? %>
  <label ...>Non</label>
</fieldset>
```

### Périmètre-conditional rendering in section

The section div is shared for all périmètres. Use ERB conditionals on `@acte.perimetre`:

```erb
<% if @acte.perimetre == 'organisme' %>
  <%# Budget exécutoire, Délibération en CA, sub-fields %>
<% end %>
<% if @acte.perimetre == 'etat' %>
  <%# label: Impact autre CBCM %>
<% elsif @acte.perimetre == 'organisme' %>
  <%# label: Impact autre CBR %>
<% end %>
```

### acte_params — t2_detail_attributes

`budget_executoire`, `deliberation_ca`, `numero_deliberation_ca`, `date_deliberation_ca`, `observations_deliberation_ca` are **already permitted** in `acte_params` (line 1138–1139 of controller). No change needed for those.

The only addition needed: `t2_detail_attributes: [:id, :type_acte_t2, :effectifs, :effectifs_complementaire, :corps, :date_arrete_concours, :date_effet_acte, :impact_schema_emplois, :impact_autre_cbcm, grade: []]`.

### build_t2_detail in controller

When a T2 acte is first created (new action), `t2_detail` is nil. Without `build_t2_detail`, `fields_for :t2_detail` will render nothing. Add in `new` action or in the before_action that sets `@acte`:

```ruby
# In new action, after @acte is assigned:
@acte.build_t2_detail if @acte.titre == 'T2' && @acte.t2_detail.nil?
```

For the `edit` action, the same guard is needed in case a T2 acte was created before this story was deployed.

### Files to create

- `app/javascript/controllers/checkbox_dropdown_controller.js` — Stimulus controller pour dropdown à checkboxes (Catégorie(s))
- `app/views/actes/t2_sections/_annexe_financiere.html.erb` — partial Annexe financière
- `app/views/actes/t2_sections/_enveloppe_limitative.html.erb` — placeholder
- `app/views/actes/t2_sections/_fongibilite_asymetrique.html.erb` — placeholder
- `app/views/actes/t2_sections/_isp.html.erb` — placeholder
- `app/views/actes/t2_sections/_marche.html.erb` — placeholder
- `app/views/actes/t2_sections/_mesure_transversale.html.erb` — placeholder
- `app/views/actes/t2_sections/_referentiel.html.erb` — placeholder

### Files to modify

- `app/models/acte.rb` — add `accepts_nested_attributes_for :t2_detail`
- `app/models/t2_detail.rb` — validation inclusion `:type_acte_t2`
- `app/controllers/actes_controller.rb` — permit `t2_detail_attributes` (avec `:type_acte_t2`), add `build_t2_detail` guard in `new`/`edit`
- `app/views/actes/_form_informations_t2.html.erb` — sections nature refactorisées en partials, `fields_for :t2_detail` partagé, `#t2-deliberation-ca-row` ajouté après la row principale
- `app/javascript/controllers/acte_form_controller.js` — `toggleNatureT2` étendu pour gérer `#t2-deliberation-ca-row`
- `db/migrate/20260512092104_create_t2_details.rb` — colonne `type_acte_t2` ajoutée in-place (rollback + replay sur branche non-partagée)

### Files NOT touched

- `app/views/actes/_form_informations.html.erb` — HT2 État form unchanged
- `app/views/actes/_form_informations_organisme.html.erb` — HT2 Organisme form unchanged
- `db/schema.rb` — no migration needed (all columns exist in `t2_details` and `actes`)

### Existing patterns to reuse

| Pattern | Where |
|---------|-------|
| Radio Oui/Non fieldset | `_form_informations_organisme.html.erb` lines 162–178 (budget_executoire) |
| conditional-field Stimulus reveal | `_form_informations_organisme.html.erb` lines 247–288 (deliberation_ca block) |
| flatpickr date input | `_form_informations_t2.html.erb` line 86 (date_saisine) |
| `fields_for` nested | Standard Rails — no existing example in this codebase, introduce it here |

### Project Structure Notes

- Views: `app/views/actes/` — `_form_informations_t2.html.erb` is the sole T2 step-1 partial
- Models: `app/models/acte.rb` (parent), `app/models/t2_detail.rb` (child, `belongs_to :acte`)
- Controller: `app/controllers/actes_controller.rb` — `acte_params` at line ~1129, `new` at line ~280
- DSFR: use `fr-fieldset`, `fr-radio-group`, `fr-input-group`, `fr-select-group`, `fr-grid-row fr-grid-row--gutters`, `fr-col-12 fr-col-lg-4`

### References

- Epic spec — Story 2.3: [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 297–319
- Epic spec — Story 2.2 (budget_executoire/deliberation_ca for Organisme): [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 286–290
- Previous story (2.2, done): [_bmad-output/implementation-artifacts/2-2-formulaire-t2-etape-1-champs-communs.md](_bmad-output/implementation-artifacts/2-2-formulaire-t2-etape-1-champs-communs.md)
- T2 form partial (current state): [app/views/actes/_form_informations_t2.html.erb](app/views/actes/_form_informations_t2.html.erb)
- HT2 Organisme form (deliberation_ca/budget_executoire patterns): [app/views/actes/_form_informations_organisme.html.erb](app/views/actes/_form_informations_organisme.html.erb) lines 162–288
- Acte model: [app/models/acte.rb](app/models/acte.rb)
- T2Detail model: [app/models/t2_detail.rb](app/models/t2_detail.rb)
- Controller: [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb) — `acte_params` ~l.1129, `new` ~l.280
- t2_details schema: [db/schema.rb](db/schema.rb) — `create_table "t2_details"`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `accepts_nested_attributes_for :t2_detail, update_only: true, reject_if: :all_blank` ajouté dans `Acte` modèle (avant les autres `accepts_nested_attributes_for`).
- `acte_params` étendu avec `t2_detail_attributes: [:id, :type_acte_t2, :effectifs, :effectifs_complementaire, :corps, :date_arrete_concours, :date_effet_acte, :impact_schema_emplois, :impact_autre_cbcm, grade: []]`. Préprocesseur ajouté pour convertir la string `grade` (saisie CSV) en array avant le permit.
- `build_t2_detail` ajouté dans `new` (après création de `@acte` quand `titre == 'T2'`) et dans `edit` (guard `t2_detail.nil?`).
- `_form_informations_t2.html.erb` : placeholder Annexe financière remplacé par la section complète avec `f.fields_for :t2_detail`. Les 6 autres natures conservent leur placeholder. Layout fidèle aux screenshots.
- **Décision post-revue** : le champ "Type d'acte" T2 est mappé sur une nouvelle colonne dédiée `t2_details.type_acte_t2` (et non sur `actes.type_engagement`). Cela évite toute pollution sémantique du flux HT2. Migration `CreateT2Details` enrichie in-place (rollback + replay, branche non partagée). Validation `T2Detail` : `inclusion: { in: %w[Initial Complémentaire], allow_nil: true }`.
- `Catégorie(s)` : dropdown à checkboxes (A+, A, B, C) via Stimulus controller `checkbox-dropdown`. Hidden field soumet la valeur CSV, préprocesseur controller split → array PostgreSQL.
- `impact_schema_emplois` et `impact_autre_cbcm` : défaut **Non** pour un nouvel acte (`checked: field == false || field.nil?`).
- Sections nature refactorisées en partials sous `app/views/actes/t2_sections/` (une par nature). `fields_for :t2_detail` dans le parent, locals `f:, td:, acte:` passés à chaque partial.
- Layout sections : row séparée sans marge top pour continuité visuelle (pas de `fr-mt-2w`).
- `acte_form_controller.js` : `toggleNatureT2` étendu pour gérer `#t2-deliberation-ca-row` (show si Annexe financière, hide sinon).
- 6 nouveaux tests dans `actes_controller_test.rb` couvrant rendu de section, conditionnels périmètre, persistance t2_details, non-régression HT2.
- Tests post-revue enrichis : assertions sur `grade` (CSV→array PG), `date_arrete_concours` (Date parsée), `date_effet_acte` (string), `date_deliberation_ca`, `observations_deliberation_ca`. Assertion `assert_nil acte.type_engagement` pour T2 (vérifie la non-pollution du champ HT2).
- Suite complète : **51 runs / 185 assertions / 0 failures / 0 errors**.

### File List

- `app/models/acte.rb`
- `app/models/t2_detail.rb`
- `app/controllers/actes_controller.rb`
- `app/views/actes/_form_informations_t2.html.erb`
- `app/views/actes/t2_sections/_annexe_financiere.html.erb`
- `app/views/actes/t2_sections/_enveloppe_limitative.html.erb`
- `app/views/actes/t2_sections/_fongibilite_asymetrique.html.erb`
- `app/views/actes/t2_sections/_isp.html.erb`
- `app/views/actes/t2_sections/_marche.html.erb`
- `app/views/actes/t2_sections/_mesure_transversale.html.erb`
- `app/views/actes/t2_sections/_referentiel.html.erb`
- `app/javascript/controllers/acte_form_controller.js`
- `app/javascript/controllers/checkbox_dropdown_controller.js`
- `db/migrate/20260512092104_create_t2_details.rb` (modifié in-place — colonne `type_acte_t2`)
- `db/schema.rb` (régénéré)
- `test/controllers/actes_controller_test.rb`
