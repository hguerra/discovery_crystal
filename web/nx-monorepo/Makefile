# Nx Monorepo Makefile
# Simplifica o uso diário dos comandos Nx
# Todos os comandos mantêm os recursos avançados do Nx (cache, affected, etc.)

.PHONY: help install build test clean all-build all-test all-install all-clean graph list affected affected-test affected-install dev dev-all dev-service-a dev-service-b dev-watch-all dev-watch-a dev-watch-b

# Default target
help:
	@echo "Nx Monorepo - Available commands:"
	@echo ""
	@echo "Quick commands (most common):"
	@echo "  build                Build all services (with Nx cache)"
	@echo "  test                 Test all services (with Nx cache)"
	@echo "  install              Install dependencies for all services"
	@echo "  clean                Clean all builds"
	@echo "  dev                  Setup development environment"
	@echo "  ci                   Run CI pipeline"
	@echo ""
	@echo "Development commands (with Nx watch):"
	@echo "  dev-watch-all        Run all services with Nx watch (rebuild on changes)"
	@echo "  dev-watch-a          Run service-a with Nx watch"
	@echo "  dev-watch-b          Run service-b with Nx watch"
	@echo "  dev-service-a        Run service-a (uses cached build)"
	@echo "  dev-service-b        Run service-b (uses cached build)"
	@echo "  dev-all              Run all services (uses cached builds)"
	@echo ""
	@echo "Smart commands (Nx affected):"
	@echo "  affected             Build only affected services"
	@echo "  affected-test        Test only affected services"
	@echo "  affected-install     Install only affected services"
	@echo ""
	@echo "Individual services:"
	@echo "  install-service-a    Install dependencies for service-a"
	@echo "  install-service-b    Install dependencies for service-b"
	@echo "  build-service-a      Build service-a (with Nx cache)"
	@echo "  build-service-b      Build service-b (with Nx cache)"
	@echo "  test-service-a       Test service-a (with Nx cache)"
	@echo "  test-service-b       Test service-b (with Nx cache)"
	@echo "  clean-service-a      Clean service-a"
	@echo "  clean-service-b      Clean service-b"
	@echo ""
	@echo "All services:"
	@echo "  all-install          Install dependencies for all services"
	@echo "  all-build            Build all services (with Nx cache)"
	@echo "  all-test             Test all services (with Nx cache)"
	@echo "  all-clean            Clean all services"
	@echo ""
	@echo "Utilities:"
	@echo "  graph                Show dependency graph"
	@echo "  list                 List all projects"
	@echo "  help                 Show this help"
	@echo ""
	@echo "Note: All commands use Nx features (cache, affected, parallel execution)"

# Individual service commands (with Nx cache)
install-air:
	mkdir -p ./bin
	curl -sSfL https://raw.githubusercontent.com/air-verse/air/master/install.sh | sh -s

install-service-a:
	./nx run service-a:install

install-service-b:
	./nx run service-b:install

build-service-a:
	./nx run service-a:build

build-service-b:
	./nx run service-b:build

test-service-a:
	./nx run service-a:test

test-service-b:
	./nx run service-b:test

clean-service-a:
	./nx run service-a:clean

clean-service-b:
	./nx run service-b:clean

# Development commands (uses cached builds)
dev-service-a:
	./nx run service-a:dev

dev-service-b:
	./nx run service-b:dev

# Nx Watch commands (hot reload)
dev-watch-a:
	./nx run service-a:dev-watch

dev-watch-b:
	./nx run service-b:dev-watch

dev-watch-all:
	./nx run-many --target=dev-watch --all

# All services commands (with Nx cache and parallel execution)
all-install:
	./nx run-many --target=install --all

all-build:
	./nx run-many --target=build --all

all-test:
	./nx run-many --target=test --all

all-clean:
	./nx run-many --target=clean --all

# Development commands for all services
dev-all:
	./nx run-many --target=dev --all

# Smart commands using Nx affected (only changed services)
affected:
	./nx affected --target=build

affected-test:
	./nx affected --target=test

affected-install:
	./nx affected --target=install

# Utility commands
graph:
	./nx graph

list:
	./nx list

# Development shortcuts (composite commands)
dev: all-install all-build
	@echo "Development environment ready!"

ci: all-install all-test all-build
	@echo "CI pipeline completed!"

# Quick commands (most common) - aliases for convenience
install: install-air all-install
build: all-build
test: all-test
clean: all-clean
