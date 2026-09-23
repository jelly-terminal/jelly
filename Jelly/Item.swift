//
//  Item.swift
//  Jelly
//
//  Created by Monawwar Abdullah on 23/09/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
