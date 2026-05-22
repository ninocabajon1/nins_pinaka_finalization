#!/bin/bash
set -e

# Run production migrations automatically
echo "Running database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

# Substitute Railway's dynamic PORT into Nginx config (default to 80 for local dev)
sed -i "s/__PORT__/${PORT:-80}/g" /etc/nginx/conf.d/symfony.conf

echo "Starting PHP-FPM..."
php-fpm -F &
PHP_PID=$!

echo "Starting Nginx..."
# Start Nginx in the foreground so the container stays active
nginx -g "daemon off;" &
NGINX_PID=$!

# Wait on both processes so if either crashes, the container handles it
wait -n $PHP_PID $NGINX_PID