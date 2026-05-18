# Story 2.5: Nature-Specific Section — "Fongibilité asymétrique"

Status: done

## Story

As an instructor,
I want to fill in the specific fields of a T2 acte with nature "Fongibilité asymétrique",
so that I can document the required prior authorizations.

## Acceptance Criteria

### AC1 — Fongibilité asymétrique section appears when nature is selected

**Given** the instructor selects "Fongibilité asymétrique" from the nature dropdown in the T2 step-1 form
**When** the `toggleNatureT2` Stimulus method fires
**Then** the `#t2-section-fongibilite-asymetrique` div becomes visible (removes `fr-hidden`)
**And** all other nature sections remain hidden
**And** `#t2-deliberation-ca-row` remains hidden (Fongibilité asymétrique does not use CA deliberation)

### AC2 — Common fields always displayed

**Given** the Fongibilité asymétrique section is visible
**When** it renders (any périmètre, any user profile)
**Then** the following fields are present:
- **Montant au contrôle** (`acte[montant_ae]`, decimal input) — obligatoire
- **FA Technique** (`t2_detail[fa_technique]`, radio Oui/Non) — obligatoire, **default Non**

### AC3 — État périmètre: N° Chorus field

**Given** the section is visible **AND** `acte.perimetre == 'etat'`
**When** it renders
**Then** the **N° Chorus** field (`acte[numero_chorus]`, text input) — optionnel — is present

**Given** `acte.perimetre == 'organisme'`
**Then** N° Chorus is NOT displayed

### AC4 — État DCB: Accord RFFIM/RPROG + Sollicitation DB/BS

**Given** the section is visible **AND** `acte.perimetre == 'etat'` **AND** `current_user.statut ∈ {DCB, admin}`
**When** it renders
**Then** the following fields are present:
- **Accord RFFIM/RPROG préalable** (`t2_detail[accord_rffim]`, radio Oui/Non) — obligatoire, **default Non**
- **Sollicitation DB/BS préalable** (`t2_detail[sollicitation_db]`, dropdown: Favorable / Non favorable / Non sollicité) — obligatoire

**Given** `current_user.statut == 'CBR'`
**Then** Accord RFFIM/RPROG and Sollicitation DB/BS are NOT displayed

### AC5 — État CBR: Avis CBCM

**Given** the section is visible **AND** `acte.perimetre == 'etat'` **AND** `current_user.statut == 'CBR'`
**When** it renders
**Then** the following field is present:
- **Sollicitation CBCM préalable** (`t2_detail[sollicitation_db]`, dropdown: Favorable / Non favorable / Non sollicité) — obligatoire

> Note: from screenshots, the CBR variant uses a dropdown labeled "Sollicitation CBCM préalable" with the same options (Favorable / Non favorable / Non sollicité). This reuses the `sollicitation_db` column.

### AC6 — Organisme périmètre: Enveloppe budgétaire abondée

**Given** the section is visible **AND** `acte.perimetre == 'organisme'`
**When** it renders
**Then** the following field is present:
- **Enveloppe budgétaire abondée** (`t2_detail[enveloppe_abondee]`, dropdown: Fonctionnement / Investissement / Intervention) — optionnel

**Given** `acte.perimetre == 'etat'`
**Then** Enveloppe budgétaire abondée is NOT displayed

### AC7 — Data saved to t2_details and acte

**Given** the form is submitted with Fongibilité asymétrique fields filled
**When** the controller processes params
**Then** the following are saved:
- `acte.montant_ae` (decimal) — from the common `montant_ae` field in `acte_params`
- `acte.numero_chorus` (string, état only) — from `acte_params`
- `t2_detail.fa_technique` (boolean)
- `t2_detail.accord_rffim` (boolean, état DCB only)
- `t2_detail.sollicitation_db` (string: "Favorable" / "Non favorable" / "Non sollicité")
- `t2_detail.enveloppe_abondee` (string: "Fonctionnement" / "Investissement" / "Intervention", organisme only)
**And** the `t2_detail` record is created if it does not exist; updated if it does
**And** `clear_irrelevant_t2_detail_fields` nullifies t2_detail fields not belonging to this nature

