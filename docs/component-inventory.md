# Component Inventory — Avisbop

## Overview

Avisbop uses a server-rendered architecture with Rails ERB views enhanced by Stimulus controllers for interactivity. The UI follows the DSFR (Systeme de Design de l'Etat) French government design system.

---

## Stimulus Controllers (30 total)

### Form Management

| Controller | File | Purpose |
|------------|------|---------|
| acte_form | `acte_form_controller.js` | Complex HT2 act form with number formatting, validation, state transitions, Chorus number checking |
| form | `form_controller.js` | Budget schema forms with AE/CP balance calculations, field validation |
| session | `session_controller.js` | Login form with profile-based field visibility, dynamic user list |
| nested_form | `nested_form_controller.js` | Extends @stimulus-components for adding/removing line items |
| nested_form2 | `nested_form2_controller.js` | Alternative nested form variant |
| conditional_field | `conditional_field_controller.js` | Show/hide fields based on checkbox state, manages required attributes |
| operation_budgetaire | `operation_budgetaire_controller.js` | Budget operation conditional visibility |
| year_validation | `year_validation_controller.js` | Year input validation (4 digits) |

### Search & Filtering

| Controller | File | Purpose |
|------------|------|---------|
| autocomplete | `autocomplete_controller.js` | Generic code/reference autocomplete via AJAX |
| autocomplete_organisme | `autocomplete_organisme_controller.js` | Organization search with acronym-name format |
| filter | `filter_controller.js` | Tab and filter management in tables |
| controleur_filter | `controleur_filter_controller.js` | Profile-based controller filtering (CBR/DCB) |
| date_range_filter | `date_range_filter_controller.js` | Date range constraining based on year |
| search | `search_controller.js` | Search interface expand/collapse |
| request | `request_controller.js` | Dynamic tag management for filters |

### Data Display

| Controller | File | Purpose |
|------------|------|---------|
| highcharts | `highcharts_controller.js` | 30+ chart types: pie, bar, column, line, bubble |
| highcharts_actes | `highcharts_actes_controller.js` | Act-specific charts with CSS variable colors |
| sheet | `sheet_controller.js` | Editable jSpreadsheet integration |
| sheet_readonly | `sheet_readonly_controller.js` | Read-only spreadsheet display |
| toggle | `toggle_controller.js` | Show/hide sections, smooth scroll, button text updates |

### Selection & Tagging

| Controller | File | Purpose |
|------------|------|---------|
| bulk | `bulk_controller.js` | Bulk checkbox selection with count display |
| multi_select | `multi_select_controller.js` | Multi-select tag management |
| multi_select_filter | `multi_select_filter_controller.js` | Multi-select with form sync |
| tag_select | `tag_select_controller.js` | Checkbox styling (is-selected class) |

### Date & Time

| Controller | File | Purpose |
|------------|------|---------|
| flatpickr | `flatpickr_controller.js` | Date picker with French locale (d/m/Y) |
| flatpickr_modal | `flatpickr_modal_controller.js` | Modal-aware date picker |

### Export & Rich Text

| Controller | File | Purpose |
|------------|------|---------|
| pdf_export | `pdf_export_controller.js` | PDF export via html2canvas + jsPDF |
| trix | `trix_controller.js` | Rich text editor (image-only uploads, 1MB limit) |

---

## View Components (ERB Templates)

### Layouts

| Template | Purpose |
|----------|---------|
| `layouts/application.html.erb` | Master layout with DSFR 1.14.0, importmap, stylesheets |
| `layouts/_header.html.erb` | Navigation with role-based visibility, responsive menu |
| `layouts/_footer.html.erb` | DSFR footer with theme selector (light/dark/system) |
| `layouts/pdf.html.erb` | Minimal layout for PDF rendering |

### HT2 Actes (Largest View Section)

| Template | Purpose |
|----------|---------|
| `ht2_actes/index.html.erb` | List view with advanced filters, search, pagination (500+ lines) |
| `ht2_actes/new.html.erb` | Modal creation form (step 1: type/perimeter selection) |
| `ht2_actes/edit.html.erb` | Multi-step edit with side navigation |
| `ht2_actes/show.html.erb` | Detail view with tabs |
| `ht2_actes/_form_informations.html.erb` | Step 1: General information (150+ lines) |
| `ht2_actes/_form_criteres.html.erb` | Step 2: Validation criteria checks |
| `ht2_actes/_form_proposition_decision.html.erb` | Step 3: Decision proposal |
| `ht2_actes/_form_suspension.html.erb` | Suspension/interruption management |
| `ht2_actes/_form_echeancier.html.erb` | Budget scheduler (nested form) |
| `ht2_actes/_form_poste_ligne.html.erb` | Line item template (nested form) |
| `ht2_actes/_flash_message.html.erb` | Status notification display |
| `ht2_actes/synthese.html.erb` | Dashboard with charts |
| `ht2_actes/synthese_temporelle.html.erb` | Time-based analytics |
| `ht2_actes/synthese_suspensions.html.erb` | Suspension analytics |
| `ht2_actes/export.html.erb` | Bulk export interface |
| `ht2_actes/export_pdf.html.erb` | PDF export preview |

### Avis (Opinions)

| Template | Purpose |
|----------|---------|
| `avis/index.html.erb` | Opinion history with filters |
| `avis/_form_debut.html.erb` | Initial management opinion form |
| `avis/_form_services_votes.html.erb` | Voted services opinion form |
| `avis/_form_execution.html.erb` | Execution phase opinion form |
| `avis/_rappel_ecart.html.erb` | Execution comparison accordion |

### Other Resource Views

| Directory | Templates | Purpose |
|-----------|-----------|---------|
| `bops/` | index, show, edit, _form_bop_dotation | BOP management |
| `programmes/` | index, show, edit | Program directory |
| `schemas/` | index, show, edit | Budget planning schemas |
| `gestion_schemas/` | edit, _form | Schema management forms |
| `centre_financiers/` | index, show, new, edit | Financial center management |
| `organismes/` | index, show, new, edit | Organization management |
| `ministeres/` | index, show | Ministry directory |
| `missions/` | index, show | Mission directory |
| `suspensions/` | _form | Suspension form partial |
| `users/` | index, show, new, edit | User management |
| `pages/` | accueil, mentions_legales, faq | Static pages |
| `errors/` | 404, 500, 503 | Error pages |
| `devise/` | sessions/new, passwords/* | Authentication views |

---

## DSFR Components Used

### Layout
- `.fr-container` — Content container
- `.fr-grid-row`, `.fr-col-*` — Responsive grid (12-column)
- `.fr-header` — Navigation header
- `.fr-footer` — Page footer

### Navigation
- `.fr-nav` — Main navigation
- `.fr-sidemenu` — Sidebar navigation
- `.fr-tabs` — Tab panels
- `.fr-accordion` — Collapsible sections
- `.fr-breadcrumb` — Breadcrumb trail

### Forms
- `.fr-input`, `.fr-input-group` — Text inputs
- `.fr-select`, `.fr-select-group` — Select dropdowns
- `.fr-checkbox-group` — Checkboxes
- `.fr-radio-group` — Radio buttons
- `.fr-fieldset` — Field grouping
- `.fr-btn` — Buttons (primary, secondary, tertiary, close)

### Data Display
- `.fr-table` — Data tables
- `.fr-card` — Cards with color variants
- `.fr-badge` — Status badges with color coding
- `.fr-tag` — Filter tags
- `.fr-alert` — Alert messages (success, warning, error, info)
- `.fr-notice` — Information notices
- `.fr-tooltip` — Help tooltips

### Interaction
- `.fr-modal` — Modal dialogs (custom left-panel variant)
- `.fr-link` — Styled links
- `.fr-icon-*` — Icon system

---

## Custom Styles

### Color System (application.scss)
- `.cbleu` — Blue text
- `.crouge` — Red/danger text
- `.cwarning` — Warning orange
- `.cgreen` — Success green
- `.cblack` — Overdue/expired

### Card Variants
- `.fr-card--blue`, `.fr-card--red`, `.fr-card--green`, `.fr-card--orange`, `.fr-card--creme`

### Status Badges
| Badge Class | Meaning |
|-------------|---------|
| `fr-badge--success` | Favorable, Cloture |
| `fr-badge--error` | Defavorable, Suspendu |
| `fr-badge--new` | En pre-instruction |
| `fr-badge--green-archipel` | En cours, Type avis |
| `fr-badge--pink-tuile` | A valider, Type TF |
| `fr-badge--beige-gris-galet` | Saisine a posteriori, Type visa |
| `fr-badge--yellow-tournesol` | Cloture apres pre-instruction |
| `fr-badge--purple-glycine` | Perimetre organisme |

---

## Helpers

### Application Helper
- `format_date(date)` — French date formatting (d/m/Y)
- `format_number(number)` — French number formatting (space separators)

### Ht2Actes Helper (Most Complex)
- `badge_class_for_decision(decision)` — Decision status badge color
- `badge_class_for_type(type_acte)` — Act type badge color
- `badge_class_for_etat_actes(etat)` — State badge color
- `flag_date(date_limite)` — Deadline urgency color (green > 10d, warning > 5d, red < 5d, black overdue)
- `etat_acte(acte)` — Display state (maps suspension to interruption for visa/TF)
- `update_acte_notice(etat, etape, type_acte)` — Flash message text based on action
- `tous_types_observations` — List of 14 observation types
- `etape2_complete?(acte)` — Checks if step 2 validation is complete

### Schemas Helper
- `numero_version(schema)` — Schema version number within programme/year

### Gestion Schemas Helper
- `find_gestion_schema_vision(gestion_schemas, vision, profil)` — Lookup by vision/profil

### Bops Helper
- `format_date(date)` — Date formatting
- Various display helpers

---

## Admin Interface (ActiveAdmin)

16 admin resources providing full CRUD:
- admin_users, avis, bops, centre_financiers, dashboard, echeanciers, gestion_schemas, ht2_actes, ministeres, missions, poste_lignes, programmes, schemas, suspensions, transferts, users

Each resource includes: index with filters, show view, edit form, and batch actions where appropriate.
