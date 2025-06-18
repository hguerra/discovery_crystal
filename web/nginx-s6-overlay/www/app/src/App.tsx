import { useState, useEffect } from 'react'
import './App.css'

interface HealthData {
  status: string
  instance_id: string
  timestamp: string
  uptime: number
  requests_total: number
}

function App() {
  const [count, setCount] = useState(0)
  const [healthData, setHealthData] = useState<HealthData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchHealthData()
    const interval = setInterval(fetchHealthData, 10000) // Atualizar a cada 10 segundos
    return () => clearInterval(interval)
  }, [])

  const fetchHealthData = async () => {
    try {
      setLoading(true)
      const response = await fetch('/api/health')
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      const data = await response.json()
      setHealthData(data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro desconhecido')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="app">
      {/* Hero Section com Imagem */}
      <div className="hero">
        <div className="hero-content">
          <h1>🚀 nginx-s6-overlay</h1>
          <p>Arquitetura moderna com Crystal + React + Nginx</p>
          <img
            src="/app/hero-image.jpg"
            alt="Hero Image"
            className="hero-image"
          />
        </div>
      </div>

      {/* Main Content */}
      <div className="main-content">
        {/* Counter Section */}
        <div className="card">
          <h2>🎯 Contador Interativo</h2>
          <div className="counter-section">
            <button onClick={() => setCount(count + 1)} className="counter-button">
              Contador: {count}
            </button>
            <p>Clique no botão para testar a interatividade do React</p>
          </div>
        </div>

        {/* API Health Section */}
        <div className="card">
          <h2>🏥 Status da API Crystal</h2>
          <div className="api-section">
            {loading && <div className="loading">Carregando dados da API...</div>}
            {error && <div className="error">Erro: {error}</div>}
            {healthData && (
              <div className="health-data">
                <div className="health-item">
                  <strong>Status:</strong>
                  <span className={`status ${healthData.status}`}>
                    {healthData.status}
                  </span>
                </div>
                <div className="health-item">
                  <strong>Instância:</strong> {healthData.instance_id}
                </div>
                <div className="health-item">
                  <strong>Uptime:</strong> {healthData.uptime}s
                </div>
                <div className="health-item">
                  <strong>Requests:</strong> {healthData.requests_total}
                </div>
                <div className="health-item">
                  <strong>Timestamp:</strong> {new Date(healthData.timestamp).toLocaleString('pt-BR')}
                </div>
              </div>
            )}
            <button onClick={fetchHealthData} className="refresh-button">
              🔄 Atualizar
            </button>
          </div>
        </div>

        {/* Features Section */}
        <div className="card">
          <h2>✨ Funcionalidades</h2>
          <div className="features-grid">
            <div className="feature">
              <h3>⚡ Performance</h3>
              <p>Backend Crystal com 3 instâncias e load balancing nginx</p>
            </div>
            <div className="feature">
              <h3>🔒 Segurança</h3>
              <p>Headers de segurança, rate limiting e usuário não-root</p>
            </div>
            <div className="feature">
              <h3>📈 Monitoramento</h3>
              <p>Logs estruturados em JSON e métricas Prometheus</p>
            </div>
            <div className="feature">
              <h3>🧪 Testes</h3>
              <p>Sistema completo de testes simples e de carga</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
