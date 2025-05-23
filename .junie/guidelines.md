# Project Guidelines

This document provides guidelines and information for developers working on this project.

## Build/Configuration Instructions

### Environment Setup

1. **Ruby Version**: 3.4.4 (as specified in `.ruby-version`)
2. **Rails Version**: 7.2.2.1 or higher
3. **Database**: PostgreSQL

### Dependencies

The project uses the following key dependencies:
- **Hotwire** (Turbo and Stimulus) for JavaScript
- **ActiveAdmin** for admin interface
- **Devise** for authentication
- **Ransack** for search functionality
- **Google Cloud Storage** for file storage

### Docker Setup

The project includes a Dockerfile for containerized deployment:

```bash
# Build the Docker image
docker build -t avisbop .

# Run the container
docker run -p 8080:8080 avisbop
```

The Dockerfile:
- Uses Ruby 3.4 as the base image
- Installs Node.js 14.x and Yarn for JavaScript dependencies
- Installs Google Chrome for system tests
- Sets up the Rails environment for production
- Exposes port 8080

### Cloud Deployment

The project is configured for deployment to Google Cloud Run with:
- `cloudbuild.yaml` for CI/CD pipeline configuration
- `cloud-sql-proxy` for database connectivity
- Environment variables stored in `.env` file (not committed to version control)

## Testing Information

### Test Structure

The project follows the standard Rails testing structure:
- `test/models/`: Model tests
- `test/controllers/`: Controller tests
- `test/system/`: System tests (browser-based integration tests)
- `test/fixtures/`: Test data

### Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/ht2_acte_test.rb

# Run specific test
bin/rails test test/models/ht2_acte_test.rb:4
```

### System Tests

System tests use Selenium with Chrome:

```ruby
# test/application_system_test_case.rb
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
end
```

### Adding New Tests

#### Model Test Example

```ruby
# test/models/example_test.rb
require "test_helper"

class ExampleTest < ActiveSupport::TestCase
  test "valid example" do
    example = Example.new(name: "Test")
    assert example.valid?
  end
end
```

#### Controller Test Example

```ruby
# test/controllers/example_controller_test.rb
require "test_helper"

class ExampleControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get examples_url
    assert_response :success
  end
end
```

### Known Testing Issues

There are some issues with the test fixtures that may cause foreign key violations. When creating new tests, consider:
1. Creating test data directly in the test rather than relying on fixtures
2. Ensuring that all foreign key relationships are properly set up in fixtures
3. Using factories (consider adding FactoryBot) for more complex test data setup

## Additional Development Information

### Code Style

The project uses Rubocop for code style checking:

```bash
# Run Rubocop
bundle exec rubocop

# Run Rubocop with auto-correct
bundle exec rubocop -a
```

### Security

The project includes security scanning tools:

```bash
# Check for security vulnerabilities in dependencies
bundle exec bundler-audit check --update

# Check for security vulnerabilities in code
bundle exec brakeman
```

### Database Schema

The database uses PostgreSQL with the following extensions:
- `unaccent`: For accent-insensitive text search

Key models include:
- `Ht2Acte`: Main model for handling acts/documents
- `User`: User accounts
- `CentreFinancier`: Financial centers
- `Suspension`: Suspensions of acts
- `Echeancier`: Payment schedules

### JavaScript Framework

The project uses Stimulus.js for JavaScript functionality:

```javascript
// Example Stimulus controller
// app/javascript/controllers/example_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  
  connect() {
    this.outputTarget.textContent = "Hello, Stimulus!"
  }
}
```

### Debugging

For debugging in development:
- Use `debug` gem (included in development group)
- Add `debugger` statement in code to set breakpoints
- Use Rails console: `bin/rails console`

### Performance Monitoring

Consider adding performance monitoring tools like:
- New Relic
- Skylight
- Scout APM

### Deployment Process

The application is deployed to Google Cloud Run:
1. Changes pushed to main branch trigger Cloud Build
2. Cloud Build builds the Docker image and deploys to Cloud Run
3. Database migrations are run as part of the deployment process