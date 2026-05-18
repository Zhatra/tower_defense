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
├── STYLE.md            — guia de estilo visual (paleta B&W, reglas absolutas)
├── src/
│   ├── levels.lua      — 10 niveles (layout, waypoints, oleadas, stats)
│   ├── map.lua         — renderizado del mapa y conversion de coordenadas
│   ├── wave.lua        — sistema de oleadas (spawn secuencial por grupos)
│   ├── enemy.lua       — enemigos con armadura, slow, debuf de armor
│   ├── tower.lua       — 5 tipos de torres, upgrades bifurcados, guerreros, mortero
│   ├── ui.lua          — panel lateral (construccion + upgrade de torre seleccionada)
│   ├── menu.lua        — menu principal con fondo de estrellas
│   ├── slotselect.lua  — seleccion de ranura de guardado (3 ranuras)
│   ├── levelselect.lua — mapa de niveles con 10 nodos en curva S
│   ├── saves.lua       — guardado por ranura (niveles completados)
│   └── dbg.lua         — overlay de debug (F1) + log a archivo wave_debug.log
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

| Tecla / Boton     | Accion                                          |
|-------------------|-------------------------------------------------|
| Click en mapa     | Colocar torre seleccionada                      |
| Click en torre    | Ver mejoras / vender                            |
| Craneo (1 clic)   | Abrir/cerrar preview de la siguiente ola        |
| Craneo (2 clics)  | Avanzar ola anticipado (+20g) o saltar countdown|
| Guante (boton)    | Mover una torre colocada (CD 15s)               |
| Pausa (boton)     | Pausar la partida                               |
| Esc               | Pausar / Cancelar seleccion activa              |
| R                 | Reiniciar nivel                                 |
| M                 | Volver al mapa de niveles                       |
| F1                | Mostrar/ocultar overlay de debug                |

---

## Paleta visual (STYLE.md)

**Regla absoluta: solo negro `(0,0,0)` y blanco `(1,1,1)`. Alpha permitido. Ningun otro color.**

- Fondo/mapa: negro
- Contenido/entidades: blanco
- Hover/seleccionado: invertido (fondo blanco, texto negro)
- Desactivado: blanco con alpha bajo (0.22-0.28)
- Enemigos: basic/tank = negro relleno + borde blanco; fast = blanco relleno + borde negro
- Torres: blanco relleno + borde negro; puntos de nivel en negro

---

## Niveles (`src/levels.lua`)

10 niveles, cada uno con layout unico y camino distinto.

| #   | Oleadas | Oro inicial | Vidas |
|-----|---------|-------------|-------|
| 1   | 6       | 150         | 20    |
| 2   | 7       | 150         | 20    |
| 3   | 8       | 175         | 20    |
| 4-5 | 11      | 175         | 20    |
| 6-7 | 11      | 200         | 20    |
| 8-9 | 13      | 225         | 20    |
| 10  | 13      | 250         | 20    |

---

## Enemigos (`src/enemy.lua`)

| Tipo  | HP  | Velocidad | Armadura | Recompensa |
|-------|-----|-----------|----------|------------|
| basic | 240 | 45 px/s   | 0%       | 10 oro     |
| fast  | 120 | 90 px/s   | 0%       | 15 oro     |
| tank  | 900 | 22 px/s   | 45%      | 30 oro     |

Cada enemigo genera un camino con offset aleatorio +-10px en waypoints intermedios.

**Efectos:** `slowTimer/slowFactor`, `armorDebufTimer/armorDebufPct`

---

## Torres (`src/tower.lua`)

5 tipos, sistema de upgrades L1 -> L2 -> L3A / L3B (especializacion bifurcada).
Las torres priorizan al enemigo mas avanzado en el camino.

| Tipo    | Daño | Rango | Cad.   | Costo | Especial                        |
|---------|------|-------|--------|-------|---------------------------------|
| Basica  | 20   | 100   | 1.0/s  | $50   | Splash (L3A), Slow (L3B)        |
| Franco. | 80   | 200   | 0.4/s  | $100  | Ignora armor 50%                |
| Rapida  | 8    | 80    | 4.0/s  | $75   | Slow (L3B), Minigun (L3A)       |
| Cuartel | -    | 130   | -      | $100  | 3 guerreros fisicos             |
| Mortero | 70   | 160   | 0.4/s  | $125  | Splash en area, arco parabolico |

**Guante:** mueve una torre ya colocada a otro tile (CD 15s). Boton esquina superior derecha.

**Venta:** 50% de la inversion total acumulada.

---

## Sistema de Guerreros (torre Cuartel)

- 3 guerreros por torre, estados: `idle -> moving -> fighting -> respawning`
- El guerrero reserva un enemigo (`enemy.engagedBy = warrior`); el enemigo se detiene
- Si el guerrero muere -> respawn en 8s (L1), 6s (L2), 5s/3s (L3A/B)
- Al mover la torre con el guante, los `homeX/homeY` de los guerreros se actualizan

