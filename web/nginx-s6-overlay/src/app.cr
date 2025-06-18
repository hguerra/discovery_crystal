require "http"
require "json"
require "log"
require "digest/sha256"

# Hash thread-local para armazenar dados de tracing
class ThreadLocalStorage
  @@storage = {} of UInt64 => Hash(String, String)

  def self.set(key : String, value : String)
    thread_id = Thread.current.object_id
    @@storage[thread_id] ||= {} of String => String
    @@storage[thread_id][key] = value
  end

  def self.get(key : String) : String?
    thread_id = Thread.current.object_id
    @@storage[thread_id]?.try(&.[key]?)
  end

  def self.delete(key : String)
    thread_id = Thread.current.object_id
    if store = @@storage[thread_id]?
      store.delete(key)
      # Se o hash da thread ficar vazio, remove a entrada do @@storage
      @@storage.delete(thread_id) if store.empty?
    end
  end

  def self.clear
    thread_id = Thread.current.object_id
    @@storage.delete(thread_id)
  end
end

# Backend customizado para GCP/Stackdriver
class GCPJsonBackend < Log::Backend
  def write(entry : Log::Entry)
    # Extrair traceparent e tracestate do ThreadLocalStorage de forma segura
    traceparent = ThreadLocalStorage.get("traceparent")
    tracestate = ThreadLocalStorage.get("tracestate")

    trace_id = nil
    span_id = nil
    if traceparent
      parts = traceparent.split('-')
      trace_id = parts[1]?
      span_id = parts[2]?
    end

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

    if trace_id
      data["logging.googleapis.com/trace"] = trace_id
    end
    if span_id
      data["logging.googleapis.com/spanId"] = span_id
    end
    if trace = ENV["GCP_TRACE_ID"]?
      data["logging.googleapis.com/trace"] = trace
    end
    data["logging.googleapis.com/labels"] = {
      "environment" => ENV["ENVIRONMENT"]? || "development",
      "app_version" => App::VERSION,
      "instance_id" => ENV["INSTANCE_ID"]? || "1"
    }
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

# Autenticação simplificada para múltiplas instâncias
class Auth
  def self.authenticate(username : String, password : String) : Bool
    # Demo: aceita qualquer usuário/senha
    # Em produção, implementar validação real
    !username.empty? && !password.empty?
  end

  def self.generate_session_cookie(username : String) : String
    # Cookie simples com username e timestamp
    timestamp = Time.utc.to_unix
    signature = generate_signature(username, timestamp)
    "session_token=#{username}.#{timestamp}.#{signature}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=3600"
  end

  def self.validate_session_cookie(cookie_value : String) : String?
    return nil if cookie_value.empty?

    parts = cookie_value.split('.')
    return nil if parts.size != 3

    username, timestamp_str, signature = parts
    timestamp = timestamp_str.to_i64

    # Verificar se o cookie não expirou (1 hora)
    return nil if Time.utc.to_unix - timestamp > 3600

    # Verificar assinatura
    expected_signature = generate_signature(username, timestamp)
    return nil unless signature == expected_signature

    username
  end

  def self.clear_session_cookie : String
    "session_token=; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=0"
  end

  private def self.generate_signature(username : String, timestamp : Int64) : String
    # Em produção, usar uma chave secreta real
    secret = "demo_secret_key_2024"
    data = "#{username}.#{timestamp}.#{secret}"
    Digest::SHA256.hexdigest(data)[0..15]
  end
end

# Log de requests
class RequestLogger
  include HTTP::Handler

  def call(context)
    # Extrair e armazenar traceparent e tracestate de forma segura
    if tp = context.request.headers["traceparent"]?
      ThreadLocalStorage.set("traceparent", tp)
    end
    if ts = context.request.headers["tracestate"]?
      ThreadLocalStorage.set("tracestate", ts)
    end

    start_time = Time.utc
    call_next(context)
    duration = Time.utc - start_time

    Metrics.increment_request

    Log.info { "Request: #{context.request.method} #{context.request.path} - #{context.response.status_code} (#{duration.total_milliseconds.round(2)}ms)" }

    # Limpeza segura dos dados de tracing após o uso
    ThreadLocalStorage.delete("traceparent")
    ThreadLocalStorage.delete("tracestate")
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
    ctx.response.print({
      status: "healthy",
      instance_id: instance_id,
      timestamp: Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ"),
      uptime: Metrics.get_metrics[:uptime_seconds],
      requests_total: Metrics.get_metrics[:requests_total]
    }.to_json)
  when "/api/auth"
    # Autenticação
    session_token = ctx.request.cookies["session_token"]?.try(&.value)

    if session_token && Auth.validate_session_cookie(session_token)
      user_id = Auth.validate_session_cookie(session_token)
      ctx.response.content_type = "application/json"
      ctx.response.print({
        "authenticated" => true,
        "user" => user_id,
        "message" => "Usuário autenticado"
      }.to_json)
    else
      ctx.response.status_code = 401
      ctx.response.content_type = "application/json"
      ctx.response.print({
        "authenticated" => false,
        "message" => "Não autenticado"
      }.to_json)
    end
  when "/api/login"
    # Login
    username = ctx.request.form_params["username"]?
    password = ctx.request.form_params["password"]?

    # Debug: log dos dados recebidos
    Log.info { "Login attempt - Username: #{username.inspect}, Password: #{password.inspect}" }
    Log.info { "Form params: #{ctx.request.form_params}" }
    Log.info { "Content-Type: #{ctx.request.headers["Content-Type"]?}" }

    if username && password && Auth.authenticate(username, password)
      session_id = Auth.generate_session_cookie(username)
      ctx.response.headers["Set-Cookie"] = session_id
      ctx.response.content_type = "application/json"
      ctx.response.print({
        "success" => true,
        "message" => "Login realizado com sucesso"
      }.to_json)
    else
      ctx.response.status_code = 401
      ctx.response.content_type = "application/json"
      ctx.response.print({
        "success" => false,
        "message" => "Usuário ou senha inválidos"
      }.to_json)
    end
  when "/api/logout"
    # Logout
    session_token = ctx.request.cookies["session_token"]?.try(&.value)

    # Sempre limpar o cookie, independente de ter sessão ou não
    cookie = Auth.clear_session_cookie
    ctx.response.headers["Set-Cookie"] = cookie

    ctx.response.content_type = "application/json"
    ctx.response.print({
      "success" => true,
      "message" => "Logout realizado com sucesso"
    }.to_json)
  when "/test", "/api/test"
    ctx.response.content_type = "application/json"
    ctx.response.print({
      message: "Test endpoint from Crystal backend",
      instance_id: instance_id,
      data: {
        items: [
          { id: 1, name: "Item 1", description: "First test item" },
          { id: 2, name: "Item 2", description: "Second test item" },
          { id: 3, name: "Item 3", description: "Third test item" }
        ],
        timestamp: Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ"),
        random_number: Random.new.rand(1..100)
      }
    }.to_json)
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
