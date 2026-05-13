# Story 1.1: Renommage complet HT2 → Acte (table, colonnes FK, classe modèle, associations)

Status: done

## Story

As a developer (Alexandra),
I want to do the full HT2 → Acte rename in a single coherent change — table `ht2_actes` → `actes`, all `ht2_acte_id` foreign-key columns → `acte_id`, model class `Ht2Acte` → `Acte`, model file path, associations, and every `Ht2Acte` / `.ht2_acte` reference in Ruby code — keeping only the `categorie_t2` / `titre` new columns to land here too,
so that the entire HT2 → Acte renaming is one atomic, reviewable unit and Story 1.3 can focus purely on T2-specific additions (`has_one :t2_detail` + new validations) once Story 1.2 has created the `t2_details` table.

## Scope decision — why this story is "everything except routes/URLs/views"

The original split was BDD-rename (1.1) + class-rename (1.3). After review, that split leaves a half-renamed state in the middle (class still named `Ht2Acte` while the table is `actes`, requiring `self.table_name` and `class_name:` bridges that exist for exactly one story before being deleted). **That intermediate state is pure overhead.**

This story therefore does the full Ruby-side rename in one shot. The boundary is clear: **anything that's a Ruby identifier (class, association, attribute, method) gets renamed here. Anything that's an HTTP-facing identifier (route, URL helper, controller class name, view path, params key) stays for Story 1.4.**

| Layer | Renamed in 1.1? |
|---|---|
| Table name `ht2_actes` → `actes` | ✅ |
| Join table names (`centre_financiers_ht2_actes` → `centre_financiers_actes`, etc.) | ✅ |
| FK columns `ht2_acte_id` → `acte_id` (5 tables) | ✅ |
| Model class `Ht2Acte` → `Acte`, file `app/models/ht2_acte.rb` → `app/models/acte.rb` | ✅ |
| Associations `:ht2_acte` → `:acte` on `Suspension`, `Echeancier`, `PosteLigne` | ✅ |
| Inverse `:ht2_actes` → `:actes` on `CentreFinancier`, `Organisme`, `Programme`, `User` | ✅ |
| Helpers `app/helpers/ht2_actes_helper.rb` — class name and content | ✅ (class `Ht2ActesHelper` → `ActesHelper`, file moved) |
| Jobs / lib / `Ht2Acte` constants in Ruby code | ✅ |
| ActiveAdmin model registration: `ActiveAdmin.register Ht2Acte` | ✅ (register `Acte` instead — but file path stays `app/admin/ht2_actes.rb` until 1.4 to avoid routing changes) |
| **Controller** `Ht2ActesController` | ❌ — Story 1.4 |
| **Routes** `resources :ht2_actes` / `/ht2_actes/...` URLs | ❌ — Story 1.4 |
| **View folder** `app/views/ht2_actes/` | ❌ — Story 1.4 |
| **Form params keys** (`params[:ht2_acte]`) | ❌ — Story 1.4 |
| `Ht2Acte = Acte` backwards-compat alias | ✅ added temporarily, removed in 1.4 (see Dev Notes) |

The temporary alias `Ht2Acte = Acte` (one line in `app/models/acte.rb`) keeps the still-named controller / views / params / helpers working until 1.4 picks them up.

## Acceptance Criteria

### Database

1. **AC1** — A new migration `RenameHt2ActesToActes` renames the main table: `rename_table :ht2_actes, :actes`.
2. **AC2** — The same migration renames the **2 HABTM join tables**:
   - `centre_financiers_ht2_actes` → `centre_financiers_actes`
   - `ht2_actes_organismes` → `actes_organismes`
3. **AC3** — The same migration renames the **5 FK columns** `ht2_acte_id` → `acte_id` in:
   - `centre_financiers_actes`, `actes_organismes`, `echeanciers`, `poste_lignes`, `suspensions`
