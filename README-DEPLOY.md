# 🚀 Despliegue Rápido en Digital Ocean

## Configuración completada ✅

Tu proyecto ya está configurado para desplegarse en Digital Ocean App Platform. Los siguientes archivos fueron creados:

- `Procfile` - Especifica cómo ejecutar la aplicación
- `runtime.txt` - Versión de Python (3.13)
- `.do/app.yaml` - Configuración completa de la app
- `DEPLOYMENT.md` - Guía detallada de despliegue

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
5. Selecciona el plan **Basic-XXS** ($5/mes)
6. Click en **Create Resources**

### 3. ¡Listo! 🎉

En 2-5 minutos tendrás tu app en: `https://tu-app-xxxxx.ondigitalocean.app`

## Características

- ✅ Deploy automático con cada push a `main`
- ✅ Health checks configurados
- ✅ Puerto dinámico configurado
- ✅ Configuración optimizada para producción
- ✅ Variables de entorno pre-configuradas

## Más Información

Para instrucciones detalladas, consulta [DEPLOYMENT.md](DEPLOYMENT.md)

## Notas Importantes

1. **Puerto**: La app usa el puerto configurado por Digital Ocean (`$PORT`)
2. **CORS**: Ya está configurado para permitir todas las solicitudes
3. **Archivos estáticos**: Servidos desde `/static`
4. **Timeout**: Configurado para manejar queries largas de Overpass API

## Solución de Problemas

Si el deploy falla:
1. Revisa los logs en Digital Ocean
2. Verifica que `requirements.txt` esté actualizado
3. Asegúrate de que el puerto use `$PORT` (no hardcoded)
