FROM eagweb/glencore-base-app:latest as build

COPY . .

RUN COMPOSER_MEMORY_LIMIT=-1 composer install --optimize-autoloader --no-interaction --no-progress --no-dev;
#RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs
