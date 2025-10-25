/**
 * OpenTrees Web - Aplicación JavaScript
 * Visualizador de árboles y tocones de Rota, Cádiz usando datos de OpenStreetMap
 */

// Variables globales
let map;
let treeLayer;
let stumpLayer;
let treeCount = 0;
let stumpCount = 0;
let autoUpdateEnabled = true;
let autoFitBoundsEnabled = true;
let isUpdatingBbox = false;
let isProgrammaticMove = false;

// Estado de visibilidad de las capas
let layerVisibility = {
    trees: true,
    stumps: true
};

// Almacenar datos de árboles para estadísticas
let treesData = [];
let stumpsData = [];

/**
 * Inicialización de la aplicación
 */
document.addEventListener('DOMContentLoaded', function() {
    initializeMap();
    initializeEventListeners();
    loadSpecies();
    updateBboxFromMap();
});

/**
 * Inicializar el mapa de Leaflet
 */
function initializeMap() {
    // Crear el mapa centrado en Rota
    map = L.map('map').setView([36.627719378319, -6.3697957992555], 13);
    
    // Añadir capa de tiles de OpenStreetMap
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);
    
    // Crear capas para árboles y tocones
    treeLayer = L.layerGroup().addTo(map);
    stumpLayer = L.layerGroup().addTo(map);
    
    // Event listeners para el mapa
    map.on('moveend', onMapMoveEnd);
    map.on('zoomend', onMapMoveEnd);
}

/**
 * Inicializar event listeners para los controles
 */
function initializeEventListeners() {
    // Event listeners para controles
    document.getElementById('species').addEventListener('change', loadData);
    document.getElementById('bbox').addEventListener('change', function() {
        if (!isUpdatingBbox) {
            loadData();
        }
    });
    document.getElementById('limit').addEventListener('change', loadData);
    document.getElementById('autoUpdate').addEventListener('change', function() {
        autoUpdateEnabled = this.checked;
    });
    document.getElementById('autoFitBounds').addEventListener('change', function() {
        autoFitBoundsEnabled = this.checked;
    });
    
    // Event listeners para la leyenda
    initializeLegendListeners();
}

/**
 * Mostrar/ocultar indicador de carga
 * @param {boolean} show - Mostrar o ocultar el loading
 */
function showLoading(show) {
    const loading = document.getElementById('loading');
    if (show) {
        loading.classList.add('show');
    } else {
        loading.classList.remove('show');
    }
}

/**
 * Actualizar estadísticas en la interfaz
 */
function updateStats() {
    document.getElementById('tree-count').textContent = treeCount;
    document.getElementById('stump-count').textContent = stumpCount;
    document.getElementById('total-count').textContent = treeCount + stumpCount;
    
    // Actualizar desglose por especies
    updateSpeciesBreakdown();
}

/**
 * Actualizar el desglose de especies en las estadísticas
 */
function updateSpeciesBreakdown() {
    const speciesList = document.getElementById('species-list');
    
    if (treesData.length === 0) {
        speciesList.innerHTML = '<p class="no-data">No hay datos cargados</p>';
        return;
    }
    
    // Contar especies
    const speciesCount = {};
    treesData.forEach(tree => {
        const species = tree.species || 'No especificada';
        speciesCount[species] = (speciesCount[species] || 0) + 1;
    });
    
    // Ordenar por cantidad (descendente)
    const sortedSpecies = Object.entries(speciesCount)
        .sort(([,a], [,b]) => b - a);
    
    // Generar HTML
    if (sortedSpecies.length === 0) {
        speciesList.innerHTML = '<p class="no-data">No hay especies identificadas</p>';
        return;
    }
    
    const html = sortedSpecies.map(([species, count]) => `
        <div class="species-item">
            <span class="species-name">${species}</span>
            <span class="species-count">${count}</span>
        </div>
    `).join('');
    
    speciesList.innerHTML = html;
}

/**
 * Crear contenido del popup para árboles
 * @param {Object} tree - Datos del árbol
 * @returns {string} HTML del popup
 */
function createTreePopup(tree) {
    let content = `<div class="popup-content">
        <h4 class="popup-title popup-tree-title">🌳 Árbol</h4>
        <p class="popup-info"><strong>Especie:</strong> ${tree.species || 'No especificada'}</p>`;
    
    if (tree.height) content += `<p class="popup-info"><strong>Altura:</strong> ${tree.height}m</p>`;
    if (tree.diameter) content += `<p class="popup-info"><strong>Diámetro:</strong> ${tree.diameter}cm</p>`;
    if (tree.age) content += `<p class="popup-info"><strong>Edad:</strong> ${tree.age} años</p>`;
    if (tree.health) content += `<p class="popup-info"><strong>Salud:</strong> ${tree.health}</p>`;
    
    content += `<p class="popup-coordinates"><strong>Coordenadas:</strong> ${tree.lat.toFixed(6)}, ${tree.lon.toFixed(6)}</p>`;
    content += `</div>`;
    
    return content;
}

