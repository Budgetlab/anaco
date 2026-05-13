# Story 1.4: Update the controller, routes, and views

Status: done

## Story

As a developer (Alexandra),
I want to rename `ht2_actes_controller.rb` → `actes_controller.rb`, update all routes to use `/actes`, rename `app/views/ht2_actes/` → `app/views/actes/`, rename `app/admin/ht2_actes.rb` → `app/admin/actes.rb`, and replace all remaining `Ht2Acte`/`ht2_acte`/`ht2_actes` references across controllers, views, jobs, helpers, and tests,
so that the HTTP boundary of the application is fully consistent with the `Acte` model introduced in Stories 1.1–1.3, and the transitional `Ht2Acte = Acte` alias can be removed.

## Acceptance Criteria

### AC1 — Controller renamed and class updated

`app/controllers/ht2_actes_controller.rb` is renamed (git mv) to `app/controllers/actes_controller.rb`.
The class name becomes `ActesController < ApplicationController`.
All internal references to `set_acte_ht2`, `Ht2Acte`, and `ht2_acte` params are updated to `set_acte`, `Acte`, and `acte` params respectively.

### AC2 — Routes use `/actes` exclusively

`config/routes.rb` resource block changed from `resources :ht2_actes` to `resources :actes`.
All standalone route helpers pointing to `ht2_actes#...` are updated to `actes#...`.
No `/ht2_actes/...` route remains (per NFR2 in epics — backward compat URLs not preserved).
The custom route `synthese_users_ht2_actes` may keep its URL string but must point to `actes#synthese_utilisateurs`.
The nested `resources :suspensions` under `:actes` remains unchanged in structure.

### AC3 — Views directory renamed

`app/views/ht2_actes/` is renamed (git mv) to `app/views/actes/`.
All route helpers inside those views (`ht2_actes_path`, `ht2_acte_path`, `new_ht2_acte_path`, etc.) are replaced with their `actes`/`acte` equivalents.
The partial `ht2_actes/acte_pdf_content` referenced in `generate_acte_pdf_job.rb` is updated to `actes/acte_pdf_content` (and `actes/acte_organisme_pdf_content`).

### AC4 — ActiveAdmin file renamed and `as:` alias removed

`app/admin/ht2_actes.rb` is renamed (git mv) to `app/admin/actes.rb`.
The registration changes from `ActiveAdmin.register Acte, as: "Ht2Acte"` to `ActiveAdmin.register Acte` (no alias needed — the alias was only a temporary shim while URLs still pointed to `ht2_actes`).

### AC5 — All cross-file references updated

Files that reference `ht2_acte`/`Ht2Acte`/`ht2_actes` outside the renamed files are updated:
- `app/controllers/suspensions_controller.rb` — `edit_ht2_acte_path` / `ht2_acte_path` → `edit_acte_path` / `acte_path`
- `app/controllers/organismes_controller.rb` — `includes(:ht2_actes)` → `includes(:actes)`
- `app/controllers/pages_controller.rb` — `@ht2_actes` variable renamed `@actes` (instance variable used in `pages/index.html.erb`)
- `app/views/pages/index.html.erb` — `ht2_actes_path(...)`, `tableau_de_bord_ht2_actes_path` → `actes_path(...)`, `tableau_de_bord_actes_path`
- `app/views/suspensions/modal_delete.html.erb` — `ht2_acte_suspension_path` → `acte_suspension_path`
- `app/views/suspensions/modal_refus_suspension.html.erb` — `ht2_acte_suspension_refus_suspension_path` → `acte_suspension_refus_suspension_path`
- `app/jobs/generate_acte_pdf_job.rb` — partial name `'ht2_actes/acte_*_pdf_content'` → `'actes/acte_*_pdf_content'`
- `app/jobs/generate_backup_job.rb` — worksheet name `'ht2_actes'` → `'actes'` (Excel tab label); column headers `ht2_acte_id` may stay as-is since they reflect DB column names (now `acte_id`) — update header strings to `acte_id`
- `test/controllers/ht2_actes_controller_test.rb` — renamed to `test/controllers/actes_controller_test.rb`; class renamed `ActesControllerTest`

