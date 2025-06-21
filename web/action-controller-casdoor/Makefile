# Makefile para Integração Casdoor com Spider-Gazelle

.PHONY: help install run test clean

# Variáveis
APP_NAME = spider-gazelle
APP_PORT = 3000
CASDOOR_URL = http://localhost:8000
APP_URL = http://localhost:$(APP_PORT)

# Comandos principais
help: ## Mostra esta ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Instala dependências
	@echo "Instalando dependências..."
	shards install

run: ## Executa a aplicação
	@echo "Executando aplicação na porta $(APP_PORT)..."
	crystal src/app.cr

dev: ## Executa em modo desenvolvimento (com reload)
	@echo "Executando em modo desenvolvimento..."
	crystal src/app.cr --reload

dev-air: ## Executa com Air (hot reload)
	@echo "🚀 Executando com Air (hot reload)..."
	@echo "📁 Monitorando alterações em arquivos .cr, .ecr, .yml..."
	air

# Testes com curl
test: ## Executa todos os testes
	@echo "Executando testes..."
	@$(MAKE) test-home
	@$(MAKE) test-login
	@$(MAKE) test-dashboard-unauthorized
	@$(MAKE) test-profile-unauthorized
	@$(MAKE) test-logout
	@echo "✅ Todos os testes passaram!"

test-home: ## Testa página inicial
	@echo "🧪 Testando página inicial..."
	@curl -s -o /dev/null -w "Status: %{http_code}\n" $(APP_URL)/ || echo "❌ Aplicação não está rodando"

test-login: ## Testa redirecionamento para login
	@echo "🧪 Testando redirecionamento para login..."
	@curl -s -o /dev/null -w "Status: %{http_code}\n" $(APP_URL)/login || echo "❌ Aplicação não está rodando"

test-dashboard-unauthorized: ## Testa acesso não autorizado ao dashboard
	@echo "🧪 Testando acesso não autorizado ao dashboard..."
	@curl -s -o /dev/null -w "Status: %{http_code}\n" $(APP_URL)/dashboard || echo "❌ Aplicação não está rodando"

test-profile-unauthorized: ## Testa acesso não autorizado ao perfil
	@echo "🧪 Testando acesso não autorizado ao perfil..."
	@curl -s -o /dev/null -w "Status: %{http_code}\n" $(APP_URL)/profile || echo "❌ Aplicação não está rodando"

test-logout: ## Testa logout
	@echo "🧪 Testando logout..."
	@curl -s -o /dev/null -w "Status: %{http_code}\n" $(APP_URL)/logout || echo "❌ Aplicação não está rodando"

test-callback: ## Testa callback OAuth (sem parâmetros)
	@echo "🧪 Testando callback OAuth..."
	@curl -s -o /dev/null -w "Status: %{http_code}\n" $(APP_URL)/auth/callback || echo "❌ Aplicação não está rodando"

test-casdoor: ## Testa se Casdoor está rodando
	@echo "🧪 Testando conexão com Casdoor..."
	@curl -s -o /dev/null -w "Status: %{http_code}\n" $(CASDOOR_URL) || echo "❌ Casdoor não está rodando"

# Comandos de desenvolvimento
check: ## Verifica sintaxe e estilo do código
	@echo "Verificando código..."
	crystal tool format --check
	ameba

format: ## Formata o código
	@echo "Formatando código..."
	crystal tool format

# Comandos de limpeza
clean: ## Limpa arquivos temporários
	@echo "Limpa arquivos temporários..."
	rm -rf .crystal
	rm -rf lib
	rm -rf bin

clean-cache: ## Limpa cache do Crystal
	@echo "🧹 Limpando cache do Crystal..."
	rm -rf ~/.cache/crystal
	rm -rf tmp/
	rm -rf .crystal/
	@echo "✅ Cache limpo!"

# Comandos de debug
logs: ## Mostra logs da aplicação
	@echo "Logs da aplicação:"
	@tail -f logs/app.log 2>/dev/null || echo "Arquivo de log não encontrado"

status: ## Mostra status dos serviços
	@echo "📊 Status dos serviços:"
	@echo "Aplicação: $(shell curl -s -o /dev/null -w "%{http_code}" $(APP_URL) 2>/dev/null || echo "Parada")"
	@echo "Casdoor: $(shell curl -s -o /dev/null -w "%{http_code}" $(CASDOOR_URL) 2>/dev/null || echo "Parado")"

# Comandos de curl úteis
curl-home: ## Testa página inicial com curl detalhado
	@echo "🔍 Testando página inicial..."
	@curl -v $(APP_URL)/

curl-login: ## Testa redirecionamento de login
	@echo "🔍 Testando redirecionamento de login..."
	@curl -v $(APP_URL)/login

curl-dashboard: ## Testa dashboard (requer autenticação)
	@echo "🔍 Testando dashboard..."
	@curl -v $(APP_URL)/dashboard

curl-profile: ## Testa perfil (requer autenticação)
	@echo "🔍 Testando perfil..."
	@curl -v $(APP_URL)/profile

curl-logout: ## Testa logout
	@echo "🔍 Testando logout..."
	@curl -v $(APP_URL)/logout

curl-callback: ## Testa callback OAuth
	@echo "🔍 Testando callback OAuth..."
	@curl -v $(APP_URL)/auth/callback

# Comandos de setup
setup: ## Setup completo do projeto
	@echo "🚀 Setup completo do projeto..."
	@$(MAKE) install
	@$(MAKE) test-casdoor
	@echo "✅ Setup concluído!"

# Comandos de desenvolvimento rápido
dev-test: ## Executa aplicação e testes em paralelo
	@echo "🚀 Executando aplicação e testes..."
	@$(MAKE) run & sleep 3 && $(MAKE) test && kill %1

# Comandos de documentação
docs: ## Gera documentação da API
	@echo "📚 Gerando documentação..."
	crystal src/app.cr --docs > openapi.yml

routes: ## Lista todas as rotas
	@echo "🛣️ Listando rotas..."
	crystal src/app.cr --routes
