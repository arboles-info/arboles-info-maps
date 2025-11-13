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

Para permitir que GitHub Actions haga push a `main`:

1. En la regla de protección de `main`, busca la sección **"Allow specified actors to bypass required pull requests"**
2. Agrega `github-actions[bot]` a la lista de actores permitidos
3. Guarda los cambios

### 3. Verificar Permisos del Workflow

El workflow necesita estos permisos (ya configurados en `release.yml`):
```yaml
permissions:
  contents: write  # Para crear tags y hacer push
  pull-requests: read
```

## Soluciones Alternativas

### Opción 1: Usar Personal Access Token (PAT)

1. Crea un PAT con permisos `repo` (full control)
2. Agrega el PAT como secret en GitHub: `Settings → Secrets and variables → Actions → New repository secret`
3. Nombre del secret: `RELEASE_TOKEN`
4. Modifica el workflow para usar el PAT:
   ```yaml
   - name: Checkout repository
     uses: actions/checkout@v5
     with:
       token: ${{ secrets.RELEASE_TOKEN }}
   ```

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

