# Makefile para OpenTrees Web
# Maneja todos los casos: con/sin venv, con/sin pip

# Variables
PYTHON := python3
VENV := venv
VENV_BIN := $(VENV)/bin
PIP := $(VENV_BIN)/pip
PYTHON_VENV := $(VENV_BIN)/python
APP := main.py
HOST := 0.0.0.0
PORT := 8000

# Colores para output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help setup install run clean test lint format check-deps check-venv check-pip install-system-deps

# Target por defecto
help:
	@echo "$(GREEN)OpenTrees Web - Comandos disponibles:$(NC)"
	@echo ""
	@echo "$(YELLOW)check-deps$(NC)     - Verificar dependencias del sistema"
	@echo "$(YELLOW)setup$(NC)          - Crear virtualenv e instalar dependencias"
	@echo "$(YELLOW)install$(NC)        - Instalar dependencias en el virtualenv existente"
	@echo "$(YELLOW)install-system$(NC) - Instalar dependencias del sistema (sin virtualenv)"
	@echo "$(YELLOW)run$(NC)            - Levantar la aplicación"
	@echo "$(YELLOW)dev$(NC)            - Levantar la aplicación en modo desarrollo"
	@echo "$(YELLOW)clean$(NC)          - Limpiar archivos temporales"
	@echo "$(YELLOW)clean-venv$(NC)     - Eliminar virtualenv"
	@echo "$(YELLOW)test$(NC)           - Ejecutar tests (si existen)"
	@echo "$(YELLOW)lint$(NC)           - Verificar código con linters"
	@echo "$(YELLOW)format$(NC)         - Formatear código"
	@echo "$(YELLOW)info$(NC)           - Mostrar información del entorno"
	@echo ""

# Verificar dependencias del sistema
check-deps:
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
setup: check-deps
	@echo "$(YELLOW)🔧 Configurando entorno...$(NC)"
	@if $(PYTHON) -m venv --help >/dev/null 2>&1; then \
		echo "$(YELLOW)Creando virtualenv...$(NC)"; \
		if $(PYTHON) -m venv $(VENV) 2>/dev/null; then \
			echo "$(GREEN)✅ Virtualenv creado$(NC)"; \
			echo "$(YELLOW)📦 Instalando dependencias...$(NC)"; \
			$(PIP) install --upgrade pip; \
			$(PIP) install -r requirements.txt; \
			echo "$(GREEN)✅ Dependencias instaladas$(NC)"; \
			echo "$(YELLOW)Para activar el virtualenv ejecuta: source $(VENV)/bin/activate$(NC)"; \
		else \
			echo "$(RED)❌ Error creando virtualenv$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)❌ python3-venv no disponible$(NC)"; \
		echo "$(YELLOW)Instalando dependencias del sistema...$(NC)"; \
		$(MAKE) install-system; \
	fi

# Instalar dependencias en virtualenv existente
install: check-venv
	@echo "$(YELLOW)📦 Actualizando dependencias en virtualenv...$(NC)"
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	@echo "$(GREEN)✅ Dependencias actualizadas$(NC)"

# Instalar dependencias del sistema (sin virtualenv)
install-system: check-pip
	@echo "$(YELLOW)📦 Instalando dependencias del sistema...$(NC)"
	$(PYTHON) -m pip install --user -r requirements.txt
	@echo "$(GREEN)✅ Dependencias instaladas del sistema$(NC)"
	@echo "$(YELLOW)Nota: Las dependencias se instalaron globalmente$(NC)"

# Verificar que pip está disponible
check-pip:
	@if ! $(PYTHON) -m pip --version >/dev/null 2>&1; then \
		echo "$(RED)❌ pip no encontrado. Instala python3-pip:$(NC)"; \
		echo "$(YELLOW)sudo apt install python3-pip$(NC)"; \
		exit 1; \
	fi

# Verificar que el virtualenv existe y es válido
check-venv:
	@if [ ! -d "$(VENV)" ]; then \
		echo "$(RED)❌ Virtualenv no encontrado. Ejecuta 'make setup' primero$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(VENV_BIN)/pip" ]; then \
		echo "$(RED)❌ Virtualenv corrupto. Ejecuta 'make clean-venv' y luego 'make setup'$(NC)"; \
		exit 1; \
	fi

