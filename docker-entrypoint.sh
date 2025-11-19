#!/bin/bash
set -e

# Determine if we need to wait for services based on the command
COMMAND="$1"

# Wait for database if command might need it
if [[ "$COMMAND" == "php-fpm" ]] || [[ "$COMMAND" == "php" ]] && [[ "$2" == "artisan" ]]; then
    DB_HOST="${DB_HOST:-postgres}"
    DB_PORT="${DB_PORT:-5432}"
    if [[ "$DB_CONNECTION" == "pgsql" ]] || [[ "$DB_HOST" == "postgres" ]]; then
        echo "Waiting for PostgreSQL..."
        while ! nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; do
            sleep 1
        done
        echo "PostgreSQL is ready!"
    elif [[ "$DB_CONNECTION" == "mysql" ]] || [[ "$DB_HOST" == "mysql" ]]; then
        echo "Waiting for MySQL..."
        while ! nc -z "$DB_HOST" 3306 2>/dev/null; do
            sleep 1
        done
        echo "MySQL is ready!"
    fi
fi

# Wait for Redis if command might need it
if [[ "$COMMAND" == "php-fpm" ]] || [[ "$COMMAND" == "php" ]] || [[ "$COMMAND" == *"horizon"* ]] || [[ "$COMMAND" == *"reverb"* ]]; then
    echo "Waiting for Redis..."
    while ! nc -z redis 6379 2>/dev/null; do
        sleep 1
    done
    echo "Redis is ready!"
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Only run initialization for main app service (php-fpm)
if [[ "$COMMAND" == "php-fpm" ]]; then
    # Install dependencies if vendor doesn't exist
    if [ ! -d "vendor" ]; then
        echo "Installing PHP dependencies..."
        composer install --no-interaction --prefer-dist
    fi

    # Install Node dependencies if node_modules doesn't exist
    if [ ! -d "node_modules" ]; then
        echo "Installing Node dependencies..."
        npm install
    fi

    # Build frontend assets if not in development mode or if build doesn't exist
    if [ "$APP_ENV" != "local" ] || [ ! -f "public/build/manifest.json" ]; then
        echo "Building frontend assets..."
        npm run build || true
    fi

    # Generate application key if not set
    if [ -z "$APP_KEY" ] || [ "$APP_KEY" == "" ]; then
        echo "Generating application key..."
        php artisan key:generate --force || true
    fi

    # Run migrations (only if not already run)
    if php artisan migrate:status > /dev/null 2>&1; then
        echo "Database migrations already run."
    else
        echo "Running migrations..."
        php artisan migrate --force || true
    fi

    # Clear and cache config
    php artisan config:clear || true
    php artisan cache:clear || true
    php artisan route:clear || true
    php artisan view:clear || true

    # Cache config for production
    if [ "$APP_ENV" = "production" ]; then
        php artisan config:cache || true
        php artisan route:cache || true
        php artisan view:cache || true
    fi
fi

# Execute the main command
exec "$@"

