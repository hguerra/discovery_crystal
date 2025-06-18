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
