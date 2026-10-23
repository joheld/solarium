// ==============================================================================
// Solarium: Reloj Solar Local & Calendario Fijo de 13 Meses
// Widget Nativo para macOS (Menu Bar Extra & Desktop Floating Widget)
// Swift & AppKit • Apple Silicon ARM64 • 100% Offline & Zero Dependencias
// ==============================================================================

import Cocoa
import Darwin

// MARK: - Extensiones de Soporte macOS
extension NSWindow.Level {
    static let desktop = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
}

// MARK: - Modelo de Tiempo Solar y Calendario de 13 Meses
struct SolarLunarSnapshot {
    let cityName: String
    let lat: Double
    let lon: Double
    let tzOffset: Double
    
    let solarHours: Int
    let solarMinutes: Int
    let solarSeconds: Int
    let civilTimeString: String
    let totalOffsetMinutes: Double
    let eotMinutes: Double
    let noonTimeString: String
    let altitudeDeg: Double
    let isDay: Bool
    let phaseTitle: String
    
    // Calendario de 13 meses
    let fixedMonthIndex: Int
    let fixedMonthName: String
    let fixedDay: Int
    let fixedWeekdayName: String
    let fixedWeekNum: Int
    let fixedDateString: String
    let isYearDay: Bool
    let isLeapDay: Bool
    
    // Luna
    let moonPhaseName: String
    let moonEmoji: String
    let moonIlluminationPct: Double
    let moonAgeDays: Double
    
    static func current(lat: Double, lon: Double, tzOffset: Double, cityName: String) -> SolarLunarSnapshot {
        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: now) ?? 1
        
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        let s = cal.component(.second, from: now)
        let hourFrac = Double(h) + Double(m)/60.0 + Double(s)/3600.0
        
        // Ecuación del Tiempo (Spencer)
        let gamma = (2.0 * .pi / 365.0) * (Double(dayOfYear - 1) + (hourFrac - 12.0) / 24.0)
        let eot = 229.18 * (
            0.000075 +
            0.001868 * cos(gamma) -
            0.032077 * sin(gamma) -
            0.014615 * cos(2.0 * gamma) -
            0.040849 * sin(2.0 * gamma)
        )
        
        // Declinación Solar
        let decl = 0.006918 -
            0.399912 * cos(gamma) +
            0.070257 * sin(gamma) -
            0.006758 * cos(2.0 * gamma) +
            0.000907 * sin(2.0 * gamma) -
            0.002697 * cos(3.0 * gamma) +
            0.00148 * sin(3.0 * gamma)
        
        // Corrección por Longitud (4 min por grado respecto al meridiano estándar)
        let stdMeridian = tzOffset * 15.0
        let lonDiff = lon - stdMeridian
        let lonCorrection = lonDiff * 4.0
        let totalOffset = lonCorrection + eot
        
        let midnight = cal.startOfDay(for: now)
        let civilMinutes = now.timeIntervalSince(midnight) / 60.0
        var solMin = (civilMinutes + totalOffset).truncatingRemainder(dividingBy: 1440.0)
        if solMin < 0 { solMin += 1440.0 }
        
        let solH = Int(solMin / 60.0)
        let solM = Int(solMin.truncatingRemainder(dividingBy: 60.0))
        let solS = Int((solMin * 60.0).truncatingRemainder(dividingBy: 60.0))
        
        // Mediodía Solar en hora civil
        var noonCiv = (720.0 - totalOffset).truncatingRemainder(dividingBy: 1440.0)
        if noonCiv < 0 { noonCiv += 1440.0 }
        let noonH = Int(noonCiv / 60.0)
        let noonM = Int(noonCiv.truncatingRemainder(dividingBy: 60.0))
        let noonPeriod = noonH >= 12 ? "PM" : "AM"
        let noonH12 = noonH % 12 == 0 ? 12 : noonH % 12
        let noonStr = String(format: "%d:%02d %@", noonH12, noonM, noonPeriod)
        
        // Altitud Solar
        let latRad = lat * .pi / 180.0
        let hourAngleRad = (solMin / 4.0 - 180.0) * .pi / 180.0
        let sinAlt = sin(latRad) * sin(decl) + cos(latRad) * cos(decl) * cos(hourAngleRad)
        let altDeg = asin(max(-1.0, min(1.0, sinAlt))) * 180.0 / .pi
        let isDay = altDeg > 0.0
        
