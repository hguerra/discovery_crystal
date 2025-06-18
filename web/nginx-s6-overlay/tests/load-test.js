import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Métricas customizadas
const errorRate = new Rate('errors');

// Configuração do teste
export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Rampa de subida
    { duration: '1m', target: 50 },   // Carga constante
    { duration: '30s', target: 0 },   // Rampa de descida
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% das requisições devem ser < 500ms
    http_req_failed: ['rate<0.1'],    // Taxa de erro < 10%
    errors: ['rate<0.1'],             // Taxa de erro customizada < 10%
  },
};

// Função principal do teste
export default function () {
  // Teste 1: Health Check com Load Balancing
  const healthResponse = http.get('http://localhost:8080/api/health');

  check(healthResponse, {
    'health check status is 200': (r) => r.status === 200,
    'health check has instance_id': (r) => r.json('instance_id') !== undefined,
    'health check has status healthy': (r) => r.json('status') === 'healthy',
    'response time < 200ms': (r) => r.timings.duration < 200,
  });

  // Registrar erro se status não for 200
  errorRate.add(healthResponse.status !== 200);

  // Teste 2: API Principal
  const apiResponse = http.get('http://localhost:8080/api');

  check(apiResponse, {
    'api status is 200': (r) => r.status === 200,
    'api response contains instance': (r) => r.body.includes('instance'),
    'response time < 300ms': (r) => r.timings.duration < 300,
  });

  errorRate.add(apiResponse.status !== 200);

  // Teste 3: Métricas
  const metricsResponse = http.get('http://localhost:8080/api/metrics');

  check(metricsResponse, {
    'metrics status is 200': (r) => r.status === 200,
    'metrics contains prometheus format': (r) => r.body.includes('http_requests_total'),
    'response time < 200ms': (r) => r.timings.duration < 200,
  });

  errorRate.add(metricsResponse.status !== 200);

  // Teste 4: Site Público
  const publicResponse = http.get('http://localhost:8080/');

  check(publicResponse, {
    'public site status is 200': (r) => r.status === 200,
    'public site contains HTML': (r) => r.body.includes('<html'),
    'public site contains "Site Público"': (r) => r.body.includes('Site Público'),
    'response time < 100ms': (r) => r.timings.duration < 100,
  });

  errorRate.add(publicResponse.status !== 200);

  // Teste 5: Área Logada (SPA)
  const appResponse = http.get('http://localhost:8080/app');

  check(appResponse, {
    'app area status is 200': (r) => r.status === 200,
    'app area contains HTML': (r) => r.body.includes('<html'),
    'app area contains "Área Logada"': (r) => r.body.includes('Área Logada'),
    'response time < 150ms': (r) => r.timings.duration < 150,
  });

  errorRate.add(appResponse.status !== 200);

  // Teste 6: Arquivo estático (logo.svg)
  const staticResponse = http.get('http://localhost:8080/logo.svg');

  check(staticResponse, {
    'static file status is 200': (r) => r.status === 200,
    'static file has cache headers': (r) => r.headers['Cache-Control'] !== undefined,
    'response time < 50ms': (r) => r.timings.duration < 50,
  });

  errorRate.add(staticResponse.status !== 200);

  // Pausa entre requisições
  sleep(1);
}

// Função executada no início do teste
export function setup() {
  console.log('🚀 Iniciando teste de carga para nginx-s6-overlay');
  console.log('📊 Testando load balancing entre 3 instâncias Crystal');
  console.log('🌐 Testando site público (/) e área logada (/app)');
  console.log('⏱️  Duração total: 2 minutos');
}

// Função executada no final do teste
export function teardown(data) {
  console.log('✅ Teste de carga concluído');
  console.log('📈 Verifique os resultados para validar o load balancing');
  console.log('🌐 URLs testadas:');
  console.log('   - Site público: http://localhost:8080/');
  console.log('   - Área logada: http://localhost:8080/app');
  console.log('   - API: http://localhost:8080/api');
}
