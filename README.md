# Tower Defense — LÖVE 11.5

Juego de tower defense desarrollado en Lua con el framework LÖVE.  
~1950 líneas de código en 11 archivos.

## Cómo correr

```bash
open -n -a /Applications/love.app --args /Users/zatra/projects/tower_defense
```

> LÖVE debe estar en `/Applications/love.app` (descargado de love2d.org, versión 11.5).

---

## Estructura de archivos

```
tower_defense/
├── main.lua            — loop principal + máquina de estados
├── conf.lua            — configuración de ventana (1168×768)
├── src/
│   ├── levels.lua      — definiciones de los 3 niveles (layout, waypoints, oleadas)
│   ├── map.lua         — renderizado del mapa y conversión de coordenadas
│   ├── wave.lua        — sistema de oleadas (spawn por grupos)
│   ├── enemy.lua       — enemigos con armadura, slow, debuf de armor
│   ├── tower.lua       — torres con sistema de upgrade y balas con efectos
│   ├── ui.lua          — panel lateral (construcción + panel de upgrade de torre)
│   ├── menu.lua        — menú principal minimalista con fondo de estrellas
│   ├── slotselect.lua  — pantalla de selección de ranura de guardado
│   ├── levelselect.lua — mapa de niveles visual con nodos conectados
│   └── saves.lua       — guardado por ranura (niveles completados)
└── assets/             — (vacío, sin sprites aún)
```

---

## Estados del juego (main.lua)

```
"menu" → "slots" → "levelmap" → "game"
```

- **menu** — menú principal (Jugar / Opciones / Créditos / Salir)
- **slots** — selección de ranura (3 ranuras, muestra niveles completados)
- **levelmap** — mapa de niveles: 3 nodos conectados, animación de pulso en disponibles
- **game** — partida activa

Teclas en partida: `Espacio` iniciar/saltar ola · `R` reiniciar · `M` volver al mapa · `Esc` cancelar selección

---

## Niveles (`src/levels.lua`)

| # | Nombre            | Forma del camino | Entrada | Oleadas | Oro inicial |
|---|-------------------|-----------------|---------|---------|-------------|
| 1 | Bosque del Norte  | Serpentina (4 giros) | Izquierda | 3 | 150 |
| 2 | Ruinas del Este   | U (3 horizontales)   | Izquierda | 3 | 150 |
| 3 | Volcán del Sur    | Zigzag (5 giros)     | Arriba    | 3 | 175 |

Cada nivel define: `layout` (grid 21×16), `waypoints`, `waves`, `goldStart`, `livesStart`, colores de tiles.

---

## Enemigos (`src/enemy.lua`)

| Tipo  | HP  | Velocidad | Armadura | Recompensa | Radio |
|-------|-----|-----------|----------|------------|-------|
| basic | 80  | 60 px/s   | 0%       | 10 oro     | 10    |
| fast  | 40  | 120 px/s  | 0%       | 15 oro     | 8     |
| tank  | 300 | 30 px/s   | 45%      | 30 oro     | 14    |

**Efectos en enemigos:**
- `armor` — reduce el daño recibido (tanque = 0.45)
- `slowTimer / slowFactor` — ralentiza la velocidad (azul claro encima del enemigo)
- `armorDebufTimer / armorDebufPct` — reduce temporalmente la armadura
- Overlay azul semitransparente cuando está bajo slow

**API:** `enemy:applySlow(dur, factor)` · `enemy:applyArmorDebuf(dur, pct)` · `enemy:takeDamage(amount, opts)`

`opts` puede incluir: `armorIgnore` (0–1), `instakillAt` (ratio HP para instamatar)

---

## Torres (`src/tower.lua`)

### Tipos base

| Tipo   | Daño | Rango | Cadencia | Costo | Ignora armor |
|--------|------|-------|----------|-------|--------------|
| basic  | 20   | 100   | 1.0/s    | $50   | 0%           |
| sniper | 80   | 200   | 0.4/s    | $100  | 50%          |
| rapid  | 8    | 80    | 4.0/s    | $75   | 0%           |

### Sistema de upgrades (nivel 1 → 2 → 3A/3B)

**Básica:**
- L2 ($75): daño 32, rango 115, cadencia 1.3/s
- L3-A **Cañón** ($110): daño 55, splash r=38, cadencia 0.8/s
- L3-B **Shocker** ($110): daño 28, slow 55% por 2s

**Francotirador:**
- L2 ($125): daño 135, rango 245, cadencia 0.5/s
- L3-A **Élite** ($160): daño 220, ignora 100% armor, instakill <22% HP
- L3-B **Artillero** ($160): daño 100, debuf de armor -55% por 3s

**Rápida:**
- L2 ($100): daño 13, rango 90, cadencia 5.5/s
- L3-A **Minigun** ($130): daño 11, cadencia 9/s
- L3-B **Frost** ($130): daño 9, slow 62% por 2.5s

Nivel visual: la torre cambia de color e indica puntos debajo del sprite según el nivel.  
Vender: 50% de la inversión total acumulada.

### Balas (`Bullet` dentro de tower.lua)

Campos: `splash` (radio 0=sin splash), `slowDur`, `slowFactor`, `armorIgnore`, `armorDebufPct`, `armorDebufDur`, `instakillAt`.

---

## UI (`src/ui.lua`)

Panel lateral derecho (160px, desde x=1008):

**Modo construcción:**
- 3 botones de tipo de torre (grises si no hay oro)
- Oro / Vidas / Ola actuales
- Instrucciones de teclado

**Modo upgrade (clic en torre colocada):**
- Nombre, nivel, stats de la torre seleccionada
- Botón de upgrade a L2 (si nivel 1)
- Dos botones de especialización A/B (si nivel 2)
- Botón "Vender $X" (siempre)

Comportamiento del cursor:
- Al colocar una torre el cursor se **auto-deselecciona** (vuelve a modo normal)
- Para colocar otra hay que volver a hacer clic en el botón del panel
- Clic en tile vacío → modo construcción; clic en torre → modo upgrade

---

## Habilidad Guante — Mover Torre

Botón en la esquina superior derecha del mapa (x≈940, y=8, 56×56px), dibujado como mano con primitivas.

- **Cooldown:** 30 segundos (barra de llenado visible en el botón)
- **Uso:** clic al guante → modo mover (torres se iluminan en amarillo)
  - Clic en una torre → la levanta (flota en el cursor)
  - Clic en tile válido → la deposita y activa cooldown
- `Esc` cancela el modo sin gastar cooldown

---

## Sistema de guardado (`src/saves.lua`)

Formato por ranura (`slot1.sav`, `slot2.sav`, `slot3.sav`):
```
date=16/05/2026 21:30
completed=1,2
```

- `Saves.loadAll()` → tabla de 3 ranuras (nil si vacía)
- `Saves.setCompleted(slotIdx, levelIdx, existingSlot)` → guarda al completar nivel
- `Saves.delete(slotIdx)` → borra ranura
- `Saves.countCompleted(slotData)` → número de niveles completados

Se guarda automáticamente al completar cada nivel.  
El mapa de niveles muestra ✓ en niveles completados y desbloquea el siguiente.

---

## Oleadas (`src/wave.lua`)

- **Cooldown entre olas:** 15 segundos automáticos (o `Espacio` para saltar)
- Indicador en el punto de spawn: "Ola X en Ns [Espacio]"
- Preview de la siguiente ola justo debajo del indicador
- `wave:nextWavePreview()` → descripción de la siguiente ola

---

## Backlog sugerido (siguiente sesión)

### Alta prioridad
- [ ] **Sonidos** — disparos, muerte de enemigo, game over, música de fondo (`love.audio`)
- [ ] **Más oleadas** — ampliar WAVES en `levels.lua` (actualmente 3 oleadas por nivel)
- [ ] **Enemigo Sanador** — cura a enemigos cercanos, obliga a priorizar eliminación
- [ ] **Pantalla de resultado** — estrellas (1–3) al terminar un nivel según vidas restantes
- [ ] **Oro bonus** — al saltar ola antes del countdown: `15 * segs_restantes / 15` de oro extra

### Media prioridad
- [ ] **Sprites/assets PNG** — reemplazar rectángulos y círculos con imágenes
- [ ] **Sistema de estrellas permanente** — gastables en upgrades globales entre niveles
- [ ] **Animaciones** — flash al recibir daño, explosión al morir
- [ ] **Más niveles** — actualmente 3; fácil agregar en `levels.lua`
- [ ] **Opciones funcionales** — volumen de sonido, resolución

### Baja prioridad / polish
- [ ] **Cursor personalizado** — imagen de mano cuando guante está activo
- [ ] **Efectos de partículas** — `love.graphics.newParticleSystem`
- [ ] **Pantalla de inicio animada** — parallax o intro
- [ ] **Editor de mapas**

---

## Notas técnicas

### Agregar un nuevo tipo de enemigo
1. Añadir entrada en `TYPES` en `src/enemy.lua` con `hp`, `speed`, `armor`, `color`, `reward`, `radius`
2. Usarlo en las definiciones de oleadas en `src/levels.lua`

### Agregar un nuevo nivel
1. Añadir `L[4] = {...}` en `src/levels.lua` con `layout` (grid de tiles), `waypoints`, `waves`, colores
2. Agregar nodo en `NODES` en `src/levelselect.lua` con coordenadas del mapa de niveles
3. Actualizar `MAX_LEVELS = 4` en `src/slotselect.lua`

### Agregar un nuevo tipo de torre
1. Añadir entrada en `TYPES` en `src/tower.lua` con stats base y `upgrades`
2. Añadir a `towerOrder` y `towerLabels` en `src/ui.lua`

### Cambiar balance de dificultad
- Oleadas: editar `waves` por nivel en `src/levels.lua`
- Stats de torres: editar `TYPES` en `src/tower.lua`
- Stats de enemigos: editar `TYPES` en `src/enemy.lua`
- Cooldown entre olas: `WAVE_DELAY` en `main.lua` (actualmente 15s)
- Cooldown del guante: `GLOVE_CD` en `main.lua` (actualmente 30s)