# Verificar que las dependencias están disponibles
check-app-deps:
	@if [ -f "$(VENV_BIN)/python" ]; then \
		PYTHON_CMD="$(PYTHON_VENV)"; \
	else \
		PYTHON_CMD="$(PYTHON)"; \
	fi; \
	if ! $$PYTHON_CMD -c "import fastapi, uvicorn, httpx, pydantic" 2>/dev/null; then \
		echo "$(RED)❌ Faltan dependencias. Ejecuta 'make setup' o 'make install-system' primero$(NC)"; \
		exit 1; \
	fi

# Levantar la aplicación
run: check-app-deps
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
dev: check-app-deps
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
		$$UVICORN_CMD main:app --host $(HOST) --port $(PORT) --reload; \
	elif $$PYTHON_CMD -c "import uvicorn" 2>/dev/null; then \
		$$PYTHON_CMD -m uvicorn main:app --host $(HOST) --port $(PORT) --reload; \
	else \
		echo "$(RED)❌ Uvicorn no encontrado para modo desarrollo$(NC)"; \
		echo "$(YELLOW)Usando modo normal...$(NC)"; \
		$$PYTHON_CMD $(APP); \
	fi

# Limpiar archivos temporales
clean:
	@echo "$(YELLOW)🧹 Limpiando archivos temporales...$(NC)"
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type d -name "__pycache__" -delete 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache 2>/dev/null || true
	rm -rf .coverage 2>/dev/null || true
	rm -rf htmlcov 2>/dev/null || true
	@echo "$(GREEN)✅ Archivos temporales eliminados$(NC)"

# Limpiar virtualenv
clean-venv:
	@echo "$(YELLOW)🧹 Eliminando virtualenv...$(NC)"
	rm -rf $(VENV)
	@echo "$(GREEN)✅ Virtualenv eliminado$(NC)"

# Limpiar todo
clean-all: clean clean-venv
	@echo "$(GREEN)✅ Limpieza completa realizada$(NC)"

# Ejecutar tests (si existen)
test: check-app-deps
	@echo "$(YELLOW)🧪 Ejecutando tests...$(NC)"
	@if [ -f "test_*.py" ] || [ -d "tests" ]; then \
		$(PYTHON) -m pip install --user pytest pytest-asyncio 2>/dev/null || true; \
		$(PYTHON) -m pytest -v; \
	else \
		echo "$(YELLOW)⚠️  No se encontraron tests$(NC)"; \
	fi

# Verificar código con linters
lint: check-app-deps
	@echo "$(YELLOW)🔍 Verificando código...$(NC)"
	@$(PYTHON) -m pip install --user flake8 black isort 2>/dev/null || true
	@echo "$(YELLOW)📝 Verificando con flake8...$(NC)"
	@$(PYTHON) -m flake8 $(APP) --max-line-length=100 --ignore=E203,W503 || true
	@echo "$(YELLOW)📝 Verificando imports con isort...$(NC)"
	@$(PYTHON) -m isort $(APP) --check-only --diff || true
	@echo "$(GREEN)✅ Verificación completada$(NC)"

# Formatear código
format: check-app-deps
	@echo "$(YELLOW)🎨 Formateando código...$(NC)"
	@$(PYTHON) -m pip install --user black isort 2>/dev/null || true
	@$(PYTHON) -m black $(APP) --line-length=100
	@$(PYTHON) -m isort $(APP)
	@echo "$(GREEN)✅ Código formateado$(NC)"

# Mostrar información del entorno
info:
	@echo "$(GREEN)📋 Información del entorno:$(NC)"
	@echo "$(YELLOW)Python:$(NC) $$($(PYTHON) --version 2>/dev/null || echo 'No disponible')"
	@echo "$(YELLOW)Ubicación Python:$(NC) $$(which $(PYTHON) 2>/dev/null || echo 'No encontrado')"
	@if $(PYTHON) -m pip --version >/dev/null 2>&1; then \
		echo "$(YELLOW)Pip:$(NC) $$($(PYTHON) -m pip --version)"; \
	else \
		echo "$(YELLOW)Pip:$(NC) No disponible"; \
	fi
	@if [ -d "$(VENV)" ]; then \
		echo "$(YELLOW)Virtualenv:$(NC) $(VENV) (existe)"; \
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