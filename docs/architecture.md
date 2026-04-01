# Architecture — Avisbop

## Executive Summary

Avisbop (also known internally as "Anaco") is a budget opinion and financial act management system for the French government. It enables financial controllers (CBR/DCB) to manage budget opinions (avis), financial acts (actes HT2), budget planning schemas, and organizational structure (programs, missions, ministries). The system handles the full lifecycle of financial acts: creation, instruction, validation, suspension, and closure.

---

## Architecture Pattern

**Type:** Monolithic MVC (Model-View-Controller)
**Style:** Server-rendered with progressive enhancement via Hotwire

The application follows the classic Ruby on Rails MVC pattern with Hotwire (Turbo + Stimulus) for SPA-like interactivity without a JavaScript SPA framework. Views are server-rendered ERB templates enhanced with 30 Stimulus controllers for client-side behavior.

```
┌──────────────────────────────────────────────────────┐
│                     Browser                          │
│  ┌─────────────┐  ┌──────────┐  ┌────────────────┐  │
│  │ Turbo Drive  │  │ Stimulus │  │ Highcharts/    │  │
│  │ (Navigation) │  │ (30 ctrls)│ │ jSpreadsheet   │  │
│  └──────┬──────┘  └─────┬────┘  └───────┬────────┘  │
└─────────┼───────────────┼───────────────┼────────────┘
          │ HTML/Turbo    │ fetch()       │
          ▼               ▼               │
┌──────────────────────────────────────────────────────┐
│                  Rails Application                    │
│  ┌──────────────────────────────────────────────┐    │
│  │              Controllers (16)                 │    │
│  │  ApplicationController (Devise + Pagy)        │    │
│  │  ├── Ht2ActesController (core)               │    │
│  │  ├── AvisController                           │    │
│  │  ├── BopsController                           │    │
│  │  ├── ProgrammesController                     │    │
│  │  ├── SchemasController                        │    │
│  │  └── ... (11 more)                            │    │
│  └──────────────────┬───────────────────────────┘    │
│                     │                                 │
│  ┌──────────────────▼───────────────────────────┐    │
│  │                Models (17)                    │    │
│  │  Ht2Acte (core: state machine, 65+ cols)     │    │
│  │  ├── Suspension, Echeancier, PosteLigne      │    │
│  │  User (Devise auth, complex queries)          │    │
│  │  Programme → Ministere, Mission               │    │
│  │  Bop → Avi                                    │    │
│  │  Schema → GestionSchema → Transfert           │    │
│  │  CentreFinancier, Organisme                   │    │
│  └──────────────────┬───────────────────────────┘    │
│                     │                                 │
│  ┌──────────────────▼───────────────────────────┐    │
│  │              PostgreSQL                       │    │
│  │  28 application tables                        │    │
│  │  unaccent extension for French search         │    │
│  └──────────────────────────────────────────────┘    │
│                                                       │
│  ┌──────────────────────────────────────────────┐    │
│  │           Background Jobs (Solid Queue)       │    │
│  │  GenerateActePdfJob, UrlToPdfJob              │    │
│  └──────────────────────────────────────────────┘    │
│                                                       │
│  ┌──────────────────────────────────────────────┐    │
│  │           Admin Interface (ActiveAdmin)       │    │
│  │  16 admin resources at /anaco/admin           │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

---

## Technology Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| Language | Ruby | 3.4.8 | Primary language |
| Framework | Rails | 8.1.1 | MVC web framework |
| Database | PostgreSQL | Cloud SQL | Primary data store |
| Web Server | Puma | 6.4.2 | Application server |
| Authentication | Devise | latest | User + Admin auth |
| Admin | ActiveAdmin | latest | Back-office interface |
| Frontend JS | Stimulus | latest | 30 interactive controllers |
| Page Nav | Turbo Rails | latest | SPA-like navigation |
| Rich Text | Trix/ActionText | latest | Content editing |
| CSS | DSFR 1.14.0 | latest | French government design system |
| CSS Preprocessor | Sass | latest | SCSS stylesheets |
| Asset Pipeline | Sprockets + Importmap | latest | ESM import maps |
| Charts | Highcharts | 11.4.1 | Data visualization |
| Spreadsheets | jspreadsheet-ce | 5.0.3 | Interactive tables |
| Date Picker | Flatpickr | 4.6.13 | Date selection (French) |
| PDF | Grover + Puppeteer | latest | Chromium PDF rendering |
| Search | Ransack | latest | Advanced filtering |
| Pagination | Pagy | 43.2 | Efficient pagination |
| Excel | caxlsx + Roo | latest | Import/export |
| File Storage | Active Storage + GCS | latest | Document storage |
| Background Jobs | Solid Queue | latest | Database-backed queue |
| Deployment (App) | Cloud Run | - | Auto-scaling containers |
| Deployment (Workers) | Kamal | latest | Docker on GCP VM |
| CI/CD | GitHub Actions + Cloud Build | - | Testing + deployment |

---

## Data Architecture

### Core Domain Model

The application revolves around three main business domains:

#### 1. Budget Opinions (Avis)

```
User → manages → Bop → has_many → Avi
                  │
                  └── belongs_to → Programme → Ministere
                                              → Mission
