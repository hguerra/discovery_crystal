IMAGE_NAME=myapp:local
CONTAINER_NAME=myapp_local

.PHONY: build run stop logs clean

build:
	docker build -t $(IMAGE_NAME) .

run:
	docker run --rm -d -p 8080:80 --name $(CONTAINER_NAME) $(IMAGE_NAME)

stop:
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true

logs:
	docker logs -f $(CONTAINER_NAME)

clean: stop
	docker rmi $(IMAGE_NAME) || true
