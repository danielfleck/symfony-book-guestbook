APP_VERSION=`grep "version" $(PWD)/composer.json | grep -o "[\"][0-9].*[\"]" | sed "s/\"//" | sed "s/\"//"`
DOCKER_APP_EXEC=docker-compose --env-file $(ENV_FILE) exec app
DOCKER_APP_RUN=docker-compose --env-file $(ENV_FILE) run app
DOCKER_YARN_RUN=docker run -v $(HOME)/.gitconfig:/root/.gitconfig --env-file $(ENV_FILE) --rm -v $(PWD):/srv/app -w /srv/app node:lts yarn
ENV_FILE=$(PWD)/.env.local
SYMFONY_CMD=

chown:
	@sudo chown -R $(USER):$(USER) $(PWD)

up: .gerar-env-local .composer-install .yarn-install
	@docker-compose --env-file $(ENV_FILE) up -d --remove-orphans --force-recreate
	@make chown

down:
	@docker-compose down --rmi local -v --remove-orphans

log: up
	@docker-compose logs -f

app-bash: up
	@docker-compose exec app bash
	@make chown

app-bash-cmd: up
	@docker-compose exec app bash $(CMD)
	@make chown

symfony-cmd: up
	@docker-compose exec app symfony $(SYMFONY_CMD)
	@make chown

yarn-cmd:
	@$(DOCKER_YARN_RUN) $(YARN_CMD)
	@make chown

qa: up
	@$(DOCKER_APP_RUN) vendor/bin/php-cs-fixer fix --allow-risky yes
	@$(DOCKER_APP_RUN) vendor/bin/phpstan analyse --level 4 src tests
	@make test

test:
	@$(DOCKER_APP_RUN) vendor/bin/phpunit

clean:
	@rm -rf $(PWD)/vendor/ $(PWD)/node_modules/ $(PWD)/var/ $(PWD)/.env.local $(PWD)/composer.lock $(PWD)/yarn.lock
	@echo "Arquivos removidos"

.gerar-arquivo-com-licencas:
	@$(DOCKER_YARN_RUN) licenses list --prod > LICENSE_JS_PACKAGES
	@$(DOCKER_APP_RUN) composer licenses --no-dev --no-interaction --no-cache --no-ansi > LICENSE_PHP_PACKAGES
	@sed -i "/Xdebug:.*Could not connect/d" LICENSE_PHP_PACKAGES
	@make chown

.yarn-install: .gerar-env-local
	@echo "Instalando/Atualizando pacotes javascript"
	@$(DOCKER_YARN_RUN) licenses list --prod > LICENSE_JS_PACKAGES
	@make chown

.composer-install: .gerar-env-local
	@echo "Instalando/Atualizando pacotes do composer"
	@if [ -d $(PWD)/vendor ]; then $(DOCKER_APP_RUN) composer update; else $(DOCKER_APP_RUN) composer install; fi
	@make chown

.gerar-env-local:
	@cat $(PWD)/.env > $(ENV_FILE)
	@proxy_test=0 env | grep -iE "proxy" >> $(ENV_FILE)
	@echo "APP_VERSION="$(APP_VERSION) >> $(ENV_FILE)
	@make .gerar-arquivo-com-licencas