### AC6 — Transitional alias removed

The line `Ht2Acte = Acte` at the bottom of `app/models/acte.rb` (around line 815–817) is removed.
The comment block above it is also removed.

### AC7 — `titre` and `categorie_t2` added to `ransackable_attributes`

Per the note in Story 1.3 Dev Notes: ransackable exposure was explicitly deferred to Story 1.4.
Add `'titre'` and `'categorie_t2'` to `ransackable_attributes` in `app/models/acte.rb` (around line 66).

### AC8 — Integration tests pass

`bin/rails test` is green with zero regressions.
The controller test file `test/controllers/actes_controller_test.rb` inherits from `ActionDispatch::IntegrationTest` (class body may remain empty as it was).

---

## Tasks / Subtasks

- [x] **Task 1: Rename controller file and update class internals** (AC: 1)
  - [x] `git mv app/controllers/ht2_actes_controller.rb app/controllers/actes_controller.rb`
  - [x] Change class declaration: `class Ht2ActesController` → `class ActesController`
  - [x] Rename private method `set_acte_ht2` → `set_acte`; update all `before_action :set_acte_ht2` references within the file
  - [x] Replace all remaining `Ht2Acte`/`ht2_acte` references inside the file (params key `:ht2_acte` → `:acte`, etc.)
  - [x] Remove the duplicate `include ActesHelper` (line 16 — it already appears on line 2)

- [x] **Task 2: Update routes** (AC: 2)
  - [x] In `config/routes.rb`: `resources :ht2_actes` → `resources :actes`
  - [x] Update nested collection/member route strings: `to: 'ht2_actes#...'` → `to: 'actes#...'`
  - [x] Update all standalone `get`/`post`/`delete` routes pointing to `ht2_actes#*`
  - [x] Rename route named `synthese_users_ht2_actes` path — change to point to `actes#synthese_utilisateurs` (URL string may change or keep `synthese_users` as appropriate)
  - [x] Verify no `ht2_actes` string remains in routes.rb

- [x] **Task 3: Rename views directory and update route helpers inside views** (AC: 3)
  - [x] `git mv app/views/ht2_actes app/views/actes`
  - [x] In all files under `app/views/actes/`: replace `ht2_actes_path` → `actes_path`, `ht2_acte_path` → `acte_path`, `new_ht2_acte_path` → `new_acte_path`, `edit_ht2_acte_path` → `edit_acte_path`, `bulk_cloture_ht2_actes_path` → `bulk_cloture_actes_path`, `synthese_anomalies_ht2_actes_path` → `synthese_anomalies_actes_path`, `tableau_de_bord_ht2_actes_path` → `tableau_de_bord_actes_path`, `synthese_temporelle_ht2_actes_path` → `synthese_temporelle_actes_path`, `synthese_suspensions_ht2_actes_path` → `synthese_suspensions_actes_path`
  - [x] Update `search_form_for` URL: `url: ht2_actes_path` → `url: actes_path`

- [x] **Task 4: Rename ActiveAdmin file and fix registration** (AC: 4)
  - [x] `git mv app/admin/ht2_actes.rb app/admin/actes.rb`
  - [x] Change `ActiveAdmin.register Acte, as: "Ht2Acte"` → `ActiveAdmin.register Acte` (drop the `as:` alias)
  - [x] Verify no remaining reference to `"Ht2Acte"` in admin files

- [x] **Task 5: Update cross-file references in controllers** (AC: 5)
  - [x] `app/controllers/suspensions_controller.rb`: replace `edit_ht2_acte_path` → `edit_acte_path`, `ht2_acte_path` → `acte_path`
  - [x] `app/controllers/organismes_controller.rb`: `includes(:ht2_actes)` → `includes(:actes)` (x2 occurrences)
  - [x] `app/controllers/pages_controller.rb`: rename `@ht2_actes` → `@actes` (lines 29–33 approx); check pages/index.html.erb for matching variable name

