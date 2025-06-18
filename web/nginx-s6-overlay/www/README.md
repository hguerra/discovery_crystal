# Estrutura de Diretórios WWW

Este diretório contém os arquivos estáticos da aplicação, organizados em duas áreas principais:

## 📁 Estrutura Atual

```
www/
├── public/          # Site público externo
│   ├── index.html   # Landing page pública
│   └── logo.svg     # Logo da aplicação
├── app/             # SPA React para área logada
│   └── index.html   # Página inicial da área logada
└── README.md        # Esta documentação
```

## 🌐 URLs da Aplicação

### Site Público
- **URL**: `http://localhost:8080/`
- **Diretório**: `www/public/`
- **Descrição**: Landing page pública com informações sobre o projeto
- **Características**:
  - Design responsivo e moderno
  - Navegação para área logada
  - Teste de API em tempo real
  - Informações sobre funcionalidades

### Área Logada
- **URL**: `http://localhost:8080/app`
- **Diretório**: `www/app/`
- **Descrição**: SPA (Single Page Application) para usuários logados
- **Características**:
  - Interface moderna com gradiente
  - Teste de conectividade com API
  - Navegação entre áreas
  - Informações do sistema em tempo real

## 🔧 Configuração Nginx

A configuração nginx (`rootfs/etc/nginx/conf.d/default.conf`) foi atualizada para suportar:

### Site Público (`/`)
```nginx
location / {
    root /var/www/html/public;
    index index.html;
    try_files $uri $uri/ =404;
}
```

### Área Logada (`/app`)
```nginx
location /app {
    alias /var/www/html/app;
    try_files $uri $uri/ /app/index.html;
}
```

## 🚀 Próximos Passos

### Para o Site Público (`public/`)
- [ ] Adicionar mais páginas (sobre, contato, etc.)
- [ ] Implementar SEO otimizado
- [ ] Adicionar formulários de contato
- [ ] Integrar analytics

### Para a Área Logada (`app/`)
- [ ] Implementar SPA React completa
- [ ] Adicionar sistema de autenticação
- [ ] Criar dashboard interativo
- [ ] Implementar funcionalidades específicas

## 🧪 Testes

Os testes foram atualizados para incluir a nova estrutura:

### Teste Simples
```bash
make test-simple
```
- Testa site público (`/`)
- Testa área logada (`/app`)
- Valida load balancing da API

### Teste de Carga
```bash
make test
```
- Testa performance de ambas as áreas
- Valida cache e compressão
- Verifica rate limiting

## 📋 Comandos Úteis

```bash
# Build e execução
make build
make run

# Testes
make test-simple    # Teste rápido (10s)
make test           # Teste de carga (2min)

# Logs
make logs

# Parar container
make stop
```

## 🔒 Segurança

### Headers de Segurança
- **Site Público**: Headers padrão de segurança
- **Área Logada**: Headers mais restritivos (X-Frame-Options: DENY)

### Rate Limiting
- **Site Público**: 100 r/s
- **Área Logada**: 20 r/s
- **API**: 10 r/s

## 📈 Performance

### Cache
- Arquivos estáticos: 1 ano
- Headers: `Cache-Control: public, immutable, max-age=31536000`

### Compressão
- Gzip habilitado para tipos de conteúdo apropriados
- Tamanho mínimo: 1024 bytes

## 🎯 Benefícios da Nova Estrutura

1. **Separação Clara**: Conteúdo público vs. privado
2. **Escalabilidade**: Fácil adicionar novas áreas
3. **Segurança**: Headers específicos por área
4. **Performance**: Cache otimizado por tipo de conteúdo
5. **Manutenibilidade**: Estrutura organizada e documentada
