#!/usr/bin/env bash
set -e

# Enable debug logging
echo "APP_DEBUG=true" >> /laravel/.env
echo "LOG_LEVEL=debug" >> /laravel/.env

# Generate the proper APP_URL based on Home Assistant Ingress
if [ -n "$INGRESS_URL" ]; then
    echo "Setting up for ingress at $INGRESS_URL"
    # Update the .env file with the ingress URL
    sed -i "s#APP_URL=.*#APP_URL=${INGRESS_URL}#g" /laravel/.env

    # Extract the base path for assets
    INGRESS_PATH=$(echo "$INGRESS_URL" | sed -E 's|^https?://[^/]+(/.*)?$|\1|')
    echo "ASSET_URL=${INGRESS_PATH}" >> /laravel/.env
    echo "INGRESS_PATH=${INGRESS_PATH}" >> /laravel/.env
fi

# Set session and cookie settings to be more compatible with proxies
sed -i "s#SESSION_SECURE_COOKIE=.*#SESSION_SECURE_COOKIE=false#g" /laravel/.env
sed -i "s#SESSION_DRIVER=.*#SESSION_DRIVER=file#g" /laravel/.env
echo "TRUSTED_PROXIES=*" >> /laravel/.env

# Run database migrations if needed
php /laravel/artisan migrate --force

# Clear all caches to ensure new settings are applied
php /laravel/artisan optimize:clear
php /laravel/artisan config:cache
php /laravel/artisan route:cache
php /laravel/artisan view:cache

echo "Starting Laravel application with Home Assistant ingress support..."
echo "Current .env configuration:"
cat /laravel/.env

# Start Laravel server with longer timeout and proper host binding
exec php /laravel/artisan serve --host=0.0.0.0 --port=8000