- [x] **Task 6: Update cross-file references in views** (AC: 5)
  - [x] `app/views/pages/index.html.erb`: `ht2_actes_path(...)` → `actes_path(...)` (5 occurrences), `tableau_de_bord_ht2_actes_path` → `tableau_de_bord_actes_path`; also update `@ht2_actes` references if any
  - [x] `app/views/suspensions/modal_delete.html.erb`: `ht2_acte_suspension_path` → `acte_suspension_path`
  - [x] `app/views/suspensions/modal_refus_suspension.html.erb`: `ht2_acte_suspension_refus_suspension_path` → `acte_suspension_refus_suspension_path`

- [x] **Task 7: Update jobs** (AC: 3, 5)
  - [x] `app/jobs/generate_acte_pdf_job.rb`: `'ht2_actes/acte_organisme_pdf_content'` → `'actes/acte_organisme_pdf_content'` and `'ht2_actes/acte_pdf_content'` → `'actes/acte_pdf_content'`
  - [x] `app/jobs/generate_backup_job.rb`: worksheet name `'ht2_actes'` → `'actes'`; header strings `'ht2_acte_id'` → `'acte_id'` (x3 — suspensions, poste_lignes, echeanciers worksheets)

- [x] **Task 8: Rename controller test and update class** (AC: 5, 8)
  - [x] `git mv test/controllers/ht2_actes_controller_test.rb test/controllers/actes_controller_test.rb`
  - [x] Change class declaration: `class Ht2ActesControllerTest` → `class ActesControllerTest`

- [x] **Task 9: Remove transitional alias from model** (AC: 6)
  - [x] In `app/models/acte.rb`, delete the `Ht2Acte = Acte` line and its surrounding comment block (lines ~813–817)

- [x] **Task 10: Add `titre` and `categorie_t2` to ransackable_attributes** (AC: 7)
  - [x] In `app/models/acte.rb`, add `'titre'` and `'categorie_t2'` to the `ransackable_attributes` array (around line 66)

- [x] **Task 11: Run full test suite** (AC: 8)
  - [x] `bin/rails test` — verify green, 0 failures, 0 errors

---

## Dev Notes

### Key files and their exact changes

**Renames (use `git mv` — do NOT copy/delete):**
```
git mv app/controllers/ht2_actes_controller.rb  app/controllers/actes_controller.rb
git mv app/views/ht2_actes                       app/views/actes
git mv app/admin/ht2_actes.rb                    app/admin/actes.rb
git mv test/controllers/ht2_actes_controller_test.rb test/controllers/actes_controller_test.rb
```

**Controller class rename pattern:**
```ruby
# Before
class Ht2ActesController < ApplicationController
  before_action :set_acte_ht2, only: [...]
  private
  def set_acte_ht2
    @acte = Acte.find(params[:id])
  end

# After
class ActesController < ApplicationController
  before_action :set_acte, only: [...]
  private
  def set_acte
    @acte = Acte.find(params[:id])
  end
```

**Routes block replacement:**
```ruby
# Before
resources :ht2_actes do
  resources :suspensions do ...
  collection do
    post :bulk_cloture
    get 'tableau_de_bord', to: 'ht2_actes#tableau_de_bord'
    ...

# After
resources :actes do
  resources :suspensions do ...
  collection do
    post :bulk_cloture
    get 'tableau_de_bord', to: 'actes#tableau_de_bord'
    ...
```

All standalone routes: `to: 'ht2_actes#method_name'` → `to: 'actes#method_name'`.

**ActiveAdmin fix:**
```ruby
# Before
ActiveAdmin.register Acte, as: "Ht2Acte" do

# After
ActiveAdmin.register Acte do
```
Dropping the `as: "Ht2Acte"` alias changes the ActiveAdmin admin URL prefix from `/admin/ht2_actes` to `/admin/actes`. This is acceptable per NFR2 (no backward compat for URLs). Any hardcoded ActiveAdmin URL strings in views/tests must also be updated if they exist.

**Ransackable attributes in `acte.rb` (around line 66):**
```ruby
# Before (example structure)
def self.ransackable_attributes(_auth_object = nil)
  %w[annee categorie centre_financier_code date_cloture date_saisine ...]
end

# After — add 'titre' and 'categorie_t2'
def self.ransackable_attributes(_auth_object = nil)
  %w[annee categorie categorie_t2 centre_financier_code date_cloture date_saisine ... titre ...]
end
```
Maintain alphabetical order if the existing list is alphabetical.

