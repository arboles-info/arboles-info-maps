# Makefile para comandos de desarrollo y seguridad
# Facilita la ejecución de scripts de seguridad y desarrollo

.PHONY: help install-security-tools security-quick security-full security-install clean-security-reports test-local

# Variables
PYTHON := python3
PIP := python3 -m pip
VENV := venv-security
VENV_DEV := venv
VENV_BIN := $(VENV_DEV)/bin
PIP_DEV := $(VENV_BIN)/pip
PYTHON_VENV := $(VENV_BIN)/python
APP := src/main.py
HOST := 0.0.0.0
PORT := 8000

# Colores para output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Ayuda por defecto
help: ## Mostrar esta ayuda
	@echo "$(GREEN)Comandos disponibles:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Comandos de seguridad
install-security-tools: ## Instalar herramientas de seguridad
	@echo "🔧 Instalando herramientas de seguridad..."
	@./scripts/install-security-tools.sh

security-quick: ## Ejecutar verificación rápida de seguridad (equivalente a security-quick.yml)
	@echo "🚀 Ejecutando verificación rápida de seguridad..."
	@bash -c "source $(VENV)/bin/activate && ./scripts/quick-security-check.sh"

security-full: ## Ejecutar verificación completa de seguridad (equivalente a security.yml)
	@echo "🔒 Ejecutando verificación completa de seguridad..."
	@bash -c "source $(VENV)/bin/activate && ./scripts/run-security-checks.sh"

security-install: ## Crear entorno virtual y instalar herramientas de seguridad
	@echo "📦 Creando entorno virtual para seguridad..."
	@$(PYTHON) -m venv $(VENV)
	@echo "🔧 Activando entorno virtual e instalando herramientas..."
	@bash -c "source $(VENV)/bin/activate && ./scripts/install-security-tools.sh"
	@echo "✅ Entorno de seguridad configurado. Para activar: source $(VENV)/bin/activate"

# Verificar dependencias del sistema
check-deps: ## Verificar dependencias del sistema
	@echo "$(YELLOW)🔍 Verificando dependencias del sistema...$(NC)"
	@echo ""
	@echo "$(BLUE)Python:$(NC)"
	@if command -v $(PYTHON) >/dev/null 2>&1; then \
		echo "  ✅ $(PYTHON) disponible: $$($(PYTHON) --version)"; \
	else \
		echo "  ❌ $(PYTHON) no encontrado"; \
	fi
	@echo ""
	@echo "$(BLUE)Pip:$(NC)"
	@if $(PYTHON) -m pip --version >/dev/null 2>&1; then \
		echo "  ✅ pip disponible: $$($(PYTHON) -m pip --version)"; \
	else \
		echo "  ❌ pip no encontrado"; \
	fi
	@echo ""
	@echo "$(BLUE)Virtualenv:$(NC)"
	@if $(PYTHON) -m venv --help >/dev/null 2>&1; then \
		echo "  ✅ python3-venv disponible"; \
	else \
		echo "  ❌ python3-venv no encontrado"; \
	fi
	@echo ""
	@echo "$(BLUE)Dependencias de Python:$(NC)"
	@if $(PYTHON) -c "import fastapi" 2>/dev/null; then \
		echo "  ✅ FastAPI disponible"; \
	else \
		echo "  ❌ FastAPI no encontrado"; \
	fi
	@if $(PYTHON) -c "import uvicorn" 2>/dev/null; then \
		echo "  ✅ Uvicorn disponible"; \
	else \
		echo "  ❌ Uvicorn no encontrado"; \
	fi
	@if $(PYTHON) -c "import httpx" 2>/dev/null; then \
		echo "  ✅ HTTPX disponible"; \
	else \
		echo "  ❌ HTTPX no encontrado"; \
	fi
	@if $(PYTHON) -c "import pydantic" 2>/dev/null; then \
		echo "  ✅ Pydantic disponible"; \
	else \
		echo "  ❌ Pydantic no encontrado"; \
	fi
	@echo ""
	@echo "$(BLUE)Recomendaciones:$(NC)"
	@if ! $(PYTHON) -m pip --version >/dev/null 2>&1; then \
		echo "  📦 Instalar pip: sudo apt install python3-pip"; \
	fi
	@if ! $(PYTHON) -m venv --help >/dev/null 2>&1; then \
		echo "  📦 Instalar venv: sudo apt install python3-venv"; \
	fi
	@if ! $(PYTHON) -c "import fastapi" 2>/dev/null; then \
		echo "  📦 Instalar dependencias: make install-system"; \
	fi

