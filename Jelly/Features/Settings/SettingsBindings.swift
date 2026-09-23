import JellyCore
import SwiftUI

extension ConfigStore {
    func binding<Value: Equatable>(
        _ keyPath: KeyPath<JellyCore.Settings, Value>,
        at path: [String],
        as encode: @escaping (Value) -> TOMLValue
    ) -> Binding<Value> {
        Binding(
            get: { self.config.settings[keyPath: keyPath] },
            set: { value in
                guard value != self.config.settings[keyPath: keyPath] else { return }
                self.set(encode(value), at: ["settings"] + path)
            }
        )
    }

    func toggle(_ keyPath: KeyPath<JellyCore.Settings, Bool>, at path: String...) -> Binding<Bool> {
        binding(keyPath, at: path, as: TOMLValue.bool)
    }
}

extension TOMLValue {
    static func number(_ value: Double) -> TOMLValue {
        value == value.rounded() ? .integer(Int(value)) : .float((value * 100).rounded() / 100)
    }

    static func inlineTable(_ pairs: KeyValuePairs<String, TOMLValue>) -> TOMLValue {
        var table = TOMLTable()
        for (key, value) in pairs { table.set(key, value) }
        return .table(table)
    }
}
