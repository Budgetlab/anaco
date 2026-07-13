# Story 2.1: Extend the "New Acte" Modal with the T2 Selector

Status: done

## Story

As an instructor,
I want to choose between HT2 and T2 in the new acte creation modal,
so that I can start entering the correct type of acte.

## Acceptance Criteria

### AC1 — "Titre" selector displayed at top of modal

**Given** the user clicks "Nouvel acte" on the dashboard
**When** the modal opens
**Then** a "Choisissez un titre" radio group is displayed at the very top of the modal form (before "Périmètre")
**And** it shows two options: "HT2 - Hors actes de personnel" and "T2 - Actes de personnel"
**And** "HT2" is selected by default

### AC2 — Existing selectors remain unchanged and always visible

**Given** the modal is open
**When** any titre value is selected
**Then** the "Périmètre" selector (État / Organisme) remains always visible
**And** the "Type de contrôle" selector (Avis / Visa) remains always visible for both HT2 and T2, regardless of périmètre
**And** the "État de l'acte" block (En instruction / En pré-instruction) remains always visible and unchanged

### AC2b — "Catégorie organisme" block hidden when T2 is selected

**Given** the user selects T2 as the titre
**When** T2 is active (regardless of périmètre)
**Then** the "Catégorie organisme" block (Dépense / Recette, currently `#categorie-organisme-block`) is hidden
**And** any previously selected `categorie_organisme` value is cleared
**Given** the user then switches back to HT2
**When** HT2 is selected AND périmètre is Organisme
**Then** the "Catégorie organisme" block is shown again (same behaviour as today)

### AC3 — TF type disappears when T2 is selected

**Given** the user is viewing the modal in "État" périmètre
**When** the user selects T2 as the titre
**Then** the "TF" option in "Type de contrôle" is hidden (it was already only shown for État+HT2)
**And** if TF was selected, it is deselected automatically

### AC4 — "Catégorie" selector appears conditionally for T2

**Given** the user selects T2 as the titre
**When** T2 is selected
**Then** a "Choisissez une catégorie" radio group appears below "Type de contrôle" and above "État de l'acte"
**And** it shows two options: "Contrat" and "Hors contrat"
**And** "Contrat" is visually disabled (grayed out, aria-disabled, not selectable) with a visual indication that it is out of scope for this stage
**And** "Hors contrat" is selected by default when T2 is selected
**And** the categorie field is required when T2 is selected

### AC5 — "Catégorie" hidden for HT2

**Given** the user selects HT2 as the titre (or it is the initial default state)
**When** HT2 is selected
**Then** the "Catégorie" block is not displayed
**And** no categorie_t2 value is passed to the new action

### AC6 — Modal validates correctly before navigating to the form

**Given** the user has selected T2 + Hors contrat + a périmètre + a type de contrôle + an état
**When** the user clicks "Commencer l'instruction"
**Then** the form submits (GET to `new_acte_path`) with the correct parameters: `titre=T2`, `categorie_t2=hors_contrat`, `perimetre`, `type_acte`, `etat`, `pre_instruction`
**And** the `new` action in `ActesController` initialises `@acte` with `titre: 'T2'` and `categorie_t2: 'hors_contrat'`

### AC7 — HT2 flow unchanged

**Given** the user selects HT2 (default)
**When** the user clicks "Commencer l'instruction" with the existing fields filled
**Then** the form submits without `titre` or `categorie_t2` params (or with `titre=HT2`)
**And** the controller sets `titre` to 'HT2' by default (model default already handles this)
**And** no regression occurs in the existing HT2 flow

## Tasks / Subtasks

- [x] **Task 1: Update `new_modal.html.erb` — add Titre selector** (AC: 1, 2, 3, 5)
  - [x] Add a new `<fieldset>` at the top of the form (before the Périmètre fieldset) for "Choisissez un titre*"
  - [x] Add two radio buttons: value `"HT2"` (id: `titre_ht2`, label: "HT2 - Hors actes de personnel", checked by default) and value `"T2"` (id: `titre_t2`, label: "T2 - Actes de personnel")
  - [x] Wire both radios to the Stimulus controller: `data-acte-form-target="titreRadio"` and `action: "change->acte-form#toggleTitre"`
  - [x] Use the same DSFR `fr-radio-group fr-radio-rich` pattern as the existing selectors

