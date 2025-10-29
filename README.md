# OpenTrees Web

Una aplicación web para visualizar árboles y tocones usando datos de OpenStreetMap (OSM) a través de la API de Overpass.

## Características

- 🌳 Visualización de árboles y tocones en un mapa interactivo
- 🗺️ Interfaz web moderna con Leaflet.js
- 🔍 Filtrado por especie y área geográfica
- 📊 Estadísticas en tiempo real
- 🚀 API REST con FastAPI
- 📱 Diseño responsive

## Tecnologías

- **Backend**: FastAPI (Python)
- **Frontend**: HTML5, CSS3, JavaScript, Leaflet.js
- **Datos**: OpenStreetMap via Overpass API
- **Servidor**: Uvicorn

## Instalación

### Verificar dependencias del sistema

Primero, verifica qué dependencias están disponibles:

```bash
make check-deps
```

### Opción 1: Con virtualenv (recomendado)

Si tienes `python3-venv` instalado:

```bash
make setup
```

### Opción 2: Sin virtualenv

Si no tienes `python3-venv` pero sí `pip`:

```bash
make install-system
```

### Opción 3: Instalación manual

Si no tienes `make` instalado:

1. Instala pip (si no lo tienes):
```bash
sudo apt install python3-pip
```

2. Instala las dependencias:
```bash
pip3 install -r requirements.txt
```

3. Ejecuta el servidor:
```bash
python3 main.py
```

## Uso

Una vez configurado, abre tu navegador y ve a:
```
http://localhost:8000
```

### Comandos disponibles

- `make check-deps` - Verificar dependencias del sistema
- `make setup` - Crear virtualenv e instalar dependencias
- `make install` - Instalar dependencias en virtualenv existente
- `make install-system` - Instalar dependencias del sistema (sin virtualenv)
- `make run` - Levantar la aplicación
- `make dev` - Modo desarrollo con recarga automática
- `make clean` - Limpiar archivos temporales
- `make clean-venv` - Eliminar virtualenv
- `make test` - Ejecutar tests (si existen)
- `make lint` - Verificar código con linters
- `make format` - Formatear código
- `make info` - Mostrar información del entorno
- `make help` - Mostrar ayuda

## API Endpoints

### GET /
Sirve la página principal de la aplicación.

### GET /api/trees
Obtiene árboles de OSM en un área específica.

**Parámetros:**
- `bbox` (opcional): Bounding box en formato "min_lat,min_lon,max_lat,max_lon"
- `species` (opcional): Filtrar por especie específica
- `limit` (opcional): Número máximo de resultados (default: 100)

**Ejemplo:**
```
GET /api/trees?bbox=40.3,-3.8,40.5,-3.6&species=Quercus&limit=50
```

### GET /api/stumps
Obtiene tocones de OSM en un área específica.

**Parámetros:**
- `bbox` (opcional): Bounding box en formato "min_lat,min_lon,max_lat,max_lon"
- `species` (opcional): Filtrar por especie específica
- `limit` (opcional): Número máximo de resultados (default: 100)

## Estructura del Proyecto

```
opentrees-web/
├── main.py              # Aplicación FastAPI principal
├── requirements.txt     # Dependencias de Python
├── Makefile            # Makefile con comandos de desarrollo
├── .gitignore          # Archivos a ignorar en Git
├── static/
│   └── index.html      # Frontend HTML con Leaflet.js
└── README.md           # Este archivo
```

## Modelos de Datos

### Tree
- `id`: Identificador único
- `lat`, `lon`: Coordenadas geográficas
- `species`: Especie del árbol
- `height`: Altura en metros
- `diameter`: Diámetro en centímetros
- `age`: Edad en años
- `health`: Estado de salud
- `last_updated`: Fecha de última actualización

### Stump
- `id`: Identificador único
- `lat`, `lon`: Coordenadas geográficas
- `species`: Especie del tocón
- `diameter`: Diámetro en centímetros
- `removal_date`: Fecha de tala
- `reason`: Razón de la tala

## Personalización

### Cambiar el área por defecto
Modifica las coordenadas en `main.py` en las funciones `get_trees()` y `get_stumps()`:

```python
# Bounding box por defecto (Madrid, España)
min_lat, min_lon, max_lat, max_lon = 40.3, -3.8, 40.5, -3.6
```

### Añadir más filtros
Puedes extender las consultas de Overpass para incluir más filtros como:
- Estado de salud del árbol
- Edad mínima/máxima
- Altura mínima/máxima

### Personalizar el mapa
Modifica el archivo `static/index.html` para:
- Cambiar el estilo del mapa
- Añadir más capas
- Personalizar los marcadores

## Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Agradecimientos

- [OpenStreetMap](https://www.openstreetmap.org/) por los datos geográficos
- [Overpass API](https://overpass-api.de/) por la API de consulta
- [Leaflet](https://leafletjs.com/) por la librería de mapas
- [FastAPI](https://fastapi.tiangolo.com/) por el framework web
