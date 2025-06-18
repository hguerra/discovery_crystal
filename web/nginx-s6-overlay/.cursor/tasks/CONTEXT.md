# Contexto para LLM - nginx-s6-overlay

## Visão Geral do Projeto

Este é um projeto de POC (Proof of Concept) que visa criar uma imagem Docker otimizada para executar backend e frontend em um único container, reduzindo custos de infraestrutura.

### Arquitetura Atual (Atualizada)
```
┌─────────────────┐
│   Nginx (80)    │ ← Proxy reverso + load balancing + arquivos estáticos
├─────────────────┤
│ Crystal API 1   │ ← Backend na porta 3001
│ Crystal API 2   │ ← Backend na porta 3002
│ Crystal API 3   │ ← Backend na porta 3003
├─────────────────┤
│  s6-overlay     │ ← Orquestração de múltiplos processos
└─────────────────┘
```

### Tecnologias Utilizadas
- **Backend**: Crystal (linguagem compilada, alta performance) - 3 instâncias
- **Frontend**: HTML estático servido pelo nginx
- **Proxy**: nginx como proxy reverso com load balancing
- **Orquestração**: s6-overlay para gerenciar múltiplos processos
- **Container**: Docker com multi-stage build
- **Testes**: k6 para testes de carga + Node.js para testes simples

## Estado Atual do Projeto

### ✅ Funcionalidades Implementadas
- **Backend Crystal com múltiplas instâncias** (3 instâncias: portas 3001, 3002, 3003)
- **Load balancing nginx** entre as instâncias Crystal
- **s6-overlay** orquestrando nginx e 3 instâncias Crystal
- **Multi-stage Docker build** otimizado
- **Frontend HTML** básico com JavaScript
- **Health check endpoint** (`/api/health`) com identificação de instância
- **Usuário não-root** (`appuser`)
- **Dockerignore** para otimizar build context
- **Cache de arquivos estáticos** (1 ano, headers corretos)
- **Compressão gzip** para tipos de conteúdo apropriados
- **Headers de segurança** (X-Frame-Options, CSP, etc.)
- **Rate limiting** (API: 10r/s, Static: 100r/s)
- **Logging estruturado em JSON** compatível com GCP/Stackdriver
- **Logs direcionados para stdout/stderr** (padrão containers)
- **Request ID** para tracing
- **Métricas Prometheus** (`/api/metrics`) por instância
- **Testes de carga com k6** para validar load balancing
- **Testes simples com Node.js** para desenvolvimento rápido
- **Documentação completa** sobre s6-overlay

### ❌ Funcionalidades Pendentes
- Configurações de segurança avançadas
- Métricas e monitoramento avançados
- CI/CD pipeline
- Testes de integração automatizados

## Estrutura de Arquivos Atual (Atualizada)

```
nginx-s6-overlay/
├── Dockerfile                    # Multi-stage build otimizado
├── .dockerignore                 # Exclui arquivos desnecessários
├── Makefile                      # Comandos de automação (inclui test e test-simple)
├── shard.yml                     # Dependências Crystal
├── docs/
│   ├── nginx-otimizacoes.md      # Documentação das otimizações nginx
│   └── s6-overlay-guia.md        # Guia completo sobre s6-overlay
├── src/
│   └── app.cr                    # Backend Crystal com suporte a múltiplas instâncias
├── rootfs/
│   └── etc/
│       ├── nginx/
│       │   ├── nginx.conf        # Configuração principal com logging JSON
│       │   └── conf.d/
│       │       └── default.conf  # Configuração com load balancing
│       └── services.d/
│           ├── crystal-api-1/    # Primeira instância Crystal
│           │   ├── run           # Script Crystal porta 3001
│           │   └── type          # Tipo longrun
│           ├── crystal-api-2/    # Segunda instância Crystal
│           │   ├── run           # Script Crystal porta 3002
│           │   └── type          # Tipo longrun
│           ├── crystal-api-3/    # Terceira instância Crystal
│           │   ├── run           # Script Crystal porta 3003
│           │   └── type          # Tipo longrun
│           └── nginx/            # Serviço nginx
│               ├── run           # Script nginx
│               └── type          # Tipo longrun
├── tests/
│   ├── load-test.js              # Teste de carga k6
│   ├── simple-test.js            # Teste simples Node.js (fetch API)
│   └── README.md                 # Documentação completa dos testes
├── scripts/
│   └── test-load-balancing.sh    # Script para executar testes k6
└── www/
    ├── index.html                # Frontend básico
    └── logo.svg                  # Arquivo estático para teste de cache
```

