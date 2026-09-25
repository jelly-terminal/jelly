enum ActivityTab: String, CaseIterable, Identifiable {
    case processes
    case ports
    case system

    var id: Self { self }

    var title: String {
        switch self {
        case .processes: "Processes"
        case .ports: "Ports"
        case .system: "System"
        }
    }

    var symbol: String {
        switch self {
        case .processes: "list.bullet"
        case .ports: "network"
        case .system: "gauge.with.dots.needle.33percent"
        }
    }
}
