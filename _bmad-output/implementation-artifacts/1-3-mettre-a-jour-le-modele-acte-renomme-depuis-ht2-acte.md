# Story 1.3: Enrich the `Acte` model with the T2 association and validations

Status: done

## Story

As a developer (Alexandra),
I want to add the `has_one :t2_detail` association and T2-specific validations to the `Acte` model,
so that the model layer enforces T2 business rules and Stories 1.4+ (controller/views) and Epic 2 (T2 forms) can rely on a complete, validated model.

## Acceptance Criteria

### AC1 — `has_one :t2_detail` declared on `Acte`

`app/models/acte.rb` declares:

```ruby
has_one :t2_detail, dependent: :destroy
```

### AC2 — Validation: `titre` restricted to `['HT2', 'T2']`

A validation is added on `titre`:
- Presence required (already enforced at DB level with `null: false, default: 'HT2'`)
- Inclusion in `['HT2', 'T2']`

An `Acte` with `titre: 'INVALID'` fails validation with a meaningful error message.

### AC3 — Validation: `categorie_t2` restricted when present

A validation is added on `categorie_t2`:
- Allowed values: `['contrat', 'hors_contrat', nil]`
- Nullable for HT2 acts (`titre == 'HT2'` → `categorie_t2` may be nil)

### AC4 — Conditional validation: `categorie_t2` required when `titre == 'T2'`

When `titre == 'T2'`, `categorie_t2` must be present (non-nil, non-blank).
When `titre == 'HT2'`, `categorie_t2` may be nil.

An `Acte` with `titre: 'T2'` and `categorie_t2: nil` fails validation.
An `Acte` with `titre: 'HT2'` and `categorie_t2: nil` passes validation.

### AC5 — Guard: HT2 actes cannot have a `t2_detail`

A model-level validation prevents an HT2 act from having an associated `t2_detail`.
An `Acte` with `titre: 'HT2'` that attempts to build/save a `t2_detail` is rejected with a clear error.

### AC6 — Transitional alias `Ht2Acte = Acte` remains in place

The alias at the bottom of `acte.rb` is NOT removed in this story. It is removed in Story 1.4 alongside the controller/routes/views rename.

### AC7 — Existing test suite passes with no regression

`bin/rails test` is green. No previously-passing test breaks.

### AC8 — New model tests cover all ACs

New tests in `test/models/acte_test.rb` cover:
- `has_one :t2_detail` association declared
- `titre` validation (valid values, invalid values)
- `categorie_t2` validation (presence conditional on `titre == 'T2'`)
- Guard preventing HT2 actes from having a `t2_detail`

---

## Tasks / Subtasks

- [x] **Task 1: Add `has_one :t2_detail` association to `Acte`** (AC: 1)
  - [x] In `app/models/acte.rb`, add `has_one :t2_detail, dependent: :destroy` — place it after the existing `has_many :poste_lignes` line
  - [x] Verify in console: `Acte.reflect_on_association(:t2_detail)` returns an association reflection

- [x] **Task 2: Add `titre` and `categorie_t2` validations** (AC: 2, 3, 4)
  - [x] Add inclusion validation on `titre`: `validates :titre, inclusion: { in: %w[HT2 T2] }`
  - [x] Add inclusion validation on `categorie_t2` when present: `validates :categorie_t2, inclusion: { in: %w[contrat hors_contrat], allow_nil: true }`
  - [x] Add conditional presence validation: `validates :categorie_t2, presence: true, if: -> { titre == 'T2' }`

- [x] **Task 3: Add guard preventing HT2 actes from having a `t2_detail`** (AC: 5)
  - [x] Add a custom validation method `validate :no_t2_detail_for_ht2_acte`
  - [x] Implementation: if `titre == 'HT2'` and `t2_detail.present?`, add error on `:t2_detail`

- [x] **Task 4: Update `T2Detail` model with inverse association** (AC: 1, 8)
  - [x] Verify `app/models/t2_detail.rb` has `belongs_to :acte` — it does (from Story 1.2)
  - [x] No changes needed to `t2_detail.rb` unless `accepts_nested_attributes_for` is required (NOT needed yet — forms come in Epic 2)

- [x] **Task 5: Write tests** (AC: 7, 8)
  - [x] Add tests to `test/models/acte_test.rb` (see Dev Notes for test list)
  - [x] Update `test/fixtures/t2_details.yml` stub if needed for association tests
  - [x] Run `bin/rails test` — verify green