## Código Atual dos Arquivos Principais

### Dockerfile (otimizado)
```dockerfile
# -------- Stage 1: Build backend
FROM crystallang/crystal:1.16 AS backend

WORKDIR /opt/my-api
COPY shard.yml shard.lock* ./
RUN shards install

COPY src/ ./src/
RUN crystal build src/app.cr -o /usr/bin/my-api --release

# -------- Stage 2: nginx + s6-overlay
FROM nginx:1.27-bookworm AS nginx_s6

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_SERVICES_GRACETIME=5000

# Install s6-overlay and create non-root user
RUN apt-get update && apt-get install -y --no-install-recommends curl xz-utils \
  && curl -L https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-noarch.tar.xz | tar -C / -Jx \
  && curl -L https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-x86_64.tar.xz | tar -C / -Jx \
  && groupadd -r appuser && useradd -r -g appuser appuser \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy configuration files first (better cache)
COPY rootfs/ /

# Set proper permissions for all service scripts
RUN chmod +x /etc/services.d/nginx/run \
  && chmod +x /etc/services.d/crystal-api-1/run \
  && chmod +x /etc/services.d/crystal-api-2/run \
  && chmod +x /etc/services.d/crystal-api-3/run \
  && mkdir -p /run/secrets && chown appuser:appuser /run/secrets

# Copy static files
COPY --chown=appuser:appuser www/ /var/www/html/
RUN chown -R appuser:appuser /var/www/html /var/log/nginx /var/cache/nginx

# -------- Stage 3: Final image
FROM nginx_s6 AS final

# Copy binary from backend stage and set permissions
COPY --from=backend /usr/bin/my-api /usr/bin/my-api
RUN chown appuser:appuser /usr/bin/my-api && chmod +x /usr/bin/my-api

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/api/health || exit 1

ENTRYPOINT ["/init"]
```

