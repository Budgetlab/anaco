# Story 2.11: Suspension et reprise d'un acte T2

Status: done

## Story

As an instructor,
I want to suspend and resume a T2 acte,
so that I can manage interruptions to the processing deadline.

## Acceptance Criteria

### AC1 — Suspension form renders for T2 actes at step 3

**Given** a T2 acte with `etat == "en cours d'instruction"` at step 3
**When** the instructor clicks the suspend button
**Then** the `_form_suspension` partial renders with `@liste_motifs_suspension` populated with T2-specific motifs:
- Demande de précision
- Pièce(s) manquante(s)
- Problématique de compatibilité avec la programmation
- Problématique de soutenabilité
- Saisine a posteriori
- Autre

**And** the form contains the date field, motif multi-select, and observations textarea — identical layout to HT2

### AC2 — Suspension is recorded in `suspensions` table with `acte_id`

**Given** a T2 acte at step 3
**When** the instructor submits the suspension form (via `PATCH acte_path`, `suspensions_attributes`)
**Then** a new `Suspension` record is created with `acte_id` = the T2 acte's id
**And** `motif`, `date_suspension`, and `observations` are persisted correctly
**And** the acte's `etat` is updated to `"suspendu"`

### AC3 — Resume (reprise) works for T2 actes

**Given** a T2 acte with `etat == "suspendu"` that has an open suspension
**When** the instructor accesses `edit_acte_suspension_path(@acte, @suspension)` and submits the reprise form
**Then** the `Suspension` record is updated with `date_reprise` and `commentaire_reprise`
**And** the acte's `etat` is reset to `"en cours d'instruction"`
**And** the instructor is redirected to `edit_acte_path(@acte, etape: 2)`

### AC4 — `check_edit_conditions` allows editing for T2 actes in suspended state

**Given** a T2 acte with `etat == "suspendu"` or `"à suspendre"`
**When** the instructor navigates to any edit step
**Then** `check_edit_conditions` does NOT redirect (the etat is in the allowed list)
**And** the edit form renders normally

### AC5 — No regression on HT2 suspension

**Given** an HT2 acte at step 3
**When** the instructor creates a suspension
**Then** the HT2-specific suspension motifs are used (e.g. "Défaut du circuit d'approbation Chorus", "Problématique de disponibilité des crédits")
**And** the T2 suspension motifs are NOT shown for HT2 actes

### AC6 — `refus_suspension` works for T2 actes

**Given** a T2 acte at step 3 that was suspended and sent to validation (`"à suspendre"` etat)
**When** the validator refuses the suspension via `POST refus_suspension`
**Then** the suspension record is destroyed
**And** the acte's `etat` reverts to `"en cours d'instruction"` with `renvoie_instruction: true`

## Tasks / Subtasks

- [x] **Task 1: Verify `@liste_motifs_suspension` is already set for T2 in `set_variables_form`** (AC: 1)
  - [x] In `app/controllers/actes_controller.rb`, locate the T2 block in `set_variables_form` (line ~1223)
  - [x] Confirm `@liste_motifs_suspension` is set with the 6 T2 motifs (done in story 2.10 — verify no regression)
  - [x] If missing, add it inside the T2 block before the `return`

- [x] **Task 2: Verify `suspensions_attributes` is accepted in `acte_params`** (AC: 2)
  - [x] In `app/controllers/actes_controller.rb`, locate `acte_params` (private method)
  - [x] Confirm `suspensions_attributes` is permitted (it should be — HT2 already uses it)
  - [x] If not, add: `suspensions_attributes: [:id, :date_suspension, :motif, :observations, :date_reprise, :commentaire_reprise, :_destroy]`

- [x] **Task 3: Verify `Acte` model accepts `suspensions_attributes`** (AC: 2)
  - [x] In `app/models/acte.rb`, confirm `has_many :suspensions` and `accepts_nested_attributes_for :suspensions` are declared
  - [x] If missing, add `accepts_nested_attributes_for :suspensions, allow_destroy: true`

- [x] **Task 4: Verify `SuspensionsController#update` redirects correctly for T2** (AC: 3)
  - [x] In `app/controllers/suspensions_controller.rb`, confirm `update` redirects to `edit_acte_path(@acte, etape: 2)` — this is already correct
  - [x] Confirm `set_acte` loads `@acte` via `@suspension.acte` — already correct since `Suspension` `belongs_to :acte`

- [x] **Task 5: Write controller tests** (AC: 1–6)
  - [x] `edit T2 step 3 suspension form renders with T2 motifs (AC1)` — already existed (story 2.10), verified passing
  - [x] `update T2 creates suspension with acte_id (already in story 2.10, verify exists)` — verified at line 1621
  - [x] `update T2 acte etat becomes suspendu after suspension (AC2)` — added, passing
  - [x] `suspension update resumes T2 acte (AC3)` — added in suspensions_controller_test.rb, passing
  - [x] `HT2 suspension motifs unchanged (AC5)` — added dedicated regression test, passing

