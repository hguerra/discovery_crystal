clean:
	rm -rf bin
	mkdir bin

build_web:
	crystal build -o ./bin/web --release src/web.cr

start_web:
	bin/web

build_producers:
	crystal build -o ./bin/producers --release src/producers.cr

start_producers:
	bin/producers

build_consumers:
	crystal build -o ./bin/consumers --release src/consumers.cr

start_consumers:
	bin/consumers
