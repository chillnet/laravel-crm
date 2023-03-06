#!/bin/sh

php artisan cache:clear
php artisan route:cache

/usr/bin/supervisord -c /etc/supervisor/conf.d/laravel-app.conf
