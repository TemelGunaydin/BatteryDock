import Foundation

struct AppCopy {
    let language: AppLanguage

    var connectedDevicesEmpty: String { text(.connectedDevicesEmpty) }
    var bluetoothUnavailable: String { text(.bluetoothUnavailable) }
    var retry: String { text(.retry) }
    var refresh: String { text(.refresh) }
    var refreshing: String { text(.refreshing) }
    var noBatteryData: String { text(.noBatteryData) }
    var settings: String { text(.settings) }
    var quit: String { text(.quit) }
    var shortcut: String { text(.shortcut) }
    var lastUpdatedPrefix: String { text(.lastUpdatedPrefix) }
    var general: String { text(.general) }
    var launchAtLogin: String { text(.launchAtLogin) }
    var refreshSetting: String { text(.refreshSetting) }
    var languageSetting: String { text(.languageSetting) }
    var notifications: String { text(.notifications) }
    var lowBatteryAlerts: String { text(.lowBatteryAlerts) }
    var threshold: String { text(.threshold) }
    var menuBar: String { text(.menuBar) }
    var privacy: String { text(.privacy) }
    var privacyNote: String { text(.privacyNote) }
    var support: String { text(.support) }
    var copyDiagnostic: String { text(.copyDiagnostic) }
    var reset: String { text(.reset) }
    var close: String { text(.close) }
    var back: String { text(.back) }
    var recordPrompt: String { text(.recordPrompt) }
    var invalidShortcut: String { text(.invalidShortcut) }
    var diagnosticCopied: String { text(.diagnosticCopied) }
    var loginItemFailed: String { text(.loginItemFailed) }

    func connectedDeviceCount(_ count: Int) -> String {
        String(format: text(.connectedDeviceCount), count)
    }

    func readingLabel(_ reading: BatteryReading) -> String {
        switch reading.kind {
        case .main:
            return text(.battery)
        case .left:
            return text(.left)
        case .right:
            return text(.right)
        case .case:
            return text(.caseBattery)
        case .other:
            return reading.label
        }
    }

    func menuBarModeLabel(_ mode: MenuBarDisplayMode) -> String {
        switch mode {
        case .iconOnly:
            return text(.iconOnly)
        case .lowestPercent:
            return text(.lowestPercent)
        case .criticalDevice:
            return text(.criticalDevice)
        }
    }

    func refreshIntervalLabel(_ interval: RefreshInterval) -> String {
        switch interval {
        case .manual:
            return text(.manual)
        case .thirtySeconds:
            return text(.thirtySeconds)
        case .oneMinute:
            return text(.oneMinute)
        case .fiveMinutes:
            return text(.fiveMinutes)
        }
    }

    func languageLabel(_ appLanguage: AppLanguage) -> String {
        switch appLanguage {
        case .turkish:
            return "Türkçe"
        case .english:
            return "English"
        case .german:
            return "Deutsch"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .italian:
            return "Italiano"
        case .portuguese:
            return "Português"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .chineseSimplified:
            return "简体中文"
        }
    }

    private func text(_ key: CopyKey) -> String {
        CopyTable.values[key]?[language]
            ?? CopyTable.values[key]?[.english]
            ?? ""
    }
}

private enum CopyKey {
    case connectedDevicesEmpty
    case bluetoothUnavailable
    case retry
    case refresh
    case refreshing
    case noBatteryData
    case settings
    case quit
    case shortcut
    case lastUpdatedPrefix
    case connectedDeviceCount
    case battery
    case left
    case right
    case caseBattery
    case iconOnly
    case lowestPercent
    case criticalDevice
    case manual
    case thirtySeconds
    case oneMinute
    case fiveMinutes
    case general
    case launchAtLogin
    case refreshSetting
    case languageSetting
    case notifications
    case lowBatteryAlerts
    case threshold
    case menuBar
    case privacy
    case privacyNote
    case support
    case copyDiagnostic
    case reset
    case close
    case back
    case recordPrompt
    case invalidShortcut
    case diagnosticCopied
    case loginItemFailed
}

