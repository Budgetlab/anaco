# Story 2.10: T2 Form Step 3 — Decision

Status: done

## Story

As an instructor / validator,
I want to access step 3 (decision) of a T2 acte,
so that I can record the proposal and final control decision.

## Acceptance Criteria

### AC1 — Step 3 renders the existing `_form_proposition_decision` partial unchanged

**Given** I navigate to `edit_acte_path(@acte, etape: 3)` for a T2 acte
**When** the page loads
**Then** the partial `_form_proposition_decision.html.erb` is rendered — identical to HT2
**And** no T2-specific partial is created — the existing partial is reused as-is

### AC2 — `@liste_types_observations` is set for T2 actes

**Given** `set_variables_form` runs for a T2 acte at step 3
**When** `@liste_types_observations` is consumed by `_form_proposition_decision`
**Then** it contains exactly these values (T2 hors contrat observation types):
- Acte déjà signé par l'ordonnateur
- Compatibilité avec la programmation
- Evaluation de la consommation des crédits
- Fondement juridique
- Fongibilité asymétrique de faible montant
- Hors périmètre du CBR/DCB
- Incohérence avec le cadre de gestion
- Pièce(s) manquante(s)
- Risque au titre de la RGP
- Saisine a posteriori
- Saisine en dessous du seuil de soumission au contrôle
- Autre

### AC3 — `@liste_decisions` is set for T2 actes

**Given** `set_variables_form` runs for a T2 acte
**When** `@liste_decisions` is consumed by the decision dropdown in `_form_proposition_decision`
**Then** it is set based on `type_acte` (same logic as HT2):
- `type_acte == 'avis'` → `["Favorable", "Favorable avec observations", "Défavorable", "Retour sans décision (sans suite)", "Saisine a posteriori"]`
- `type_acte != 'avis'` (visa/TF) → `["Visa accordé", "Visa accordé avec observations", "Refus de visa", "Retour sans décision (sans suite)", "Saisine a posteriori"]`

### AC4 — `@liste_motifs_suspension` is set for T2 actes

**Given** `set_variables_form` runs for a T2 acte
**When** `@liste_motifs_suspension` is consumed by `_form_suspension`
**Then** it contains exactly these values (T2 hors contrat suspension motifs):
- Demande de précision
- Pièce(s) manquante(s)
- Problématique de compatibilité avec la programmation
- Problématique de soutenabilité
- Saisine a posteriori
- Autre

### AC5 — Status workflow is identical to HT2

