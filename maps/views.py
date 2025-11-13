"""
Vistas de la aplicación maps
"""
import logging
import time
import asyncio
from datetime import datetime
from typing import Optional, List
from django.http import JsonResponse, HttpRequest, HttpResponse
from django.shortcuts import render
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings
import os
import httpx
from pydantic import BaseModel

# Configurar logging
logger = logging.getLogger(__name__)

# Configuración de la API de Overpass
OVERPASS_URL = "https://overpass-api.de/api/interpreter"


# Modelos Pydantic (mantenidos de FastAPI)
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

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }


class Stump(BaseModel):
    id: str
    lat: float
    lon: float
    species: Optional[str] = None
    diameter: Optional[float] = None
    removal_date: Optional[datetime] = None
    reason: Optional[str] = None

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }


# Funciones auxiliares
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
        raise Exception(f"Timeout al consultar Overpass API")
    except httpx.HTTPStatusError as e:
        total_time = time.time() - start_time
        status_code = e.response.status_code
        logger.error(f"Error HTTP {status_code} consultando Overpass API en {total_time:.2f}s. Response: {e.response.text[:200]}")
        if status_code == 504:
            raise Exception(f"Gateway Timeout desde Overpass API")
        raise Exception(f"Error HTTP {status_code} al consultar Overpass API")
    except httpx.RequestError as e:
        total_time = time.time() - start_time
        logger.error(f"Error de conexión consultando Overpass API en {total_time:.2f}s: {str(e)}")
        raise Exception(f"Error de conexión con Overpass API: {str(e)}")
    except Exception as e:
        total_time = time.time() - start_time
        logger.error(f"Error inesperado consultando Overpass API en {total_time:.2f}s: {str(e)}")
        raise Exception(f"Error inesperado al consultar Overpass API: {str(e)}")


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
    """Ejecuta la consulta a Overpass con reintentos en caso de timeout."""
    attempt = 0
    delay = initial_delay
    while True:
        try:
            return await query_overpass(query)
        except Exception as exc:
            error_msg = str(exc)
            if "504" in error_msg or "Timeout" in error_msg:
                if attempt < max_retries:
                    attempt += 1
                    logger.warning(f"Intento {attempt}/{max_retries} tras timeout de Overpass. Reintentando en {delay:.1f}s")
                    await asyncio.sleep(delay)
                    delay *= backoff_factor
                    continue
            # No es timeout o se agotaron los reintentos
            raise


# Vistas de páginas
def welcome(request: HttpRequest):
    """Página de bienvenida"""
    return render(request, 'welcome.html')


def mapa(request: HttpRequest):
    """Página del mapa interactivo"""
    return render(request, 'mapa.html')


def robots_txt(request: HttpRequest):
    """Servir robots.txt"""
    robots_path = os.path.join(settings.BASE_DIR, 'static', 'robots.txt')
    try:
        with open(robots_path, 'r') as f:
            content = f.read()
        return HttpResponse(content, content_type='text/plain')
    except FileNotFoundError:
        # Si no existe, devolver un robots.txt básico
        return HttpResponse('User-agent: *\nDisallow:', content_type='text/plain')