        var phaseTxt = "Noche"
        if solMin >= 360 && solMin < 510 { phaseTxt = "Amanecer: Activación" }
        else if solMin >= 510 && solMin < 720 { phaseTxt = "Mañana: Alerta Máxima" }
        else if solMin >= 720 && solMin < 870 { phaseTxt = "Cenit Solar: Pico Metabólico" }
        else if solMin >= 870 && solMin < 1080 { phaseTxt = "Tarde: Coordinación y Fuerza" }
        else if solMin >= 1080 && solMin < 1320 { phaseTxt = "Ocaso: Preparación Nocturna" }
        
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        let civilStr = df.string(from: now)
        
        // Calendario Fijo Internacional de 13 Meses
        let leap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
        var isYD = false
        var isLD = false
        var mIdx = 0
        var dIdx = 1
        var wName = "Domingo"
        var wNum = 1
        let fixedMonths = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Sol", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
        
        if !leap && dayOfYear == 365 {
            isYD = true
            mIdx = 12
            dIdx = 29
            wName = "Día Fuera del Tiempo"
            wNum = 4
        } else if leap && dayOfYear == 197 {
            isLD = true
            mIdx = 6
            dIdx = 29
            wName = "Día Bisiesto"
            wNum = 4
        } else {
            var adjDay = dayOfYear
            if leap && dayOfYear > 197 { adjDay -= 1 }
            mIdx = min(12, max(0, (adjDay - 1) / 28))
            dIdx = ((adjDay - 1) % 28) + 1
            let weekdays = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
            wName = weekdays[(dIdx - 1) % 7]
            wNum = ((dIdx - 1) / 7) + 1
        }
        
        let fixedDateStr = isYD ? "Día del Año (Year Day)" : "\(wName), \(dIdx) de \(fixedMonths[mIdx])"
        
        // Luna
        let refDate = Date(timeIntervalSince1970: 1704974220) // 11 Ene 2024
        let diffSec = now.timeIntervalSince(refDate)
        let synodicSec = 29.53058867 * 86400.0
        let cycles = diffSec / synodicSec
        let phaseFrac = (cycles - floor(cycles))
        let ageDays = phaseFrac * 29.53058867
        let illPct = (1.0 - cos(phaseFrac * 2.0 * .pi)) / 2.0 * 100.0
        
        var mName = "Luna Nueva"
        var mEmoji = "🌑"
        if ageDays >= 1.84 && ageDays < 5.53 { mName = "Creciente Cóncava"; mEmoji = "🌒" }
        else if ageDays >= 5.53 && ageDays < 9.22 { mName = "Cuarto Creciente"; mEmoji = "🌓" }
        else if ageDays >= 9.22 && ageDays < 12.91 { mName = "Creciente Gibosa"; mEmoji = "🌔" }
        else if ageDays >= 12.91 && ageDays < 16.61 { mName = "Luna Llena"; mEmoji = "🌕" }
        else if ageDays >= 16.61 && ageDays < 20.30 { mName = "Menguante Gibosa"; mEmoji = "🌖" }
        else if ageDays >= 20.30 && ageDays < 23.99 { mName = "Cuarto Menguante"; mEmoji = "🌗" }
        else if ageDays >= 23.99 && ageDays < 27.68 { mName = "Menguante Cóncava"; mEmoji = "🌘" }
        
        return SolarLunarSnapshot(
            cityName: cityName,
            lat: lat,
            lon: lon,
            tzOffset: tzOffset,
            solarHours: solH,
            solarMinutes: solM,
            solarSeconds: solS,
            civilTimeString: civilStr,
            totalOffsetMinutes: totalOffset,
            eotMinutes: eot,
            noonTimeString: noonStr,
            altitudeDeg: altDeg,
            isDay: isDay,
            phaseTitle: phaseTxt,
            fixedMonthIndex: mIdx,
            fixedMonthName: fixedMonths[mIdx],
            fixedDay: dIdx,
            fixedWeekdayName: wName,
            fixedWeekNum: wNum,
            fixedDateString: fixedDateStr,
            isYearDay: isYD,
            isLeapDay: isLD,
            moonPhaseName: mName,
            moonEmoji: mEmoji,
            moonIlluminationPct: illPct,
            moonAgeDays: ageDays
        )
    }
}

// MARK: - Vista de Tarjeta Solarium (Popover y Desktop Widget)
class SolariumCardView: NSView {
    let lblHeader = NSTextField(labelWithString: "SOLARIUM • TIEMPO SOLAR & 13 MESES")
    let lblLocation = NSTextField(labelWithString: "📍 Mérida, Yucatán (Auto-detectada)")
    