**Given** a T2 acte at step 3
**When** the instructor submits the form
**Then** the status transitions (en cours d'instruction → à valider → à clôturer → clôturé) work identically to HT2
**And** all data is saved to the `actes` table (no `t2_details` changes at step 3)

### AC6 — Suspension form works for T2 actes

**Given** a T2 acte at step 3 with `etat == "en cours d'instruction"`
**When** the instructor clicks the suspension button
**Then** the suspension form renders with the T2-specific `@liste_motifs_suspension`
**And** the suspension is recorded in the `suspensions` table with `acte_id`

### AC7 — No regression on HT2

**Given** an HT2 acte at step 3
**When** the step-3 form is accessed
**Then** all existing `@liste_types_observations`, `@liste_decisions`, and `@liste_motifs_suspension` values are unchanged

## Tasks / Subtasks

- [x] **Task 1: Fix the early `return` in the T2 branch of `set_variables_form`** (AC: 2, 3, 4)
  - [x] In `app/controllers/actes_controller.rb`, locate the `if titre == 'T2'` block (line ~1223)
  - [x] Remove the bare `return` at the end of the T2 block
  - [x] Inside the T2 block (after setting `@liste_natures`), set `@liste_types_observations` with the T2 hors contrat observation types (AC2)
  - [x] Set `@liste_decisions` using the same `type_acte`-based logic that already exists below for HT2 (AC3) — copy/extract the existing `if type_acte == 'avis' ... else ... end` block
  - [x] Set `@liste_motifs_suspension` with the T2 hors contrat suspension motifs (AC4)
  - [x] Add `return` after setting all three lists so that the HT2 branches below are not evaluated

- [x] **Task 2: Write controller/integration tests** (AC: 1–7)
  - [x] `edit T2 avis etat step 3 renders form_proposition_decision with T2 observation types`
  - [x] `edit T2 visa etat step 3 renders form_proposition_decision`
  - [x] `edit T2 step 3 liste_decisions is Favorable list for type_acte avis`
  - [x] `edit T2 step 3 liste_decisions is Visa list for type_acte visa`
  - [x] `edit T2 step 3 liste_motifs_suspension contains T2 motifs`
  - [x] `HT2 step 3 liste_types_observations unchanged (regression check)`

## Dev Notes

### Root cause: early `return` in `set_variables_form`

The T2 block in `set_variables_form` (controller line ~1223) currently looks like:

```ruby
if titre == 'T2'
  perimetre_t2 = @acte&.perimetre || params[:perimetre]
  if perimetre_t2 == 'etat'
    if current_user.statut == 'DCB' || current_user.statut == 'admin'
      @liste_natures = [...]
    else
      @liste_natures = ['Fongibilité asymétrique']
    end
  else
    @liste_natures = [...]
  end
  return  # ← This is the problem. It skips @liste_decisions, @liste_types_observations, @liste_motifs_suspension
end
```

The fix: set all three lists inside the T2 block before returning. **Do not delete the `return`** — it must stay to prevent the HT2 branches below from running and overwriting with HT2 values.

### Correct final structure

```ruby
if titre == 'T2'
  perimetre_t2 = @acte&.perimetre || params[:perimetre]
  if perimetre_t2 == 'etat'
    if current_user.statut == 'DCB' || current_user.statut == 'admin'
      @liste_natures = ['Annexe financière', 'Enveloppe limitative', 'Fongibilité asymétrique', 'ISP', 'Marché', 'Mesure transversale', 'Référentiel']
    else
      @liste_natures = ['Fongibilité asymétrique']
    end
  else
    @liste_natures = ['Annexe financière', 'Enveloppe limitative', 'Fongibilité asymétrique', 'Marché', 'Mesure transversale', 'Référentiel']
  end

  @liste_types_observations = [
    "Acte déjà signé par l'ordonnateur",
    "Compatibilité avec la programmation",
    "Evaluation de la consommation des crédits",
    "Fondement juridique",
    "Fongibilité asymétrique de faible montant",
    "Hors périmètre du CBR/DCB",
    "Incohérence avec le cadre de gestion",
    "Pièce(s) manquante(s)",
    "Risque au titre de la RGP",
    "Saisine a posteriori",
    "Saisine en dessous du seuil de soumission au contrôle",
    "Autre"
  ]

  if type_acte == 'avis'
    @liste_decisions = ["Favorable", "Favorable avec observations", "Défavorable", "Retour sans décision (sans suite)", "Saisine a posteriori"]
  else
    @liste_decisions = ["Visa accordé", "Visa accordé avec observations", "Refus de visa", "Retour sans décision (sans suite)", "Saisine a posteriori"]
  end

  @liste_motifs_suspension = [
    "Demande de précision",
    "Pièce(s) manquante(s)",
    "Problématique de compatibilité avec la programmation",
    "Problématique de soutenabilité",
    "Saisine a posteriori",
    "Autre"
  ]

  return
end
```

### No view changes needed

The `when 3` block in `edit.html.erb` (line 117) already renders `_form_proposition_decision` unconditionally — it has no T2/HT2 branching:

```erb
<% when 3 %>
  <%= render 'form_proposition_decision' %>
```

This is correct. T2 shares the exact same step-3 form as HT2.

### `type_acte` for T2 actes

T2 actes can have `type_acte` = `'avis'` or `'visa'` (set at creation, defaults to `'visa'` per controller line 280). Tests at line 411 and 454 use `type_acte: 'visa'`. When writing tests, use both to cover both decision lists.

### `type_suspension` / `verbe_suspension` helpers — no change

These helpers (`actes_helper.rb` lines 74–79) check `acte.type_acte == 'avis'` → 'suspension' / 'interruption'. Since T2 actes can have either type_acte, this behavior is already correct and no change is needed.

### `_form_suspension.html.erb` — no change

The partial uses `@liste_motifs_suspension` (line 23) which will now be populated for T2 actes. No modification to the partial is needed.

### Data saved to `actes` table only

Step 3 fields (`proposition_decision`, `commentaire_proposition_decision`, `observations`, `type_observations`, `decision_finale`, `date_cloture`, `valideur`) are all in the `actes` table. No `t2_details` changes occur at step 3.

### Test fixture setup

```ruby
# T2 acte for step-3 tests
acte = current_user.actes.create!(
  titre: 'T2', perimetre: 'etat', nature: 'Annexe financière',
  type_acte: 'avis',
  etat: "en cours d'instruction", instructeur: 'AB',
  annee: Date.today.year, categorie_t2: 'hors_contrat'
)

# GET edit step 3
get edit_acte_path(acte, etape: 3)
assert_response :success
assert_select "select#proposition_decision"
assert_select "option", text: "Favorable"
# Verify T2 observation type present
assert_select "option", text: "Acte déjà signé par l'ordonnateur"
# Verify HT2-only observation type absent
assert_select "option[value=?]", "Construction de l'EJ", count: 0
```

Use `users(:three)` (statut: DCB) for état tests. Pattern mirrors existing test at line 1483+.

### Files to touch

- `app/controllers/actes_controller.rb` — update T2 block in `set_variables_form` (line ~1223–1237), add three list assignments before `return`
- `test/controllers/actes_controller_test.rb` — add 6 tests

### No migration needed

All step-3 fields already exist in `actes` table. No schema changes.

### References

- Epic spec — Story 2.10: [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 496–516
- Previous story (2.9, done): [_bmad-output/implementation-artifacts/2-9-formulaire-t2-etape-2-criteres-de-controle.md](_bmad-output/implementation-artifacts/2-9-formulaire-t2-etape-2-criteres-de-controle.md)
- T2 block in `set_variables_form` (line ~1223): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb:1223)
- `@liste_decisions` and `@liste_motifs_suspension` logic (line ~1291): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb:1291)
- Step-3 view routing (line 117): [app/views/actes/edit.html.erb](app/views/actes/edit.html.erb:117)
- `_form_proposition_decision.html.erb`: [app/views/actes/_form_proposition_decision.html.erb](app/views/actes/_form_proposition_decision.html.erb)
- `_form_suspension.html.erb` (uses `@liste_motifs_suspension`): [app/views/actes/_form_suspension.html.erb](app/views/actes/_form_suspension.html.erb)
- Existing tests (pattern to replicate, line 1483+): [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb:1483)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Ajout de `@liste_types_observations`, `@liste_decisions` et `@liste_motifs_suspension` dans le bloc T2 de `set_variables_form` (actes_controller.rb). Le `return` prématuré empêchait ces listes d'être renseignées, causant une erreur `undefined method 'map' for nil` à l'étape 3 pour les actes T2.
- `@liste_types_observations` : 12 types spécifiques T2 hors contrat (dont "Acte déjà signé par l'ordonnateur", "Incohérence avec le cadre de gestion", "Fongibilité asymétrique de faible montant" — absents de la liste HT2).
- `@liste_decisions` : basée sur `type_acte` (avis → Favorable/..., visa/TF → Visa accordé/...) — même logique que HT2.
- `@liste_motifs_suspension` : 6 motifs spécifiques T2 hors contrat (dont "Demande de précision", "Problématique de soutenabilité").
- Aucun changement de vue nécessaire — `when 3` dans `edit.html.erb` rend déjà `_form_proposition_decision` sans branchement T2/HT2.
- 6 tests ajoutés. Suite complète post-implémentation : **76 runs / 776 assertions / 0 failures / 0 errors**.