**Alias removal in `acte.rb`:**
Lines approximately 813–817 contain:
```ruby
# Alias transitoire conservé jusqu'à ce que le controller, les routes et les vues
# auront été renommés. Permet à ActiveAdmin (`register Acte, as: "Ht2Acte"`)
# de conserver ses URLs admin jusqu'à la Story 1.4.
Ht2Acte = Acte
```
Delete all 4 lines (comment + constant assignment).

**generate_backup_job.rb — worksheet and headers:**
```ruby
# Before
wb.add_worksheet(name: 'ht2_actes') do |sheet|
  sheet.add_row %w[id ht2_acte_id date_suspension ...  # in suspensions worksheet
  sheet.add_row %w[id ht2_acte_id numero ...           # in poste_lignes worksheet
  sheet.add_row %w[id ht2_acte_id annee ...            # in echeanciers worksheet

# After
wb.add_worksheet(name: 'actes') do |sheet|
  sheet.add_row %w[id acte_id date_suspension ...
  sheet.add_row %w[id acte_id numero ...
  sheet.add_row %w[id acte_id annee ...
```

**generate_acte_pdf_job.rb:**
```ruby
# Before
partial_name = acte.perimetre == 'organisme' ? 'ht2_actes/acte_organisme_pdf_content' : 'ht2_actes/acte_pdf_content'

# After
partial_name = acte.perimetre == 'organisme' ? 'actes/acte_organisme_pdf_content' : 'actes/acte_pdf_content'
```

**pages_controller.rb — variable rename:**
```ruby
# Before (lines ~29–33)
@ht2_actes = @statut_user == 'admin' ? Acte.all : current_user.actes
counts = @ht2_actes.group(:etat).count
@ht2_echeance_courte = @ht2_actes.echeance_courte
@ht2_long_delay = @ht2_actes.count_current_with_long_delay

# After
@actes = @statut_user == 'admin' ? Acte.all : current_user.actes
counts = @actes.group(:etat).count
@ht2_echeance_courte = @actes.echeance_courte   # keep instance var names used by view
@ht2_long_delay = @actes.count_current_with_long_delay
```
Note: `@ht2_echeance_courte` and `@ht2_long_delay` are used by `pages/index.html.erb` — change those instance variable names in both controller AND view together, OR leave them as-is (they represent HT2+T2 combined eventually but keeping the name is harmless for now). **Safest approach: only rename `@ht2_actes` → `@actes` (the query variable), leave `@ht2_echeance_courte` / `@ht2_long_delay` unchanged to avoid touching the view.** Only update them if they appear in view and you're confident about the scope.

**organismes_controller.rb:**
```ruby
# Before
@organismes = Organisme.includes(:ht2_actes).order(nom: :asc)   # x2

# After
@organismes = Organisme.includes(:actes).order(nom: :asc)       # x2
```
This works because Story 1.1 renamed the `has_many` association on `Organisme` from `:ht2_actes` to `:actes`.

### Scope of this story

This story is the **HTTP boundary rename** only. No new features, no T2 form logic. The `Acte` model itself is complete (Story 1.3). The `T2Detail` model is complete (Story 1.2). This story closes the loop on all files that still reference the old `ht2_actes` naming.

### Files NOT touched in this story

- `app/models/acte.rb` — only the alias removal and ransackable changes (Tasks 9 and 10)
- `app/models/t2_detail.rb` — no changes
- `db/schema.rb` — no migration in this story
- Any Epic 2 form logic — out of scope
- `lib/tasks/generate_missing_pdfs.rake` — check if it references `Ht2Acte` or `ht2_actes`

### Check `lib/tasks/generate_missing_pdfs.rake`

```bash
grep -n "ht2_acte\|Ht2Acte\|ht2_actes" lib/tasks/generate_missing_pdfs.rake
```
If any references found, update them to `Acte` / `acte` / `actes`. Story 1.1 dev notes mention this file was updated, but double-check at implementation time.

### Pitfalls to avoid

