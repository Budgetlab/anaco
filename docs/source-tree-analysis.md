# Source Tree Analysis — Avisbop

## Overview

Avisbop is a monolithic Ruby on Rails 8.1 application following standard Rails conventions. All source code lives in a single repository with no workspace/monorepo structure.

---

## Annotated Directory Tree

```
avisbop/
├── app/                          # Main application directory
│   ├── admin/                    # ActiveAdmin resource definitions (16 files)
│   │   ├── dashboard.rb          # Admin dashboard
│   │   ├── ht2_actes.rb          # Acts admin CRUD
│   │   ├── users.rb              # User admin management
│   │   ├── avis.rb               # Opinions admin
│   │   ├── bops.rb               # BOPs admin
│   │   ├── programmes.rb         # Programs admin
│   │   ├── schemas.rb            # Schemas admin
│   │   ├── gestion_schemas.rb    # Schema management admin
│   │   ├── centre_financiers.rb  # Financial centers admin
│   │   ├── organismes.rb         # Organisms admin
│   │   ├── ministeres.rb         # Ministries admin
│   │   ├── missions.rb           # Missions admin
│   │   ├── suspensions.rb        # Suspensions admin
│   │   ├── echeanciers.rb        # Schedules admin
│   │   ├── poste_lignes.rb       # Line items admin
│   │   └── transferts.rb         # Transfers admin
│   │
│   ├── assets/                   # Static assets
│   │   ├── stylesheets/
│   │   │   ├── application.scss  # Main styles (~550 lines, custom + DSFR overrides)
│   │   │   ├── dsfr.scss         # DSFR 1.14.0 framework CSS
│   │   │   ├── utility.scss      # Spacing/layout utilities
│   │   │   ├── active_admin.scss # Admin panel styles
│   │   │   └── actiontext.scss   # Rich text editor styles
│   │   ├── fonts/                # DSFR font files
│   │   ├── images/               # Application images/icons
│   │   └── config/               # Asset configuration
│   │
│   ├── channels/                 # Action Cable channels (unused, default)
│   │
│   ├── controllers/              # Rails controllers (16 files)
│   │   ├── application_controller.rb    # [ENTRY] Base controller: Devise auth, Pagy
│   │   ├── ht2_actes_controller.rb      # [CORE] Acts CRUD + bulk ops + syntheses
│   │   ├── avis_controller.rb           # Opinions management
│   │   ├── bops_controller.rb           # BOP management
│   │   ├── programmes_controller.rb     # Program directory
│   │   ├── schemas_controller.rb        # Budget schemas
│   │   ├── gestion_schemas_controller.rb # Schema management
│   │   ├── centre_financiers_controller.rb # Financial centers
│   │   ├── organismes_controller.rb     # Organizations
│   │   ├── ministeres_controller.rb     # Ministries
│   │   ├── missions_controller.rb       # Missions
│   │   ├── suspensions_controller.rb    # Act suspensions
│   │   ├── users_controller.rb          # User management
│   │   ├── pages_controller.rb          # Static pages (home, legal, FAQ)
│   │   ├── sessions_controller.rb       # Custom Devise session handling
│   │   └── errors_controller.rb         # Error pages (404, 500, 503)
│   │
│   ├── helpers/                  # View helpers (14 files)
│   │   ├── application_helper.rb        # Date/number formatting
│   │   ├── ht2_actes_helper.rb          # [COMPLEX] Badge classes, date flags, state display
│   │   ├── avis_helper.rb              # Opinion display helpers
│   │   ├── bops_helper.rb              # BOP display helpers
│   │   ├── schemas_helper.rb           # Version numbering
│   │   ├── gestion_schemas_helper.rb   # Vision/profil lookup
│   │   └── ... (8 empty module stubs)
│   │
│   ├── javascript/               # Frontend JavaScript
│   │   ├── application.js        # [ENTRY] Turbo, Stimulus, Trix imports
│   │   └── controllers/          # Stimulus controllers (30 files)
│   │       ├── index.js           # Controller registration
│   │       ├── acte_form_controller.js        # [COMPLEX] Act form logic
│   │       ├── form_controller.js             # Budget form calculations
│   │       ├── highcharts_controller.js       # [COMPLEX] 30+ chart definitions
│   │       ├── highcharts_actes_controller.js # Act-specific charts
│   │       ├── session_controller.js          # Login form
│   │       ├── autocomplete_controller.js     # Generic autocomplete
│   │       ├── autocomplete_organisme_controller.js # Org autocomplete
│   │       ├── sheet_controller.js            # Editable spreadsheet
│   │       ├── sheet_readonly_controller.js   # Read-only spreadsheet
│   │       ├── flatpickr_controller.js        # Date picker
│   │       ├── flatpickr_modal_controller.js  # Modal date picker
│   │       ├── pdf_export_controller.js       # PDF export
│   │       ├── bulk_controller.js             # Bulk selection
│   │       ├── filter_controller.js           # Filter/tab management
│   │       ├── multi_select_controller.js     # Multi-select tags
│   │       ├── nested_form_controller.js      # Nested form items
│   │       ├── toggle_controller.js           # Show/hide sections
│   │       ├── conditional_field_controller.js # Field visibility
│   │       ├── trix_controller.js             # Rich text config
│   │       └── ... (10 more controllers)
│   │
│   ├── jobs/                     # Background jobs (Solid Queue)
│   │   ├── application_job.rb           # Base job class
│   │   ├── url_to_pdf_job.rb            # URL to PDF conversion
│   │   └── generate_acte_pdf_job.rb     # Act PDF generation
│   │
│   ├── mailers/                  # Email mailers
│   │   └── application_mailer.rb        # Base mailer (unused)
│   │
│   ├── models/                   # Active Record models (17 files)
│   │   ├── application_record.rb        # Base model class
│   │   ├── ht2_acte.rb                  # [CORE] Acts (65+ cols, state machine)
│   │   ├── avi.rb                       # Opinions with import
│   │   ├── bop.rb                       # Budget programs
│   │   ├── programme.rb                 # Programs
│   │   ├── schema.rb                    # Budget schemas
│   │   ├── gestion_schema.rb            # Schema management (55+ financial cols)
│   │   ├── centre_financier.rb          # Financial centers
│   │   ├── organisme.rb                 # Organizations
│   │   ├── ministere.rb                 # Ministries
│   │   ├── mission.rb                   # Missions
│   │   ├── suspension.rb               # Act suspensions
│   │   ├── echeancier.rb               # Payment schedules
│   │   ├── poste_ligne.rb              # Line items
│   │   ├── transfert.rb                # Budget transfers
│   │   ├── user.rb                     # Users (Devise + complex query methods)
│   │   └── admin_user.rb               # Admin users (Devise)
│   │
│   └── views/                    # ERB templates
│       ├── layouts/              # Application layouts
│       │   ├── application.html.erb     # [ENTRY] Master template with DSFR
│       │   ├── _header.html.erb         # Navigation (role-based)
│       │   ├── _footer.html.erb         # Footer with theme selector
│       │   └── pdf.html.erb             # PDF export layout
│       ├── ht2_actes/            # [LARGEST] Act views (15+ templates)
│       ├── avis/                 # Opinion views
│       ├── bops/                 # BOP views
│       ├── programmes/           # Program views
│       ├── schemas/              # Schema views
│       ├── gestion_schemas/      # Schema management views
│       ├── centre_financiers/    # Financial center views
│       ├── organismes/           # Organization views
│       ├── ministeres/           # Ministry views
│       ├── missions/             # Mission views
│       ├── suspensions/          # Suspension views
│       ├── users/                # User management views
│       ├── pages/                # Static pages (home, legal, FAQ)
│       ├── errors/               # Error pages (404, 500, 503)
│       └── devise/               # Authentication views
│
├── bin/                          # Executable scripts
│   ├── rails                    # Rails CLI
│   ├── rake                     # Rake tasks
│   ├── setup                    # Project setup script
│   ├── dev                      # Development helper
│   ├── jobs                     # Solid Queue worker launcher
│   └── ...
│
├── config/                       # Configuration
│   ├── application.rb           # [ENTRY] Rails app config (locale: fr)
│   ├── routes.rb                # [CRITICAL] All routes (scoped under /anaco)
│   ├── database.yml             # PostgreSQL config (dev/test/Cloud SQL prod)
│   ├── deploy.yml               # Kamal deployment (workers on GCP VM)
│   ├── storage.yml              # Active Storage (local + Google Cloud Storage)
│   ├── importmap.rb             # Frontend JS dependencies (ESM)
│   ├── puma.rb                  # Puma web server config
│   ├── queue.yml                # Solid Queue config
│   ├── recurring.yml            # Recurring job schedules
│   ├── environments/
│   │   ├── development.rb       # Dev config (GCS storage)
│   │   ├── production.rb        # Prod config (Cloud Run, Solid Queue)
│   │   └── test.rb              # Test config
│   ├── initializers/            # Rails initializers (12 files)
│   │   ├── devise.rb            # Devise authentication config
│   │   ├── active_admin.rb      # Admin panel config
│   │   ├── grover.rb            # [CRITICAL] PDF generation (Chromium)
│   │   ├── pagy.rb              # Pagination config (10 items/page)
│   │   ├── ransack.rb           # Search predicates (contains, in_insensitive)
│   │   ├── assets.rb            # Asset pipeline (/anaco/assets prefix)
│   │   ├── active_storage.rb    # Storage routes prefix
│   │   └── ...
│   └── locales/
│       ├── en.yml               # English translations (minimal)
│       └── devise.en.yml        # Devise translations
│
├── db/                           # Database
│   ├── schema.rb                # [CRITICAL] Current schema (28 tables)
│   ├── seeds.rb                 # Seed data (admin user)
│   └── migrate/                 # 71 migration files (2022-2026)
│
├── lib/                          # Custom libraries (currently empty)
│
├── test/                         # Test suite
│   ├── test_helper.rb           # Test configuration
│   ├── application_system_test_case.rb # System test setup (Selenium/Chrome)
│   ├── controllers/             # Controller tests (14 files)
│   ├── models/                  # Model tests (15 files)
│   ├── jobs/                    # Job tests
│   ├── channels/                # Channel tests
│   ├── fixtures/                # Test data (YAML)
│   └── system/                  # System tests (browser-based)
│
├── public/                       # Static files served directly
│   ├── pdfs/                    # Generated PDF storage
│   └── ...                      # Favicon, robots.txt, etc.
│
├── .github/
│   └── workflows/
│       └── rubyonrails.yml      # CI: tests + security scanning
│
├── .kamal/                       # Kamal deployment config
│   ├── README.md                # Deployment guide
│   ├── deploy.yml               # Worker deployment config
│   ├── secrets                  # Secrets file (gitignored)
│   └── hooks/                   # Deployment hooks
│
├── Dockerfile                   # App container (Ruby 3.4 + Node + Chrome)
├── Dockerfile.workers           # Worker container (Ruby 3.4 + Chromium)
├── cloudbuild.yaml              # Google Cloud Build CI/CD
├── Gemfile                      # Ruby dependencies
├── Gemfile.lock                 # Locked Ruby dependencies
├── package.json                 # Node dependencies (Puppeteer only)
├── config.ru                    # Rack entry point
├── Rakefile                     # Rake tasks
├── .ruby-version                # Ruby 3.4.8
├── .env                         # Environment variables (gitignored)
└── .gitignore                   # Git ignore rules
```

---

## Critical Folders Summary

| Folder | Purpose | Complexity |
|--------|---------|------------|
| `app/models/` | Business logic, state machines, data validation | High |
| `app/controllers/` | Request handling, authentication, authorization | Medium |
| `app/views/ht2_actes/` | Act management UI (largest view section) | High |
| `app/javascript/controllers/` | 30 Stimulus controllers for interactivity | High |
| `config/` | Application, database, deployment, routes | Medium |
| `db/migrate/` | 71 migrations tracking schema evolution | Reference |
| `app/admin/` | ActiveAdmin back-office interface | Low |

---

## Entry Points

| Entry Point | File | Purpose |
|-------------|------|---------|
| Web Server | `config.ru` | Rack entry point → `Rails.application` |
| Application | `config/application.rb` | Rails app initialization |
| Routes | `config/routes.rb` | URL routing (all under `/anaco`) |
| Frontend JS | `app/javascript/application.js` | Turbo + Stimulus + Trix |
| Background Jobs | `bin/jobs` | Solid Queue worker process |
| Master Layout | `app/views/layouts/application.html.erb` | HTML template with DSFR |
