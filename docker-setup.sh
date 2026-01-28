#!/bin/bash

# Vorthex Docker Quick Start Script
# This script helps you quickly deploy Vorthex with Docker

set -e

echo "🚀 Vorthex Docker Quick Start"
echo "=============================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from example..."
    cp .env.example .env
    
    echo ""
    echo "⚠️  IMPORTANT: You need to configure your .env file!"
    echo ""
    echo "Generating secret keys..."
    
    # Generate secret keys using openssl
    SECRET_KEY_BASE=$(openssl rand -hex 64)
    ENCRYPTION_PRIMARY_KEY=$(openssl rand -hex 32)
    ENCRYPTION_DETERMINISTIC_KEY=$(openssl rand -hex 32)
    ENCRYPTION_KEY_DERIVATION_SALT=$(openssl rand -hex 32)
    POSTGRES_PASSWORD=$(openssl rand -hex 16)
    
    # Update .env file
    sed -i.bak "s|your_secret_key_base_here|$SECRET_KEY_BASE|g" .env
    sed -i.bak "s|your_encryption_primary_key_here|$ENCRYPTION_PRIMARY_KEY|g" .env
    sed -i.bak "s|your_encryption_deterministic_key_here|$ENCRYPTION_DETERMINISTIC_KEY|g" .env
    sed -i.bak "s|your_encryption_key_derivation_salt_here|$ENCRYPTION_KEY_DERIVATION_SALT|g" .env
    sed -i.bak "s|your_secure_postgres_password|$POSTGRES_PASSWORD|g" .env
    rm .env.bak 2>/dev/null || true
    
    echo "✅ Secret keys generated and saved to .env"
    echo ""
    echo "📧 Don't forget to configure SMTP settings in .env if you want email functionality!"
    echo ""
else
    echo "✅ .env file already exists"
    echo ""
fi

# Build and start containers
echo "🏗️  Building Docker images (this may take a few minutes)..."
docker-compose build

echo ""
echo "🚀 Starting containers..."
docker-compose up -d

echo ""
echo "⏳ Waiting for database to be ready..."
sleep 10

# Setup database
echo ""
echo "📦 Setting up database..."
docker-compose exec -T app bin/rails db:create db:migrate

echo ""
echo "✅ Vorthex is now running!"
echo ""
echo "🌐 Access your application at: http://localhost"
echo ""
echo "📋 Useful commands:"
echo "  - View logs:           docker-compose logs -f"
echo "  - Stop:                docker-compose stop"
echo "  - Restart:             docker-compose restart"
echo "  - Create admin user:   docker-compose exec app bin/rails console"
echo ""
echo "📖 See DOCKER.md for more information"
echo ""
echo "🎉 Setup complete!"
