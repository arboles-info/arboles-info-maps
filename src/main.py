from fastapi import FastAPI, HTTPException, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, PlainTextResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import httpx
import asyncio
from datetime import datetime
import logging
import time
import sys
from pathlib import Path

# Configurar logging detallado (solo stdout)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

app = FastAPI(title="Mapa de árboles y tocones", description="Aplicación para visualizar árboles y tocones usando datos de OSM")

# Rutas de archivos basadas en la ubicación de este archivo
HERE = Path(__file__).resolve().parent
STATIC_DIR = HERE / "static"

# Configurar archivos estáticos
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware de logging para todas las peticiones HTTP
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # Log de la petición entrante
    logger.info(f"🔵 REQUEST: {request.method} {request.url.path}")
    logger.info(f"Query params: {dict(request.query_params)}")
    logger.info(f"Client IP: {request.client.host if request.client else 'unknown'}")
    
    # Procesar la petición
    try:
        response = await call_next(request)
        
        # Calcular tiempo de procesamiento
        process_time = time.time() - start_time
        
        # Log de la respuesta
        logger.info(f"🟢 RESPONSE: {response.status_code} - {process_time:.3f}s")
        
        # Agregar header con tiempo de procesamiento
        response.headers["X-Process-Time"] = str(process_time)
        
        return response
        
    except Exception as e:
        process_time = time.time() - start_time
        logger.error(f"🔴 ERROR: {str(e)} - {process_time:.3f}s")
        raise

# Modelos de datos
class Tree(BaseModel):
    id: str
    lat: float
    lon: float
    species: Optional[str] = None
    height: Optional[float] = None
    diameter: Optional[float] = None
    age: Optional[int] = None
    health: Optional[str] = None
    last_updated: Optional[datetime] = None

class Stump(BaseModel):
    id: str
    lat: float
    lon: float
    species: Optional[str] = None
    diameter: Optional[float] = None
    removal_date: Optional[datetime] = None
    reason: Optional[str] = None

class OverpassResponse(BaseModel):
    elements: List[dict]

# Configuración de la API de Overpass
OVERPASS_URL = "https://overpass-api.de/api/interpreter"

async def query_overpass(query: str) -> dict:
    """Realiza una consulta a la API de Overpass en una sola petición (sin reintentos)."""
    start_time = time.time()
    logger.info(f"Iniciando consulta a Overpass API. Query length: {len(query)} chars")
    logger.debug(f"Query Overpass: {query[:200]}...")  # Log solo los primeros 200 chars

    timeout = httpx.Timeout(60.0, connect=10.0, read=60.0, write=10.0)

    try:
        request_start = time.time()
        async with httpx.AsyncClient(timeout=timeout) as client:
            logger.debug(f"Enviando POST a {OVERPASS_URL} con timeout: {timeout}")
            response = await client.post(OVERPASS_URL, data=query, headers={
                'User-Agent': 'Mapa-Arboles-Tocones/1.0'
            })

        response_time = time.time() - request_start
        logger.info(f"Respuesta recibida en {response_time:.2f}s. Status: {response.status_code}")

        response.raise_for_status()
        result = response.json()

        total_time = time.time() - start_time
        elements_count = len(result.get("elements", []))
        logger.info(f"Consulta exitosa. Elementos encontrados: {elements_count}. Tiempo total: {total_time:.2f}s")

        return result

    except httpx.TimeoutException as e:
        total_time = time.time() - start_time
        logger.error(f"TIMEOUT consultando Overpass API en {total_time:.2f}s: {str(e)}")
        raise HTTPException(status_code=504, detail="Timeout al consultar Overpass API")
    except httpx.HTTPStatusError as e:
        total_time = time.time() - start_time
        status_code = e.response.status_code
        logger.error(f"Error HTTP {status_code} consultando Overpass API en {total_time:.2f}s. Response: {e.response.text[:200]}")
        # Preservar 504 para permitir reintentos aguas arriba
        if status_code == 504:
            raise HTTPException(status_code=504, detail="Gateway Timeout desde Overpass API")
        raise HTTPException(status_code=502, detail=f"Error HTTP {status_code} al consultar Overpass API")
    except httpx.RequestError as e:
        total_time = time.time() - start_time
        logger.error(f"Error de conexión consultando Overpass API en {total_time:.2f}s: {str(e)}")
        raise HTTPException(status_code=503, detail=f"Error de conexión con Overpass API: {str(e)}")
    except Exception as e:
        total_time = time.time() - start_time
        logger.error(f"Error inesperado consultando Overpass API en {total_time:.2f}s: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error inesperado al consultar Overpass API: {str(e)}")