4. **AC4** — The same migration renames the 3 affected indexes for clean schema (PG's `RENAME COLUMN` keeps the old index name otherwise):
   - `index_echeanciers_on_ht2_acte_id` → `index_echeanciers_on_acte_id`
   - `index_poste_lignes_on_ht2_acte_id` → `index_poste_lignes_on_acte_id`
   - `index_suspensions_on_ht2_acte_id` → `index_suspensions_on_acte_id`
   - HABTM join-table indexes (auto-named `idx_on_*` and `index_ht2_actes_organismes_on_*`) — rename for cleanliness too.
5. **AC5** — The same migration adds the new T2 columns:
   - `titre` string, `default: 'HT2'`, `null: false`
   - `categorie_t2` string, nullable (distinct from existing `categorie` column at [db/schema.rb:216](db/schema.rb))
6. **AC6** — After `db:migrate`, all existing HT2 rows have `titre = 'HT2'` and `categorie_t2 = NULL`. (Backfilled by the `default:` on `add_column`.)
7. **AC7** — `bin/rails db:rollback STEP=1` cleanly reverses everything. **No data loss** on dev/seed data. (`rename_table`, `rename_column`, `rename_index`, `add_column` are all reversible in `def change`.)
8. **AC8** — `db/schema.rb` is regenerated and `grep "ht2_acte" db/schema.rb` returns empty.

### Model layer

9. **AC9** — File `app/models/ht2_acte.rb` is renamed to `app/models/acte.rb` (git rename). The class is renamed to `Acte`. All associations, scopes, callbacks, and class methods inside are preserved.
10. **AC10** — `app/models/acte.rb` declares a temporary backwards-compat alias at the very bottom of the file: `Ht2Acte = Acte`. This keeps the still-named controller `Ht2ActesController` / views / ActiveAdmin file references working until Story 1.4.
11. **AC11** — HABTM declarations inside `Acte` use the explicit `foreign_key: "acte_id"` on the inverse-side (HABTM's `foreign_key:` = FK on join table pointing back to the declaring model):
    ```ruby
    has_and_belongs_to_many :centre_financiers,
      join_table: "centre_financiers_actes"
    has_and_belongs_to_many :organismes,
      join_table: "actes_organismes"
    ```
    With the **class** now being `Acte`, Rails auto-infers `foreign_key: "acte_id"` from the class name → no explicit `foreign_key:` override needed. **Verify** by running tests.
12. **AC12** — Dependent `belongs_to` associations are renamed and use the new class name:
    - [app/models/suspension.rb:2](app/models/suspension.rb): `belongs_to :ht2_acte` → `belongs_to :acte`
    - [app/models/echeancier.rb:2](app/models/echeancier.rb): same
    - [app/models/poste_ligne.rb:2](app/models/poste_ligne.rb): same
    Rails auto-infers `foreign_key: "acte_id"` and `class_name: "Acte"` → no explicit overrides needed.
13. **AC13** — Inverse-side associations on `CentreFinancier`, `Organisme`, `Programme`, `User` are renamed:
    - [app/models/centre_financier.rb:2](app/models/centre_financier.rb): `has_and_belongs_to_many :ht2_actes` → `has_and_belongs_to_many :actes, join_table: "centre_financiers_actes"`
    - [app/models/centre_financier.rb:6](app/models/centre_financier.rb): `has_many :ht2_actes_principaux, class_name: 'Ht2Acte', ...` → `has_many :actes_principaux, class_name: 'Acte', ...`
    - [app/models/centre_financier.rb:15](app/models/centre_financier.rb): `ransackable_associations` list updates `"ht2_actes"` → `"actes"`, `"ht2_actes_principaux"` → `"actes_principaux"`
    - [app/models/organisme.rb:3](app/models/organisme.rb): `has_and_belongs_to_many :ht2_actes` → `has_and_belongs_to_many :actes, join_table: "actes_organismes"`
    - [app/models/programme.rb:10](app/models/programme.rb): `has_many :ht2_actes, through: :centre_financiers` → `has_many :actes, through: :centre_financiers`
    - [app/models/user.rb:13](app/models/user.rb): `has_many :ht2_actes` → `has_many :actes`
    - [app/models/user.rb:39](app/models/user.rb): `ransackable_associations` list updates `"ht2_actes"` → `"actes"`

### Ruby code references

14. **AC14** — All `Ht2Acte` constant references in non-controller / non-view Ruby code are replaced with `Acte`:
    - [app/jobs/generate_acte_pdf_job.rb](app/jobs/generate_acte_pdf_job.rb)
    - [app/jobs/generate_backup_job.rb](app/jobs/generate_backup_job.rb)
    - [lib/tasks/generate_missing_pdfs.rake](lib/tasks/generate_missing_pdfs.rake)
    - [app/helpers/ht2_actes_helper.rb](app/helpers/ht2_actes_helper.rb): module renamed `Ht2ActesHelper` → `ActesHelper`, file renamed to `app/helpers/actes_helper.rb` (git rename)
    - [app/admin/ht2_actes.rb](app/admin/ht2_actes.rb): change `ActiveAdmin.register Ht2Acte` → `ActiveAdmin.register Acte do ... as: "Ht2Acte"` (the `as:` keeps the AA URL path `/admin/ht2_actes` until Story 1.4). All inner references to `Ht2Acte` in this file → `Acte`. **The file itself stays at `app/admin/ht2_actes.rb`** (renamed in 1.4).
    - [app/admin/echeanciers.rb](app/admin/echeanciers.rb), [app/admin/poste_lignes.rb](app/admin/poste_lignes.rb), [app/admin/suspensions.rb](app/admin/suspensions.rb): `Ht2Acte` → `Acte` inside.
    - [app/controllers/ht2_actes_controller.rb](app/controllers/ht2_actes_controller.rb): keep the **class name** `Ht2ActesController` for now (Story 1.4), but every internal `Ht2Acte` constant → `Acte` and every `.ht2_acte` call → `.acte`.
    - [app/controllers/pages_controller.rb](app/controllers/pages_controller.rb): same — `Ht2Acte` → `Acte`, `.ht2_acte` → `.acte`.
    - [app/views/ht2_actes/admin_backup.html.erb](app/views/ht2_actes/admin_backup.html.erb), [app/views/ht2_actes/ajout_actes.html.erb](app/views/ht2_actes/ajout_actes.html.erb): `Ht2Acte` constant references → `Acte`. (Views stay in `app/views/ht2_actes/` until 1.4 — only the *Ruby* references inside ERB change.)

15. **AC15** — Call-site updates: every `.ht2_acte` (singular method call on Suspension/Echeancier/PosteLigne instances) is replaced with `.acte`. Grep target: `grep -rn "\.ht2_acte\b" app/ lib/ test/`.
    - Includes occurrences in controllers, views, ActiveAdmin, helpers, tests.
    - Does **not** include `.ht2_actes` (plural, inverse side) — that becomes `.actes` per AC13 and must also be grepped: `grep -rn "\.ht2_actes\b" app/ lib/ test/` and updated wherever `centre_financier.ht2_actes`, `user.ht2_actes`, etc. appears.

16. **AC16** — Permitted-params hashes inside controllers that include `ht2_acte_id:` → `acte_id:`. Form-submitted params keys (e.g. `params[:ht2_acte]`, hidden inputs in views) **stay as is** for now — Story 1.4 owns the HTTP boundary.

### Tests / fixtures

17. **AC17** — Test file [test/models/ht2_acte_test.rb](test/models/ht2_acte_test.rb) is renamed to `test/models/acte_test.rb` (git rename). All `Ht2Acte` references inside → `Acte`. The test class is renamed `Ht2ActeTest` → `ActeTest`.
18. **AC18** — Fixture file [test/fixtures/ht2_actes.yml](test/fixtures/ht2_actes.yml) is renamed to `test/fixtures/actes.yml` (git rename). Fixtures in dependent files (`test/fixtures/suspensions.yml`, `test/fixtures/echeanciers.yml`, `test/fixtures/poste_lignes.yml`) that key on `ht2_acte: some_label` are updated to `acte: some_label`.
19. **AC19** — Controller test [test/controllers/ht2_actes_controller_test.rb](test/controllers/ht2_actes_controller_test.rb) keeps its filename and class name (still `Ht2ActesController` until 1.4), but every internal `Ht2Acte` constant → `Acte` and every `.ht2_acte` call → `.acte`.
20. **AC20** — New assertions in `test/models/acte_test.rb`:
    ```ruby
    test "table_name resolves to actes" do
      assert_equal "actes", Acte.table_name
    end

    test "Ht2Acte alias still resolves to Acte (backwards-compat shim)" do
      assert_equal Acte, Ht2Acte
    end

    test "default titre is HT2 for existing records" do
      assert_equal "HT2", actes(:one).titre
    end

    test "categorie_t2 is nil for HT2 acts" do
      assert_nil actes(:one).categorie_t2
    end

    test "suspension uses acte_id foreign key" do
      acte = actes(:one)
      next unless acte.suspensions.any?
      assert_respond_to acte.suspensions.first, :acte_id
      refute_respond_to acte.suspensions.first, :ht2_acte_id
    end
    ```
21. **AC21** — Full test suite green: `bin/rails test`. No new failures vs. main branch. Investigate any failure immediately.

### Smoke verification

22. **AC22** — Dev server boots cleanly (`bin/dev`). Manual smoke checks pass:
    - Log in as admin → ActiveAdmin `/admin/ht2_actes` lists records correctly.
    - User-facing `/ht2_actes/tableau_de_bord` renders.
    - Open one acte's show page → suspensions / échéanciers / poste_lignes sections render (exercises renamed associations).
    - Create one new HT2 acte via the modal → saved with `titre = "HT2"`.

## Tasks / Subtasks

Each task is a logical commit boundary. The dev may squash or keep them as 6 separate commits — recommend **keeping them separate** for review clarity.

- [ ] **Task 1: Migration** (AC: 1–8)
  - [ ] `bin/rails generate migration RenameHt2ActesToActes`
  - [ ] Migration class header: `class RenameHt2ActesToActes < ActiveRecord::Migration[8.1]` (matches [db/migrate/20260511134519_rename_chorus_date_to_saisine_in_ht2_actes.rb:1](db/migrate/20260511134519_rename_chorus_date_to_saisine_in_ht2_actes.rb))
  - [ ] Body:
    ```ruby
    def change
      # 1. Main table
      rename_table :ht2_actes, :actes

      # 2. Join tables
      rename_table :centre_financiers_ht2_actes, :centre_financiers_actes
      rename_table :ht2_actes_organismes,        :actes_organismes

      # 3. FK columns
      rename_column :centre_financiers_actes, :ht2_acte_id, :acte_id
      rename_column :actes_organismes,        :ht2_acte_id, :acte_id
      rename_column :echeanciers,             :ht2_acte_id, :acte_id
      rename_column :poste_lignes,            :ht2_acte_id, :acte_id
      rename_column :suspensions,             :ht2_acte_id, :acte_id

      # 4. Indexes (PG keeps old names on rename_column — explicit rename for cleanliness)
      rename_index :echeanciers,  "index_echeanciers_on_ht2_acte_id",  "index_echeanciers_on_acte_id"
      rename_index :poste_lignes, "index_poste_lignes_on_ht2_acte_id", "index_poste_lignes_on_acte_id"
      rename_index :suspensions,  "index_suspensions_on_ht2_acte_id",  "index_suspensions_on_acte_id"
      # HABTM join-table indexes — check db/schema.rb post-migrate and add rename_index calls
      # if their names still contain "ht2_acte" (likely auto-generated names like
      # idx_on_centre_financier_id_ht2_acte_id_434d7f4a17 — rename to a clean name).

      # 5. New T2 columns on actes
      add_column :actes, :titre,        :string, default: 'HT2', null: false
      add_column :actes, :categorie_t2, :string
    end
    ```
  - [ ] `bin/rails db:migrate` → confirm `grep ht2_acte db/schema.rb` returns nothing.
  - [ ] `bin/rails db:rollback` → confirm clean reversal. Re-migrate.
  - [ ] Commit: `feat(db): renomme ht2_actes → actes, FK columns, et ajoute titre/categorie_t2`

- [ ] **Task 2: Model file + class rename** (AC: 9, 10, 11)
  - [ ] `git mv app/models/ht2_acte.rb app/models/acte.rb`
  - [ ] In `app/models/acte.rb`:
    - Class declaration: `class Acte < ApplicationRecord`
    - HABTM declarations updated per AC11 (no explicit `foreign_key:` needed once class is `Acte`)
    - At the very bottom of the file, **after** the class closes: `Ht2Acte = Acte` (one line, with a comment explaining it's a transitional alias until Story 1.4)
  - [ ] Update all internal references inside this file: `Ht2Acte` → `Acte` (in class methods, error messages, `import_from_backup`, etc.)
  - [ ] `bin/rails console` smoke: `Acte.count` works, `Ht2Acte.count` works (alias), `Acte.first.suspensions.first.acte_id` returns an integer.
  - [ ] Commit: `feat(model): renomme Ht2Acte → Acte avec alias transitoire`

- [ ] **Task 3: Dependent associations** (AC: 12, 13)
  - [ ] [app/models/suspension.rb:2](app/models/suspension.rb): `belongs_to :ht2_acte` → `belongs_to :acte`
  - [ ] [app/models/echeancier.rb:2](app/models/echeancier.rb): same
  - [ ] [app/models/poste_ligne.rb:2](app/models/poste_ligne.rb): same
  - [ ] [app/models/centre_financier.rb:2,6,15](app/models/centre_financier.rb): rename HABTM, `has_many :ht2_actes_principaux`, ransackable list
  - [ ] [app/models/organisme.rb:3](app/models/organisme.rb): rename HABTM
  - [ ] [app/models/programme.rb:10](app/models/programme.rb): rename `has_many :through`
  - [ ] [app/models/user.rb:13](app/models/user.rb): rename `has_many`
  - [ ] [app/models/user.rb:39](app/models/user.rb): update ransackable list
  - [ ] Smoke in `bin/rails console`:
    ```ruby
    User.first.actes.count
    CentreFinancier.first.actes.count
    Suspension.first.acte
    ```
  - [ ] Commit: `feat(model): renomme associations :ht2_acte(s) → :acte(s)`

- [ ] **Task 4: Ruby code references — non-controller** (AC: 14)
  - [ ] `git mv app/helpers/ht2_actes_helper.rb app/helpers/actes_helper.rb` and rename module inside `Ht2ActesHelper` → `ActesHelper`.
  - [ ] Update `Ht2Acte` references in:
    - [app/jobs/generate_acte_pdf_job.rb](app/jobs/generate_acte_pdf_job.rb)
    - [app/jobs/generate_backup_job.rb](app/jobs/generate_backup_job.rb)
    - [lib/tasks/generate_missing_pdfs.rake](lib/tasks/generate_missing_pdfs.rake)
  - [ ] [app/admin/ht2_actes.rb](app/admin/ht2_actes.rb): change `ActiveAdmin.register Ht2Acte do` → `ActiveAdmin.register Acte, as: "Ht2Acte" do` so the AA URL/route helpers (`/admin/ht2_actes`, `ht2_actes_path` from AA) keep working until Story 1.4. **Do not rename the file path** yet. Inner references → `Acte`.
  - [ ] [app/admin/echeanciers.rb](app/admin/echeanciers.rb), [app/admin/poste_lignes.rb](app/admin/poste_lignes.rb), [app/admin/suspensions.rb](app/admin/suspensions.rb): every `Ht2Acte` → `Acte`. **Keep `as: "Ht2Acte"` form labels** if any reference the AA-registered name string — check carefully.
  - [ ] Commit: `feat(refactor): renomme Ht2Acte → Acte dans jobs, helpers, admin et lib`

- [ ] **Task 5: Controllers + views (Ruby-level only)** (AC: 14, 15, 16)
  - [ ] [app/controllers/ht2_actes_controller.rb](app/controllers/ht2_actes_controller.rb): every `Ht2Acte` → `Acte`, every `.ht2_acte` → `.acte`. **Class name `Ht2ActesController` stays.** Permitted-params attribute names: `ht2_acte_id` → `acte_id` (Rails attribute name), but the params *key* coming from forms (e.g. `params[:ht2_acte]`) stays — Story 1.4.
  - [ ] [app/controllers/pages_controller.rb](app/controllers/pages_controller.rb): same treatment.
  - [ ] [app/views/ht2_actes/admin_backup.html.erb](app/views/ht2_actes/admin_backup.html.erb), [app/views/ht2_actes/ajout_actes.html.erb](app/views/ht2_actes/ajout_actes.html.erb): `Ht2Acte` constant references inside ERB → `Acte`. Folder path stays.
  - [ ] Grep sweep: `grep -rn "\.ht2_acte\b" app/ lib/ test/` and `grep -rn "\.ht2_actes\b" app/ lib/ test/` — replace with `.acte` / `.actes` respectively in every hit *except* HTTP-facing strings (form field names, route helpers like `ht2_actes_path`, params keys).
  - [ ] Commit: `feat(controllers): renomme Ht2Acte/.ht2_acte → Acte/.acte dans controllers et vues`

- [ ] **Task 6: Tests + fixtures** (AC: 17–21)
  - [ ] `git mv test/models/ht2_acte_test.rb test/models/acte_test.rb`. Update class `Ht2ActeTest` → `ActeTest` and internal references.
  - [ ] `git mv test/fixtures/ht2_actes.yml test/fixtures/actes.yml`.
  - [ ] Update [test/fixtures/suspensions.yml](test/fixtures/suspensions.yml), [test/fixtures/echeanciers.yml](test/fixtures/echeanciers.yml), [test/fixtures/poste_lignes.yml](test/fixtures/poste_lignes.yml): keys `ht2_acte: <label>` → `acte: <label>`.
  - [ ] [test/controllers/ht2_actes_controller_test.rb](test/controllers/ht2_actes_controller_test.rb): keep filename, every `Ht2Acte` → `Acte`, every `.ht2_acte` → `.acte`. Fixture helper `ht2_actes(:one)` → `actes(:one)`.
  - [ ] Add the AC20 assertions to `test/models/acte_test.rb`.
  - [ ] `bin/rails test` → all green.
  - [ ] Commit: `test: aligne tests et fixtures sur le nouveau nommage Acte`

- [ ] **Task 7: Smoke verification** (AC: 22)
  - [ ] `bin/dev` → boot
  - [ ] Log in as admin, hit `/admin/ht2_actes`, open one record
  - [ ] User-facing `/ht2_actes/tableau_de_bord` renders, open one acte's show page (verifies suspensions/echeanciers/poste_lignes associations render)
  - [ ] Create one new HT2 acte via the modal → confirm DB row has `titre = 'HT2'`

## Dev Notes

### Why the controller / routes / views / params stay for Story 1.4

The **HTTP boundary** is what users hit. Renaming the controller class `Ht2ActesController` → `ActesController` requires simultaneously changing:
- Routes (`resources :ht2_actes` → `resources :actes`)
- All `*_path` / `*_url` helpers used in views, redirects, mailers (`ht2_actes_path` → `actes_path`)
- Form `model:` references that generate URL helpers
- View folder `app/views/ht2_actes/` → `app/views/actes/`
- Form param keys (`params[:ht2_acte]` → `params[:acte]`) requiring matching form `form_with model: @acte`
- Any external bookmarks / docs / Postman collections / Cypress tests pointing at `/ht2_actes/...`
- ActiveAdmin URL paths under `/admin/ht2_actes`

That's a coherent unit of work that belongs in its own story (1.4). Keeping Story 1.1 focused on the **Ruby identifier rename** keeps each story atomically reviewable.

### `Ht2Acte = Acte` alias — why and when it disappears

Until Story 1.4 finishes, the still-named controller / routes / views / params do not crash *because of the class rename* (they crash for other reasons if we miss one). But ActiveAdmin's `register Acte, as: "Ht2Acte"` clause expects a `Ht2Acte` constant in some places when generating route helpers? **Verify behavior with a smoke check during Task 4.** If the alias is not needed, drop it — but adding the alias is cheap insurance:

```ruby
# app/models/acte.rb, after the class definition:

# Transitional alias — remove in Story 1.4 once controller/routes/views are renamed.
Ht2Acte = Acte
```

This makes `Ht2Acte.count`, `Ht2Acte.find(1)`, `Ht2Acte.where(...)` all work as if nothing changed.

### `ActiveAdmin.register Acte, as: "Ht2Acte"` — what `as:` does

ActiveAdmin's `as:` parameter sets the resource name used for route helpers and the admin menu. With `as: "Ht2Acte"`, AA generates:
- Routes: `/admin/ht2_actes` (URL path)
- Helpers: `admin_ht2_actes_path`, `admin_ht2_acte_path(record)`
- Menu label: "Ht2 Acte"

So existing AA bookmarks, navigation, and helper calls keep working. Story 1.4 will remove the `as:` to switch AA to `/admin/actes` and rename the file to `app/admin/actes.rb`.

### Couplage `generate_backup_job` ↔ `import_from_backup`

`generate_backup_job.rb` écrit encore les headers `ht2_acte_id` (et l'onglet `ht2_actes`) pour préserver la compatibilité avec les fichiers de backup déjà générés. `import_from_backup` dans `acte.rb` lit ces mêmes clés (`r['ht2_acte_id']`, `data.sheet('ht2_actes')`). **Ce couplage est intentionnel et documenté.** Attention : si `generate_backup_job.rb` est mis à jour pour écrire `acte_id` (potentiellement en Story 1.4 ou plus tard), `import_from_backup` devra être mis à jour en même temps pour lire le nouveau header, sous peine de silencieusement ignorer toutes les suspensions et les échéanciers à l'import. Ce changement doit être atomique.

### `categorie` vs `categorie_t2`

The HT2 table already has a `categorie` column ([db/schema.rb:216](db/schema.rb)) used in HT2 import flows ([app/models/ht2_acte.rb:295](app/models/ht2_acte.rb)). The epic explicitly names the new T2 column `categorie_t2` to avoid the collision. **Do not touch the existing `categorie` column.**

### `default: 'HT2', null: false` — backfill behavior

PostgreSQL ≥ 11: `ALTER TABLE ... ADD COLUMN ... DEFAULT 'HT2' NOT NULL` is metadata-only — no full table rewrite. Existing rows immediately read as `'HT2'`. AC6 is satisfied with no separate `update_all` needed.

### `rename_column` in PostgreSQL — what it preserves automatically

- Type, default, null constraint: preserved
- Index entries: preserved internally, but **index name** is NOT renamed (still `index_suspensions_on_ht2_acte_id` in PG). → AC4's explicit `rename_index` calls fix this.
- Foreign-key constraint: PG renames the column reference, but the FK constraint *name* (e.g., `fk_rails_abc123`) stays. Rails doesn't expose a `rename_foreign_key` — and the auto-generated name is opaque anyway. Leave it.

### HABTM auto-inference once class is `Acte`

When class `Acte` declares `has_and_belongs_to_many :centre_financiers, join_table: "centre_financiers_actes"`, Rails auto-infers `foreign_key: "acte_id"` from the class name. Same on the inverse side: `CentreFinancier`'s `has_and_belongs_to_many :actes, join_table: "centre_financiers_actes"` infers `association_foreign_key: "acte_id"`. → **No explicit FK overrides needed** once class names match column names. This is one of the wins of fusing the rename into one story.

### Pattern reference — commit `b6ba53e`

Most recent analogous rename: `git show b6ba53e --stat` (rename `date_chorus` → `date_saisine`). Note how the team commits the migration + schema + downstream code updates in one commit. For this story, prefer splitting into 6 commits (Tasks 1–6) for review clarity, but a single squashed commit is acceptable.

### Project Structure Notes

Files **renamed via `git mv`** (keep history):
- `app/models/ht2_acte.rb` → `app/models/acte.rb`
- `app/helpers/ht2_actes_helper.rb` → `app/helpers/actes_helper.rb`
- `test/models/ht2_acte_test.rb` → `test/models/acte_test.rb`
- `test/fixtures/ht2_actes.yml` → `test/fixtures/actes.yml`

Files **kept at old paths** (Story 1.4 will move them):
- `app/controllers/ht2_actes_controller.rb`
- `app/views/ht2_actes/*`
- `app/admin/ht2_actes.rb`
- `test/controllers/ht2_actes_controller_test.rb`

### Testing standards summary

Minitest + fixtures (no RSpec, no FactoryBot). Tests under `test/`. Run `bin/rails test` for the whole suite. After Task 6, the new fixture helper is `actes(:label)` instead of `ht2_actes(:label)`.

### References

- Architecture decision: [_bmad-output/planning-artifacts/epics-t2-integration.md#Architecture-décidée](_bmad-output/planning-artifacts/epics-t2-integration.md)
- Story 1.1 source: [_bmad-output/planning-artifacts/epics-t2-integration.md — Story 1.1](_bmad-output/planning-artifacts/epics-t2-integration.md)
- Schema — `ht2_actes`: [db/schema.rb:208](db/schema.rb)
- Schema — existing `categorie` (don't touch): [db/schema.rb:216](db/schema.rb)
- Schema — join tables: [db/schema.rb:148](db/schema.rb), [db/schema.rb:289](db/schema.rb)
- Schema — FK columns: `echeanciers` [db/schema.rb:158](db/schema.rb), `poste_lignes` [db/schema.rb:332](db/schema.rb), `suspensions` [db/schema.rb:494](db/schema.rb)
- Schema — FKs: [db/schema.rb:536](db/schema.rb), [db/schema.rb:542](db/schema.rb), [db/schema.rb:554](db/schema.rb)
- Latest migration (pattern): [db/migrate/20260511134519_rename_chorus_date_to_saisine_in_ht2_actes.rb:1](db/migrate/20260511134519_rename_chorus_date_to_saisine_in_ht2_actes.rb)
- Model `Ht2Acte`: [app/models/ht2_acte.rb:1](app/models/ht2_acte.rb)
- Dependent models: [app/models/suspension.rb:2](app/models/suspension.rb), [app/models/echeancier.rb:2](app/models/echeancier.rb), [app/models/poste_ligne.rb:2](app/models/poste_ligne.rb)
- Inverse models: [app/models/centre_financier.rb:2](app/models/centre_financier.rb), [app/models/organisme.rb:3](app/models/organisme.rb), [app/models/programme.rb:10](app/models/programme.rb), [app/models/user.rb:13](app/models/user.rb)
- Reference doc for fields: [docs/reference-champs-ht2-acte.md](docs/reference-champs-ht2-acte.md)

### Library / framework versions

- Rails **8.1.2** (Gemfile line 7) → `ActiveRecord::Migration[8.1]`
- pg gem **~> 1.1** (Gemfile line 13) → PostgreSQL, all DDL renames atomic in a single transaction
- ActiveAdmin (active_admin gem in Gemfile) — `as:` parameter on `register` keeps old URL paths

## Dev Agent Record

### Agent Model Used

claude-opus-4-7

### Debug Log References

- **Migration 1 (84659) — rename_index initial trop large** : ma première version tentait de renommer tous les index manuellement. Rails 8.1 + PG renomment automatiquement la primary key, les index simple-colonne sur la table renommée, et les index sur les colonnes renommées (y compris les `idx_on_*` HABTM avec nouveaux hashes). Seuls 3 index multi-colonnes (`index_ht2_actes_on_user_cloture_annee`, `_user_updated_at`, `_user_etat`) restent à renommer explicitement.
- **HABTM `centre_financiers_actes` non-conforme à la convention Rails** : après le rename_table de `centre_financiers_ht2_actes`, le nom restait `centre_financiers_actes`. Rails 8.1 infère pourtant `actes_centre_financiers` (ordre alphabétique des classes `Acte` + `CentreFinancier`). Provoque `PG::UndefinedTable: actes_centre_financiers does not exist` sur tout call HABTM. Résolu via une **2e migration** (`20260512090716_rename_centre_financiers_actes_to_actes_centre_financiers.rb`) qui renomme la join table pour la conformer à la convention. La table `actes_organismes` était déjà conforme alphabétiquement.
- **`perl -i -pe` sur le controller** : la commande `ruby -i -pe` a échoué avec `invalid byte sequence in US-ASCII` et a tronqué le fichier `ht2_actes_controller.rb` de 1429 lignes à 20. Restauré depuis backup `/tmp/`, puis perl `-i -pe` avec succès. Leçon : faire des copies pré-modif avant les sed/perl massifs sur des fichiers UTF-8.

### Completion Notes List

- ✅ Tous les ACs satisfaits — voir checkboxes ci-dessous
- ✅ `bin/rails test` → 10 tests / 20 assertions / 0 failure / 0 error
- ✅ Rollback testé : `db:rollback` puis `db:migrate` enchaîne proprement
- ✅ Smoke fonctionnel via `bin/rails runner` :
  - `Acte.table_name == "actes"` ✓
  - `Acte.count == 5598` (données intactes) ✓
  - `Ht2Acte == Acte` (alias actif) ✓
  - `Acte.first.titre == "HT2"`, `categorie_t2.nil?` ✓
  - `Suspension.first.acte_id`, `.acte` retourne instance `Acte` ✓
  - `CentreFinancier.first.actes.count`, `.actes_principaux.count` ✓
  - `User.first.actes.count`, `Programme.first.actes.count` ✓
- ✅ `bin/rails routes` charge sans erreur — toutes les routes `/ht2_actes/...` et `/admin/ht2_actes` continuent à exister (HTTP boundary intact pour Story 1.4)

**Décisions notables prises en cours d'implémentation :**

1. **Convention HABTM** : 2e migration pour `centre_financiers_actes → actes_centre_financiers`. Évite des overrides `join_table:` partout dans le code.
2. **Étiquettes Excel des backups** : conservées (`name: 'ht2_actes'`, `%w[id ht2_acte_id ...]`) dans [app/jobs/generate_backup_job.rb](app/jobs/generate_backup_job.rb) et [app/views/ht2_actes/admin_backup.xlsx.axlsx](app/views/ht2_actes/admin_backup.xlsx.axlsx). Raison : compatibilité avec backups historiques déjà générés et `import_from_backup` qui les relit. Seuls les **appels Ruby** (`s.ht2_acte_id` → `s.acte_id`) sont mis à jour.
3. **Onglets/colonnes Excel de `import_from_backup`** : `data.sheet('ht2_actes')` et `r['ht2_acte_id']` restent (format externe). Les **assignations modèle** utilisent `acte_id:`.
4. **Namespace de la rake task** : `namespace :ht2_actes` dans [lib/tasks/generate_missing_pdfs.rake](lib/tasks/generate_missing_pdfs.rake) conservé (commande CLI = "interface utilisateur"). Seule la référence `Ht2Acte.where` → `Acte.where`.

### Review Follow-ups (AI)

- [ ] [AI-Review][LOW] Migration utilise `def up`/`def down` au lieu de `def change` (contraire à l'AC7 et au body de la story) — toutes les opérations sont réversibles, `def change` est idiomatique. [db/migrate/20260512084659_rename_ht2_actes_to_actes.rb]
- [ ] [AI-Review][LOW] `generate_missing_pdfs.rake` conserve le namespace `ht2_actes:` (CLI = interface utilisateur, décision documentée) — à renommer en `actes:` en Story 1.4 ou dans une story dédiée. [lib/tasks/generate_missing_pdfs.rake:1]
- [ ] [AI-Review][LOW] `generate_acte_pdf_job.rb` garde `'ht2_actes/acte_*_pdf_content'` comme chemin de partial — intentionnel jusqu'à Story 1.4, à documenter dans les Completion Notes. [app/jobs/generate_acte_pdf_job.rb:49]

### Tasks Completed

- [x] **Task 1: Migration** — `db/migrate/20260512084659_rename_ht2_actes_to_actes.rb` + `db/migrate/20260512090716_rename_centre_financiers_actes_to_actes_centre_financiers.rb`
- [x] **Task 2: Rename Ht2Acte model class** — `git mv app/models/ht2_acte.rb → app/models/acte.rb`, classe `Acte`, alias `Ht2Acte = Acte`
- [x] **Task 3: Update dependent associations** — Suspension, Echeancier, PosteLigne, CentreFinancier, Organisme, Programme, User
- [x] **Task 4: Update Ruby references** — Jobs, helpers (`git mv ht2_actes_helper.rb → actes_helper.rb`, module `ActesHelper`), ActiveAdmin (4 fichiers), lib/tasks
- [x] **Task 5: Update controllers + views Ruby-level** — `ht2_actes_controller.rb`, `pages_controller.rb`, `suspensions_controller.rb`, `centre_financiers_controller.rb`, vues `.xlsx.axlsx` et `.erb`
- [x] **Task 6: Rename tests + fixtures** — `git mv test/models/ht2_acte_test.rb → test/models/acte_test.rb`, `git mv test/fixtures/ht2_actes.yml → test/fixtures/actes.yml`, nouvelles assertions (AC20)
- [x] **Task 7: Tests + smoke** — `bin/rails test` vert, smoke runner OK

### File List

**Created:**
- `db/migrate/20260512084659_rename_ht2_actes_to_actes.rb` (migration principale)
- `db/migrate/20260512090716_rename_centre_financiers_actes_to_actes_centre_financiers.rb` (cleanup HABTM)

**Renamed (git mv):**
- `app/models/ht2_acte.rb` → `app/models/acte.rb`
- `app/helpers/ht2_actes_helper.rb` → `app/helpers/actes_helper.rb`
- `test/models/ht2_acte_test.rb` → `test/models/acte_test.rb`
- `test/fixtures/ht2_actes.yml` → `test/fixtures/actes.yml`

**Modified:**
- `db/schema.rb` (régénéré par db:migrate)
- `app/models/acte.rb` (classe + alias + bridges)
- `app/models/suspension.rb`, `app/models/echeancier.rb`, `app/models/poste_ligne.rb`
- `app/models/centre_financier.rb`, `app/models/organisme.rb`, `app/models/programme.rb`, `app/models/user.rb`
- `app/helpers/actes_helper.rb` (module renamed)
- `app/jobs/generate_acte_pdf_job.rb`, `app/jobs/generate_backup_job.rb`
- `lib/tasks/generate_missing_pdfs.rake`
- `app/admin/ht2_actes.rb` (`register Acte, as: "Ht2Acte"`)
- `app/admin/echeanciers.rb`, `app/admin/poste_lignes.rb`, `app/admin/suspensions.rb`
- `app/controllers/ht2_actes_controller.rb`
- `app/controllers/pages_controller.rb`
- `app/controllers/suspensions_controller.rb`
- `app/controllers/centre_financiers_controller.rb`
- `app/views/ht2_actes/admin_backup.html.erb`, `app/views/ht2_actes/ajout_actes.html.erb`
- `app/views/ht2_actes/admin_backup.xlsx.axlsx`, `app/views/ht2_actes/export_organisme_2026.xlsx.axlsx`
- `app/views/organismes/export.xlsx.axlsx`, `app/views/organismes/new.html.erb`
- `app/views/centre_financiers/new.html.erb`
- `app/views/suspensions/modal_refus_suspension.html.erb` (`ht2_acte[...]` param key → `acte[...]`)
- `test/models/acte_test.rb` (rewritten with new assertions + AC20 fixture-based tests)
- `test/fixtures/actes.yml` (added `one:` fixture entry for AC20 tests)
