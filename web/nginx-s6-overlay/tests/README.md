# Testes de Carga - nginx-s6-overlay

Este diretório contém os testes para validar o funcionamento do load balancing entre as múltiplas instâncias Crystal.

## Arquivos

- `load-test.js` - Script principal de teste de carga usando k6
- `simple-test.js` - Teste simples usando Node.js (fetch API)
- `README.md` - Esta documentação

## Tipos de Teste

### 1. Teste Simples (Node.js)
Teste básico de conectividade e funcionamento das APIs.

**Vantagens:**
- ✅ Não requer dependências externas (apenas Node.js 18+)
- ✅ Execução rápida (< 10 segundos)
- ✅ Output colorido e informativo
- ✅ Validação de load balancing
- ✅ Verificações específicas por endpoint

**Uso:**
```bash
# Via Makefile
make test-simple

# Direto
node tests/simple-test.js
```

### 2. Teste de Carga (k6)
Teste de performance e stress com múltiplos usuários simultâneos.

**Vantagens:**
- ✅ Teste de carga realista
- ✅ Métricas detalhadas de performance
- ✅ Configuração flexível de cenários
- ✅ Integração com CI/CD

**Uso:**
```bash
# Via Makefile
make test

# Direto
./scripts/test-load-balancing.sh
```

## Pré-requisitos

### Para Teste Simples
- Node.js 18+ (para fetch API)

### Para Teste de Carga
- k6

#### Instalação do k6
```bash
# Ubuntu/Debian
sudo apt-get install k6

# macOS
brew install k6

# Docker
docker run -i grafana/k6 run -
```

### Dependências
- `curl` - Para health checks
- `jq` - Para parsing de JSON
- `docker` - Para gerenciar o container

## Execução dos Testes

### Teste Simples (Recomendado para desenvolvimento)
```bash
# Garantir que o container está rodando
make run

# Executar teste simples
make test-simple
```

### Teste de Carga (Recomendado para validação completa)
```bash
# Garantir que o container está rodando
make run

# Executar teste de carga
make test
```

## Configuração do Teste Simples

### Endpoints Testados
1. **Página inicial** (`/`) - Valida HTML e frontend
2. **API principal** (`/api`) - Testa resposta básica
3. **Health check** (`/api/health`) - Valida load balancing
4. **Métricas** (`/api/metrics`) - Valida formato Prometheus
5. **Arquivo estático** (`/logo.svg`) - Valida cache
6. **404** (`/nonexistent`) - Valida tratamento de erro

### Verificações Específicas
- ✅ **HTML válido** na página inicial
- ✅ **Health check JSON** com instance_id
- ✅ **Métricas Prometheus** no formato correto
- ✅ **Headers de cache** em arquivos estáticos
- ✅ **Load balancing** entre 3 instâncias

### Exemplo de Saída
```
🧪 Teste Simples - nginx-s6-overlay
=====================================

📋 Executando testes básicos...
  ✅ Página inicial (index.html)
     Status: 200
     Tempo: 70ms
     ✓ Contém HTML válido
  ✅ API principal
     Status: 200
     Tempo: 2ms
  ✅ Health check
     Status: 200
     Tempo: 2ms
     ✓ Health check válido (instância 3)
  ✅ Métricas Prometheus
     Status: 200
     Tempo: 6ms
     ✓ Métricas Prometheus válidas
  ✅ Arquivo estático (logo.svg)
     Status: 200
     Tempo: 2ms
     ✓ Headers de cache presentes
  ✅ Página inexistente (404)
     Status: 404
     Tempo: 2ms
     ✓ 404 retornado corretamente

🔄 Testando Load Balancing...
  ✓ Instância 1 respondendo
  ✓ Instância 2 respondendo
  ✓ Instância 3 respondendo

📊 Resultado do Load Balancing:
  Instâncias únicas detectadas: 3
  IDs das instâncias: 1, 2, 3
  ✅ Load balancing funcionando corretamente!

📊 Resumo dos Testes
====================
Testes básicos: 6/6 passaram
🎉 Todos os testes passaram! O sistema está funcionando corretamente.
```

## Configuração do Teste de Carga

### Perfil de Carga
- **Duração total**: 2 minutos
- **Rampa de subida**: 30 segundos (0 → 10 usuários)
- **Carga constante**: 1 minuto (50 usuários simultâneos)
- **Rampa de descida**: 30 segundos (50 → 0 usuários)

### Thresholds (Limites)
- **Latência**: 95% das requisições < 500ms
- **Taxa de erro**: < 10%
- **Taxa de erro customizada**: < 10%

### Endpoints Testados
1. **Health Check** (`/api/health`) - Valida load balancing
2. **API Principal** (`/api`) - Testa resposta básica
3. **Métricas** (`/api/metrics`) - Valida formato Prometheus
4. **Frontend** (`/`) - Testa arquivos estáticos
5. **Arquivo estático** (`/logo.svg`) - Valida cache

## Interpretação dos Resultados

### Load Balancing
O teste verifica se as requisições estão sendo distribuídas entre as 3 instâncias Crystal:

```bash
# Verificar distribuição manualmente
for i in {1..10}; do
  curl -s http://localhost:8080/api/health | jq -r '.instance_id'
done
```

**Resultado esperado**: Deve mostrar uma distribuição entre as instâncias 1, 2 e 3.

### Métricas Importantes
- **http_req_duration**: Latência das requisições
- **http_req_failed**: Taxa de falhas
- **http_reqs**: Total de requisições por segundo
- **iterations**: Número de iterações completadas

### Exemplo de Saída k6
```
     █ setup

     █ teardown

     checks.........................: 100.00% ✓ 1500 ✗ 0
     data_received..................: 1.2 MB  10 kB/s
     data_sent......................: 180 kB  1.5 kB/s
     http_req_duration..............: avg=45.12ms min=12.34ms med=42.56ms max=234.56ms p(95)=89.23ms
     http_req_failed...............: 0.00%   ✓ 0     ✗ 1500
     http_reqs......................: 1500    12.5/s
     iterations.....................: 1500    12.5/s
     vus............................: 1       min=1   max=50
     vus_max........................: 50      min=50  max=50
```

## Troubleshooting

### Container não está rodando
```bash
# Verificar status
docker ps | grep myapp_local

# Se não estiver rodando, iniciar
make run
```

### Node.js não encontrado ou versão antiga
```bash
# Verificar versão
node --version

# Se for menor que 18, atualizar
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# macOS
brew install node@18
```

### k6 não encontrado
```bash
# Verificar instalação
k6 version

# Se não estiver instalado, instalar
sudo apt-get install k6  # Ubuntu/Debian
# ou
brew install k6          # macOS
```

### Health check falhando
```bash
# Testar manualmente
curl http://localhost:8080/api/health

# Verificar logs do container
make logs
```

### Load balancing não funcionando
```bash
# Verificar se todas as instâncias estão rodando
docker exec myapp_local ps aux | grep my-api

# Verificar logs específicos
docker logs myapp_local | grep "Crystal server instance"
```

## Personalização

### Modificar Teste Simples
Edite o arquivo `tests/simple-test.js`:

```javascript
// Adicionar novo endpoint
const tests = [
  // ... endpoints existentes
  { path: '/api/new-endpoint', description: 'Novo endpoint', expectedStatus: 200 }
];

// Adicionar verificação específica
if (test.path === '/api/new-endpoint') {
  if (result.data.includes('expected_content')) {
    log(`     ✓ Conteúdo esperado encontrado`, 'green');
  }
}
```

### Modificar Perfil de Carga
Edite o arquivo `tests/load-test.js`:

```javascript
export const options = {
  stages: [
    { duration: '1m', target: 100 },   // Mais usuários
    { duration: '5m', target: 100 },   // Duração maior
    { duration: '1m', target: 0 },     // Rampa de descida
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],  // Latência mais restritiva
    http_req_failed: ['rate<0.05'],    // Taxa de erro mais restritiva
  },
};
```

### Adicionar Novos Endpoints
```javascript
// Adicionar novo teste
const newEndpointResponse = http.get('http://localhost:8080/api/new-endpoint');

check(newEndpointResponse, {
  'new endpoint status is 200': (r) => r.status === 200,
  'new endpoint response time < 100ms': (r) => r.timings.duration < 100,
});
```

## Integração com CI/CD

### GitHub Actions
```yaml
name: Testing
on: [push, pull_request]

jobs:
  test-simple:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Build and run container
        run: |
          make build
          make run
          sleep 10
      - name: Run simple tests
        run: make test-simple

  load-test:
    runs-on: ubuntu-latest
    needs: test-simple
    steps:
      - uses: actions/checkout@v3
      - name: Install k6
        run: sudo apt-get install k6
      - name: Run load tests
        run: make test
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    stages {
        stage('Simple Test') {
            steps {
                sh 'make build'
                sh 'make run'
                sleep 10
                sh 'make test-simple'
            }
        }
        stage('Load Test') {
            steps {
                sh 'make test'
            }
        }
    }
}
```

## Monitoramento

### Métricas em Tempo Real
```bash
# Monitorar logs durante o teste
make logs &

# Executar teste
make test-simple

# Parar monitoramento
kill %1
```

### Análise de Resultados
```bash
# Salvar resultados em arquivo
k6 run tests/load-test.js --out json=results.json

# Analisar com jq
jq '.metrics.http_req_duration.values.p95' results.json
```

## Fluxo de Desenvolvimento Recomendado

1. **Desenvolvimento**: Use `make test-simple` para testes rápidos
2. **Validação**: Use `make test` para testes de carga completos
3. **CI/CD**: Execute ambos os testes no pipeline

## Referências

- [Documentação oficial do k6](https://k6.io/docs/)
- [Fetch API MDN](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API)
- [Guia de load testing](https://k6.io/docs/testing-guides/)
- [Métricas e thresholds](https://k6.io/docs/using-k6/thresholds/)
- [Integração com CI/CD](https://k6.io/docs/testing-guides/continuous-integration/)
