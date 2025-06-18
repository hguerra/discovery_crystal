# Tarefa 1: Otimização do Dockerfile

## Objetivo
Otimizar o Dockerfile para reduzir o tamanho da imagem, melhorar a segurança e acelerar os builds.

## Prioridade: ALTA
## Complexidade: MÉDIA
## Tempo Estimado: 2-3 horas

## Subtarefas

### 1.1 Criar .dockerignore
**Objetivo**: Excluir arquivos desnecessários do contexto de build
**Arquivos a modificar**: `.dockerignore` (novo)
**Comandos necessários**: `touch .dockerignore`

**Conteúdo do .dockerignore**:
```
.git
.gitignore
README.md
.cursor
spec/
*.md
Dockerfile
Makefile
.env*
```

### 1.2 Otimizar multi-stage build
**Objetivo**: Reduzir número de camadas e tamanho final
**Arquivos a modificar**: `Dockerfile`
**Linhas a alterar**: 1-35

**Mudanças específicas**:
- Combinar comandos RUN relacionados
- Usar `--no-cache-dir` para apt-get
- Adicionar `--chown` nos comandos COPY
- Remover arquivos temporários no mesmo RUN

### 1.3 Implementar usuário não-root
**Objetivo**: Melhorar segurança da aplicação
**Arquivos a modificar**: `Dockerfile`
**Linhas a adicionar**: Após linha 15

**Comandos a adicionar**:
```dockerfile
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser
```

### 1.4 Adicionar health check
**Objetivo**: Permitir monitoramento da saúde do container
**Arquivos a modificar**: `Dockerfile`
**Linhas a adicionar**: Antes do ENTRYPOINT

**Comando a adicionar**:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/api/health || exit 1
```

### 1.5 Otimizar ordem das camadas
**Objetivo**: Melhorar cache do Docker
**Arquivos a modificar**: `Dockerfile`
**Estratégia**: Mover arquivos que mudam menos para o início

## Critérios de Aceitação
- [ ] Imagem final menor que 150MB
- [ ] Build time reduzido em pelo menos 30%
- [ ] Container roda com usuário não-root
- [ ] Health check funciona corretamente
- [ ] Não há regressões funcionais

## Comandos de Teste
```bash
# Build da imagem
docker build -t myapp:optimized .

# Verificar tamanho
docker images myapp:optimized

# Testar health check
docker run -d --name test-app myapp:optimized
docker inspect --format='{{.State.Health.Status}}' test-app

# Verificar usuário
docker exec test-app whoami
```

## Notas para LLM
- Manter compatibilidade com s6-overlay
- Preservar funcionalidade de proxy do nginx
- Testar cada mudança incrementalmente
- Documentar mudanças no README.md
