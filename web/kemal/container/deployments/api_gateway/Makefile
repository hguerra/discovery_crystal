.PHONY: config

install:
	mkdir ./bin
	curl -L https://github.com/hguerra/envsubst/releases/download/v1.0.6/envsubst_linux_amd64 -o bin/envsubst && chmod +x bin/envsubst

config:
	bin/envsubst -no-empty < config/kong-template.yaml > kong.yaml

clean:
	rm -f kong.yaml

# https://docs.konghq.com/gateway/latest/production/deployment-topologies/db-less-and-declarative-config/
# https://docs.konghq.com/gateway/latest/install/docker/
build_docker:
	docker build --network host -t heitorcarneiro/kong:3.2.2-ubuntu .

build: clean config build_docker

up: config
	docker compose up -d
	docker logs -f kong

down: clean
	docker compose down
	docker compose rm -f

restart: config
	docker compose restart kong
	docker logs -f kong

test_health:
	curl -i -X GET http://localhost:8080/gateway/health/incidents.schema.json?auth_token=abc

test_gzip:
	curl --compressed -i -X GET http://localhost:8080/gateway/health/incidents.schema.json?auth_token=abc -H 'Accept-Encoding: gzip'

test_auth:
	curl -i -X GET http://localhost:8080/mock/request -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJhMzZjMzA0OWIzNjI0OWEzYzlmODg5MWNiMTI3MjQzYyIsImlhdCI6MTY4MTY1Njk3OSwiZXhwIjoxNjgxNjU4MzQ0LCJhdWQiOiJ3d3cuZXhhbXBsZS5jb20iLCJzdWIiOiJqcm9ja2V0QGV4YW1wbGUuY29tIiwiR2l2ZW5OYW1lIjoiSm9obm55IiwiU3VybmFtZSI6IlJvY2tldCIsIkVtYWlsIjoianJvY2tldEBleGFtcGxlLmNvbSIsIlJvbGUiOlsiTWFuYWdlciIsIlByb2plY3QgQWRtaW5pc3RyYXRvciJdfQ.9bWybQeBejaN5_vDhPGaNcPO4n0_e04StJUsaMRSugg'

test_performance:
	k6 run test/performance.test.js

test_serve:
	npx serve test