---

## Sistema de Oleadas (`src/wave.lua`)

Los grupos dentro de cada ola se lanzan de forma **secuencial** (uno tras otro, no en paralelo).

- `spawnDuration = sum(count x interval por grupo) + 5s`
- El countdown de 15s entre olas empieza cuando `activeTimer >= spawnDuration` O cuando `allSpawned == true AND todos los enemigos muertos`
- El boton craneo aparece 17s despues del inicio de la ola (`SKULL_SHOW_DELAY = 17`)
- Doble clic en el craneo:
  - Antes del countdown: avanza ola anticipado (+20 oro)
  - Durante countdown (todos muertos): salta el tiempo restante
- El anillo de progreso alrededor del craneo muestra cuanto falta para la siguiente ola automatica

**Duracion aproximada de oleadas:**
- Nivel 1: 23-45 segundos por ola
- Nivel 10: 30-72 segundos por ola

---

## Debug (`src/dbg.lua`)

- **F1** — toggle del overlay de debug
- El overlay muestra: waveIndex, activeTimer, spawnDuration, active, allSpawned, enemigos vivos, awaitingNextWave, waveTimer, skullShouldShow
- Los eventos recientes se escriben a `wave_debug.log` en la carpeta de datos de LOVE

---

## Guardado (`src/saves.lua`)

3 ranuras, guardado automatico al completar cada nivel.

---

## ROADMAP — Proximas features

### Alta prioridad

#### Arbol de upgrades expandido (L1 -> L2 -> L3 -> L4A / L4B / L4C)
- Actualmente: L1 -> L2 -> L3A/B (2 especializaciones)
- Objetivo: L1 -> L2 -> L3 -> L4A / L4B / L4C (3 especializaciones con identidades claras)
- Archivos: `tower.lua` (restructurar TYPES.upgrades), `ui.lua` (3 botones en nivel L3->L4)

#### Heroes (unidad movil controlable)
- Una unidad que el jugador puede colocar y mover libremente
- Funciona como los guerreros: intercepta y retiene enemigos, tiene habilidades especiales
- Sube de nivel al matar enemigos
- Archivos nuevos: `hero.lua`, integracion en `main.lua` y `ui.lua`

#### Multiples puntos de spawn (mas caminos)
- Algunos niveles tendrian 2-3 entradas y salidas simultaneas
- `levels.lua`: campo `spawnPoints = { {waypoints=...}, {waypoints=...} }`
- `wave.lua`: distribuir grupos de enemigos entre caminos
- Archivos: `levels.lua`, `wave.lua`, `main.lua`

#### Mas variedad de enemigos
- **Sanador**: cura a enemigos cercanos mientras camina
- **Blindado**: armadura muy alta pero sin velocidad
- **Corredor elite**: muy rapido
- Archivos: `enemy.lua` (TYPES), `levels.lua` (oleadas)

### Media prioridad

#### Poderes con cooldown (botones de habilidad)
- Panel de poderes del jugador con 3-4 habilidades activas
- Ideas: Meteorito (CD 30s), Rayo (CD 20s), Lluvia de flechas (CD 25s), Escudo temporal (CD 45s)
- Archivos nuevos: `powers.lua`, integracion en `main.lua` y `ui.lua`

#### Pantalla de resultado con estrellas
- Al completar nivel: 1-3 estrellas segun vidas restantes
- Guardado de estrellas por nivel por ranura

### Baja prioridad / polish

- Efectos visuales de explosion en mortero
- Sonidos 8-bit/chiptune (`love.audio`)
- Animaciones de enemigos (flash al recibir dano, muerte)
- Pantalla de estadisticas post-nivel

---

## Plan de conversion a Pixel Art (futuro)

El juego usa primitivas LOVE2D como placeholder.
Al implementar sprites: `love.graphics.setDefaultFilter("nearest","nearest")`, 16x16 o 32x32px, paleta B&W.

---

## Notas tecnicas

### Agregar un nuevo tipo de enemigo
1. Anadir entrada en `TYPES` en `src/enemy.lua` con `hp`, `speed`, `armor`, `reward`, `radius`, `attack`
2. Usarlo en las definiciones de oleadas en `src/levels.lua`

### Agregar un nuevo nivel
1. Anadir `L[N] = {...}` en `src/levels.lua`
2. Anadir nodo en `NODES` en `src/levelselect.lua`
3. Actualizar `MAX_LEVELS` en `src/slotselect.lua`

### Agregar un nuevo tipo de torre
1. Anadir entrada en `TYPES` en `src/tower.lua` con stats base y `upgrades`
2. Anadir a `towerOrder` en `src/ui.lua`

### Constantes de balance clave (`main.lua`)
- `WAVE_DELAY = 15` — cooldown entre olas (segundos)
- `SKULL_SHOW_DELAY = 17` — segundos desde inicio de ola hasta que aparece el craneo
- `GLOVE_CD = 15` — cooldown del guante (segundos)
