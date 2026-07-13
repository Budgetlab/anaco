# Story 2.12: Affichage des détails d'un acte T2 en mode consultation

Status: done

## Story

As an instructor or validator,
I want to see the T2-specific fields (from `t2_details`) displayed on the acte show page,
so that I can consult all the information of a T2 acte in read-only mode, just like HT2 actes display their details via `_acte_details`.

## Acceptance Criteria

### AC1 — Routing: show page selects `_acte_details_t2` for T2 actes

**Given** I navigate to `acte_path(@acte)` for a T2 acte (titre == 'T2')
**When** the show page renders
**Then** the partial `_acte_details_t2.html.erb` is rendered (not `_acte_details` or `_acte_details_organisme`)
**And** HT2 actes continue to use `_acte_details` or `_acte_details_organisme` as before (no regression)

### AC2 — Common fields block is identical to `_acte_details`

**Given** a T2 acte show page
**When** the page renders
**Then** the following common blocks are displayed, identical to `_acte_details`:
- Turbo frame (actions bloc) if `acte.user == current_user`, else etat badge
- "Décision de contrôle" card: `proposition_decision`, `instructeur`, `decision_finale`, `valideur`, `commentaire_proposition_decision`
- "Observations à l'ordonnateur" card: `observations`, `type_observations` (T2-specific list)
- Table 1 — Informations: `nature`, `montant_ae`, `montant_global`, `annee`, `date_saisine`, `delai_traitement` (no `type_engagement` column for T2)
- Table 2 — Informations: `centre_financier_code` (if perimetre == 'etat') or `nom_organisme` (if perimetre == 'organisme'), `numero_chorus`, `objet`, `ordonnateur`
- "Précisions sur l'acte" text block
- Suspensions block (same as HT2)

### AC3 — T2-specific details section displayed according to `nature`

**Given** a T2 acte with a given `nature`
**When** the show page renders
**Then** a "Détails de l'acte T2" section appears, showing only the fields relevant to that nature:

| Nature | Read-only fields to display |
|--------|----------------------------|
| Annexe financière | `type_acte_t2` (Initial/Complémentaire), `date_effet_acte`, `effectifs`, `effectifs_complementaire`, `grade` (array), `corps`, `date_arrete_concours`, `impact_schema_emplois` (boolean), `impact_autre_cbcm` (boolean) |
| ISP | `date_effet_acte`, Cercle 1: `isp_cercle1` (boolean), `isp_cercle1_natures` (array), `isp_cercle1_montant`, `isp_cercle1_enveloppe_sgg`, `isp_cercle1_consommation` + reste calculé; Cercle 2: même structure |
| Fongibilité asymétrique | `montant_ae` (from `actes`), `numero_chorus` (from `actes`), `fa_technique` (boolean), `accord_rffim` (boolean, if état+DCB), `sollicitation_db` (if état+DCB), `avis_cbcm` (boolean, if état+CBR), `enveloppe_abondee` (if organisme) |
| Marché | `montant_ae` (from `actes`), `beneficiaire` (from `actes`), `operation_budgetaire` (if organisme) |
| Mesure transversale | `date_effet_acte`, `perimetre_mesure` (array), `grade` (array), `corps`, `effectifs` (N), `effectifs_complementaire` (N+1), `statut_agents`, `montant_ae`, `impact_financier_n1`, `origine_financement` (array, if état) |
| Enveloppe limitative | `date_effet_acte`, `perimetre_mesure` (array), `grade` (array), `corps`, `effectifs` (N), `effectifs_complementaire` (N+1), `statut_agents`, `montant_ae`, `montant_enveloppe_n1`, `impact_maximal_sans_enveloppe`, effet calculé (%), `origine_financement` (array, if état) |
| Référentiel | `referentiel_type`, `date_effet_acte`, `perimetre_mesure` (array), `grade` (array), `corps`, `effectifs` (N), `effectifs_complementaire` (N+1), `montant_ae`, `impact_financier_n1`, `origine_financement` (array, if état) |

**And** if `acte.t2_detail.nil?`, the T2 details section is either omitted or shows "Aucune donnée T2 renseignée"