### AC8 — No regression on other natures / HT2

**Given** an acte with `titre = 'HT2'`
**Then** the Fongibilité asymétrique section does not appear

**Given** a different T2 nature is selected (e.g. ISP, Annexe financière)
**Then** the Fongibilité asymétrique section is hidden and the appropriate other section shows

## Tasks / Subtasks

- [x] **Task 1: Extend `T2_DETAIL_FIELDS_BY_NATURE` and `acte_params`** (AC: 7)
  - [x] In `actes_controller.rb`, update `T2_DETAIL_FIELDS_BY_NATURE['Fongibilité asymétrique']` to list its t2_detail fields: `%i[fa_technique accord_rffim sollicitation_db enveloppe_abondee]`
  - [x] In `acte_params` `t2_detail_attributes`, add: `:fa_technique`, `:accord_rffim`, `:sollicitation_db`, `:enveloppe_abondee`
  - [x] Note: `montant_ae` and `numero_chorus` are already permitted at the `acte` level — no change needed there

- [x] **Task 2: Implement `_fongibilite_asymetrique.html.erb` partial** (AC: 1, 2, 3, 4, 5, 6)
  - [x] Replace the placeholder in `app/views/actes/t2_sections/_fongibilite_asymetrique.html.erb`
  - [x] Row 1: N° Chorus (état only, `f.text_field :numero_chorus`) + Montant au contrôle (`f.number_field :montant_ae`, required)
  - [x] Row 2: FA Technique radio Oui/Non (default Non, `td.radio_button :fa_technique`, `td.object.fa_technique == true || td.object.fa_technique.nil?` defaults to Non)
  - [x] Row 2 (état DCB): Accord RFFIM/RPROG radio Oui/Non (`td.radio_button :accord_rffim`, default Non)
  - [x] Row 2 (état DCB): Sollicitation DB/BS dropdown (`td.select :sollicitation_db`, options: Favorable / Non favorable / Non sollicité, prompt: "Sélectionner une option")
  - [x] Row 2 (état CBR): Sollicitation CBCM préalable dropdown (`td.select :sollicitation_db`, same options, different label)
  - [x] Row 2 (organisme): Enveloppe budgétaire abondée dropdown (`td.select :enveloppe_abondee`, options: Fonctionnement / Investissement / Intervention, prompt: "Sélectionner une option")
  - [x] Use `current_user` (accessible via `acte.user` or through Rails `current_user` helper available in views) for DCB/CBR conditional rendering
  - [x] All conditionals use ERB `<% if ... %>` blocks

- [x] **Task 3: Write controller/integration tests** (AC: 7, 8)
  - [x] Test: `new T2 Fongibilité asymétrique état DCB renders correct fields` — verifies fa_technique, accord_rffim, sollicitation_db, numero_chorus inputs present
  - [x] Test: `new T2 Fongibilité asymétrique état CBR renders CBCM field only` — verifies sollicitation_db present, accord_rffim absent
  - [x] Test: `new T2 Fongibilité asymétrique organisme renders enveloppe_abondee` — verifies enveloppe_abondee present, accord_rffim/cbcm absent
  - [x] Test: `create T2 Fongibilité asymétrique DCB saves fa_technique, accord_rffim, sollicitation_db` — full persistence test
  - [x] Test: `create T2 Fongibilité asymétrique organisme saves enveloppe_abondee` — persistence test

## Dev Notes

### Screenshot analysis — Fongibilité asymétrique form layout

Three screenshots provided:

**État DCB layout:**
```
Row 1: [Initiales instructeur*] | [Nature: Fongibilité asymétrique (dropdown)] | [Centre financier*]
Row 2: [Exercice* dropdown]     | [Date de saisine* dropdown]                  | [Service ordonnateur]
Row 3: [Objet]                  | [Montant au contrôle*]                        | [N°Chorus]
Row 4: [FA technique* Oui/Non•] | [Accord RFFIM/RPROG préalable* Oui/Non•]     | [Sollicitation DB/BS préalable* dropdown]
Row 5: [Précisions sur l'acte (textarea)]
Footer: [Cet acte a été réalisé en période de services votés (checkbox)]
```

