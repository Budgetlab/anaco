# API Contracts & Routes — Avisbop

## Overview

Avisbop is a server-rendered Rails application. All routes are scoped under `/anaco`. There are no standalone REST API endpoints — the application serves HTML views with Turbo Frame responses and some JSON endpoints for autocomplete/filtering.

---

## Route Scope

All application routes are nested under `scope '/anaco'`. The root path (`/`) redirects to `/anaco`.

---

## Authentication Routes

### Devise — Admin Users
- `GET /anaco/admin/login` — Admin sign in
- `POST /anaco/admin/login` — Admin sign in submit
- `DELETE /anaco/admin/logout` — Admin sign out

### Devise — Regular Users
- `GET /anaco/users/sign_in` — User sign in
- `POST /anaco/users/sign_in` — User sign in submit
- `DELETE /anaco/users/sign_out` — User sign out
- `GET /anaco/users/password/new` — Forgot password
- `POST /anaco/users/password` — Send reset instructions
- `GET /anaco/users/password/edit` — Edit password
- `PATCH /anaco/users/password` — Update password

---

## Active Admin Routes

`/anaco/admin/*` — Full CRUD admin interface for all models via ActiveAdmin.

---

## Resource Routes

### BOPs (Budget Operating Programs)

| Method | Path | Action | Notes |
|--------|------|--------|-------|
| GET | /anaco/bops | index | List all BOPs with filters |
| GET | /anaco/bops/new | new | New BOP form |
| POST | /anaco/bops | create | Create BOP |
| GET | /anaco/bops/:id | show | BOP detail with nested avis |
| GET | /anaco/bops/:id/edit | edit | Edit BOP form |
| PATCH | /anaco/bops/:id | update | Update BOP |
| DELETE | /anaco/bops/:id | destroy | Delete BOP |

**Nested:** `resources :avis` under bops (consultation, remplissage actions).

### Avis (Opinions)

| Method | Path | Action | Notes |
|--------|------|--------|-------|
| GET | /anaco/avis | index | List all opinions |
| GET | /anaco/bops/:bop_id/avis/:id/consultation | consultation | View opinion |
| GET | /anaco/bops/:bop_id/avis/:id/remplissage | remplissage | Fill/edit opinion form |
| POST | /anaco/avis/import | import | Import from spreadsheet |

### HT2 Actes (Financial Acts)

| Method | Path | Action | Notes |
|--------|------|--------|-------|
| GET | /anaco/ht2_actes | index | List with advanced filters |
| GET | /anaco/ht2_actes/new | new | New act modal form |
| POST | /anaco/ht2_actes | create | Create act |
| GET | /anaco/ht2_actes/:id | show | Act detail view |
| GET | /anaco/ht2_actes/:id/edit | edit | Multi-step edit form |
| PATCH | /anaco/ht2_actes/:id | update | Update act |
| DELETE | /anaco/ht2_actes/:id | destroy | Delete act |

**Nested under ht2_actes:**

| Method | Path | Action |
|--------|------|--------|
| POST | /anaco/ht2_actes/:id/suspensions | create suspension |
| PATCH | /anaco/ht2_actes/:id/suspensions/:s_id | update suspension |

**Custom HT2 Actes routes:**

| Method | Path | Purpose |
|--------|------|---------|
| POST | /anaco/ht2_actes/import | Bulk import from spreadsheet |
| GET | /anaco/ht2_actes/export | Export listing (XLSX/CSV) |
| GET | /anaco/ht2_actes/:id/export_pdf | PDF export for single act |
| POST | /anaco/ht2_actes/validate_bulk | Bulk validation |
| POST | /anaco/ht2_actes/close_bulk | Bulk closure |
| POST | /anaco/ht2_actes/generate_pdf | Background PDF generation |
| GET | /anaco/ht2_actes/synthese | Dashboard/synthesis view |
| GET | /anaco/ht2_actes/synthese_temporelle | Time-based analysis |
| GET | /anaco/ht2_actes/synthese_anomalies | Anomaly synthesis |
| GET | /anaco/ht2_actes/synthese_suspensions | Suspension analysis |
| GET | /anaco/ht2_actes/filter_centre_financiers | JSON: filter CF list |
| GET | /anaco/ht2_actes/filter_organismes | JSON: filter organisms |