    let lblSolarTime = NSTextField(labelWithString: "12:00:00")
    let lblSubCivil = NSTextField(labelWithString: "Hora Civil: 12:00:00  •  Desfase: +00m 00s")
    
    let lblNoon = NSTextField(labelWithString: "Mediodía Solar: 11:42 AM  •  Altitud: 00°")
    let lblPhase = NSTextField(labelWithString: "☀️ Fase: Cenit Solar (Pico Metabólico)")
    
    let boxCalendar = NSBox()
    let lblCalendarDate = NSTextField(labelWithString: "📅 16 de Octubre (Mes 11) • Martes")
    let lblCalendarWeek = NSTextField(labelWithString: "Semana 3: Cosecha y Concreción Analítica")
    
    let lblMoon = NSTextField(labelWithString: "🌔 Luna: Creciente Gibosa (48% iluminada)")
    
    let btnDesktop = NSButton(title: "📌 Fijar en Escritorio", target: nil, action: nil)
    let btnCopy = NSButton(title: "📋 Copiar", target: nil, action: nil)
    let btnWeb = NSButton(title: "🌐 Abrir Web", target: nil, action: nil)
    
    var onToggleDesktopWidget: (() -> Void)?
    var onOpenWeb: (() -> Void)?
    var onCopyTime: (() -> Void)?
    
    let isDesktopWidget: Bool
    
