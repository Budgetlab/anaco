# Story 1.2: Create the `t2_details` table

Status: done

## Story

As a developer (Alexandra),
I want to create the `t2_details` table with all T2-specific fields via a single reversible migration,
so that the T2 data model foundation is in place and Stories 1.3+ can add the `has_one :t2_detail` association and form logic on top of a complete schema.

## Acceptance Criteria

### AC1 — Migration exists and runs cleanly

A migration `CreateT2Details` is generated and runs without error:

```
bin/rails db:migrate
```

After migration, `db/schema.rb` contains a `t2_details` table.

### AC2 — Table structure: identification / FK

The table contains:

| Column | Type | Constraints |
|--------|------|-------------|
| `acte_id` | bigint (references actes) | null: false, FK |
| `created_at` | datetime | null: false |
| `updated_at` | datetime | null: false |

A unique index on `acte_id` enforces the one-to-one relationship.

### AC3 — Table structure: Section Annexe financière (concours / RH)

| Column | Type | Constraints |
|--------|------|-------------|
| `effectifs` | float | nullable |
| `effectifs_complementaire` | float | nullable |
| `corps` | string | nullable |
| `grade` | string[] (PostgreSQL array) | nullable, default: [] |
| `date_arrete_concours` | date | nullable |
| `date_effet_acte` | string | nullable |
| `impact_schema_emplois` | boolean | nullable |
| `impact_autre_cbcm` | boolean | nullable |

### AC4 — Table structure: Section ISP

| Column | Type | Constraints |
|--------|------|-------------|
| `isp_cercle1` | boolean | nullable |
| `isp_cercle1_natures` | string[] (array) | nullable, default: [] |
| `isp_cercle1_montant` | decimal | nullable |
| `isp_cercle1_enveloppe_sgg` | decimal | nullable |
| `isp_cercle1_consommation` | decimal | nullable |
| `isp_cercle2` | boolean | nullable |
| `isp_cercle2_natures` | string[] (array) | nullable, default: [] |
| `isp_cercle2_montant` | decimal | nullable |
| `isp_cercle2_enveloppe_sgg` | decimal | nullable |
| `isp_cercle2_consommation` | decimal | nullable |

### AC5 — Table structure: Section Fongibilité asymétrique

| Column | Type | Constraints |
|--------|------|-------------|
| `fa_technique` | boolean | nullable |
| `enveloppe_abondee` | string | nullable |
| `accord_rffim` | boolean | nullable |
| `sollicitation_db` | string | nullable |
| `avis_cbcm` | boolean | nullable |

### AC6 — Table structure: Section Mesure transversale

| Column | Type | Constraints |
|--------|------|-------------|
| `perimetre_mesure` | string[] (array) | nullable, default: [] |
| `statut_agents` | string | nullable |
| `impact_financier_n1` | decimal | nullable |
| `origine_financement` | string[] (array) | nullable, default: [] |

Note: `origine_financement` is shared with Section Enveloppe limitative — single column covers both natures.

### AC7 — Table structure: Section Enveloppe limitative

| Column | Type | Constraints |
|--------|------|-------------|
| `montant_enveloppe_n1` | decimal | nullable |
| `impact_maximal_sans_enveloppe` | decimal | nullable |

(`origine_financement` already listed in AC6.)

### AC8 — Table structure: Section Référentiel

| Column | Type | Constraints |
|--------|------|-------------|
| `referentiel_type` | string | nullable |

Allowed values (enforced at model level in Story 1.3): `'interministeriel'` | `'autre'`.

### AC9 — Table structure: Contrôles RH communs T2 (étape 2)

| Column | Type | Constraints |
|--------|------|-------------|
| `inscription_pap` | boolean | nullable |
| `respect_plafond_emplois` | boolean | nullable |
| `respect_schema_emplois` | boolean | nullable |
| `controle_modalites` | boolean | nullable |
| `respect_enveloppe` | boolean | nullable |
| `risque_reconventionnel` | boolean | nullable |

Note: `consommation_credits` is NOT duplicated here — it is reused from `actes.consommation_credits` (already present in `db/schema.rb:33`).

### AC10 — Foreign key and index

