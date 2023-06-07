tika-shell:
	docker-compose build
	docker-compose run tika bash

rails-server:
	docker-compose up web

rails-console:
	docker-compose run web bash