**État CBR layout:**
```
Row 1: [Initiales instructeur*] | [Nature: Fongibilité asymétrique] | [Centre financier*]
Row 2: [Exercice*]              | [Date de saisine*]                 | [Service ordonnateur]
Row 3: [Objet]                  | [Montant au contrôle*]             | (no N°Chorus for CBR? or same as DCB)
Row 4: [FA Technique* Oui/Non]  | [Sollicitation CBCM préalable* dropdown]
       ↳ dropdown open: "Favorable" / "Non favorable" / "Non sollicité"
```

> Note: The CBR screenshot shows "Sollicitation CBCM préalable" (not "Sollicitation DB/BS préalable"), but the dropdown options are identical. This reuses `t2_detail.sollicitation_db` with a different label depending on the user profile.

**Organisme layout:**
```
Row 1: [Initiales instructeur*]        | [Nature: Fongibilité asymétrique] | [Organisme*]
Row 2: [Exercice*]                     | [Date de saisine*]                 | [Service ordonnateur]
Row 3: [Objet]                         | [Montant au contrôle*]             | [FA Technique* Oui/Non•]
Row 4: [Enveloppe budgétaire abondée (dropdown)]
       ↳ dropdown open: "Fonctionnement" / "Investissement" / "Intervention"
```

> Note: For organisme, no N°Chorus, no accord_rffim, no sollicitation_db/CBCM. FA Technique is in the third column of row 3 instead of row 4.

### `montant_ae` and `numero_chorus` — on `actes` table, not `t2_details`

These fields already exist on the `actes` table and are already permitted in `acte_params`:
- `montant_ae` (float, line 1175 of actes_controller.rb)
- `numero_chorus` (string, line 1175 of actes_controller.rb)

Use `f.number_field :montant_ae` and `f.text_field :numero_chorus` (form builder `f:`, not `td:`).

### `fa_technique` — radio Oui/Non, default Non

```erb
<fieldset class="fr-fieldset fr-mb-0" aria-labelledby="fa-technique-legend">
  <legend class="fr-fieldset__legend--regular fr-fieldset__legend" id="fa-technique-legend">
    FA Technique*
    <%= render partial: "actes/tooltip", locals: { name: "fa_technique_info" } %>
  </legend>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <%= td.radio_button :fa_technique, true, id: "fa_technique_oui" %>
      <label class="fr-label" for="fa_technique_oui">Oui</label>
    </div>
  </div>
  <div class="fr-fieldset__element fr-fieldset__element--inline">
    <div class="fr-radio-group">
      <%= td.radio_button :fa_technique, false, id: "fa_technique_non",
          checked: td.object.fa_technique == false || td.object.fa_technique.nil? %>
      <label class="fr-label" for="fa_technique_non">Non</label>
    </div>
  </div>
</fieldset>
```

### `accord_rffim` — radio Oui/Non, default Non (état DCB only)

Same pattern as `fa_technique`. Default Non (checked when `nil`):
```erb
checked: td.object.accord_rffim == false || td.object.accord_rffim.nil?
```

### `sollicitation_db` — dropdown with 3 options

```erb
<div class="fr-select-group">
  <label for="t2_detail_sollicitation_db" class="fr-label">
    <%= acte.perimetre == 'etat' && current_user.statut == 'CBR' ? 'Sollicitation CBCM préalable*' : 'Sollicitation DB/BS préalable*' %>
  </label>
  <%= td.select :sollicitation_db,
               options_for_select(
                 [['Favorable', 'Favorable'], ['Non favorable', 'Non favorable'], ['Non sollicité', 'Non sollicité']],
                 td.object.sollicitation_db
               ),
               { prompt: 'Sélectionner une option' },
               { id: "t2_detail_sollicitation_db", class: "fr-select" } %>
</div>
```