- A database-level foreign key `t2_details.acte_id → actes.id` is declared.
- A unique index on `t2_details.acte_id` enforces the 1:1 relationship at the DB level.

### AC11 — Rollback is clean

`bin/rails db:rollback STEP=1` fully reverses the migration without error. Re-migrating works. No data loss.

### AC12 — Schema reflects the table

After `bin/rails db:migrate`, `db/schema.rb` contains the full `t2_details` table definition. Running `grep "t2_detail" db/schema.rb` returns results.

### AC13 — No regression on existing test suite

`bin/rails test` passes with no new failures. The migration does not touch the `actes` table or any existing table.

## Tasks / Subtasks

- [x] **Task 1: Generate and write migration** (AC: 1, 2–9, 10, 11, 12)
  - [x] `bin/rails generate migration CreateT2Details`
  - [x] Replace generated body with full column list (see Dev Notes below for exact migration body)
  - [x] `bin/rails db:migrate`
  - [x] Verify: `grep "t2_detail" db/schema.rb` returns the table definition
  - [x] `bin/rails db:rollback STEP=1` — confirm clean reversal, then re-migrate
  - [x] Commit: `feat(db): crée la table t2_details avec tous les champs T2`

- [x] **Task 2: Create the `T2Detail` model** (AC: 10)
  - [x] Create `app/models/t2_detail.rb` with:
    - `belongs_to :acte`
    - No validations yet — those land in Story 1.3
  - [x] Quick console smoke: `T2Detail.column_names` (verify columns present)
  - [x] Commit: `feat(model): ajoute le modèle T2Detail avec belongs_to :acte`

- [x] **Task 3: Test and fixture stubs** (AC: 13)
  - [x] Create `test/models/t2_detail_test.rb` with a minimal table-name assertion:
    ```ruby
    require "test_helper"
    class T2DetailTest < ActiveSupport::TestCase
      test "table_name is t2_details" do
        assert_equal "t2_details", T2Detail.table_name
      end
    end
    ```
  - [x] Create `test/fixtures/t2_details.yml` with a commented-out stub (no live fixture needed until Story 1.3 adds the association to `Acte`)
  - [x] `bin/rails test` → all green
  - [x] Commit: `test: ajoute test et fixture stub pour T2Detail`

## Dev Notes

### Exact migration body

Use `ActiveRecord::Migration[8.1]` (matches all migrations in this project — e.g., `20260512090716_rename_centre_financiers_actes_to_actes_centre_financiers.rb:1`).

```ruby
class CreateT2Details < ActiveRecord::Migration[8.1]
  def change
    create_table :t2_details do |t|
      # FK to actes (1:1)
      t.references :acte, null: false, foreign_key: true, index: { unique: true }

      # Section Annexe financière / RH
      t.float   :effectifs
      t.float   :effectifs_complementaire
      t.string  :corps
      t.string  :grade,                  array: true, default: []
      t.date    :date_arrete_concours
      t.string  :date_effet_acte
      t.boolean :impact_schema_emplois
      t.boolean :impact_autre_cbcm

      # Section ISP — Cercle 1
      t.boolean :isp_cercle1
      t.string  :isp_cercle1_natures,    array: true, default: []
      t.decimal :isp_cercle1_montant
      t.decimal :isp_cercle1_enveloppe_sgg
      t.decimal :isp_cercle1_consommation

      # Section ISP — Cercle 2
      t.boolean :isp_cercle2
      t.string  :isp_cercle2_natures,    array: true, default: []
      t.decimal :isp_cercle2_montant
      t.decimal :isp_cercle2_enveloppe_sgg
      t.decimal :isp_cercle2_consommation

      # Section Fongibilité asymétrique
      t.boolean :fa_technique
      t.string  :enveloppe_abondee
      t.boolean :accord_rffim
      t.string  :sollicitation_db
      t.boolean :avis_cbcm

      # Section Mesure transversale + Enveloppe limitative (shared fields)
      t.string  :perimetre_mesure,       array: true, default: []
      t.string  :statut_agents
      t.decimal :impact_financier_n1
      t.string  :origine_financement,    array: true, default: []

      # Section Enveloppe limitative
      t.decimal :montant_enveloppe_n1
      t.decimal :impact_maximal_sans_enveloppe

      # Section Référentiel
      t.string  :referentiel_type

      # Contrôles RH communs T2 (étape 2)
      t.boolean :inscription_pap
      t.boolean :respect_plafond_emplois
      t.boolean :respect_schema_emplois
      t.boolean :controle_modalites
      t.boolean :respect_enveloppe
      t.boolean :risque_reconventionnel

      t.timestamps
    end
  end
end
```

