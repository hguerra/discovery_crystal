# Spider-Gazelle: Guia Completo, Padrões de Produção e Exemplos Reais

## 1. Introdução

Spider-Gazelle é um framework web moderno, de alta performance, para Crystal, inspirado em padrões MVC e focado em segurança de tipos, produtividade do desenvolvedor, extensibilidade e escalabilidade. Ele aproveita a velocidade do Crystal e seu sistema de tipos, fornecendo uma base robusta para APIs e aplicações web de missão crítica.

- **Extremamente rápido**: aproveita o Crystal nativo
- **Segurança de tipos**: conversão automática de parâmetros e validação
- **Produtividade**: DSL intuitivo, anotações, geração automática de OpenAPI
- **Extensível**: macros, filtros, middlewares, integração fácil com Redis, PostgreSQL, Elasticsearch, JWT, etc.
- **Pronto para produção**: clustering, graceful shutdown, logging estruturado, health checks, rate limiting, versionamento

---

## 2. Instalação

Adicione ao seu `shard.yml`:

```yaml
dependencies:
  action-controller:
    github: spider-gazelle/action-controller
    version: ">= 7.0"
```

Instale as dependências:

```bash
shards install
```

---

## 3. Estrutura de Projeto

Um projeto típico Spider-Gazelle segue a estrutura:

```
src/
  app.cr            # Ponto de entrada
  config.cr         # Configuração da aplicação
  constants.cr      # Constantes globais
  controllers/
    application.cr  # Controller base abstrato
    welcome.cr      # Controller de exemplo
  models/           # Modelos de dados
  services/         # Serviços externos (ex: OAuth, Redis, etc)
  views/            # Templates ECR
```

---

## 4. Conceitos Fundamentais

- **Controllers**: Herdam de `ActionController::Base` ou de um controller base customizado.
- **Rotas**: Definidas por anotações (`@[AC::Route::GET(...)]`) ou DSL macro.
- **Parâmetros Fortes**: Conversão automática de tipos, validação e documentação.
- **Filtros**: before_action, after_action, around_action, skip_action, force_ssl.
- **Middlewares**: Handlers customizados antes/depois da aplicação.
- **Sessões e Cookies**: Cookies assinados e criptografados.
- **WebSockets**: Suporte nativo e fácil.
- **OpenAPI**: Geração automática de documentação.
- **Clustering**: Multi-processos para alta performance.
- **Rate Limiting**: Limite de requisições concorrentes por usuário.
- **Health Checks**: Endpoints e lógica de verificação de saúde.
- **Integração com Redis, PostgreSQL, Elasticsearch, JWT, etc.**

---

## 5. Exemplos de Uso

(Os próximos tópicos detalharão exemplos reais, padrões de produção, e recursos avançados do framework, baseados em projetos PlaceOS REST API e Staff API.)

---

## 6. Recursos Avançados e Padrões de Produção

### 6.1. Health Checks (Verificação de Saúde)

```crystal
@[AC::Route::GET("/")]
def root : Nil
  raise "not healthy" unless self.class.healthcheck?
end

def self.healthcheck? : Bool
  Promise.all(
    Promise.defer { check_resource?("redis") { RedisStorage.with_redis &.ping } },
    Promise.defer { check_resource?("postgres") { pg_healthcheck } }
  ).then(&.all?).get
end
```

### 6.2. Rate Limiting (Limite de Requisições)

```crystal
QUEUE_LIMIT = ENV["QUEUE_LIMIT"]?.try &.to_i
USER_LOCK = Hash(String, Mutex).new { |lock, user| lock[user] = Mutex.new }
USER_COUNT = Hash(String, Int32).new { |count, user| count[user] = 0 }
COUNT_LOCK = Mutex.new

def request_queue(&) : Nil
  limit = QUEUE_LIMIT
  return yield unless limit
  user_id = user_token.id
  lock = COUNT_LOCK.synchronize do
    count = USER_COUNT[user_id]
    raise Error::TooManyRequests.new if count >= limit
    USER_COUNT[user_id] = count + 1
    USER_LOCK[user_id]
  end
  begin
    lock.synchronize { yield }
  ensure
    COUNT_LOCK.synchronize do
      count = USER_COUNT[user_id] - 1
      if count.zero?
        USER_COUNT.delete user_id
        USER_LOCK.delete user_id
      else
        USER_COUNT[user_id] = count
      end
    end
  end
end
```

### 6.3. Clustering (Multi-processos)

```crystal
server = ActionController::Server.new(port, host)
server.cluster(process_count, "-w", "--workers") if process_count != 1
```

### 6.4. Logging Estruturado

```crystal
@[AC::Route::Filter(:before_action)]
def set_request_id
  request_id = UUID.random.to_s
  Log.context.set(client_ip: client_ip, request_id: request_id)
  response.headers["X-Request-ID"] = request_id
end
```

### 6.5. Integração com Redis, PostgreSQL, Elasticsearch, JWT

- **Redis**: `RedisStorage.with_redis &.publish(channel, payload)`
- **PostgreSQL**: `PgORM::Database.parse(pg_url)`
- **Elasticsearch**: `elastic.search(query)`
- **JWT**: `JWT.decode(token, JWT_SECRET, JWT::Algorithm::HS256)`

### 6.6. Autenticação, Escopos e Permissões

```crystal
before_action :check_jwt_scope

def check_jwt_scope
  access = user_token.get_access("public")
  block_access = request.method.downcase == "get" ? access.none? : !access.write?
  raise Error::Forbidden.new if block_access
end
```

### 6.7. Versionamento e OpenAPI

```crystal
@[AC::Route::GET("/version")]
def version : Version
  Version.new(service: NAME, commit: BUILD_COMMIT, version: VERSION, build_time: BUILD_TIME)
end

@[AC::Route::GET("/openapi")]
def openapi : YAML::Any
  ActionController::OpenAPI.generate_open_api_docs(title: NAME, version: VERSION).to_yaml
end
```

### 6.8. Middlewares Customizados

```crystal
ActionController::Server.before(
  ActionController::ErrorHandler.new(App.running_in_production?, ["X-Request-ID"]),
  ActionController::LogHandler.new(["password", "bearer_token"]),
  HTTP::CompressHandler.new
)
```

### 6.9. Testes e Boas Práticas

- Use `action-controller/spec_helper` e HotTopic para testes de integração
- Separe controllers por domínio
- Use handlers de erro padronizados
- Documente parâmetros com `@[AC::Param::Info]`
- Use paginadores e headers HTTP para grandes volumes

### 6.10. Tabela de Recursos e Anotações

| Recurso                | Anotação/DSL                      | Exemplo                                      |
|------------------------|------------------------------------|----------------------------------------------|
| Rota GET               | @[AC::Route::GET("/path")]        | def index; ...; end                          |
| Rota POST              | @[AC::Route::POST("/path")]       | def create(obj : Obj); ...; end              |
| Parâmetro forte        | Argumento tipado                   | def show(id : Int32)                         |
| Filtro before/after    | @[AC::Route::Filter(:before_action)]| def auth; ...; end                           |
| Exceção customizada    | @[AC::Route::Exception(...)]       | def not_found(error); ...; end               |
| WebSocket              | @[AC::Route::WebSocket("/ws")]    | def ws(socket); ...; end                     |
| Conversor customizado  | struct ConvertX; def convert ...   | converters: {id: ConvertX}                   |
| Documentação param     | @[AC::Param::Info(...)]            | def show(@[AC::Param::Info(...)] id : Int32) |
| Macro DSL              | get "/path", :name do ... end      |                                            |