# Crear virtualenv e instalar dependencias
setup: check-deps ## Crear virtualenv e instalar dependencias
	@echo "$(YELLOW)🔧 Configurando entorno...$(NC)"
	@if $(PYTHON) -m venv --help >/dev/null 2>&1; then \
		echo "$(YELLOW)Creando virtualenv...$(NC)"; \
		if $(PYTHON) -m venv $(VENV_DEV) 2>/dev/null; then \
			echo "$(GREEN)✅ Virtualenv creado$(NC)"; \
			echo "$(YELLOW)📦 Instalando dependencias...$(NC)"; \
			bash -c "source $(VENV_DEV)/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"; \
			echo "$(GREEN)✅ Dependencias instaladas$(NC)"; \
			echo "$(YELLOW)Para activar el virtualenv ejecuta: source $(VENV_DEV)/bin/activate$(NC)"; \
		else \
			echo "$(RED)❌ Error creando virtualenv$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)❌ python3-venv no disponible$(NC)"; \
		echo "$(YELLOW)Instalando dependencias del sistema...$(NC)"; \
		$(MAKE) install-system; \
	fi

# Verificar que pip está disponible
check-pip: ## Verificar que pip está disponible
	@if ! $(PYTHON) -m pip --version >/dev/null 2>&1; then \
		echo "$(RED)❌ pip no encontrado. Instala python3-pip:$(NC)"; \
		echo "$(YELLOW)sudo apt install python3-pip$(NC)"; \
		exit 1; \
	fi

# Verificar que el virtualenv existe y es válido
check-venv: ## Verificar que el virtualenv existe y es válido
	@if [ ! -d "$(VENV_DEV)" ]; then \
		echo "$(RED)❌ Virtualenv no encontrado. Ejecuta 'make setup' primero$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(VENV_BIN)/pip" ]; then \
		echo "$(RED)❌ Virtualenv corrupto. Ejecuta 'make clean-venv' y luego 'make setup'$(NC)"; \
		exit 1; \
	fi

# Verificar que las dependencias están disponibles
check-app-deps: ## Verificar que las dependencias están disponibles
	@if [ -f "$(VENV_BIN)/python" ]; then \
		PYTHON_CMD="$(PYTHON_VENV)"; \
	else \
		PYTHON_CMD="$(PYTHON)"; \
	fi; \
	if ! $$PYTHON_CMD -c "import fastapi, uvicorn, httpx, pydantic" 2>/dev/null; then \
		echo "$(RED)❌ Faltan dependencias. Ejecuta 'make setup' o 'make install-system' primero$(NC)"; \
		exit 1; \
	fi

# Instalar dependencias del sistema (sin virtualenv)
install-system: check-pip ## Instalar dependencias del sistema (sin virtualenv)
	@echo "$(YELLOW)📦 Instalando dependencias del sistema...$(NC)"
	$(PYTHON) -m pip install --user -r requirements.txt
	@echo "$(GREEN)✅ Dependencias instaladas del sistema$(NC)"
	@echo "$(YELLOW)Nota: Las dependencias se instalaron globalmente$(NC)"

# Comandos de desarrollo
install: check-venv ## Instalar dependencias en el virtualenv existente
	@echo "$(YELLOW)📦 Actualizando dependencias en virtualenv...$(NC)"
	@bash -c "source $(VENV_DEV)/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
	@echo "$(GREEN)✅ Dependencias actualizadas$(NC)"

