INTERACTIVE := $(shell [ -t 0 ] && echo 1)
ERROR_ONLY_FOR_HOST = @printf "\033[33mThis command for host machine\033[39m\n"
.DEFAULT_GOAL := help
ifneq ($(INTERACTIVE), 1)
	OPTION_T := -T
endif

# Determine if .env file exist
ifneq ("$(wildcard .env)","")
	include .env
endif

help: ## Shows available commands with description
	@echo "\033[34mList of available commands:\033[39m"
	@grep -E '^[a-zA-Z-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "[32m%-27s[0m %s\n", $$1, $$2}'
info: ## Shows Php and Laravel version
	sail php artisan --version
	sail php artisan env
	sail php --version
start: ## Start docker compose environment
	docker compose up -d
ps: ## Show docker compose processes
	docker compose ps
stop: ## Stop docker compose environment
	docker compose down
restart: ## Stop and start docker compose environment
	docker compose restart
cda: ## Composer dump autoload
	composer dump-autoload
tail: ## Tail the application logs
	tail -f storage/logs/laravel-`date +%Y`-`date +%m`-`date +%d`.log storage/logs/smsapp-*.log | grep -v ReflectionException
copydb: ## Copy the latest backup from the remote server
	./copy_latest_backup.sh
build: ptags ## Build a production docker image for the application and push to dockerhub
	./build-dockerhub.sh
clear: ## Clear the application cache, configs, permissions, views and routes
	sail php artisan cache:clear
	sail php artisan config:cache
	sail php artisan permission:cache-reset
	sail php artisan config:clear
	sail php artisan view:clear
	sail php artisan route:clear
migrate: ## Run database migrations
	sail php artisan migrate --step
rollback: ## Rollback database migrations
	sail php artisan migrate:rollback
prod: ## Recompile production assets
	npm run prod
	git add public
	git commit -m \"Recompiling Production Assets\"
release: ## Get release notes
	./get_release_notes.sh
tinker: ## Tinker
	sail php artisan tinker
ctink: ## CT API Tinker
	docker compose exec ctapi php artisan tinker
cbash: ## CT API Bash
	docker compose exec ctapi bash
tink: tinker
install_composer: ## Install composer
	sail php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\"
	sail php -r \"if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;\"
	sail php composer-setup.php
	sail php -r "unlink('composer-setup.php');"
shell: ## Shell into the webapp container
	sail bash
bash: shell
sh: shell
importdb: ## Import latest production database
	$(eval LATEST_BACKUP_FILE := $(shell ls -rth ~/Downloads/glencore_au-* | tail -n 1))
	mysql --login-path=dev -e "DROP database glencore_au; CREATE DATABASE glencore_au COLLATE utf8mb4_general_ci;"
	gunzip -c ${LATEST_BACKUP_FILE} | mysql --login-path=dev glencore_au
idb: importdb
ptags: ## Push tags to production
	git push --tags
pintify: ## Pintify
	./pintify.sh
fixperms: ## Fix permission issues inside the webapp container
	sail chown www-data: storage -R
recent: ## Show recent git branches ordered latest to oldest
	echo "Showing recent git branches ordered latest to oldest"
	git branch --sort=-committerdate
mysql: ## Mysql cli interface to the database
	# mysql_config_editor set --login-path=webapp --host=127.0.0.1 --port=3306 --user=sourcing --password
	mysql --login-path=webapp
live: ## Artisan up inside the webapp container
	sail php artisan up
maintenance: ## Artisan down inside the webapp container
	sail php artisan down
maint: maintenance ## Alias to maintenance
refresh: ## Refresh all the containers and pull the latest changes
	$(eval HOSTNAME := $(shell hostname -f))
	$(eval PREFIX := **${HOSTNAME}**)
	$(eval APP_VERSION := $(shell grep APP_VERSION .env | grep -v '#' | cut -d '=' -f 2 | head -n 1))
	$(eval BIDDER_PORTALAPP_VERSION := $(shell grep APP_VERSION .env | grep -v '#' | cut -d '=' -f 2 | tail -n 1))

	sail /var/www/html/teams.sh "${PREFIX} Updating docker image..."
	$(MAKE) up
	sail /var/www/html/teams.sh "${PREFIX} Done! docker image updated. Artisan will activate maintenance mode now."
	sail php artisan storage:link
	$(MAKE) maintenance
	sail php artisan migrate --step
	sail php artisan optimize:clear
	sail php artisan permission:cache-reset
	sail php artisan clear-compiled
	sail php artisan event:cache
	sail php artisan route:cache
	sail php artisan view:cache
	echo "making sure we dont have permission issues inside the container..."
	$(MAKE) fixperms
	$(MAKE) migrate
	$(MAKE) live
	sail /var/www/html/teams.sh "${PREFIX} Maintenance and migrations are complete"
	sail /var/www/html/teams.sh "${PREFIX} version:  **${APP_VERSION}** and bidder-portal version: **${BIDDER_PORTALAPP_VERSION}** successfully deployed"
	# "If you experience any issues, strange server errors, quickly run this: "
	# sail chown www-data: storage -R
	# sail chmod -R 755 storage -R
	# "For Database Seeds, use this prefix"
	# sail php artisan db:seed --class=
	$(MAKE) ps
encrypt: ## Encrypt the source code
	rm -rf encrypted
	find . -type f -name '.DS_Store' -exec rm {} +
	sail php artisan encrypt-source
create-storage: ## Create the storage directory and all sub directories
	mkdir -p storage storage/app storage/app/public storage/framework/cache storage/framework/cache/data storage/framework/testing storage/framework/sessions storage/framework/views storage/logs

