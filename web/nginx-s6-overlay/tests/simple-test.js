#!/usr/bin/env node

/**
 * Teste Simples - nginx-s6-overlay
 *
 * Script Node.js para verificar se as APIs e páginas estão funcionando.
 * Usa fetch API (disponível no Node.js 18+) para requisições HTTP.
 */

// Configuração
const BASE_URL = 'http://localhost:8080';
const TIMEOUT = 5000; // 5 segundos

// Cores para output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

// Função para imprimir mensagens coloridas
function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// Função para fazer requisição HTTP usando fetch
async function makeRequest(path, description) {
  const url = `${BASE_URL}${path}`;
  const startTime = Date.now();

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), TIMEOUT);

    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'nginx-s6-overlay-test/1.0'
      }
    });

    clearTimeout(timeoutId);

    const duration = Date.now() - startTime;
    const data = await response.text();

    return {
      success: response.ok,
      statusCode: response.status,
      duration,
      data,
      headers: Object.fromEntries(response.headers.entries()),
      description
    };
  } catch (error) {
    const duration = Date.now() - startTime;

    if (error.name === 'AbortError') {
      return {
        success: false,
        statusCode: 0,
        duration,
        error: 'Timeout',
        description
      };
    }

    return {
      success: false,
      statusCode: 0,
      duration,
      error: error.message,
      description
    };
  }
}