/**
 * Crear contenido del popup para tocones
 * @param {Object} stump - Datos del tocón
 * @returns {string} HTML del popup
 */
function createStumpPopup(stump) {
    let content = `<div class="popup-content">
        <h4 class="popup-title popup-stump-title">🪵 Tocón</h4>
        <p class="popup-info"><strong>Especie:</strong> ${stump.species || 'No especificada'}</p>`;
    
    if (stump.diameter) content += `<p class="popup-info"><strong>Diámetro:</strong> ${stump.diameter}cm</p>`;
    if (stump.reason) content += `<p class="popup-info"><strong>Razón de tala:</strong> ${stump.reason}</p>`;
    
    content += `<p class="popup-coordinates"><strong>Coordenadas:</strong> ${stump.lat.toFixed(6)}, ${stump.lon.toFixed(6)}</p>`;
    content += `</div>`;
    
    return content;
}

/**
 * Cargar especies disponibles desde la API
 */
async function loadSpecies() {
    try {
        const response = await fetch('/api/species');
        const data = await response.json();
        
        const speciesSelect = document.getElementById('species');
        speciesSelect.innerHTML = '<option value="">Todas las especies</option>';
        
        data.species.forEach(species => {
            const option = document.createElement('option');
            option.value = species;
            option.textContent = species;
            speciesSelect.appendChild(option);
        });
    } catch (error) {
        console.error('Error al cargar especies:', error);
    }
}

/**
 * Cargar datos de árboles y tocones desde la API
 */
async function loadData() {
    showLoading(true);
    
    const species = document.getElementById('species').value;
    const bbox = document.getElementById('bbox').value;
    const limit = document.getElementById('limit').value;
    
    try {
        // Limpiar capas existentes
        treeLayer.clearLayers();
        stumpLayer.clearLayers();
        treeCount = 0;
        stumpCount = 0;
        
        // Limpiar datos almacenados
        treesData = [];
        stumpsData = [];
        
        // Resetear visibilidad de capas
        layerVisibility.trees = true;
        layerVisibility.stumps = true;
        
        // Construir parámetros de consulta
        const params = new URLSearchParams();
        if (species) params.append('species', species);
        if (bbox) params.append('bbox', bbox);
        if (limit) params.append('limit', limit);
        
        // Cargar árboles y tocones en paralelo
        const [treesResponse, stumpsResponse] = await Promise.all([
            fetch(`/api/trees?${params}`),
            fetch(`/api/stumps?${params}`)
        ]);
        
        const trees = await treesResponse.json();
        const stumps = await stumpsResponse.json();
        
        // Almacenar datos de árboles y añadir al mapa
        treesData = trees;
        trees.forEach(tree => {
            const marker = L.circleMarker([tree.lat, tree.lon], {
                radius: 6,
                fillColor: '#2d5016',
                color: '#1a3009',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.8
            });
            
            marker.bindPopup(createTreePopup(tree));
            treeLayer.addLayer(marker);
            treeCount++;
        });
        
        // Almacenar datos de tocones y añadir al mapa
        stumpsData = stumps;
        stumps.forEach(stump => {
            const marker = L.circleMarker([stump.lat, stump.lon], {
                radius: 5,
                fillColor: '#8b4513',
                color: '#5d2e0a',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.8
            });
            
            marker.bindPopup(createStumpPopup(stump));
            stumpLayer.addLayer(marker);
            stumpCount++;
        });
        
        // Actualizar estadísticas
        updateStats();
        
        // Aplicar el estado de visibilidad (reseteado a visible)
        applyLayerVisibility();
        
        // Ajustar vista del mapa si hay datos y está habilitado
        if (autoFitBoundsEnabled && (trees.length > 0 || stumps.length > 0)) {
            adjustMapView(trees, stumps);
        }
        
    } catch (error) {
        console.error('Error al cargar datos:', error);
        alert('Error al cargar los datos. Por favor, inténtalo de nuevo.');
    } finally {
        showLoading(false);
    }
}

/**
 * Aplicar el estado de visibilidad actual de las capas
 */
function applyLayerVisibility() {
    // Aplicar visibilidad a la capa de árboles
    if (layerVisibility.trees) {
        if (!map.hasLayer(treeLayer)) {
            map.addLayer(treeLayer);
        }
        document.getElementById('legend-trees').classList.remove('hidden');
    } else {
        if (map.hasLayer(treeLayer)) {
            map.removeLayer(treeLayer);
        }
        document.getElementById('legend-trees').classList.add('hidden');
    }
    
    // Aplicar visibilidad a la capa de tocones
    if (layerVisibility.stumps) {
        if (!map.hasLayer(stumpLayer)) {
            map.addLayer(stumpLayer);
        }
        document.getElementById('legend-stumps').classList.remove('hidden');
    } else {
        if (map.hasLayer(stumpLayer)) {
            map.removeLayer(stumpLayer);
        }
        document.getElementById('legend-stumps').classList.add('hidden');
    }
    
    // Actualizar indicadores visuales
    updateLegendIndicator('trees');
    updateLegendIndicator('stumps');
}

