#!/bin/bash

# Script para ejecutar verificaciones de seguridad localmente
# Simula los pipelines de GitHub Actions en tu máquina local

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Función para imprimir resultados
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Variables para tracking de resultados
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Función para ejecutar check y trackear resultados
run_check() {
    local check_name="$1"
    local command="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -e "${YELLOW}Ejecutando: $check_name${NC}"
    echo "Comando: $command"
    echo ""
    
    if eval "$command"; then
        print_result 0 "$check_name - PASÓ"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        print_result 1 "$check_name - FALLÓ"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    echo ""
}

# Función para ejecutar check que puede fallar sin detener el script
run_check_optional() {
    local check_name="$1"
    local command="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -e "${YELLOW}Ejecutando: $check_name${NC}"
    echo "Comando: $command"
    echo ""
    
    if eval "$command" 2>/dev/null; then
        print_result 0 "$check_name - PASÓ"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        print_result 1 "$check_name - FALLÓ (opcional)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    echo ""
}

echo -e "${BLUE}🔒 Iniciando verificaciones de seguridad local${NC}"
echo "Fecha: $(date)"
echo "Directorio: $(pwd)"
echo ""

# Verificar que las herramientas están instaladas
print_header "Verificando herramientas instaladas"

if ! command -v safety &> /dev/null; then
    echo -e "${RED}❌ Safety no está instalado. Ejecuta: ./scripts/install-security-tools.sh${NC}"
    exit 1
fi

if ! command -v semgrep &> /dev/null; then
    echo -e "${RED}❌ Semgrep no está instalado. Ejecuta: ./scripts/install-security-tools.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Todas las herramientas están instaladas${NC}"

# 1. Análisis de dependencias Python
print_header "1. Análisis de Dependencias Python (Safety)"

run_check "Safety - Verificación de vulnerabilidades" "python3 -m pip install -r requirements.txt && safety check"
run_check "Safety - Reporte JSON" "safety check --json --output safety-report.json"

# 2. Análisis estático avanzado
print_header "2. Análisis Estático Avanzado (Semgrep)"

run_check "Semgrep - Análisis automático" "semgrep --config=auto ."
run_check "Semgrep - Reporte JSON" "semgrep --config=auto --json --output=semgrep-report.json ."

# 3. Verificaciones manuales de seguridad
print_header "3. Verificaciones Manuales de Seguridad"

run_check "Verificación - Contraseñas hardcodeadas" "! grep -r -i 'password.*=' . --include='*.py' --include='*.js' --include='*.html' | grep -v 'password.*None' | grep -v 'password.*'''"
run_check "Verificación - Tokens de API hardcodeados" "! grep -r -E '(api[_-]?key|token|secret)' . --include='*.py' --include='*.js' | grep -v 'TODO\|FIXME\|example\|placeholder'"
run_check "Verificación - URLs HTTP inseguras" "! grep -r 'http://' . --include='*.py' --include='*.js' | grep -v 'localhost\|127.0.0.1\|example.com'"

# JavaScript y configuración removidos para simplificar el pipeline

# 4. Verificación de permisos de archivos
print_header "4. Verificación de Permisos de Archivos"

run_check "Verificación - Archivos Python ejecutables" "! find . -type f -name '*.py' -exec ls -la {} \; | grep -E '^-rwx'"
run_check "Verificación - Scripts shell ejecutables" "find . -type f -name '*.sh' -exec ls -la {} \; | grep -E '^-rwx'"

# Resumen final
print_header "Resumen de Verificaciones"

echo -e "${BLUE}Total de verificaciones: $TOTAL_CHECKS${NC}"
echo -e "${GREEN}Verificaciones exitosas: $PASSED_CHECKS${NC}"
echo -e "${RED}Verificaciones fallidas: $FAILED_CHECKS${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ¡Todas las verificaciones de seguridad pasaron!${NC}"
    echo -e "${GREEN}Tu código está listo para hacer commit y push.${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  Se encontraron $FAILED_CHECKS problemas de seguridad.${NC}"
    echo -e "${YELLOW}Revisa los errores arriba antes de hacer commit.${NC}"
    exit 1
fi
