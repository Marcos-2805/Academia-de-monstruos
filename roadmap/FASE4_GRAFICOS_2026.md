# Fase 4 — Gráficos 2026

El objetivo de esta fase es cambiar el enfoque de la demo: la geometría generada por primitivas deja de ser el acabado final y pasa a ser un andamio temporal.

## Arquitectura visual

- `scripts/main_3d.gd`: lógica de juego, movimiento, interacción y flujo de la escena.
- `scripts/eldoria_graphics_2026.gd`: ambiente, iluminación, sombras, niebla, glow y materiales PBR.
- Próximos módulos: terreno, vegetación, agua, personajes, fauna y regiones.

## Orden de trabajo

1. Terreno y materiales naturales.
2. Academia con piedra, tejados, ventanas y puerta medieval.
3. Vegetación y bosque con variación, viento y sombras.
4. Agua, fuente y superficies dinámicas.
5. Personaje principal y NPC con modelos humanos y animaciones.
6. Fauna con movimiento natural.
7. Iluminación, clima y atmósfera por bioma.
8. Sustitución progresiva de primitivas por assets 3D detallados.
9. Construcción visual final de las ocho regiones de Eldoria.

## Regiones

Academia de los Monstruos · Bosque de los Susurros · Valle de Fuego · Lago Cristal · Cordillera de los Gigantes · Costa de las Sirenas · Tierras Antiguas · Cuevas Profundas · Poblaciones y conexiones.

## Nota

El módulo gráfico está preparado por separado para evitar volver a concentrar lógica y renderizado en un único `main_3d.gd` gigante. La integración con la escena principal se hará en el siguiente paso, después de comprobar el checkpoint estable local.