**Why `t.references :acte` instead of `t.bigint :acte_id`?**
`t.references` emits both the column (`acte_id bigint NOT NULL`) and the FK constraint (`FOREIGN_KEY actes(id)`) in one declaration. The `index: { unique: true }` option creates the unique index at the same time, enforcing the 1:1 at DB level. This is idiomatic Rails 8.1 — consistent with how the rest of the project declares FKs (see `db/schema.rb` foreign key section).

**Why `array: true, default: []` on string arrays?**
PostgreSQL native arrays are already used in `actes` (`type_observations string[], default: []` at `db/schema.rb:85`). Same pattern applies here for `grade`, `isp_cercle1_natures`, `isp_cercle2_natures`, `perimetre_mesure`, `origine_financement`. ActiveRecord serializes/deserializes them automatically with the `pg` gem (~> 1.1, `Gemfile:13`).

**`consommation_credits` — NOT in t2_details**
The epics file explicitly states: *"consommation_credits est réutilisé depuis la table actes (colonne HT2 existante) — pas de doublon dans t2_details"*. Story 2.9 maps this criterion to `actes.consommation_credits` (already at `db/schema.rb:33`). Do not add it here.

**`date_effet_acte` as string, not date**
The epics define this as `string` (champ libre), not a date picker — same as the HT2 pattern for free-form date text. Keep it `string`.

**decimal precision**
No precision/scale specified in the epics for decimal fields. Omit precision/scale in the migration (PostgreSQL `numeric` without precision = arbitrary precision, suitable for financial amounts). Story 1.3 can add validations; Story 2.x forms can add UI formatting.

### T2Detail model file

```ruby
# app/models/t2_detail.rb
class T2Detail < ApplicationRecord
  belongs_to :acte
end
```

No validations at this stage — those are added in Story 1.3 (`has_one :t2_detail` on `Acte`, conditional validations for `titre == 'T2'`). Keeping the model minimal avoids premature constraints that could break seeds before Story 1.3.

### What Story 1.3 adds on top

Story 1.3 (depends on this story) will:
1. Add `has_one :t2_detail, dependent: :destroy` to `app/models/acte.rb`
2. Add `accepts_nested_attributes_for :t2_detail` (if needed for the form)
3. Add validations: `titre` ∈ `['HT2', 'T2']`, `categorie_t2` required when `titre == 'T2'`
4. Add model-level guard preventing HT2 actes from having a t2_detail

**Do NOT add the `has_one` to `acte.rb` in this story** — that belongs in Story 1.3.

### Learnings from Story 1.1 to apply here

From the Story 1.1 Dev Agent Record:

1. **Migration format**: Use `def change` (not `def up` / `def down`) — all operations here (`create_table`) are reversible by Rails automatically. Story 1.1 used `def up/down` which was flagged as LOW severity review issue.

2. **Convention check after migrate**: After `db:migrate`, verify schema.rb reflects what you expected. Story 1.1 had a HABTM join table naming surprise. Here, `t.references :acte` will generate `acte_id` and a FK named `fk_rails_XXXX` — check schema.rb after migration to confirm.

3. **`perl -i -pe` risk**: Not applicable to this story (no bulk text replacements). But if you need to edit large files, use Read+Edit tools rather than shell text substitution.

4. **Smoke via `bin/rails runner`**: After Task 2, verify:
   ```ruby
   T2Detail.table_name         # => "t2_details"
   T2Detail.column_names       # => includes "acte_id", "effectifs", "isp_cercle1", etc.
   T2Detail.new.grade          # => [] (default array)
   ```

5. **Rails 8.1 + PostgreSQL array defaults**: `default: []` on `array: true` columns works correctly with the `pg ~> 1.1` gem. Confirmed by the existing `type_observations` column in `actes` (same pattern).

### Project Structure Notes

