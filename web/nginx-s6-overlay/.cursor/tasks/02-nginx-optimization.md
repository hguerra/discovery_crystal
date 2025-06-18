# Tarefa 2: Otimização da Configuração do Nginx

## Objetivo
Otimizar a configuração do nginx para melhor performance, segurança e cache.

## Prioridade: ALTA
## Complexidade: MÉDIA
## Tempo Estimado: 1-2 horas

## Subtarefas

### 2.1 Implementar cache de arquivos estáticos
**Objetivo**: Melhorar performance para arquivos estáticos
**Arquivos a modificar**: `rootfs/etc/nginx/conf.d/default.conf`
**Linhas a alterar**: 1-16

**Configurações a adicionar**:
```nginx
# Cache para arquivos estáticos
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
}

# Cache para HTML
location ~* \.html$ {
    expires 1h;
    add_header Cache-Control "public, must-revalidate";
}
```

### 2.2 Adicionar compressão gzip
**Objetivo**: Reduzir tamanho das respostas HTTP
**Arquivos a modificar**: `rootfs/etc/nginx/conf.d/default.conf`
**Linhas a adicionar**: Após linha 1

**Configuração a adicionar**:
```nginx
# Compressão gzip
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
```

### 2.3 Implementar headers de segurança
**Objetivo**: Melhorar segurança da aplicação
**Arquivos a modificar**: `rootfs/etc/nginx/conf.d/default.conf`
**Linhas a adicionar**: Dentro do bloco server

**Headers a adicionar**:
```nginx
# Headers de segurança
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
```

### 2.4 Otimizar configuração de proxy
**Objetivo**: Melhorar performance do proxy para API
**Arquivos a modificar**: `rootfs/etc/nginx/conf.d/default.conf`
**Linhas a alterar**: 10-13

**Configuração otimizada**:
```nginx
location /api {
    proxy_pass http://localhost:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_connect_timeout 5s;
    proxy_send_timeout 10s;
    proxy_read_timeout 10s;
    proxy_buffering off;
}
```

### 2.5 Adicionar rate limiting básico
**Objetivo**: Proteger contra ataques DDoS simples
**Arquivos a modificar**: `rootfs/etc/nginx/conf.d/default.conf`
**Linhas a adicionar**: Antes do bloco server

**Configuração a adicionar**:
```nginx
# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=static:10m rate=100r/s;
```

## Critérios de Aceitação
- [ ] Arquivos estáticos são servidos com cache adequado
- [ ] Compressão gzip está funcionando
- [ ] Headers de segurança estão presentes
- [ ] Rate limiting está ativo
- [ ] Performance melhorou em pelo menos 20%

## Comandos de Teste
```bash
# Testar compressão
curl -H "Accept-Encoding: gzip" -I http://localhost/css/style.css

# Testar headers de segurança
curl -I http://localhost/

# Testar cache
curl -I http://localhost/static/image.png

# Testar rate limiting
for i in {1..15}; do curl http://localhost/api; done
```

## Notas para LLM
- Manter compatibilidade com s6-overlay
- Testar cada configuração individualmente
- Verificar logs do nginx após mudanças
- Considerar impacto na performance do backend
- Documentar configurações no README.md
