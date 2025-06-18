# Guia s6-overlay no Projeto nginx-s6-overlay

## O que é s6-overlay?

O **s6-overlay** é uma camada de orquestração de processos para containers Linux, baseada no supervisor s6. Ele permite rodar múltiplos serviços (processos) de forma robusta, segura e com reinício automático, sendo ideal para containers Docker que precisam de mais de um processo rodando simultaneamente (ex: nginx + backend).

---

## Vantagens do s6-overlay

- **Multi-processo real**: Permite rodar vários serviços no mesmo container, cada um isolado e monitorado.
- **Reinício automático**: Se um serviço falha, o s6-overlay reinicia automaticamente.
- **Ordem de inicialização**: Permite definir dependências entre serviços.
- **Logs claros**: Cada serviço pode ter seu próprio log, facilitando troubleshooting.
- **Compatível com Docker/Kubernetes**: Segue boas práticas de containers.
- **Graceful shutdown**: Envia sinais corretos para todos os processos ao parar o container.
- **Configuração simples**: Baseada em arquivos e scripts shell.

---

## Tradeoffs

- **Leve aumento de complexidade**: Precisa estruturar scripts e pastas para cada serviço.
- **Mais arquivos de configuração**: Cada serviço requer pelo menos um script `run` e, idealmente, um arquivo `type`.
- **Não substitui um init system completo**: Para casos muito complexos, pode ser necessário algo mais robusto.
- **Debug inicial**: Pode ser necessário ajustar permissões e variáveis de ambiente para cada serviço.

---

## Estrutura de Serviços neste Projeto

```
rootfs/etc/services.d/
├── crystal-api-1/
│   ├── run      # Script que inicia a instância 1 do backend Crystal
│   └── type     # Indica que é um serviço longrun
├── crystal-api-2/
│   ├── run      # Instância 2
│   └── type
├── crystal-api-3/
│   ├── run      # Instância 3
│   └── type
└── nginx/
    ├── run      # Script que inicia o nginx
    └── type     # Indica que é um serviço longrun
```

### Exemplo de script `run` (Crystal):
```bash
#!/bin/bash
echo "Starting Crystal API instance 1 on port 3001..."
export PORT=3001
export INSTANCE_ID=1
exec /usr/bin/my-api
```

### Exemplo de script `run` (nginx):
```bash
#!/bin/bash
exec nginx -g "daemon off;"
```

### Exemplo de arquivo `type`:
```
longrun
```

---

## Como o s6-overlay funciona neste projeto

1. **Ao iniciar o container**, o s6-overlay lê todas as subpastas de `/etc/services.d/`.
2. Para cada subpasta (serviço):
   - Executa o script `run` como processo principal do serviço.
   - Usa o arquivo `type` para saber que é um serviço contínuo (`longrun`).
3. Se algum serviço falhar, o s6-overlay reinicia automaticamente.
4. O container só é considerado "pronto" quando todos os serviços `longrun` estão rodando.
5. Ao receber um sinal de parada, o s6-overlay envia SIGTERM/SIGINT para todos os serviços, permitindo shutdown limpo.

---

## Configurações e Boas Práticas Adotadas

- **Um serviço por pasta**: Cada processo (nginx, cada instância Crystal) tem sua própria pasta.
- **Arquivo `type` presente**: Todos os serviços contínuos têm o arquivo `type` com valor `longrun`.
- **Scripts `run` simples e explícitos**: Usam `exec` para garantir que o processo substitua o shell.
- **Variáveis de ambiente**: Usadas para parametrizar porta e ID das instâncias Crystal.
- **Permissões**: Todos os scripts e binários têm permissão de execução para o usuário do container.
- **Logs direcionados para stdout/stderr**: Seguindo boas práticas de containers.
- **Sem processos em background**: O `exec` garante que o processo principal seja monitorado pelo s6-overlay.
- **Remoção do serviço antigo `app`**: Para evitar conflitos e garantir clareza na orquestração.

---

## Integração com nginx e Crystal

- **nginx**: Roda como serviço `longrun`, servindo estáticos e fazendo proxy para as instâncias Crystal.
- **Crystal**: Três instâncias, cada uma rodando em uma porta diferente (3001, 3002, 3003), todas monitoradas pelo s6-overlay.
- **Load balancing**: O nginx faz balanceamento entre as instâncias Crystal via upstream.

---

## Dependências entre Serviços

### Configuração de Dependências

Para definir que um serviço deve aguardar outro, crie um arquivo `dependencies`:

```bash
# rootfs/etc/services.d/nginx/dependencies
crystal-api-1
crystal-api-2
crystal-api-3
```

Isso fará o nginx aguardar todas as instâncias Crystal estarem prontas antes de iniciar.

### Ordem de Inicialização Recomendada

1. **crystal-api-1, crystal-api-2, crystal-api-3**: Iniciam em paralelo
2. **nginx**: Aguarda as instâncias Crystal estarem prontas

### Exemplo de arquivo `dependencies`:
```
# Formato: um serviço por linha
crystal-api-1
crystal-api-2
crystal-api-3
```

---

## Monitoramento e Observabilidade

### Verificar Status dos Serviços

```bash
# Ver todos os processos rodando
docker exec myapp_local ps aux

# Ver logs do s6-overlay
docker logs myapp_local | grep s6

# Ver logs específicos de um serviço
docker exec myapp_local cat /var/log/s6-overlay/crystal-api-1.log
```

### Health Checks

```bash
# Testar health check de cada instância
curl http://localhost:3001/api/health
curl http://localhost:3002/api/health
curl http://localhost:3003/api/health

# Testar load balancing
for i in {1..10}; do
  curl -s http://localhost:8080/api/health | jq -r '.instance_id'
done
```

