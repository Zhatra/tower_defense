# Tower Defense — LÖVE 11.5

Juego de tower defense desarrollado en Lua con el framework LÖVE.

## Como correr

```bash
open -n -a /Applications/love.app --args /Users/zatra/projects/tower_defense
```

> LÖVE debe estar en `/Applications/love.app` (descargado de love2d.org, version 11.5).

---

## Estructura de archivos

```
tower_defense/
├── main.lua            — loop principal + maquina de estados
├── conf.lua            — configuracion de ventana (1168×768)
├── STYLE.md            — guia de estilo visual (paleta, fuentes, pixel art)
├── src/
│   ├── levels.lua      — 10 niveles (layout, waypoints, oleadas, stats)
│   ├── map.lua         — renderizado del mapa y conversion de coordenadas
│   ├── wave.lua        — sistema de oleadas (spawn por grupos, avance anticipado)
│   ├── enemy.lua       — enemigos con armadura, slow, debuf de armor
│   ├── tower.lua       — 5 tipos de torres, upgrades bifurcados, guerreros, mortero
│   ├── ui.lua          — panel lateral (construccion + upgrade de torre seleccionada)
│   ├── menu.lua        — menu principal con fondo de estrellas
│   ├── slotselect.lua  — seleccion de ranura de guardado (3 ranuras)
│   ├── levelselect.lua — mapa de niveles con 10 nodos en curva S
│   └── saves.lua       — guardado por ranura (niveles completados)
└── assets/             — (vacio, sin sprites aun)
```

---

## Estado actual del juego

### Maquina de estados (`main.lua`)

```
"menu" → "slots" → "levelmap" → "game"
```

- **menu** — menu principal (Jugar / Opciones / Creditos / Salir)
- **slots** — seleccion de ranura (3 ranuras, muestra X/10 niveles completados)
- **levelmap** — mapa de 10 nodos en curva S, desbloqueo progresivo
- **game** — partida activa (con pausa, guante para mover torres, preview de olas)

### Controles en partida

| Tecla / Boton     | Accion                                      |
|-------------------|---------------------------------------------|
| Click en mapa     | Colocar torre seleccionada                  |
| Click en torre    | Ver mejoras / vender                        |
| Espacio           | Acelerar countdown entre olas               |
| Craneo (boton)    | Ver siguiente ola; avanzar ola (+20g) si disponible |
| Guante (boton)    | Mover una torre colocada (CD 30s)           |
| Pausa (boton)     | Pausar la partida                           |
| Esc               | Pausar / Cancelar seleccion activa          |
| R                 | Reiniciar nivel                             |
| M                 | Volver al mapa de niveles                   |

---

## Niveles (`src/levels.lua`)

10 niveles, cada uno con layout unico, camino distinto y color de tiles propio.

| #  | Oleadas | Entrada  | Oro inicial | Vidas |
|----|---------|----------|-------------|-------|
| 1  | 6       | Izquierda| 150         | 20    |
| 2  | 7       | Izquierda| 160         | 20    |
| 3  | 8       | Arriba   | 175         | 20    |
| 4–7| 11      | Varios   | 175–200     | 20    |
| 8–10| 13     | Varios   | 200         | 20    |

---

## Enemigos (`src/enemy.lua`)

| Tipo  | HP  | Velocidad | Armadura | Recompensa |
|-------|-----|-----------|----------|------------|
| basic | 120 | 45 px/s   | 0%       | 10 oro     |
| fast  | 60  | 90 px/s   | 0%       | 15 oro     |
| tank  | 450 | 22 px/s   | 45%      | 30 oro     |

Cada enemigo genera un camino con offset aleatorio ±10px en waypoints intermedios.

**Efectos:** `slowTimer/slowFactor` (overlay azul), `armorDebufTimer/armorDebufPct`

---

## Torres (`src/tower.lua`)

5 tipos, sistema de upgrades L1 → L2 → L3A / L3B (especializacion bifurcada).
Las torres priorizan al enemigo mas avanzado en el camino.