```

Opinions track financial controller assessments of Budget Operating Programs (BOPs) across phases: "debut de gestion" (start), "services votes" (voted services), and "execution".

#### 2. Financial Acts (Actes HT2)

```
User → creates → Ht2Acte ──*── CentreFinancier (HABTM)
                    │        └── Organisme (HABTM)
                    │
                    ├── has_many → Suspension
                    ├── has_many → Echeancier
                    └── has_many → PosteLigne
```

Acts represent financial control actions with a state machine: pre-instruction → instruction → validation → closure (with possible suspension/interruption). Three types: avis, visa, and TF (transfert financier).

#### 3. Budget Planning (Schemas)

```
Programme → has_many → Schema → has_many → GestionSchema → has_many → Transfert
```

Schemas track end-of-management budget planning with detailed financial fields across two visions (RPROG/CBCM) and two profiles (T2/HT2).

### Database Design Patterns

- **State Machine:** `Ht2Acte.etat` with 8 valid states managed via `after_save` callbacks
- **Auto-numbering:** `numero_formate` (YY-XXXX) per user per year
- **Computed Fields:** `date_limite` (deadline), `delai_traitement` (processing delay) calculated from business rules
- **HABTM Relationships:** Acts connect to multiple financial centers and organisms via join tables
- **Soft Associations:** `centre_financier_code` string field for primary CF lookup (alongside HABTM)
- **JSONB Storage:** `sheet_data` for spreadsheet data embedded in acts
- **Rich Text:** `commentaire_disponibilite_credits` via ActionText
- **File Attachments:** `pdf_files` via Active Storage

---

## Authentication & Authorization

### Authentication

- **Regular Users:** Devise with database_authenticatable, registerable, recoverable, rememberable, validatable
- **Admin Users:** Separate Devise model for ActiveAdmin access
- **Session Management:** Cookie-based sessions with `authenticate_user!` before_action on all controllers

### Authorization

- Role-based via `user.statut` field (CBR, DCB profiles)
- Navigation visibility controlled by user role in header partial
- No formal authorization framework (no Pundit/CanCanCan)

---

## Frontend Architecture

### Hotwire Stack

1. **Turbo Drive** — Intercepts link clicks and form submissions, replaces `<body>` without full page reload
2. **Turbo Frames** — Partial page updates for filters, pagination, inline editing
3. **Stimulus Controllers** — 30 controllers for interactive behavior (forms, charts, autocomplete, validation)

### Key Frontend Patterns

| Pattern | Implementation |
|---------|---------------|
| Number formatting | French locale (thin space thousands, comma decimal) via Stimulus |
| Date picking | Flatpickr with French locale, d/m/Y format |
| Autocomplete | AJAX fetch to controller actions, dropdown results |
| Charts | Highcharts with CSS variable colors, export capabilities |
| Spreadsheets | jspreadsheet-ce with hidden input sync |
| PDF export | Client-side (html2canvas + jsPDF) and server-side (Grover/Chromium) |
| Nested forms | Dynamic add/remove via @stimulus-components/rails-nested-form |
| Conditional fields | Show/hide with required attribute management |
| Bulk operations | Checkbox selection with batch action buttons |

### DSFR Design System

The UI follows the DSFR (Systeme de Design de l'Etat) — the French government's mandatory design system for public services. This includes:
- Standardized color palette and typography
- Accessible form components
- Responsive grid system
- Light/dark/system theme support
- Government branding (Marianne logo, tricolor)

---

## Background Processing

### Solid Queue

- **Adapter:** Database-backed (PostgreSQL `queue` database)
- **Workers:** Run on GCP VM via Kamal deployment
- **Concurrency:** 4 threads

### Jobs

| Job | Purpose |
|-----|---------|
| `GenerateActePdfJob` | Generate PDF for a single act via Grover/Chromium |
| `UrlToPdfJob` | Convert URL to PDF document |

PDF generation requires Chromium (Puppeteer in development, system Chromium in production).

---

## Deployment Architecture

### Production Environment

| Component | Platform | Details |
|-----------|----------|---------|
| Web App | Google Cloud Run | Auto-scaling, port 8080 |
| Workers | GCP VM (Kamal) | 34.163.126.114, Solid Queue |
| Database | Google Cloud SQL | PostgreSQL, europe-west1 |
| Storage | Google Cloud Storage | anaco-bucket |
| CI/CD (Tests) | GitHub Actions | On push/PR to main |
| CI/CD (Deploy) | Google Cloud Build | Docker build + migration + deploy |

### Deployment Flow

```
Developer → git push → GitHub Actions (tests + lint)
                              │
                              ▼ (if main branch)
                     Cloud Build (cloudbuild.yaml)
                              │
                     ┌────────┼────────┐
                     │                 │
              Docker Build      DB Migrate
                     │                 │
              Push to GCR       Cloud SQL
                     │
              Deploy to Cloud Run
