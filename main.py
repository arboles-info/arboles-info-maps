from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import httpx
import asyncio
from datetime import datetime
import logging

logger = logging.getLogger(__name__)
logger.addHandler(logging.StreamHandler())
logger.setLevel(logging.INFO)

app = FastAPI(title="OpenTrees Web", description="Aplicación para visualizar árboles y tocones usando datos de OSM")

# Configurar archivos estáticos
app.mount("/static", StaticFiles(directory="static"), name="static")

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
    """Realiza una consulta a la API de Overpass"""
    async with httpx.AsyncClient(timeout=5.0) as client:
        try:
            response = await client.post(OVERPASS_URL, data=query, headers={
                'User-Agent': 'OpenTrees-Web/1.0'
            })
            response.raise_for_status()
            return response.json()
        except httpx.TimeoutException:
            raise HTTPException(status_code=504, detail="Timeout al consultar Overpass API")
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=502, detail=f"Error HTTP {e.response.status_code} al consultar Overpass API")
        except httpx.RequestError as e:
            raise HTTPException(status_code=503, detail=f"Error de conexión con Overpass API: {str(e)}")
        except Exception as e:
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

@app.get("/")
async def read_root():
    """Endpoint raíz que sirve la página principal"""
    try:
        with open("static/index.html", "r", encoding="utf-8") as f:
            content = f.read()
        return HTMLResponse(content=content)
    except FileNotFoundError:
        return HTMLResponse(content="<h1>Error: Archivo index.html no encontrado</h1>", status_code=404)

@app.get("/api/trees", response_model=List[Tree])
async def get_trees(
    bbox: Optional[str] = None,
    species: Optional[str] = None,
    limit: int = 500
):
    """
    Obtiene árboles de OSM en un área específica
    
    Args:
        bbox: Bounding box en formato "min_lat,min_lon,max_lat,max_lon"
        species: Filtrar por especie específica
        limit: Número máximo de resultados
    """
    if not bbox:
        return []
    else:
        min_lat, min_lon, max_lat, max_lon = map(float, bbox.split(","))
        bbox_str = bbox
    
    # Query Overpass para árboles
    if species:
        query = f"""
        [out:json][timeout:2500];
        (
          node["natural"="tree"]["species"="{species}"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out center;
        """
    else:
        query = f"""
        [out:json][timeout:2500];
        (
          node["natural"="tree"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out center;
        """
    
    try:
        result = await query_overpass(query)
        trees = []

        if not result.get("elements"):
            return []
        
        for element in result.get("elements")[:limit]:
            if element.get("type") == "node":
                try:
                    trees.append(parse_tree_element(element))
                except Exception as e:
                    logger.error(f"Error parsing tree element: {e}")
                    continue
        
        return trees
    except HTTPException:
        logger.error(f"Error getting trees: {HTTPException}")
        raise

@app.get("/api/stumps", response_model=List[Stump])
async def get_stumps(
    bbox: str = None,
    species: Optional[str] = None,
    limit: Optional[int] = 500
):
    """
    Obtiene tocones de OSM en un área específica
    
    Args:
        bbox: Bounding box en formato "min_lat,min_lon,max_lat,max_lon" (required)
        species: Filtrar por especie específica (default: "all")
        limit: Número máximo de resultados (default: 500)
    """
    if not bbox:
        return []

    min_lat, min_lon, max_lat, max_lon = map(float, bbox.split(","))
    bbox_str = bbox

    logger.debug(f"Getting stumps for bbox: {bbox_str}")
    logger.debug(f"Getting stumps for species: {species}")
    logger.debug(f"Getting stumps for limit: {limit}")
    
    # Query Overpass para tocones (optimizada)
    if species:
        query = f"""
        [out:json][timeout:2500];
        (
          node["natural"="tree_stump"]["species"="{species}"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out {limit};
        """
    else:
        query = f"""
        [out:json][timeout:2500];
        (
          node["natural"="tree_stump"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out {limit};
        """
    
    try:
        result = await query_overpass(query)
        stumps = []
        
        for element in result.get("elements", [])[:limit]:
            if element.get("type") == "node":
                try:
                    stumps.append(parse_stump_element(element))
                except Exception as e:
                    logger.error(f"Error parsing stump element: {e}")
                    continue
        

        return stumps
    except HTTPException:
        # Si hay error con Overpass API, devolver datos de ejemplo
        return []

@app.get("/api/species")
async def get_species():
    """Obtiene lista de especies disponibles en OSM"""
    try:
        # Query para obtener especies únicas en un área pequeña
        query = """
        [out:json][timeout:2500];
        (
          node["natural"="tree"]["species"](36.613770852449,-6.410994529724,36.641667904189,-6.328597068787);
          node["natural"="tree_stump"]["species"](36.613770852449,-6.410994529724,36.641667904189,-6.328597068787);
        );
        out;
        """
        
        result = await query_overpass(query)
        species = set()
        
        for element in result.get("elements", []):
            if element.get("tags", {}).get("species"):
                species.add(element["tags"]["species"])
        
        # Si no hay especies en el área por defecto, devolver algunas comunes
        if not species:
            species = {
                "Quercus", "Pinus", "Platanus", "Populus", "Ulmus", 
                "Acer", "Fraxinus", "Tilia", "Betula", "Salix"
            }
        
        return {"species": sorted(list(species))}
    except Exception as e:
        # En caso de error, devolver especies comunes
        species = {
            "Quercus", "Pinus", "Platanus", "Populus", "Ulmus", 
            "Acer", "Fraxinus", "Tilia", "Betula", "Salix"
        }
        return {"species": sorted(list(species))}

if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
