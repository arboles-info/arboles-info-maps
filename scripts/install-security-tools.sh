#!/bin/bash

# Script para instalar herramientas de seguridad localmente
# Este script instala todas las herramientas que usan los pipelines de GitHub Actions

set -e

echo "🔧 Instalando herramientas de seguridad para testing local..."

# Verificar que estamos en un entorno virtual
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "⚠️  Advertencia: No estás en un entorno virtual. Se recomienda crear uno:"
    echo "   python -m venv venv-security"
    echo "   source venv-security/bin/activate"
    echo ""
    read -p "¿Continuar de todos modos? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Actualizar pip
echo "📦 Actualizando pip..."
python -m pip install --upgrade pip

# Instalar dependencias del proyecto
echo "📦 Instalando dependencias del proyecto..."
pip install -r requirements.txt

# Instalar herramientas de seguridad Python
echo "🔒 Instalando herramientas de seguridad Python..."
pip install safety bandit semgrep

# Instalar herramientas adicionales
echo "🔍 Instalando herramientas adicionales..."
pip install checkov

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
    echo "   pip install pipx"
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