### 6.11. Dicas de Produção

- Sempre use logging estruturado e request IDs
- Configure clustering para alta disponibilidade
- Use health checks para monitoramento
- Proteja endpoints críticos com rate limiting
- Documente todas as rotas e parâmetros
- Use handlers de erro para respostas padronizadas
- Separe controllers por domínio de negócio
- Use variáveis de ambiente para segredos e configuração
- Gere e sirva OpenAPI para integração com frontends e clientes

---

## 7. ECR Templates and View Rendering

Spider-Gazelle uses ECR (Embedded Crystal) for template rendering, which allows you to embed Crystal code directly into HTML and other text formats. ECR templates are compiled at build time and embedded into the binary for maximum performance.

### 7.1. Basic ECR Syntax

ECR uses two main syntax patterns:
- `<%= %>` - Renders the returned value
- `<% %>` - Executes Crystal code without rendering output

```crystal
# views/welcome.ecr
<h1>Welcome, <%= @name %>!</h1>
<p>Current time: <%= Time.utc %></p>

<% if @user %>
  <p>Hello, <%= @user.name %>!</p>
<% else %>
  <p>Please <a href="/login">login</a></p>
<% end %>
```

### 7.2. ECR Template Structure

Create templates in the `src/views/` directory:

```
src/views/
├── layout_main.ecr      # Main layout template
├── welcome/
│   ├── index.ecr        # Welcome page
│   └── show.ecr         # User details
├── users/
│   ├── index.ecr        # User list
│   ├── show.ecr         # User details
│   └── _form.ecr        # Partial form
└── shared/
    ├── _header.ecr      # Header partial
    └── _footer.ecr      # Footer partial
```

### 7.3. Controller Integration

```crystal
class WelcomeController < Application
  base "/"

  @[AC::Route::GET("/")]
  def index
    @name = "Spider-Gazelle"
    @user = current_user
    render template: "welcome/index.ecr"
  end

  @[AC::Route::GET("/users/:id")]
  def show(id : Int32)
    @user = User.find!(id)
    render template: "users/show.ecr"
  end
end
```

### 7.4. Layouts and Partials

#### Main Layout (`src/views/layout_main.ecr`)

```crystal
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= @page_title || "Spider-Gazelle App" %></title>
  <link rel="stylesheet" href="/css/app.css">
</head>
<body>
  <header>
    <%- render "shared/_header.ecr" %>
  </header>

  <main>
    <%- content %>
  </main>

  <footer>
    <%- render "shared/_footer.ecr" %>
  </footer>

  <script src="/js/app.js"></script>
</body>
</html>
```

#### Page Template (`src/views/welcome/index.ecr`)

```crystal
<div class="welcome-container">
  <h1>Welcome to <%= @name %></h1>

  <%- if @user %>
    <div class="user-info">
      <p>Hello, <%= @user.name %>!</p>
      <p>Email: <%= @user.email %></p>
      <a href="/logout" class="btn btn-danger">Logout</a>
    </div>
  <%- else %>
    <div class="login-prompt">
      <p>Please login to continue</p>
      <a href="/login" class="btn btn-primary">Login</a>
    </div>
  <%- end %>

  <div class="features">
    <h2>Features</h2>
    <ul>
      <%- @features.each do |feature| %>
        <li><%= feature.name %>: <%= feature.description %></li>
      <%- end %>
    </ul>
  </div>
</div>
```

### 7.5. ECR Syntax Details

#### Conditionals with Proper Indentation

```crystal
<%# Note the dash (-) to control indentation %>
<%- if @user %>
  <div class="user-panel">
    <p>Welcome back, <%= @user.name %>!</p>
  </div>
<%- else %>
  <div class="guest-panel">
    <p>Please login to continue</p>
  </div>
<%- end %>
```

#### Loops and Iterations

```crystal
<%- @users.each do |user| %>
  <div class="user-card">
    <h3><%= user.name %></h3>
    <p><%= user.email %></p>
    <%- if user.admin? %>
      <span class="badge badge-admin">Admin</span>
    <%- end %>
  </div>
<%- end %>
```

#### Partials and Includes

```crystal
<%# Include a partial %>
<%- render "users/_form.ecr" %>

<%# Pass variables to partial %>
<%- render "shared/_alert.ecr", message: @message, type: @alert_type %>
```

#### Partial Template (`src/views/users/_form.ecr`)

```crystal
<form action="/users" method="POST" class="user-form">
  <div class="form-group">
    <label for="name">Name:</label>
    <input type="text" id="name" name="name" value="<%= @user.try(&.name) || "" %>" required>
  </div>

  <div class="form-group">
    <label for="email">Email:</label>
    <input type="email" id="email" name="email" value="<%= @user.try(&.email) || "" %>" required>
  </div>

  <%- if @user %>
    <button type="submit" class="btn btn-primary">Update User</button>
  <%- else %>
    <button type="submit" class="btn btn-success">Create User</button>
  <%- end %>
</form>
```

### 7.6. Advanced ECR Features

#### Comments and Escaping

```crystal
<%# This is a comment - not rendered %>
<%#= This would be a commented out expression %>

<%# To escape ECR tags, use double % %>
<%%= This will render as: <%= %> %>

<%# Control whitespace with dashes %>
<%- # Removes previous indentation %>
<% -%> <%# Removes next newline %>
```

#### Helper Methods in Controllers

```crystal
class Application < ActionController::Base
  # Helper methods available in templates
  def format_date(time : Time)
    time.to_s("%Y-%m-%d %H:%M")
  end

  def user_avatar_url(user : User)
    user.avatar_url || "/images/default-avatar.png"
  end

  def csrf_token
    session["csrf_token"]? || generate_csrf_token
  end

  private def generate_csrf_token
    token = Random::Secure.hex(32)
    session["csrf_token"] = token
    token
  end
end
```

#### Using Helpers in Templates

```crystal
<div class="user-profile">
  <img src="<%= user_avatar_url(@user) %>" alt="<%= @user.name %>">
  <h2><%= @user.name %></h2>
  <p>Member since: <%= format_date(@user.created_at) %></p>
</div>

<form action="/users" method="POST">
  <input type="hidden" name="_csrf" value="<%= csrf_token %>">
  <!-- form fields -->
</form>
```

### 7.7. Template Configuration

#### Controller Base Configuration

```crystal
abstract class Application < ActionController::Base
  # Set template path
  template_path "./src/views/"

  # Set default layout
  layout "layout_main.ecr"

  # Or disable layout for specific controllers
  # layout nil
end
```

#### Custom Template Paths

```crystal
class AdminController < Application
  # Override template path for admin views
  template_path "./src/views/admin/"

  # Override layout for admin
  layout "admin_layout.ecr"
end
```

### 7.8. JSON and API Responses

For API endpoints, you can still use ECR for JSON templates:

```crystal
# views/api/users/index.json.ecr
{
  "users": [
    <%- @users.each_with_index do |user, index| %>
      {
        "id": <%= user.id %>,
        "name": "<%= user.name %>",
        "email": "<%= user.email %>"
      }<%= "," unless index == @users.size - 1 %>
    <%- end %>
  ],
  "total": <%= @users.size %>,
  "page": <%= @page %>
}
```

### 7.9. Error Pages

Create custom error pages:

