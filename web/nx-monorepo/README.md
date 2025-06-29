# Nx


## Setup

```bash
npx nx@latest init
```


## Usage

### Quick Start (Makefile)

```bash
# Most common commands
make build          # Build all services
make test           # Test all services
make install        # Install all dependencies
make clean          # Clean all builds
make dev            # Setup development environment
make ci             # Run CI pipeline

# Individual services
make build-service-a
make test-service-b

# Show all available commands
make help
```

### Advanced Usage (Nx Direct)

```bash
./nx build my-project
./nx generate application
./nx graph
```

### Custom commands

```bash
./nx run service-a:install

./nx install service-a

./nx test service-a

./nx build service-a
```

### Commands for all services

```bash
# Build all services
./nx run-many --target=build --all

# Test all services
./nx run-many --target=test --all

# Install dependencies for all services
./nx run-many --target=install --all

# Clean all builds
./nx run-many --target=clean --all

# Run only affected services (based on changes)
./nx affected --target=build

# Run commands in parallel (default)
./nx run-many --target=build --all --parallel

# Run commands sequentially
./nx run-many --target=build --all --parallel=false
```

### Useful commands

```bash
# List all projects
./nx list

# View dependency graph
./nx graph

# Run specific services by name
./nx run-many --target=build --projects=service-a,service-b

# Run services by tags
./nx run-many --target=build --tags=scope:myteam
```

## Ref

https://nx.dev/recipes/installation/install-non-javascript

https://nx.dev/getting-started/tutorials/gradle-tutorial

https://nx.dev/reference/nx-json#nxjson

https://nx.dev/reference/project-configuration

https://nx.dev/concepts/executors-and-configurations#run-a-terminal-command-from-an-executor

https://nx.dev/reference/core-api/nx/executors/run-commands#examples