```

Workers are deployed separately via Kamal:
```
Developer → kamal deploy → Build Docker image → Push to Docker Hub → Deploy to GCP VM
```

---

## Testing Strategy

| Test Type | Framework | Location | Coverage |
|-----------|-----------|----------|----------|
| Model Tests | Minitest | `test/models/` | 15 files |
| Controller Tests | Minitest (Integration) | `test/controllers/` | 14 files |
| Job Tests | Minitest | `test/jobs/` | 1 file |
| System Tests | Minitest + Selenium/Chrome | `test/system/` | Limited |
| Security Scan | Brakeman | CI pipeline | Static analysis |
| Dependency Audit | Bundler-Audit | CI pipeline | Vulnerability check |

---

## Key Architectural Decisions

1. **Monolith over microservices** — Single Rails app handles all functionality. Appropriate for the team size and domain complexity.

2. **Hotwire over SPA** — Server-rendered HTML with Turbo/Stimulus instead of React/Vue. Reduces frontend complexity while maintaining interactive UX.

3. **Importmap over bundlers** — No webpack/esbuild build step. JavaScript dependencies loaded via ESM import maps. Simpler toolchain.

4. **Solid Queue over Redis** — Database-backed job queue (PostgreSQL) instead of Redis-backed (Sidekiq). One fewer infrastructure dependency.

5. **DSFR design system** — Mandatory for French government services. Provides accessibility compliance and consistent branding.

6. **Split deployment** — Web app on Cloud Run (auto-scaling, serverless) with workers on a dedicated VM (for Chromium/PDF generation that needs more resources).

7. **Cloud SQL Proxy** — Workers connect to Cloud SQL via a sidecar proxy container, while Cloud Run uses native socket connection.

8. **ActiveAdmin for back-office** — Rapid admin interface without custom code. Separate authentication from main app users.

---

## Risks & Technical Debt

| Risk | Severity | Notes |
|------|----------|-------|
| No authorization framework | Medium | Role checks are scattered across views/controllers |
| README is default template | Low | No project documentation for onboarding |
| Some fixtures cause FK violations | Low | Test data setup could be improved |
| RuboCop disabled in CI | Low | Code style not enforced |
| Single Chromium dependency for PDF | Medium | Workers depend on Chromium availability |
| Complex Ht2Acte model (65+ columns) | Medium | Could benefit from decomposition |
| No i18n for French content | Low | Hardcoded French strings in views and helpers |
