DOCKER_APP_EXEC="docker-compose exec app"
DOCKER_APP_RUN=docker run -it --rm -v $(PWD):/srv/app pmprcoger/symfony:latest
ENV_FILE=$(PWD)/.env

chown:
	sudo chown -R $(USER):$(USER) $(PWD)

up: .composer-install
	docker-compose --env-file $(ENV_FILE) up -d --remove-orphans --force-recreate

down:
	docker-compose down --rmi local -v --remove-orphans

log:
	docker-compose logs -f

app-bash:
	docker-compose exec app bash

.composer-install:
	$(DOCKER_APP_RUN) composer install