```crystal
# views/errors/404.ecr
<div class="error-page">
  <h1>404 - Page Not Found</h1>
  <p>The page you're looking for doesn't exist.</p>
  <a href="/" class="btn btn-primary">Go Home</a>
</div>

# views/errors/500.ecr
<div class="error-page">
  <h1>500 - Internal Server Error</h1>
  <p>Something went wrong. Please try again later.</p>
  <%- if App.development? %>
    <pre><%= @error.try(&.message) %></pre>
  <%- end %>
</div>
```

### 7.10. Best Practices

1. **Use instance variables** (`@variable`) for data passed from controllers
2. **Use dashes** (`<%- %>`) to control indentation and whitespace
3. **Keep templates simple** - move complex logic to controller helper methods
4. **Use partials** for reusable components
5. **Escape user input** to prevent XSS attacks
6. **Use layouts** for consistent page structure
7. **Organize templates** in subdirectories by feature

---

## 8. Routing and Controllers

### 8.1. Defining a Controller

Controllers inherit from `ActionController::Base` (or your own abstract base). Use annotations to define routes:

```crystal
class WelcomeController < AC::Base
  base "/"

  @[AC::Route::GET("/")]
  def index
    "Hello World"
  end
end
```

### 8.2. Route Parameters and Query Parameters

Parameters are automatically type-cast and injected as method arguments:

```crystal
@[AC::Route::GET("/:id")]
def show(id : Int32)
  "User ID: #{id}"
end

@[AC::Route::GET("/search")]
def search(query : String = "default")
  "Query: #{query}"
end
```

### 8.3. Request Body Parsing

Spider-Gazelle can automatically parse JSON bodies into structs:

```crystal
struct User
  include JSON::Serializable
  getter id : Int32
  getter name : String
end

@[AC::Route::POST("/users", body: :user)]
def create(user : User)
  "Created user: #{user.name}"
end
```

---

## 9. Response Handling

### 9.1. Return Types

Return values are automatically serialized based on the `Accept` header (JSON by default):

```crystal
@[AC::Route::GET("/users/:id")]
def show(id : Int32) : User
  User.new(id: id, name: "Alice")
end
```

### 9.2. Custom Headers and Status Codes

Set headers and status codes in your action:

```crystal
@[AC::Route::GET("/download")]
def download
  response.headers["Content-Disposition"] = "attachment; filename=\"file.txt\""
  response.status_code = 200
  response.write "File content"
end
```

Or via annotation:

```crystal
@[AC::Route::GET("/", status_code: HTTP::Status::CREATED)]
def created
  "Resource created"
end
```

---

## 10. Filters and Middleware

### 10.1. Before, After, and Around Filters

Filters are methods that run before, after, or around actions:

```crystal
abstract class Application < AC::Base
  before_action :authenticate

  def authenticate
    render :unauthorized unless session["user_id"]?
  end
end
```

You can skip or limit filters per action:

```crystal
skip_action :authenticate, only: :public_action
```

---

Define custom error handlers using annotations:

```crystal
@[AC::Route::Exception(Error::NotFound, status_code:
HTTP::Status::NOT_FOUND)]
def not_found(error)
  {error: error.message}
end

## 11. Sessions and Cookies

Sessions are encrypted and signed cookies:

```crystal
def current_user
  @current_user ||= session["user_id"]? && User.find(session["user_id"])
end

@[AC::Route::POST("/login")]
def login(username : String, password : String)
  if user = User.authenticate(username, password)
    session["user_id"] = user.id
  end
end
```

Cookies are accessed similarly:

```crystal
cookies["theme"] = "dark"
```

---

## 12. Static Files

Serve static files by enabling the handler in your config:

```crystal
if File.directory?(STATIC_FILE_PATH)
  ActionController::Server.before(
    ::HTTP::StaticFileHandler.new(STATIC_FILE_PATH, directory_listing: false)
  )
end
```

---

## 13. WebSockets

Define WebSocket endpoints with annotations:

```crystal
@[AC::Route::WebSocket("/ws/:room")]
def websocket(socket, room : String)
  socket.on_message do |msg|
    socket.send("Echo: #{msg}")
  end
end
```

---

## 14. OpenAPI Documentation

Generate OpenAPI docs automatically:

```crystal
ActionController::OpenAPI.generate_open_api_docs(
  title: "My API",
  version: "1.0.0",
  description: "API docs"
).to_yaml
```

Serve it as an endpoint:

```crystal
@[AC::Route::GET("/openapi")]
def openapi
  File.read("openapi.yml")
end
```

---

## 15. Testing

Use `action-controller/spec_helper` and HotTopic for integration tests:

```crystal
require "spec"
require "action-controller/spec_helper"
require "../src/config"

describe WelcomeController do
  client = AC::SpecHelper.client

  it "returns welcome message" do
    result = client.get("/")
    result.body.should eq %("Hello World")
  end
end
```

---

## 16. Real-World Example: Staff API

```crystal
class Staff < Application
  base "/api/staff/v1/people"

  @[AC::Route::GET("/")]
  def index(query : String? = nil) : Array(User)
    # Fetch users from DB or external API
  end

  @[AC::Route::GET("/:id")]
  def show(id : String) : User
    # Fetch user by ID
  end
end
```

---

## 17. Advanced Features

- **Custom Parameter Converters:** Implement `def convert(raw : String)` in a struct and use in route annotation.
- **Custom Parsers/Responders:** Use `add_parser` and `add_responder` in your base controller.
- **Clustering:** Use `server.cluster(process_count)` for multi-process support.
- **Graceful Shutdown:** Signal handling is built-in.

---

## 18. Deployment

Use Docker for deployment. Example Dockerfile and docker-compose are available in real projects. Example:

```dockerfile
FROM crystallang/crystal:latest as builder
WORKDIR /app
COPY . .
RUN shards install --production
RUN crystal build --release src/app.cr -o /app/bin/app

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/bin/app /app/app
CMD ["/app/app"]
```

---

## 19. Observability

- **Logging:** Structured, context-aware logging.
- **Tracing:** Request IDs propagated via headers.
- **Health Checks:** Implemented as endpoints.

---

## 20. Application Configuration

### 20.1. Base Application Controller

```crystal
require "uuid"
require "yaml"

abstract class Application < ActionController::Base
  # Configure your log source name
  Log = ::Log.for("controller")

  # Add custom responders
  add_responder("application/yaml") { |io, result| result.to_yaml(io) }
  add_responder("text/html") { |io, result| result.to_json(io) }

  # Request ID for tracing
  @[AC::Route::Filter(:before_action)]
  def set_request_id
    request_id = UUID.random.to_s
    Log.context.set(
      client_ip: client_ip,
      request_id: request_id
    )
    response.headers["X-Request-ID"] = request_id
  end

  # Set date header
  @[AC::Route::Filter(:before_action)]
  def set_date_header
    response.headers["Date"] = HTTP.format_time(Time.utc)
  end

  # Error handlers
  @[AC::Route::Exception(AC::Route::NotAcceptable, status_code: HTTP::Status::NOT_ACCEPTABLE)]
  @[AC::Route::Exception(AC::Route::UnsupportedMediaType, status_code: HTTP::Status::UNSUPPORTED_MEDIA_TYPE)]
  def bad_media_type(error) : AC::Error::ContentResponse
    AC::Error::ContentResponse.new error: error.message.as(String), accepts: error.accepts
  end

  @[AC::Route::Exception(AC::Route::Param::MissingError, status_code: HTTP::Status::UNPROCESSABLE_ENTITY)]
  @[AC::Route::Exception(AC::Route::Param::ValueError, status_code: HTTP::Status::BAD_REQUEST)]
  def invalid_param(error) : AC::Error::ParameterResponse
    AC::Error::ParameterResponse.new error: error.message.as(String), parameter: error.parameter, restriction: error.restriction
  end
