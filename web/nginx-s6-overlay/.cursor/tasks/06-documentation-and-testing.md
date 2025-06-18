# Tarefa 6: Documentação e Testes

## Objetivo
Melhorar a documentação do projeto e implementar testes automatizados.

## Prioridade: MÉDIA
## Complexidade: BAIXA
## Tempo Estimado: 2-3 horas

## Subtarefas

### 6.1 Atualizar README.md
**Objetivo**: Documentar o projeto de forma completa
**Arquivos a modificar**: `README.md`
**Linhas a alterar**: 1-28

**Conteúdo a adicionar**:
```markdown
# nginx-s6-overlay

Uma aplicação web otimizada que combina backend Crystal com frontend servido pelo nginx, usando s6-overlay para orquestração de processos em um único container Docker.

## Características

- 🚀 Backend Crystal de alta performance
- 🌐 Nginx como proxy reverso e servidor de arquivos estáticos
- 🔄 s6-overlay para gerenciamento de processos
- 🔒 Configurações de segurança otimizadas
- 📊 Health checks e métricas
- 🐳 Container Docker otimizado

## Arquitetura

```
┌─────────────────┐
│   Nginx (80)    │ ← Proxy reverso + arquivos estáticos
├─────────────────┤
│  Crystal API    │ ← Backend na porta 3000
│   (3000)        │
├─────────────────┤
│  s6-overlay     │ ← Orquestração de processos
└─────────────────┘
```

## Instalação

```bash
# Clone o repositório
git clone <repository-url>
cd nginx-s6-overlay

# Build da imagem
make build

# Executar container
make run
```

## Uso

### Endpoints Disponíveis

- `GET /` - Frontend (HTML estático)
- `GET /api` - API Crystal backend
- `GET /api/health` - Health check
- `GET /api/metrics` - Métricas Prometheus

### Variáveis de Ambiente

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `PORT` | `3000` | Porta do backend Crystal |
| `HOST` | `0.0.0.0` | Host do backend Crystal |
| `LOG_LEVEL` | `info` | Nível de log |

### Comandos Make

```bash
make build    # Build da imagem Docker
make run      # Executar container
make stop     # Parar container
make logs     # Ver logs
make clean    # Limpar recursos
make scan     # Scan de vulnerabilidades
```

## Desenvolvimento

### Estrutura do Projeto

```
.
├── Dockerfile              # Multi-stage build otimizado
├── Makefile               # Comandos de automação
├── shard.yml              # Dependências Crystal
├── src/
│   └── app.cr             # Backend Crystal
├── rootfs/
│   └── etc/
│       ├── nginx/         # Configurações nginx
│       └── services.d/    # Scripts s6-overlay
└── www/                   # Arquivos estáticos
```

### Adicionando Novos Endpoints

1. Edite `src/app.cr`
2. Adicione nova rota
3. Teste localmente: `crystal run src/app.cr`
4. Rebuild: `make build`

## Performance

### Métricas de Baseline

- **Tamanho da imagem**: ~150MB
- **Tempo de startup**: <10s
- **Throughput**: 1000+ req/s
- **Latência média**: <50ms

### Otimizações Implementadas

- Multi-stage Docker build
- Cache de arquivos estáticos
- Compressão gzip
- Headers de segurança
- Rate limiting
- Health checks

## Segurança

### Medidas Implementadas

- Usuário não-root
- Headers de segurança
- Rate limiting
- Logs de auditoria
- Scanning de vulnerabilidades
- Secrets management

## Troubleshooting

### Logs

```bash
# Ver logs do container
make logs

# Ver logs específicos
docker exec container_name tail -f /var/log/nginx/access.log
docker exec container_name tail -f /var/log/nginx/error.log
```

### Health Check

```bash
# Verificar saúde da aplicação
curl http://localhost/api/health

# Verificar métricas
curl http://localhost/api/metrics
```

## Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature
3. Implemente as mudanças
4. Adicione testes
5. Atualize documentação
6. Abra um Pull Request

## Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.
```

### 6.2 Implementar testes básicos
**Objetivo**: Adicionar testes automatizados
**Arquivos a modificar**: `spec/`, `Makefile`
**Linhas a adicionar**: Várias

**Testes Crystal**:
```crystal
# spec/app_spec.cr
require "spec"
require "../src/app"

describe App do
  it "should respond to health check" do
    # Teste básico de health check
    response = HTTP::Client.get("http://localhost:3000/health")
    response.status_code.should eq(200)
  end
end
```

**Testes de integração**:
```bash
# test/integration.sh
#!/bin/bash
set -e

echo "🧪 Running integration tests..."

# Teste de health check
curl -f http://localhost/api/health || exit 1

# Teste de métricas
curl -f http://localhost/api/metrics || exit 1

# Teste de frontend
curl -f http://localhost/ || exit 1

echo "✅ All integration tests passed!"
```

### 6.3 Adicionar CI/CD básico
**Objetivo**: Automatizar build e testes
**Arquivos a modificar**: `.github/workflows/ci.yml`
**Linhas a adicionar**: Arquivo novo

**GitHub Actions**:
```yaml
name: CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Crystal
      uses: crystal-lang/install-crystal@v1
      with:
        crystal: 1.16

    - name: Install dependencies
      run: shards install

    - name: Run tests
      run: crystal spec

    - name: Build Docker image
      run: make build

    - name: Run integration tests
      run: |
        make run
        sleep 10
        ./test/integration.sh
        make stop
```

### 6.4 Criar documentação de API
**Objetivo**: Documentar endpoints da API
**Arquivos a modificar**: `docs/api.md`
**Linhas a adicionar**: Arquivo novo

**Documentação da API**:
```markdown
# API Documentation

## Base URL
`http://localhost/api`

## Endpoints

### GET /health
Health check da aplicação.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z",
  "uptime": 123.456
}
```

### GET /metrics
Métricas no formato Prometheus.

**Response:**
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/"} 42
```

### GET /
Endpoint principal da API.

**Response:**
```
Hello from Crystal backend!
```
```

### 6.5 Adicionar exemplos de uso
**Objetivo**: Fornecer exemplos práticos
**Arquivos a modificar**: `examples/`
**Linhas a adicionar**: Vários arquivos

**Exemplos**:
```bash
# examples/curl-examples.sh
#!/bin/bash

echo "Testing API endpoints..."

# Health check
echo "Health check:"
curl -s http://localhost/api/health | jq .

# Metrics
echo "Metrics:"
curl -s http://localhost/api/metrics

# Main endpoint
echo "Main endpoint:"
curl -s http://localhost/api
```

## Critérios de Aceitação
- [ ] README.md está completo e atualizado
- [ ] Testes básicos estão funcionando
- [ ] CI/CD está configurado
- [ ] Documentação da API está disponível
- [ ] Exemplos de uso estão incluídos

## Comandos de Teste
```bash
# Executar testes
crystal spec

# Executar testes de integração
./test/integration.sh

# Verificar documentação
markdownlint README.md docs/*.md

# Testar build
make build && make run
```

## Notas para LLM
- Manter documentação atualizada com mudanças
- Testes devem ser rápidos e confiáveis
- CI/CD deve falhar rápido em caso de problemas
- Exemplos devem ser práticos e funcionais
- Documentação deve ser clara para novos desenvolvedores
