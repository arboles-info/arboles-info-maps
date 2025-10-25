# Política de Seguridad

Este documento describe las políticas y procedimientos de seguridad para el proyecto Arboles Info Maps.

## Pipelines de Seguridad

El proyecto incluye varios pipelines de GitHub Actions para mantener la seguridad del código:

### 1. Pipeline Principal de Seguridad (`security.yml`)

**Activación:**
- Push a ramas `main` y `develop`
- Pull requests a `main` y `develop`
- Ejecución diaria programada (2:00 AM UTC)

**Herramientas incluidas:**
- **CodeQL**: Análisis estático de código para detectar vulnerabilidades
- **Safety**: Verificación de vulnerabilidades en dependencias Python
- **Semgrep**: Análisis estático avanzado con múltiples reglas

### 2. Pipeline de Verificación Rápida (`security-quick.yml`)

**Activación:**
- Push a cualquier rama
- Pull requests a `main` y `develop`

**Herramientas incluidas:**
- **Safety**: Verificación rápida de dependencias
- **Verificaciones manuales**: Búsqueda de patrones de seguridad comunes

### 3. Dependabot (`dependabot.yml`)

**Activación:**
- Actualizaciones semanales automáticas
- Lunes a las 9:00 AM (hora de Madrid)

**Funcionalidades:**
- Actualización automática de dependencias Python
- Actualización automática de GitHub Actions
- Creación automática de pull requests
- Etiquetado automático de PRs

## Configuración de Herramientas

### Bandit (`.bandit`)
- **Removido**: Bandit ha sido eliminado para simplificar los pipelines
- Se mantiene el archivo de configuración por compatibilidad

### Safety (`.safety`)
- Nivel de reporte: medium
- Incluye información de remediación
- Verifica solo dependencias instaladas

### Semgrep (`.semgrepignore`)
- Excluye directorios de dependencias y cache
- Excluye archivos de configuración y logs
- Permite personalización por proyecto

### TruffleHog (`.trufflehogignore`)
- **Removido**: TruffleHog ha sido eliminado para simplificar los pipelines
- Se mantiene el archivo de configuración por compatibilidad

## Interpretación de Resultados

### Códigos de Salida
- **0**: Sin problemas de seguridad detectados
- **1**: Problemas de seguridad detectados (requiere atención)

### Niveles de Severidad
- **Critical**: Vulnerabilidades críticas que requieren atención inmediata
- **High**: Vulnerabilidades importantes que deben corregirse pronto
- **Medium**: Problemas de seguridad que deben abordarse
- **Low**: Problemas menores o recomendaciones de seguridad

### Tipos de Problemas Comunes

1. **Vulnerabilidades en Dependencias**
   - Solución: Actualizar a versiones seguras
   - Usar `pip install --upgrade package-name`

2. **Secretos Hardcodeados**
   - Solución: Usar variables de entorno
   - Nunca commitear credenciales

3. **Código Inseguro**
   - Solución: Revisar y corregir según las recomendaciones
   - Usar alternativas seguras

4. **Configuración Insegura**
   - Solución: Ajustar configuración según mejores prácticas
   - Revisar permisos y configuraciones

## Procedimientos de Respuesta

### Para Vulnerabilidades Críticas
1. Evaluar el impacto inmediatamente
2. Crear un hotfix si es necesario
3. Actualizar dependencias vulnerables
4. Notificar al equipo de seguridad

### Para Problemas de Seguridad en PRs
1. Revisar los reportes de seguridad
2. Corregir los problemas identificados
3. Re-ejecutar los pipelines
4. No hacer merge hasta que todos los checks pasen

### Para Actualizaciones de Dependencias
1. Revisar el changelog de la dependencia
2. Probar en entorno de desarrollo
3. Verificar que no hay breaking changes
4. Aplicar la actualización

## Mejores Prácticas

### Desarrollo Seguro
- Nunca hardcodear credenciales o secretos
- Usar HTTPS en producción
- Validar todas las entradas de usuario
- Mantener dependencias actualizadas
- Revisar regularmente los logs de seguridad

### Gestión de Secretos
- Usar variables de entorno para configuración sensible
- Usar servicios de gestión de secretos en producción
- Rotar credenciales regularmente
- No incluir archivos `.env` en el repositorio

### Dependencias
- Revisar regularmente las dependencias
- Usar versiones específicas en producción
- Mantener un registro de licencias
- Evaluar dependencias antes de añadirlas

## Contacto

Para reportar vulnerabilidades de seguridad, contacta con:
- Email: [email de seguridad]
- GitHub: Crea un issue privado

## Recursos Adicionales

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Python Security Best Practices](https://python-security.readthedocs.io/)
- [GitHub Security Advisories](https://github.com/advisories)
- [Safety Documentation](https://pyup.io/safety/)
- [Bandit Documentation](https://bandit.readthedocs.io/)