run: check-app-deps ## Ejecutar la aplicación
	@echo "$(GREEN)🚀 Levantando OpenTrees Web...$(NC)"
	@echo "$(YELLOW)📱 Aplicación disponible en: http://$(HOST):$(PORT)$(NC)"
	@echo "$(YELLOW)⏹️  Presiona Ctrl+C para detener$(NC)"
	@echo ""
	@if [ -f "$(VENV_BIN)/python" ]; then \
		$(PYTHON_VENV) $(APP); \
	else \
		$(PYTHON) $(APP); \
	fi

# Levantar en modo desarrollo (con recarga automática)
dev: check-app-deps ## Levantar la aplicación en modo desarrollo
	@echo "$(GREEN)🚀 Levantando OpenTrees Web en modo desarrollo...$(NC)"
	@echo "$(YELLOW)📱 Aplicación disponible en: http://$(HOST):$(PORT)$(NC)"
	@echo "$(YELLOW)🔄 Recarga automática habilitada$(NC)"
	@echo "$(YELLOW)⏹️  Presiona Ctrl+C para detener$(NC)"
	@echo ""
	@if [ -f "$(VENV_BIN)/python" ]; then \
		PYTHON_CMD="$(PYTHON_VENV)"; \
		UVICORN_CMD="$(VENV_BIN)/uvicorn"; \
	else \
		PYTHON_CMD="$(PYTHON)"; \
		UVICORN_CMD="uvicorn"; \
	fi; \
	if command -v $$UVICORN_CMD >/dev/null 2>&1; then \
    		$$UVICORN_CMD src.main:app --host $(HOST) --port $(PORT) --reload; \
    	elif $$PYTHON_CMD -c "import uvicorn" 2>/dev/null; then \
    		$$PYTHON_CMD -m uvicorn src.main:app --host $(HOST) --port $(PORT) --reload; \
	else \
		echo "$(RED)❌ Uvicorn no encontrado para modo desarrollo$(NC)"; \
		echo "$(YELLOW)Usando modo normal...$(NC)"; \
		$$PYTHON_CMD $(APP); \
	fi

test: check-app-deps ## Ejecutar tests (si existen)
	@echo "$(YELLOW)🧪 Ejecutando tests...$(NC)"
	@if [ -f "test_*.py" ] || [ -d "tests" ]; then \
		$(PYTHON) -m pip install --user pytest pytest-asyncio 2>/dev/null || true; \
		$(PYTHON) -m pytest -v; \
	else \
		echo "$(YELLOW)⚠️  No se encontraron tests$(NC)"; \
	fi

# Verificar código con linters
lint: check-app-deps ## Verificar código con linters
	@echo "$(YELLOW)🔍 Verificando código...$(NC)"
	@$(PYTHON) -m pip install --user flake8 black isort 2>/dev/null || true
	@echo "$(YELLOW)📝 Verificando con flake8...$(NC)"
	@$(PYTHON) -m flake8 $(APP) --max-line-length=100 --ignore=E203,W503 || true
	@echo "$(YELLOW)📝 Verificando imports con isort...$(NC)"
	@$(PYTHON) -m isort $(APP) --check-only --diff || true
	@echo "$(GREEN)✅ Verificación completada$(NC)"

# Formatear código
format: check-app-deps ## Formatear código
	@echo "$(YELLOW)�� Formateando código...$(NC)"
	@$(PYTHON) -m pip install --user black isort 2>/dev/null || true
	@$(PYTHON) -m black $(APP) --line-length=100
	@$(PYTHON) -m isort $(APP)
	@echo "$(GREEN)✅ Código formateado$(NC)"