### Backend Crystal (src/app.cr) - com suporte a múltiplas instâncias
```crystal
require "http"
require "json"
require "log"

# Backend customizado para GCP/Stackdriver
class GCPJsonBackend < Log::Backend
  def write(entry : Log::Entry)
    data = {
      "timestamp" => entry.timestamp.to_s("%Y-%m-%dT%H:%M:%S.%6NZ"),
      "severity" => entry.severity.to_s.upcase,
      "message" => entry.message,
      "logging.googleapis.com/sourceLocation" => {
        "file" => "app.cr",
        "line" => entry.source,
        "function" => "log"
      }
    }
    if trace = ENV["GCP_TRACE_ID"]?
      data["logging.googleapis.com/trace"] = trace
    end
    data["logging.googleapis.com/labels"] = {
      "environment" => ENV["ENVIRONMENT"]? || "development",
      "app_version" => App::VERSION,
      "crystal_version" => Crystal::VERSION,
      "instance_id" => ENV["INSTANCE_ID"]? || "1"
    }
    if op_id = ENV["OPERATION_ID"]?
      data["logging.googleapis.com/operation"] = {
        "id" => op_id,
        "producer" => "crystal-backend",
        "first" => "true",
        "last" => "true"
      }
    end
    STDOUT.puts data.to_json
  end
end

# Configurar logging via env, usando backend customizado
Log.setup do |c|
  backend = GCPJsonBackend.new
  level = case ENV["LOG_LEVEL"]?.try(&.downcase)
    when "debug"   then Log::Severity::Debug
    when "info"    then Log::Severity::Info
    when "warn"    then Log::Severity::Warn
    when "error"   then Log::Severity::Error
    when "fatal"   then Log::Severity::Fatal
    else Log::Severity::Info
  end
  c.bind "*", level, backend
end

# Métricas básicas
class Metrics
  @@request_count = 0
  @@start_time = Time.utc

  def self.increment_request
    @@request_count += 1
  end

  def self.get_metrics
    {
      requests_total: @@request_count,
      uptime_seconds: (Time.utc - @@start_time).total_seconds.to_i
    }
  end
end

# Log de requests
class RequestLogger
  include HTTP::Handler

  def call(context)
    start_time = Time.utc
    call_next(context)
    duration = Time.utc - start_time

    Metrics.increment_request

    Log.info { "Request: #{context.request.method} #{context.request.path} - #{context.response.status_code} (#{duration.total_milliseconds.round(2)}ms)" }
  end
end

# Error handler
class ErrorHandler
  include HTTP::Handler

  def call(context)
    call_next(context)
  rescue ex : Exception
    Log.error { "Unhandled exception: #{ex.message}" }
    Log.error { ex.backtrace.join("\n") }

    context.response.status_code = 500
    context.response.content_type = "application/json"
    context.response.print({
      error: "Internal Server Error",
      message: ex.message,
      timestamp: Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ")
    }.to_json)
  end
end

# TODO: Write documentation for `App`
module App
  VERSION = "0.1.0"
end

# Configuração via env vars
port = ENV["PORT"]? || "3000"
host = ENV["HOST"]? || "0.0.0.0"
environment = ENV["ENVIRONMENT"]? || "development"
instance_id = ENV["INSTANCE_ID"]? || "1"

Log.info { "Starting Crystal server instance #{instance_id} in #{environment} mode" }
Log.info { "Server will listen on #{host}:#{port}" }

# Start server with handlers
server = HTTP::Server.new([
  RequestLogger.new,
  ErrorHandler.new
]) do |ctx|
  case ctx.request.path
  when "/", "/api"
    ctx.response.content_type = "text/plain"
    ctx.response.print "Hello from Crystal backend instance #{instance_id}!"
  when "/health", "/api/health"
    ctx.response.content_type = "application/json"
    ctx.response.print {
      status: "healthy",
      instance_id: instance_id,
      timestamp: Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ"),
      uptime: Metrics.get_metrics[:uptime_seconds],
      requests_total: Metrics.get_metrics[:requests_total]
    }.to_json
  when "/metrics", "/api/metrics"
    ctx.response.content_type = "text/plain"
    metrics = Metrics.get_metrics
    ctx.response.print <<-METRICS
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{instance=\"#{instance_id}\"} #{metrics[:requests_total]}
# HELP http_server_uptime_seconds Server uptime in seconds
# TYPE http_server_uptime_seconds gauge
http_server_uptime_seconds{instance=\"#{instance_id}\"} #{metrics[:uptime_seconds]}
METRICS
  else
    ctx.response.status_code = 404
    ctx.response.print "Not Found"
  end
end

# Graceful shutdown
Signal::INT.trap do
  Log.info { "Instance #{instance_id}: Received SIGINT, shutting down gracefully..." }
  server.close
  exit 0
end

Signal::TERM.trap do
  Log.info { "Instance #{instance_id}: Received SIGTERM, shutting down gracefully..." }
  server.close
  exit 0
end

address = server.bind_tcp(host, port.to_i)
Log.info { "🚀 Crystal server instance #{instance_id} listening on #{address}" }
server.listen
```

### Scripts de Serviço s6-overlay

#### crystal-api-1/run
```bash
#!/bin/bash
echo "Starting Crystal API instance 1 on port 3001..."
export PORT=3001
export INSTANCE_ID=1
exec /usr/bin/my-api
```