// Função para testar load balancing
async function testLoadBalancing() {
  log('\n🔄 Testando Load Balancing...', 'cyan');

  const instances = new Set();
  const results = [];

  // Fazer 10 requisições para verificar distribuição
  for (let i = 0; i < 10; i++) {
    try {
      const result = await makeRequest('/api/health', `Health check ${i + 1}`);

      if (result.success) {
        try {
          const healthData = JSON.parse(result.data);
          if (healthData.instance_id) {
            instances.add(healthData.instance_id);
            log(`  ✓ Instância ${healthData.instance_id} respondendo`, 'green');
          }
        } catch (e) {
          log(`  ⚠️  Resposta não é JSON válido: ${result.data.substring(0, 100)}`, 'yellow');
        }
      } else {
        log(`  ✗ Erro na requisição ${i + 1}: ${result.error || `Status ${result.statusCode}`}`, 'red');
      }

      results.push(result);
    } catch (error) {
      log(`  ✗ Erro na requisição ${i + 1}: ${error.message}`, 'red');
    }

    // Pequena pausa entre requisições
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  log(`\n📊 Resultado do Load Balancing:`, 'blue');
  log(`  Instâncias únicas detectadas: ${instances.size}`, instances.size >= 2 ? 'green' : 'yellow');
  log(`  IDs das instâncias: ${Array.from(instances).join(', ')}`, 'cyan');

  if (instances.size >= 2) {
    log('  ✅ Load balancing funcionando corretamente!', 'green');
  } else if (instances.size === 1) {
    log('  ⚠️  Apenas uma instância detectada - verificar configuração', 'yellow');
  } else {
    log('  ❌ Nenhuma instância respondendo - verificar se o container está rodando', 'red');
  }
}

// Função principal de testes
async function runTests() {
  log('🧪 Teste Simples - nginx-s6-overlay', 'bright');
  log('=====================================', 'bright');

  const tests = [
    { path: '/', description: 'Site público (index.html)', expectedStatus: 200 },
    { path: '/app', description: 'Área logada (SPA)', expectedStatus: 200 },
    { path: '/api', description: 'API principal', expectedStatus: 200 },
    { path: '/api/health', description: 'Health check', expectedStatus: 200 },
    { path: '/api/metrics', description: 'Métricas Prometheus', expectedStatus: 200 },
    { path: '/logo.svg', description: 'Arquivo estático (logo.svg)', expectedStatus: 200 },
    { path: '/nonexistent', description: 'Página inexistente (404)', expectedStatus: 404 }
  ];

  let passedTests = 0;
  let totalTests = tests.length;

  log('\n📋 Executando testes básicos...', 'blue');

  for (const test of tests) {
    try {
      const result = await makeRequest(test.path, test.description);

      const isExpectedStatus = result.statusCode === test.expectedStatus;

      if (isExpectedStatus) {
        log(`  ✅ ${test.description}`, 'green');
        log(`     Status: ${result.statusCode}`, 'cyan');
        log(`     Tempo: ${result.duration}ms`, 'cyan');

        // Verificações específicas
        if (test.path === '/') {
          if (result.data.includes('<html') && result.data.includes('Site Público')) {
            log(`     ✓ Site público carregado corretamente`, 'green');
          } else {
            log(`     ⚠️  Não parece ser o site público esperado`, 'yellow');
          }
        } else if (test.path === '/app') {
          if (result.data.includes('<html') && result.data.includes('Área Logada')) {
            log(`     ✓ Área logada carregada corretamente`, 'green');
          } else {
            log(`     ⚠️  Não parece ser a área logada esperada`, 'yellow');
          }
        } else if (test.path === '/api/health') {
          try {
            const healthData = JSON.parse(result.data);
            if (healthData.status === 'healthy' && healthData.instance_id) {
              log(`     ✓ Health check válido (instância ${healthData.instance_id})`, 'green');
            } else {
              log(`     ⚠️  Health check com formato inesperado`, 'yellow');
            }
          } catch (e) {
            log(`     ⚠️  Health check não é JSON válido`, 'yellow');
          }
        } else if (test.path === '/api/metrics') {
          if (result.data.includes('http_requests_total')) {
            log(`     ✓ Métricas Prometheus válidas`, 'green');
          } else {
            log(`     ⚠️  Métricas não estão no formato Prometheus`, 'yellow');
          }
        } else if (test.path === '/logo.svg') {
          if (result.headers['cache-control']) {
            log(`     ✓ Headers de cache presentes`, 'green');
          } else {
            log(`     ⚠️  Headers de cache ausentes`, 'yellow');
          }
        } else if (test.path === '/nonexistent') {
          log(`     ✓ 404 retornado corretamente`, 'green');
        }

        passedTests++;
      } else {
        log(`  ❌ ${test.description}`, 'red');
        log(`     Status: ${result.statusCode} (esperado: ${test.expectedStatus})`, 'red');
        log(`     Tempo: ${result.duration}ms`, 'red');
      }
    } catch (error) {
      log(`  ❌ ${test.description}`, 'red');
      log(`     Erro: ${error.message}`, 'red');
    }

    // Pequena pausa entre testes
    await new Promise(resolve => setTimeout(resolve, 200));
  }

  // Teste de load balancing
  await testLoadBalancing();

  // Resumo final
  log('\n📊 Resumo dos Testes', 'bright');
  log('====================', 'bright');
  log(`Testes básicos: ${passedTests}/${totalTests} passaram`, passedTests === totalTests ? 'green' : 'yellow');

  if (passedTests === totalTests) {
    log('🎉 Todos os testes passaram! O sistema está funcionando corretamente.', 'green');
  } else {
    log('⚠️  Alguns testes falharam. Verifique se o container está rodando corretamente.', 'yellow');
  }

  log('\n💡 Dicas:', 'blue');
  log('  - Execute "make run" para iniciar o container', 'cyan');
  log('  - Execute "make logs" para ver os logs', 'cyan');
  log('  - Execute "make stop" para parar o container', 'cyan');
  log('  - Execute "make test-simple" para executar este teste', 'cyan');
  log('  - Acesse http://localhost:8080 para o site público', 'cyan');
  log('  - Acesse http://localhost:8080/app para a área logada', 'cyan');
}

// Verificar se o script foi chamado diretamente
if (require.main === module) {
  runTests().catch(error => {
    log(`\n❌ Erro fatal: ${error.message}`, 'red');
    process.exit(1);
  });
}

module.exports = { runTests, makeRequest, testLoadBalancing };
