# Avisbop — Project Documentation Index

## Project Overview

- **Type:** Monolithic web application
- **Primary Language:** Ruby 3.4.8
- **Framework:** Ruby on Rails 8.1.1
- **Architecture:** MVC with Hotwire (Turbo + Stimulus)
- **Database:** PostgreSQL (Google Cloud SQL)
- **Design System:** DSFR (Systeme de Design de l'Etat)

## Quick Reference

- **Entry Point:** `http://[host]/anaco`
- **Tech Stack:** Rails 8.1, Devise, ActiveAdmin, Ransack, Pagy, Solid Queue, Highcharts, jspreadsheet, DSFR
- **Architecture Pattern:** Server-rendered MVC with progressive enhancement
- **Key Entity:** Ht2Acte (financial acts with 8-state machine, 65+ columns)

## Generated Documentation

- [Project Overview](./project-overview.md) — Purpose, key entities, technology summary
- [Architecture](./architecture.md) — System architecture, patterns, data design, deployment
- [Data Models](./data-models.md) — Database schema (28 tables), model relationships, state machines
- [API Contracts](./api-contracts.md) — Routes and endpoints (all under /anaco scope)
- [Component Inventory](./component-inventory.md) — 30 Stimulus controllers, view templates, DSFR components
- [Source Tree Analysis](./source-tree-analysis.md) — Annotated directory structure with entry points
- [Development Guide](./development-guide.md) — Setup, testing, debugging, common tasks
- [Deployment Guide](./deployment-guide.md) — CI/CD, Docker, Cloud Run, Kamal, Cloud SQL

## Existing Documentation

- [README](../README.md) — Default Rails README (template)
- [Kamal Deployment Guide](../.kamal/README.md) — Worker deployment on GCP VM
- [Development Guidelines](../.junie/guidelines.md) — Build, test, and code style guidelines

## Getting Started

1. Install Ruby 3.4.8 and PostgreSQL
2. Run `bundle install && npm install`
3. Create database: `bin/rails db:create db:schema:load db:seed`
4. Start server: `bin/rails server`
5. Access at `http://localhost:3000/anaco`
6. Admin panel: `http://localhost:3000/anaco/admin` (admin@anaco.com / password)

For detailed instructions, see [Development Guide](./development-guide.md).