### AC4 — T2 critères de contrôle displayed

**Given** a T2 acte at show page
**When** the critères section renders
**Then** the T2-specific criteria are shown as boolean icons (✓/—), displayed only when their condition is met (same conditions as step 2 form in story 2.9):

| Critère | Source | Display condition |
|---------|--------|-------------------|
| Inscription au PAP | `t2_detail.inscription_pap` | état + nature ∈ {Annexe financière, Mesure transversale, Référentiel} |
| Respect du plafond d'emplois | `t2_detail.respect_plafond_emplois` | nature == Annexe financière |
| Respect du schéma d'emplois | `t2_detail.respect_schema_emplois` | nature == Annexe financière + `impact_schema_emplois` == true |
| Contrôle des modalités | `t2_detail.controle_modalites` | nature == Fongibilité asymétrique + état + DCB |
| Exactitude de la consommation des crédits | `acte.consommation_credits` | nature ∈ {Fongibilité asymétrique, Marché, Mesure transversale} |
| Respect de l'enveloppe notifiée | `t2_detail.respect_enveloppe` | nature == ISP |
| Risque d'effet reconventionnel | `t2_detail.risque_reconventionnel` | nature ∈ {Mesure transversale, Référentiel} |
| Acte dans la programmation | `acte.programmation_prevue` | nature ∉ {ISP} + not (FA + organisme) |
| Opération autorisée tutelle | `acte.autorisation_tutelle` | nature ∉ {ISP, FA} + organisme + `budget_executoire` == false |
| Programmation initiale transmise | `acte.avis_programmation` | nature ≠ ISP + état |
| Compatibilité programmation | `acte.programmation` | nature ∉ {ISP} + conditions complexes (voir story 2.9) |
| Soutenabilité des crédits | `acte.soutenabilite` | nature ≠ Annexe financière |

**And** HT2 critères section is unchanged

### AC5 — No regression on HT2 show

**Given** an HT2 acte
**When** the show page renders
**Then** `_acte_details` or `_acte_details_organisme` is rendered as before, with no T2 section
**And** all HT2 fields display correctly

## Tasks / Subtasks

- [x] **Task 1: Update `show.html.erb` routing to add T2 branch** (AC: 1)
  - [x] In `app/views/actes/show.html.erb` (lines 91–95), add a T2 branch before the existing perimetre check:
    ```erb
    <% if acte.titre == 'T2' %>
      <%= render 'acte_details_t2', acte: acte %>
    <% elsif acte.perimetre == 'organisme' %>
      <%= render 'acte_details_organisme', acte: acte %>
    <% else %>
      <%= render 'acte_details', acte: acte %>
    <% end %>
    ```

- [x] **Task 2: Create `_acte_details_t2.html.erb`** (AC: 2, 3, 4)
  - [x] Copy common structure from `_acte_details.html.erb` (turbo_frame, decision card, observations card, suspensions block)
  - [x] Adapt Table 1 for T2: remove `type_engagement` column; keep `nature`, `montant_ae`, `montant_global`, `annee`, `date_saisine`, `delai_traitement`
  - [x] Adapt Table 2 for T2: show `centre_financier_code` if perimetre == 'etat', `nom_organisme` if perimetre == 'organisme'; keep `numero_chorus`, `objet`, `ordonnateur`
  - [x] Remove HT2-specific blocks: `poste_lignes`, `echeanciers`, "Informations complémentaires" (catégorie/action/activite)
  - [x] Add "Détails de l'acte T2" section: `case acte.nature` switch rendering the appropriate read-only sub-partial
  - [x] Add T2 critères block (AC4)
  - [x] Keep `precisions_acte`, suspensions, tableur (sheet_data) blocks

