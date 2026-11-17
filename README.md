# ☀️ Solarium — Reloj Solar Local Verdadero & Calendario Fijo de 13 Meses

> Aplicación astronómica standalone y **Widget Nativo para macOS (Swift & AppKit)** que reconecta la percepción del tiempo con los ciclos celestes naturales a través del mediodía solar local y el calendario armónico de 13 meses.

---

## 🌟 Pilares y Características

### 1. Reloj Solar Local Verdadero (Local Apparent Solar Time - LAST)
- **Cálculo Astronómico Preciso:** Ancla las 12:00:00 exactas al instante en que el Sol cruza el meridiano local (culminación cenital).
- **Corrección de Ecuación del Tiempo ($E_oT$):** Ajuste continuo por la excentricidad de la órbita terrestre y la oblicuidad de la eclíptica.
- **Auto-Detección IANA Offline:** Detección instantánea de latitud y longitud a partir de la zona horaria del sistema sin requerir conexión a internet.
- **Simulador de Bóveda Celeste:** Visualización en vivo de la trayectoria del sol, hora dorada, crepúsculo y nadir solar.

### 2. Calendario Fijo Internacional de 13 Meses
- **Estructura Armónica:** 13 meses idénticos de exactamente 28 días (4 semanas exactas cada uno: de lunes a domingo).
- **Mes Central *Sol*:** Insertado entre junio y julio para alinear el año con el solsticio de verano.
- **Día del Año (*Year Day*):** Día festivo fuera de la semana para completar los 365 días del ciclo solar trópico.
- **Rastreador Lunar Astronómico:** Fase lunar en vivo con porcentaje de iluminación, edad lunar y distancia al perigeo/apogeo.

### 3. Widget Nativo para macOS (`Solarium Widget.app`)
- **Desarrollado en Swift 6 & AppKit:** Binario universal para Apple Silicon e Intel.
- **Elemento de Barra de Menús (`NSStatusItem`):** Hora solar en tiempo real, altitud solar y fase lunar directamente en la barra superior.
- **Popover y Panel de Escritorio Frosted Glass:** Panel translúcido arrastrable que puede anclarse al fondo de pantalla (`.desktop`) o mantenerse como ventana flotante (`.floating`).
- **Compatibilidad con macOS Sequoia:** Optimizado para bajo consumo energético sin bloqueos en el hilo principal.

---

## 🚀 Instalación y Uso

### Ejecución Web Local
```bash
# Iniciar servidor local en el puerto 5195
./start.sh

# Detener el servidor
./stop.sh
```

### Compilación del Widget Nativo (macOS)
```bash
# Compilar y firmar ad-hoc el widget en Swift
./build-widget.sh
```

---

## 📄 Licencia

Distribuido bajo la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.