### `enveloppe_abondee` — dropdown with 3 options (organisme only)

```erb
<div class="fr-select-group">
  <label for="t2_detail_enveloppe_abondee" class="fr-label">Enveloppe budgétaire abondée</label>
  <%= td.select :enveloppe_abondee,
               options_for_select(
                 [['Fonctionnement', 'Fonctionnement'], ['Investissement', 'Investissement'], ['Intervention', 'Intervention']],
                 td.object.enveloppe_abondee
               ),
               { prompt: 'Sélectionner une option' },
               { id: "t2_detail_enveloppe_abondee", class: "fr-select" } %>
</div>
```

### User profile conditional rendering

The partial receives `acte:` and `f:` and `td:`. `current_user` is available in views via the `current_user` helper (Devise). Use it directly:

```erb
<% is_dcb = current_user.statut == 'DCB' || current_user.statut == 'admin' %>
<% is_cbr = current_user.statut == 'CBR' %>
```

### `T2_DETAIL_FIELDS_BY_NATURE` — must be updated

Current (line 1137 of actes_controller.rb):
```ruby
'Fongibilité asymétrique' => [],
```

Must become:
```ruby
'Fongibilité asymétrique' => %i[fa_technique accord_rffim sollicitation_db enveloppe_abondee],
```

This ensures `clear_irrelevant_t2_detail_fields` only preserves these fields when nature is Fongibilité asymétrique, and nullifies them when switching to other natures.

### `acte_params` — t2_detail_attributes extension

Current `t2_detail_attributes` (line 1190–1195):
```ruby
t2_detail_attributes: [:id,
  :type_acte_t2, :effectifs, :effectifs_complementaire, :corps, :date_arrete_concours,
  :date_effet_acte, :impact_schema_emplois, :impact_autre_cbcm,
  :isp_cercle1, :isp_cercle1_montant, :isp_cercle1_enveloppe_sgg, :isp_cercle1_consommation,
  :isp_cercle2, :isp_cercle2_montant, :isp_cercle2_enveloppe_sgg, :isp_cercle2_consommation,
  grade: [], isp_cercle1_natures: [], isp_cercle2_natures: []]
```

Add the four new fields:
```ruby
t2_detail_attributes: [:id,
  :type_acte_t2, :effectifs, :effectifs_complementaire, :corps, :date_arrete_concours,
  :date_effet_acte, :impact_schema_emplois, :impact_autre_cbcm,
  :isp_cercle1, :isp_cercle1_montant, :isp_cercle1_enveloppe_sgg, :isp_cercle1_consommation,
  :isp_cercle2, :isp_cercle2_montant, :isp_cercle2_enveloppe_sgg, :isp_cercle2_consommation,
  :fa_technique, :accord_rffim, :sollicitation_db, :enveloppe_abondee,
  grade: [], isp_cercle1_natures: [], isp_cercle2_natures: []]
```

### Database columns confirmed — no migration needed

From `db/schema.rb` (t2_details table, lines 504–540):
- `t.boolean "accord_rffim"` ✓
- `t.boolean "avis_cbcm"` ✓ (not used in this story — `sollicitation_db` is used instead per screenshots)
- `t.string "enveloppe_abondee"` ✓
- `t.boolean "fa_technique"` ✓
- `t.string "sollicitation_db"` ✓

**No migration needed.** All columns already exist.

> Note: `avis_cbcm` (boolean) exists in `t2_details` but is NOT used in this story. Per screenshot analysis, CBR users get a dropdown `Sollicitation CBCM préalable` which maps to `sollicitation_db` (string). The `avis_cbcm` boolean column may be intended for a later step (AC criteria in Story 2.9 — contrôle criteria). Do not use `avis_cbcm` here.

### Partial layout — ERB skeleton

The partial is called by `_form_informations_t2.html.erb` line 121:
```erb
<div id="t2-section-fongibilite-asymetrique" class="fr-hidden" data-acte-form-target="natureT2Section" aria-live="polite">
  <%= render 'actes/t2_sections/fongibilite_asymetrique', f: f, td: td, acte: @acte %>
</div>
```