| Tipo    | Daño | Rango | Cad.   | Costo | Especial              |
|---------|------|-------|--------|-------|-----------------------|
| Basica  | 20   | 100   | 1.0/s  | $50   | Splash (L3A), Slow (L3B) |
| Franco. | 80   | 200   | 0.4/s  | $100  | Ignora armor 50%      |
| Rapida  | 8    | 80    | 4.0/s  | $75   | Slow (L3B), Minigun (L3A) |
| Cuartel | —    | 130   | —      | $100  | 3 guerreros fisicos   |
| Mortero | 70   | 160   | 0.4/s  | $125  | Splash en area, arco parabolico |

**Guante:** mueve una torre ya colocada a otro tile (CD 30s). Boton esquina superior derecha.

**Venta:** 50% de la inversion total acumulada.

---

## Sistema de Guerreros (torre Cuartel)

- 3 guerreros por torre, cada uno con estados: `idle → moving → fighting → respawning`
- El guerrero reserva un enemigo (`enemy.engagedBy = warrior`) y el enemigo se detiene inmediatamente
- Si el guerrero muere → respawn en 8s (L1), 6s (L2), 5s/3s (L3A/B)
- Al mover la torre con el guante, los `homeX/homeY` de los guerreros se actualizan

---

## Sistema de Oleadas (`src/wave.lua`)

- **Cooldown entre olas:** 15 segundos automaticos
- **Espacio:** salta el countdown restante (no lanza ola mid-combat)
- **Avanzar ola anticipado:** disponible 9 segundos despues de iniciar cada ola.
  Boton verde ">> Avanzar +20g" aparece en el popup del craneo.
  Da 20 de oro bonus por lanzar la siguiente ola antes de terminar la actual.
- El boton craneo (esquina del spawn) siempre muestra la composicion de la siguiente ola.

---

## Guardado (`src/saves.lua`)

3 ranuras, guardado automatico al completar cada nivel.

```
date=17/05/2026 21:30
completed=1,2,5
```

---

---

## ROADMAP — Proximas features

### Alta prioridad

#### Arbol de upgrades expandido (L1 → L2 → L3 → L4A / L4B / L4C)
- Actualmente: L1 → L2 → L3A/B (2 especializaciones)
- Objetivo: L1 → L2 → L3 → L4A / L4B / L4C (3 especializaciones con identidades claras)
- Cada torre necesita 3 especializaciones nuevas: daño, control/utilidad, area/soporte
- Archivos: `tower.lua` (restructurar TYPES.upgrades), `ui.lua` (panel upgrade con 3 botones en L3→L4)

#### Heroes (unidad movil controlable)
- Una unidad que el jugador puede colocar y mover libremente por tiles de hierba
- Funciona como los guerreros del Cuartel: intercepta y retiene enemigos
- Tiene ataques especiales y una ulti con cooldown largo
- Ideas de habilidades: golpe de area (CD 8s), grito de guerra (buff guerreros, CD 15s), torbellino (ulti CD 60s)
- Sube de nivel al matar enemigos
- Archivos nuevos: `hero.lua`, integracion en `main.lua` y `ui.lua`

#### Multiples puntos de spawn (mas caminos)
- Algunos niveles tendrian 2-3 entradas y salidas simultaneas
- `levels.lua`: campo `spawnPoints = { {waypoints=...}, {waypoints=...} }`
- `wave.lua`: distribuir grupos de enemigos entre caminos (round-robin o aleatorio)
- Archivos: `levels.lua`, `wave.lua`, `enemy.lua` (ya soporta waypoints propios), `main.lua`

#### Mas variedad de enemigos
- **Sanador**: cura a los enemigos cercanos mientras camina (obliga a priorizar)
- **Blindado**: armadura muy alta pero sin velocidad
- **Corredor elite**: muy rapido, invisible a torres lentas
- Archivos: `enemy.lua` (TYPES), `levels.lua` (incluir en oleadas)

### Media prioridad

#### Poderes con cooldown (botones de habilidad)
- Panel de poderes del jugador con 3-4 habilidades activas
- Ideas: Meteorito (CD 30s, daño masivo en area), Rayo (CD 20s, daño instantaneo ignora armor),
  Lluvia de flechas (CD 25s, daño en linea), Escudo temporal (CD 45s, tropas invulnerables 5s)
