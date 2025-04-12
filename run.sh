#!/usr/bin/env bash
set -e

# Debugging: Output environment variables
echo "Environment variables:"
echo "INGRESS_URL: $INGRESS_URL"
echo "SUPERVISOR_TOKEN: ${SUPERVISOR_TOKEN:0:5}..." # Only show first few chars for security
echo "HOSTNAME: $HOSTNAME"

# Generate the proper APP_URL based on Home Assistant Ingress
if [ -n "$INGRESS_URL" ]; then
    echo "Setting up for ingress at $INGRESS_URL"
    # Update the .env file with the ingress URL
    sed -i "s#APP_URL=.*#APP_URL=${INGRESS_URL}#g" /laravel/.env

    # Add ingress path to .env for dynamic handling
    echo "INGRESS_PATH=$(echo $INGRESS_URL | sed 's/^.*\/\/[^\/]*//')" >> /laravel/.env

    # Extract protocol from INGRESS_URL to set secure cookies if needed
    if [[ "$INGRESS_URL" == https://* ]]; then
        echo "HTTPS detected, enabling secure cookies"
        sed -i "s#SESSION_SECURE_COOKIE=.*#SESSION_SECURE_COOKIE=true#g" /laravel/.env
    else
        echo "HTTP detected, disabling secure cookies"
        sed -i "s#SESSION_SECURE_COOKIE=.*#SESSION_SECURE_COOKIE=false#g" /laravel/.env
    fi
else
    echo "No INGRESS_URL provided, using default settings"
fi

# Run database migrations if needed
php /laravel/artisan migrate --force

# Clear all caches to ensure new settings are applied
php /laravel/artisan optimize
php /laravel/artisan config:clear
php /laravel/artisan route:clear
php /laravel/artisan view:clear
php /laravel/artisan cache:clear

echo "Waiting for system to stabilize..."
sleep 2  # Add a small delay to ensure everything is ready

# Start Laravel server with longer timeout
exec php /laravel/artisan serve --host=0.0.0.0 --port=8000