### Senior Developer Review (AI) — 2026-05-15

Reviewed by AI senior reviewer. 7 findings identifiés (4 medium, 3 low). Fixes appliqués pour les 4 medium :

1. **AC5 (workflow de statut)** — test ajouté : `update T2 step 3 transitions etat from en cours d'instruction to à valider (AC5)` (PATCH sur `acte_path` avec `etape: 3` et `etat: 'à valider'`).
2. **AC6 (création de suspension)** — test ajouté : `update T2 step 3 creates suspension with acte_id (AC6)` (vérifie `assert_difference -> { acte.suspensions.count }` et `suspension.acte_id == acte.id`).
3. **Duplication `@liste_decisions`** — extraction de la logique dans une méthode privée `liste_decisions_for(type_acte)` ; appelée à la fois dans la branche T2 et dans la branche HT2.
4. **`@categories` non défini pour T2** — `@categories` est désormais défini explicitement dans la branche T2 avant le `return` pour éviter une régression latente (le `return` early est conservé selon le pattern existant).

Suite complète post-revue : **108 runs / 844 assertions / 0 failures / 0 errors** (toute la suite, dont controller : 78 runs / 784 assertions).

Findings low (non bloquants, conservés sans correction) :
- Aucun commit dédié à la story 2.10 (toutes les stories 2.x dans le working tree).
- Note Dev Notes sur `type_acte` défaut 'visa' est correcte, mention `visa/TF` à clarifier dans la branche `else`.
- `T2_DETAIL_FIELDS_BY_NATURE` non trié alphabétiquement (hors-périmètre de cette story).

### File List

- `app/controllers/actes_controller.rb`
- `test/controllers/actes_controller_test.rb`