private enum CopyTable {
    static let values: [CopyKey: [AppLanguage: String]] = [
        .connectedDevicesEmpty: [
            .turkish: "Bağlı Bluetooth cihazı yok",
            .english: "No connected Bluetooth devices",
            .german: "Keine verbundenen Bluetooth-Geräte",
            .spanish: "No hay dispositivos Bluetooth conectados",
            .french: "Aucun appareil Bluetooth connecté",
            .italian: "Nessun dispositivo Bluetooth connesso",
            .portuguese: "Nenhum dispositivo Bluetooth conectado",
            .japanese: "接続中のBluetoothデバイスはありません",
            .korean: "연결된 Bluetooth 기기가 없습니다",
            .chineseSimplified: "没有已连接的蓝牙设备"
        ],
        .bluetoothUnavailable: [
            .turkish: "Bluetooth bilgisi okunamadı",
            .english: "Bluetooth data unavailable",
            .german: "Bluetooth-Daten nicht verfügbar",
            .spanish: "Datos de Bluetooth no disponibles",
            .french: "Données Bluetooth indisponibles",
            .italian: "Dati Bluetooth non disponibili",
            .portuguese: "Dados de Bluetooth indisponíveis",
            .japanese: "Bluetooth情報を取得できません",
            .korean: "Bluetooth 데이터를 사용할 수 없습니다",
            .chineseSimplified: "蓝牙数据不可用"
        ],
        .retry: [
            .turkish: "Tekrar dene",
            .english: "Retry",
            .german: "Erneut versuchen",
            .spanish: "Reintentar",
            .french: "Réessayer",
            .italian: "Riprova",
            .portuguese: "Tentar novamente",
            .japanese: "再試行",
            .korean: "다시 시도",
            .chineseSimplified: "重试"
        ],
        .refresh: [
            .turkish: "Yenile",
            .english: "Refresh",
            .german: "Aktualisieren",
            .spanish: "Actualizar",
            .french: "Actualiser",
            .italian: "Aggiorna",
            .portuguese: "Atualizar",
            .japanese: "更新",
            .korean: "새로 고침",
            .chineseSimplified: "刷新"
        ],
        .refreshing: [
            .turkish: "Yenileniyor",
            .english: "Refreshing",
            .german: "Aktualisiert",
            .spanish: "Actualizando",
            .french: "Actualisation",
            .italian: "Aggiornamento",
            .portuguese: "Atualizando",
            .japanese: "更新中",
            .korean: "새로 고치는 중",
            .chineseSimplified: "正在刷新"
        ],
        .noBatteryData: [
            .turkish: "macOS pil bilgisini paylaşmıyor",
            .english: "macOS does not expose battery data",
            .german: "macOS stellt keine Batteriedaten bereit",
            .spanish: "macOS no muestra datos de batería",
            .french: "macOS n’expose pas les données de batterie",
            .italian: "macOS non espone i dati della batteria",
            .portuguese: "O macOS não expõe dados da bateria",
            .japanese: "macOSがバッテリー情報を公開していません",
            .korean: "macOS가 배터리 데이터를 제공하지 않습니다",
            .chineseSimplified: "macOS未提供电池数据"
        ],
        .settings: [
            .turkish: "Ayarlar",
            .english: "Settings",
            .german: "Einstellungen",
            .spanish: "Ajustes",
            .french: "Réglages",
            .italian: "Impostazioni",
            .portuguese: "Ajustes",
            .japanese: "設定",
            .korean: "설정",
            .chineseSimplified: "设置"
        ],
        .quit: [
            .turkish: "Çıkış",
            .english: "Quit",
            .german: "Beenden",
            .spanish: "Salir",
            .french: "Quitter",
            .italian: "Esci",
            .portuguese: "Sair",
            .japanese: "終了",
            .korean: "종료",
            .chineseSimplified: "退出"
        ],
        .shortcut: [
            .turkish: "Kısayol",
            .english: "Shortcut",
            .german: "Kurzbefehl",
            .spanish: "Atajo",
            .french: "Raccourci",
            .italian: "Scorciatoia",
            .portuguese: "Atalho",
            .japanese: "ショートカット",
            .korean: "단축키",
            .chineseSimplified: "快捷键"
        ],
        .lastUpdatedPrefix: [
            .turkish: "Son",
            .english: "Last",
            .german: "Zuletzt",
            .spanish: "Última",
            .french: "Dernière",
            .italian: "Ultimo",
            .portuguese: "Última",
            .japanese: "最終",
            .korean: "마지막",
            .chineseSimplified: "上次"
        ],
        .connectedDeviceCount: [
            .turkish: "%d bağlı cihaz",
            .english: "%d connected",
            .german: "%d verbunden",
            .spanish: "%d conectados",
            .french: "%d connectés",
            .italian: "%d connessi",
            .portuguese: "%d conectados",
            .japanese: "%d台接続中",
            .korean: "%d개 연결됨",
            .chineseSimplified: "已连接%d个"
        ],
        .battery: [
            .turkish: "Pil",
            .english: "Battery",
            .german: "Akku",
            .spanish: "Batería",
            .french: "Batterie",
            .italian: "Batteria",
            .portuguese: "Bateria",
            .japanese: "バッテリー",
            .korean: "배터리",
            .chineseSimplified: "电池"
        ],
        .left: [
            .turkish: "Sol",
            .english: "Left",
            .german: "Links",
            .spanish: "Izq.",
            .french: "Gauche",
            .italian: "Sinistra",
            .portuguese: "Esq.",
            .japanese: "左",
            .korean: "왼쪽",
            .chineseSimplified: "左"
        ],
        .right: [
            .turkish: "Sağ",
            .english: "Right",
            .german: "Rechts",
            .spanish: "Der.",
            .french: "Droite",
            .italian: "Destra",
            .portuguese: "Dir.",
            .japanese: "右",
            .korean: "오른쪽",
            .chineseSimplified: "右"
        ],
        .caseBattery: [
            .turkish: "Kutu",
            .english: "Case",
            .german: "Case",
            .spanish: "Estuche",
            .french: "Boîtier",
            .italian: "Custodia",
            .portuguese: "Estojo",
            .japanese: "ケース",
            .korean: "케이스",
            .chineseSimplified: "充电盒"
        ],
        .iconOnly: [
            .turkish: "Sadece ikon",
            .english: "Icon only",
            .german: "Nur Symbol",
            .spanish: "Solo icono",
            .french: "Icône seule",
            .italian: "Solo icona",
            .portuguese: "Só ícone",
            .japanese: "アイコンのみ",
            .korean: "아이콘만",
            .chineseSimplified: "仅图标"
        ],
        .lowestPercent: [
            .turkish: "En düşük yüzde",
            .english: "Lowest percent",
            .german: "Niedrigster Wert",
            .spanish: "Porcentaje menor",
            .french: "Pourcentage le plus bas",
            .italian: "Percentuale più bassa",
            .portuguese: "Menor porcentagem",
            .japanese: "最低残量",
            .korean: "최저 배터리",
            .chineseSimplified: "最低电量"
        ],
        .criticalDevice: [
            .turkish: "Kritik cihaz",
            .english: "Critical device",
            .german: "Kritisches Gerät",
            .spanish: "Dispositivo crítico",
            .french: "Appareil critique",
            .italian: "Dispositivo critico",
            .portuguese: "Dispositivo crítico",
            .japanese: "低残量デバイス",
            .korean: "위험 기기",
            .chineseSimplified: "低电量设备"
        ],
        .manual: [
            .turkish: "Manuel",
            .english: "Manual",
            .german: "Manuell",
            .spanish: "Manual",
            .french: "Manuel",
            .italian: "Manuale",
            .portuguese: "Manual",
            .japanese: "手動",
            .korean: "수동",
            .chineseSimplified: "手动"
        ],
        .thirtySeconds: [
            .turkish: "30 sn",
            .english: "30 sec",
            .german: "30 s",
            .spanish: "30 s",
            .french: "30 s",
            .italian: "30 sec",
            .portuguese: "30 s",
            .japanese: "30秒",
            .korean: "30초",
            .chineseSimplified: "30秒"
        ],
        .oneMinute: [
            .turkish: "1 dk",
            .english: "1 min",
            .german: "1 Min.",
            .spanish: "1 min",
            .french: "1 min",
            .italian: "1 min",
            .portuguese: "1 min",
            .japanese: "1分",
            .korean: "1분",
            .chineseSimplified: "1分钟"
        ],
        .fiveMinutes: [
            .turkish: "5 dk",
            .english: "5 min",
            .german: "5 Min.",
            .spanish: "5 min",
            .french: "5 min",
            .italian: "5 min",
            .portuguese: "5 min",
            .japanese: "5分",
            .korean: "5분",
            .chineseSimplified: "5分钟"
        ],
        .general: [
            .turkish: "Genel",
            .english: "General",
            .german: "Allgemein",
            .spanish: "General",
            .french: "Général",
            .italian: "Generali",
            .portuguese: "Geral",
            .japanese: "一般",
            .korean: "일반",
            .chineseSimplified: "通用"
        ],
        .launchAtLogin: [
            .turkish: "Girişte başlat",
            .english: "Launch at login",
            .german: "Beim Anmelden starten",
            .spanish: "Abrir al iniciar sesión",
            .french: "Lancer à l’ouverture",
            .italian: "Apri al login",
            .portuguese: "Abrir ao iniciar sessão",
            .japanese: "ログイン時に起動",
            .korean: "로그인 시 실행",
            .chineseSimplified: "登录时启动"
        ],
        .refreshSetting: [
            .turkish: "Yenileme",
            .english: "Refresh",
            .german: "Aktualisierung",
            .spanish: "Actualización",
            .french: "Actualisation",
            .italian: "Aggiorna",
            .portuguese: "Atualização",
            .japanese: "更新",
            .korean: "새로 고침",
            .chineseSimplified: "刷新"
        ],
        .languageSetting: [
            .turkish: "Dil",
            .english: "Language",
            .german: "Sprache",
            .spanish: "Idioma",
            .french: "Langue",
            .italian: "Lingua",
            .portuguese: "Idioma",
            .japanese: "言語",
            .korean: "언어",
            .chineseSimplified: "语言"
        ],
        .notifications: [
            .turkish: "Bildirimler",
            .english: "Notifications",
            .german: "Mitteilungen",
            .spanish: "Notificaciones",
            .french: "Notifications",
            .italian: "Notifiche",
            .portuguese: "Notificações",
            .japanese: "通知",
            .korean: "알림",
            .chineseSimplified: "通知"
        ],
        .lowBatteryAlerts: [
            .turkish: "Düşük pil bildirimi",
            .english: "Low battery alerts",
            .german: "Warnungen bei niedrigem Akku",
            .spanish: "Avisos de batería baja",
            .french: "Alertes batterie faible",
            .italian: "Avvisi batteria scarica",
            .portuguese: "Alertas de bateria fraca",
            .japanese: "低バッテリー通知",
            .korean: "배터리 부족 알림",
            .chineseSimplified: "低电量提醒"
        ],
        .threshold: [
            .turkish: "Eşik",
            .english: "Threshold",
            .german: "Grenzwert",
            .spanish: "Umbral",
            .french: "Seuil",
            .italian: "Soglia",
            .portuguese: "Limite",
            .japanese: "しきい値",
            .korean: "임계값",
            .chineseSimplified: "阈值"
        ],
        .menuBar: [
            .turkish: "Menü bar",
            .english: "Menu bar",
            .german: "Menüleiste",
            .spanish: "Barra de menús",
            .french: "Barre des menus",
            .italian: "Barra dei menu",
            .portuguese: "Barra de menus",
            .japanese: "メニューバー",
            .korean: "메뉴 막대",
            .chineseSimplified: "菜单栏"
        ],
        .privacy: [
            .turkish: "Gizlilik",
            .english: "Privacy",
            .german: "Datenschutz",
            .spanish: "Privacidad",
            .french: "Confidentialité",
            .italian: "Privacy",
            .portuguese: "Privacidade",
            .japanese: "プライバシー",
            .korean: "개인정보",
            .chineseSimplified: "隐私"
        ],
        .privacyNote: [
            .turkish: "Veriler cihazda kalır. Backend, hesap ve analytics yok.",
            .english: "Data stays on device. No backend, account, or analytics.",
            .german: "Daten bleiben auf dem Gerät. Kein Backend, Konto oder Analytics.",
            .spanish: "Los datos permanecen en el dispositivo. Sin backend, cuenta ni analíticas.",
            .french: "Les données restent sur l’appareil. Aucun backend, compte ni analytics.",
            .italian: "I dati restano sul dispositivo. Nessun backend, account o analytics.",
            .portuguese: "Os dados ficam no dispositivo. Sem backend, conta ou analytics.",
            .japanese: "データはデバイス上に残ります。バックエンド、アカウント、分析はありません。",
            .korean: "데이터는 기기에만 저장됩니다. 백엔드, 계정, 분석 기능은 없습니다.",
            .chineseSimplified: "数据保留在设备上。没有后端、账号或分析。"
        ],
        .support: [
            .turkish: "Destek",
            .english: "Support",
            .german: "Support",
            .spanish: "Soporte",
            .french: "Assistance",
            .italian: "Supporto",
            .portuguese: "Suporte",
            .japanese: "サポート",
            .korean: "지원",
            .chineseSimplified: "支持"
        ],
        .copyDiagnostic: [
            .turkish: "Tanıyı kopyala",
            .english: "Copy diagnostics",
            .german: "Diagnose kopieren",
            .spanish: "Copiar diagnóstico",
            .french: "Copier le diagnostic",
            .italian: "Copia diagnostica",
            .portuguese: "Copiar diagnóstico",
            .japanese: "診断をコピー",
            .korean: "진단 복사",
            .chineseSimplified: "复制诊断"
        ],
        .reset: [
            .turkish: "Sıfırla",
            .english: "Reset",
            .german: "Zurücksetzen",
            .spanish: "Restablecer",
            .french: "Réinitialiser",
            .italian: "Ripristina",
            .portuguese: "Redefinir",
            .japanese: "リセット",
            .korean: "재설정",
            .chineseSimplified: "重置"
        ],
        .close: [
            .turkish: "Kapat",
            .english: "Close",
            .german: "Schließen",
            .spanish: "Cerrar",
            .french: "Fermer",
            .italian: "Chiudi",
            .portuguese: "Fechar",
            .japanese: "閉じる",
            .korean: "닫기",
            .chineseSimplified: "关闭"
        ],
        .back: [
            .turkish: "Geri",
            .english: "Back",
            .german: "Zurück",
            .spanish: "Atrás",
            .french: "Retour",
            .italian: "Indietro",
            .portuguese: "Voltar",
            .japanese: "戻る",
            .korean: "뒤로",
            .chineseSimplified: "返回"
        ],
        .recordPrompt: [
            .turkish: "Tuşa basın",
            .english: "Press keys",
            .german: "Tasten drücken",
            .spanish: "Pulsa las teclas",
            .french: "Appuyez sur les touches",
            .italian: "Premi i tasti",
            .portuguese: "Pressione as teclas",
            .japanese: "キーを押してください",
            .korean: "키를 누르세요",
            .chineseSimplified: "按下按键"
        ],
        .invalidShortcut: [
            .turkish: "⌘, ⌥, ⌃ veya ⇧ ile kaydedin.",
            .english: "Use ⌘, ⌥, ⌃, or ⇧.",
            .german: "⌘, ⌥, ⌃ oder ⇧ verwenden.",
            .spanish: "Usa ⌘, ⌥, ⌃ o ⇧.",
            .french: "Utilisez ⌘, ⌥, ⌃ ou ⇧.",
            .italian: "Usa ⌘, ⌥, ⌃ o ⇧.",
            .portuguese: "Use ⌘, ⌥, ⌃ ou ⇧.",
            .japanese: "⌘、⌥、⌃、または⇧を使用してください。",
            .korean: "⌘, ⌥, ⌃ 또는 ⇧를 사용하세요.",
            .chineseSimplified: "请使用⌘、⌥、⌃或⇧。"
        ],
        .diagnosticCopied: [
            .turkish: "Tanı panoya kopyalandı.",
            .english: "Diagnostics copied.",
            .german: "Diagnose kopiert.",
            .spanish: "Diagnóstico copiado.",
            .french: "Diagnostic copié.",
            .italian: "Diagnostica copiata.",
            .portuguese: "Diagnóstico copiado.",
            .japanese: "診断をコピーしました。",
            .korean: "진단이 복사되었습니다.",
            .chineseSimplified: "诊断已复制。"
        ],
        .loginItemFailed: [
            .turkish: "Login item güncellenemedi.",
            .english: "Login item could not be updated.",
            .german: "Anmeldeobjekt konnte nicht aktualisiert werden.",
            .spanish: "No se pudo actualizar el ítem de inicio.",
            .french: "Impossible de mettre à jour l’élément de connexion.",
            .italian: "Impossibile aggiornare l’elemento di login.",
            .portuguese: "Não foi possível atualizar o item de início de sessão.",
            .japanese: "ログイン項目を更新できませんでした。",
            .korean: "로그인 항목을 업데이트할 수 없습니다.",
            .chineseSimplified: "无法更新登录项。"
        ]
    ]
}
