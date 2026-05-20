#!/bin/sh
set -e

APP_ENV="${APP_ENV:-prod}"

# Dev bind-mounts need full dependencies; production image ships --no-dev vendor only
if [ "$APP_ENV" != "prod" ]; then
    echo "Installing Composer dependencies (dev)..."
    composer install --no-interaction
elif [ ! -f vendor/autoload.php ]; then
    echo "Installing Composer dependencies (prod)..."
    composer install --no-dev --optimize-autoloader --no-interaction --no-scripts
fi

if [ "$APP_ENV" = "prod" ]; then
    echo "Warming up production cache..."
    php bin/console cache:clear --env=prod --no-debug
    php bin/console cache:warmup --env=prod --no-debug
else
    echo "Preparing development cache..."
    php bin/console cache:clear --env=dev
fi

echo "Executing database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

echo "Starting PHP-FPM..."
php-fpm -D

echo "Starting Nginx web server..."
exec nginx -g "daemon off;"