#### crystal-api-2/run
```bash
#!/bin/bash
echo "Starting Crystal API instance 2 on port 3002..."
export PORT=3002
export INSTANCE_ID=2
exec /usr/bin/my-api
```

#### crystal-api-3/run
```bash
#!/bin/bash
echo "Starting Crystal API instance 3 on port 3003..."
export PORT=3003
export INSTANCE_ID=3
exec /usr/bin/my-api
```

#### nginx/run
```bash
#!/bin/bash
exec nginx -g "daemon off;"
```

### Configuração Nginx com Load Balancing (rootfs/etc/nginx/conf.d/default.conf)
```nginx
# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=static:10m rate=100r/s;

# Upstream para load balancing das instâncias Crystal
upstream crystal_cluster {
    # Round-robin load balancing (padrão)
    server localhost:3001 weight=1 max_fails=3 fail_timeout=30s;
    server localhost:3002 weight=1 max_fails=3 fail_timeout=30s;
    server localhost:3003 weight=1 max_fails=3 fail_timeout=30s;

    # Configurações de health check
    keepalive 32;  # Conexões persistentes
}

server {
  listen 80;

  # Compressão gzip
  gzip on;
  gzip_vary on;
  gzip_min_length 1024;
  gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

  # Headers de segurança
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-XSS-Protection "1; mode=block" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;

  location /api {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://crystal_cluster;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Request-ID $request_id;
    proxy_connect_timeout 5s;
    proxy_send_timeout 10s;
    proxy_read_timeout 10s;
    proxy_buffering off;
  }

  # Cache para arquivos estáticos (deve vir ANTES do location /)
  location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    root /var/www/html;
    expires 1y;
    add_header Cache-Control "public, immutable, max-age=31536000";
    access_log off;
  }

  location / {
    limit_req zone=static burst=100 nodelay;
    root /var/www/html;
    index index.html;
    try_files $uri $uri/ =404;
  }
}
```