- [x] **Task 2: Update `new_modal.html.erb` — add Catégorie T2 selector** (AC: 4, 5)
  - [x] Add a new `<fieldset>` for "Choisissez une catégorie*" between "Type de contrôle" and "État de l'acte"
  - [x] Give it `id="categorie-t2-block"`, `class="fr-fieldset fr-hidden"`, and `data-acte-form-target="categorieT2Block"`
  - [x] Add radio button for "Contrat": value `"contrat"`, id `"categorie_t2_contrat"` — add `disabled` attribute, wrap label with visual styling to show it is grayed/unavailable (DSFR `fr-label--disabled` pattern or similar)
  - [x] Add radio button for "Hors contrat": value `"hors_contrat"`, id `"categorie_t2_hors_contrat"` — not disabled, `data-acte-form-target="categorieT2Radio"`
  - [x] Use form field name `categorie_t2` (not `categorie_organisme`)

- [x] **Task 3: Update `acte_form_controller.js` — add `toggleTitre` method** (AC: 2b, 3, 4, 5, 6)
  - [x] Add `"titreRadio"`, `"categorieT2Block"`, `"categorieT2Radio"` to the `static targets` list (the `categorieBlock` target already exists for catégorie organisme)
  - [x] Add method `toggleTitre(event)`:
    - Read selected titre value from `titreRadioTargets`
    - If T2:
      - Show `categorieT2BlockTarget` (remove `fr-hidden`), set `categorieT2RadioTargets` required, auto-select "Hors contrat" if nothing is checked
      - **Hide `categorieBlockTarget`** (add `fr-hidden`), uncheck and clear required on all `categorieRadioTargets` (same cleanup as `togglePerimetre` does when switching to État)
      - Hide TF option (same logic as `togglePerimetre` for TF)
    - If HT2:
      - Hide `categorieT2BlockTarget` (add `fr-hidden`), uncheck and clear required on all `categorieT2RadioTargets`
      - **Re-apply `togglePerimetre` logic for `categorieBlockTarget`**: show only if périmètre = Organisme
      - Show TF option if périmètre is État (re-use existing TF toggle logic)
  - [x] Call `toggleTitre()` from `connect()` if `hasTitreRadioTarget` (like `togglePerimetre`)
  - [x] Adjust `togglePerimetre` so it also respects the current titre:
    - TF option should only show if `titre === 'HT2'` AND `perimetre === 'etat'`
    - `categorieBlockTarget` (catégorie organisme) should only show if `titre === 'HT2'` AND `perimetre === 'organisme'`

- [x] **Task 4: Update `ActesController#new` — handle `titre` and `categorie_t2` params** (AC: 6, 7)
  - [x] In the `else` branch (lines ~278–285), add:
    - `titre = params[:titre].present? && %w[HT2 T2].include?(params[:titre]) ? params[:titre] : 'HT2'`
    - `categorie_t2 = params[:categorie_t2].present? && %w[hors_contrat contrat].include?(params[:categorie_t2]) ? params[:categorie_t2] : nil`
    - `categorie_t2 = nil if titre == 'HT2'`
  - [x] Pass `titre:` and `categorie_t2:` to `current_user.actes.new(...)` call on line ~285

- [ ] **Task 5: Verify no test regressions** (AC: 7)
  - [x] Run `bin/rails test` — 31 runs, 62 assertions, 0 failures, 0 errors ✅
  - [ ] Smoke-test the modal manually in the browser (dev server): open modal, switch HT2/T2, verify Catégorie apparaît/disparaît, Contrat grisé, Hors contrat pré-sélectionné, TF se comporte correctement

- [x] **Task 6 (review): Address code-review findings** (AC: 3, 4, 6, 7)
  - [x] H1 — Disable TF radio in DOM (`disabled=true`) when hidden, not just `fr-hidden`, so it can't be submitted in T2 mode
  - [x] H2 — Restrict controller `categorie_t2` to `'hors_contrat'` only when titre=T2 (Contrat is hors-périmètre)
  - [x] M2 — Broader DOM reset for `categorie_t2` radios (covers `contrat` disabled radio too)
  - [x] M3 — Add `required: true` initial on `hors_contrat` radio in ERB (defense if JS fails)
  - [x] M4 — Add controller integration tests for `ActesController#new` (titre/categorie_t2 whitelist + defaults) — Devise sign_in helpers wired in `test/test_helper.rb`

## Dev Notes

### Current modal structure (file: `app/views/actes/new_modal.html.erb`)

The form at line 18 submits via GET to `new_acte_path`. The current field flow is:
1. Périmètre (État / Organisme) → always visible
2. Type d'acte → Avis / Visa / TF (TF hidden for Organisme via `togglePerimetre`)
3. Catégorie organisme (Dépense / Recette) → shown only when Organisme (uses `fr-hidden` + `categorieBlock` target)
4. État de l'acte → always visible

The new flow after this story:
1. **[NEW] Titre** (HT2 / T2) — always at top
2. Périmètre (État / Organisme) — unchanged
3. Type de contrôle → Avis / Visa / TF (TF: hide if Organisme OR if T2)
4. Catégorie organisme (Dépense / Recette) → only for **HT2 + Organisme** (hidden if T2, regardless of périmètre)
5. **[NEW] Catégorie T2** (Contrat disabled / Hors contrat) — shown only when T2
6. État de l'acte — unchanged

