# Guía de Despliegue en Digital Ocean App Platform

Esta guía te ayudará a desplegar tu aplicación OpenTrees Web en Digital Ocean App Platform desde GitHub.

## 📋 Requisitos Previos

1. **Cuenta de GitHub** con el código del proyecto subido
2. **Cuenta de Digital Ocean** (si no tienes, puedes crear una en [digitalocean.com](https://www.digitalocean.com))
3. **Repositorio de GitHub** con acceso a push

## 🚀 Pasos para Desplegar

### 1. Subir el Código a GitHub

Si aún no has subido tu código a GitHub:

```bash
# Inicializar repositorio (si no lo has hecho)
git init

# Agregar todos los archivos
git add .

# Hacer commit
git commit -m "Initial commit for Digital Ocean deployment"

# Agregar el remoto de GitHub (reemplaza con tu URL)
git remote add origin https://github.com/tu-usuario/arboles-info-maps.git

# Subir el código
git push -u origin main
```

### 2. Crear la App en Digital Ocean

1. **Inicia sesión** en [Digital Ocean Control Panel](https://cloud.digitalocean.com)
2. Ve a **Apps** en el menú lateral
3. Haz clic en **Create App**

### 3. Conectar con GitHub

1. En la pantalla de creación, selecciona **GitHub** como fuente
2. **Autoriza** Digital Ocean para acceder a tu cuenta de GitHub (si es la primera vez)
3. Selecciona el **repositorio** `arboles-info-maps`
4. Selecciona la **rama** `main` (o la que uses)

### 4. Configurar el Build

Digital Ocean detectará automáticamente la configuración basándose en los archivos:

- **`Procfile`**: Especifica cómo ejecutar la aplicación
- **`runtime.txt`**: Especifica la versión de Python
- **`.do/app.yaml`**: Configuración completa de la app

Verifica que la configuración sea:

- **Source Directory**: `/` (raíz del proyecto)
- **Build Command**: `pip install --upgrade pip && pip install -r requirements.txt`
- **Run Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`

### 5. Configurar Variables de Entorno

Si necesitas variables de entorno:

1. Ve a la sección **Environment Variables**
2. Agrega las variables necesarias
3. Por defecto, la app configurará:
   - `PYTHONUNBUFFERED=1`
   - `PORT=8080`

### 6. Seleccionar el Plan

- **Plan básico**: Comienza con `Basic` plan
- **Tamaño de instancia**: `Basic-XXS` ($5/mes) es suficiente para empezar

### 7. Nombrar tu App

1. Elige un **nombre** para tu app (ej: `opentrees-web`)
2. Selecciona una **región** cercana a tus usuarios

### 8. Revisar y Crear

1. Revisa la **configuración**
2. Haz clic en **Create Resources**
3. Digital Ocean comenzará el proceso de deploy

## 📊 Monitoreo del Deploy

Una vez iniciado el deploy:

1. Verás el **progreso** en tiempo real
2. El proceso incluye:
   - Clonar el repositorio
   - Instalar dependencias (`pip install -r requirements.txt`)
   - Construir la aplicación
   - Iniciar los contenedores
   - Ejecutar health checks

3. El deploy tomará aproximadamente **2-5 minutos**

## ✅ Verificar el Despliegue

Una vez completado el deploy:

1. Verás un **URL** como: `https://opentrees-web-xxxxx.ondigitalocean.app`
2. Haz clic en el enlace para **verificar** que la app funciona
3. Deberías ver la interfaz de OpenTrees Web

## 🔄 Actualizaciones Automáticas

Una vez configurado:

- **Cada push a `main`** triggereará un deploy automático
- Podrás ver el **historial de deploys** en la sección "Deployments"
- Puedes **rollback** a una versión anterior si es necesario

## 📝 Archivos de Configuración

### Procfile
```
web: uvicorn main:app --host 0.0.0.0 --port $PORT
```

### runtime.txt
```
python-3.13
```

### .do/app.yaml
Configuración detallada de la aplicación (ya incluido en el repo)

## 🔧 Solución de Problemas

### Error: No se puede conectar a la base de datos
- Si usas una base de datos, asegúrate de configurar las variables de entorno

### Error: Build failed
- Verifica que `requirements.txt` esté completo
- Revisa los logs de build en la interfaz de Digital Ocean

### La app no inicia
- Revisa los logs en la sección "Runtime Logs"
- Verifica que el puerto sea configurado por `$PORT`
- Asegúrate de que uvicorn esté en `requirements.txt`

### Health check falla
- Verifica que el endpoint `/` responda correctamente
- Revisa los tiempos en `.do/app.yaml`

## 💰 Costos

- **Basic Plan - XXS**: $5 USD/mes
- **Basic Plan - XS**: $12 USD/mes
- **Basic Plan - S**: $24 USD/mes

Puedes escalar cuando lo necesites.

## 🎯 Próximos Pasos

1. **Configurar dominio personalizado** (opcional):
   - Ve a Settings > Domains
   - Agrega tu dominio
   - Configura los DNS records

2. **Configurar CI/CD avanzado**:
   - Usa diferentes ramas para staging/production
   - Configura deployment branches

3. **Monitoreo y logs**:
   - Revisa los logs en tiempo real
   - Configura alertas

4. **Escalar la aplicación**:
   - Aumenta el número de instancias
   - Cambia el tamaño de instancia

## 📚 Recursos Adicionales

- [Documentación de Digital Ocean App Platform](https://docs.digitalocean.com/products/app-platform/)
- [Pricing Calculator](https://www.digitalocean.com/pricing/app-platform)
- [FastAPI Deployment Guide](https://fastapi.tiangolo.com/deployment/)

## 🆘 Soporte

Si tienes problemas con el despliegue:
1. Revisa los logs en Digital Ocean
2. Verifica la configuración en `.do/app.yaml`
3. Contacta con el soporte de Digital Ocean