def parse_tree_element(element: dict) -> Tree:
    """Convierte un elemento de OSM en un objeto Tree"""
    tags = element.get("tags", {})
    return Tree(
        id=f"tree_{element['id']}",
        lat=element["lat"],
        lon=element["lon"],
        species=tags.get("species"),
        height=float(tags["height"]) if tags.get("height") else None,
        diameter=float(tags["diameter"]) if tags.get("diameter") else None,
        age=int(tags["age"]) if tags.get("age") and type(tags["age"]) == int else None,
        health=tags.get("health"),
        last_updated=datetime.now()
    )

def parse_stump_element(element: dict) -> Stump:
    """Convierte un elemento de OSM en un objeto Stump"""
    tags = element.get("tags", {})
    return Stump(
        id=f"stump_{element['id']}",
        lat=element["lat"],
        lon=element["lon"],
        species=tags.get("species"),
        diameter=float(tags["diameter"]) if tags.get("diameter") else None,
        removal_date=datetime.now(),  # OSM no suele tener esta info
        reason=tags.get("removal_reason")
    )

async def query_overpass_with_retry(query: str, max_retries: int = 2, initial_delay: float = 1.5, backoff_factor: float = 2.0) -> dict:
    """Ejecuta la consulta a Overpass con reintentos en caso de 504 (timeout gateway o cliente).

    - Reintenta solo ante HTTPException con status 504
    - Backoff exponencial entre intentos
    """
    attempt = 0
    delay = initial_delay
    while True:
        try:
            return await query_overpass(query)
        except HTTPException as exc:
            if exc.status_code == 504 and attempt < max_retries:
                attempt += 1
                logger.warning(f"Intento {attempt}/{max_retries} tras 504 de Overpass. Reintentando en {delay:.1f}s")
                await asyncio.sleep(delay)
                delay *= backoff_factor
                continue
            # No es 504 o se agotaron los reintentos
            raise

@app.get("/", include_in_schema=False)
async def read_index():
    """Endpoint raíz que sirve la página de índice"""
    try:
        with open(STATIC_DIR / "welcome.html", "r", encoding="utf-8") as f:
            content = f.read()
        return HTMLResponse(content=content)
    except FileNotFoundError:
        return HTMLResponse(content="<h1>Error: Archivo welcome.html no encontrado</h1>", status_code=404)

@app.get("/mapa", include_in_schema=False)
async def read_map():
    """Endpoint que sirve la página principal del mapa"""
    try:
        with open(STATIC_DIR / "index.html", "r", encoding="utf-8") as f:
            content = f.read()
        return HTMLResponse(content=content)
    except FileNotFoundError:
        return HTMLResponse(content="<h1>Error: Archivo index.html no encontrado</h1>", status_code=404)

