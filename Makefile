build:
	docker-compose build web que

rails-server: build
	docker-compose up --build --abort-on-container-exit web que

rails-console: build
	docker-compose run --rm web bash

RAILS_COMMAND="db:migrate"
migrate:
	aws ecs run-task --cluster GreenDocuments-ClusterEB0386A7-kwsxyPlUHcXv --task-definition arn:aws:ecs:eu-central-1:343826926861:task-definition/GreenDocumentsTaskDefinitionRails5D03672F:8 --network-configuration "awsvpcConfiguration={subnets=[subnet-00ffae1cfa887308b,subnet-0a863b23944f1862d],securityGroups=[sg-0490d213869a80cdf],assignPublicIp=DISABLED}" --overrides '{ "containerOverrides": [ { "name": "web", "command": ["rails", "db:create", "db:migrate", "db:seed"] } ] }' --launch-type FARGATE --query "tasks[0].taskArn"
	awsinfo logs -s now GreenDocuments-TaskDefinition Rails