//
//  Item.swift
//  ArcBrowser
//
//  Created by Sharath Chenna on 04/04/26.
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