# Vistas API
@csrf_exempt
@require_http_methods(["GET"])
async def get_trees(request: HttpRequest):
    """
    Obtiene árboles de OSM en un área específica
    
    Args:
        bbox: Bounding box en formato "min_lat,min_lon,max_lat,max_lon"
        limit: Número máximo de resultados (máximo 1000)
        timeout: Timeout para la consulta Overpass
    """
    start_time = time.time()
    logger.info(f"Starting endpoint /api/trees")
    
    bbox = request.GET.get('bbox')
    limit = int(request.GET.get('limit', 500))
    timeout = int(request.GET.get('timeout', 6000))
    
    logger.info(f"Parámetros recibidos - bbox: {bbox}, limit: {limit}, timeout: {timeout}")
    
    if not bbox:
        logger.warning("No se proporcionó bbox, devolviendo lista vacía")
        return JsonResponse([], safe=False)
    
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
                return JsonResponse([], safe=False)
            
            # Procesar elementos
            processed_count = 0
            error_count = 0
            
            for element in elements[:limit]:
                if element.get("type") == "node":
                    try:
                        tree = parse_tree_element(element)
                        trees.append(tree.model_dump())
                        processed_count += 1
                    except Exception as e:
                        error_count += 1
                        logger.error(f"Error parsing tree element {element.get('id', 'unknown')}: {e}")
                        continue
            
            total_time = time.time() - start_time
            logger.info("Finished endpoint /api/trees")
            logger.info(f"Árboles procesados: {processed_count}, Errores: {error_count}, Tiempo total: {total_time:.2f}s")
            
            return JsonResponse(trees, safe=False)
            
        except Exception as e:
            total_time = time.time() - start_time
            logger.error("Error happened in /api/trees")
            logger.error(f"Error: {str(e)}. Tiempo total: {total_time:.2f}s")
            return JsonResponse({'error': f'Error interno del servidor: {str(e)}'}, status=500)
    
    except Exception as e:
        total_time = time.time() - start_time
        logger.error("Error happened in parsing bbox in /api/trees")
        logger.error(f"Error parsing bbox: {str(e)}. Tiempo total: {total_time:.2f}s")
        return JsonResponse({'error': f'Error en formato de bbox: {str(e)}'}, status=400)


@csrf_exempt
@require_http_methods(["GET"])
async def get_stumps(request: HttpRequest):
    """
    Obtiene tocones de OSM en un área específica
    
    Args:
        bbox: Bounding box en formato "min_lat,min_lon,max_lat,max_lon" (required)
        limit: Número máximo de resultados (default: 500, máximo 1000)
        timeout: Timeout para la consulta Overpass
    """
    start_time = time.time()
    logger.info("Starting endpoint /api/stumps")
    
    bbox = request.GET.get('bbox')
    limit = int(request.GET.get('limit', 500))
    timeout = int(request.GET.get('timeout', 6000))
    
    logger.info(f"Parámetros recibidos - bbox: {bbox}, limit: {limit}, timeout: {timeout}")
    
    if not bbox:
        logger.warning("No se proporcionó bbox, devolviendo lista vacía")
        return JsonResponse([], safe=False)

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
                return JsonResponse([], safe=False)
            
            # Procesar elementos
            processed_count = 0
            error_count = 0
            
            for element in elements[:limit]:
                if element.get("type") == "node":
                    try:
                        stump = parse_stump_element(element)
                        stumps.append(stump.model_dump())
                        processed_count += 1
                    except Exception as e:
                        error_count += 1
                        logger.error(f"Error parsing stump element {element.get('id', 'unknown')}: {e}")
                        continue
            
            total_time = time.time() - start_time
            logger.info("Finished endpoint /api/stumps")
            logger.info(f"Tocones procesados: {processed_count}, Errores: {error_count}, Tiempo total: {total_time:.2f}s")
            
            return JsonResponse(stumps, safe=False)
            
        except Exception as e:
            total_time = time.time() - start_time
            logger.error("Error happened in /api/stumps")
            logger.error(f"Error: {str(e)}. Tiempo total: {total_time:.2f}s")
            # Devolver lista vacía en lugar de fallar
            logger.warning("Devolviendo lista vacía debido a error")
            return JsonResponse([], safe=False)
    
    except Exception as e:
        total_time = time.time() - start_time
        logger.error("Error happened in parsing bbox in /api/stumps")
        logger.error(f"Error parsing bbox: {str(e)}. Tiempo total: {total_time:.2f}s")
        # Devolver lista vacía en lugar de fallar
        logger.warning("Devolviendo lista vacía debido a error de parsing")
        return JsonResponse([], safe=False)
