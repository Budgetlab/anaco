# Development Guide — Avisbop

## Prerequisites

| Requirement | Version | Notes |
|------------|---------|-------|
| Ruby | 3.4.8 | Specified in `.ruby-version` |
| Rails | 8.1.1 | Specified in `Gemfile` |
| PostgreSQL | 11+ | Local or Cloud SQL |
| Node.js | 18+ | For asset compilation and Puppeteer |
| npm | latest | For node_modules |
| Bundler | latest | Ruby dependency manager |

---

## Initial Setup

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd avisbop

# Install Ruby gems
bundle install

# Install Node dependencies (Puppeteer for PDF generation)
npm install
```

### 2. Database Setup

```bash
# Create development and test databases
bin/rails db:create

# Load schema
bin/rails db:schema:load

# Seed admin user (development only)
bin/rails db:seed
```

**Development database:** `avisbop_development_main` (PostgreSQL, default local connection)
**Test database:** `avisbop_test_main`

### 3. Environment Variables

Create a `.env` file at the project root with:

```
PRODUCTION_DB_NAME=<database_name>
PRODUCTION_DB_USERNAME=<db_user>
PRODUCTION_DB_PASSWORD=<db_password>
CLOUD_SQL_CONNECTION_NAME=<gcp_connection>
GOOGLE_PROJECT_ID=<gcp_project>
STORAGE_BUCKET_NAME=<gcs_bucket>
SERVICE_NAME=<service_id>
KAMAL_REGISTRY_PASSWORD=<docker_hub_token>
SECRET_KEY_BASE=<rails_secret>
RAILS_MASTER_KEY=<master_key>
```

The `config/master.key` file is required for credentials decryption (not committed to git).

### 4. Active Storage Setup

Development uses Google Cloud Storage by default. Ensure GCS credentials are configured in `config/storage.yml` or switch to local storage in `config/environments/development.rb`:

```ruby
config.active_storage.service = :local  # or :google
```

---

## Running the Application

### Development Server

```bash
# Start Rails server (default port 3000)
bin/rails server

# Or with specific port
bin/rails server -p 3000
```

The application is accessible at `http://localhost:3000/anaco` (all routes are scoped under `/anaco`).

### Background Jobs (Solid Queue)

```bash
# Start Solid Queue workers
bin/jobs
```

Required for PDF generation jobs. In development, Puma can also run Solid Queue via the plugin (configured in `config/puma.rb`).

### Rails Console

```bash
bin/rails console
```

---

## Default Credentials

### Development Admin
- **URL:** `http://localhost:3000/anaco/admin`
- **Email:** `admin@anaco.com`
- **Password:** `password`

### Regular Users
Created via admin panel or `bin/rails console`.

---

## Testing

### Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/ht2_acte_test.rb

# Run specific test by line number
bin/rails test test/models/ht2_acte_test.rb:4

# Run controller tests only
bin/rails test test/controllers/

# Run model tests only
bin/rails test test/models/
```

### Test Structure

| Directory | Purpose |
|-----------|---------|
| `test/models/` | Model unit tests (15 files) |
| `test/controllers/` | Controller integration tests (14 files) |
| `test/jobs/` | Background job tests |
| `test/system/` | Browser-based system tests (Selenium + Chrome) |
| `test/fixtures/` | YAML test data |

### System Tests

```bash
# Requires Chrome/Chromium installed
bin/rails test:system
```

Configured with Selenium using Chrome at 1400x1400 resolution.

### Known Issues

- Some fixtures may cause foreign key violations. Prefer creating test data directly in tests.
- Consider adding FactoryBot for complex test data setup.

---

## Security Scanning

```bash
# Dependency vulnerability audit
bundle exec bundle audit --update

# Static code security analysis
bundle exec brakeman -q -w2

# Code style (currently disabled in CI)
bundle exec rubocop
# With auto-correct:
bundle exec rubocop -a
```

---

## Build & Asset Compilation

### Import Maps (No Build Step)

Avisbop uses `importmap-rails` for JavaScript — no webpack/esbuild build step required. Dependencies are pinned in `config/importmap.rb` and loaded via ESM.

### Stylesheet Compilation

```bash
# Precompile assets (for production-like testing)
bin/rails assets:precompile

# Clean compiled assets
bin/rails assets:clobber
```

Assets are served from `/anaco/assets` prefix (configured in `config/initializers/assets.rb`).

---

## Key Development Patterns

### Routing Scope

All routes are under `scope '/anaco'`. When adding new routes, place them inside this scope block in `config/routes.rb`.

### Search & Filtering

Uses Ransack with custom predicates:
- `contains` — Case-insensitive LIKE with `unaccent()` transliteration
- `in_insensitive` — Case-insensitive IN clause

### Pagination

Uses Pagy (10 items/page, 7 pagination slots). Include `Pagy::Backend` in controllers and `Pagy::Frontend` in helpers.

### PDF Generation

Two approaches:
1. **Grover** (server-side) — Renders HTML to PDF via Chromium. Configured in `config/initializers/grover.rb`. Background jobs use `GenerateActePdfJob`.
2. **jsPDF** (client-side) — Uses `html2canvas` + `jsPDF` via the `pdf_export` Stimulus controller.

### Data Import

Multiple models support spreadsheet import via the `roo` gem. Import methods follow the pattern:

```ruby
def self.import(file)
  spreadsheet = Roo::Spreadsheet.open(file.path)
  # Parse rows and create/update records
end
```

### French Locale

Default locale is French (`config.i18n.default_locale = :fr`). Date format is `d/m/Y`. Numbers use thin space as thousands separator and comma as decimal separator.

---

## Debugging

```bash
# Rails console
bin/rails console

# In code: add debugger breakpoint
debugger

# View database queries in development log
tail -f log/development.log
```

The `debug` gem is included in development/test groups.

---

## Common Development Tasks

### Adding a New Model

```bash
bin/rails generate model ModelName field:type
bin/rails db:migrate
```

Remember to add `ransackable_attributes` and `ransackable_associations` class methods for Ransack search support.

### Adding a New Controller

```bash
bin/rails generate controller ControllerName action1 action2
```

Add routes under the `/anaco` scope in `config/routes.rb`.

### Adding a New Stimulus Controller

Create `app/javascript/controllers/my_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["output"]
  connect() { /* ... */ }
}
```

Controllers are auto-registered via `app/javascript/controllers/index.js`.

### Adding an Admin Resource

Create `app/admin/my_resource.rb`:

```ruby
ActiveAdmin.register MyModel do
  permit_params :field1, :field2
end
```
