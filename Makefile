APP_VERSION=`grep "version" $(PWD)/composer.json | grep -o "[\"][0-9].*[\"]" | sed "s/\"//" | sed "s/\"//"`
DOCKER_APP_EXEC=docker-compose --env-file $(ENV_FILE) exec app
DOCKER_APP_RUN=docker-compose --env-file $(ENV_FILE) run app 
ENV_FILE=$(PWD)/.env.local
SYMFONY_CMD=

chown:
	@sudo chown -R $(USER):$(USER) $(PWD)

up: .gerar-env-local .composer-install
	docker-compose --env-file $(ENV_FILE) up -d --remove-orphans --force-recreate
	@make chown

down:
	docker-compose down --rmi local -v --remove-orphans

log:
	docker-compose logs -f

app-bash: .gerar-env-local
	docker-compose exec app bash
	@make chown

symfony: .gerar-env-local
	docker-compose exec app symfony $(SYMFONY_CMD)
	@make chown

clean:
	@rm -rf $(PWD)/vendor/ $(PWD)/node_modules/ $(PWD)/var/ $(PWD)/.env.local $(PWD)/composer.lock $(PWD)/yarn.lock
	@echo "Arquivos removidos"

.composer-install: .gerar-env-local
	@echo "Instalando/Atualizando pacotes do composer"
	@if [ -d $(PWD)/vendor ]; then $(DOCKER_APP_RUN) composer update; else $(DOCKER_APP_RUN) composer install; fi
	@make chown

.gerar-env-local:
	@cat $(PWD)/.env > $(ENV_FILE)
	@proxy_test=0 env | grep -iE "proxy" >> $(ENV_FILE)
	@echo "APP_VERSION="$(APP_VERSION) >> $(ENV_FILE)