**Files to create:**
- `db/migrate/TIMESTAMP_create_t2_details.rb` — migration
- `app/models/t2_detail.rb` — model
- `test/models/t2_detail_test.rb` — model test
- `test/fixtures/t2_details.yml` — fixture stub (empty/commented)

**Files NOT touched in this story:**
- `app/models/acte.rb` — the `has_one :t2_detail` association goes in Story 1.3
- `db/schema.rb` — auto-regenerated by `db:migrate`, not hand-edited
- Any controller, view, or admin file — those are Epic 2 / 3 territory

**Naming conventions (confirmed from codebase):**
- Model file: `app/models/t2_detail.rb` (snake_case, singular)
- Table name: `t2_details` (snake_case, plural) — Rails auto-infers from class `T2Detail`
- Test file: `test/models/t2_detail_test.rb`
- Fixture: `test/fixtures/t2_details.yml`

### References

- Epic definition — Story 1.2 full column spec: [_bmad-output/planning-artifacts/epics-t2-integration.md — Story 1.2](_bmad-output/planning-artifacts/epics-t2-integration.md)
- Architecture decision (table split): [_bmad-output/planning-artifacts/epics-t2-integration.md — Architecture décidée](_bmad-output/planning-artifacts/epics-t2-integration.md)
- `actes` table schema (reference for existing columns / shared fields): [db/schema.rb:18](db/schema.rb:18)
- `actes.consommation_credits` (DO NOT duplicate): [db/schema.rb:33](db/schema.rb:33)
- `actes.type_observations` (array pattern reference): [db/schema.rb:85](db/schema.rb:85)
- Story 1.1 (predecessor — completed): [_bmad-output/implementation-artifacts/1-1-renommer-la-table-ht2-actes-en-actes.md](_bmad-output/implementation-artifacts/1-1-renommer-la-table-ht2-actes-en-actes.md)
- Story 1.3 (next — adds `has_one :t2_detail` and validations): epics-t2-integration.md Story 1.3
- Story 2.9 (controls mapping — explains which boolean fields go in t2_details vs actes): epics-t2-integration.md Story 2.9
- Latest migration file (format reference): [db/migrate/20260512090716_rename_centre_financiers_actes_to_actes_centre_financiers.rb](db/migrate/20260512090716_rename_centre_financiers_actes_to_actes_centre_financiers.rb)
- Rails 8.1 / pg ~> 1.1: [Gemfile:7,13](Gemfile)

## Dev Agent Record

### Agent Model Used

claude-opus-4-7

### Debug Log References

- **Migration timestamp** : `20260512092104` (généré via `date -u +"%Y%m%d%H%M%S"`)
- **Format `def change`** : utilisé tel que prescrit dans la story (corrige le LOW finding de la Story 1.1 qui utilisait `def up/def down`). `create_table` est nativement réversible par Rails.
- **Schéma généré** : 40 colonnes au total sur `t2_details` (id + acte_id + 36 colonnes métier + created_at + updated_at). Index unique `index_t2_details_on_acte_id` créé. Foreign key `t2_details.acte_id → actes.id` créée.
- **Rollback testé** : `db:rollback STEP=1` → `drop_table(:t2_details)` propre en 0.0077s, schema.rb post-rollback ne contient plus aucune référence `t2_detail`. Re-migration enchaîne en 0.0118s.
- **Avertissement préexistant** : `test_suspension_uses_acte_id_foreign_key` dans `acte_test.rb` génère un warning "missing assertions" — vient de la Story 1.1 (pattern `next unless`), non touché par cette story.

### Completion Notes List

