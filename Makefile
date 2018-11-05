.PHONY: run

run:
	docker-compose build && docker-compose run --rm web rails db:setup