# Comandos de limpieza
clean: ## Limpiar archivos temporales
	@echo "$(YELLOW)🧹 Limpiando archivos temporales...$(NC)"
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type d -name "__pycache__" -delete 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.log" -delete 2>/dev/null || true
	rm -rf .pytest_cache 2>/dev/null || true
	rm -rf .coverage 2>/dev/null || true
	rm -rf htmlcov 2>/dev/null || true
	@echo "$(GREEN)✅ Archivos temporales eliminados$(NC)"

# Limpiar virtualenv
clean-venv: ## Eliminar virtualenv
	@echo "$(YELLOW)🧹 Eliminando virtualenv...$(NC)"
	rm -rf $(VENV_DEV)
	@echo "$(GREEN)✅ Virtualenv eliminado$(NC)"

clean-security-reports: ## Limpiar reportes de seguridad
	@echo "🧹 Limpiando reportes de seguridad..."
	@rm -f *-report.json
	@rm -f security-summary.md

clean-all: clean clean-venv clean-security-reports ## Limpiar todos los archivos temporales y reportes
	@echo "$(GREEN)✅ Limpieza completa realizada$(NC)"

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
	@$(PYTHON) -m venv $(VENV_DEV)
	@bash -c "source $(VENV_DEV)/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
	@echo "✅ Entorno de desarrollo configurado. Para activar: source $(VENV_DEV)/bin/activate"

# Comandos de información
info: ## Mostrar información del proyecto
	@echo "$(GREEN)📋 Información del entorno:$(NC)"
	@echo "$(YELLOW)Python:$(NC) $$($(PYTHON) --version 2>/dev/null || echo 'No disponible')"
	@echo "$(YELLOW)Ubicación Python:$(NC) $$(which $(PYTHON) 2>/dev/null || echo 'No encontrado')"
	@if $(PYTHON) -m pip --version >/dev/null 2>&1; then \
		echo "$(YELLOW)Pip:$(NC) $$($(PYTHON) -m pip --version)"; \
	else \
		echo "$(YELLOW)Pip:$(NC) No disponible"; \
	fi
	@if [ -d "$(VENV_DEV)" ]; then \
		echo "$(YELLOW)Virtualenv:$(NC) $(VENV_DEV) (existe)"; \
		if [ -f "$(VENV_BIN)/python" ]; then \
			echo "$(YELLOW)Python en venv:$(NC) $$($(PYTHON_VENV) --version)"; \
		fi; \
	else \
		echo "$(YELLOW)Virtualenv:$(NC) No existe"; \
	fi
	@echo "$(YELLOW)Directorio actual:$(NC) $$(pwd)"
	@echo "$(YELLOW)Archivo principal:$(NC) $(APP)"
	@if [ -f "$(APP)" ]; then \
		echo "$(GREEN)✅ Archivo principal encontrado$(NC)"; \
	else \
		echo "$(RED)❌ Archivo principal no encontrado: $(APP)$(NC)"; \
	fi
	@echo ""
	@echo "$(BLUE)Dependencias instaladas:$(NC)"
	@if [ -f "$(VENV_BIN)/python" ]; then \
		PYTHON_CMD="$(PYTHON_VENV)"; \
	else \
		PYTHON_CMD="$(PYTHON)"; \
	fi; \
	if $$PYTHON_CMD -c "import fastapi" 2>/dev/null; then \
		echo "  ✅ FastAPI"; \
	else \
		echo "  ❌ FastAPI"; \
	fi; \
	if $$PYTHON_CMD -c "import uvicorn" 2>/dev/null; then \
		echo "  ✅ Uvicorn"; \
	else \
		echo "  ❌ Uvicorn"; \
	fi; \
	if $$PYTHON_CMD -c "import httpx" 2>/dev/null; then \
		echo "  ✅ HTTPX"; \
	else \
		echo "  ❌ HTTPX"; \
	fi; \
	if $$PYTHON_CMD -c "import pydantic" 2>/dev/null; then \
		echo "  ✅ Pydantic"; \
	else \
		echo "  ❌ Pydantic"; \
	fi

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