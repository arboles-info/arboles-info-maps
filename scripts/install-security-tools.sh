#!/bin/bash

# Script para instalar herramientas de seguridad localmente
# Este script instala todas las herramientas que usan los pipelines de GitHub Actions

set -e

echo "🔧 Instalando herramientas de seguridad para testing local..."

# Verificar que estamos en un entorno virtual
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "⚠️  Advertencia: No estás en un entorno virtual. Se recomienda crear uno:"
    echo "   python3 -m venv venv-security"
    echo "   source venv-security/bin/activate"
    echo ""
    echo "Continuando con la instalación en el entorno global..."
    echo ""
fi

# Verificar e instalar pip si es necesario
echo "📦 Verificando pip..."
if ! python3 -m pip --version &> /dev/null; then
    echo "📦 pip no está instalado. Intentando instalar..."
    
    # Detectar el sistema operativo
    if command -v apt-get &> /dev/null; then
        echo "📦 Sistema Debian/Ubuntu detectado."
        echo "⚠️  pip no está disponible en el sistema."
        echo ""
        echo "🔧 Opciones disponibles:"
        echo "   1. Instalar pip en el sistema: sudo apt install python3-pip"
        echo "   2. Crear entorno virtual (recomendado):"
        echo "      python3 -m venv venv-security"
        echo "      source venv-security/bin/activate"
        echo "      ./scripts/install-security-tools.sh"
        echo ""
        echo "💡 La opción 2 es más segura y no requiere permisos de administrador."
        exit 1
    elif command -v yum &> /dev/null; then
        echo "📦 Sistema RedHat/CentOS detectado. Instalando python3-pip..."
        echo "⚠️  Necesitas ejecutar: sudo yum install python3-pip"
        exit 1
    elif command -v brew &> /dev/null; then
        echo "📦 Sistema macOS detectado. Instalando pip..."
        echo "⚠️  Necesitas ejecutar: brew install python3"
        exit 1
    else
        echo "📦 Intentando instalar pip con ensurepip..."
        python3 -m ensurepip --upgrade
    fi
fi

# Actualizar pip
echo "📦 Actualizando pip..."
python3 -m pip install --upgrade pip

# Instalar dependencias del proyecto
echo "📦 Instalando dependencias del proyecto..."
python3 -m pip install -r requirements.txt

# Instalar herramientas de seguridad Python
echo "🔒 Instalando herramientas de seguridad Python..."
python3 -m pip install safety bandit semgrep

# Instalar herramientas adicionales
echo "🔍 Instalando herramientas adicionales..."
python3 -m pip install checkov

# Instalar herramientas Node.js (si están disponibles)
if command -v npm &> /dev/null; then
    echo "📦 Instalando herramientas Node.js..."
    npm install -g npm-audit-html retire
else
    echo "⚠️  npm no está disponible. Saltando herramientas Node.js."
fi

# Instalar GitGuardian Shield (opcional)
if command -v pipx &> /dev/null; then
    echo "🛡️  Instalando GitGuardian Shield..."
    pipx install ggshield
else
    echo "⚠️  pipx no está disponible. Para instalar GitGuardian Shield:"
    echo "   python3 -m pip install pipx"
    echo "   pipx install ggshield"
fi

echo ""
echo "✅ Herramientas de seguridad instaladas correctamente!"
echo ""
echo "📋 Herramientas disponibles:"
echo "   - safety: Análisis de vulnerabilidades en dependencias Python"
echo "   - bandit: Análisis de código Python"
echo "   - semgrep: Análisis estático avanzado"
echo "   - checkov: Análisis de configuración"
echo "   - retire: Análisis de librerías JavaScript (si npm está disponible)"
echo ""
echo "🚀 Para ejecutar las verificaciones, usa:"
echo "   ./scripts/run-security-checks.sh"
