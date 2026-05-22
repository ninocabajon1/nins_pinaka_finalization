#!/bin/bash
set -e

echo "=== Starting Symfony Application ==="

# Substitute Railway's dynamic PORT into Nginx config (default to 80 for local dev)
echo "Configuring Nginx for PORT: ${PORT:-80}"
sed -i "s/__PORT__/${PORT:-80}/g" /etc/nginx/conf.d/symfony.conf

# Run production migrations automatically
echo "Running database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration || {
    echo "Warning: Migration failed, but continuing..."
}

# Clear and warm up cache
echo "Warming up production cache..."
php bin/console cache:clear --env=prod --no-debug || true
php bin/console cache:warmup --env=prod --no-debug || true

# Set proper permissions
echo "Setting permissions..."
chown -R www-data:www-data /app/var
chmod -R 775 /app/var

echo "Starting PHP-FPM..."
php-fpm -F &
PHP_PID=$!

echo "Starting Nginx..."
nginx -g "daemon off;" &
NGINX_PID=$!

echo "=== Application Started Successfully ==="
echo "PHP-FPM PID: $PHP_PID"
echo "Nginx PID: $NGINX_PID"

# Wait for both processes - if either exits, restart it
while true; do
    if ! kill -0 $PHP_PID 2>/dev/null; then
        echo "PHP-FPM died, restarting..."
        php-fpm -F &
        PHP_PID=$!
    fi
    if ! kill -0 $NGINX_PID 2>/dev/null; then
        echo "Nginx died, restarting..."
        nginx -g "daemon off;" &
        NGINX_PID=$!
    fi
    sleep 5
done
