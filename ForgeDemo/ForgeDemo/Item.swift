//
//  Item.swift
//  ForgeDemo
//
//  Created by Tate Jennings on 3/27/26.
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