- [x] **Task 6: Smoke-test in console** (AC: 1–5)
  - [x] `Acte.new(titre: 'T2', categorie_t2: nil).valid?` → false
  - [x] `Acte.new(titre: 'HT2', categorie_t2: nil).valid?` → true (for titre/categorie validation)
  - [x] `Acte.new(titre: 'INVALID').valid?` → false
  - [x] `actes(:one).t2_detail` → nil (no association yet for existing HT2 fixture)

---

## Dev Notes

### Exact model additions

Add the following to `app/models/acte.rb`. Place the `has_one` near the other association declarations (after `has_many :poste_lignes`). Place validations in the validations block (there are no explicit `validates` calls today — add them after the `VALID_ETATS` constant or before the first method):

```ruby
# Association T2
has_one :t2_detail, dependent: :destroy

# Validations T2
validates :titre, inclusion: { in: %w[HT2 T2] }
validates :categorie_t2, inclusion: { in: %w[contrat hors_contrat], allow_nil: true }
validates :categorie_t2, presence: true, if: -> { titre == 'T2' }
validate :no_t2_detail_for_ht2_acte

private

def no_t2_detail_for_ht2_acte
  return unless titre == 'HT2' && t2_detail.present?
  errors.add(:t2_detail, "ne peut pas être associé à un acte HT2")
end
```

**Important**: The `private` keyword is already present in `acte.rb` at line 573. Add `no_t2_detail_for_ht2_acte` in the private section, not before it.

### Ransackable attributes — do NOT add `titre` or `categorie_t2` yet

`titre` and `categorie_t2` are already in `db/schema.rb` but **not yet** in `ransackable_attributes` (`acte.rb:66`). Do NOT add them in this story — that belongs in Story 1.4 / Story 3.2 (search/filter feature). Adding ransackable attributes is a deliberate choice tied to UI exposure.

### Do NOT add `accepts_nested_attributes_for :t2_detail`

Nested attributes for `t2_detail` are needed in the controller/form (Story 2.x). Adding them now without the corresponding controller params whitelisting would be premature and could open mass-assignment surface. Leave it for the form story.

### Existing `acte.rb` structure to be aware of

- Line 1–22: class declaration + associations (`belongs_to`, `has_and_belongs_to_many`, `has_many`)
- Line 23–31: `accepts_nested_attributes_for` calls
- Line 32–55: callbacks (`before_save`, `after_save`, scopes)
- Line 56–70: `has_rich_text`, `ransackable_attributes`/`ransackable_associations`
- Line 72–82: `VALID_ETATS` constant
- Line 573+: `private` section with callback implementations

The `has_one :t2_detail` should go **with the other associations** around line 17–19 (after `has_many :poste_lignes`). The `validates` calls and `validate :no_t2_detail_for_ht2_acte` should go **after `VALID_ETATS`** (around line 83) to keep concerns grouped. The `no_t2_detail_for_ht2_acte` private method goes in the `private` section (after line 573).

### Fixtures: existing HT2 fixture

`test/fixtures/actes.yml:one` has `titre: HT2` and no `categorie_t2`. The new titre validation will pass for this fixture because `HT2` is in the allowed list and `categorie_t2` nil is allowed for HT2. **No fixture change needed** to keep existing tests green.