- ✅ Tous les ACs (AC1–AC13) satisfaits
- ✅ Migration `db/migrate/20260512092104_create_t2_details.rb` créée — 36 colonnes métier réparties sur 7 sections (Annexe financière, ISP cercles 1&2, FA, Mesure transversale, Enveloppe limitative, Référentiel, Contrôles RH T2)
- ✅ FK `t.references :acte, null: false, foreign_key: true, index: { unique: true }` — colonne, contrainte FK et index unique en une déclaration idiomatique Rails 8.1
- ✅ Pattern PostgreSQL arrays `string[], default: []` appliqué à 5 colonnes (`grade`, `isp_cercle1_natures`, `isp_cercle2_natures`, `perimetre_mesure`, `origine_financement`) — cohérent avec `actes.type_observations` ([db/schema.rb:85])
- ✅ `consommation_credits` **non dupliqué** dans `t2_details` — réutilise la colonne existante sur `actes` (conforme à l'epic et à la story)
- ✅ `date_effet_acte` créé en `string` (champ libre), pas en `date` — conforme à la spec epics
- ✅ Modèle `T2Detail` minimal : `belongs_to :acte`. Aucune validation ajoutée (ces ajouts sont prévus en Story 1.3). `Acte` **non modifié** — le `has_one :t2_detail` est explicitement délégué à la Story 1.3.
- ✅ Tests : 6 nouveaux tests `T2DetailTest` (table_name, association belongs_to, FK non-null, index unique, défauts arrays, présence de toutes les colonnes attendues) — 14 assertions, 0 failure
- ✅ Suite complète : `bin/rails test` → **19 runs / 36 assertions / 0 failure / 0 error / 0 skip**
- ✅ Aucune régression sur les tests Story 1.1

### File List

**Created:**
- `db/migrate/20260512092104_create_t2_details.rb` — migration `CreateT2Details`
- `app/models/t2_detail.rb` — modèle minimal `T2Detail < ApplicationRecord` avec `belongs_to :acte`
- `test/models/t2_detail_test.rb` — 6 tests (structure, association, défauts, colonnes)
- `test/fixtures/t2_details.yml` — fixture stub commenté (live fixtures viendront en Story 1.3)

**Modified:**
- `db/schema.rb` — régénéré par `db:migrate` (ajout du bloc `create_table "t2_details"`, index unique, foreign key)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — `1-2-creer-la-table-t2-details: backlog` → `ready-for-dev` → `in-progress` → `review`

### Senior Developer Review (AI)

**Date :** 2026-05-12 | **Reviewer :** Claude (adversarial)

**Issues Fixed (4) :**

- 🔴 **[HIGH] Épic incohérente corrigée** — `_bmad-output/planning-artifacts/epics-t2-integration.md:477` listait `consommation_credits` dans `(t2_details)` alors que c'est une colonne `actes` réutilisée (validé Story 1.2, confirmé ligne 488 du même fichier). Corrigé : table mention changée en `(actes) ¹` + note explicative ajoutée. À surveiller lors de Story 2.9 pour éviter toute duplication.

- 🟡 **[MEDIUM] Test FK DB absent** — Aucun test ne vérifiait l'existence de la contrainte FK DB (`t2_details.acte_id → actes.id`). Ajouté : `test "foreign key constraint exists from t2_details to actes"` via `connection.foreign_keys`.

- 🟡 **[MEDIUM] Test `belongs_to` superficiel** — Le test original vérifait uniquement la déclaration de l'association via `reflect_on_association`, pas le comportement de validation. Remplacé par un test qui vérifie que `T2Detail.new.valid? == false` et qu'une erreur est levée sur `:acte`.

- 🟡 **[MEDIUM] Commentaire fixture trompeur** — `test/fixtures/t2_details.yml` expliquait l'absence de fixtures par "l'association `has_one` n'est pas encore sur Acte" — incorrect (Rails ne requiert pas l'association pour les fixtures). Corrigé : la vraie raison est l'absence de fixture Acte T2 de référence.

**Issues laissés (LOW, non bloquants) :**
- L1 : commentaires de section dans la migration (lisibilité vs style zéro-commentaire)
- L2 : `created_at`/`updated_at` maintenant inclus dans le test "all expected columns" (fixé dans la même passe)
- L3 : décision `consommation_credits` maintenant tracée dans l'épic (H1 couvre ce point)

**Résultat :** 20 runs / 37 assertions / 0 failures — suite complète verte.

### Change Log

- **2026-05-12** — Code review adversarial Story 1.2 : 4 issues corrigés (1 HIGH incohérence épic, 3 MEDIUM tests), suite verte à 20 runs.
- **2026-05-12** — Implementation Story 1.2 : création de la table `t2_details` (36 colonnes métier + FK 1:1 vers `actes`), du modèle `T2Detail` et des tests. Migration réversible, suite complète verte.