### Teste Simples Node.js (tests/simple-test.js)
```javascript
#!/usr/bin/env node

/**
 * Teste Simples - nginx-s6-overlay
 *
 * Script Node.js para verificar se as APIs e página index.html estão funcionando.
 * Usa fetch API (disponível no Node.js 18+) para requisições HTTP.
 */

// Configuração
const BASE_URL = 'http://localhost:8080';
const TIMEOUT = 5000; // 5 segundos

// Cores para output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

// Função para imprimir mensagens coloridas
function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// Função para fazer requisição HTTP usando fetch
async function makeRequest(path, description) {
  const url = `${BASE_URL}${path}`;
  const startTime = Date.now();

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), TIMEOUT);

    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'nginx-s6-overlay-test/1.0'
      }
    });

    clearTimeout(timeoutId);

    const duration = Date.now() - startTime;
    const data = await response.text();

    return {
      success: response.ok,
      statusCode: response.status,
      duration,
      data,
      headers: Object.fromEntries(response.headers.entries()),
      description
    };
  } catch (error) {
    const duration = Date.now() - startTime;

    if (error.name === 'AbortError') {
      return {
        success: false,
        statusCode: 0,
        duration,
        error: 'Timeout',
        description
      };
    }

    return {
      success: false,
      statusCode: 0,
      duration,
      error: error.message,
      description
    };
  }
}

// Função para testar load balancing
async function testLoadBalancing() {
  log('\n🔄 Testando Load Balancing...', 'cyan');

  const instances = new Set();
  const results = [];

  // Fazer 10 requisições para verificar distribuição
  for (let i = 0; i < 10; i++) {
    try {
      const result = await makeRequest('/api/health', `Health check ${i + 1}`);

      if (result.success) {
        try {
          const healthData = JSON.parse(result.data);
          if (healthData.instance_id) {
            instances.add(healthData.instance_id);
            log(`  ✓ Instância ${healthData.instance_id} respondendo`, 'green');
          }
        } catch (e) {
          log(`  ⚠️  Resposta não é JSON válido: ${result.data.substring(0, 100)}`, 'yellow');
        }
      } else {
        log(`  ✗ Erro na requisição ${i + 1}: ${result.error || `Status ${result.statusCode}`}`, 'red');
      }

      results.push(result);
    } catch (error) {
      log(`  ✗ Erro na requisição ${i + 1}: ${error.message}`, 'red');
    }

    // Pequena pausa entre requisições
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  log(`\n📊 Resultado do Load Balancing:`, 'blue');
  log(`  Instâncias únicas detectadas: ${instances.size}`, instances.size >= 2 ? 'green' : 'yellow');
  log(`  IDs das instâncias: ${Array.from(instances).join(', ')}`, 'cyan');

  if (instances.size >= 2) {
    log('  ✅ Load balancing funcionando corretamente!', 'green');
  } else if (instances.size === 1) {
    log('  ⚠️  Apenas uma instância detectada - verificar configuração', 'yellow');
  } else {
    log('  ❌ Nenhuma instância respondendo - verificar se o container está rodando', 'red');
  }
}

// Função principal de testes
async function runTests() {
  log('🧪 Teste Simples - nginx-s6-overlay', 'bright');
  log('=====================================', 'bright');

  const tests = [
    { path: '/', description: 'Página inicial (index.html)', expectedStatus: 200 },
    { path: '/api', description: 'API principal', expectedStatus: 200 },
    { path: '/api/health', description: 'Health check', expectedStatus: 200 },
    { path: '/api/metrics', description: 'Métricas Prometheus', expectedStatus: 200 },
    { path: '/logo.svg', description: 'Arquivo estático (logo.svg)', expectedStatus: 200 },
    { path: '/nonexistent', description: 'Página inexistente (404)', expectedStatus: 404 }
  ];

  let passedTests = 0;
  let totalTests = tests.length;

  log('\n📋 Executando testes básicos...', 'blue');

  for (const test of tests) {
    try {
      const result = await makeRequest(test.path, test.description);

      const isExpectedStatus = result.statusCode === test.expectedStatus;

      if (isExpectedStatus) {
        log(`  ✅ ${test.description}`, 'green');
        log(`     Status: ${result.statusCode}`, 'cyan');
        log(`     Tempo: ${result.duration}ms`, 'cyan');

        // Verificações específicas
        if (test.path === '/') {
          if (result.data.includes('<html')) {
            log(`     ✓ Contém HTML válido`, 'green');
          } else {
            log(`     ⚠️  Não parece ser HTML`, 'yellow');
          }
        } else if (test.path === '/api/health') {
          try {
            const healthData = JSON.parse(result.data);
            if (healthData.status === 'healthy' && healthData.instance_id) {
              log(`     ✓ Health check válido (instância ${healthData.instance_id})`, 'green');
            } else {
              log(`     ⚠️  Health check com formato inesperado`, 'yellow');
            }
          } catch (e) {
            log(`     ⚠️  Health check não é JSON válido`, 'yellow');
          }
        } else if (test.path === '/api/metrics') {
          if (result.data.includes('http_requests_total')) {
            log(`     ✓ Métricas Prometheus válidas`, 'green');
          } else {
            log(`     ⚠️  Métricas não estão no formato Prometheus`, 'yellow');
          }
        } else if (test.path === '/logo.svg') {
          if (result.headers['cache-control']) {
            log(`     ✓ Headers de cache presentes`, 'green');
          } else {
            log(`     ⚠️  Headers de cache ausentes`, 'yellow');
          }
        } else if (test.path === '/nonexistent') {
          log(`     ✓ 404 retornado corretamente`, 'green');
        }

        passedTests++;
      } else {
        log(`  ❌ ${test.description}`, 'red');
        log(`     Status: ${result.statusCode} (esperado: ${test.expectedStatus})`, 'red');
        log(`     Tempo: ${result.duration}ms`, 'red');
      }
    } catch (error) {
      log(`  ❌ ${test.description}`, 'red');
      log(`     Erro: ${error.message}`, 'red');
    }

    // Pequena pausa entre testes
    await new Promise(resolve => setTimeout(resolve, 200));
  }

  // Teste de load balancing
  await testLoadBalancing();

  // Resumo final
  log('\n📊 Resumo dos Testes', 'bright');
  log('====================', 'bright');
  log(`Testes básicos: ${passedTests}/${totalTests} passaram`, passedTests === totalTests ? 'green' : 'yellow');

  if (passedTests === totalTests) {
    log('🎉 Todos os testes passaram! O sistema está funcionando corretamente.', 'green');
  } else {
    log('⚠️  Alguns testes falharam. Verifique se o container está rodando corretamente.', 'yellow');
  }

  log('\n💡 Dicas:', 'blue');
  log('  - Execute "make run" para iniciar o container', 'cyan');
  log('  - Execute "make logs" para ver os logs', 'cyan');
  log('  - Execute "make stop" para parar o container', 'cyan');
  log('  - Execute "make test-simple" para executar este teste', 'cyan');
}

// Verificar se o script foi chamado diretamente
if (require.main === module) {
  runTests().catch(error => {
    log(`\n❌ Erro fatal: ${error.message}`, 'red');
    process.exit(1);
  });
}

module.exports = { runTests, makeRequest, testLoadBalancing };
```