### Métricas

```bash
# Ver métricas de cada instância
curl http://localhost:3001/api/metrics
curl http://localhost:3002/api/metrics
curl http://localhost:3003/api/metrics
```

---

## Troubleshooting

### Problemas Comuns

#### 1. Serviço não inicia

**Sintomas:**
- Logs mostram "Starting..." mas processo não fica rodando
- Erro 502 Bad Gateway no nginx

**Soluções:**
```bash
# Verificar permissões
docker exec myapp_local ls -la /usr/bin/my-api
docker exec myapp_local ls -la /etc/services.d/crystal-api-1/run

# Testar script manualmente
docker exec myapp_local /etc/services.d/crystal-api-1/run

# Verificar se binário funciona
docker exec myapp_local /usr/bin/my-api --help
```

#### 2. Conflito de Portas

**Sintomas:**
- Erro "Address already in use"
- Apenas uma instância Crystal responde

**Soluções:**
```bash
# Verificar portas em uso
docker exec myapp_local netstat -tlnp

# Verificar se processos estão rodando
docker exec myapp_local ps aux | grep my-api
```

#### 3. Nginx não consegue conectar nas instâncias Crystal

**Sintomas:**
- Erro 502 Bad Gateway
- Logs nginx mostram "Connection refused"

**Soluções:**
```bash
# Verificar se instâncias estão rodando
docker exec myapp_local curl http://localhost:3001/api/health
docker exec myapp_local curl http://localhost:3002/api/health
docker exec myapp_local curl http://localhost:3003/api/health

# Verificar configuração nginx
docker exec myapp_local nginx -t
```

#### 4. Permissões de Usuário

**Sintomas:**
- Erro "Permission denied"
- Processos não iniciam

**Soluções:**
```bash
# Verificar usuário do container
docker exec myapp_local whoami

# Ajustar permissões no Dockerfile
RUN chown appuser:appuser /usr/bin/my-api && chmod +x /usr/bin/my-api
```

### Debug Avançado

#### Verificar Logs Detalhados

```bash
# Logs do container
docker logs myapp_local

# Logs do s6-overlay
docker exec myapp_local cat /var/log/s6-overlay.log

# Logs do nginx
docker exec myapp_local tail -f /var/log/nginx/error.log

# Logs do Crystal (via stdout)
docker logs myapp_local | grep "Crystal"
```

#### Testar Serviços Isoladamente

```bash
# Testar nginx isoladamente
docker run --rm nginx:1.27-bookworm nginx -t

# Testar Crystal isoladamente
docker exec myapp_local timeout 5 /usr/bin/my-api

# Testar script de serviço
docker exec myapp_local bash -c "cd /tmp && /etc/services.d/crystal-api-1/run"
```

#### Verificar Configuração s6-overlay

```bash
# Ver estrutura de serviços
docker exec myapp_local ls -la /etc/services.d/

# Ver conteúdo dos scripts
docker exec myapp_local cat /etc/services.d/crystal-api-1/run
docker exec myapp_local cat /etc/services.d/crystal-api-1/type

# Ver variáveis de ambiente
docker exec myapp_local env | grep PORT
docker exec myapp_local env | grep INSTANCE
```

---

## Exemplos Práticos

### Adicionar um Novo Serviço

1. **Criar pasta do serviço:**
```bash
mkdir -p rootfs/etc/services.d/novo-servico
```

2. **Criar script run:**
```bash
# rootfs/etc/services.d/novo-servico/run
#!/bin/bash
echo "Starting novo-servico..."
exec /usr/bin/novo-servico
```

3. **Criar arquivo type:**
```bash
# rootfs/etc/services.d/novo-servico/type
longrun
```

4. **Atualizar Dockerfile:**
```dockerfile
RUN chmod +x /etc/services.d/novo-servico/run
```

### Configurar Dependências

```bash
# rootfs/etc/services.d/nginx/dependencies
crystal-api-1
crystal-api-2
crystal-api-3
novo-servico
```

### Script de Debug

```bash
#!/bin/bash
# debug-services.sh
echo "=== Status dos Serviços ==="
docker exec myapp_local ps aux | grep -E "(nginx|my-api)"

echo -e "\n=== Portas em Uso ==="
docker exec myapp_local netstat -tlnp | grep -E "(80|3001|3002|3003)"

echo -e "\n=== Health Checks ==="
for port in 3001 3002 3003; do
  echo "Porta $port:"
  docker exec myapp_local curl -s http://localhost:$port/api/health | jq -r '.instance_id'
done

echo -e "\n=== Load Balancing ==="
for i in {1..5}; do
  curl -s http://localhost:8080/api/health | jq -r '.instance_id'
done
```

---

## Resumo dos Arquivos Criados/Alterados

- `rootfs/etc/services.d/crystal-api-1/run` e `type`
- `rootfs/etc/services.d/crystal-api-2/run` e `type`
- `rootfs/etc/services.d/crystal-api-3/run` e `type`
- `rootfs/etc/services.d/nginx/run` e `type`

---

## Referências
- [Documentação oficial do s6-overlay](https://github.com/just-containers/s6-overlay)
- [Boas práticas Docker multi-processo](https://docs.docker.com/config/containers/multi-service_container/)
- [Troubleshooting s6-overlay](https://github.com/just-containers/s6-overlay#troubleshooting)

---

Se precisar adicionar mais serviços, basta criar uma nova pasta em `/etc/services.d/`, adicionar um script `run` e (recomendado) um arquivo `type` com o valor `longrun`.
