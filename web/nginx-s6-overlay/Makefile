IMAGE_NAME=myapp:local
CONTAINER_NAME=myapp_local

.PHONY: build run stop logs clean test test-simple

build:
	docker build -t $(IMAGE_NAME) .

run:
	docker run --rm -d -p 8080:8080 --name $(CONTAINER_NAME) $(IMAGE_NAME)

stop:
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true

logs:
	docker logs -f $(CONTAINER_NAME)

clean: stop
	docker rmi $(IMAGE_NAME) || true

test:
	./scripts/test-load-balancing.sh

test-simple:
	node tests/simple-test.js
