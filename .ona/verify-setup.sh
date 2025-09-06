#!/usr/bin/env bash

echo "🔍 Verifying Ona environment setup..."

# Check if we're in an Ona environment
if [ -n "$ONA_ENVIRONMENT_NAME" ]; then
    echo "✅ Running in Ona environment: $ONA_ENVIRONMENT_NAME"
else
    echo "⚠️  Not running in Ona environment (ONA_ENVIRONMENT_NAME not set)"
fi

# Check if .env file exists
if [ -f .env ]; then
    echo "✅ .env file exists"

    # Check for Ona-specific configurations
    if grep -q "app.ona.dev" .env; then
        echo "✅ Ona domain configuration found"
    else
        echo "⚠️  Ona domain configuration not found in .env"
    fi
else
    echo "❌ .env file not found"
fi

# Check if database is accessible
if command -v psql >/dev/null 2>&1; then
    if psql -h postgres -U postgres -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ PostgreSQL database is accessible"
    else
        echo "❌ PostgreSQL database is not accessible"
    fi
else
    echo "⚠️  psql command not available"
fi

# Check if Redis is accessible
if command -v redis-cli >/dev/null 2>&1; then
    if redis-cli -h redis ping >/dev/null 2>&1; then
        echo "✅ Redis is accessible"
    else
        echo "❌ Redis is not accessible"
    fi
else
    echo "⚠️  redis-cli command not available"
fi

# Check if Ruby dependencies are installed
if [ -d "vendor/bundle" ]; then
    echo "✅ Ruby dependencies are installed"
else
    echo "❌ Ruby dependencies are not installed"
fi

# Check if Node.js dependencies are installed
if [ -d "node_modules" ]; then
    echo "✅ Node.js dependencies are installed"
else
    echo "❌ Node.js dependencies are not installed"
fi

# Check if database is set up
if [ -f "db/schema.rb" ]; then
    echo "✅ Database schema exists"
else
    echo "⚠️  Database schema not found (may need to run migrations)"
fi

echo ""
echo "🎯 Next steps:"
echo "1. If you see any ❌ errors, run: ona automation run setup-environment"
echo "2. If dependencies are missing, run: ona automation run install-dependencies"
echo "3. To start the development server: ona automation run start-services"
echo "4. Or manually: dip up web"
echo ""
echo "📚 For more help, see ONA_README.md"