    init(frame: NSRect, isDesktopWidget: Bool = false) {
        self.isDesktopWidget = isDesktopWidget
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupViews() {
        wantsLayer = true
        
        lblHeader.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        lblHeader.textColor = NSColor(calibratedRed: 0.96, green: 0.62, blue: 0.04, alpha: 1.0)
        addSubview(lblHeader)
        
        lblLocation.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        lblLocation.textColor = NSColor(calibratedRed: 0.06, green: 0.72, blue: 0.50, alpha: 1.0)
        addSubview(lblLocation)
        
        lblSolarTime.font = NSFont.monospacedDigitSystemFont(ofSize: isDesktopWidget ? 32 : 36, weight: .bold)
        lblSolarTime.textColor = .white
        addSubview(lblSolarTime)
        
        lblSubCivil.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        lblSubCivil.textColor = NSColor(calibratedWhite: 0.75, alpha: 1.0)
        addSubview(lblSubCivil)
        
        lblNoon.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        lblNoon.textColor = NSColor(calibratedWhite: 0.85, alpha: 1.0)
        addSubview(lblNoon)
        
        lblPhase.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        lblPhase.textColor = NSColor(calibratedRed: 0.96, green: 0.62, blue: 0.04, alpha: 1.0)
        addSubview(lblPhase)
        
        // Bloque del Calendario de 13 Meses
        lblCalendarDate.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        lblCalendarDate.textColor = NSColor(calibratedRed: 0.22, green: 0.74, blue: 0.97, alpha: 1.0)
        addSubview(lblCalendarDate)
        
        lblCalendarWeek.font = NSFont.systemFont(ofSize: 10, weight: .regular)
        lblCalendarWeek.textColor = NSColor(calibratedWhite: 0.65, alpha: 1.0)
        addSubview(lblCalendarWeek)
        
        lblMoon.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        lblMoon.textColor = NSColor(calibratedWhite: 0.9, alpha: 1.0)
        addSubview(lblMoon)
        
        if !isDesktopWidget {
            btnDesktop.bezelStyle = .rounded
            btnDesktop.target = self; btnDesktop.action = #selector(handleDesktop)
            addSubview(btnDesktop)
            
            btnCopy.bezelStyle = .rounded
            btnCopy.target = self; btnCopy.action = #selector(handleCopy)
            addSubview(btnCopy)
            
            btnWeb.bezelStyle = .rounded
            btnWeb.target = self; btnWeb.action = #selector(handleWeb)
            addSubview(btnWeb)
        }
    }
    
    @objc func handleDesktop() { onToggleDesktopWidget?() }
    @objc func handleCopy() { onCopyTime?() }
    @objc func handleWeb() { onOpenWeb?() }
    
    override func layout() {
        super.layout()
        let w = bounds.width
        let pad: CGFloat = 18
        
        if isDesktopWidget {
            lblHeader.frame = NSRect(x: pad, y: bounds.height - 28, width: w - pad * 2, height: 14)
            lblLocation.frame = NSRect(x: pad, y: bounds.height - 46, width: w - pad * 2, height: 16)
            lblSolarTime.frame = NSRect(x: pad, y: bounds.height - 86, width: w - pad * 2, height: 38)
            lblSubCivil.frame = NSRect(x: pad, y: bounds.height - 104, width: w - pad * 2, height: 16)
            lblNoon.frame = NSRect(x: pad, y: bounds.height - 124, width: w - pad * 2, height: 16)
            lblCalendarDate.frame = NSRect(x: pad, y: bounds.height - 146, width: w - pad * 2, height: 18)
            lblMoon.frame = NSRect(x: pad, y: bounds.height - 168, width: w - pad * 2, height: 16)
        } else {
            lblHeader.frame = NSRect(x: pad, y: bounds.height - 30, width: w - pad * 2, height: 16)
            lblLocation.frame = NSRect(x: pad, y: bounds.height - 50, width: w - pad * 2, height: 16)
            
            lblSolarTime.frame = NSRect(x: pad, y: bounds.height - 94, width: w - pad * 2, height: 40)
            lblSubCivil.frame = NSRect(x: pad, y: bounds.height - 114, width: w - pad * 2, height: 16)
            lblNoon.frame = NSRect(x: pad, y: bounds.height - 134, width: w - pad * 2, height: 16)
            lblPhase.frame = NSRect(x: pad, y: bounds.height - 152, width: w - pad * 2, height: 16)
            
            lblCalendarDate.frame = NSRect(x: pad, y: bounds.height - 176, width: w - pad * 2, height: 18)
            lblCalendarWeek.frame = NSRect(x: pad, y: bounds.height - 194, width: w - pad * 2, height: 15)
            lblMoon.frame = NSRect(x: pad, y: bounds.height - 214, width: w - pad * 2, height: 16)
            
            let btnY: CGFloat = 14
            let btnW = (w - pad * 2 - 16) / 3.0
            btnDesktop.frame = NSRect(x: pad, y: btnY, width: btnW, height: 28)
            btnCopy.frame = NSRect(x: pad + btnW + 8, y: btnY, width: btnW, height: 28)
            btnWeb.frame = NSRect(x: pad + (btnW + 8) * 2, y: btnY, width: btnW, height: 28)
        }
    }
    
    func update(with data: SolarLunarSnapshot) {
        lblLocation.stringValue = "📍 \(data.cityName)"
        lblSolarTime.stringValue = String(format: "%02d : %02d : %02d  SOLAR", data.solarHours, data.solarMinutes, data.solarSeconds)
        
        let sign = data.totalOffsetMinutes >= 0 ? "+" : "-"
        let absOff = abs(data.totalOffsetMinutes)
        let offM = Int(absOff)
        let offS = Int((absOff * 60.0).truncatingRemainder(dividingBy: 60.0))
        lblSubCivil.stringValue = "Hora Civil: \(data.civilTimeString)  •  Desfase: \(sign)\(offM)m \(offS)s"
        
        lblNoon.stringValue = "Mediodía Solar: \(data.noonTimeString)  •  Altitud: \(String(format: "%.1f°", data.altitudeDeg))"
        lblPhase.stringValue = "☀️ \(data.phaseTitle)"
        
        lblCalendarDate.stringValue = "📅 \(data.fixedDateString) (Mes \(data.fixedMonthIndex + 1))"
        
        var weekDesc = "Semana 1: Siembra y Renovación"
        if data.fixedWeekNum == 2 { weekDesc = "Semana 2: Cenit y Vitalidad" }
        else if data.fixedWeekNum == 3 { weekDesc = "Semana 3: Cosecha y Concreción Analítica" }
        else if data.fixedWeekNum == 4 { weekDesc = "Semana 4: Regeneración y Reposo" }
        lblCalendarWeek.stringValue = weekDesc
        
        lblMoon.stringValue = "\(data.moonEmoji) Luna: \(data.moonPhaseName) (\(String(format: "%.0f%%", data.moonIlluminationPct)) iluminada)"
    }
}

// MARK: - Panel de Widget de Escritorio Flotante
class SolariumDesktopPanel: NSPanel {
    let cardView: SolariumCardView
    let visualEffect = NSVisualEffectView()
    