@app.get("/api/trees", response_model=List[Tree])
async def get_trees(
    bbox: Optional[str] = None,
    limit: int = 500,
    timeout: int = 6000
):
    """
    Obtiene árboles de OSM en un área específica
    
    Args:
        bbox: Bounding box en formato "min_lat,min_lon,max_lat,max_lon"
        limit: Número máximo de resultados (máximo 1000)
    """
    start_time = time.time()
    logger.info(f"Starting endpoint /api/trees")
    logger.info(f"Parámetros recibidos - bbox: {bbox}, limit: {limit}, timeout: {timeout}")
    
    if not bbox:
        logger.warning("No se proporcionó bbox, devolviendo lista vacía")
        return []
    
    try:
        if not timeout:
            logger.warning("Timeout not provided, using default value of 6000 seconds")
            timeout = 6000
            
        min_lat, min_lon, max_lat, max_lon = map(float, bbox.split(","))
        bbox_str = bbox
        logger.info(f"Bbox parseado - min_lat: {min_lat}, min_lon: {min_lon}, max_lat: {max_lat}, max_lon: {max_lon}")
        
        # Limitar el límite para evitar consultas demasiado grandes
        original_limit = limit
        limit = min(limit, 1000)
        if original_limit != limit:
            logger.warning(f"Límite reducido de {original_limit} a {limit} (máximo permitido)")
        
        # Calcular área del bbox para ajustar límite dinámicamente
        area = abs(max_lat - min_lat) * abs(max_lon - min_lon)
        logger.info(f"Área del bbox: {area:.6f}")
        
        if area > 0.01:  # Área muy grande
            limit = min(limit, 200)
            logger.warning(f"Área muy grande detectada, limitando a {limit} elementos")
        elif area > 0.005:  # Área grande
            limit = min(limit, 500)
            logger.info(f"Área grande detectada, limitando a {limit} elementos")
    
        # Query Overpass para árboles (optimizada)
        query = f"""
        [out:json][timeout:{timeout}];
        (
          node["natural"="tree"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out center {limit};
        """
        logger.info("Query para obtener árboles sin filtro de especie")
        
        logger.info(f"Ejecutando consulta Overpass con timeout: {timeout}s")
        query_start = time.time()
        
        try:
            result = await query_overpass_with_retry(query)
            query_time = time.time() - query_start
            logger.info(f"Consulta Overpass completada en {query_time:.2f}s")
            
            trees = []
            elements = result.get("elements", [])
            logger.info(f"Elementos raw recibidos de Overpass: {len(elements)}")

            if not elements:
                logger.warning("No se encontraron elementos en la respuesta de Overpass")
                return []
            
            # Procesar elementos
            processed_count = 0
            error_count = 0
            
            for element in elements[:limit]:
                if element.get("type") == "node":
                    try:
                        tree = parse_tree_element(element)
                        trees.append(tree)
                        processed_count += 1
                    except Exception as e:
                        error_count += 1
                        logger.error(f"Error parsing tree element {element.get('id', 'unknown')}: {e}")
                        continue
            
            total_time = time.time() - start_time
            logger.info("Finished endpoint /api/trees")
            logger.info(f"Árboles procesados: {processed_count}, Errores: {error_count}, Tiempo total: {total_time:.2f}s")
            
            return trees
            
        except HTTPException as e:
            total_time = time.time() - start_time
            logger.error("HTTPException happened in /api/trees")
            logger.error(f"HTTPException: {e.detail}. Tiempo total: {total_time:.2f}s")
            raise
        except Exception as e:
            total_time = time.time() - start_time
            logger.error("Unexpected error happened in /api/trees")
            logger.error(f"Error: {str(e)}. Tiempo total: {total_time:.2f}s")
            raise HTTPException(status_code=500, detail=f"Error interno del servidor: {str(e)}")
    
    except Exception as e:
        total_time = time.time() - start_time
        logger.error("Error happened in parsing bbox in /api/trees")
        logger.error(f"Error: {str(e)}")
        logger.error(f"Error parsing bbox: {str(e)}. Tiempo total: {total_time:.2f}s")
        raise HTTPException(status_code=400, detail=f"Error en formato de bbox: {str(e)}")

