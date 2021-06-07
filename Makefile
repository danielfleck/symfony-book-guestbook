APP_VERSION=`cat $(PWD)/APP_VERSION`
BRANCH_ATUAL=`git status | head -n 1 | awk '/.*/ { print $$3 }'`
ENV_FILE=$(PWD)/.env.local
DOCKER_APP_STAT=`docker-compose ps|grep "app.*Up"|wc -l`
LICENSE_PHP_PACKAGES_NAME=LICENSE_PHP_PACKAGES
LICENSE_PHP_PACKAGES_FILE=$(PWD)/$(LICENSE_PHP_PACKAGES_NAME)
LICENSE_JS_PACKAGES_NAME=LICENSE_JS_PACKAGES
LICENSE_JS_PACKAGES_FILE=$(PWD)/$(LICENSE_JS_PACKAGES_NAME)
DOCKER_COMPOSE=docker-compose --env-file $(ENV_FILE)
DOCKER_APP_EXEC=$(DOCKER_COMPOSE) exec app
DOCKER_APP_RUN=$(DOCKER_COMPOSE) run app
DOCKER_YARN_RUN=docker run -v $(HOME)/.gitconfig:/root/.gitconfig --env-file $(ENV_FILE) --rm -v $(PWD):/srv/app -w /srv/app node:lts yarn
CMD=bash
SYMFONY_CMD=


chown:
	@sudo chown -R $(USER):$(USER) $(PWD)

up:
	@if [ $(DOCKER_APP_STAT) = 1  ]; then echo "O container app já está rodando"; else \
	make -s .gerar-env-local; \
	make -s .composer-install; \
	make -s .yarn-install; \
	$(DOCKER_COMPOSE) up -d --remove-orphans --force-recreate; \
	make -s migrate; \
	make -s chown; \
	fi

down:
	@$(DOCKER_COMPOSE) down --rmi local -v --remove-orphans

log: up
	@$(DOCKER_COMPOSE) logs -f

app-bash: up
	@$(DOCKER_COMPOSE) exec app bash
	@make -s chown

psql: up
	$(DOCKER_COMPOSE) exec db_postgres su postgres -c 'psql -U $$POSTGRES_USER -d $$POSTGRES_DB -w'

app-bash-cmd: up
	@$(DOCKER_COMPOSE) exec app $(CMD)
	@make -s chown

symfony-cmd: up
	@$(DOCKER_COMPOSE) exec app symfony $(SYMFONY_CMD)
	@make -s chown

yarn-cmd:
	@$(DOCKER_YARN_RUN) $(YARN_CMD)
	@make -s chown

qa: up
	@$(DOCKER_APP_RUN) vendor/bin/php-cs-fixer fix --allow-risky yes
	@$(DOCKER_APP_RUN) vendor/bin/phpstan analyse --level 4 src tests
	@make -s test
	@make -s phploc

phploc: up
	@make app-bash-cmd CMD="vendor/bin/phploc src tests --log-csv /srv/app/doc/phploc/temp.csv"
	@make chown
	@echo -n "\"" >> $(PWD)/doc/phploc/historico.csv
	@echo -n `date "+%Y-%m-%d %H:%M:%S%z"` >> $(PWD)/doc/phploc/historico.csv
	@echo -n "\"," >> $(PWD)/doc/phploc/historico.csv
	@tail -n 1 $(PWD)/doc/phploc/temp.csv >> $(PWD)/doc/phploc/historico.csv
	@rm $(PWD)/doc/phploc/temp.csv >> $(PWD)/doc/phploc/historico.csv

test:
	@$(DOCKER_APP_RUN) vendor/bin/phpunit

build:
	@echo "Building... TODO"

push:
	@echo "Pushing... TODO"

prerelease: .test-branch yarn
	@$(DOCKER_YARN_RUN) run standard-version --no-verify --prerelease $(VERSAO)
	@make -s .post-release

release-patch: .test-branch yarn
	@$(DOCKER_YARN_RUN) run standard-version --no-verify --release-as patch
	@make -s .post-release

release-minor: .test-branch yarn
	@$(DOCKER_YARN_RUN) run standard-version --no-verify --release-as minor
	@make -s .post-release

criar-migracao:
	@$(DOCKER_COMPOSE) exec app symfony $(SYMFONY_CMD) console make:migration --quiet --no-debug

migrate:
	@$(DOCKER_COMPOSE) exec app symfony $(SYMFONY_CMD) console doctrine:migrations:migrate --no-interaction --allow-no-migration --quiet

clean:
	@rm -rf $(PWD)/vendor/ $(PWD)/node_modules/ $(PWD)/var/ $(PWD)/.env.local $(PWD)/composer.lock $(PWD)/yarn.lock
	@echo "Arquivos removidos"

.post-release:
	@make -s build
	@make -s push

.test-branch:
	@if [ ! $(BRANCH_ATUAL) = "release" ]; then \
  echo "\e[1;40;31mLiberações são permitidas apenas na branch 'release'\e[0m"; \
  exit 255; \
  fi

.gerar-arquivo-com-licencas: up
	@$(DOCKER_YARN_RUN)
	@$(DOCKER_YARN_RUN) licenses list --prod > $(LICENSE_JS_PACKAGES_FILE)
	@$(DOCKER_APP_RUN) composer licenses --no-dev --no-interaction --no-cache --no-ansi > LICENSE_PHP_PACKAGES
	@sed -i "/Xdebug:.*Could not connect/d" $(LICENSE_PHP_PACKAGES_FILE)
	@echo -n "Atualizado em: " >> $(LICENSE_JS_PACKAGES_FILE)
	@date "+%Y-%m-%d %H:%M:%S%z" >> $(LICENSE_JS_PACKAGES_FILE)
	@echo -n "Atualizado em: " >> $(LICENSE_PHP_PACKAGES_FILE)
	@date "+%Y-%m-%d %H:%M:%S%z" >> $(LICENSE_PHP_PACKAGES_FILE)
	@make -s chown

.yarn-install: .gerar-env-local
	@echo "Instalando/Atualizando pacotes javascript"
	@$(DOCKER_YARN_RUN)
	@make -s .instalacao-husky
	@make -s chown

.composer-install: .gerar-env-local
	@echo "Instalando/Atualizando pacotes do composer"
	@if [ -d $(PWD)/vendor ]; then $(DOCKER_APP_RUN) composer update; else $(DOCKER_APP_RUN) composer install; fi
	@make -s chown

.gerar-env-local:
	@cat $(PWD)/.env > $(ENV_FILE)
	@proxy_test=0 env | grep -iE "proxy" >> $(ENV_FILE)
	@echo "APP_VERSION="$(APP_VERSION) >> $(ENV_FILE)

.instalacao-husky:
	@if [ `git config --local --list | grep "core[.]hookspath.*husky" | wc -l` = 0 ]; then \
	make yarn-cmd YARN_CMD="run husky install"; \
	fi