- Mecanica: clic en boton → cursor especial → clic en mapa para aplicar
- Archivos nuevos: `powers.lua`, integracion en `main.lua` y `ui.lua`

#### Pantalla de resultado con estrellas
- Al completar nivel: 1-3 estrellas segun vidas restantes
- Guardado de estrellas por nivel por ranura

### Baja prioridad / polish

- Efectos visuales de explosion en mortero (circulo de expansion animado)
- Sonidos 8-bit/chiptune (`love.audio`)
- Animaciones de enemigos (flash al recibir daño, muerte)
- Pantalla de estadisticas post-nivel

---

## Plan de conversion a Pixel Art (Aseprite)

El juego usa primitivas LOVE2D (circulos, rectangulos) como placeholder.
El objetivo es reemplazarlos con sprites pixel art sin cambiar la logica.

### Flujo de trabajo

1. **Disenar en Aseprite** — sprites 16x16 o 32x32px por objeto
2. **Exportar como PNG** — un archivo por sprite, o spritesheet para animaciones
3. **Cargar en LOVE2D** con filtro nearest:
   ```lua
   love.graphics.setDefaultFilter("nearest", "nearest")
   local img = love.graphics.newImage("assets/enemy_basic.png")
   ```
4. **Reemplazar draw calls** — cambiar `love.graphics.circle/rectangle` por `love.graphics.draw(img, x, y)`

### Sprites necesarios (por orden de impacto visual)

| Sprite              | Tamano sugerido | Animaciones              |
|---------------------|-----------------|--------------------------|
| Enemigo basico      | 16x16           | walk (4f), death (3f)    |
| Enemigo rapido      | 16x16           | walk (4f), death (3f)    |
| Enemigo tanque      | 24x24           | walk (4f), death (4f)    |
| Torres (x5)         | 32x32           | idle, shoot (2f)         |
| Guerrero            | 16x16           | idle, run, fight, death  |
| Tiles (suelo/camino)| 48x48           | estaticos                |
| Proyectiles         | 8x8             | estaticos o 2f spin      |
| Explosion mortero   | 32x32           | 5-6 frames               |
| UI icons (guante, craneo) | 32x32     | estaticos                |

### Convencion de archivos

```
assets/
├── tiles/
│   ├── ground.png
│   ├── path.png
│   └── ...
├── towers/
│   ├── basic_L1.png
│   ├── basic_L2.png
│   └── ...
├── enemies/
│   ├── basic_walk.png   (spritesheet)
│   └── ...
└── ui/
    ├── skull.png
    └── glove.png
```

### Cuando implementar

- Primero terminar toda la logica de gameplay (heroes, multiples caminos, poderes)
- Luego hacer una pasada de sprites empezando por enemigos y torres
- Los tiles son los de mayor impacto visual por cantidad de pixeles en pantalla
- Usar `love.graphics.setDefaultFilter("nearest","nearest")` en `love.load()` antes de cargar cualquier imagen

---

## Notas tecnicas

### Agregar un nuevo tipo de enemigo
1. Añadir entrada en `TYPES` en `src/enemy.lua` con `hp`, `speed`, `armor`, `color`, `reward`, `radius`, `attack`
2. Usarlo en las definiciones de oleadas en `src/levels.lua`

### Agregar un nuevo nivel
1. Añadir `L[N] = {...}` en `src/levels.lua`
2. Añadir nodo en `NODES` en `src/levelselect.lua`
3. Actualizar `MAX_LEVELS` en `src/slotselect.lua`

### Agregar un nuevo tipo de torre
1. Añadir entrada en `TYPES` en `src/tower.lua` con stats base y `upgrades`
2. Añadir a `towerOrder` en `src/ui.lua`

### Constantes de balance
- `WAVE_DELAY` en `main.lua` — cooldown entre olas (15s)
- `GLOVE_CD` en `main.lua` — cooldown del guante (30s)
- `ADVANCE_DELAY` en `src/wave.lua` — espera antes de poder avanzar ola (9s)
- `ADVANCE_BONUS` — oro bonus por avanzar ola anticipado (20g)
