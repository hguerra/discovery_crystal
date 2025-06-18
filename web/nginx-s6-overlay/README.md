# nginx-s6-overlay

Um projeto POC que combina backend Crystal e frontend nginx em um único container Docker, usando s6-overlay para orquestração de múltiplos processos.

## 🏗️ Arquitetura

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

## ✨ Funcionalidades

- **Backend Crystal** com 3 instâncias para load balancing
- **Nginx** como proxy reverso com otimizações
- **s6-overlay** para orquestração de processos
- **Logging estruturado** em JSON (compatível com GCP/Stackdriver)
- **Cache agressivo** para arquivos estáticos
- **Compressão gzip** automática
- **Rate limiting** configurável
- **Headers de segurança** (CSP, X-Frame-Options, etc.)
- **Health checks** com identificação de instância
- **Métricas Prometheus** por instância
- **Testes de carga** com k6
- **Testes simples** com Node.js

## 🚀 Quick Start

### Pré-requisitos
- Docker
- Node.js 18+ (para testes simples)
- k6 (para testes de carga)

### Instalação do Node.js 18+
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# macOS
brew install node@18
```

### Instalação do k6
```bash
# Ubuntu/Debian
sudo apt-get install k6

# macOS
brew install k6

# Ou via Docker
docker run -i grafana/k6 run -
```

### Execução
```bash
# Build da imagem
make build

# Executar container
make run

# Ver logs
make logs

# Executar testes simples (rápido)
make test-simple

# Executar testes de carga (completo)
make test

# Parar container
make stop
```

## 🧪 Testes

### Testes Simples (Recomendado para desenvolvimento)
```bash
# Executar teste simples (10 segundos)
make test-simple

# Ou executar diretamente
node tests/simple-test.js
```

**Vantagens:**
- ✅ Execução rápida (< 10 segundos)
- ✅ Não requer dependências externas
- ✅ Output colorido e informativo
- ✅ Validação de load balancing
- ✅ Verificações específicas por endpoint

### Testes de Carga (Recomendado para validação completa)
```bash
# Executar teste completo (2 minutos)
make test

# Ou executar diretamente
./scripts/test-load-balancing.sh
```

**Vantagens:**
- ✅ Teste de carga realista
- ✅ Métricas detalhadas de performance
- ✅ Configuração flexível de cenários
- ✅ Integração com CI/CD

### Testes de Funcionalidade
```bash
# Testar frontend
curl http://localhost:8080/

# Testar API com load balancing
curl http://localhost:8080/api

# Testar health check
curl http://localhost:8080/api/health

# Verificar load balancing
for i in {1..10}; do curl -s http://localhost:8080/api/health | jq -r '.instance_id'; done
```

O teste simples valida:
- ✅ Load balancing entre 3 instâncias Crystal
- ✅ Todos os endpoints respondendo corretamente
- ✅ Headers de cache em arquivos estáticos
- ✅ Tratamento de erros (404)
- ✅ Formato JSON válido nos health checks

O teste de carga valida:
- ✅ Load balancing entre 3 instâncias Crystal
- ✅ Latência < 500ms para 95% das requisições
- ✅ Taxa de erro < 10%
- ✅ Cache de arquivos estáticos
- ✅ Compressão gzip

## 📁 Estrutura do Projeto

```
nginx-s6-overlay/
├── Dockerfile                    # Multi-stage build
├── Makefile                      # Comandos de automação
├── docs/
│   ├── nginx-otimizacoes.md      # Otimizações nginx
│   └── s6-overlay-guia.md        # Guia s6-overlay
├── src/
│   └── app.cr                    # Backend Crystal
├── rootfs/
│   └── etc/
│       ├── nginx/                # Configurações nginx
│       └── services.d/           # Serviços s6-overlay
│           ├── crystal-api-1/    # Instância 1 (porta 3001)
│           ├── crystal-api-2/    # Instância 2 (porta 3002)
│           ├── crystal-api-3/    # Instância 3 (porta 3003)
│           └── nginx/            # Serviço nginx
├── tests/
│   ├── load-test.js              # Teste de carga k6
│   ├── simple-test.js            # Teste simples Node.js
│   └── README.md                 # Documentação dos testes
├── scripts/
│   └── test-load-balancing.sh    # Script de teste
└── www/                          # Arquivos estáticos
    ├── index.html
    └── logo.svg
```

## 🔧 Configuração

### Variáveis de Ambiente
- `PORT` - Porta do Crystal (padrão: 3000)
- `INSTANCE_ID` - ID da instância (1, 2, 3)
- `ENVIRONMENT` - Ambiente (development, production)
- `LOG_LEVEL` - Nível de log (debug, info, warn, error, fatal)

### Endpoints
- `/` - Frontend (arquivos estáticos)
- `/api` - API principal
- `/api/health` - Health check com identificação de instância
- `/api/metrics` - Métricas Prometheus

## 📊 Monitoramento

### Logs
```bash
# Ver logs em formato JSON
docker logs myapp_local | jq .

# Ver logs específicos do Crystal
docker logs myapp_local | grep "Crystal"

# Ver logs de acesso nginx
docker logs myapp_local | grep "httpRequest"
```

### Métricas
```bash
# Métricas da instância 1
curl http://localhost:8080/api/health | jq .

# Métricas Prometheus
curl http://localhost:8080/api/metrics
```

## 🛡️ Segurança

- **Usuário não-root** (`appuser`)
- **Headers de segurança** configurados
- **Rate limiting** por IP
- **Content Security Policy** ativo
- **Logs sem dados sensíveis**

## 🚀 Otimizações

- **Cache de 1 ano** para arquivos estáticos
- **Compressão gzip** automática
- **Keepalive connections** (32 conexões)
- **Load balancing** round-robin
- **Health checks** automáticos

## 📚 Documentação

- [Guia s6-overlay](docs/s6-overlay-guia.md) - Documentação completa sobre s6-overlay
- [Otimizações nginx](docs/nginx-otimizacoes.md) - Detalhes das otimizações
- [Testes](tests/README.md) - Documentação completa dos testes

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🙏 Agradecimentos

- [s6-overlay](https://github.com/just-containers/s6-overlay) - Orquestração de processos
- [Crystal](https://crystal-lang.org/) - Linguagem de programação
- [k6](https://k6.io/) - Ferramenta de testes de carga
- [Nginx](https://nginx.org/) - Servidor web e proxy reverso
