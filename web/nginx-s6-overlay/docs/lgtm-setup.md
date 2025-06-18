# LGTM Stack Setup

Este documento descreve como configurar e usar o LGTM Stack (Loki, Grafana, Tempo, Prometheus) para observabilidade da aplicação Crystal/nginx.

## Componentes

- **Loki**: Armazenamento de logs
- **Grafana**: Dashboards e visualização
- **Tempo**: Distributed tracing
- **Prometheus**: Métricas
- **Promtail**: Coletor de logs

## Configuração Rápida

### 1. Setup Inicial

```bash
# Criar diretórios e iniciar stack
bash scripts/setup-lgtm.sh
```

### 2. Acessar Grafana

- URL: http://localhost:3000
- Usuário: `admin`
- Senha: `admin`

### 3. Configurar Fontes de Dados

No Grafana, adicione as seguintes fontes de dados:

1. **Loki** (Logs)
   - URL: `http://loki:3100`
   - Access: `Server (default)`

2. **Prometheus** (Métricas)
   - URL: `http://prometheus:9090`
   - Access: `Server (default)`

3. **Tempo** (Traces)
   - URL: `http://tempo:3200`
   - Access: `Server (default)`

## Comandos Úteis

```bash
# Iniciar stack completo
bash scripts/setup-lgtm.sh

# Parar stack
  docker-compose -f docker-compose-opentelemetry.yaml down

# Ver logs
  docker-compose -f docker-compose-opentelemetry.yaml logs -f
```

## Logs e Tracing

### Logs
Os logs da aplicação são coletados automaticamente pelo Promtail e enviados para o Loki. Você pode consultá-los no Grafana usando queries como:

```
{job="myapp"}
{app="crystal-nginx"}
```

### Tracing
Para visualizar traces no Grafana:

1. Acesse Grafana
2. Vá para "Explore"
3. Selecione "Tempo" como fonte de dados
4. Use queries como:
   - `{service.name="myapp"}`
   - `{traceparent="00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"}`

### Métricas
As métricas da aplicação são expostas em `/api/metrics` e podem ser coletadas pelo Prometheus.

## Troubleshooting

### Verificar se os serviços estão rodando
```bash
docker-compose -f docker-compose-opentelemetry.yaml ps
```

### Ver logs de um serviço específico
```bash
docker-compose -f docker-compose-opentelemetry.yaml logs lgtm
docker-compose -f docker-compose-opentelemetry.yaml logs promtail
docker-compose -f docker-compose-opentelemetry.yaml logs myapp
```

### Limpar dados
```bash
# Parar stack
docker-compose -f docker-compose-opentelemetry.yaml down

# Remover volumes
docker volume rm nginx-s6-overlay_promtail-positions

# Remover diretórios
rm -rf lgtm/
```

## Estrutura de Arquivos

```
.
├── docker-compose-opentelemetry.yaml  # Stack LGTM
├── promtail-config.yaml              # Configuração Promtail
├── lgtm/                             # Volumes persistentes
│   ├── grafana/
│   ├── prometheus/
│   └── loki/
└── scripts/
    └── setup-lgtm.sh                 # Script de setup
```
