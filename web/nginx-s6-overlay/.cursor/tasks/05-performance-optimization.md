# Tarefa 5: Otimização de Performance

## Objetivo
Otimizar a performance da aplicação através de configurações avançadas e cache.

## Prioridade: BAIXA
## Complexidade: ALTA
## Tempo Estimado: 3-4 horas

## Subtarefas

### 5.1 Implementar connection pooling
**Objetivo**: Melhorar performance de conexões com banco de dados
**Arquivos a modificar**: `src/app.cr`
**Linhas a adicionar**: Após configurações de env

**Implementação**:
```crystal
# Connection pooling (se houver banco de dados)
require "db"
require "sqlite3"

# Pool de conexões
DB_URL = ENV["DATABASE_URL"]? || "sqlite3://./app.db"
pool_size = (ENV["DB_POOL_SIZE"]? || "5").to_i

DB.connect(DB_URL) do |db|
  # Configurar pool
  db.pool_size = pool_size
end
```

### 5.2 Otimizar configurações do Crystal
**Objetivo**: Melhorar performance do runtime Crystal
**Arquivos a modificar**: `Dockerfile`
**Linhas a alterar**: Linha 8

**Flags de otimização**:
```dockerfile
RUN crystal build src/app.cr -o /usr/bin/my-api --release \
  --no-debug \
  --prelude=empty \
  --link-flags="-static"
```

### 5.3 Implementar cache em memória
**Objetivo**: Reduzir latência para dados frequentemente acessados
**Arquivos a modificar**: `src/app.cr`
**Linhas a adicionar**: Após requires

**Cache simples**:
```crystal
# Cache em memória
class Cache
  @@store = {} of String => {String, Time}
  @@max_size = 1000
  @@ttl = 300 # 5 minutos

  def self.get(key : String) : String?
    if entry = @@store[key]?
      if Time.utc < entry[1]
        entry[0]
      else
        @@store.delete(key)
        nil
      end
    end
  end

  def self.set(key : String, value : String)
    if @@store.size >= @@max_size
      # Remove entrada mais antiga
      oldest = @@store.min_by { |k, v| v[1] }
      @@store.delete(oldest[0])
    end
    @@store[key] = {value, Time.utc + @@ttl.seconds}
  end
end
```

### 5.4 Configurar worker processes
**Objetivo**: Melhorar throughput com múltiplos workers
**Arquivos a modificar**: `rootfs/etc/nginx/nginx.conf`
**Linhas a adicionar**: Arquivo novo

**Configuração de workers**:
```nginx
worker_processes auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    # Configurações de buffer
    client_body_buffer_size 128k;
    client_max_body_size 10m;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;

    # Configurações de proxy buffer
    proxy_buffer_size 4k;
    proxy_buffers 8 4k;
    proxy_busy_buffers_size 8k;
}
```

### 5.5 Implementar load balancing interno
**Objetivo**: Distribuir carga entre múltiplas instâncias
**Arquivos a modificar**: `rootfs/etc/nginx/conf.d/default.conf`
**Linhas a alterar**: Configuração de proxy

**Upstream com múltiplos backends**:
```nginx
# Upstream para load balancing
upstream backend {
    least_conn;
    server 127.0.0.1:3000 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:3001 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

location /api {
    proxy_pass http://backend;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    # ... outras configurações
}
```

## Critérios de Aceitação
- [ ] Throughput aumentou em pelo menos 50%
- [ ] Latência média reduzida em 30%
- [ ] Cache está funcionando corretamente
- [ ] Workers estão distribuindo carga
- [ ] Load balancing está ativo

## Comandos de Teste
```bash
# Teste de performance
ab -n 1000 -c 10 http://localhost/api

# Teste de latência
curl -w "@curl-format.txt" -o /dev/null -s http://localhost/api

# Monitorar recursos
docker stats container_name

# Verificar cache hit rate
curl http://localhost/metrics | grep cache
```

## Arquivo curl-format.txt
```
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
```

## Notas para LLM
- Implementar gradualmente para medir impacto
- Monitorar uso de memória e CPU
- Testar com carga realista
- Considerar trade-offs entre performance e recursos
- Documentar métricas de baseline