### Teste de Carga k6 (tests/load-test.js)
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Métricas customizadas
const errorRate = new Rate('errors');

// Configuração do teste
export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Rampa de subida
    { duration: '1m', target: 50 },   // Carga constante
    { duration: '30s', target: 0 },   // Rampa de descida
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% das requisições devem ser < 500ms
    http_req_failed: ['rate<0.1'],    // Taxa de erro < 10%
    errors: ['rate<0.1'],             // Taxa de erro customizada < 10%
  },
};

// Função principal do teste
export default function () {
  // Teste 1: Health Check com Load Balancing
  const healthResponse = http.get('http://localhost:8080/api/health');

  check(healthResponse, {
    'health check status is 200': (r) => r.status === 200,
    'health check has instance_id': (r) => r.json('instance_id') !== undefined,
    'health check has status healthy': (r) => r.json('status') === 'healthy',
    'response time < 200ms': (r) => r.timings.duration < 200,
  });

  // Registrar erro se status não for 200
  errorRate.add(healthResponse.status !== 200);

  // Teste 2: API Principal
  const apiResponse = http.get('http://localhost:8080/api');

  check(apiResponse, {
    'api status is 200': (r) => r.status === 200,
    'api response contains instance': (r) => r.body.includes('instance'),
    'response time < 300ms': (r) => r.timings.duration < 300,
  });

  errorRate.add(apiResponse.status !== 200);

  // Teste 3: Métricas
  const metricsResponse = http.get('http://localhost:8080/api/metrics');

  check(metricsResponse, {
    'metrics status is 200': (r) => r.status === 200,
    'metrics contains prometheus format': (r) => r.body.includes('http_requests_total'),
    'response time < 200ms': (r) => r.timings.duration < 200,
  });

  errorRate.add(metricsResponse.status !== 200);

  // Teste 4: Frontend (arquivos estáticos)
  const frontendResponse = http.get('http://localhost:8080/');

  check(frontendResponse, {
    'frontend status is 200': (r) => r.status === 200,
    'frontend contains HTML': (r) => r.body.includes('<html'),
    'response time < 100ms': (r) => r.timings.duration < 100,
  });

  errorRate.add(frontendResponse.status !== 200);

  // Teste 5: Arquivo estático (logo.svg)
  const staticResponse = http.get('http://localhost:8080/logo.svg');

  check(staticResponse, {
    'static file status is 200': (r) => r.status === 200,
    'static file has cache headers': (r) => r.headers['Cache-Control'] !== undefined,
    'response time < 50ms': (r) => r.timings.duration < 50,
  });

  errorRate.add(staticResponse.status !== 200);

  // Pausa entre requisições
  sleep(1);
}

