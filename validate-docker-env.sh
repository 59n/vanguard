#!/bin/bash

# Docker Environment Validation Script
# This script checks if your .env file is properly configured for Docker

echo "🔍 Validating .env file for Docker compatibility..."
echo ""

ENV_FILE=".env"
REQUIRED_VARS=(
    "APP_NAME"
    "APP_ENV"
    "APP_KEY"
    "APP_URL"
    "DB_CONNECTION"
    "DB_HOST"
    "DB_DATABASE"
    "DB_USERNAME"
    "DB_PASSWORD"
    "REDIS_HOST"
    "QUEUE_CONNECTION"
)

DOCKER_SPECIFIC_VARS=(
    "DB_HOST=mysql"
    "REDIS_HOST=redis"
    "QUEUE_CONNECTION=redis"
)

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found!"
    exit 1
fi

# Source the .env file
set -a
source "$ENV_FILE"
set +a

echo "📋 Checking required variables..."
echo ""

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
        echo "❌ Missing: $var"
    else
        echo "✅ Found: $var=${!var}"
    fi
done

echo ""
echo "🐳 Checking Docker-specific configurations..."
echo ""

ISSUES=0

# Check DB_HOST (supports both postgres and mysql)
if [ "$DB_CONNECTION" == "pgsql" ] || [ "$DB_CONNECTION" == "postgres" ]; then
    if [ "$DB_HOST" != "postgres" ]; then
        echo "⚠️  Warning: DB_HOST is set to '$DB_HOST' but should be 'postgres' for Docker (PostgreSQL)"
        ISSUES=$((ISSUES + 1))
    else
        echo "✅ DB_HOST is correctly set to 'postgres'"
    fi
elif [ "$DB_CONNECTION" == "mysql" ]; then
    if [ "$DB_HOST" != "mysql" ]; then
        echo "⚠️  Warning: DB_HOST is set to '$DB_HOST' but should be 'mysql' for Docker (MySQL)"
        ISSUES=$((ISSUES + 1))
    else
        echo "✅ DB_HOST is correctly set to 'mysql'"
    fi
else
    echo "ℹ️  Info: DB_CONNECTION is '$DB_CONNECTION', DB_HOST is '$DB_HOST'"
fi

# Check REDIS_HOST
if [ "$REDIS_HOST" != "redis" ]; then
    echo "⚠️  Warning: REDIS_HOST is set to '$REDIS_HOST' but should be 'redis' for Docker"
    ISSUES=$((ISSUES + 1))
else
    echo "✅ REDIS_HOST is correctly set to 'redis'"
fi

# Check QUEUE_CONNECTION
if [ "$QUEUE_CONNECTION" != "redis" ]; then
    echo "⚠️  Warning: QUEUE_CONNECTION is set to '$QUEUE_CONNECTION' but should be 'redis' for Docker"
    ISSUES=$((ISSUES + 1))
else
    echo "✅ QUEUE_CONNECTION is correctly set to 'redis'"
fi

# Check DB_CONNECTION (supports both pgsql and mysql)
if [ "$DB_CONNECTION" == "pgsql" ] || [ "$DB_CONNECTION" == "postgres" ]; then
    echo "✅ DB_CONNECTION is correctly set to '$DB_CONNECTION' (PostgreSQL)"
elif [ "$DB_CONNECTION" == "mysql" ]; then
    echo "✅ DB_CONNECTION is correctly set to 'mysql'"
else
    echo "⚠️  Warning: DB_CONNECTION is set to '$DB_CONNECTION' (expected 'pgsql' or 'mysql')"
    ISSUES=$((ISSUES + 1))
fi

# Check APP_KEY
if [ -z "$APP_KEY" ] || [ "$APP_KEY" == "" ]; then
    echo "⚠️  Warning: APP_KEY is not set. It will be generated automatically on first run."
else
    echo "✅ APP_KEY is set"
fi

# Check REVERB settings
if [ -z "$REVERB_SERVER_HOST" ]; then
    echo "ℹ️  Info: REVERB_SERVER_HOST not set (will use default: 0.0.0.0)"
fi

if [ -z "$REVERB_HOST" ]; then
    echo "ℹ️  Info: REVERB_HOST not set (should be 'localhost' for local development)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "❌ Found ${#MISSING_VARS[@]} missing required variable(s)"
    echo ""
    exit 1
fi

if [ $ISSUES -gt 0 ]; then
    echo "⚠️  Found $ISSUES potential issue(s) that may prevent Docker from working correctly"
    echo ""
    echo "💡 Quick fix suggestions:"
    if [ "$DB_CONNECTION" == "pgsql" ] || [ "$DB_CONNECTION" == "postgres" ]; then
        echo "   DB_HOST=postgres"
        echo "   DB_CONNECTION=pgsql"
    else
        echo "   DB_HOST=mysql"
        echo "   DB_CONNECTION=mysql"
    fi
    echo "   REDIS_HOST=redis"
    echo "   QUEUE_CONNECTION=redis"
    echo ""
    exit 1
fi

echo "✅ Your .env file looks good for Docker!"
echo ""
echo "🚀 You can now run: docker-compose up -d --build"
echo ""

