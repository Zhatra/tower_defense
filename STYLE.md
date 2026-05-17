# Guia de Estilo — Tower Defense

Referencia para mantener coherencia visual y de UX en todas las sesiones de desarrollo.

---

## Estetica general

**Estilo objetivo:** pixel art, oscuro, con acentos dorados/ambar.
El juego debe sentirse como un tower defense clasico de los 2000s — funcional, legible, sin decoracion innecesaria.

**Paleta base:**
- Fondo de pantallas: negro/gris muy oscuro `(0.05–0.10, 0.07–0.13, 0.08–0.20)`
- Acento principal: dorado/ambar `(0.95, 0.78, 0.14)` — titulos, seleccion activa, oro
- Acento secundario: azul-gris `(0.35–0.55, 0.45–0.65, 0.75–1.00)` — botones normales, UI neutral
- Peligro/vida: rojo `(1.0, 0.20–0.35, 0.20–0.35)`
- Exito/victoria: verde `(0.20–0.40, 0.85–1.00, 0.40–0.55)`
- Texto principal: blanco/gris claro `(0.80–1.0)`
- Texto secundario/desactivado: gris `(0.40–0.55)`

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

---

## Pixel art (objetivo a implementar)

Cuando se introduzcan sprites:
- Resolucion de sprites: 16x16 o 32x32 px, escalados con `love.graphics.setDefaultFilter("nearest", "nearest")` para mantener pixeles nitidos.
- Sin antialiasing en sprites.
- Animaciones: maquina de estados simple (idle, move, attack, death) con spritesheet.
- Las torres y enemigos actuales (circulos y cuadrados) deben reemplazarse por sprites pixel art cuando esten listos, sin cambiar la logica subyacente.
- Tiles del mapa: 48x48px, mismas restricciones de filtro.

---

## UI y layout

- Panel de control: siempre a la derecha, 160px de ancho, fondo oscuro semitransparente.
- Botones: esquinas redondeadas (radio 5–8px), borde visible en hover.
- Sin sombras ni gradientes (incompatible con pixel art).
- Indicadores de estado (vida, oro, ola): iconos simples o texto, nunca elementos flotantes que tapen el area de juego.
- El banner de "siguiente ola" va fijo en la parte inferior del area de juego (y=726), nunca cerca del spawn.

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
