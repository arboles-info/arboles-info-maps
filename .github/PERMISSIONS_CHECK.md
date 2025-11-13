# Verificación de Permisos para GitHub Actions

## Problema

Si el workflow de release falla con el error:
```
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: - Cannot update this protected ref.
```

Significa que la rama `main` está protegida y el token `GITHUB_TOKEN` no tiene permisos para hacer push directo.

## Cómo Verificar los Permisos

### 1. Verificar Reglas de Protección de Rama

1. Ve a: `https://github.com/arboles-info/arboles-info-webpage/settings/rules`
2. Busca la regla de protección para la rama `main`
3. Verifica las siguientes configuraciones:
   - **Require pull request reviews before merging**: Si está activado, puede bloquear pushes directos
   - **Require status checks to pass before merging**: Puede requerir que los workflows pasen
   - **Restrict who can push to matching branches**: Puede estar restringido

### 2. Permitir Bypass para GitHub Actions

**⚠️ IMPORTANTE:** `github-actions[bot]` **NO aparece** en la lista de usuarios/equipos que pueden ser añadidos a las excepciones de las reglas de protección de rama. Esto es porque `github-actions[bot]` no es un usuario o equipo tradicional, sino una cuenta de servicio interna de GitHub.

**Solución:** Debes usar un **Personal Access Token (PAT)** asociado a una cuenta de usuario con permisos adecuados. Ver la sección "Opción 1" más abajo.

### 3. Verificar Permisos del Workflow

El workflow necesita estos permisos (ya configurados en `release.yml`):
```yaml
permissions:
  contents: write  # Para crear tags y hacer push
  pull-requests: read
```

## Soluciones Alternativas

### Opción 1: Usar Personal Access Token (PAT) ⭐ RECOMENDADO

Esta es la solución recomendada por GitHub cuando `github-actions[bot]` no puede ser añadido al bypass.

#### Pasos para implementar:

1. **Crear un Personal Access Token (PAT):**
   - Ve a: https://github.com/settings/tokens
   - Haz clic en "Generate new token" → "Generate new token (classic)"
   - Asigna un nombre descriptivo (ej: `arboles-info-maps-release`)
   - Selecciona los permisos necesarios:
     - ✅ `repo` (Full control of private repositories) - Esto incluye permisos para hacer push a ramas protegidas
   - Haz clic en "Generate token"
   - **⚠️ IMPORTANTE:** Copia el token inmediatamente, no podrás verlo de nuevo

2. **Agregar el PAT como secret en el repositorio:**
   - Ve a: `https://github.com/arboles-info/arboles-info-webpage/settings/secrets/actions`
   - Haz clic en "New repository secret"
   - Nombre: `RELEASE_TOKEN`
   - Valor: Pega el PAT que copiaste
   - Haz clic en "Add secret"

3. **El workflow ya está configurado para usar el PAT:**
   - El workflow usa `${{ secrets.RELEASE_TOKEN }}` si está disponible
   - Si no está disponible, usa `${{ secrets.GITHUB_TOKEN }}` como fallback
   - Con el PAT, las operaciones se ejecutarán con los permisos de la cuenta asociada al PAT

#### Notas de seguridad:
- El PAT debe pertenecer a una cuenta con permisos de escritura en el repositorio
- El PAT otorga los permisos de la cuenta asociada, así que asegúrate de que la cuenta tenga solo los permisos necesarios
- Nunca expongas el PAT en logs o código público

### Opción 2: No Pushear el Commit de Bump

El workflow actual está configurado para:
- ✅ Crear y pushear el tag (esto funciona)
- ⚠️ Intentar pushear el commit de bump (puede fallar si la rama está protegida)

Si el commit de bump no se puede pushear, el tag seguirá funcionando correctamente. Los archivos de versión (`__version__.py`, `pyproject.toml`, `CHANGELOG.md`) se actualizarán localmente pero no se pushearán automáticamente.

### Opción 3: Cambiar Estrategia de Commit

En lugar de que Commitizen cree un commit automáticamente, podríamos:
1. Usar `cz bump --no-commit` para solo actualizar archivos
2. Crear el commit manualmente con permisos adecuados
3. O simplemente no commitear los cambios de versión

## Estado Actual

El workflow está configurado para:
- ✅ Crear tags automáticamente (funciona)
- ⚠️ Intentar pushear commits de bump (puede fallar si la rama está protegida)
- ✅ Continuar aunque el push del commit falle (no rompe el workflow)

## Recomendación

La mejor solución es **Opción 1** o configurar el bypass para `github-actions[bot]` en las reglas de protección de la rama `main`.

