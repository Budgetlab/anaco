# Project Overview — Avisbop

## Purpose

Avisbop (internally "Anaco") is a web application for the French government's financial control services. It manages the lifecycle of budget opinions (avis), financial acts (actes HT2), budget planning schemas, and organizational structure (programs, missions, ministries, financial centers, organisms).

The application enables financial controllers (CBR — Controleur Budgetaire Regional, DCB — Directeur de Cabinet) to:
- Issue and track budget opinions on operating programs (BOPs)
- Create, instruct, validate, suspend, and close financial acts
- Plan and manage end-of-year budget schemas with detailed AE/CP tracking
- Import and export financial data via spreadsheets
- Generate PDF documents for acts and schemas
- Visualize financial data through interactive charts and dashboards

---

## Quick Reference

| Property | Value |
|----------|-------|
| **Type** | Monolithic web application |
| **Framework** | Ruby on Rails 8.1.1 |
| **Language** | Ruby 3.4.8 |
| **Database** | PostgreSQL (Google Cloud SQL) |
| **Frontend** | Hotwire (Turbo + Stimulus) with DSFR design system |
| **Architecture** | MVC with server-rendered HTML |
| **Hosting** | Google Cloud Run (app) + GCP VM (workers) |
| **Entry Point** | `http://[host]/anaco` |

---

## Key Business Entities

| Entity | Description |
|--------|-------------|
| **Ht2Acte** | Core entity — financial acts with state machine (8 states), 65+ fields |
| **Avi** | Budget opinions on BOPs across management phases |
| **Programme** | Budget programs belonging to ministries and missions |
| **Bop** | Budget Operating Programs with associated opinions |
| **Schema / GestionSchema** | End-of-management budget planning with 55+ financial fields |
| **CentreFinancier** | Financial centers managing budget execution |
| **Organisme** | External organizations subject to financial control |
| **Suspension** | Act suspension/interruption tracking |

---

## Technology Stack Summary

| Category | Technologies |
|----------|-------------|
| **Backend** | Rails 8.1, Devise, ActiveAdmin, Ransack, Pagy, Solid Queue |
| **Frontend** | Stimulus (30 controllers), Turbo, Highcharts, jspreadsheet, Flatpickr, DSFR |
| **Infrastructure** | GCP (Cloud Run, Cloud SQL, GCS), Kamal, Docker |
| **PDF Generation** | Grover/Puppeteer (Chromium) |
| **CI/CD** | GitHub Actions (tests) + Cloud Build (deployment) |
| **Data Import/Export** | Roo (import), caxlsx (XLSX export), jsPDF (PDF export) |

---

## Repository Structure

- **`app/`** — Models (17), Controllers (16), Views, Helpers, Jobs, Stimulus controllers (30)
- **`config/`** — Routes, database, deployment, initializers, locales
- **`db/`** — Schema (28 tables), 71 migrations, seeds
- **`test/`** — Model tests (15), Controller tests (14), Job tests
- **`.github/workflows/`** — CI pipeline
- **`docs/`** — Generated project documentation

---

## Documentation Index

- [Architecture](./architecture.md) — System architecture, patterns, and decisions
- [Data Models](./data-models.md) — Database schema and model relationships
- [API Contracts](./api-contracts.md) — Routes and endpoint documentation
- [Component Inventory](./component-inventory.md) — UI components and Stimulus controllers
- [Source Tree Analysis](./source-tree-analysis.md) — Annotated directory structure
- [Development Guide](./development-guide.md) — Setup, testing, and development workflow
- [Deployment Guide](./deployment-guide.md) — CI/CD, Docker, Cloud Run, Kamal

---

## Getting Started

1. Clone the repository
2. Install Ruby 3.4.8 and PostgreSQL
3. Run `bundle install && npm install`
4. Create database: `bin/rails db:create db:schema:load db:seed`
5. Start server: `bin/rails server`
6. Access at `http://localhost:3000/anaco`
7. Admin: `http://localhost:3000/anaco/admin` (admin@anaco.com / password)

See [Development Guide](./development-guide.md) for detailed instructions.