For tests that need a valid T2 acte, build one inline (don't add a fixture yet — fixtures with `t2_detail` require the association to be in place, which this story provides, but keep tests simple with `build` rather than adding a new fixture unless necessary).

### Tests to add to `test/models/acte_test.rb`

```ruby
# Association
test "has_one :t2_detail association declared" do
  reflection = Acte.reflect_on_association(:t2_detail)
  assert_not_nil reflection
  assert_equal :has_one, reflection.macro
end

# titre validations
test "titre validates inclusion in HT2 and T2" do
  acte = Acte.new(titre: 'INVALID')
  acte.valid?
  assert_includes acte.errors[:titre], "n'est pas inclus(e) dans la liste"
end

test "titre HT2 is valid" do
  acte = actes(:one) # fixture has titre: HT2
  assert_equal "HT2", acte.titre
  # not checking full model validity since many other fields may be missing
  column = Acte.columns_hash["titre"]
  assert_equal "HT2", column.default
end

test "titre T2 is valid value" do
  acte = Acte.new(titre: 'T2', categorie_t2: 'hors_contrat')
  acte.valid?
  refute_includes acte.errors[:titre], "n'est pas inclus(e) dans la liste"
end

# categorie_t2 validations
test "categorie_t2 required when titre is T2" do
  acte = Acte.new(titre: 'T2', categorie_t2: nil)
  acte.valid?
  assert_includes acte.errors[:categorie_t2], "doit être rempli(e)"
end

test "categorie_t2 nil allowed when titre is HT2" do
  acte = Acte.new(titre: 'HT2', categorie_t2: nil)
  acte.valid?
  refute_includes acte.errors[:categorie_t2], "doit être rempli(e)"
end

test "categorie_t2 rejects invalid values" do
  acte = Acte.new(titre: 'T2', categorie_t2: 'invalid_value')
  acte.valid?
  assert_includes acte.errors[:categorie_t2], "n'est pas inclus(e) dans la liste"
end

test "categorie_t2 accepts contrat and hors_contrat" do
  %w[contrat hors_contrat].each do |val|
    acte = Acte.new(titre: 'T2', categorie_t2: val)
    acte.valid?
    refute_includes acte.errors[:categorie_t2], "n'est pas inclus(e) dans la liste"
  end
end

# Guard: no t2_detail for HT2
test "HT2 acte cannot have a t2_detail" do
  acte = Acte.new(titre: 'HT2')
  acte.build_t2_detail
  acte.valid?
  assert acte.errors[:t2_detail].any?
end
```

### Learnings from Stories 1.1 and 1.2

1. **`def change` for migrations** (not relevant here — no migration in this story).
2. **Warning `test_suspension_uses_acte_id_foreign_key`** — this test uses `next unless` inside a test, which generates a "missing assertions" warning. Ignore it; do NOT change it (pre-existing, not introduced here).
3. **Test suite baseline**: Story 1.2 ended with 19 runs / 36 assertions / 0 failure. After adding the new tests in this story, expected count is ~28 runs / ~50+ assertions / 0 failure.
4. **No `perl -i` or bulk shell substitution** — use Read+Edit tools for any file modifications.
5. **Smoke via `bin/rails runner`** after implementation, before running the full test suite.

### Architecture decisions (from epics)

- `Ht2Acte = Acte` alias at bottom of `acte.rb` **stays** — removed only in Story 1.4 when controller/routes/views are renamed.
- `has_one :t2_detail, dependent: :destroy` — `dependent: :destroy` ensures cascading delete when an acte is destroyed (consistent with `has_many :suspensions, dependent: :destroy` etc.).
- No DB-level constraint prevents HT2 from having a `t2_detail` — enforcement is at the model layer via the `no_t2_detail_for_ht2_acte` validation.

### Project Structure Notes

**Files to modify:**
- `app/models/acte.rb` — add `has_one :t2_detail`, validations, `no_t2_detail_for_ht2_acte` private method
- `test/models/acte_test.rb` — add new tests (see above)

**Files NOT touched in this story:**
- `app/models/t2_detail.rb` — already has `belongs_to :acte` from Story 1.2, no changes needed
- `db/schema.rb` — no migration in this story, auto-regenerated only on migrate
- Any controller, view, admin, or route file — those are Story 1.4 / Epic 2
- `test/fixtures/t2_details.yml` — may need a fixture entry if tests require a persisted T2Detail; prefer inline `build` to avoid fixture complexity

### References

- Story 1.2 (predecessor — in review): [_bmad-output/implementation-artifacts/1-2-creer-la-table-t2-details.md](_bmad-output/implementation-artifacts/1-2-creer-la-table-t2-details.md)
- Story 1.4 (next — controller/routes/views + alias removal): epics-t2-integration.md Story 1.4
- Epic definition — Story 1.3 spec: [_bmad-output/planning-artifacts/epics-t2-integration.md — Story 1.3](_bmad-output/planning-artifacts/epics-t2-integration.md)
- Current `Acte` model: [app/models/acte.rb](app/models/acte.rb)
- Current `T2Detail` model: [app/models/t2_detail.rb](app/models/t2_detail.rb)
- Current `acte_test.rb`: [test/models/acte_test.rb](test/models/acte_test.rb)
- `actes` fixture: [test/fixtures/actes.yml](test/fixtures/actes.yml)
- `t2_details` fixture stub: [test/fixtures/t2_details.yml](test/fixtures/t2_details.yml)
- `db/schema.rb` — `titre` (line 81), `categorie_t2` (line 28): [db/schema.rb](db/schema.rb)
- Architecture decision (table split, `has_one :t2_detail`): [_bmad-output/planning-artifacts/epics-t2-integration.md — Architecture décidée](_bmad-output/planning-artifacts/epics-t2-integration.md)

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- **Smoke test via `bin/rails runner`** : toutes les assertions validées (`T2+nil→invalid`, `HT2+nil→valid`, `INVALID titre→invalid`, `reflect_on_association(:t2_detail).macro == :has_one`)
- **Warning préexistant** : `test_suspension_uses_acte_id_foreign_key` — `next unless` sans assertion, ignoré (Story 1.1, non touché)
- **Suite complète** : 29 runs / 56 assertions / 0 failures / 0 errors / 0 skips (baseline Story 1.2 = 19/36)

### Completion Notes List

- ✅ AC1 — `has_one :t2_detail, dependent: :destroy` ajouté dans `app/models/acte.rb` après `has_many :poste_lignes`
- ✅ AC2 — `validates :titre, inclusion: { in: %w[HT2 T2] }` — `Acte.new(titre: 'INVALID').valid?` → false avec erreur claire
- ✅ AC3 — `validates :categorie_t2, inclusion: { in: %w[contrat hors_contrat], allow_nil: true }` — nil accepté, valeurs hors liste rejetées
- ✅ AC4 — `validates :categorie_t2, presence: true, if: -> { titre == 'T2' }` — `T2+nil` → invalid, `HT2+nil` → pas d'erreur sur categorie_t2
- ✅ AC5 — Méthode privée `no_t2_detail_for_ht2_acte` — `Acte.new(titre: 'HT2').tap { |a| a.build_t2_detail }.valid?` → erreur sur `:t2_detail`
- ✅ AC6 — Alias `Ht2Acte = Acte` conservé en bas de `acte.rb` (suppression prévue Story 1.4)
- ✅ AC7 — Aucune régression : 29 runs / 56 assertions / 0 failures
- ✅ AC8 — 9 nouveaux tests dans `test/models/acte_test.rb` couvrant association, validations titre, validations categorie_t2, guard HT2

### File List

**Modified:**
- `app/models/acte.rb` — ajout `has_one :t2_detail`, validations T2, méthode privée `no_t2_detail_for_ht2_acte`
- `test/models/acte_test.rb` — 9 nouveaux tests (Story 1.3 section)

**Unchanged (verified):**
- `app/models/t2_detail.rb` — `belongs_to :acte` déjà présent (Story 1.2), aucune modification
- `db/schema.rb` — pas de migration dans cette story
- `test/fixtures/t2_details.yml` — fixture stub commenté suffisant (tests utilisent `build` inline)

### Change Log

- **2026-05-12** — Story 1.3 : enrichissement du modèle `Acte` avec `has_one :t2_detail` + validations T2 (`titre`, `categorie_t2` conditionnelle) + guard `no_t2_detail_for_ht2_acte`. 9 nouveaux tests. Suite complète verte (29/56/0).
- **2026-05-12 — Review (AI)** — Corrections suite revue adversariale :
  - H1 : assertion `assert_includes` sur le message de la guard `no_t2_detail_for_ht2_acte` (au lieu de `errors[:t2_detail].any?`)
  - M1 : ajout `presence: true` sur la validation `titre` (défense en profondeur Ruby/DB, message d'erreur plus clair)
  - M3 : ajout test cascade `acte.destroy` → `t2_detail` détruit (`assert_difference 'T2Detail.count', -1`)
  - Nouveau test `titre presence is required (nil rejected with clear message)` pour couvrir M1
  - Suite complète verte : **31 runs / 61 assertions / 0 failures**

### Review Follow-ups (AI) — not fixed in this pass

- [ ] [AI-Review][MEDIUM] Pas de normalisation `titre`/`categorie_t2` (strip/upcase) — `'t2'` ou `'T2 '` court-circuiteraient la conditionnelle `if: -> { titre == 'T2' }`. À traiter si l'import Excel ou un formulaire envoie des valeurs non-canoniques. [`app/models/acte.rb:86-89`]
- [ ] [AI-Review][LOW] Test `titre HT2 is valid value` redondant avec `titre column defaults to HT2 in schema` (Story 1.1). [`test/models/acte_test.rb:67-72`]
- [ ] [AI-Review][LOW] Test `categorie_t2 accepts contrat and hors_contrat` : la boucle pourrait utiliser `assert_empty acte.errors[:categorie_t2]` pour plus de clarté. [`test/models/acte_test.rb:98-104`]