### Stimulus controller: `app/javascript/controllers/acte_form_controller.js`

- File is already large (762 lines). The `togglePerimetre` method (lines 384–426) is the closest pattern to what `toggleTitre` needs.
- Two invariants now govern the modal's conditional blocks:
  - **TF must only show when titre=HT2 AND périmètre=État**
  - **Catégorie organisme must only show when titre=HT2 AND périmètre=Organisme**
- Currently `togglePerimetre` controls both of these based only on périmètre. After this story, both must also check titre. Best approach: extract two helpers `updateTfVisibility()` and `updateCategorieOrganismeVisibility()` called by both `toggleTitre` and `togglePerimetre`, each reading the current state of both titre and périmètre radios.
- Target naming: follow existing convention (`categorieBlock` for organisme catégorie). Suggest: `categorieT2Block` and `categorieT2Radio` for the new targets.

### DSFR disabled radio pattern

The DSFR design system uses a `disabled` attribute on the `<input>` and `fr-label--disabled` class on `<label>` to gray out a radio button. The wrapper div keeps `fr-radio-group fr-radio-rich`. Do NOT use `aria-disabled` on the input — use the native `disabled` attribute.

Example:
```html
<div class="fr-radio-group fr-radio-rich">
  <%= f.radio_button :categorie_t2, "contrat", id: "categorie_t2_contrat", disabled: true %>
  <label class="fr-label fr-label--disabled" for="categorie_t2_contrat">Contrat</label>
</div>
```

### `ActesController#new` — relevant section (lines 278–285)

```ruby
# Current (simplified)
type_acte = params[:type_acte]...
etat = params[:etat]...
pre_instruction = params[:pre_instruction] == 'true'
perimetre = params[:perimetre]...
categorie_organisme = params[:categorie_organisme]...
@acte = current_user.actes.new(type_acte:, etat:, type_engagement:, pre_instruction:, perimetre:, categorie_organisme:)

# After Task 4 addition:
titre = params[:titre].present? && %w[HT2 T2].include?(params[:titre]) ? params[:titre] : 'HT2'
categorie_t2 = titre == 'T2' && params[:categorie_t2].present? && %w[hors_contrat contrat].include?(params[:categorie_t2]) ? params[:categorie_t2] : nil
@acte = current_user.actes.new(titre:, type_acte:, etat:, type_engagement:, pre_instruction:, perimetre:, categorie_organisme:, categorie_t2:)
```

### Model validations already in place (no changes needed to model)

From `app/models/acte.rb` lines 86–88:
```ruby
validates :titre, presence: true, inclusion: { in: %w[HT2 T2] }
validates :categorie_t2, inclusion: { in: %w[contrat hors_contrat], allow_nil: true }
validates :categorie_t2, presence: true, if: -> { titre == 'T2' }
```
Database default: `titre` defaults to `'HT2'` (schema line 81). `categorie_t2` is a nullable string (schema line 28).

Note: the model validation requires `categorie_t2` when `titre == 'T2'`. The controller must pass it. The modal must enforce it client-side too (the radio group must have `required` when T2 is selected).

### Screenshot reference

The target design (provided by user) shows this exact layout:
- Section "Type d'acte": HT2 and T2 as radio-rich buttons (T2 selected in example)
- Section "Périmètre": État / Organisme
- Section "Type de contrôle": Avis / Visa (no TF when T2 is shown)
- Section "Catégorie": Contrat (grayed) / Hors contrat (selected)
- Section "État de l'acte": En instruction / En pré-instruction
- Button: "Commencer l'instruction"

Note: The screenshot labels the first section "Type d'acte" but the epics spec calls it "Titre". Use "Titre" as the fieldset legend to match the epics spec and model field name.

### Previous story learnings (Stories 1.1–1.4)

1. **No bulk shell substitutions** — use Read+Edit per file.
2. **Run `bin/rails test` after changes** — baseline is 31 runs / 62 assertions / 0 failures (from Story 1.4 end).
3. **Stimulus targets must be declared in `static targets`** before they can be used as `hasXxxTarget` — easy to forget.
4. **DSFR `fr-hidden` class** is what the app uses to toggle visibility (not `hidden` attribute) for Stimulus-toggled elements.
5. **`fr-radio-rich` pattern** is used consistently for all modal radio groups in `new_modal.html.erb`.
6. **GET form, not POST** — the modal form submits GET to `new_acte_path`, so params go into the query string, picked up in `ActesController#new` via `params[]`.

### Project Structure Notes

