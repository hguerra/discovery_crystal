# Otimizações e Configurações do Nginx

Este documento explica cada configuração adicionada aos arquivos de configuração do Nginx para otimizar, proteger e melhorar a performance do nginx neste projeto.

## 1. Configurações Globais (nginx.conf)

### 1.1 Otimizações de Worker Processes
```nginx
# Otimizações de worker processes
worker_rlimit_nofile 65536;

events {
    worker_connections  1024;
    use epoll;
    multi_accept on;
}
```
- **O que faz:** Configura o nginx para melhor performance e escalabilidade.
- **Por quê:** Otimiza o processamento de conexões e recursos do sistema.
- **Detalhes:**
  - `worker_rlimit_nofile 65536`: Aumenta o limite de file descriptors para 65k
  - `use epoll`: Usa o event loop epoll (mais eficiente no Linux)
  - `multi_accept on`: Aceita múltiplas conexões de uma vez
  - `worker_connections 1024`: Máximo de conexões simultâneas por worker

### 1.2 Severity Dinâmica Baseada no Status HTTP
```nginx
# Mapeamento de status HTTP para severity
map $status $log_severity {
    ~^2  "INFO";
    ~^3  "INFO";
    ~^4  "WARNING";
    ~^5  "ERROR";
    default "INFO";
}
```
- **O que faz:** Mapeia automaticamente o status HTTP para o nível de severity do log.
- **Por quê:** Facilita o monitoramento e alertas baseados na gravidade dos erros.
- **Mapeamento:**
  - **2xx (Sucesso)**: `INFO` - Requisições bem-sucedidas
  - **3xx (Redirecionamento)**: `INFO` - Redirecionamentos normais
  - **4xx (Erro do Cliente)**: `WARNING` - Erros como 404, 403, 400
  - **5xx (Erro do Servidor)**: `ERROR` - Erros internos do servidor

### 1.3 Otimizações de Performance
```nginx
# Otimizações de performance
sendfile        on;
tcp_nopush      on;
tcp_nodelay     on;
```
- **O que faz:** Otimiza o envio de arquivos e a latência de rede.
- **Por quê:** Melhora significativamente a performance para arquivos estáticos e APIs.
- **Detalhes:**
  - `sendfile on`: Usa sendfile() do sistema para envio eficiente de arquivos
  - `tcp_nopush on`: Otimiza o envio de pacotes TCP (usado com sendfile)
  - `tcp_nodelay on`: Desativa o algoritmo de Nagle, reduzindo latência

### 1.4 Timeouts Otimizados
```nginx
# Timeouts otimizados
keepalive_timeout  65;
client_body_timeout 12;
client_header_timeout 12;
send_timeout 10;
```
- **O que faz:** Configura timeouts apropriados para diferentes tipos de operações.
- **Por quê:** Evita conexões penduradas e melhora a responsividade.
- **Detalhes:**
  - `keepalive_timeout 65`: Mantém conexões HTTP abertas por 65 segundos
  - `client_body_timeout 12`: Timeout para upload de arquivos
  - `client_header_timeout 12`: Timeout para receber headers
  - `send_timeout 10`: Timeout para envio de resposta

### 1.5 Otimizações de Buffer
```nginx
# Otimizações de buffer
client_max_body_size 10m;
client_body_buffer_size 128k;
client_header_buffer_size 1k;
large_client_header_buffers 4 4k;
```
- **O que faz:** Configura buffers para requisições HTTP.
- **Por quê:** Otimiza o uso de memória e permite uploads de arquivos.
- **Detalhes:**
  - `client_max_body_size 10m`: Permite uploads até 10MB
  - `client_body_buffer_size 128k`: Buffer para o corpo da requisição
  - `client_header_buffer_size 1k`: Buffer para headers pequenos
  - `large_client_header_buffers 4 4k`: Buffers para headers grandes

### 1.6 Segurança Global
```nginx
# Segurança
server_tokens off;
```
- **O que faz:** Oculta a versão do nginx nos headers de resposta.
- **Por quê:** Reduz a superfície de ataque, não expondo informações desnecessárias.

## 2. Rate Limiting
```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=static:10m rate=100r/s;
```
- **O que faz:** Cria zonas de memória para limitar o número de requisições por IP.
- **Por quê:** Protege contra ataques DDoS e abuso de API/recursos estáticos.
- **Como funciona:**
  - `api`: 10 requisições/segundo por IP (com burst de 20)
  - `static`: 100 requisições/segundo por IP (com burst de 100)

## 3. Compressão gzip
```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
```
- **O que faz:** Ativa compressão gzip para tipos de conteúdo comuns.
- **Por quê:** Reduz o tamanho das respostas HTTP, economizando banda e acelerando o carregamento.
- **Detalhes:**
  - Só comprime arquivos maiores que 1024 bytes.
  - Inclui tipos de texto, CSS, JS, JSON, XML, etc.

