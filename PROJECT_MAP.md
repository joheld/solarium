# Solarium: Reloj Solar Local & Calendario Fijo de 13 Meses - Project Map

Aplicación web astronómica y cronobiológica standalone, 100% offline y sin dependencias externas, que sincroniza el tiempo humano con el cosmos y la naturaleza a través de dos pilares:
1. **Reloj Solar Local Verdadero (LAST)** anclado al mediodía solar local mediante corrección de longitud y la Ecuación del Tiempo ($E_oT$).
2. **Calendario Fijo Internacional de 13 Meses de 28 Días** (incluyendo el mes central *Sol* y el *Year Day*), integrado con rastreador de fases lunares en tiempo real y sincronización de ritmos biológicos/circadianos.

---

## 📊 Grafo de Versiones

```mermaid
gitGraph
    commit id: "init-project-map" tag: "v0.1.0"
    commit id: "feat-solar-lunar-core" tag: "v1.0.0"
    commit id: "feat-desktop-shortcuts-and-icon" tag: "v1.1.0"
```

---

## 📌 Checkpoints

| ID | Fecha | Versión | Descripción | Estado |
|---|---|---|---|---|
| `CHK-001` | 2026-10-23 | `v0.1.0` | Inicialización del repositorio git y mapa del proyecto | ✅ Completado |
| `CHK-002` | 2026-10-23 | `v1.0.0` | Aplicación interactiva completa (`index.html`) con Reloj Solar Local Verdadero, simulador de bóveda celeste, Calendario de 13 meses de 28 días perpetuo, calculador lunar astronómico, guía de fases biológicas y scripts desacoplados POSIX `start.sh`/`stop.sh` en puerto asignado `5195` | ✅ Completado |
| `CHK-003` | 2026-10-23 | `v1.1.0` | Creación de lanzadores en el Escritorio: aplicación nativa compilada macOS `Solarium.app` con icono personalizado de sol y luna dorada/plateada (`.icns`), lanzador por terminal `Solarium.command` y script desacoplado `launch-desktop.sh` | ✅ Completado |

---

## 🚦 Estado de la Sesión
- **Estado Actual:** Servidor local activo en puerto 5195 (`HTTP 200 OK`) y aplicación verificada al 100%. Accesos directos creados en el Escritorio de macOS.
- **Siguiente paso:** Entrega al usuario con documentación técnica y enlaces clicables.