    init() {
        let rect = NSRect(x: 140, y: 160, width: 340, height: 184)
        cardView = SolariumCardView(frame: NSRect(origin: .zero, size: rect.size), isDesktopWidget: true)
        
        super.init(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isMovableByWindowBackground = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        
        visualEffect.material = .underWindowBackground
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 20.0
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.borderColor = NSColor(calibratedRed: 0.96, green: 0.62, blue: 0.04, alpha: 0.4).cgColor
        visualEffect.layer?.borderWidth = 1.0
        
        contentView = visualEffect
        visualEffect.addSubview(cardView)
        
        if let originStr = UserDefaults.standard.string(forKey: "SolariumWidgetOrigin") {
            setFrameOrigin(NSPointFromString(originStr))
        }
    }
    
    func savePosition() {
        UserDefaults.standard.set(NSStringFromPoint(frame.origin), forKey: "SolariumWidgetOrigin")
    }
    
    func update(with data: SolarLunarSnapshot) {
        cardView.update(with: data)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        savePosition()
    }
}

// MARK: - App Delegate Principal
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var cardView: SolariumCardView!
    var desktopWidget: SolariumDesktopPanel?
    var timer: Timer?
    
    // Coordenadas detectadas (Mérida como default de sistema IANA)
    var cityName = "Mérida, Yucatán, México"
    var lat = 20.9674
    var lon = -89.5926
    var tzOffset = -6.0
    
    enum StatusFormat: Int {
        case solarHM = 0   // ☀️ 14:15
        case solarHMS = 1  // ☀️ 14:15:30
        case solarAndFixed = 2 // ☀️ 14:15 • 16 Oct
    }
    var currentFormat: StatusFormat = .solarHM
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        autoDetectLocation()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.title = "☀️ --:--"
            btn.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            btn.target = self
            btn.action = #selector(handleStatusClick(_:))
            btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 260)
        popover.behavior = .transient
        
        cardView = SolariumCardView(frame: NSRect(x: 0, y: 0, width: 340, height: 260), isDesktopWidget: false)
        let vc = NSViewController()
        vc.view = cardView
        popover.contentViewController = vc
        