## 4. Headers de Segurança
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
```
- **O que faz:** Adiciona headers HTTP para proteger contra ataques comuns.
- **Por quê:** Melhora a segurança do frontend e backend.
- **Explicação:**
  - `X-Frame-Options`: Previne clickjacking
  - `X-Content-Type-Options`: Previne sniffing de MIME
  - `X-XSS-Protection`: Ativa proteção XSS em navegadores antigos
  - `Referrer-Policy`: Controla envio de referrer
  - `Content-Security-Policy`: Restringe fontes de scripts e estilos

## 5. Cache de Arquivos Estáticos
```nginx
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    root /var/www/html;
    expires 1y;
    add_header Cache-Control "public, immutable, max-age=31536000";
    access_log off;
}
```
- **O que faz:** Aplica cache agressivo para arquivos estáticos.
- **Por quê:** Melhora performance e reduz carga no servidor.
- **Detalhes:**
  - `expires 1y`: Header `Expires` para 1 ano
  - `Cache-Control`: Público, imutável, 1 ano
  - `access_log off`: Não loga acessos a estáticos
  - `root`: Garante que arquivos são servidos do diretório correto

## 6. Proxy para API
```nginx
location /api {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://localhost:3000;
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
```
- **O que faz:** Encaminha requisições `/api` para o backend Crystal.
- **Por quê:** Permite separar frontend e backend, mantendo segurança e performance.
- **Detalhes de cada configuração:**
  - `limit_req zone=api burst=20 nodelay;`: Aplica rate limiting para proteger a API.
  - `proxy_pass http://localhost:3000;`: Redireciona as requisições para o backend Crystal na porta 3000.
  - `proxy_set_header Host $host;`: Garante que o header Host original do cliente seja enviado ao backend (útil para logs, autenticação e multi-tenancy).
  - `proxy_set_header X-Real-IP $remote_addr;`: Passa o IP real do cliente para o backend, permitindo logs e controle de acesso corretos.
  - `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`: Adiciona o IP do cliente à cadeia de proxies, importante para rastreamento e segurança.
  - `proxy_set_header X-Forwarded-Proto $scheme;`: Informa ao backend se a requisição original era HTTP ou HTTPS (útil para redirecionamentos e geração de links).
  - `proxy_set_header X-Request-ID $request_id;`: Adiciona ID único para tracing e debugging.
  - `proxy_connect_timeout 5s;`: Tempo máximo para o nginx conseguir se conectar ao backend. Evita travamentos em caso de backend lento ou indisponível.
  - `proxy_send_timeout 10s;`: Tempo máximo para o nginx enviar dados ao backend.
  - `proxy_read_timeout 10s;`: Tempo máximo para o nginx esperar resposta do backend.
  - `proxy_buffering off;`: Desativa o buffering de resposta, útil para APIs que fazem streaming ou para respostas rápidas (reduz latência).

- **Exemplo de uso prático:**
  - Permite que o frontend e o backend rodem no mesmo container, mas de forma isolada.
  - Garante que logs, autenticação e rastreamento de IP funcionem corretamente.
  - Melhora a resiliência do sistema a falhas e ataques.

## 7. Servir Frontend (Single Page Application)
```nginx
location / {
    limit_req zone=static burst=100 nodelay;
    root /var/www/html;
    index index.html;
    try_files $uri $uri/ =404;
}
```
- **O que faz:** Serve o frontend estático e aplica rate limiting.
- **Por quê:** Garante que o SPA funcione corretamente e protege contra abusos.
- **Detalhes:**
  - `try_files $uri $uri/ =404;`: Retorna 404 se arquivo não existir
  - `index index.html;`: Serve index.html por padrão

## 8. Logging Estruturado em JSON com Severity Dinâmica

### Configuração de Logs para Containers
```nginx
# Direcionar error_log para stderr (padrão para containers)
error_log /dev/stderr notice;

# Direcionar access_log para stdout em formato JSON (padrão para containers)
access_log /dev/stdout json_escape;
```

### Formato JSON para GCP/Stackdriver com Severity Dinâmica
```nginx
log_format json_escape escape=json '{'
    '"timestamp": "$time_iso8601",'
    '"severity": "$log_severity",'
    '"httpRequest": {'
        '"requestMethod": "$request_method",'
        '"requestUrl": "$request_uri",'
        '"requestSize": "$request_length",'
        '"status": $status,'
        '"responseSize": "$body_bytes_sent",'
        '"userAgent": "$http_user_agent",'
        '"remoteIp": "$remote_addr",'
        '"serverIp": "$server_addr",'
        '"referer": "$http_referer",'
        '"latency": "$request_time",'
        '"cacheLookup": false,'
        '"cacheHit": false,'
        '"cacheValidatedWithOriginServer": false,'
        '"cacheFillBytes": "0",'
        '"protocol": "$server_protocol"'
    '},'
    '"resource": {'
        '"type": "http_load_balancer",'
        '"labels": {'
            '"backend_service_name": "crystal-api",'
            '"zone": "container"'
        '}'
    '},'
    '"labels": {'
        '"nginx_version": "$nginx_version",'
        '"worker_pid": "$pid"'
    '},'
    '"operation": {'
        '"id": "$request_id",'
        '"producer": "nginx",'
        '"first": true,'
        '"last": true'
    '},'
    '"trace": "$http_x_cloud_trace_context",'
    '"spanId": "$http_x_cloud_trace_context",'
    '"traceSampled": true,'
    '"sourceLocation": {'
        '"file": "nginx.conf",'
        '"line": 1,'
        '"function": "http_request"'
    '}'
'}';
```

- **O que faz:** Configura logging estruturado em JSON com severity automática baseada no status HTTP.
- **Por quê:** Facilita integração com sistemas de observabilidade e permite alertas inteligentes.
- **Benefícios:**
  - **Severity Dinâmica**: Automática baseada no status HTTP (2xx=INFO, 4xx=WARNING, 5xx=ERROR)
  - **stdout/stderr**: Logs aparecem diretamente no `docker logs` ou `kubectl logs`
  - **Formato JSON**: Estruturado e fácil de processar
  - **Request ID**: Cada requisição tem ID único para tracing
  - **Compatibilidade GCP**: Segue padrão do Google Cloud Platform
  - **Performance**: Não há overhead de escrita em arquivos

### Exemplo de Logs com Severity Dinâmica
```json
// Requisição bem-sucedida (200)
{
  "timestamp": "2025-06-19T00:58:19+00:00",
  "severity": "INFO",
  "httpRequest": {
    "requestMethod": "GET",
    "requestUrl": "/api/health",
    "status": 200,
    "responseSize": "55",
    "userAgent": "curl/7.81.0",
    "remoteIp": "172.17.0.1",
    "latency": "0.000",
    "protocol": "HTTP/1.1"
  }
}

// Erro do cliente (404)
{
  "timestamp": "2025-06-19T00:58:22+00:00",
  "severity": "WARNING",
  "httpRequest": {
    "requestMethod": "GET",
    "requestUrl": "/notfound",
    "status": 404,
    "responseSize": "146",
    "userAgent": "curl/7.81.0",
    "remoteIp": "172.17.0.1",
    "latency": "0.000",
    "protocol": "HTTP/1.1"
  }
}

// Erro do servidor (500)
{
  "timestamp": "2025-06-19T00:58:25+00:00",
  "severity": "ERROR",
  "httpRequest": {
    "requestMethod": "GET",
    "requestUrl": "/api/error",
    "status": 500,
    "responseSize": "0",
    "userAgent": "curl/7.81.0",
    "remoteIp": "172.17.0.1",
    "latency": "0.001",
    "protocol": "HTTP/1.1"
  }
}
```

## 9. Comandos de Teste e Validação

### Testar Severity Dinâmica
```bash
# Testar requisições com diferentes status
curl -s http://localhost:8080/api/health  # Deve gerar severity: "INFO"
curl -s -w "%{http_code}\n" http://localhost:8080/notfound  # Deve gerar severity: "WARNING"

# Verificar logs com severity
docker logs myapp_local | jq '.severity' | sort | uniq -c
```

### Testar Otimizações de Performance
```bash
# Verificar configurações aplicadas
docker exec myapp_local nginx -T | grep -E "(tcp_nopush|tcp_nodelay|epoll|multi_accept)"

# Teste de performance
ab -n 1000 -c 10 http://localhost:8080/api/health
```

### Testar Headers de Segurança
```bash
# Verificar headers de segurança
curl -I http://localhost:8080/ | grep -E "(X-Frame-Options|X-Content-Type-Options|X-XSS-Protection|Server)"
```

### Testar Rate Limiting
```bash
# Testar rate limiting da API
for i in {1..15}; do echo -n "Request $i: "; curl -s -w "%{http_code}\n" http://localhost:8080/api; done
```

---

**Dica:** Sempre que alterar a configuração, rode `make build && make run` e teste os endpoints e arquivos estáticos para garantir que tudo está funcionando!

**Nota sobre Logging:** Esta configuração segue as melhores práticas para containers Docker/Kubernetes, onde logs devem ser direcionados para stdout/stderr para facilitar a coleta por sistemas de logging. A severity dinâmica permite alertas mais inteligentes baseados na gravidade real dos problemas.
