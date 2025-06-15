build_openresty:
	podman build -f Dockerfile.openresty -t discovery-openresty .

up_openresty:
	podman compose -f compose-openresty.yaml up -d
	podman ps

exec_openresty:
	podman exec -it openresty /bin/sh

down_openresty:
	podman compose -f compose-openresty.yaml down

build_dev_api:
	podman build -f Dockerfile.dev -t crystal-dev

run_dev_api:
	podman run --name discovery_api -it --rm -p "3000:3000" -v "./src:/usr/app/src" localhost/crystal-dev:latest /bin/ash
