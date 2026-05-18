# Guia de Estilo — Tower Defense

Referencia para mantener coherencia visual y de UX en todas las sesiones de desarrollo.

---

## Estetica general

**Estilo objetivo:** minimalista, alto contraste, blanco y negro puro.
El juego usa exactamente dos colores: negro `(0,0,0)` y blanco `(1,1,1)`. No hay grises, dorados, azules ni ningun otro tono.
La opacidad (alpha) esta permitida como unica herramienta de jerarquia visual.

**Paleta — REGLA ABSOLUTA:**
- Color 1: negro puro `(0, 0, 0)` — fondos, fills de enemigos normales y tanques
- Color 2: blanco puro `(1, 1, 1)` — bordes, texto, torres, fill de enemigos rapidos
- Variantes con alpha: `(0,0,0, α)` para overlays oscuros, `(1,1,1, α)` para elementos sutiles/desactivados
- Prohibido: cualquier RGB con r≠g≠b, cualquier tono no neutro (dorado, rojo, verde, azul, etc.)

**Logica de contraste:**
- Fondos de pantalla y tiles de cesped: negro
- Tiles de camino: blanco — los enemigos se mueven sobre blanco
- Enemigos (basico/tanque): fill negro + borde blanco — visibles sobre camino blanco
- Enemigos (rapido): fill blanco + borde negro — variante para diferenciar sin color
- Torres: fill blanco + borde negro — visibles sobre cesped negro
- Botones (normal): fill negro + borde blanco + texto blanco
- Botones (hover / seleccionado): fill blanco + borde negro + texto negro
- Botones (desactivado): fill negro + borde `(1,1,1,0.25)` + texto `(1,1,1,0.30)`

---

## Texto y tipografia

- **Sin emojis** en ningun texto del juego (UI, menus, overlays, mensajes).
- **Sin tildes ni caracteres especiales** en strings Lua (evitar problemas de encoding en LOVE2D). Usar: "Maximo" en lugar de "Máximo", "Camino" en lugar de "Camión", etc.
- Fuentes: solo `love.graphics.newFont(size)` con tamanos estandar:
  - 11px — texto pequeno, stats secundarios
  - 13px — texto general, listas
  - 15px — titulos de panel, labels de torre
  - 18px — mensajes de estado en juego
  - 34–38px — titulos de pantalla (menu, slots, level select)
  - 48px — mensajes grandes (GAME OVER, VICTORIA)
- Color de texto: siempre blanco `(1,1,1)` sobre fondo negro, negro `(0,0,0)` sobre fondo blanco (hover invertido).

---

## Pixel art (objetivo a implementar)

Cuando se introduzcan sprites:
- Resolucion de sprites: 16x16 o 32x32 px, escalados con `love.graphics.setDefaultFilter("nearest", "nearest")` para mantener pixeles nitidos.
- Sin antialiasing en sprites.
- Animaciones: maquina de estados simple (idle, move, attack, death) con spritesheet.
- Las torres y enemigos actuales (circulos y cuadrados) deben reemplazarse por sprites pixel art cuando esten listos, sin cambiar la logica subyacente.
- Tiles del mapa: 48x48px, mismas restricciones de filtro.
- Los sprites deben seguir la paleta B&W: tinta negra sobre fondo blanco, o viceversa.

---

## UI y layout

- Panel de control: siempre a la derecha, 160px de ancho, fondo negro con borde blanco.
- Botones: esquinas redondeadas (radio 5–8px), borde blanco visible, inversion al hover.
- Sin sombras ni gradientes.
- Indicadores de estado (vida, oro, ola): texto blanco sobre panel negro.

---

## Audio (pendiente)

- Efectos de sonido 8-bit/chiptune coherentes con el estilo pixel art.
- Sin musica de fondo por defecto (opcional, toggle en opciones).
- Sonidos clave: disparo de torre, impacto, muerte de enemigo, victoria, game over, colocar torre.

---

## Reglas de codigo

- Sin comentarios que expliquen QUE hace el codigo — solo comentarios de POR QUE cuando no es obvio.
- Sin emojis en strings de codigo.
- Constantes de layout en mayusculas al inicio del archivo.
- Clases nuevas siguen el patron existente: tabla local + metatable, metodos con `:`.
- Para colores: usar solo `(0,0,0)` y `(1,1,1)` con alpha opcional. Prohibido cualquier otro RGB.
