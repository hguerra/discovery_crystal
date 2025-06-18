# Tarefa 3: Melhorias no Backend Crystal

## Objetivo
Melhorar o backend Crystal com health checks, logging, configuração e graceful shutdown.

## Prioridade: MÉDIA
## Complexidade: MÉDIA
## Tempo Estimado: 2-3 horas

## Subtarefas

### 3.1 Adicionar health check endpoint
**Objetivo**: Permitir monitoramento da saúde da aplicação
**Arquivos a modificar**: `src/app.cr`
**Linhas a alterar**: 1-16

**Funcionalidades a adicionar**:
```crystal
# Health check endpoint
get "/health" do |ctx|
  ctx.response.content_type = "application/json"
  {
    status: "healthy",
    timestamp: Time.utc.to_iso8601,
    uptime: Process.clock_gettime(Process::CLOCK_MONOTONIC)
  }.to_json
end
```

### 3.2 Implementar logging estruturado
**Objetivo**: Melhorar observabilidade da aplicação
**Arquivos a modificar**: `src/app.cr`
**Linhas a adicionar**: Após require "http"

**Dependências a adicionar**: `shard.yml`
```yaml
dependencies:
  log:
    github: crystal-lang/log
    version: ~> 0.1
```

**Código de logging**:
```crystal
require "log"

Log.setup do |c|
  backend = Log::IOBackend.new
  c.bind("*", :info, backend)
end

# Log de requests
before_all do |ctx|
  Log.info { "Request: #{ctx.request.method} #{ctx.request.path}" }
end
```

### 3.3 Configuração via variáveis de ambiente
**Objetivo**: Tornar a aplicação configurável
**Arquivos a modificar**: `src/app.cr`
**Linhas a alterar**: 1-16

**Configurações a adicionar**:
```crystal
# Configuração via env vars
PORT = ENV["PORT"]? || "3000"
HOST = ENV["HOST"]? || "0.0.0.0"
LOG_LEVEL = ENV["LOG_LEVEL"]? || "info"

# Configurar log level
Log.level = Log::Level.parse(LOG_LEVEL)
```

### 3.4 Implementar graceful shutdown
**Objetivo**: Permitir shutdown seguro da aplicação
**Arquivos a modificar**: `src/app.cr`
**Linhas a adicionar**: Antes do server.listen

**Código de graceful shutdown**:
```crystal
# Graceful shutdown
Signal::INT.trap do
  Log.info { "Shutting down gracefully..." }
  server.close
  exit 0
end

Signal::TERM.trap do
  Log.info { "Shutting down gracefully..." }
  server.close
  exit 0
end
```

### 3.5 Adicionar métricas básicas
**Objetivo**: Permitir monitoramento de performance
**Arquivos a modificar**: `src/app.cr`
**Linhas a adicionar**: Após health check

**Endpoint de métricas**:
```crystal
# Métricas básicas
get "/metrics" do |ctx|
  ctx.response.content_type = "text/plain"
  <<-METRICS
  # HELP http_requests_total Total number of HTTP requests
  # TYPE http_requests_total counter
  http_requests_total{method="GET",path="/"} #{request_count}
  METRICS
end
```

## Critérios de Aceitação
- [ ] Health check retorna status correto
- [ ] Logs são estruturados e informativos
- [ ] Configuração via env vars funciona
- [ ] Graceful shutdown funciona
- [ ] Métricas estão disponíveis

## Comandos de Teste
```bash
# Testar health check
curl http://localhost:3000/health

# Testar métricas
curl http://localhost:3000/metrics

# Testar graceful shutdown
docker exec -it container_name kill -TERM 1

# Verificar logs
docker logs container_name
```

## Notas para LLM
- Manter compatibilidade com nginx proxy
- Testar cada funcionalidade individualmente
- Verificar se s6-overlay detecta o shutdown
- Considerar performance impact das mudanças
- Documentar endpoints no README.md