// Função executada no início do teste
export function setup() {
  console.log('🚀 Iniciando teste de carga para nginx-s6-overlay');
  console.log('📊 Testando load balancing entre 3 instâncias Crystal');
  console.log('⏱️  Duração total: 2 minutos');
}

// Função executada no final do teste
export function teardown(data) {
  console.log('✅ Teste de carga concluído');
  console.log('📈 Verifique os resultados para validar o load balancing');
}
```

### Script de Teste (scripts/test-load-balancing.sh)
```bash
#!/bin/bash

# Script para testar load balancing com k6
# Uso: ./scripts/test-load-balancing.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se k6 está instalado
check_k6() {
    if ! command -v k6 &> /dev/null; then
        print_error "k6 não está instalado. Instale com:"
        echo "  Ubuntu/Debian: sudo apt-get install k6"
        echo "  macOS: brew install k6"
        echo "  Docker: docker run -i grafana/k6 run -"
        exit 1
    fi
    print_success "k6 encontrado: $(k6 version)"
}

# Verificar se o container está rodando
check_container() {
    if ! docker ps | grep -q myapp_local; then
        print_error "Container myapp_local não está rodando. Execute: make run"
        exit 1
    fi
    print_success "Container myapp_local está rodando"
}

# Verificar se os serviços estão respondendo
check_services() {
    print_status "Verificando se os serviços estão respondendo..."

    # Testar health check
    if curl -s http://localhost:8080/api/health > /dev/null; then
        print_success "Health check OK"
    else
        print_error "Health check falhou"
        exit 1
    fi

    # Testar load balancing
    print_status "Testando load balancing..."
    instances=()
    for i in {1..10}; do
        instance_id=$(curl -s http://localhost:8080/api/health | jq -r '.instance_id')
        instances+=($instance_id)
        sleep 0.1
    done

    unique_instances=$(printf '%s\n' "${instances[@]}" | sort -u | wc -l)
    if [ $unique_instances -ge 2 ]; then
        print_success "Load balancing funcionando: $unique_instances instâncias únicas detectadas"
        echo "  Instâncias encontradas: $(printf '%s\n' "${instances[@]}" | sort -u | tr '\n' ' ')"
    else
        print_warning "Load balancing pode não estar funcionando: apenas $unique_instances instância única"
    fi
}

# Executar teste de carga
run_load_test() {
    print_status "Iniciando teste de carga com k6..."
    print_status "Duração: 2 minutos (30s subida, 1min carga, 30s descida)"
    print_status "Pico de carga: 50 usuários simultâneos"

    # Executar k6
    k6 run tests/load-test.js

    if [ $? -eq 0 ]; then
        print_success "Teste de carga concluído com sucesso!"
    else
        print_error "Teste de carga falhou"
        exit 1
    fi
}

# Função principal
main() {
    echo "🧪 Teste de Load Balancing - nginx-s6-overlay"
    echo "=============================================="

    check_k6
    check_container
    check_services
    run_load_test

    echo ""
    print_success "Todos os testes passaram! ✅"
    echo ""
    echo "📊 Resultados esperados:"
    echo "  - Load balancing distribuindo carga entre 3 instâncias Crystal"
    echo "  - Latência < 500ms para 95% das requisições"
    echo "  - Taxa de erro < 10%"
    echo "  - Cache funcionando para arquivos estáticos"
}

# Executar função principal
main "$@"
```

## Comandos de Teste

### Build e Execução
```bash
# Build da imagem
make build

# Executar container
make run

# Ver logs
make logs

# Parar container
make stop

# Executar testes simples (rápido)
make test-simple

# Executar testes de carga (completo)
make test
```

### Testes de Funcionalidade
```bash
# Testar frontend
curl http://localhost:8080/

# Testar API com load balancing
curl http://localhost:8080/api

# Testar health check
curl http://localhost:8080/api/health

# Testar load balancing (múltiplas requisições)
for i in {1..10}; do curl -s http://localhost:8080/api/health | jq -r '.instance_id'; done

# Testar arquivo estático (cache)
curl -I http://localhost:8080/logo.svg

# Testar compressão gzip
curl -H "Accept-Encoding: gzip" -I http://localhost:8080/

# Testar rate limiting
for i in {1..15}; do curl http://localhost:8080/api; done
```

### Testes Simples com Node.js
```bash
# Executar teste simples (10 segundos)
make test-simple

# Ou executar diretamente
node tests/simple-test.js
```

### Testes de Carga com k6
```bash
# Executar teste completo (2 minutos)
make test

# Ou executar diretamente
./scripts/test-load-balancing.sh

# Ou executar k6 diretamente
k6 run tests/load-test.js
```

### Verificação de Logs
```bash
# Ver logs em formato JSON
docker logs myapp_local | jq .

# Ver logs de acesso
docker logs myapp_local | grep "httpRequest"

# Ver logs de erro
docker logs myapp_local 2>&1 | grep "error"

# Ver logs específicos do Crystal
docker logs myapp_local | grep "Crystal"
```

## Comparação dos Testes

| Aspecto | Teste Simples (Node.js) | Teste de Carga (k6) |
|---------|------------------------|---------------------|
| **Duração** | < 10 segundos | 2 minutos |
| **Dependências** | Apenas Node.js 18+ | k6 + Node.js |
| **Foco** | Funcionalidade | Performance |
| **Uso** | Desenvolvimento | Validação |
| **Output** | Colorido/detalhado | Métricas/gráficos |
| **Load Balancing** | 10 requisições | 50 usuários simultâneos |
| **Verificações** | 6 endpoints + validações | 5 endpoints + thresholds |

## Próximos Passos

### Tarefa 4: Hardening de Segurança
- Secrets management
- Network policies
- Logging de auditoria
- Scanning de vulnerabilidades

### Tarefa 5: Otimização de Performance
- Connection pooling
- Cache em memória
- Worker processes
- Load balancing interno

### Tarefa 6: CI/CD e Monitoramento
- Pipeline de CI/CD
- Métricas avançadas
- Alertas automáticos
- Documentação de API

## Notas Importantes

### Logging para Containers
- **Padrão**: Logs direcionados para stdout/stderr
- **Formato**: JSON estruturado
- **Compatibilidade**: Docker, Kubernetes, GCP, Datadog
- **Performance**: Sem overhead de escrita em arquivos

### Cache de Arquivos Estáticos
- **Duração**: 1 ano (31536000 segundos)
- **Headers**: Expires + Cache-Control
- **Imutabilidade**: `immutable` para arquivos versionados
- **Logging**: Desativado para melhor performance

### Rate Limiting
- **API**: Proteção contra abuso
- **Estáticos**: Proteção contra DDoS
- **Burst**: Permite picos temporários
- **Configuração**: Por IP usando `$binary_remote_addr`

### Load Balancing
- **Algoritmo**: Round-robin
- **Instâncias**: 3 instâncias Crystal (portas 3001, 3002, 3003)
- **Health Check**: max_fails=3, fail_timeout=30s
- **Keepalive**: 32 conexões persistentes

### Fluxo de Desenvolvimento Recomendado
1. **Desenvolvimento**: Use `make test-simple` para testes rápidos
2. **Validação**: Use `make test` para testes de carga completos
3. **CI/CD**: Execute ambos os testes no pipeline

---

**Nota para LLM**: Este contexto contém todas as informações necessárias para implementar as tarefas de otimização. As Tarefas 1, 2 e 3 foram concluídas com sucesso, incluindo sistema completo de testes (simples e carga). Sempre teste incrementalmente e mantenha a compatibilidade com a arquitetura existente.
