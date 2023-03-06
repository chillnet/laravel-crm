FROM eagweb/glencore-base-app:latest as build

COPY . .

RUN COMPOSER_MEMORY_LIMIT=-1 composer install --optimize-autoloader --no-interaction --no-progress --no-dev;
#RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs

#composer install
COPY --from=composer:2.2.16 /usr/bin/composer /usr/bin/composer

# Remove the hidden docker folder
RUN rm -rf .docker docker

EXPOSE 80

COPY .docker/run.sh /var/www/.docker/run.sh
COPY .docker/config/supervisor/laravel-app-supervisor.conf /etc/supervisor/conf.d/laravel-app.conf
COPY .docker/config/vhosts/vhost.conf /etc/apache2/sites-available/000-default.conf

RUN chmod -R 755 /var/www/.docker/

# Operation not supported: AH00023: Couldn't create the mpm-accept mutex Apple M1 Issue Fix
RUN echo "Mutex posixsem" >> /etc/apache2/apache2.conf

ENTRYPOINT ["/var/www/.docker/run.sh"]
