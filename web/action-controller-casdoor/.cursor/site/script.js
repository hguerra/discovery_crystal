// Inicialização quando DOM carrega
document.addEventListener('DOMContentLoaded', function() {
    initializeNavigation();
    initializeSyntaxHighlighting();
    initializeScrollEffects();
    initializeCodeCopyButtons();
    initializeSearchFunctionality();
    initializeThemeToggle();
});

// Navegação móvel
function initializeNavigation() {
    const hamburger = document.querySelector('.hamburger');
    const navMenu = document.querySelector('.nav-menu');

    if (hamburger && navMenu) {
        hamburger.addEventListener('click', function() {
            hamburger.classList.toggle('active');
            navMenu.classList.toggle('active');
        });

        // Fechar menu ao clicar em link
        document.querySelectorAll('.nav-menu a').forEach(link => {
            link.addEventListener('click', () => {
                hamburger.classList.remove('active');
                navMenu.classList.remove('active');
            });
        });
    }

    // Scroll spy para navegação ativa
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-menu a');

    window.addEventListener('scroll', () => {
        let current = '';
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            if (pageYOffset >= sectionTop - 200) {
                current = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${current}`) {
                link.classList.add('active');
            }
        });
    });
}

// Inicializar highlight.js
function initializeSyntaxHighlighting() {
    if (typeof hljs !== 'undefined') {
        hljs.highlightAll();

        // Adicionar numeração de linhas
        document.querySelectorAll('pre code').forEach((block) => {
            const lines = block.innerHTML.split('\n');
            if (lines.length > 1) {
                const numberedLines = lines.map((line, index) => {
                    return `<span class="line-number">${index + 1}</span>${line}`;
                });
                block.innerHTML = numberedLines.join('\n');
            }
        });
    }
}

// Efeitos de scroll e animações
function initializeScrollEffects() {
    // Fade in ao scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in-up');
            }
        });
    }, observerOptions);

    // Observar subsections
    document.querySelectorAll('.subsection').forEach(section => {
        observer.observe(section);
    });

    // Scroll suave para links internos
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Navbar transparente no topo
    const navbar = document.querySelector('.navbar');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 100) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    });
}

// Botões de copiar código
function initializeCodeCopyButtons() {
    document.querySelectorAll('pre').forEach(pre => {
        const button = document.createElement('button');
        button.className = 'copy-button';
        button.innerHTML = '📋 Copiar';
        button.title = 'Copiar código';

        button.addEventListener('click', async () => {
            const code = pre.querySelector('code').textContent;
            try {
                await navigator.clipboard.writeText(code);
                button.innerHTML = '✅ Copiado!';
                setTimeout(() => {
                    button.innerHTML = '📋 Copiar';
                }, 2000);
            } catch (err) {
                console.error('Erro ao copiar:', err);
                button.innerHTML = '❌ Erro';
                setTimeout(() => {
                    button.innerHTML = '📋 Copiar';
                }, 2000);
            }
        });

        pre.style.position = 'relative';
        pre.appendChild(button);
    });
}

// Funcionalidade de busca
function initializeSearchFunctionality() {
    // Criar modal de busca
    const searchModal = document.createElement('div');
    searchModal.className = 'search-modal';
    searchModal.innerHTML = `
        <div class="search-content">
            <div class="search-header">
                <input type="text" id="search-input" placeholder="Buscar no guia..." />
                <button id="search-close">×</button>
            </div>
            <div class="search-results" id="search-results"></div>
        </div>
    `;
    document.body.appendChild(searchModal);

    // Atalho de teclado Ctrl+K
    document.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            openSearch();
        }
        if (e.key === 'Escape') {
            closeSearch();
        }
    });

    // Handlers dos botões
    document.getElementById('search-close').addEventListener('click', closeSearch);
    document.getElementById('search-input').addEventListener('input', handleSearch);

    function openSearch() {
        searchModal.style.display = 'flex';
        document.getElementById('search-input').focus();
        document.body.style.overflow = 'hidden';
    }

    function closeSearch() {
        searchModal.style.display = 'none';
        document.body.style.overflow = 'auto';
        document.getElementById('search-results').innerHTML = '';
    }

    function handleSearch(e) {
        const query = e.target.value.toLowerCase();
        const resultsContainer = document.getElementById('search-results');

        if (query.length < 2) {
            resultsContainer.innerHTML = '';
            return;
        }

        // Buscar em todas as seções
        const sections = document.querySelectorAll('.subsection');
        const results = [];

        sections.forEach(section => {
            const title = section.querySelector('h3')?.textContent || '';
            const content = section.textContent.toLowerCase();

            if (content.includes(query)) {
                results.push({
                    title: title,
                    content: section.querySelector('p')?.textContent || '',
                    element: section
                });
            }
        });

        // Exibir resultados
        if (results.length === 0) {
            resultsContainer.innerHTML = '<div class="no-results">Nenhum resultado encontrado</div>';
        } else {
            resultsContainer.innerHTML = results.map(result => `
                <div class="search-result" onclick="navigateToResult('${result.title}')">
                    <h4>${result.title}</h4>
                    <p>${result.content.substring(0, 150)}...</p>
                </div>
            `).join('');
        }
    }

    // Função global para navegar até resultado
    window.navigateToResult = function(title) {
        const section = Array.from(document.querySelectorAll('.subsection h3'))
            .find(h3 => h3.textContent === title)?.parentElement;

        if (section) {
            closeSearch();
            section.scrollIntoView({ behavior: 'smooth' });
            section.classList.add('highlight');
            setTimeout(() => section.classList.remove('highlight'), 3000);
        }
    };
}

// Toggle de tema escuro/claro
function initializeThemeToggle() {
    const themeToggle = document.createElement('button');
    themeToggle.className = 'theme-toggle';
    themeToggle.innerHTML = '🌙';
    themeToggle.title = 'Alternar tema';

    document.querySelector('.nav-container').appendChild(themeToggle);

    // Carregar tema salvo
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.body.setAttribute('data-theme', savedTheme);
    updateThemeToggle(savedTheme);

    themeToggle.addEventListener('click', () => {
        const currentTheme = document.body.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';

        document.body.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
        updateThemeToggle(newTheme);
    });

    function updateThemeToggle(theme) {
        themeToggle.innerHTML = theme === 'dark' ? '☀️' : '🌙';
    }
}

// Utilitários gerais
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function throttle(func, limit) {
    let inThrottle;
    return function() {
        const args = arguments;
        const context = this;
        if (!inThrottle) {
            func.apply(context, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// Adicionar estilos para funcionalidades JavaScript
const additionalStyles = `
    .copy-button {
        position: absolute;
        top: 10px;
        right: 10px;
        background: var(--accent-color);
        color: white;
        border: none;
        padding: 0.3rem 0.6rem;
        border-radius: 4px;
        font-size: 0.7rem;
        cursor: pointer;
        opacity: 0.8;
        transition: opacity 0.3s ease;
    }

    .copy-button:hover {
        opacity: 1;
    }

    .search-modal {
        display: none;
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.8);
        z-index: 2000;
        align-items: flex-start;
        justify-content: center;
        padding-top: 5rem;
    }

    .search-content {
        background: var(--card-bg);
        width: 90%;
        max-width: 600px;
        border-radius: 10px;
        overflow: hidden;
        box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
    }

    .search-header {
        display: flex;
        align-items: center;
        padding: 1rem;
        border-bottom: 1px solid var(--border-color);
    }

    #search-input {
        flex: 1;
        border: none;
        outline: none;
        font-size: 1.1rem;
        padding: 0.5rem;
        background: transparent;
        color: var(--text-color);
    }

    #search-close {
        background: none;
        border: none;
        font-size: 1.5rem;
        cursor: pointer;
        color: var(--text-light);
        padding: 0.5rem;
    }

    .search-results {
        max-height: 400px;
        overflow-y: auto;
    }

    .search-result {
        padding: 1rem;
        border-bottom: 1px solid var(--border-color);
        cursor: pointer;
        transition: background 0.3s ease;
    }

    .search-result:hover {
        background: var(--background-color);
    }

    .search-result h4 {
        margin: 0 0 0.5rem 0;
        color: var(--accent-color);
    }

    .search-result p {
        margin: 0;
        color: var(--text-light);
        font-size: 0.9rem;
    }

    .no-results {
        padding: 2rem;
        text-align: center;
        color: var(--text-light);
    }

    .theme-toggle {
        background: none;
        border: none;
        font-size: 1.2rem;
        cursor: pointer;
        padding: 0.5rem;
        border-radius: 50%;
        transition: background 0.3s ease;
    }

    .theme-toggle:hover {
        background: var(--background-color);
    }

    .highlight {
        animation: highlight 2s ease-in-out;
    }

    @keyframes highlight {
        0%, 100% { background: transparent; }
        50% { background: rgba(159, 122, 234, 0.2); }
    }

    /* Tema escuro */
    [data-theme="dark"] {
        --primary-color: #1a202c;
        --secondary-color: #2d3748;
        --accent-color: #9f7aea;
        --background-color: #1a202c;
        --text-color: #e2e8f0;
        --text-light: #a0aec0;
        --border-color: #4a5568;
        --card-bg: #2d3748;
        --code-bg: #0d1117;
    }

    [data-theme="dark"] .hero {
        background: linear-gradient(135deg, #0d1117 0%, #1a202c 100%);
    }

    .nav-menu.active {
        background: var(--card-bg);
    }

    .navbar.scrolled {
        background: rgba(255, 255, 255, 0.95);
        backdrop-filter: blur(10px);
    }

    [data-theme="dark"] .navbar.scrolled {
        background: rgba(45, 55, 72, 0.95);
    }

    .line-number {
        display: inline-block;
        width: 2rem;
        text-align: right;
        margin-right: 1rem;
        color: var(--text-light);
        opacity: 0.5;
        user-select: none;
    }
`;

// Adicionar estilos ao head
const styleSheet = document.createElement('style');
styleSheet.textContent = additionalStyles;
document.head.appendChild(styleSheet);

// Service Worker para cache (PWA)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then(registration => {
                console.log('SW registered: ', registration);
            })
            .catch(registrationError => {
                console.log('SW registration failed: ', registrationError);
            });
    });
}

// Função para exportar página como PDF
function exportToPDF() {
    if (window.print) {
        window.print();
    }
}

// Função para compartilhar página
async function shareContent() {
    if (navigator.share) {
        try {
            await navigator.share({
                title: 'Crystal - Guia Completo',
                text: 'Guia completo sobre a linguagem Crystal',
                url: window.location.href
            });
        } catch (err) {
            console.log('Error sharing:', err);
        }
    } else {
        // Fallback para copiar URL
        await navigator.clipboard.writeText(window.location.href);
        alert('Link copiado para a área de transferência!');
    }
}

// Adicionar funções globais
window.exportToPDF = exportToPDF;
window.shareContent = shareContent;