1. **Do NOT use bulk shell substitution** (`sed -i`, `perl -i`, `find -exec`). Use Read + Edit for each file to avoid accidental replacements (e.g. `ht2_actes_path` in a comment that shouldn't change, or a CSV/YAML that uses the old name intentionally).

2. **Route helper name changes ripple into views and controller specs.** After renaming routes, Rails will error immediately on any remaining `ht2_acte_path`/`ht2_actes_path` call — use this to find any missed occurrences. Run `bin/rails routes | grep ht2` after task 2 to confirm no old routes remain.

3. **ActiveAdmin URL change**: dropping `as: "Ht2Acte"` means the admin panel URL for actes changes from `/anaco/admin/ht2_actes` to `/anaco/admin/actes`. If there are any hardcoded admin URL strings in specs or config, they need updating.

4. **Duplicate `include ActesHelper`**: The controller file has `include ActesHelper` on both line 2 and line 16. Remove the duplicate (line 16) while renaming — clean this up in Task 1.

5. **`synthese_users_ht2_actes` path**: this is currently a named route `as: 'synthese_users_ht2_actes'` (implicit) pointing to `get 'synthese_users_ht2_actes', to: 'ht2_actes#synthese_utilisateurs'`. In the new routes, it becomes `get 'synthese_users_actes', to: 'actes#synthese_utilisateurs'`. The URL string itself changes — scan all views/controller for `synthese_users_ht2_actes_path` helper usage.

6. **Turbo frames**: many views use `data: { turbo_frame: "table" }` etc. These are unaffected by the route rename — do NOT touch them.

7. **`check_chorus_number` route**: currently `get 'check_chorus_number', to: 'ht2_actes#check_chorus_number'`. Update to `to: 'actes#check_chorus_number'`. Verify the Stimulus/Turbo JS call that triggers this endpoint (likely a URL string in a view or JS file) is also updated.

### `check_chorus_number` endpoint — JS/Stimulus reference

Search for the URL used by the chorus number check:
```bash
grep -rn "check_chorus_number" app/ --include="*.erb" --include="*.js" --include="*.html"
```
This endpoint is likely called from a Stimulus controller or view with a hardcoded URL or `check_chorus_number_path`. Update as needed.

### Learnings from Stories 1.1–1.3

1. **`git mv` preserves history** — always use `git mv` for renames, never delete+create.
2. **Run `bin/rails runner` smoke test** before full test suite — catches route/constant errors early.
3. **Test baseline (Story 1.3 end)**: 31 runs / 61 assertions / 0 failures. After this story: test count should remain similar (controller test file currently has 0 tests).
4. **Warning `test_suspension_uses_acte_id_foreign_key`** — pre-existing, ignore.
5. **No bulk shell substitution** — confirmed from Story 1.3 learnings.
6. **`actes` fixture** (`test/fixtures/actes.yml`) was renamed in Story 1.1 and should not need changes here.

### Project Structure Notes

**Files to rename (git mv):**
- `app/controllers/ht2_actes_controller.rb` → `app/controllers/actes_controller.rb`
- `app/views/ht2_actes/` → `app/views/actes/` (entire directory)
- `app/admin/ht2_actes.rb` → `app/admin/actes.rb`
- `test/controllers/ht2_actes_controller_test.rb` → `test/controllers/actes_controller_test.rb`

**Files to edit (content changes only):**
- `config/routes.rb`
- `app/models/acte.rb` (alias removal + ransackable)
- `app/controllers/suspensions_controller.rb`
- `app/controllers/organismes_controller.rb`
- `app/controllers/pages_controller.rb`
- `app/views/pages/index.html.erb`
- `app/views/suspensions/modal_delete.html.erb`
- `app/views/suspensions/modal_refus_suspension.html.erb`
- `app/jobs/generate_acte_pdf_job.rb`
- `app/jobs/generate_backup_job.rb`
- All files under `app/views/actes/` that contain `ht2_acte*` route helpers
- `lib/tasks/generate_missing_pdfs.rake` (if needed — verify first)

### References

- Story 1.3 (predecessor — in review): [_bmad-output/implementation-artifacts/1-3-mettre-a-jour-le-modele-acte-renomme-depuis-ht2-acte.md](_bmad-output/implementation-artifacts/1-3-mettre-a-jour-le-modele-acte-renomme-depuis-ht2-acte.md)
- Epic definition — Story 1.4 spec: [_bmad-output/planning-artifacts/epics-t2-integration.md — Story 1.4](_bmad-output/planning-artifacts/epics-t2-integration.md)
- Architecture decision (routes migration, no compat `/ht2_actes`): epics-t2-integration.md — Architecture décidée + NFR2
- Current controller: [app/controllers/ht2_actes_controller.rb](app/controllers/ht2_actes_controller.rb)
- Current routes: [config/routes.rb](config/routes.rb) lines 75–117
- Current admin: [app/admin/ht2_actes.rb](app/admin/ht2_actes.rb)
- Transitional alias location: [app/models/acte.rb](app/models/acte.rb) lines ~813–817
- Ransackable attributes location: [app/models/acte.rb](app/models/acte.rb) line ~66
- `generate_acte_pdf_job.rb`: [app/jobs/generate_acte_pdf_job.rb](app/jobs/generate_acte_pdf_job.rb)
- `generate_backup_job.rb`: [app/jobs/generate_backup_job.rb](app/jobs/generate_backup_job.rb)

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (dev) ; claude-opus-4-7 (review)

### Debug Log References

### Completion Notes List

- Story 1.4 (HTTP boundary rename) appliquée : controller, routes, vues, ActiveAdmin, jobs, tests intégrés.
- Alias transitoire `Ht2Acte = Acte` supprimé de `app/models/acte.rb`.
- `titre` et `categorie_t2` ajoutés à `ransackable_attributes` dans `app/models/acte.rb`.
- Test baseline : `bin/rails test` → 31 runs / 62 assertions / 0 failures / 0 errors.

#### Review Follow-ups (AI) — corrigés en review

- [x] [AI-Review][HIGH] Renommage manquant des partials `_ht2_acte_details*.html.erb` → `_acte_details*.html.erb` (référencés par `show.html.erb:92,94`, `export.html.erb:20`, `export_pdf.html.erb:20`). Cassait `actes#show` en `ActionView::MissingTemplate`.
- [x] [AI-Review][HIGH] Migrations historiques `20250603122756_add_numero_format_to_ht2_acte.rb` et `20250604131307_add_annee_to_ht2_actes.rb` cassaient `db:setup` après suppression de l'alias `Ht2Acte`. Résolution dynamique de la classe via `Object.const_defined?(:Ht2Acte) ? Ht2Acte : Acte`.
- [x] [AI-Review][MEDIUM] Smoke test ajouté dans `test/controllers/actes_controller_test.rb` pour vérifier la présence des partials critiques.
- [x] [AI-Review][LOW] Route `historique_ht2` renommée en `actes_historique` (`config/routes.rb:113`) + helpers `historique_ht2_path` → `actes_historique_path` mis à jour dans `app/views/layouts/_header.html.erb`, `app/views/pages/index.html.erb`, `app/views/actes/historique.html.erb`, `app/views/actes/show.html.erb` (11 occurrences au total).

#### Review Follow-ups (AI) — restant à traiter

- [ ] [AI-Review][LOW] Renommer `user_ht2_stats` → `user_acte_stats` dans `app/controllers/actes_controller.rb:1284` (et call-sites lignes 962-963) pour cohérence post-rename. Hors scope strict mais utile.
- [ ] [AI-Review][LOW] Renommer `@ht2_echeance_courte` / `@ht2_long_delay` dans `app/controllers/pages_controller.rb:32-33` et `app/views/pages/index.html.erb:274,285` (Dev Notes autorisait à les laisser).

### File List

**Fichiers renommés (git mv) — scope Story 1.4 :**
- `app/controllers/ht2_actes_controller.rb` → `app/controllers/actes_controller.rb`
- `app/admin/ht2_actes.rb` → `app/admin/actes.rb`
- `app/views/ht2_actes/` → `app/views/actes/` (dossier entier, 38 fichiers)
- `app/views/actes/_ht2_acte_details.html.erb` → `app/views/actes/_acte_details.html.erb` *(correction review)*
- `app/views/actes/_ht2_acte_details_organisme.html.erb` → `app/views/actes/_acte_details_organisme.html.erb` *(correction review)*
- `test/controllers/ht2_actes_controller_test.rb` → `test/controllers/actes_controller_test.rb`

**Fichiers modifiés — scope Story 1.4 :**
- `config/routes.rb` (resources + routes standalone vers `actes#…`)
- `app/models/acte.rb` (suppression alias `Ht2Acte = Acte` + ajout `titre` / `categorie_t2` à `ransackable_attributes`)
- `app/controllers/suspensions_controller.rb` (`edit_ht2_acte_path` → `edit_acte_path`)
- `app/controllers/organismes_controller.rb` (`includes(:ht2_actes)` → `includes(:actes)`)
- `app/controllers/pages_controller.rb` (`@ht2_actes` → `@actes`)
- `app/controllers/centre_financiers_controller.rb` (call-sites association rename)
- `app/views/pages/index.html.erb` (helpers de route)
- `app/views/suspensions/modal_delete.html.erb` (`ht2_acte_suspension_path` → `acte_suspension_path`)
- `app/views/suspensions/modal_refus_suspension.html.erb` (id.)
- `app/views/centre_financiers/new.html.erb` (`cf.ht2_actes` → `cf.actes`)
- `app/views/organismes/new.html.erb` (`organisme.ht2_actes.size` → `organisme.actes.size`)
- `app/views/layouts/_header.html.erb` (helpers `ht2_actes_path` / `tableau_de_bord_ht2_actes_path` / `synthese_users_ht2_actes_path`)
- `app/jobs/generate_acte_pdf_job.rb` (partials `actes/acte_*_pdf_content`)
- `app/jobs/generate_backup_job.rb` (worksheet name + headers `acte_id`)
- `test/controllers/actes_controller_test.rb` (classe renommée + smoke test partials)

**Fichiers modifiés en review (corrections post-revue) :**
- `db/migrate/20250603122756_add_numero_format_to_ht2_acte.rb` (résolution dynamique `Ht2Acte`/`Acte`)
- `db/migrate/20250604131307_add_annee_to_ht2_actes.rb` (id.)
- `config/routes.rb` (`historique_ht2` → `actes_historique`)
- `app/views/layouts/_header.html.erb`, `app/views/pages/index.html.erb`, `app/views/actes/historique.html.erb`, `app/views/actes/show.html.erb` (helpers `historique_ht2_path` → `actes_historique_path`)

**Modifications hors-scope Story 1.4 (leftover Stories 1.1–1.3, présentes dans la même branche) :**
- Renames BDD : `app/admin/ht2_actes.rb`/`controllers`/`helpers`/`models`/`views`/`test` (déjà inclus ci-dessus mais issus de Story 1.1)
- Modèles ajustés par Story 1.1 : `app/models/centre_financier.rb`, `echeancier.rb`, `organisme.rb`, `poste_ligne.rb`, `programme.rb`, `suspension.rb`, `user.rb`
- ActiveAdmin ajustés par Story 1.1 : `app/admin/echeanciers.rb`, `poste_lignes.rb`, `suspensions.rb`
- `lib/tasks/generate_missing_pdfs.rake` (Story 1.1)
- `app/views/organismes/export.xlsx.axlsx` (Story 1.1)
- `app/models/t2_detail.rb`, `test/fixtures/t2_details.yml`, `test/models/t2_detail_test.rb` (Story 1.2)
- Migrations BDD : `20260512084659_rename_ht2_actes_to_actes.rb` (Story 1.1), `20260512090716_rename_centre_financiers_actes_to_actes_centre_financiers.rb` (Story 1.1 — correction tardive du nommage HABTM), `20260512092104_create_t2_details.rb` (Story 1.2)
- `db/schema.rb` (reflet des migrations Stories 1.1–1.2)

**Documents de planning modifiés :**
- `_bmad-output/planning-artifacts/epics-t2-integration.md` (mise à jour du découpage des stories 1.1/1.3)