### Programmes

| Method | Path | Action |
|--------|------|--------|
| GET | /anaco/programmes | index |
| GET | /anaco/programmes/:id | show |
| GET | /anaco/programmes/:id/edit | edit |
| PATCH | /anaco/programmes/:id | update |

**Nested:** `resources :schemas` under programmes.

### Schemas & Gestion Schemas

| Method | Path | Action |
|--------|------|--------|
| GET | /anaco/schemas | index |
| GET | /anaco/programmes/:programme_id/schemas/:id | show |
| GET | /anaco/programmes/:programme_id/schemas/:id/edit | edit |
| PATCH | /anaco/programmes/:programme_id/schemas/:id | update |

**Nested:** `resources :gestion_schemas` under schemas.

### Reference Data

| Resource | Path | Actions |
|----------|------|---------|
| Missions | /anaco/missions | index, show, edit, update |
| Ministeres | /anaco/ministeres | index, show, edit, update |
| Centre Financiers | /anaco/centre_financiers | index, show, new, create, edit, update |
| Organismes | /anaco/organismes | index, show, new, create, edit, update |
| Users | /anaco/users | index, show, new, create, edit, update |

---

## Import Routes

| Method | Path | Purpose |
|--------|------|---------|
| POST | /anaco/users/import | Import users from spreadsheet |
| POST | /anaco/bops/import | Import BOPs |
| POST | /anaco/programmes/import | Import programmes |
| POST | /anaco/avis/import | Import avis |
| POST | /anaco/ht2_actes/import | Import acts |
| POST | /anaco/centre_financiers/import | Import financial centers |
| POST | /anaco/organismes/import | Import organisms |

---

## Dashboard & Analytics Routes

| Method | Path | Purpose |
|--------|------|---------|
| GET | /anaco/tableau_de_bord | Main dashboard |
| GET | /anaco/ht2_actes/synthese | Acts synthesis |
| GET | /anaco/ht2_actes/synthese_temporelle | Time analysis |
| GET | /anaco/ht2_actes/synthese_anomalies | Anomaly detection |
| GET | /anaco/ht2_actes/synthese_suspensions | Suspension analysis |

---

## Static & Error Pages

| Method | Path | Purpose |
|--------|------|---------|
| GET | /anaco/pages/accueil | Home page |
| GET | /anaco/pages/mentions_legales | Legal mentions |
| GET | /anaco/pages/faq | FAQ |
| GET | /500 | Server error |
| GET | /404 | Not found |
| GET | /503 | Service unavailable |

---

## JSON/AJAX Endpoints

These endpoints return JSON for client-side interactivity:

| Method | Path | Purpose |
|--------|------|---------|
| GET | /anaco/ht2_actes/filter_centre_financiers | Autocomplete CF lookup |
| GET | /anaco/ht2_actes/filter_organismes | Autocomplete organism lookup |
| GET | /anaco/organismes/search | Organism search |

---

## Controller Architecture

### ApplicationController
- `before_action :authenticate_user!` — All routes require authentication
- Includes `Pagy::Backend` for pagination
- Sets `@current_user` via `current_user` helper

### Key Controller Patterns
- **Filters:** Ransack-based search with `params[:q]`
- **Pagination:** Pagy with 10 items/page default
- **Response formats:** HTML (primary), XLSX (exports), PDF (act documents), JSON (autocomplete)
- **Strong parameters:** Defined per controller with extensive permit lists
- **Turbo Frames:** Used for inline updates and partial page rendering