The partial receives locals `f:` (form builder for `acte`), `td:` (fields_for builder for `t2_detail`), `acte:` (@acte instance).

ERB structure:
```erb
<%# locals: (f:, td:, acte:) %>
<% is_dcb = current_user.statut == 'DCB' || current_user.statut == 'admin' %>
<% is_cbr = current_user.statut == 'CBR' %>
<div class="fr-grid-row fr-grid-row--gutters">
  <%# Montant au contrôle (all) %>
  <%# N° Chorus (état only) %>
  <%# [empty col or other] %>
</div>

<div class="fr-grid-row fr-grid-row--gutters">
  <%# FA Technique radio (all) %>
  <%# État DCB: Accord RFFIM/RPROG radio %>
  <%# État DCB: Sollicitation DB/BS dropdown %>
  <%# État CBR: Sollicitation CBCM dropdown %>
  <%# Organisme: Enveloppe budgétaire abondée dropdown %>
</div>
```

> Important: `Précisions sur l'acte` (textarea) and `Cet acte a été réalisé en période de services votés` (checkbox) are in the **parent partial** `_form_informations_t2.html.erb`, not in this section partial. Do not add them here.

### Tests — user fixtures available

- `users(:two)` — statut: CBR
- `users(:three)` — statut: DCB
- `users(:one)` — statut: admin (treated as DCB for nature list)

For organisme tests, pass `perimetre: 'organisme'` in params (same user, DCB). The controller sets `@liste_natures` based on `perimetre_t2` and `current_user.statut`.

### No Stimulus changes needed

- `toggleNatureT2` already maps 'Fongibilité asymétrique' → `t2-section-fongibilite-asymetrique` (line 869 of acte_form_controller.js)
- No new JS methods needed (no real-time calculations for this nature)
- `calculateIspReste` already exists and is only wired to ISP fields — no risk of conflict

### Files to create

- `app/views/actes/t2_sections/_fongibilite_asymetrique.html.erb` — replace placeholder with full section

### Files to modify

- `app/controllers/actes_controller.rb` — two changes:
  1. Update `T2_DETAIL_FIELDS_BY_NATURE['Fongibilité asymétrique']` (line 1137)
  2. Extend `t2_detail_attributes` in `acte_params` (line 1190–1195)
- `test/controllers/actes_controller_test.rb` — add Fongibilité asymétrique tests

### Files NOT touched

- `db/schema.rb` — no migration needed
- `db/migrate/20260512092104_create_t2_details.rb` — already has all columns
- `app/models/acte.rb` — no changes needed
- `app/models/t2_detail.rb` — no new validations needed
- `app/views/actes/_form_informations_t2.html.erb` — section wrapper already in place (line 120–122)
- `app/javascript/controllers/acte_form_controller.js` — no changes needed
- All HT2 forms

### Existing patterns to reuse

| Pattern | Where |
|---------|-------|
| Radio Oui/Non with default Non | `_annexe_financiere.html.erb` lines 75–94 (`impact_autre_cbcm`), lines 97–116 (`impact_schema_emplois`) |
| Dropdown `fr-select` with prompt | `_annexe_financiere.html.erb` lines 5–9 (`type_acte_t2`), `_form_informations_t2.html.erb` (`date_saisine`) |
| `acte.perimetre == 'organisme'` conditional | `_annexe_financiere.html.erb` lines 127–148 (budget_executoire), `_form_informations_t2.html.erb` line 143 |
| `current_user.statut` check | `actes_controller.rb` line 1212–1215 (nature list logic) |
| `f.number_field :montant_ae` | Already in `acte_params` line 1175 |
| `f.text_field :numero_chorus` | Already in `acte_params` line 1175 |
| tooltip partial | `_annexe_financiere.html.erb` line 78: `render partial: "actes/tooltip", locals: { name: "..." }` |
| `fr-grid-row fr-grid-row--gutters` | Used in all partials |
| `fr-col-12 fr-col-lg-4` | Column pattern throughout |