## Dev Notes

### Architecture — how suspension works

Suspension follows a nested-attributes pattern rooted in `Acte`:

1. **Creation** (suspend): `PATCH acte_path(@acte)` with `params[:acte][:suspensions_attributes]` — handled by `ActesController#update`. The acte's `etat` is set to `"suspendu"` in the same payload.

2. **Reprise** (resume): `PATCH acte_suspension_path(@acte, @suspension)` — handled by `SuspensionsController#update`. It updates `date_reprise` + `commentaire_reprise`, then calls `@acte.update!(etat: "en cours d'instruction")`.

3. **Refus de suspension**: `POST refus_suspension_acte_suspension_path` — handled by `SuspensionsController#refus_suspension`. Destroys the suspension and resets acte etat.

The routes are:
```
resources :actes do
  resources :suspensions do
    post :refus_suspension
    get :modal_delete
    get :modal_refus_suspension
  end
end
```

### What story 2.10 already implemented

Story 2.10 (done) already set `@liste_motifs_suspension` for T2 actes inside the T2 branch of `set_variables_form` in the controller. It also added a test (`update T2 step 3 creates suspension with acte_id (AC6)` at line ~1621) that verifies a suspension is created with the correct `acte_id`.

**This story (2.11) is therefore largely already working.** The implementation tasks are primarily:
1. Verification that nothing is missing
2. Filling any gaps (especially the reprise path and the `SuspensionsController`)
3. Writing dedicated tests that specifically target T2 suspension/reprise as a complete workflow

### Key implementation constraint: early `return` in `set_variables_form`

The T2 branch of `set_variables_form` ends with `return` to prevent HT2 list assignments from running. This is the established pattern from story 2.10. **Do not remove this return** — it is load-bearing.

The full T2 block structure after story 2.10:
```ruby
if titre == 'T2'
  # ... @liste_natures assignment based on perimetre/statut ...
  @liste_types_observations = [...]  # T2-specific
  @liste_decisions = liste_decisions_for(type_acte)  # extracted private method
  @liste_motifs_suspension = [
    "Demande de précision",
    "Pièce(s) manquante(s)",
    "Problématique de compatibilité avec la programmation",
    "Problématique de soutenabilité",
    "Saisine a posteriori",
    "Autre"
  ]
  @categories = ...  # set to prevent regression
  return
end
```

### `Suspension` model — no changes needed

`Suspension` already `belongs_to :acte` (renamed from `ht2_acte` in story 1.1). No schema changes are required for T2 suspension — the `acte_id` foreign key is already in place.

### `_form_suspension.html.erb` — no changes needed

The partial uses `@liste_motifs_suspension` (line 23) and `type_suspension` (derived from `verbe_suspension` helper). Since T2 actes have `type_acte` ∈ {avis, visa}, the helper already returns the correct value (avis → "suspension", visa/TF → "interruption"). No view modification needed.

### `check_edit_conditions` — already supports suspended T2

```ruby
redirect_to actes_path and return unless ["en cours d'instruction", "suspendu", "en pré-instruction", "à suspendre"].include?(@acte.etat)
```
This already covers all suspension-related states for T2 actes.

### `acte_params` — verify `suspensions_attributes` is permitted

If `acte_params` does not already include `suspensions_attributes:`, add it. The expected shape for creation:
```ruby
suspensions_attributes: [:id, :date_suspension, :motif, :observations, :date_reprise, :commentaire_reprise, :_destroy]
```

### Test fixture pattern

```ruby
# Standard T2 acte for suspension tests
acte = users(:three).actes.create!(
  titre: 'T2', categorie_t2: 'hors_contrat', perimetre: 'etat',
  nature: 'Annexe financière', type_acte: 'avis',
  etat: "en cours d'instruction", instructeur: 'AB',
  annee: Date.today.year, date_saisine: Date.today
)

# Create a suspension directly for reprise tests
suspension = acte.suspensions.create!(
  date_suspension: Date.today - 2.days,
  motif: 'Demande de précision'
)
acte.update!(etat: 'suspendu')
```

Use `users(:three)` (statut: DCB) for État tests. Use `sign_in` before each test.

### Files to touch

- `app/controllers/actes_controller.rb` — verify `acte_params` has `suspensions_attributes:` (likely already present)
- `app/models/acte.rb` — verify `accepts_nested_attributes_for :suspensions` (likely already present)
- `test/controllers/actes_controller_test.rb` — add suspension/reprise workflow tests
- `test/controllers/suspensions_controller_test.rb` — add reprise test (currently empty stub)

### No view changes needed

All views (`_form_suspension`, `suspensions/edit`) are already correct. No new partials required.

### No migration needed

