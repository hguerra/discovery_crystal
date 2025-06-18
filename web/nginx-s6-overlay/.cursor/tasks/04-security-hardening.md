# Tarefa 4: Hardening de Segurança

## Objetivo
Implementar medidas de segurança para proteger a aplicação contra ataques comuns.

## Prioridade: MÉDIA
## Complexidade: ALTA
## Tempo Estimado: 2-4 horas

## Subtarefas

### 4.1 Implementar secrets management básico
**Objetivo**: Gerenciar configurações sensíveis de forma segura
**Arquivos a modificar**: `Dockerfile`, `rootfs/etc/services.d/app/run`
**Linhas a alterar**: Várias

**Implementação**:
```dockerfile
# Criar diretório para secrets
RUN mkdir -p /run/secrets && chown appuser:appuser /run/secrets
```

**Script de inicialização**:
```bash
#!/bin/bash
# Carregar secrets do Docker secrets
if [ -f /run/secrets/db_password ]; then
  export DB_PASSWORD=$(cat /run/secrets/db_password)
fi
exec /usr/bin/my-api
```

### 4.2 Configurar network policies
**Objetivo**: Restringir comunicação de rede desnecessária
**Arquivos a modificar**: `Dockerfile`
**Linhas a adicionar**: Após health check

**Configurações**:
```dockerfile
# Expor apenas portas necessárias
EXPOSE 80

# Configurar usuário não-root (já implementado na tarefa 1)
# Adicionar capabilities mínimas
```

### 4.3 Implementar logging de auditoria
**Objetivo**: Registrar atividades suspeitas
**Arquivos a modificar**: `rootfs/etc/nginx/conf.d/default.conf`
**Linhas a adicionar**: Dentro do bloco server

**Configuração de logging**:
```nginx
# Log de auditoria
log_format audit '$remote_addr - $remote_user [$time_local] '
                 '"$request" $status $body_bytes_sent '
                 '"$http_referer" "$http_user_agent" '
                 'rt=$request_time uct="$upstream_connect_time" '
                 'uht="$upstream_header_time" urt="$upstream_response_time"';

access_log /var/log/nginx/audit.log audit;
```

### 4.4 Adicionar scanning de vulnerabilidades
**Objetivo**: Detectar vulnerabilidades na imagem
**Arquivos a modificar**: `Makefile`
**Linhas a adicionar**: Após linha 21

**Comandos a adicionar**:
```makefile
# Scanning de vulnerabilidades
scan:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		-v $(PWD):/workspace \
		-aquasec/trivy image $(IMAGE_NAME)

# Verificar secrets expostos
secrets-scan:
	docker run --rm -v $(PWD):/workspace \
		-aquasec/trivy fs /workspace
```

### 4.5 Implementar timeouts e rate limiting avançado
**Objetivo**: Proteger contra ataques de força bruta
**Arquivos a modificar**: `rootfs/etc/nginx/conf.d/default.conf`
**Linhas a adicionar**: Após rate limiting básico

**Configurações avançadas**:
```nginx
# Rate limiting por IP e endpoint
limit_req zone=api burst=20 nodelay;
limit_req zone=static burst=100 nodelay;

# Timeouts de segurança
client_body_timeout 10s;
client_header_timeout 10s;
keepalive_timeout 65s;
send_timeout 10s;
```

## Critérios de Aceitação
- [ ] Secrets são gerenciados de forma segura
- [ ] Network policies estão ativas
- [ ] Logs de auditoria estão funcionando
- [ ] Scanning não detecta vulnerabilidades críticas
- [ ] Rate limiting protege contra ataques

## Comandos de Teste
```bash
# Testar secrets management
echo "test123" | docker secret create db_password -
docker run --rm --secret db_password myapp:secure

# Executar scan de vulnerabilidades
make scan

# Testar rate limiting
ab -n 100 -c 10 http://localhost/api

# Verificar logs de auditoria
docker exec container_name tail -f /var/log/nginx/audit.log
```

## Notas para LLM
- Manter compatibilidade com funcionalidades existentes
- Testar cada medida de segurança individualmente
- Documentar impactos na performance
- Considerar false positives nos scans
- Implementar gradualmente para evitar quebras