Files to modify:
- `app/views/actes/new_modal.html.erb` — add Titre fieldset + Catégorie T2 fieldset
- `app/javascript/controllers/acte_form_controller.js` — add `toggleTitre` + update `togglePerimetre` for TF+T2
- `app/controllers/actes_controller.rb` — extend `new` action's else branch with `titre` and `categorie_t2` params

Files NOT touched:
- `app/models/acte.rb` — model already has `titre` and `categorie_t2` validations and DB fields (done in Story 1.3)
- `db/schema.rb` — no migration needed
- Any T2 form files — out of scope (Stories 2.2–2.10)
- `new.html.erb` / `edit.html.erb` / `_form_informations.html.erb` — out of scope

### References

- Epic spec — Story 2.1: [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 240–259
- Modal view: [app/views/actes/new_modal.html.erb](app/views/actes/new_modal.html.erb)
- Stimulus controller: [app/javascript/controllers/acte_form_controller.js](app/javascript/controllers/acte_form_controller.js)
- Controller new action: [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb) lines 249–288
- Model validations for titre/categorie_t2: [app/models/acte.rb](app/models/acte.rb) lines 86–88
- DB schema — titre and categorie_t2 columns: [db/schema.rb](db/schema.rb) lines 28, 81
- Story 1.4 (last completed, same branch): [_bmad-output/implementation-artifacts/1-4-mettre-a-jour-le-controller-les-routes-et-les-vues.md](_bmad-output/implementation-artifacts/1-4-mettre-a-jour-le-controller-les-routes-et-les-vues.md)

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Modal `new_modal.html.erb` : fieldset "Titre" ajouté en tête de formulaire (HT2 par défaut), fieldset "Catégorie T2" ajouté entre "Type de contrôle" et "État de l'acte" (masqué par défaut, Contrat disabled, Hors contrat sélectionnable).
- Legend "Choisissez un type d'acte" renommée en "Choisissez un type de contrôle" pour cohérence avec la spec épique.
- `acte_form_controller.js` : ajout targets `titreRadio`, `categorieT2Block`, `categorieT2Radio` ; refactoring de `togglePerimetre` via deux helpers privés `_updateTfVisibility()` et `_updateCategorieOrganismeVisibility()` qui vérifient à la fois le titre et le périmètre ; ajout de `toggleTitre()` appelé depuis `connect()`.
- `actes_controller.rb` : branche `else` du `new` action enrichie avec `titre` (whitelist HT2/T2, défaut HT2) et `categorie_t2` (whitelist hors_contrat/contrat, nil si HT2).
- Suite de tests : 31 runs / 62 assertions / 0 failures / 0 errors. Avertissement `test_suspension_uses_acte_id_foreign_key` pré-existant, ignoré.

### Code Review (2026-05-13)

Adversarial code review effectué. 2 HIGH + 5 MEDIUM + 4 LOW findings. Issues HIGH+MEDIUM appliquées :

- **H1 (Stimulus)** : `_updateTfVisibility()` pose désormais `tfRadio.disabled = true/false` en plus de `fr-hidden` — empêche soumission TF en T2 si l'élément reste atteignable via focus clavier ou DevTools.
- **H2 (Controller)** : whitelist `categorie_t2` resserrée : `titre == 'T2' ? 'hors_contrat' : nil`. La valeur `'contrat'` (hors-périmètre story 2.x) ne peut plus être persistée même par requête GET forgée.
- **M2 (Stimulus)** : reset des radios `categorie_t2` au switch T2→HT2 élargi à `querySelectorAll('input[type=radio]')` sur le bloc — couvre aussi le radio `contrat` (qui n'est pas un Stimulus target).
- **M3 (View)** : `required: true` posé statiquement sur le radio `hors_contrat` dans l'ERB — défense en profondeur si Stimulus échoue à se connecter.
- **M4 (Tests)** : 6 smoke tests ajoutés sur `ActesController#new` couvrant les 6 combinaisons titre/categorie_t2 (default, T2, T2+hors_contrat, invalid titre, HT2+stray categorie_t2, T2+contrat). Helpers Devise integration câblés dans `test/test_helper.rb`. User fixture étendu avec `encrypted_password` (bcrypt).
- **M5** : tâche 5 parent décochée — la sous-tâche smoke-test browser reste `[ ]`.

Suite de tests post-review : **37 runs / 68 assertions / 0 failures / 0 errors**.

### File List

- `app/views/actes/new_modal.html.erb`
- `app/javascript/controllers/acte_form_controller.js`
- `app/controllers/actes_controller.rb`
- `test/controllers/actes_controller_test.rb` (review)
- `test/test_helper.rb` (review — Devise integration helpers)
- `test/fixtures/users.yml` (review — encrypted_password pour sign_in)