        cardView.onToggleDesktopWidget = { [weak self] in self?.toggleDesktopWidget() }
        cardView.onOpenWeb = { [weak self] in self?.openWebApp() }
        cardView.onCopyTime = { [weak self] in self?.copySolarTime() }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateApp()
        }
        RunLoop.main.add(timer!, forMode: .common)
        
        updateApp()
    }
    
    private func autoDetectLocation() {
        let tz = TimeZone.current.identifier
        tzOffset = Double(TimeZone.current.secondsFromGMT()) / 3600.0
        
        let database: [String: (name: String, lat: Double, lon: Double)] = [
            "America/Merida": ("Mérida, Yucatán", 20.9674, -89.5926),
            "America/Cancun": ("Cancún, Q. Roo", 21.1619, -86.8515),
            "America/Mexico_City": ("Ciudad de México", 19.4326, -99.1332),
            "America/Monterrey": ("Monterrey, N.L.", 25.6866, -100.3161),
            "America/Guadalajara": ("Guadalajara, Jal.", 20.6597, -103.3496),
            "America/Tijuana": ("Tijuana, B.C.", 32.5149, -117.0382),
            "Europe/Madrid": ("Madrid, España", 40.4168, -3.7038),
            "America/Bogota": ("Bogotá, Colombia", 4.7110, -74.0721),
            "America/Buenos_Aires": ("Buenos Aires, Argentina", -34.6037, -58.3816),
            "America/Santiago": ("Santiago, Chile", -33.4489, -70.6693),
            "America/New_York": ("Nueva York, EE. UU.", 40.7128, -74.0060)
        ]
        
        if let match = database[tz] {
            cityName = match.name
            lat = match.lat
            lon = match.lon
        }
    }
    
    @objc func updateApp() {
        let data = SolarLunarSnapshot.current(lat: lat, lon: lon, tzOffset: tzOffset, cityName: cityName)
        
        if let btn = statusItem.button {
            switch currentFormat {
            case .solarHM:
                btn.title = String(format: "☀️ %02d:%02d", data.solarHours, data.solarMinutes)
            case .solarHMS:
                btn.title = String(format: "☀️ %02d:%02d:%02d", data.solarHours, data.solarMinutes, data.solarSeconds)
            case .solarAndFixed:
                btn.title = String(format: "☀️ %02d:%02d • %d %@", data.solarHours, data.solarMinutes, data.fixedDay, String(data.fixedMonthName.prefix(3)))
            }
        }
        
        if popover.isShown {
            cardView.update(with: data)
        }
        
        if let dw = desktopWidget, dw.isVisible {
            dw.update(with: data)
        }
    }
    
    @objc func handleStatusClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }
    
    func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            let data = SolarLunarSnapshot.current(lat: lat, lon: lon, tzOffset: tzOffset, cityName: cityName)
            cardView.update(with: data)
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }
    
    func showContextMenu() {
        let menu = NSMenu()
        
        let isWidgetOn = desktopWidget?.isVisible ?? false
        let itemWidget = NSMenuItem(title: isWidgetOn ? "Ocultar Widget de Escritorio" : "Mostrar Widget en Escritorio", action: #selector(toggleDesktopWidget), keyEquivalent: "d")
        itemWidget.target = self
        menu.addItem(itemWidget)
        
        if isWidgetOn {
            let itemLevel = NSMenuItem(title: "Nivel de Visualización", action: nil, keyEquivalent: "")
            let sub = NSMenu()
            let iFloat = NSMenuItem(title: "Flotante sobre ventanas", action: #selector(setLevelFloating), keyEquivalent: "")
            iFloat.target = self; iFloat.state = (desktopWidget?.level == .floating) ? .on : .off
            sub.addItem(iFloat)
            
            let iDesk = NSMenuItem(title: "Fijado al Fondo de Pantalla", action: #selector(setLevelDesktop), keyEquivalent: "")
            iDesk.target = self; iDesk.state = (desktopWidget?.level == .desktop) ? .on : .off
            sub.addItem(iDesk)
            itemLevel.submenu = sub
            menu.addItem(itemLevel)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let itemFmt = NSMenuItem(title: "Formato en Barra de Menús", action: nil, keyEquivalent: "")
        let subFmt = NSMenu()
        let f1 = NSMenuItem(title: "Hora Solar (☀️ 14:15)", action: #selector(setFmtHM), keyEquivalent: "1")
        f1.target = self; f1.state = (currentFormat == .solarHM) ? .on : .off
        subFmt.addItem(f1)
        
        let f2 = NSMenuItem(title: "Hora Solar con Segundos (☀️ 14:15:30)", action: #selector(setFmtHMS), keyEquivalent: "2")
        f2.target = self; f2.state = (currentFormat == .solarHMS) ? .on : .off
        subFmt.addItem(f2)
        
        let f3 = NSMenuItem(title: "Hora Solar + Día de 13 Meses (☀️ 14:15 • 16 Oct)", action: #selector(setFmtCombined), keyEquivalent: "3")
        f3.target = self; f3.state = (currentFormat == .solarAndFixed) ? .on : .off
        subFmt.addItem(f3)
        itemFmt.submenu = subFmt
        menu.addItem(itemFmt)
        
        menu.addItem(NSMenuItem.separator())
        
        let itemCopy = NSMenuItem(title: "Copiar Hora Solar Actual", action: #selector(copySolarTime), keyEquivalent: "c")
        itemCopy.target = self
        menu.addItem(itemCopy)
        
        let itemWeb = NSMenuItem(title: "Abrir Solarium Web Completo...", action: #selector(openWebApp), keyEquivalent: "w")
        itemWeb.target = self
        menu.addItem(itemWeb)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Salir de Solarium", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc func toggleDesktopWidget() {
        if desktopWidget == nil { desktopWidget = SolariumDesktopPanel() }
        guard let dw = desktopWidget else { return }
        if dw.isVisible {
            dw.orderOut(nil)
            cardView.btnDesktop.title = "📌 Fijar en Escritorio"
        } else {
            let data = SolarLunarSnapshot.current(lat: lat, lon: lon, tzOffset: tzOffset, cityName: cityName)
            dw.update(with: data)
            dw.makeKeyAndOrderFront(nil)
            cardView.btnDesktop.title = "✕ Ocultar Widget"
        }
    }
    
    @objc func setLevelFloating() { desktopWidget?.level = .floating }
    @objc func setLevelDesktop() { desktopWidget?.level = .desktop }
    
    @objc func setFmtHM() { currentFormat = .solarHM; updateApp() }
    @objc func setFmtHMS() { currentFormat = .solarHMS; updateApp() }
    @objc func setFmtCombined() { currentFormat = .solarAndFixed; updateApp() }
    
    @objc func copySolarTime() {
        let data = SolarLunarSnapshot.current(lat: lat, lon: lon, tzOffset: tzOffset, cityName: cityName)
        let text = String(format: "%02d:%02d:%02d SOLAR (%@)", data.solarHours, data.solarMinutes, data.solarSeconds, data.cityName)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
    
    @objc func openWebApp() {
        let url = URL(string: "http://127.0.0.1:5195")!
        NSWorkspace.shared.open(url)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
