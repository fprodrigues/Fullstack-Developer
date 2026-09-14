<div align="center">
  <img src="app/assets/images/jerimum.jpeg" alt="Jerimun logo" width="180">

# Jerimun User Management

**A secure, real-time user management application built with Ruby on Rails 8.1.**

User registration, profile management, role-based administration and asynchronous spreadsheet imports — without Node.js, Redis or external services.

</div>

---

## Table of contents

- [Overview](#overview)
- [Features](#features)
- [Technology stack](#technology-stack)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Database](#database)
- [File uploads](#file-uploads)
- [Background jobs and real-time updates](#background-jobs-and-real-time-updates)
- [Tests and quality](#tests-and-quality)
- [Security](#security)
- [Docker](#docker)
- [Production notes](#production-notes)
- [Technical decisions and trade-offs](#technical-decisions-and-trade-offs)
- [Future improvements](#future-improvements)
- [AI usage disclosure](#ai-usage-disclosure)

## Overview

Jerimun is a compact full-stack user management application with two roles: **user** and **admin**.

| Role    | Capabilities                                                                |
| ------- | --------------------------------------------------------------------------- |
| Visitor | Register a regular user account and sign in                                 |
| User    | View, edit and delete their own account; upload an avatar                   |
| Admin   | Access a live dashboard, manage users, change roles and import spreadsheets |

Registration always creates a regular user. The `role` attribute is excluded from public registration and explicitly forced to `user` in the controller.

After authentication:

- Regular users are redirected to `/profile`.
- Administrators are redirected to `/admin`.

Imports accept `.csv` and `.xlsx` files. Files are stored with Active Storage and processed asynchronously by Solid Queue. Invalid rows are counted without aborting the entire import, while progress is streamed to the browser through Turbo Streams and Solid Cable — no polling required.

## Features

- Built-in Rails authentication, without Devise
- Secure public registration
- Self-service user profile and avatar upload
- Structural role-based authorization
- Administrative user CRUD
- Live dashboard counters
- CSV and XLSX imports
- Asynchronous import processing
- Real-time progress updates
- Server-side validations
- Automated tests and branch coverage
- Static security analysis
- Multi-stage Docker image

## Technology stack

| Layer              | Technology                                       |
| ------------------ | ------------------------------------------------ |
| Language           | Ruby 4.0.1                                       |
| Framework          | Rails 8.1                                        |
| Database           | SQLite in WAL mode                               |
| Authentication     | Rails built-in authentication generator          |
| Front end          | Hotwire: Turbo Drive, Turbo Streams and Stimulus |
| Styling            | Tailwind CSS v4 via `tailwindcss-rails`          |
| Assets             | Propshaft                                        |
| Background jobs    | Solid Queue                                      |
| WebSockets         | Solid Cable                                      |
| File storage       | Active Storage with local disk service           |
| Application server | Puma behind Thruster                             |
| Tests              | Minitest, Capybara system tests and SimpleCov    |
| Code quality       | RuboCop with Rails Omakase                       |
| Security analysis  | Brakeman                                         |
| Deployment         | Multi-stage Docker build                         |

> [!NOTE]
> The application has no Redis dependency, Node.js build step or required external service.

## Architecture

```text
app/
├── controllers/
│   ├── admin/
│   │   ├── base_controller.rb          # Shared admin authorization guard
│   │   ├── dashboard_controller.rb
│   │   ├── user_imports_controller.rb
│   │   └── users_controller.rb
│   ├── concerns/
│   │   └── authentication.rb           # Generated authentication concern
│   ├── application_controller.rb       # Authentication and current_user
│   ├── home_controller.rb              # Public landing page
│   ├── passwords_controller.rb         # Generated password recovery
│   ├── profiles_controller.rb          # Always operates on Current.user
│   ├── registrations_controller.rb     # Public sign-up; role is not permitted
│   └── sessions_controller.rb           # Generated session management
├── javascript/
│   └── controllers/
│       └── avatar_preview_controller.js
├── jobs/
│   └── user_import_job.rb
├── models/
│   ├── current.rb
│   ├── session.rb
│   ├── user.rb                          # Roles and dashboard broadcasts
│   └── user_import.rb                   # Import lifecycle and progress broadcasts
└── services/
    └── user_imports/
        ├── csv_reader.rb                # CSV blob to Array<Hash>
        ├── processor.rb                 # Import orchestration and counters
        └── xlsx_reader.rb               # XLSX blob to Array<Hash> via Roo
```

### Architectural principles

#### Structural authorization

Every admin controller inherits from `Admin::BaseController`, which runs `require_admin!`. This makes the authorization boundary explicit and prevents an admin action from being added without the shared guard.

#### Context-specific strong parameters

Parameters are defined according to the operation rather than shared globally:

- Public registration excludes `role`.
- Profile updates exclude `role`.
- Admin user management permits `role`.

This prevents privilege escalation through crafted requests by construction.

#### Model-driven real-time updates

The `User` model broadcasts dashboard statistics after create, destroy or role changes. `UserImport` broadcasts import progress after updates. Views subscribe with `turbo_stream_from`, so no custom Action Cable channel or hand-written polling code is necessary.

## Getting started

### Requirements

- Ruby 4.0.1 — see `.ruby-version`
- SQLite 3.8 or newer
- Google Chrome — required only for system tests
- Docker — optional, for the production image

### Quick setup

```bash
git clone <repository-url>
cd user_management
bin/setup
```

`bin/setup` installs dependencies, prepares the databases and loads the seed data.

To execute each step manually:

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
```

### Seed accounts

| Email               | Password      | Role  |
| ------------------- | ------------- | ----- |
| `admin@example.com` | `password123` | Admin |
| `user@example.com`  | `password123` | User  |

> [!WARNING]
> These credentials are intended for local development only. Replace them before deploying a public environment.

### Run locally

```bash
bin/dev
```

This starts the processes declared in `Procfile.dev`:

```text
web:  bin/rails server
css:  bin/rails tailwindcss:watch
jobs: bin/jobs
```

Open [http://localhost:3000](http://localhost:3000).

## Database

The application uses four SQLite databases under `storage/`:

| Database  | Purpose          |
| --------- | ---------------- |
| `primary` | Application data |
| `cache`   | Solid Cache      |
| `queue`   | Solid Queue      |
| `cable`   | Solid Cable      |

All databases run in **WAL mode**, configured under `pragmas:` in `config/database.yml`:

- `journal_mode: wal`
- `synchronous: normal`
- `foreign_keys: true`
- Bounded `journal_size_limit`

WAL mode lets readers and a single writer operate concurrently, making a web process and a background worker practical on the same SQLite storage.

`bin/rails db:prepare` creates all four databases and loads the schemas supplied by the Solid adapters:

- `db/cache_schema.rb`
- `db/cable_schema.rb`
- `db/queue_schema.rb`

Verify the journal mode:

```bash
bin/rails runner \
  'puts ActiveRecord::Base.connection.execute("PRAGMA journal_mode").inspect'
```

## File uploads

Active Storage manages two attachments:

| Attachment          | Validation                                   |
| ------------------- | -------------------------------------------- |
| `User#avatar_image` | PNG, JPEG, WEBP or GIF; maximum size of 5 MB |
| `UserImport#file`   | `.csv` or `.xlsx` extension                  |

The local disk service is used in every environment, and uploaded files are stored under `storage/`.

Remote avatar URLs are intentionally unsupported. Fetching arbitrary user-provided URLs on the server would introduce an SSRF risk, while direct file upload already satisfies the feature requirement.

## Background jobs and real-time updates

### Solid Queue

Solid Queue is configured as the Active Job adapter in development, test and production:

```ruby
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

Worker settings live in `config/queue.yml`.

Run a dedicated worker:

```bash
bin/jobs
```

Alternatively, embed Solid Queue in Puma:

```bash
SOLID_QUEUE_IN_PUMA=1 bin/rails server
```

> [!IMPORTANT]
> Without a running worker, imports remain in the `pending` state.

### Solid Cable

Development uses Solid Cable rather than the default `async` adapter because import jobs run in a separate process. The `async` adapter only delivers messages within the publishing process.

```yaml
development:
  adapter: solid_cable
  connects_to:
    database:
      writing: cable
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

## Tests and quality

### Test suite

```bash
bin/rails test          # Models, controllers, jobs and services
bin/rails test:system   # Capybara with headless Chrome
bin/rails test:all      # Entire suite with a single coverage result
```

Tests run in parallel with:

```ruby
parallelize(workers: :number_of_processors)
```

### Coverage

SimpleCov runs with branch coverage enabled and a minimum coverage threshold of 90%.

```bash
bin/rails test:all
open coverage/index.html
```

Each parallel worker receives a distinct `command_name` and calls `SimpleCov.result` during `parallelize_teardown`. This allows results to merge instead of overwriting one another.

### Linting

```bash
bundle exec rubocop      # Check style
bundle exec rubocop -a   # Apply safe corrections
```

The project uses `rubocop-rails-omakase`, the Rails 8 default style configuration.

### Security scanning

```bash
bundle exec brakeman --no-pager
```

Expected result: **zero warnings**.

## Security

The application implements and tests the following protections:

- Public registration cannot create administrators: `role` is neither permitted nor trusted from the request.
- Every `/admin` route is protected by `Admin::BaseController`.
- Regular users cannot access or edit another user's account.
- Regular users cannot change their own role.
- Email addresses are normalized to lowercase and protected by both a unique index and case-insensitive uniqueness validation.
- ERB output is escaped by default; the only `html_safe` call is applied to a static HTML entity.
- Rails' default CSRF protection remains enabled.
- Session cookies are signed, `httponly` and `same_site: :lax`.
- Sign-in and registration are limited to 10 attempts every 3 minutes.
- Remote avatar URLs are rejected to avoid SSRF.
- All validations are enforced server-side; client-side validation is only a convenience.

## Docker

Build the image:

```bash
docker build -t user_management .
```

Run the container:

```bash
docker run --rm \
  -p 80:80 \
  -e RAILS_MASTER_KEY="$(cat config/master.key)" \
  -e SOLID_QUEUE_IN_PUMA=1 \
  -v user_management_storage:/rails/storage \
  --name user_management \
  user_management
```

Then open [http://localhost](http://localhost).

The multi-stage build installs compilers and gems and precompiles assets in the build stage. The final image contains only the runtime dependencies and application. It runs as the non-root `rails` user (`uid 1000`), with Thruster in front of Puma for HTTP caching, compression and X-Sendfile support.

## Production notes

- **Persist `/rails/storage`.** It contains all four SQLite databases and every Active Storage file. Without a persistent volume, data is lost when the container is replaced.
- **Provide `RAILS_MASTER_KEY` at runtime.** The key is never baked into the image, and `config/master.key` is excluded through `.dockerignore`.
- **Separate jobs for real traffic.** `SOLID_QUEUE_IN_PUMA=1` is suitable for an assessment or compact deployment. At higher load, run `bin/jobs` in a separate container so slow imports cannot consume web request threads.
- **Understand SQLite's boundary.** WAL performs well on a single node with fast local storage, but SQLite does not scale horizontally. Migrating to PostgreSQL requires a `database.yml` change and data migration; the application code does not depend on SQLite-specific behavior.
- **Back up the storage volume.** Copy the volume or use SQLite's `.backup` command for a consistent snapshot while WAL is active.

## Technical decisions and trade-offs

### Hotwire instead of a SPA

A React or Inertia front end would add a build pipeline, client-side router, API layer and duplicated validation for a small interface. Turbo Streams satisfies the real-time requirement with substantially less code. The accepted trade-off is reduced client-side interactivity.

### SQLite in WAL mode instead of PostgreSQL

The project remains runnable with `git clone` and `bin/setup`, without an extra infrastructure tier. The trade-off is a single writer and no horizontal database scaling.

### Direct avatar uploads only

Server-side downloading of user-provided URLs would require URL allowlists, DNS-rebinding protection and strict timeout controls to mitigate SSRF. Direct upload provides the required functionality without that attack surface.

### Simple and readable imports

`UserImports::Processor` reads rows, persists them individually and counts successes and failures. This approach is appropriate for hundreds or a few thousand records and is easy to reason about.

For imports around 500,000 rows, a production implementation should use streaming reads, batched `insert_all`, one transaction per batch and Rails 8.1 Active Job continuations so interrupted jobs can resume.

### Throttled progress broadcasts

Import progress is broadcast every 25 rows. Broadcasting each row would generate more Action Cable traffic than a user could perceive, while batches of 25 still provide a responsive progress indicator.

### Suppressed dashboard broadcasts during imports

Without suppression, each imported user would trigger a dashboard update. `User.suppressing_dashboard_broadcasts` wraps the import loop, followed by one consolidated broadcast when processing finishes.

### Shared admin controller instead of Pundit

With two roles and one authorization rule, `Admin::BaseController` is smaller and easier to audit than a policy class for each resource. Per-record permissions or additional roles would justify a dedicated policy layer.

### Docker without Kamal

The project uses `rails new --skip-kamal`. Docker fulfills the deployment requirement while keeping the implementation focused on application behavior and automated tests.

## Future improvements

- Add streaming reads, batched inserts and Active Job continuations for large imports.
- Generate a downloadable CSV describing rejected rows and their validation errors.
- Add pagination and search to `/admin/users`.
- Generate optimized avatar thumbnails with `image_processing`.
- Replace manually assigned passwords with an administrator invitation flow.
- Add a Kamal deployment configuration with a dedicated jobs container.
- Record role changes in an audit log.

## AI usage disclosure

This project was developed with assistance from **OpenAI GPT-5.6 Sol**.

AI assistance was used for:

- Discussing architectural alternatives, including Hotwire versus a SPA.
- Evaluating a shared admin controller guard versus a policy-object layer.
- Designing the spreadsheet import pipeline and real-time progress flow.
- Reviewing code structure and identifying potential edge cases.
- Suggesting authorization, import and security test scenarios.
- Refining technical documentation and presentation.

All generated suggestions were reviewed and adapted before inclusion. Final implementation decisions, code integration and validation remained under human responsibility.
