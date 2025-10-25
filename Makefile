# Makefile para comandos de desarrollo y seguridad
# Facilita la ejecución de scripts de seguridad y desarrollo

.PHONY: help install-security-tools security-quick security-full security-install clean-security-reports test-local

# Variables
PYTHON := python3
PIP := pip3
VENV := venv-security

# Ayuda por defecto
help: ## Mostrar esta ayuda
	@echo "Comandos disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Comandos de seguridad
install-security-tools: ## Instalar herramientas de seguridad
	@echo "🔧 Instalando herramientas de seguridad..."
	@./scripts/install-security-tools.sh

security-quick: ## Ejecutar verificación rápida de seguridad (equivalente a security-quick.yml)
	@echo "🚀 Ejecutando verificación rápida de seguridad..."
	@./scripts/quick-security-check.sh

security-full: ## Ejecutar verificación completa de seguridad (equivalente a security.yml)
	@echo "🔒 Ejecutando verificación completa de seguridad..."
	@./scripts/run-security-checks.sh

security-install: ## Crear entorno virtual y instalar herramientas de seguridad
	@echo "📦 Creando entorno virtual para seguridad..."
	@$(PYTHON) -m venv $(VENV)
	@echo "🔧 Activando entorno virtual e instalando herramientas..."
	@bash -c "source $(VENV)/bin/activate && ./scripts/install-security-tools.sh"
	@echo "✅ Entorno de seguridad configurado. Para activar: source $(VENV)/bin/activate"

# Comandos de desarrollo
install: ## Instalar dependencias del proyecto
	@echo "📦 Instalando dependencias del proyecto..."
	@$(PIP) install -r requirements.txt

run: ## Ejecutar la aplicación
	@echo "🚀 Iniciando aplicación..."
	@$(PYTHON) main.py

test: ## Ejecutar tests (si existen)
	@echo "🧪 Ejecutando tests..."
	@if [ -f "pytest.ini" ] || [ -d "tests" ]; then \
		pytest; \
	else \
		echo "⚠️  No se encontraron tests configurados"; \
	fi

# Comandos de limpieza
clean: ## Limpiar archivos temporales
	@echo "🧹 Limpiando archivos temporales..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@find . -type f -name "*.log" -delete

clean-security-reports: ## Limpiar reportes de seguridad
	@echo "🧹 Limpiando reportes de seguridad..."
	@rm -f *-report.json
	@rm -f security-summary.md

clean-all: clean clean-security-reports ## Limpiar todos los archivos temporales y reportes

# Comandos de verificación
check-format: ## Verificar formato del código
	@echo "🎨 Verificando formato del código..."
	@if command -v black >/dev/null 2>&1; then \
		black --check .; \
	else \
		echo "⚠️  Black no está instalado. Instala con: pip install black"; \
	fi

check-lint: ## Verificar linting del código
	@echo "🔍 Verificando linting del código..."
	@if command -v flake8 >/dev/null 2>&1; then \
		flake8 .; \
	else \
		echo "⚠️  Flake8 no está instalado. Instala con: pip install flake8"; \
	fi

check-types: ## Verificar tipos del código
	@echo "🔍 Verificando tipos del código..."
	@if command -v mypy >/dev/null 2>&1; then \
		mypy .; \
	else \
		echo "⚠️  MyPy no está instalado. Instala con: pip install mypy"; \
	fi

# Comando combinado para verificación completa
check-all: check-format check-lint check-types security-quick ## Ejecutar todas las verificaciones

# Comandos de desarrollo con entorno virtual
dev-setup: ## Configurar entorno de desarrollo completo
	@echo "🚀 Configurando entorno de desarrollo..."
	@$(PYTHON) -m venv venv
	@bash -c "source venv/bin/activate && $(PIP) install -r requirements.txt"
	@echo "✅ Entorno de desarrollo configurado. Para activar: source venv/bin/activate"

# Comandos de información
info: ## Mostrar información del proyecto
	@echo "📋 Información del proyecto:"
	@echo "  - Python: $(shell $(PYTHON) --version)"
	@echo "  - Pip: $(shell $(PIP) --version)"
	@echo "  - Directorio: $(shell pwd)"
	@echo "  - Rama Git: $(shell git branch --show-current 2>/dev/null || echo 'No es un repo git')"
	@echo "  - Último commit: $(shell git log -1 --oneline 2>/dev/null || echo 'No hay commits')"

# Comandos de Git
git-status: ## Mostrar estado de Git
	@echo "📊 Estado de Git:"
	@git status --short

git-log: ## Mostrar últimos commits
	@echo "📝 Últimos commits:"
	@git log --oneline -10

# Comandos de Docker (si se usa)
docker-build: ## Construir imagen Docker
	@echo "🐳 Construyendo imagen Docker..."
	@if [ -f "Dockerfile" ]; then \
		docker build -t arboles-info-maps .; \
	else \
		echo "⚠️  No se encontró Dockerfile"; \
	fi

docker-run: ## Ejecutar contenedor Docker
	@echo "🐳 Ejecutando contenedor Docker..."
	@if [ -f "Dockerfile" ]; then \
		docker run -p 8000:8000 arboles-info-maps; \
	else \
		echo "⚠️  No se encontró Dockerfile"; \
	fi

# Comando por defecto
.DEFAULT_GOAL := help