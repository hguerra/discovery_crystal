# Integração Casdoor com Spider-Gazelle - Implementação LLM

## Contexto
- Casdoor já está rodando em http://localhost:8000
- Projeto Spider-Gazelle precisa ser configurado
- Objetivo: Demonstrar páginas públicas e privadas com autenticação OAuth

## Estrutura Final
```
src/
  app.cr                    # Ponto de entrada
  config.cr                 # Configuração básica
  constants.cr              # Constantes do Casdoor
  controllers/
    application.cr          # Controller base com autenticação
    auth.cr              # Controller de autenticacao
  services/
    casdoor_client.cr       # Cliente básico do Casdoor
```

## Tarefas de Implementação

### Fase 1: Configuração Inicial

#### 1.1 Configurar Dependências
- [ ] Atualizar `shard.yml` com dependências:
  ```yaml
  dependencies:
    action-controller:
      github: spider-gazelle/action-controller
      version: ~> 7.0
    http: "*"
  ```

#### 1.2 Configurar Variáveis de Ambiente
- [ ] Criar arquivo `.env`:
  ```
  CASDOOR_URL=http://localhost:8000
  CASDOOR_CLIENT_ID=<obter_do_casdoor>
  CASDOOR_CLIENT_SECRET=<obter_do_casdoor>
  CASDOOR_ORGANIZATION=built-in
  ```

### Fase 2: Implementação dos Arquivos Base

#### 2.1 Constantes (`src/constants.cr`)
- [ ] Definir constantes:
  ```crystal
  CASDOOR_URL = ENV["CASDOOR_URL"]? || "http://localhost:8000"
  CASDOOR_CLIENT_ID = ENV["CASDOOR_CLIENT_ID"]? || ""
  CASDOOR_CLIENT_SECRET = ENV["CASDOOR_CLIENT_SECRET"]? || ""
  ```

#### 2.2 Configuração (`src/config.cr`)
- [ ] Configurar logging e handlers HTTP
- [ ] Configurar sessões criptografadas
- [ ] Configurar tratamento de erros

#### 2.3 Controller Base (`src/controllers/application.cr`)
- [ ] Implementar herança de `ActionController::Base`
- [ ] Método `current_user` para verificar sessão
- [ ] Filtro `require_auth` para páginas privadas
- [ ] Tratamento de erros de parâmetros

### Fase 3: Cliente Casdoor

#### 3.1 Cliente HTTP (`src/services/casdoor_client.cr`)
- [ ] Struct `OAuthToken`:
  ```crystal
  struct OAuthToken
    include JSON::Serializable
    getter access_token : String
    getter refresh_token : String?
    getter expires_in : Int32
  end
  ```

- [ ] Struct `CasdoorUser`:
  ```crystal
  struct CasdoorUser
    include JSON::Serializable
    getter name : String
    getter displayName : String
    getter email : String?
    getter avatar : String?
  end
  ```

- [ ] Classe `CasdoorClient`:
  ```crystal
  class CasdoorClient
    def exchange_code_for_token(code : String) : OAuthToken
    def get_user_info(access_token : String) : CasdoorUser
    def build_authorization_url(redirect_uri : String) : String
  end
  ```

### Fase 4: Controller de autenticacao

#### 4.1 Rotas Públicas (`src/controllers/auth.cr`)
- [ ] `GET /` - Página inicial
- [ ] `GET /login` - Redireciona para Casdoor
- [ ] `GET /logout` - Limpa sessão

#### 4.2 Rotas Privadas
- [ ] `GET /dashboard` - Dashboard (com `before_action :require_auth`)
- [ ] `GET /profile` - Perfil (com `before_action :require_auth`)

#### 4.3 Callback OAuth
- [ ] `GET /auth/callback` - Processa retorno do Casdoor:
  - Validar parâmetros `code` e `state`
  - Trocar código por token
  - Obter dados do usuário
  - Criar sessão local
  - Redirecionar para dashboard

### Fase 5: Interface HTML

#### 5.1 Templates
- [ ] Página inicial: status de autenticação + links
- [ ] Dashboard: informações do usuário + logout
- [ ] Perfil: dados detalhados do usuário

### Fase 6: Ponto de Entrada

#### 6.1 Aplicação Principal (`src/app.cr`)
- [ ] Configurar servidor HTTP na porta 3000
- [ ] Implementar graceful shutdown
- [ ] Configurar argumentos de linha de comando

## Fluxo de Autenticação

1. **Usuário acessa `/`** → Página pública com link para login
2. **Usuário clica "Login"** → Redirecionado para Casdoor
3. **Usuário faz login no Casdoor** → Redirecionado para `/auth/callback`
4. **Aplicação processa callback** → Cria sessão e redireciona para `/dashboard`
5. **Usuário acessa páginas privadas** → Autenticação verificada automaticamente
6. **Usuário clica "Logout"** → Limpa sessão e volta para `/`

## Configuração do Casdoor

### Aplicação OAuth Necessária
- **Nome**: spider-gazelle-demo
- **Redirect URLs**: http://localhost:3000/auth/callback
- **Grant Types**: authorization_code
- **Token Format**: JWT

### Endpoints Utilizados
- **Authorization**: `GET /login/oauth/authorize`
- **Token Exchange**: `POST /api/login/oauth/access_token`
- **User Info**: `GET /api/get-user`

## Critérios de Aceitação

### Funcionalidades
- [ ] Página inicial acessível sem autenticação
- [ ] Redirecionamento para Casdoor ao acessar páginas privadas
- [ ] Login bem-sucedido via OAuth
- [ ] Dashboard privado acessível após login
- [ ] Logout funcional
- [ ] Sessão persistente

### Segurança
- [ ] Sessões criptografadas
- [ ] Validação de tokens OAuth
- [ ] Proteção contra CSRF
- [ ] Headers de segurança

## Ordem de Implementação Recomendada

1. **Configurar dependências** (shard.yml)
2. **Implementar constantes** (constants.cr)
3. **Implementar configuração** (config.cr)
4. **Implementar controller base** (application.cr)
5. **Implementar cliente Casdoor** (casdoor_client.cr)
6. **Implementar controller de autenticacao** (auth.cr)
7. **Implementar templates HTML**
8. **Implementar ponto de entrada** (app.cr)
9. **Testar fluxo completo**

## Comandos de Execução

```bash
# Instalar dependências
shards install

# Executar aplicação
crystal run src/app.cr

# Acessar aplicação
open http://localhost:3000
```

## Estrutura de Arquivos para Implementação

### Arquivos a serem criados/modificados:
1. `shard.yml` - Dependências
2. `.env` - Variáveis de ambiente
3. `src/constants.cr` - Constantes
4. `src/config.cr` - Configuração
5. `src/controllers/application.cr` - Controller base
6. `src/services/casdoor_client.cr` - Cliente Casdoor
7. `src/controllers/auth.cr` - Controller de autenticacao
8. `src/app.cr` - Ponto de entrada

### Arquivos existentes (não modificar):
- `casdoor.yml` - Já configurado
- `docker-compose.yml` - Já configurado
