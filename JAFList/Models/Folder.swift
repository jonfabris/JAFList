//
//  Folder.swift
//  JAFList

import Foundation

struct Folder: Identifiable, Codable {
    let id: UUID
    var name: String
    var items: [TodoItem]

    init(id: UUID = UUID(), name: String, items: [TodoItem] = []) {
        self.id = id
        self.name = name
        self.items = items
    }
}
