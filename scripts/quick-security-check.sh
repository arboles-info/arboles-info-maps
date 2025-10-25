#!/bin/bash

# Script para verificación rápida de seguridad (equivalente al pipeline security-quick.yml)
# Ejecuta las mismas verificaciones que el pipeline de verificación rápida

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Verificación Rápida de Seguridad${NC}"
echo "Simulando pipeline security-quick.yml"
echo "Fecha: $(date)"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "requirements.txt" ]; then
    echo -e "${RED}❌ Error: No se encontró requirements.txt. Ejecuta desde el directorio raíz del proyecto.${NC}"
    exit 1
fi

# Verificar que las herramientas están instaladas
if ! command -v safety &> /dev/null; then
    echo -e "${RED}❌ Safety no está instalado. Ejecuta: ./scripts/install-security-tools.sh${NC}"
    exit 1
fi

# Función para ejecutar check
run_check() {
    local check_name="$1"
    local command="$2"
    
    echo -e "${YELLOW}🔍 $check_name${NC}"
    echo "Comando: $command"
    echo ""
    
    if eval "$command"; then
        echo -e "${GREEN}✅ $check_name - PASÓ${NC}"
        return 0
    else
        echo -e "${RED}❌ $check_name - FALLÓ${NC}"
        return 1
    fi
    echo ""
}

# 1. Quick safety check
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}1. Verificación Rápida de Dependencias${NC}"
echo -e "${BLUE}========================================${NC}"

if ! run_check "Safety - Verificación rápida" "python3 -m pip install -r requirements.txt && safety check --short-report"; then
    echo -e "${RED}❌ Falló la verificación de dependencias${NC}"
    exit 1
fi

# 2. Verificaciones manuales de seguridad
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}2. Verificaciones de Seguridad Comunes${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}🔍 Verificando problemas de seguridad comunes...${NC}"

# Verificar contraseñas hardcodeadas
echo "Verificando contraseñas hardcodeadas..."
if grep -r -i "password.*=" . --include="*.py" --include="*.js" --include="*.html" | grep -v "password.*None" | grep -v "password.*''"; then
    echo -e "${RED}❌ WARNING: Se encontraron posibles contraseñas hardcodeadas${NC}"
    exit 1
else
    echo -e "${GREEN}✅ No se encontraron contraseñas hardcodeadas${NC}"
fi

# Verificar tokens de API hardcodeados
echo "Verificando tokens de API hardcodeados..."
if grep -r -E "(api[_-]?key|token|secret)" . --include="*.py" --include="*.js" | grep -v "TODO\|FIXME\|example\|placeholder"; then
    echo -e "${RED}❌ WARNING: Se encontraron posibles tokens de API hardcodeados${NC}"
    exit 1
else
    echo -e "${GREEN}✅ No se encontraron tokens de API hardcodeados${NC}"
fi

# Verificar URLs HTTP inseguras
echo "Verificando URLs HTTP inseguras..."
if grep -r "http://" . --include="*.py" --include="*.js" | grep -v "localhost\|127.0.0.1\|example.com"; then
    echo -e "${RED}❌ WARNING: Se encontraron URLs HTTP inseguras (usa HTTPS en producción)${NC}"
    exit 1
else
    echo -e "${GREEN}✅ No se encontraron URLs HTTP inseguras${NC}"
fi

echo ""
echo -e "${GREEN}🎉 ¡Verificación rápida de seguridad completada exitosamente!${NC}"
echo -e "${GREEN}Tu código está listo para hacer commit y push.${NC}"
echo ""
echo -e "${BLUE}💡 Para una verificación más completa, ejecuta:${NC}"
echo -e "${BLUE}   ./scripts/run-security-checks.sh${NC}"