Schema is complete. `suspensions.acte_id` already exists from story 1.1.

### References

- Epic spec — Story 2.11: [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 520–533
- Previous story (2.10, done): [_bmad-output/implementation-artifacts/2-10-formulaire-t2-etape-3-decision.md](_bmad-output/implementation-artifacts/2-10-formulaire-t2-etape-3-decision.md)
- `set_variables_form` T2 block: [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb:1223)
- `acte_params` (verify `suspensions_attributes`): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb)
- `SuspensionsController`: [app/controllers/suspensions_controller.rb](app/controllers/suspensions_controller.rb)
- `Suspension` model: [app/models/suspension.rb](app/models/suspension.rb)
- `_form_suspension` partial: [app/views/actes/_form_suspension.html.erb](app/views/actes/_form_suspension.html.erb)
- Suspension reprise view: [app/views/suspensions/edit.html.erb](app/views/suspensions/edit.html.erb)
- Existing suspension test (AC2 already covered): [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb:1621)
- Routes (nested suspensions under actes): [config/routes.rb](config/routes.rb:75)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- **Vérification** : Toutes les tâches 1–4 étaient déjà implémentées correctement depuis la story 2.10. Aucun changement de code de production nécessaire.
- **Task 1** : `@liste_motifs_suspension` T2 confirmé à `actes_controller.rb` lignes 1252–1259 avec les 6 motifs corrects.
- **Task 2** : `suspensions_attributes` confirmé dans `acte_params` à la ligne 1195 (shape : `[:id, :_destroy, :date_suspension, :observations, motif: []]`).
- **Task 3** : `has_many :suspensions, dependent: :destroy` + `accepts_nested_attributes_for :suspensions` confirmés dans `acte.rb` lignes 17 et 23.
- **Task 4** : `SuspensionsController#update` redirige correctement vers `edit_acte_path(@acte, etape: 2)`, `set_acte` charge via `@suspension.acte`.
- **Task 5 — Tests ajoutés** (6 nouveaux tests, tous verts) :
  - `actes_controller_test.rb` : `update T2 etat becomes suspendu after suspension creation (AC2)`, `edit T2 acte with etat suspendu renders form (AC4)`, `edit T2 acte with etat a suspendre renders form (AC4)`, `HT2 step 3 liste_motifs_suspension uses HT2 motifs (AC5 regression)`, `refus_suspension resets T2 acte etat to en cours d instruction (AC6)`
  - `suspensions_controller_test.rb` : `update suspension resumes T2 acte and redirects to edit step 2 (AC3)` — fichier préalablement vide, maintenant implémenté.
- **Suite complète** : 114 runs / 865 assertions / 0 failures / 0 errors / 0 skips.
- **Corrections appliquées pendant les tests** : motif doit être `Array` pour `Suspension.create!`, route `acte_suspension_refus_suspension_path` (pas `refus_suspension_acte_suspension_path`), assertion AC5 affinée ("Demande de précision" sans 's' est T2-only).

### Code Review Fixes (review pass)

La review adversariale a révélé que 4 tests étaient faussement verts : le callback `after_save :set_etat_acte` du modèle `Acte` ramène immédiatement un acte créé avec `etat: 'suspendu'`/`'à suspendre'` vers `"en cours d'instruction"` si aucune suspension ouverte n'existe encore. Conséquence : tests AC3, AC4×2 et AC6 ne validaient pas réellement les scénarios décrits dans les AC.

Corrections apportées :

- **Tests AC3, AC4×2, AC6** : restructurés pour créer la suspension AVANT de positionner l'état suspendu/à suspendre. Pour `suspendu`, `acte.save!` re-déclenche `set_etat_acte` qui confirme l'état grâce à la suspension ouverte. Pour `à suspendre`, `update_column` court-circuite `set_etat_acte`. Ajout d'assertions de précondition `assert_equal 'suspendu'/'à suspendre', acte.etat` avant le PATCH pour rendre la régression immédiate si le scénario rompt à nouveau.
- **Test AC2 renforcé** : ajout de `assert_difference -> { acte.suspensions.count }, 1`, assertions sur `acte_id`, `motif`, `observations`, `date_suspension` du record créé.
- **Validations serveur ajoutées sur `Suspension`** :
  - `motif_must_have_non_blank_value` — rejette `[""]` ou `[]` que `presence: true + length >= 1` laissait passer.
  - `date_reprise_not_before_date_suspension` — la protection était uniquement côté JS (`flatpickr_min_date`), un POST direct (curl/Postman) pouvait soumettre une date_reprise antérieure.
- **Suite complète après corrections** : 114 runs / 876 assertions / 0 failures / 0 errors / 0 skips.

### File List

- `test/controllers/actes_controller_test.rb`
- `test/controllers/suspensions_controller_test.rb`
- `app/models/suspension.rb` (ajouts validations review pass)