end
```

### 20.2. Application Entry Point

```crystal
require "option_parser"
require "./constants"

module App
  # Server defaults
  port = DEFAULT_PORT
  host = DEFAULT_HOST
  process_count = DEFAULT_PROCESS_COUNT

  # Command line options
  OptionParser.parse(ARGV.dup) do |parser|
    parser.banner = "Usage: #{PROGRAM_NAME} [arguments]"

    parser.on("-b HOST", "--bind=HOST", "Specifies the server host") { |bind_host| host = bind_host }
    parser.on("-p PORT", "--port=PORT", "Specifies the server port") { |bind_port| port = bind_port.to_i }
    parser.on("-w COUNT", "--workers=COUNT", "Specifies the number of processes") { |workers| process_count = workers.to_i }
    parser.on("-r", "--routes", "List the application routes") do
      ActionController::Server.print_routes
      exit 0
    end
    parser.on("-v", "--version", "Display the application version") do
      puts "#{NAME} v#{VERSION}"
      exit 0
    end
    parser.on("-d", "--docs", "Outputs OpenAPI documentation") do
      puts ActionController::OpenAPI.generate_open_api_docs(
        title: NAME,
        version: VERSION,
        description: "API documentation"
      ).to_yaml
      exit 0
    end
  end

  # Load configuration
  require "./config"

  # Create server
  server = ActionController::Server.new(port, host)
  server.cluster(process_count, "-w", "--workers") if process_count != 1

  # Graceful shutdown
  Process.on_terminate do
    puts "\n > terminating gracefully"
    server.close
  end

  # Start server
  server.run do
    puts "Listening on #{server.print_addresses}"
  end
end
```

---

## 21. Advanced Routing Features

### 21.1. Optional and Wildcard Parameters

```crystal
# Optional parameter
@[AC::Route::GET("/users/?:id/posts")]
def user_posts(id : Int32? = nil)
  if id
    "Posts for user #{id}"
  else
    "All posts"
  end
end

# Wildcard parameter
@[AC::Route::GET("/files/*:path")]
def serve_file(path : String)
  "Serving file: #{path}"
end
```

### 21.2. Custom Parameter Converters

```crystal
# Convert comma-separated strings to arrays
struct ConvertStringArray
  def convert(raw : String)
    raw.split(',').map!(&.strip).reject(&.empty?).uniq!
  end
end

@[AC::Route::GET("/search", converters: {fields: ConvertStringArray})]
def search(fields : Array(String))
  "Searching in fields: #{fields.join(", ")}"
end
```

### 21.3. Multiple Routes per Action

```crystal
@[AC::Route::GET("/users/:id/groups")]
@[AC::Route::GET("/users/groups")]
def groups(user_id : Int32? = nil)
  if user_id
    "Groups for user #{user_id}"
  else
    "All groups"
  end
end
```

---

## 22. Real-World Examples from Production

### 22.1. REST API Controller (from PlaceOS)

```crystal
class Root < Application
  base "/api/engine/v2/"

  before_action :check_admin, except: [:root, :version, :health]

  # Health check endpoint
  @[AC::Route::GET("/")]
  def root : Nil
    raise "not healthy" unless self.class.healthcheck?
  end

  def self.healthcheck? : Bool
    Promise.all(
      Promise.defer {
        check_resource?("redis") { ::PlaceOS::Driver::RedisStorage.with_redis &.ping }
      },
      Promise.defer {
        check_resource?("postgres") { pg_healthcheck }
      },
    ).then(&.all?).get
  end

  # Version endpoint
  @[AC::Route::GET("/version")]
  def version : ::PlaceOS::Model::Version
    Root.version
  end

  # Signal endpoint for Redis pub/sub
  @[AC::Route::POST("/signal")]
  def signal(channel : String) : Nil
    payload = request.body.try(&.gets_to_end) || ""
    Log.info { "signalling #{channel} with #{payload.bytesize} bytes" }
    ::PlaceOS::Driver::RedisStorage.with_redis &.publish(channel, payload)
  end

  private def self.check_resource?(resource, &)
    Log.trace { "healthchecking #{resource}" }
    !!yield
  rescue e
    Log.error(exception: e) { {"connection check to #{resource} failed"} }
    false
  end
