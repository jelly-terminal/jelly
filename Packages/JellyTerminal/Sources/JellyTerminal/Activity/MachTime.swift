import Darwin

enum MachTime {
    private static let timebase: (numer: UInt64, denom: UInt64) = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info.denom == 0 ? (1, 1) : (UInt64(info.numer), UInt64(info.denom))
    }()

    static func nanoseconds(_ ticks: UInt64) -> UInt64 {
        let (high, low) = ticks.multipliedFullWidth(by: timebase.numer)
        return timebase.denom.dividingFullWidth((high, low)).quotient
    }
}
