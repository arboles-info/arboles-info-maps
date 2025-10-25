# Scripts de Testing Local de Seguridad

Este directorio contiene scripts para ejecutar las mismas verificaciones de seguridad que los pipelines de GitHub Actions, pero localmente en tu máquina.

## 🚀 Inicio Rápido

### 1. Instalar herramientas de seguridad
```bash
./scripts/install-security-tools.sh
```

### 2. Ejecutar verificación rápida (equivalente a security-quick.yml)
```bash
./scripts/quick-security-check.sh
```

### 3. Ejecutar verificación completa (equivalente a security.yml)
```bash
./scripts/run-security-checks.sh
```

## 📋 Scripts Disponibles

### `install-security-tools.sh`
Instala todas las herramientas de seguridad necesarias:
- **Safety**: Análisis de vulnerabilidades en dependencias Python
- **Bandit**: Análisis de código Python
- **Semgrep**: Análisis estático avanzado
- **Checkov**: Análisis de configuración
- **Retire.js**: Análisis de librerías JavaScript
- **GitGuardian Shield**: Análisis de secretos

### `quick-security-check.sh`
Ejecuta las mismas verificaciones que el pipeline `security-quick.yml`:
- Verificación rápida de dependencias con Safety
- Análisis básico de código con Bandit
- Verificaciones manuales de patrones de seguridad comunes

### `run-security-checks.sh`
Ejecuta todas las verificaciones del pipeline principal `security.yml`:
- Análisis completo de dependencias
- Análisis completo de código Python
- Análisis estático avanzado
- Verificaciones de configuración
- Análisis de JavaScript
- Verificación de permisos de archivos

## 🔧 Configuración

### Entorno Virtual Recomendado
Se recomienda usar un entorno virtual separado para las herramientas de seguridad:

```bash
# Crear entorno virtual para seguridad
python -m venv venv-security
source venv-security/bin/activate

# Instalar herramientas
./scripts/install-security-tools.sh
```

### Variables de Entorno
Los scripts respetan las siguientes variables de entorno:

- `VIRTUAL_ENV`: Detecta si estás en un entorno virtual
- `SKIP_OPTIONAL`: Si está definida, omite verificaciones opcionales

## 📊 Interpretación de Resultados

### Códigos de Salida
- **0**: Todas las verificaciones pasaron
- **1**: Una o más verificaciones fallaron

### Niveles de Severidad
- **Critical**: Requiere atención inmediata
- **High**: Debe corregirse pronto
- **Medium**: Debe abordarse
- **Low**: Recomendación de seguridad

### Reportes Generados
Los scripts generan reportes en formato JSON:
- `safety-report.json`: Vulnerabilidades en dependencias
- `bandit-report.json`: Problemas en código Python
- `semgrep-report.json`: Análisis estático avanzado

## 🛠️ Comandos Individuales

Si prefieres ejecutar las herramientas individualmente:

### Safety (Dependencias Python)
```bash
# Verificación básica
safety check

# Verificación con reporte JSON
safety check --json --output safety-report.json

# Verificación con reporte corto
safety check --short-report
```

### Bandit (Código Python)
```bash
# Análisis básico
bandit -r .

# Análisis con formato específico
bandit -r . -f screen
bandit -r . -f json -o bandit-report.json

# Análisis con configuración personalizada
bandit -r . -c .bandit
```

### Semgrep (Análisis Estático)
```bash
# Análisis automático
semgrep --config=auto .

# Análisis con reporte JSON
semgrep --config=auto --json --output=semgrep-report.json .

# Análisis con configuración específica
semgrep --config=p/security-audit .
```

### Verificaciones Manuales
```bash
# Buscar contraseñas hardcodeadas
grep -r -i "password.*=" . --include="*.py" --include="*.js"

# Buscar tokens de API
grep -r -E "(api[_-]?key|token|secret)" . --include="*.py" --include="*.js"

# Buscar URLs HTTP inseguras
grep -r "http://" . --include="*.py" --include="*.js"
```

## 🔍 Solución de Problemas

### Error: "Herramienta no encontrada"
```bash
# Reinstalar herramientas
./scripts/install-security-tools.sh
```

### Error: "No se puede acceder al archivo"
```bash
# Verificar permisos
chmod +x scripts/*.sh
```

### Error: "Entorno virtual no activado"
```bash
# Activar entorno virtual
source venv-security/bin/activate
```

### Falsos Positivos
Si encuentras falsos positivos, puedes:
1. Actualizar los archivos de configuración (`.bandit`, `.safety`, etc.)
2. Usar comentarios `# nosec` en el código
3. Ajustar los niveles de severidad

## 📚 Recursos Adicionales

- [Documentación de Safety](https://pyup.io/safety/)
- [Documentación de Bandit](https://bandit.readthedocs.io/)
- [Documentación de Semgrep](https://semgrep.dev/docs/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## 🤝 Contribuir

Para mejorar estos scripts:
1. Haz fork del repositorio
2. Crea una rama para tu feature
3. Ejecuta los scripts localmente para probar
4. Haz commit y push de tus cambios
5. Crea un pull request

## 📝 Notas

- Los scripts están diseñados para ser ejecutados desde el directorio raíz del proyecto
- Se recomienda ejecutar las verificaciones antes de cada commit
- Los reportes JSON pueden ser procesados por herramientas de CI/CD
- Los scripts son compatibles con sistemas Unix/Linux/macOS