- [x] **Task 3: Create read-only sub-partials per nature in `t2_sections/`** (AC: 3)
  - [x] `app/views/actes/t2_sections/_show_annexe_financiere.html.erb` — read-only fields for Annexe financière
  - [x] `app/views/actes/t2_sections/_show_isp.html.erb` — read-only fields for ISP (with reste calculé = enveloppe - consommation)
  - [x] `app/views/actes/t2_sections/_show_fongibilite_asymetrique.html.erb` — read-only fields, conditioned by perimetre/statut
  - [x] `app/views/actes/t2_sections/_show_marche.html.erb` — read-only fields (simple)
  - [x] `app/views/actes/t2_sections/_show_mesure_transversale.html.erb` — read-only fields
  - [x] `app/views/actes/t2_sections/_show_enveloppe_limitative.html.erb` — read-only fields (with effet calculé %)
  - [x] `app/views/actes/t2_sections/_show_referentiel.html.erb` — read-only fields

- [x] **Task 4: Write controller/integration tests** (AC: 1–5)
  - [x] `GET show T2 acte routes to acte_details_t2 partial (AC1)`
  - [x] `GET show T2 acte nature Annexe financière displays t2_detail fields (AC3)`
  - [x] `GET show T2 acte nature ISP displays cercle 1 and cercle 2 fields (AC3)`
  - [x] `GET show T2 acte nature Fongibilité asymétrique displays FA fields (AC3)`
  - [x] `GET show T2 acte nature Marché displays Marché fields (AC3)`
  - [x] `GET show T2 acte nature Mesure transversale displays MT fields (AC3)`
  - [x] `GET show T2 acte nature Enveloppe limitative displays EL fields (AC3)`
  - [x] `GET show T2 acte nature Référentiel displays Référentiel fields (AC3)`
  - [x] `GET show T2 acte critères displayed (AC4)`
  - [x] `GET show HT2 acte not affected (AC5 regression)`

## Dev Notes

### Pattern to follow: `_acte_details.html.erb`

The new `_acte_details_t2.html.erb` partial follows the **exact same structure** as `_acte_details.html.erb`:
- Same turbo_frame / etat badge opening (lines 1–10 of `_acte_details`)
- Same decision card + observations card (lines 14–53)
- Same table style (`fr-table fr-table--no-caption`)
- Same boolean rendering helper pattern (check existing helper usage for `format_boolean` or similar — see critères section in `_acte_details.html.erb` lines 309–373)
- Same suspensions loop (lines 407–433)