### Project Structure Notes

- Views: `app/views/actes/t2_sections/` — one partial per nature (already contains placeholder)
- Section partial receives `f:, td:, acte:` locals (wired in `_form_informations_t2.html.erb` line 121)
- `f:` = form builder for `acte` (for `montant_ae`, `numero_chorus`)
- `td:` = fields_for builder for `t2_detail` (for `fa_technique`, `accord_rffim`, `sollicitation_db`, `enveloppe_abondee`)
- DSFR components: `fr-fieldset`, `fr-radio-group`, `fr-input-group`, `fr-select-group`, `fr-grid-row fr-grid-row--gutters`, `fr-col-12 fr-col-lg-4`

### References

- Epic spec — Story 2.5: [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md) lines 350–369
- Previous story (2.4 ISP, done): [_bmad-output/implementation-artifacts/2-4-section-specifique-nature-isp.md](_bmad-output/implementation-artifacts/2-4-section-specifique-nature-isp.md)
- Section placeholder (current): [app/views/actes/t2_sections/_fongibilite_asymetrique.html.erb](app/views/actes/t2_sections/_fongibilite_asymetrique.html.erb)
- Annexe financière partial (radio/dropdown patterns): [app/views/actes/t2_sections/_annexe_financiere.html.erb](app/views/actes/t2_sections/_annexe_financiere.html.erb)
- T2 form partial (section wiring, deliberation_ca): [app/views/actes/_form_informations_t2.html.erb](app/views/actes/_form_informations_t2.html.erb) lines 120–122
- Controller `T2_DETAIL_FIELDS_BY_NATURE`: [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb#L1126)
- Controller `acte_params` (extend): [app/controllers/actes_controller.rb](app/controllers/actes_controller.rb#L1190)
- T2Detail model: [app/models/t2_detail.rb](app/models/t2_detail.rb)
- DB schema (column verification): [db/schema.rb](db/schema.rb) lines 503–544
- Existing tests: [test/controllers/actes_controller_test.rb](test/controllers/actes_controller_test.rb)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `T2_DETAIL_FIELDS_BY_NATURE['Fongibilité asymétrique']` mis à jour avec `%i[fa_technique accord_rffim sollicitation_db enveloppe_abondee]` — `clear_irrelevant_t2_detail_fields` nullifie correctement les champs lors d'un changement de nature.
- `acte_params` étendu : `t2_detail_attributes` inclut désormais `:fa_technique`, `:accord_rffim`, `:sollicitation_db`, `:enveloppe_abondee`. `montant_ae` et `numero_chorus` déjà permis au niveau `acte`.
- `_fongibilite_asymetrique.html.erb` implémenté : layout en 2 rows avec conditionnels ERB par périmètre (état/organisme) et profil utilisateur (DCB/CBR). État DCB : Montant + N°Chorus + FA Technique + Accord RFFIM + Sollicitation DB/BS. État CBR : Montant + N°Chorus + FA Technique + Sollicitation CBCM. Organisme : Montant + FA Technique (row 1) + Enveloppe budgétaire abondée (row 2). Toutes options de dropdown confirmées depuis les captures d'écran.
- 5 nouveaux tests dans `actes_controller_test.rb` : rendu DCB (champs présents/absents), rendu CBR (CBCM présent, accord_rffim absent), rendu organisme (enveloppe_abondee présente, sollicitation absente), persistance complète DCB, persistance organisme.
- Code review (2026-05-13) — 3 fixes appliqués : (1) `montant_ae` corrigé en `number_field step: 0.01` (M2) ; (2) test CBR complété : assertion `numero_chorus` présent pour périmètre état (H2/AC3) ; (3) 2 tests AC8 ajoutés : section fongibilité cachée quand nature=ISP, absente pour HT2.
- Suite complète post-review : **34 runs / 278 assertions / 0 failures / 0 errors**.

### File List

- `app/controllers/actes_controller.rb`
- `app/views/actes/t2_sections/_fongibilite_asymetrique.html.erb`
- `test/controllers/actes_controller_test.rb`
