# 🚀 Despliegue Rápido en Digital Ocean

## Configuración completada ✅

Tu proyecto Django está configurado para desplegarse en Digital Ocean App Platform. Los siguientes archivos están configurados:

- `Procfile` - Especifica cómo ejecutar la aplicación con Gunicorn
- `runtime.txt` - Versión de Python (3.13)
- `requirements.txt` - Incluye Django 5.2 y Gunicorn

## Pasos Rápidos (5 minutos)

### 1. Sube tu código a GitHub
```bash
git add .
git commit -m "Prepare for Digital Ocean deployment"
git push origin main
```

### 2. Crea la App en Digital Ocean

1. Ve a [Digital Ocean Control Panel](https://cloud.digitalocean.com)
2. Click en **Apps** → **Create App**
3. Conecta tu repositorio de GitHub
4. Digital Ocean detectará automáticamente la configuración
5. **Configura el Build Command**:
   ```
   pip install --upgrade pip && pip install -r requirements.txt && python manage.py collectstatic --noinput
   ```
6. Selecciona el plan **Basic-XXS** ($5/mes)
7. Click en **Create Resources**

### 3. Configura Variables de Entorno

**IMPORTANTE**: Después de crear la app, configura estas variables de entorno en Digital Ocean:

1. Ve a **Settings** → **App-Level Environment Variables**
2. Agrega las siguientes variables:

   - **SECRET_KEY**: Genera uno seguro con:
     ```bash
     python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
     ```
   
   - **DEBUG**: `False` (para producción)
   
   - **ALLOWED_HOSTS**: `arboles.info,*.ondigitalocean.app` (ajusta según tu dominio)

### 4. ¡Listo! 🎉

En 2-5 minutos tendrás tu app en: `https://arboles-info-xxxxx.ondigitalocean.app`

## Características

- ✅ Deploy automático con cada push a `main`
- ✅ Servidor Gunicorn para producción
- ✅ Puerto dinámico configurado (`$PORT`)
- ✅ Configuración optimizada para producción
- ✅ Archivos estáticos recopilados automáticamente
- ✅ Seguridad configurada (SSL, HSTS, etc.)

## Notas Importantes

1. **Framework**: Django 5.2 con Gunicorn como servidor WSGI
2. **Puerto**: La app usa el puerto configurado por Digital Ocean (`$PORT`)
3. **Archivos estáticos**: Se recopilan con `collectstatic` durante el build y se sirven desde `STATIC_ROOT`
4. **Variables de entorno**: SECRET_KEY, DEBUG y ALLOWED_HOSTS son **obligatorias** en producción
5. **Timeout**: Configurado para manejar queries largas de Overpass API
6. **Base de datos**: Actualmente no se usa base de datos (solo consultas a Overpass API)

## Solución de Problemas

Si el deploy falla:

1. **Revisa los logs en Digital Ocean** - Ve a la sección "Runtime Logs"
2. **Verifica que `requirements.txt` esté actualizado** - Debe incluir `gunicorn>=21.2.0`
3. **Verifica las variables de entorno**:
   - `SECRET_KEY` debe estar configurado
   - `DEBUG` debe ser `False` en producción
   - `ALLOWED_HOSTS` debe incluir tu dominio y `*.ondigitalocean.app`
4. **Verifica el Build Command** - Debe incluir `python manage.py collectstatic --noinput`
5. **Error "DisallowedHost"**: Asegúrate de que `ALLOWED_HOSTS` incluya el dominio de Digital Ocean
6. **Error "Static files not found"**: Verifica que `collectstatic` se ejecute en el build command
7. **Error de puerto**: Asegúrate de que el Procfile use `$PORT` (no hardcoded)

## Comandos Útiles

### Generar SECRET_KEY
```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### Probar localmente con Gunicorn
```bash
pip install gunicorn
python manage.py collectstatic --noinput
gunicorn arboles_info_project.wsgi:application --bind 0.0.0.0:8000
```