Key differences from HT2:
- No `type_engagement` column (T2 actes don't use it)
- No `poste_lignes` section (T2 actes don't have ligne de poste)
- No `echeanciers` section
- No "Informations complémentaires" block (catégorie/action/activite — HT2-specific)
- Extra section: **T2 details** (nature-specific, from `t2_detail`)
- Different critères set (T2 critères, not HT2 critères)

### Show page routing — current state

`app/views/actes/show.html.erb` lines 91–95:
```erb
<% if acte.perimetre == 'organisme' %>
  <%= render 'acte_details_organisme', acte: acte %>
<% else %>
  <%= render 'acte_details', acte: acte %>
<% end %>
```

T2 actes can have `perimetre` = 'etat' OR 'organisme'. The T2 check must come **first** to prevent T2 organisme actes from falling into `_acte_details_organisme` (which has no T2 content).

### T2 details section — case/when pattern

Inside `_acte_details_t2.html.erb`, the nature-specific section should use:
```erb
<% if acte.t2_detail.present? %>
  <div class="fr-h6 fr-my-3w">Détails de l'acte T2</div>
  <% td = acte.t2_detail %>
  <% case acte.nature %>
  <% when 'Annexe financière' %>
    <%= render 'actes/t2_sections/show_annexe_financiere', acte: acte, td: td %>
  <% when 'ISP' %>
    <%= render 'actes/t2_sections/show_isp', acte: acte, td: td %>
  <% when 'Fongibilité asymétrique' %>
    <%= render 'actes/t2_sections/show_fongibilite_asymetrique', acte: acte, td: td %>
  <% when 'Marché' %>
    <%= render 'actes/t2_sections/show_marche', acte: acte, td: td %>
  <% when 'Mesure transversale' %>
    <%= render 'actes/t2_sections/show_mesure_transversale', acte: acte, td: td %>
  <% when 'Enveloppe limitative' %>
    <%= render 'actes/t2_sections/show_enveloppe_limitative', acte: acte, td: td %>
  <% when 'Référentiel' %>
    <%= render 'actes/t2_sections/show_referentiel', acte: acte, td: td %>
  <% end %>
<% end %>
```

### Read-only sub-partial structure

Each `_show_*.html.erb` partial receives `acte:` and `td:` (the `t2_detail` object). Use `fr-grid-row` + `fr-col-*` layout with label/value pairs. Use `format_value(td.field)` for strings, `number_to_currency` for amounts, and a simple boolean helper for booleans.

Boolean display pattern (look at how critères are rendered in `_acte_details.html.erb` lines 309–373 — likely uses `check_icon` helper or inline conditional):
```erb
<%= td.impact_schema_emplois ? '✓' : '—' %>
```
Or use existing helper if one exists (grep for `format_boolean` or `check_icon` in helpers).

Array fields (grade, perimetre_mesure, origine_financement, isp_cercle1_natures):
```erb
<%= Array(td.grade).join(', ').presence || '—' %>
```

ISP "reste à consommer" calculated field:
```erb
<% reste = (td.isp_cercle1_enveloppe_sgg.to_f - td.isp_cercle1_consommation.to_f).round(2) %>
<%= number_to_currency(reste, unit: "€", format: "%n %u") %>
```

Enveloppe limitative "effet de l'enveloppe" calculated field:
```erb
<% if td.montant_enveloppe_n1.to_f > 0 %>
  <%= number_to_percentage((td.impact_maximal_sans_enveloppe.to_f / td.montant_enveloppe_n1.to_f) * 100, precision: 1) %>
<% end %>
```

### Critères T2 section

The critères block in `_acte_details_t2.html.erb` should list only the criteria applicable to the acte's nature (same conditions as story 2.9 form, but in read-only table format). Follow the table structure in `_acte_details.html.erb` lines 309–373.

Key fields: `t2_detail.inscription_pap`, `t2_detail.respect_plafond_emplois`, `t2_detail.respect_schema_emplois`, `t2_detail.controle_modalites`, `acte.consommation_credits`, `t2_detail.respect_enveloppe`, `t2_detail.risque_reconventionnel`, `acte.programmation_prevue`, `acte.autorisation_tutelle`, `acte.avis_programmation`, `acte.programmation`, `acte.soutenabilite`.

### `acte.titre` field

Set since story 1.1. All T2 actes have `titre == 'T2'`, HT2 actes have `titre == 'HT2'`.

### Helper for boolean display

Before writing inline `td.field ? '✓' : '—'`, check `app/helpers/actes_helper.rb` for an existing helper (e.g. `format_boolean`, `check_icon`, or similar). If none exists, define one:
```ruby
# app/helpers/actes_helper.rb
def format_boolean(value)
  value ? '✓' : '—'
end
```

### T2 actes with perimetre == 'organisme'

T2 organisme actes exist (e.g. Annexe financière + organisme). The `_acte_details_t2` partial must handle both perimetre values — certain fields are conditional on `acte.perimetre`. See the form partials in `t2_sections/` for the exact conditions (e.g. `impact_autre_cbcm` is labeled "CBCM" for état, "CBR" for organisme).

### No controller changes needed

`ActesController#show` already loads `@acte` with `includes(:suspensions, :echeanciers, :poste_lignes)`. Add `:t2_detail` to the includes if not already present (check `set_acte` or `show` action).

Check:
```ruby
# actes_controller.rb show action or before_action :set_acte
@actes_groupe = @acte.numero_chorus.present? ? @acte.tous_actes_meme_chorus.includes(:suspensions, :echeanciers, :poste_lignes).order(...) : [@acte]
```
If iterating over `@actes_groupe` in show.html.erb, the t2_detail will be lazy-loaded per acte. For performance, add `.includes(:t2_detail)` to the includes chain.

### Test pattern

```ruby
test "GET show T2 acte nature Annexe financière displays t2_detail fields (AC3)" do
  sign_in users(:three) # DCB
  acte = users(:three).actes.create!(
    titre: 'T2', categorie_t2: 'hors_contrat', perimetre: 'etat',
    nature: 'Annexe financière', type_acte: 'avis',
    etat: "en cours d'instruction", instructeur: 'AB',
    annee: Date.today.year, date_saisine: Date.today
  )
  acte.create_t2_detail!(
    type_acte_t2: 'Initial',
    effectifs: 3.5,
    corps: 'Corps test',
    impact_schema_emplois: true,
    impact_autre_cbcm: false
  )
  get acte_path(acte)
  assert_response :success
  assert_select "td", text: "Initial"
  assert_select "td", text: "3.5"
  assert_select "td", text: "Corps test"
end
```

### Files to create/modify

- `app/views/actes/show.html.erb` — add T2 branch (lines 91–95)
- `app/views/actes/_acte_details_t2.html.erb` — **new** main show partial for T2
- `app/views/actes/t2_sections/_show_annexe_financiere.html.erb` — **new**
- `app/views/actes/t2_sections/_show_isp.html.erb` — **new**
- `app/views/actes/t2_sections/_show_fongibilite_asymetrique.html.erb` — **new**
- `app/views/actes/t2_sections/_show_marche.html.erb` — **new**
- `app/views/actes/t2_sections/_show_mesure_transversale.html.erb` — **new**
- `app/views/actes/t2_sections/_show_enveloppe_limitative.html.erb` — **new**
- `app/views/actes/t2_sections/_show_referentiel.html.erb` — **new**
- `app/helpers/actes_helper.rb` — add `format_boolean` helper if not already present
- `app/controllers/actes_controller.rb` — add `:t2_detail` to includes in show if needed
- `test/controllers/actes_controller_test.rb` — add 10 tests

### References

- Epic spec — FR8/Story 2.12 (implicit): [_bmad-output/planning-artifacts/epics-t2-integration.md](_bmad-output/planning-artifacts/epics-t2-integration.md)
- Pattern reference — `_acte_details.html.erb`: [app/views/actes/_acte_details.html.erb](app/views/actes/_acte_details.html.erb)
- Pattern reference — `_acte_details_organisme.html.erb`: [app/views/actes/_acte_details_organisme.html.erb](app/views/actes/_acte_details_organisme.html.erb)
- Show routing: [app/views/actes/show.html.erb](app/views/actes/show.html.erb:91)
- Form partials (to mirror in read-only): [app/views/actes/t2_sections/](app/views/actes/t2_sections/)
- T2Detail model: [app/models/t2_detail.rb](app/models/t2_detail.rb)
- Critères conditions — Story 2.9: [_bmad-output/implementation-artifacts/2-9-formulaire-t2-etape-2-criteres-de-controle.md](_bmad-output/implementation-artifacts/2-9-formulaire-t2-etape-2-criteres-de-controle.md)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `referentiel_type` is a boolean column (not string) — updated partial to render DSFR icon instead of `format_value`
- T2 actes with `nature: 'Marché'` + `perimetre: 'etat'` require `montant_ae` (model validation) — added to test fixtures

### Completion Notes List

- All 94 tests pass (0 failures, 0 errors)
- `_show_referentiel.html.erb` renders `referentiel_type` as a boolean DSFR icon (Oui/Non)
- T2 branch in `show.html.erb` precedes perimetre check to avoid T2+organisme routing to wrong partial

### File List

- `app/views/actes/show.html.erb`
- `app/views/actes/_acte_details_t2.html.erb` (new)
- `app/views/actes/t2_sections/_show_annexe_financiere.html.erb` (new)
- `app/views/actes/t2_sections/_show_isp.html.erb` (new)
- `app/views/actes/t2_sections/_show_fongibilite_asymetrique.html.erb` (new)
- `app/views/actes/t2_sections/_show_marche.html.erb` (new)
- `app/views/actes/t2_sections/_show_mesure_transversale.html.erb` (new)
- `app/views/actes/t2_sections/_show_enveloppe_limitative.html.erb` (new)
- `app/views/actes/t2_sections/_show_referentiel.html.erb` (new)
- `app/controllers/actes_controller.rb` (added `:t2_detail` to includes)
- `test/controllers/actes_controller_test.rb` (10 new tests)
