# Tower Defense - LÖVE (Love2D)

## Estado actual del proyecto

El juego tiene una base jugable completa. Se puede correr con:

```bash
love /Users/zatra/projects/tower_defense
```

> Si `love` no está instalado: `brew install love`

---

## Qué está implementado

### Mapa (`src/map.lua`)
- Grid de tiles de 48x48 px, 21 columnas × 16 filas
- Tile tipo 0 = camino (color arena), tipo 1 = terreno edificable (verde)
- Sistema de waypoints que definen el recorrido de los enemigos (serpentina)
- Métodos para convertir entre coordenadas de pixel y coordenadas de tile

### Enemigos (`src/enemy.lua`)
Tres tipos, todos siguen el camino por waypoints:

| Tipo   | HP  | Velocidad | Recompensa |
|--------|-----|-----------|------------|
| basic  | 80  | 60 px/s   | 10 oro     |
| fast   | 40  | 120 px/s  | 15 oro     |
| tank   | 300 | 30 px/s   | 30 oro     |

- Barra de vida encima de cada enemigo
- Si llegan al final se descuenta una vida

### Torres (`src/tower.lua`)
Tres tipos, se colocan sobre tiles edificables:

| Tipo          | Daño | Rango | Cadencia | Costo |
|---------------|------|-------|----------|-------|
| basic         | 20   | 100   | 1/s      | $50   |
| sniper        | 80   | 200   | 0.4/s    | $100  |
| rapid         | 8    | 80    | 4/s      | $75   |

- Balas que persiguen al enemigo objetivo (homing)
- Apuntan al primer enemigo dentro de rango
- Al seleccionar una torre del panel se muestra el rango en preview

### Sistema de oleadas (`src/wave.lua`)
3 olas definidas, se inician con la tecla `N`:
- Ola 1: 10 enemigos básicos
- Ola 2: 8 básicos + 4 rápidos
- Ola 3: 10 básicos + 6 rápidos + 2 tanques

### UI (`src/ui.lua`)
- Panel lateral derecho (160px) con botones para seleccionar tipo de torre
- Muestra oro, vidas y número de ola
- Botones en gris si no hay oro suficiente
- Instrucciones de teclado en pantalla

### Loop principal (`main.lua`)
- Oro inicial: $150, Vidas: 20
- Controles: `N` = siguiente ola, `R` = reiniciar, `Esc` = deseleccionar torre
- Pantallas de Game Over y Victoria

---

## Estructura de archivos

```
tower_defense/
├── main.lua
├── conf.lua
└── src/
    ├── map.lua
    ├── enemy.lua
    ├── tower.lua
    ├── wave.lua
    └── ui.lua
```

---

## Qué sigue (backlog sugerido)

### Prioridad alta
- [ ] **Vender torres** — botón para recuperar parte del costo al hacer clic en una torre colocada
- [ ] **Seleccionar torre colocada** — al hacer clic en una torre existente mostrar su rango y stats
- [ ] **Más oleadas** — ampliar el array `WAVES` en `wave.lua` con más variedad y dificultad progresiva
- [ ] **Cooldown visual entre olas** — countdown de 10s entre ola y ola (en lugar de tecla N manual)

### Prioridad media
- [ ] **Sonidos** — disparos, muerte de enemigo, game over (usar `love.audio`)
- [ ] **Mejoras de torre** — sistema de upgrade (nivel 1→2→3) que aumente daño y rango por costo adicional
- [ ] **Enemigo volador** — ignora el camino, vuela en línea recta; solo ciertas torres pueden atacarlo
- [ ] **Proyectiles especiales** — splash damage para la torre básica, slow para una nueva torre de hielo

### Prioridad baja / polish
- [ ] **Sprites / assets** — reemplazar rectángulos y círculos con imágenes PNG
- [ ] **Animaciones** — flash al recibir daño, explosión al morir
- [ ] **Música de fondo** — loop de música ambient
- [ ] **Pantalla de inicio** — menú con "Nueva partida" y dificultad
- [ ] **Guardar highscore** — con `love.filesystem` persistir la mejor puntuación
- [ ] **Mapa editor o mapas alternativos** — múltiples layouts seleccionables

---

## Notas técnicas para retomar

- Las oleadas se definen en `src/wave.lua` → tabla `WAVES`. Fácil agregar más.
- Para agregar un tipo de enemigo: agregar entrada en `TYPES` dentro de `src/enemy.lua`.
- Para agregar un tipo de torre: agregar entrada en `TYPES` dentro de `src/tower.lua` y en `towerOrder`/`towerLabels` en `src/ui.lua`.
- El mapa se define como una matriz en `src/map.lua` → variable `layout`. Los waypoints deben coincidir con el camino (tiles con valor 0).