end
```

### 22.2. Staff API Controller (from Staff-API)

```crystal
class Staff < Application
  base "/api/staff/v1/people"

  # List users with advanced filtering
  @[AC::Route::GET("/")]
  def index(
    @[AC::Param::Info(name: "q", description: "Search query")]
    query : String? = nil,
    @[AC::Param::Info(name: "filter", description: "Advanced filter")]
    filter : String? = nil,
    @[AC::Param::Info(description: "Next page token")]
    next_page : String? = nil,
  ) : Array(PlaceCalendar::User)
    users = if filter
              client.list_users(filter: filter, next_link: next_page)
            else
              client.list_users(query, next_link: next_page)
            end

    # Pagination headers
    if next_link = users.first?.try(&.next_link)
      params = URI::Params.build do |form|
        form.add("q", query.as(String).strip) if query.presence
        form.add("filter", filter) if filter
        form.add("next_page", next_link)
      end
      response.headers["Link"] = %(</api/staff/v1/people?#{params}>; rel="next")
    end

    users
  end

  # Get user by ID or email
  @[AC::Route::GET("/:id")]
  def show(
    @[AC::Param::Info(description: "User ID or email")]
    id : String,
  ) : PlaceCalendar::User
    if id.includes?('@')
      user = client.get_user_by_email(id)
    else
      user = client.get_user(id)
    end
    raise Error::NotFound.new("user #{id} not found") unless user
    user
  end

  # Stream user photo
  @[AC::Route::GET("/:id/photo")]
  def photo(id : String) : Nil
    if client.client_id == :office365
      token = get_placeos_client.users.resource_token
      HTTP::Client.get("https://graph.microsoft.com/v1.0/users/#{id}/photo/$value",
        headers: HTTP::Headers{"Authorization" => "Bearer #{token.token}"}) do |upstream_response|
        stream(upstream_response)
      end
    else
      user = client.get_user_by_email(id)
      raise Error::NotFound.new("user #{id} not found") unless user
      photo = user.photo
      raise Error::NotFound.new("user #{id} doesn't have a photo") unless photo

      HTTP::Client.get(photo) do |upstream_response|
        stream(upstream_response)
      end
    end
  end

  private def stream(upstream_response)
    @__render_called__ = true
    response.status_code = upstream_response.status_code

    upstream_response.headers.each do |key, value|
      response.headers[key] = value unless key.downcase == "transfer-encoding"
    end

    if body_io = upstream_response.body_io?
      IO.copy(body_io, response)
    else
      response.print upstream_response.body
    end
  end
end
```

---

## 23. Pagination and Search

### 23.1. Elasticsearch Integration

```crystal
def paginate_results(elastic, query, route = base_route)
  data = elastic.search(query)
  range_start = query.offset
  range_end = data[:results].size + range_start
  total_items = data[:total]
  item_type = elastic.elastic_index

  response.headers["X-Total-Count"] = total_items.to_s
  response.headers["Content-Range"] = "#{item_type} #{range_start}-#{range_end}/#{total_items}"

  if range_end < total_items
    query_params["offset"] = (range_end + 1).to_s
    query_params["limit"] = query.limit.to_s
    if ref = data[:ref]
      query_params["ref"] = ref
    end
    response.headers["Link"] = %(<#{route}?#{query_params}>; rel="next")
  end

  data[:results]
end
```

---

## 24. Request Queuing and Rate Limiting

```crystal
abstract class Application < ActionController::Base
  QUEUE_LIMIT = ENV["QUEUE_LIMIT"]?.try &.to_i
  USER_LOCK = Hash(String, Mutex).new { |lock, user| lock[user] = Mutex.new }
  USER_COUNT = Hash(String, Int32).new { |count, user| count[user] = 0 }
  COUNT_LOCK = Mutex.new

  macro add_request_queue
    def request_queue(&) : Nil
      limit = QUEUE_LIMIT
      return yield unless limit

      user_id = user_token.id

      lock = COUNT_LOCK.synchronize do
        count = USER_COUNT[user_id]
        raise Error::TooManyRequests.new("user #{user_id} has over #{limit} requests") if count >= limit
        USER_COUNT[user_id] = count + 1
        USER_LOCK[user_id]
      end

      begin
        lock.synchronize { yield }
      ensure
        COUNT_LOCK.synchronize do
          count = USER_COUNT[user_id] - 1
          if count.zero?
            USER_COUNT.delete user_id
            USER_LOCK.delete user_id
          else
            USER_COUNT[user_id] = count
          end
        end
      end
    end
  end
end
```

---

## 25. Configuration and Environment

### 25.1. Constants File

```crystal
module App
  NAME = "spider-gazelle"
  VERSION = "2.0.0"
  PROGRAM_NAME = "app"

  DEFAULT_HOST = "127.0.0.1"
  DEFAULT_PORT = 3000
  DEFAULT_PROCESS_COUNT = 1

  STATIC_FILE_PATH = "./www"

  COOKIE_SESSION_KEY = ENV["COOKIE_SESSION_KEY"]? || "session"
  COOKIE_SESSION_SECRET = ENV["COOKIE_SESSION_SECRET"]? || "secret"

  LOG_BACKEND = ::Log::IOBackend.new

  def self.running_in_production?
    ENV["KEMAL_ENV"]? == "production"
  end
end
```

### 25.2. Configuration File

```crystal
# Application dependencies
require "action-controller"
require "./constants"

# Application code
require "./controllers/application"
require "./controllers/*"
require "./models/*"

# Server required after application controllers
require "action-controller/server"

module App
  # Configure logging
  if running_in_production?
    log_level = ::Log::Severity::Info
    ::Log.setup "*", :warn, LOG_BACKEND
  else
    log_level = ::Log::Severity::Debug
    ::Log.setup "*", :info, LOG_BACKEND
  end
  ::Log.builder.bind "action-controller.*", log_level, LOG_BACKEND
  ::Log.builder.bind "#{NAME}.*", log_level, LOG_BACKEND

  # Filter out sensitive params
  filter_params = ["password", "bearer_token"]
  keeps_headers = ["X-Request-ID"]

  # Add handlers that should run before your application
  ActionController::Server.before(
    ActionController::ErrorHandler.new(running_in_production?, keeps_headers),
    ActionController::LogHandler.new(filter_params),
    HTTP::CompressHandler.new
  )

  # Static file serving
  if File.directory?(STATIC_FILE_PATH)
    ::MIME.register(".yaml", "text/yaml")
    ActionController::Server.before(
      ::HTTP::StaticFileHandler.new(STATIC_FILE_PATH, directory_listing: false)
    )
  end

  # Configure session cookies
  ActionController::Session.configure do |settings|
    settings.key = COOKIE_SESSION_KEY
    settings.secret = COOKIE_SESSION_SECRET
    settings.secure = running_in_production?
  end
end
```

---

## 26. Complete Example: Working Application

### 26.1. Main Application File

```crystal
require "option_parser"
require "./constants"

module App
  port = DEFAULT_PORT
  host = DEFAULT_HOST
  process_count = DEFAULT_PROCESS_COUNT

  OptionParser.parse(ARGV.dup) do |parser|
    parser.banner = "Usage: #{PROGRAM_NAME} [arguments]"
    parser.on("-b HOST", "--bind=HOST", "Server host") { |h| host = h }
    parser.on("-p PORT", "--port=PORT", "Server port") { |p| port = p.to_i }
    parser.on("-w COUNT", "--workers=COUNT", "Process count") { |w| process_count = w.to_i }
    parser.on("-r", "--routes", "List routes") do
      ActionController::Server.print_routes
      exit 0
    end
    parser.on("-v", "--version", "Show version") do
      puts "#{NAME} v#{VERSION}"
      exit 0
    end
    parser.on("-d", "--docs", "Generate OpenAPI docs") do
      puts ActionController::OpenAPI.generate_open_api_docs(
        title: NAME,
        version: VERSION,
        description: "Complete Spider-Gazelle application"
      ).to_yaml
      exit 0
    end
  end

  require "./config"
  puts "Launching #{NAME} v#{VERSION}"

  server = ActionController::Server.new(port, host)
  server.cluster(process_count, "-w", "--workers") if process_count != 1

  Process.on_terminate do
    puts "\n > terminating gracefully"
    server.close
  end

  server.run do
    puts "Listening on #{server.print_addresses}"
  end

  puts "#{NAME} leaps through the veldt\n"
end
```

---

## 27. Best Practices Summary

1. **Use strong parameters** for automatic type conversion
2. **Implement proper error handling** with custom exception handlers
3. **Use structured logging** with request context
4. **Implement health checks** for production deployments
5. **Use pagination** for large datasets
6. **Implement rate limiting** for API protection
7. **Use custom converters** for complex parameter parsing
8. **Generate OpenAPI docs** for API documentation
9. **Use clustering** for production performance
10. **Implement graceful shutdown** for zero-downtime deployments

---

## 28. Conclusion

This comprehensive guide covers all aspects of Spider-Gazelle development, from basic setup to advanced production features. The examples are drawn from real-world applications and demonstrate idiomatic usage patterns. This document provides complete context for LLMs to understand and work with the Spider-Gazelle framework without requiring additional reference materials.

---

## 29. Advanced Examples and Patterns

### 29.1. Macro DSL (Low-Level Routing)

For fine-grained control, use the macro DSL directly:

```crystal
class MyPhotos < Application
  base "/my_photos"

  # GET /my_photos/:id/features
  get "/:id/features", :features do
    features = []
    render json: features
  end

  # POST /my_photos/:id/feature
  post "/:id/feature", :feature do
    head :ok
  end
end
```

### 29.2. CORS Support

```crystal
abstract class Application < AC::Base
  before_action :enable_cors

  def enable_cors
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    response.headers["Content-Type"] = "application/json"
    response.headers["Access-Control-Allow-Methods"] = "GET,HEAD,POST,DELETE,OPTIONS,PUT,PATCH"
  end
end

class ExampleController < Application
  base "/"

  @[AC::Route::OPTIONS("/")]
  def cors
  end

  @[AC::Route::GET("/")]
  def index
    render json: {"message" => "Hello World"}
  end
end
```

### 29.3. Around Filters for Database Transactions

```crystal
abstract class Application < AC::Base
  @[AC::Route::Filter(:around_action, only: [:create, :update, :destroy])]
  def wrap_in_transaction
    Database.transaction { yield }
  end
end
```

### 29.4. Force SSL

```crystal
class SecureController < Application
  force_ssl
end
```

### 29.5. Advanced File Handling

#### QR Code Generation
```crystal
@[AC::Route::GET("/qr_code.png")]
def png_qr(
  @[AC::Param::Info(description: "the data in the QR code")]
  content : String
) : Nil
  size = 256 # px
  response.headers["Content-Disposition"] = "inline"
  response.headers["Content-Type"] = "image/png"
  @__render_called__ = true

  png_bytes = QRCode.new(content).as_png(size: size)
  response.write png_bytes
end
```

#### File Streaming
```crystal
@[AC::Route::GET("/openapi.yaml")]
def openapi
  response.headers["Content-Disposition"] = %(attachment; filename="openapi.yml")
  response.headers["Content-Type"] = "application/yaml"
  @__render_called__ = true

  File.open("/app/openapi.yml") do |file|
    IO.copy(file, response)
  end
end
```

### 29.6. Response Code Mapping

```crystal
@[AC::Route::GET("/", status: {
  Int32 => HTTP::Status::OK,
  String => HTTP::Status::ACCEPTED,
  Float64 => HTTP::Status::CREATED
})]
def dynamic_response : Int32 | String | Float64
  case rand(3)
  when 1
    1
  when 2
    0.5
  else
    "wasn't 1 or 2"
  end
end
```

### 29.7. Chat Room WebSocket

```crystal
class ChatController < AC::Base
  base "/"

  SOCKETS = Hash(String, Array(HTTP::WebSocket)).new { |hash, key| hash[key] = [] of HTTP::WebSocket }

  @[AC::Route::WebSocket("/websocket/:room")]
  def websocket(socket, room : String)
    puts "Socket opened for room: #{room}"
    sockets = SOCKETS[room]
    sockets << socket

    socket.on_message do |message|
      sockets.each &.send("#{message} from #{room}")
    end

    socket.on_close do
      puts "Socket closed"
      sockets.size == 1 ? SOCKETS.delete(room) : sockets.delete(socket)
    end
  end
end
```

### 29.8. Custom Parameter Converters

#### Commit Hash Converter
```crystal
record Commit, branch : String, commit : String

struct ::ActionController::Route::Param::ConvertCommit
  # Converts "master#742887" to Commit object
  def convert(raw : String)
    branch, commit = raw.split('#')
    Commit.new(branch, commit)
  end
end

@[AC::Route::GET("/:commit")]
def show_commit(commit : Commit)
  "Branch: #{commit.branch}, Commit: #{commit.commit}"
end
```

### 29.9. Redis Pub/Sub Integration

```crystal
@[AC::Route::POST("/signal")]
def signal(
  @[AC::Param::Info(description: "Redis channel path")]
  channel : String,
) : Nil
  # Validate guest access
  if user_token.guest_scope?
    raise Error::Forbidden.new("guest scopes can only signal paths that include '/guest/'") unless channel.includes?("/guest/")
  end

  # Get payload from request body
  payload = request.body.try(&.gets_to_end) || ""

  # Publish to multiple channels
  [
    Path["placeos/"].join(channel).to_s,
    Path["placeos/#{current_authority.not_nil!.id}/"].join(channel).to_s
  ].each do |path|
    Log.info { "signalling #{path} with #{payload.bytesize} bytes" }
    Redis::Client.new.publish(path, payload)
  end
end
```

### 29.10. Security Patterns

#### JWT Authentication
```crystal
abstract class SecureApplication < Application
  before_action :authenticate_jwt

  private def authenticate_jwt
    auth_header = request.headers["Authorization"]?
    return render :unauthorized unless auth_header

    token = auth_header.gsub("Bearer ", "")
    begin
      payload = JWT.decode(token, JWT_SECRET, JWT::Algorithm::HS256)
      @current_user = User.find(payload[0]["user_id"].as(Int32))
    rescue
      render :unauthorized
    end
  end

  getter! current_user : User
end
```

#### Role-Based Access Control
```crystal
class AdminController < SecureApplication
  before_action :require_admin

  private def require_admin
    render :forbidden unless current_user.admin?
  end
end
```

### 29.11. Performance Optimization

#### Connection Pooling
```crystal
class DatabaseController < Application
  @@pool = DB::Pool.new(DB::Connection.new(DATABASE_URL), initial_pool_size: 5, max_pool_size: 20)

  @[AC::Route::GET("/users")]
  def users : Array(User)
    @@pool.using do |connection|
      connection.query_all("SELECT * FROM users", as: User)
    end
  end
end
```

#### Caching with Redis
```crystal
class CachedController < Application
  @@redis = Redis::Client.new

  @[AC::Route::GET("/cached/:key")]
  def cached_data(key : String) : String
    # Try cache first
    if cached = @@redis.get(key)
      return cached
    end

    # Generate data
    data = expensive_operation(key)

    # Cache for 1 hour
    @@redis.setex(key, 3600, data)
    data
  end

  private def expensive_operation(key : String) : String
    sleep(1)  # Simulate expensive operation
    "Expensive data for #{key}"
  end
end
```

### 29.12. Advanced Testing

#### Integration Testing with Database
```crystal
require "spec"
require "action-controller/spec_helper"
require "../src/config"

describe UserController do
  client = AC::SpecHelper.client

  before_each do
    # Clean database
    DB.connect(DATABASE_URL) do |db|
      db.exec("DELETE FROM users")
    end
  end

  it "creates a user" do
    user_data = {
      name: "John Doe",
      email: "john@example.com"
    }

    result = client.post("/users", body: user_data.to_json, headers: HTTP::Headers{
      "Content-Type" => "application/json"
    })

    result.status_code.should eq(201)
    user = User.from_json(result.body)
    user.name.should eq("John Doe")
  end
end
```

### 29.13. Real-World Examples and Production Patterns

#### 9.1. Complete Application Controller (Production Example)

Based on PlaceOS REST API patterns:

```crystal
require "uuid"
require "yaml"

abstract class Application < ActionController::Base
  # Configure logging
  Log = ::Log.for("controller")

  # Template configuration
  template_path "./src/views/"
  layout "layout_main.ecr"

  # Custom responders
  add_responder("application/yaml") { |io, result| result.to_yaml(io) }
  add_responder("text/html") { |io, result| result.to_s(io) }

  # Request ID for tracing
  @[AC::Route::Filter(:before_action)]
  def set_request_id
    request_id = UUID.random.to_s
    Log.context.set(
      client_ip: client_ip,
      request_id: request_id
    )
    response.headers["X-Request-ID"] = request_id
  end

  # Set date header
  @[AC::Route::Filter(:before_action)]
  def set_date_header
    response.headers["Date"] = HTTP.format_time(Time.utc)
  end

  # Error handlers
  @[AC::Route::Exception(AC::Route::NotAcceptable, status_code: HTTP::Status::NOT_ACCEPTABLE)]
  @[AC::Route::Exception(AC::Route::UnsupportedMediaType, status_code: HTTP::Status::UNSUPPORTED_MEDIA_TYPE)]
  def bad_media_type(error) : AC::Error::ContentResponse
    AC::Error::ContentResponse.new error: error.message.as(String), accepts: error.accepts
  end

  @[AC::Route::Exception(AC::Route::Param::MissingError, status_code: HTTP::Status::UNPROCESSABLE_ENTITY)]
  @[AC::Route::Exception(AC::Route::Param::ValueError, status_code: HTTP::Status::BAD_REQUEST)]
  def invalid_param(error) : AC::Error::ParameterResponse
    AC::Error::ParameterResponse.new error: error.message.as(String), parameter: error.parameter, restriction: error.restriction
  end

  # Authentication helpers
  def current_user
    return nil unless session["user_id"]?
    {
      id: session["user_id"].as(String),
      name: session["user_name"]?.try(&.as(String)) || "",
      email: session["user_email"]?.try(&.as(String)) || "",
      access_token: session["access_token"]?.try(&.as(String)) || ""
    }
  end

  def require_auth
    unless current_user
      redirect_to "/login"
      return
    end
  end

  def logged_in?
    current_user != nil
  end
end
```

#### 9.2. Advanced Authentication with JWT and Scopes

Based on PlaceOS Staff API patterns:

```crystal
abstract class Application < ActionController::Base
  # JWT Scope Check
  before_action :check_jwt_scope

  protected def check_jwt_scope
    access = user_token.get_access("public")
    block_access = request.method.downcase == "get" ? access.none? : !access.write?

    if block_access
      Log.warn { {message: "unknown scope #{user_token.scope}", action: "authorize!", host: request.hostname, id: user_token.id} }
      raise Error::Forbidden.new "valid scope required for access"
    end
  end

  # Rate limiting
  QUEUE_LIMIT = ENV["QUEUE_LIMIT"]?.try &.to_i
  USER_LOCK = Hash(String, Mutex).new { |lock, user| lock[user] = Mutex.new }
  USER_COUNT = Hash(String, Int32).new { |count, user| count[user] = 0 }
  COUNT_LOCK = Mutex.new

  def request_queue(&) : Nil
    limit = QUEUE_LIMIT
    return yield unless limit

    user_id = user_token.id
    lock = COUNT_LOCK.synchronize do
      count = USER_COUNT[user_id]
      raise Error::TooManyRequests.new("user #{user_id} has over #{limit} requests") if count >= limit
      USER_COUNT[user_id] = count + 1
      USER_LOCK[user_id]
    end

    begin
      lock.synchronize { yield }
    ensure
      COUNT_LOCK.synchronize do
        count = USER_COUNT[user_id] - 1
        if count.zero?
          USER_COUNT.delete user_id
          USER_LOCK.delete user_id
        else
          USER_COUNT[user_id] = count
        end
      end
    end
  end
end
```

#### 9.3. Database Integration with PgORM and Elasticsearch

```crystal
class UsersController < Application
  base "/api/users"

  # List users with Elasticsearch pagination
  @[AC::Route::GET("/")]
  def index(
    @[AC::Param::Info(description: "Search query")]
    query : String = "*",
    @[AC::Param::Info(description: "Maximum results")]
    limit : UInt32 = 100_u32,
    @[AC::Param::Info(description: "Starting offset")]
    offset : UInt32 = 0_u32,
    @[AC::Param::Info(description: "Next page token")]
    ref : String? = nil,
    @[AC::Param::Info(description: "Search fields")]
    fields : Array(String) = [] of String,
  ) : Array(User)
    elastic = User.elastic
    search_query = elastic.query({
      "q" => query,
      "limit" => limit.to_s,
      "offset" => offset.to_s,
      "fields" => fields
    })
    search_query["ref"] = ref if ref

    paginate_results(elastic, search_query)
  end

  # Create user with validation
  @[AC::Route::POST("/", body: :user)]
  def create(user : User) : User
    user.save!
    user
  end

  # Update user with optimistic locking
  @[AC::Route::PUT("/:id", body: :user)]
  def update(id : Int32, user : User) : User
    existing_user = User.find!(id)
    existing_user.assign_attributes(user)
    existing_user.save!
    existing_user
  end

  # Delete user with soft delete
  @[AC::Route::DELETE("/:id")]
  def destroy(id : Int32) : Nil
    user = User.find!(id)
    user.deleted_at = Time.utc
    user.save!
  end

  private def paginate_results(elastic, query, route = base_route)
    data = elastic.search(query)
    range_start = query.offset
    range_end = data[:results].size + range_start
    total_items = data[:total]
    item_type = elastic.elastic_index

    response.headers["X-Total-Count"] = total_items.to_s
    response.headers["Content-Range"] = "#{item_type} #{range_start}-#{range_end}/#{total_items}"

    if range_end < total_items
      query_params["offset"] = (range_end + 1).to_s
      query_params["limit"] = query.limit.to_s
      if ref = data[:ref]
        query_params["ref"] = ref
      end
      response.headers["Link"] = %(<#{route}?#{query_params}>; rel="next")
    end

    data[:results]
  end
end
```

#### 9.4. Redis Integration and Caching

```crystal
class CacheController < Application
  base "/api/cache"

  @@redis = Redis::Client.new

  # Cache with TTL
  @[AC::Route::GET("/:key")]
  def get(key : String) : String
    cached = @@redis.get(key)
    return cached if cached

    # Generate expensive data
    data = expensive_operation(key)

    # Cache for 1 hour
    @@redis.setex(key, 3600, data)
    data
  end

  # Cache invalidation
  @[AC::Route::DELETE("/:key")]
  def invalidate(key : String) : Nil
    @@redis.del(key)
  end

  # Redis pub/sub for real-time updates
  @[AC::Route::POST("/publish")]
  def publish(
    @[AC::Param::Info(description: "Channel name")]
    channel : String,
    @[AC::Param::Info(description: "Message payload")]
    message : String
  ) : Nil
    @@redis.publish(channel, message)
  end

  private def expensive_operation(key : String) : String
    # Simulate expensive operation
    sleep(1)
    "Expensive data for #{key} at #{Time.utc}"
  end
end
```

#### 9.5. WebSocket Integration

```crystal
class ChatController < Application
  base "/api/chat"

  SOCKETS = Hash(String, Array(HTTP::WebSocket)).new { |hash, key| hash[key] = [] of HTTP::WebSocket }

  @[AC::Route::WebSocket("/:room")]
  def websocket(socket, room : String)
    Log.info { "Socket opened for room: #{room}" }
    sockets = SOCKETS[room]
    sockets << socket

    socket.on_message do |message|
      Log.debug { "Received message in room #{room}: #{message}" }
      sockets.each &.send("#{message} from #{room}")
    end

    socket.on_close do
      Log.info { "Socket closed for room: #{room}" }
      sockets.size == 1 ? SOCKETS.delete(room) : sockets.delete(socket)
    end
  end

  # Send message to specific room
  @[AC::Route::POST("/:room/message")]
  def send_message(
    room : String,
    @[AC::Param::Info(description: "Message content")]
    message : String
  ) : Nil
    if sockets = SOCKETS[room]?
      sockets.each &.send(message)
    end
  end
end
```

#### 9.6. File Upload and Processing

```crystal
class UploadsController < Application
  base "/api/uploads"

  # Upload file with validation
  @[AC::Route::POST("/")]
  def create : Upload
    file = files["file"]?.try(&.first?)
    raise Error::BadRequest.new("No file provided") unless file

    # Validate file type
    allowed_types = ["image/jpeg", "image/png", "application/pdf"]
    raise Error::BadRequest.new("Invalid file type") unless allowed_types.includes?(file.content_type)

    # Validate file size (10MB limit)
    max_size = 10 * 1024 * 1024
    raise Error::BadRequest.new("File too large") if file.size > max_size

    # Save file
    filename = "#{UUID.random}-#{file.filename}"
    file_path = File.join("uploads", filename)

    File.write(file_path, file.body)

    # Create upload record
    upload = Upload.new(
      filename: filename,
      original_name: file.filename,
      content_type: file.content_type,
      size: file.size,
      user_id: current_user["id"]
    )
    upload.save!
    upload
  end

  # Serve file
  @[AC::Route::GET("/:id")]
  def show(id : Int32) : Nil
    upload = Upload.find!(id)
    file_path = File.join("uploads", upload.filename)

    unless File.exists?(file_path)
      raise Error::NotFound.new("File not found")
    end

    response.headers["Content-Type"] = upload.content_type
    response.headers["Content-Disposition"] = "inline; filename=\"#{upload.original_name}\""

    File.open(file_path) do |file|
      IO.copy(file, response)
    end
  end
end
```

#### 9.7. Health Checks and Monitoring

```crystal
class HealthController < Application
  base "/api/health"

  @[AC::Route::GET("/")]
  def index : HealthStatus
    HealthStatus.new(
      status: "healthy",
      timestamp: Time.utc,
      version: App::VERSION,
      checks: {
        "database" => check_database,
        "redis" => check_redis,
        "elasticsearch" => check_elasticsearch
      }
    )
  end

  @[AC::Route::GET("/ready")]
  def ready : Nil
    # Check if application is ready to receive traffic
    raise "not ready" unless ready?
  end

  @[AC::Route::GET("/live")]
  def live : Nil
    # Simple liveness check
  end

  private def check_database : Bool
    begin
      DB.connect(DATABASE_URL) do |db|
        db.scalar("SELECT 1")
      end
      true
    rescue
      false
    end
  end

  private def check_redis : Bool
    begin
      Redis::Client.new.ping
      true
    rescue
      false
    end
  end

  private def check_elasticsearch : Bool
    begin
      HTTP::Client.get("#{ELASTICSEARCH_URL}/_cluster/health")
      true
    rescue
      false
    end
  end

  private def ready? : Bool
    check_database && check_redis
  end
end

record HealthStatus,
  status : String,
  timestamp : Time,
  version : String,
  checks : Hash(String, Bool) do
  include JSON::Serializable
end
```

#### 9.8. API Versioning and Documentation

```crystal
class ApiController < Application
  base "/api/v1"

  # API version info
  @[AC::Route::GET("/version")]
  def version : ApiVersion
    ApiVersion.new(
      version: "v1",
      status: "stable",
      deprecated: false,
      sunset_date: nil
    )
  end

  # OpenAPI documentation
  @[AC::Route::GET("/docs")]
  def docs : String
    ActionController::OpenAPI.generate_open_api_docs(
      title: "My API",
      version: "v1.0.0",
      description: "API documentation for version 1"
    ).to_yaml
  end

  # API status
  @[AC::Route::GET("/status")]
  def status : ApiStatus
    ApiStatus.new(
      status: "operational",
      uptime: Process.clock_gettime(Process::Clock::MONOTONIC),
      requests_per_minute: get_request_rate
    )
  end

  private def get_request_rate : Float64
    # Implementation to get current request rate
    150.5
  end
end

record ApiVersion,
  version : String,
  status : String,
  deprecated : Bool,
  sunset_date : Time? do
  include JSON::Serializable
end

record ApiStatus,
  status : String,
  uptime : Float64,
  requests_per_minute : Float64 do
  include JSON::Serializable
end
```

#### 9.9. Testing Patterns

```crystal
# spec/controllers/users_controller_spec.cr
require "spec"
require "action-controller/spec_helper"
require "../src/config"

describe UsersController do
  client = AC::SpecHelper.client

  before_each do
    # Clean database
    DB.connect(DATABASE_URL) do |db|
      db.exec("DELETE FROM users")
    end
  end

  it "creates a user" do
    user_data = {
      name: "John Doe",
      email: "john@example.com"
    }

    result = client.post("/api/users", body: user_data.to_json, headers: HTTP::Headers{
      "Content-Type" => "application/json"
    })

    result.status_code.should eq(201)
    user = User.from_json(result.body)
    user.name.should eq("John Doe")
  end

  it "lists users with pagination" do
    # Create test users
    5.times do |i|
      User.create!(name: "User #{i}", email: "user#{i}@example.com")
    end

    result = client.get("/api/users?limit=3&offset=0")
    result.status_code.should eq(200)

    users = Array(User).from_json(result.body)
    users.size.should eq(3)

    # Check pagination headers
    result.headers["X-Total-Count"].should eq("5")
    result.headers["Content-Range"].should eq("users 0-3/5")
  end

  it "handles validation errors" do
    user_data = {
      name: "",  # Invalid: empty name
      email: "invalid-email"  # Invalid: bad email format
    }

    result = client.post("/api/users", body: user_data.to_json, headers: HTTP::Headers{
      "Content-Type" => "application/json"
    })

    result.status_code.should eq(422)
    error = JSON.parse(result.body)
    error["error"].should contain("validation failed")
  end
end
```

#### 9.10. Production Deployment Configuration

```crystal
# src/app.cr - Production-ready entry point
require "option_parser"
require "./constants"

module App
  # Server defaults
  port = DEFAULT_PORT
  host = DEFAULT_HOST
  process_count = DEFAULT_PROCESS_COUNT

  # Command line options
  OptionParser.parse(ARGV.dup) do |parser|
    parser.banner = "Usage: #{PROGRAM_NAME} [arguments]"

    parser.on("-b HOST", "--bind=HOST", "Specifies the server host") { |h| host = h }
    parser.on("-p PORT", "--port=PORT", "Specifies the server port") { |p| port = p.to_i }
    parser.on("-w COUNT", "--workers=COUNT", "Specifies the number of processes") { |w| process_count = w.to_i }
    parser.on("-r", "--routes", "List the application routes") do
      ActionController::Server.print_routes
      exit 0
    end
    parser.on("-v", "--version", "Display the application version") do
      puts "#{NAME} v#{VERSION}"
      exit 0
    end
    parser.on("-d", "--docs", "Outputs OpenAPI documentation") do
      puts ActionController::OpenAPI.generate_open_api_docs(
        title: NAME,
        version: VERSION,
        description: "API documentation"
      ).to_yaml
      exit 0
    end
  end

  # Load configuration
  require "./config"

  # Create server
  server = ActionController::Server.new(port, host)
  server.cluster(process_count, "-w", "--workers") if process_count != 1

  # Graceful shutdown
  Process.on_terminate do
    puts "\n > terminating gracefully"
    server.close
  end

  # Start server
  server.run do
    puts "Listening on #{server.print_addresses}"
  end

  puts "#{NAME} leaps through the veldt\n"
end
```

---

## 30. Final Notes

This comprehensive guide now includes:

- **Basic to advanced routing patterns**
- **Real-world production examples**
- **Security implementations**
- **Performance optimization techniques**
- **Testing strategies**
- **Advanced WebSocket patterns**
- **Custom parameter converters**
- **File handling and streaming**
- **Redis integration**
- **Database connection pooling**
- **Caching strategies**

The examples are drawn from actual production applications and demonstrate the full power and flexibility of the Spider-Gazelle framework. This document serves as a complete reference for building robust, scalable web applications with Crystal and Spider-Gazelle.
