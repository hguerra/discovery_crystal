#!/bin/bash

set -e

echo "🚀 Configurando LGTM Stack para observabilidade..."

# Criar diretórios necessários
mkdir -p lgtm/grafana lgtm/prometheus lgtm/loki

# Parar containers existentes
if [ -f docker-compose-opentelemetry.yaml ]; then
  docker compose -f docker-compose-opentelemetry.yaml down || true
fi

# Iniciar LGTM stack
if [ -f docker-compose-opentelemetry.yaml ]; then
  docker compose -f docker-compose-opentelemetry.yaml up -d
else
  echo "❌ docker-compose-opentelemetry.yaml não encontrado!"
  exit 1
fi

# Aguardar inicialização
sleep 15

echo "✅ LGTM Stack configurado com sucesso!"
echo ""
echo "📊 Acesse Grafana: http://localhost:3000 (admin/admin)"
echo "🔗 OTLP gRPC: localhost:4317"
echo "🔗 OTLP HTTP: localhost:4318"
echo "📝 Para ver logs: docker compose -f docker-compose-opentelemetry.yaml logs -f"
echo "🛑 Para parar: docker compose -f docker-compose-opentelemetry.yaml down"
