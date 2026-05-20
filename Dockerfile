FROM php:8.3-fpm-alpine

# Install production system dependencies
RUN apk add --no-cache \
    nginx \
    icu-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-install intl pdo_mysql zip opcache

# Copy stable Composer binary
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy server configuration paths
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-main.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Grant execution permissions (strip CRLF when built on Windows hosts)
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# Copy your source files and establish system permissions
COPY . /app
RUN mkdir -p var/cache var/log /var/log/nginx \
    && chown -R www-data:www-data /app /var/log/nginx

# Install isolated vendor components without dev tools
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --optimize-autoloader --no-scripts

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
