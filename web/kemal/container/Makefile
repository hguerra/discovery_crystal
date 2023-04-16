install:
	curl -sSfL https://raw.githubusercontent.com/cosmtrek/air/master/install.sh | sh -s
	shards install

clean:
	rm -rf ./tmp
	rm -rf ./Dockerfile
	rm -rf ./docker-entrypoint.sh

start:
	bin/server.cr

dev_air:
	DEBUG=1 bin/air -c .air.toml

dev:
	DEBUG=1 bin/dev.cr

lint:
	bin/ameba

format:
	crystal tool format -i ./

build: clean
	mkdir ./tmp
	APP_ENV=production crystal build -o ./tmp/main bin/server.cr --progress --release

start_prod:
	APP_ENV=production APP_PORT=3000 ./tmp/main

build_docker: clean
	cp deployments/docker/Dockerfile.reverse_proxy ./Dockerfile
	cp deployments/docker/docker-entrypoint.reverse_proxy.sh ./docker-entrypoint.sh
	docker build -t heitorcarneiro/tasks:0.1.0 .

start_docker:
	docker run --name tasks --rm -e JWT_SECRET=secret -e JWT_ISS=domain.com -p "8080:8080" heitorcarneiro/tasks:0.1.0

exec_docker:
	docker exec -it tasks /bin/sh

test_protected_proxy_pass:
	curl -i -X GET http://localhost:8080 -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJkb21haW4uY29tIiwiaWF0IjoxNjgxNzgxMjM1LCJleHAiOjE2ODE3ODI0NDQsImF1ZCI6Ind3dy5leGFtcGxlLmNvbSIsInN1YiI6Impyb2NrZXRAZXhhbXBsZS5jb20iLCJHaXZlbk5hbWUiOiJKb2hubnkiLCJTdXJuYW1lIjoiUm9ja2V0IiwiRW1haWwiOiJqcm9ja2V0QGV4YW1wbGUuY29tIiwiciI6WyJNYW5hZ2VyIiwiUHJvamVjdCBBZG1pbmlzdHJhdG9yIl19.5qrd8uu4Zq12x0pqucCbVBUGu3Zo8sQ0EQUZLF1o55o'