/**
 * Ajustar la vista del mapa para mostrar todos los marcadores
 * @param {Array} trees - Array de árboles
 * @param {Array} stumps - Array de tocones
 */
function adjustMapView(trees, stumps) {
    const allMarkers = [...trees, ...stumps];
    
    if (allMarkers.length === 0) return;
    
    const group = new L.featureGroup();
    allMarkers.forEach(item => {
        group.addLayer(L.marker([item.lat, item.lon]));
    });
    
    const dataBounds = group.getBounds();
    const currentBounds = map.getBounds();
    
    // Solo ajustar si los datos están significativamente fuera del área visible actual
    const dataCenter = dataBounds.getCenter();
    const currentCenter = currentBounds.getCenter();
    const distance = dataCenter.distanceTo(currentCenter);
    
    // Si el centro de los datos está a más de 1km del centro actual, ajustar
    if (distance > 1000 || !currentBounds.contains(dataBounds)) {
        // Marcar como movimiento programático para evitar bucles
        isProgrammaticMove = true;
        map.fitBounds(dataBounds.pad(0.1));
        setTimeout(() => {
            isProgrammaticMove = false;
        }, 500);
    }
}

/**
 * Limpiar el mapa de todos los marcadores
 */
function clearMap() {
    treeLayer.clearLayers();
    stumpLayer.clearLayers();
    treeCount = 0;
    stumpCount = 0;
    
    // Limpiar datos almacenados
    treesData = [];
    stumpsData = [];
    
    updateStats();
    
    // Resetear estado de visibilidad
    layerVisibility.trees = true;
    layerVisibility.stumps = true;
    
    // Aplicar estado de visibilidad
    applyLayerVisibility();
}

/**
 * Actualizar el bbox basado en los límites actuales del mapa
 * @returns {string} String del bbox actualizado
 */
function updateBboxFromMap() {
    isUpdatingBbox = true;
    
    const bounds = map.getBounds();
    const southWest = bounds.getSouthWest();
    const northEast = bounds.getNorthEast();
    
    const bboxString = `${southWest.lat.toFixed(12)},${southWest.lng.toFixed(12)},${northEast.lat.toFixed(12)},${northEast.lng.toFixed(12)}`;
    
    const bboxInput = document.getElementById('bbox');
    bboxInput.value = bboxString;
    
    // Restaurar la bandera después de un pequeño delay
    setTimeout(() => {
        isUpdatingBbox = false;
    }, 100);
    
    return bboxString;
}

/**
 * Inicializar event listeners para la leyenda
 */
function initializeLegendListeners() {
    // Event listener para árboles
    document.getElementById('legend-trees').addEventListener('click', function() {
        toggleLayer('trees');
    });
    
    // Event listener para tocones
    document.getElementById('legend-stumps').addEventListener('click', function() {
        toggleLayer('stumps');
    });
}

/**
 * Alternar la visibilidad de una capa
 * @param {string} layerType - Tipo de capa ('trees' o 'stumps')
 */
function toggleLayer(layerType) {
    // Cambiar el estado de visibilidad
    layerVisibility[layerType] = !layerVisibility[layerType];
    
    // Obtener el elemento de la leyenda
    const legendElement = document.getElementById(`legend-${layerType}`);
    
    // Actualizar la capa correspondiente
    if (layerType === 'trees') {
        if (layerVisibility[layerType]) {
            map.addLayer(treeLayer);
            legendElement.classList.remove('hidden');
        } else {
            map.removeLayer(treeLayer);
            legendElement.classList.add('hidden');
        }
    } else if (layerType === 'stumps') {
        if (layerVisibility[layerType]) {
            map.addLayer(stumpLayer);
            legendElement.classList.remove('hidden');
        } else {
            map.removeLayer(stumpLayer);
            legendElement.classList.add('hidden');
        }
    }
    
    // Actualizar el indicador visual
    updateLegendIndicator(layerType);
}

/**
 * Actualizar el indicador visual de la leyenda
 * @param {string} layerType - Tipo de capa ('trees' o 'stumps')
 */
function updateLegendIndicator(layerType) {
    const legendElement = document.getElementById(`legend-${layerType}`);
    const indicator = legendElement.querySelector('.toggle-indicator');
    
    if (layerVisibility[layerType]) {
        indicator.textContent = '👁️';
        indicator.style.opacity = '1';
    } else {
        indicator.textContent = '🙈';
        indicator.style.opacity = '0.5';
    }
}

/**
 * Manejar el evento de fin de movimiento del mapa
 */
function onMapMoveEnd() {
    if (autoUpdateEnabled && !isProgrammaticMove) {
        updateBboxFromMap();
    }
}
