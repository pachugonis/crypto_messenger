# Vorthex

A secure, real-time messaging application built with Ruby on Rails 8.1, featuring end-to-end encrypted communications, file sharing, and folder organization.

## Features

- 🔐 Secure user authentication with bcrypt
- 💬 Real-time messaging with Action Cable
- 📁 Folder organization for messages
- 📎 File attachments with Active Storage
- 🎨 Modern UI with Tailwind CSS
- 🔍 Full-text search capabilities
- 👥 Multi-user chat rooms
- 🔔 Real-time notifications
- 👨‍💼 Admin dashboard with statistics

## Technology Stack

- **Ruby**: 3.2.2
- **Rails**: 8.1.2
- **Database**: PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Real-time**: Action Cable (WebSockets)
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Cable Backend**: Solid Cable
- **File Storage**: Active Storage
- **Testing**: RSpec, Factory Bot, Capybara

## Prerequisites

Before you begin, ensure you have the following installed:

- Ruby 3.2.2 (use rbenv or rvm)
- PostgreSQL 13 or higher
- Node.js (for JavaScript dependencies)
- Git

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd crypto_messenger
```

### 2. Install Ruby Dependencies

```bash
bundle install
```

### 3. Install JavaScript Dependencies

```bash
bundle exec rails importmap:install
```

### 4. Setup PostgreSQL

Make sure PostgreSQL is running:

```bash
# On macOS with Homebrew
brew services start postgresql

# On Linux
sudo systemctl start postgresql
```

### 5. Configure Database

The application uses the following database names:
- Development: `crypto_messenger_development`
- Test: `crypto_messenger_test`
- Production: `crypto_messenger_production`

If you need to configure database credentials, edit `config/database.yml` or set environment variables.

### 6. Create and Setup Database

```bash
# Create databases
bin/rails db:create

# Run migrations
bin/rails db:migrate

# (Optional) Seed the database with sample data
bin/rails db:seed
```

### 7. Setup Solid Queue, Cable, and Cache

Run migrations for the background job, cable, and cache systems:

```bash
bin/rails solid_queue:install:migrations
bin/rails solid_cable:install:migrations
bin/rails solid_cache:install:migrations
bin/rails db:migrate
```

## Running the Application

### Development Mode

#### Option 1: Using Foreman (Recommended)

This will start the Rails server and Tailwind CSS watcher:

```bash
bin/dev
```

The application will be available at `http://localhost:3000`

#### Option 2: Manual Start

Start the Rails server:

```bash
bin/rails server
```

In a separate terminal, start the Tailwind CSS watcher:

```bash
bin/rails tailwindcss:watch
```

### Background Jobs

To process background jobs, run:

```bash
bin/jobs
```

## Testing

### Run the Full Test Suite

```bash
bundle exec rspec
```

### Run Specific Tests

```bash
# Run model tests
bundle exec rspec spec/models

# Run a specific test file
bundle exec rspec spec/models/user_spec.rb
```

### Code Quality Checks

```bash
# Run RuboCop for code style
bin/rubocop

# Run Brakeman for security checks
bin/brakeman

# Run Bundler Audit for dependency vulnerabilities
bin/bundler-audit

# Run all checks
bin/ci
```

## Docker Deployment

### Build Docker Image

```bash
docker build -t crypto_messenger .
```

### Run with Docker

```bash
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<your-master-key> \
  -e DATABASE_URL=<your-database-url> \
  --name crypto_messenger \
  crypto_messenger
```

### Deploy with Kamal

```bash
# Setup Kamal
kamal setup

# Deploy
kamal deploy
```

## Environment Variables

### Required for Production

- `RAILS_MASTER_KEY` - Rails credentials master key (from `config/master.key`)
- `CRYPTO_MESSENGER_DATABASE_PASSWORD` - PostgreSQL password for production

### Optional

- `DATABASE_URL` - Full database connection URL (overrides database.yml)
- `RAILS_MAX_THREADS` - Maximum number of threads (default: 5)
- `RAILS_LOG_LEVEL` - Log level (debug, info, warn, error, fatal)

## Project Structure

```
app/
├── channels/          # Action Cable channels for real-time features
├── controllers/       # HTTP request handlers
│   └── admin/        # Admin panel controllers
├── javascript/        # Stimulus controllers and JS
├── models/           # ActiveRecord models
└── views/            # ERB templates

config/
├── environments/     # Environment-specific configuration
├── initializers/     # App initialization code
└── locales/          # i18n translations (en, ru)

db/
├── migrate/          # Database migrations
└── seeds.rb          # Seed data

spec/
├── factories/        # Factory Bot factories
└── models/           # Model tests
```

## Key Features

### User Authentication
- Username-based authentication (no email required)
- Secure password hashing with bcrypt
- Session management
- Account locking capability

### Messaging
- Real-time message delivery via WebSockets
- Message editing and deletion
- Read receipts and typing indicators

### Room Management
- Create private and group chat rooms
- Invite participants
- Room settings and permissions

### File Sharing
- Upload and share files in conversations
- Image preview and processing
- Secure file storage with Active Storage

### Organization
- Create folders to organize conversations
- Move messages between folders
- Archive old conversations

### Admin Panel
- User management
- Room oversight
- System statistics and analytics

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
psql --version
pg_isready

# Create database user if needed
createuser -s postgres
```

### Asset Compilation Issues

```bash
# Precompile assets manually
bin/rails assets:precompile

# Clear asset cache
bin/rails assets:clobber
```

### WebSocket Connection Issues

Ensure Action Cable is properly configured in `config/cable.yml` and your reverse proxy (if any) supports WebSocket connections.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is available for use under the terms specified in the LICENSE file.

## Support

For issues and questions, please open an issue in the repository.