@app.get("/api/stumps", response_model=List[Stump])
async def get_stumps(
    bbox: str = None,
    limit: Optional[int] = 500,
    timeout: int = 6000
):
    """
    Obtiene tocones de OSM en un área específica
    
    Args:
        bbox: Bounding box en formato "min_lat,min_lon,max_lat,max_lon" (required)
        limit: Número máximo de resultados (default: 500, máximo 1000)
    """
    start_time = time.time()
    logger.info("Starting endpoint /api/stumps")
    logger.info(f"Parámetros recibidos - bbox: {bbox}, limit: {limit}, timeout: {timeout}")
    
    if not bbox:
        logger.warning("No se proporcionó bbox, devolviendo lista vacía")
        return []

    try:
        min_lat, min_lon, max_lat, max_lon = map(float, bbox.split(","))
        bbox_str = bbox
        logger.info(f"Bbox parseado - min_lat: {min_lat}, min_lon: {min_lon}, max_lat: {max_lat}, max_lon: {max_lon}")
        
        if not timeout:
            logger.warning("Timeout not provided, using default value of 6000 seconds")
            timeout = 6000
        
        # Limitar el límite para evitar consultas demasiado grandes
        original_limit = limit
        limit = min(limit, 1000)
        if original_limit != limit:
            logger.warning(f"Límite reducido de {original_limit} a {limit} (máximo permitido)")
        
        # Calcular área del bbox para ajustar límite dinámicamente
        area = abs(max_lat - min_lat) * abs(max_lon - min_lon)
        logger.info(f"Área del bbox: {area:.6f}")
        
        if area > 0.01:  # Área muy grande
            limit = min(limit, 200)
            logger.warning(f"Área muy grande detectada, limitando a {limit} elementos")
        elif area > 0.005:  # Área grande
            limit = min(limit, 500)
            logger.info(f"Área grande detectada, limitando a {limit} elementos")

        logger.debug(f"Getting stumps for bbox: {bbox_str}")
        logger.debug(f"Getting stumps for limit: {limit}")
    
        # Query Overpass para tocones (optimizada)
        query = f"""
        [out:json][timeout:{timeout}];
        (
          node["natural"="tree_stump"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out {limit};
        """
        logger.info("Query para obtener tocones sin filtro de especie")
        
        logger.info(f"Ejecutando consulta Overpass con timeout: {timeout}s")
        query_start = time.time()
        
        try:
            result = await query_overpass_with_retry(query)
            query_time = time.time() - query_start
            logger.info(f"Consulta Overpass completada en {query_time:.2f}s")
            
            stumps = []
            elements = result.get("elements", [])
            logger.info(f"Elementos raw recibidos de Overpass: {len(elements)}")
            
            if not elements:
                logger.warning("No se encontraron elementos en la respuesta de Overpass")
                return []
            
            # Procesar elementos
            processed_count = 0
            error_count = 0
            
            for element in elements[:limit]:
                if element.get("type") == "node":
                    try:
                        stump = parse_stump_element(element)
                        stumps.append(stump)
                        processed_count += 1
                    except Exception as e:
                        error_count += 1
                        logger.error(f"Error parsing stump element {element.get('id', 'unknown')}: {e}")
                        continue
            
            total_time = time.time() - start_time
            logger.info("Finished endpoint /api/stumps")
            logger.info(f"Tocones procesados: {processed_count}, Errores: {error_count}, Tiempo total: {total_time:.2f}s")
            
            return stumps
            
        except HTTPException as e:
            total_time = time.time() - start_time
            logger.error("HTTPException happened in /api/stumps")
            logger.error(f"HTTPException: {e.detail}. Tiempo total: {total_time:.2f}s")
            # Si hay error con Overpass API, devolver lista vacía en lugar de fallar
            logger.warning("Devolviendo lista vacía debido a error de Overpass API")
            return []
        except Exception as e:
            total_time = time.time() - start_time
            logger.error("Unexpected error happened in /api/stumps")
            logger.error(f"Error: {str(e)}. Tiempo total: {total_time:.2f}s")
            # Devolver lista vacía en lugar de fallar
            logger.warning("Devolviendo lista vacía debido a error inesperado")
            return []
    
    except Exception as e:
        total_time = time.time() - start_time
        logger.error("Error happened in parsing bbox in /api/stumps")
        logger.error(f"Error parsing bbox: {str(e)}. Tiempo total: {total_time:.2f}s")
        # Devolver lista vacía en lugar de fallar
        logger.warning("Devolviendo lista vacía debido a error de parsing")
        return []


if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.environ.get("PORT", 8000))
    # Configuración con timeouts más generosos para consultas largas
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=port,
        timeout_keep_alive=120,  # Mantener conexiones vivas por 2 minutos
        timeout_graceful_shutdown=30  # Tiempo para cerrar conexiones gracefully
    )


