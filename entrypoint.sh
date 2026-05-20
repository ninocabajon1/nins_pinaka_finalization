#!/bin/bash
set -e

# Run production migrations automatically
echo "Running database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

echo "Starting PHP-FPM..."
php-fpm -F &
PHP_PID=$!