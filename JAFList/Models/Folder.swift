//
//  Folder.swift
//  JAFList

import Foundation

struct Folder: Identifiable, Codable {
    let id: UUID
    var name: String
    var items: [TodoItem]
    var subfolders: [Folder]

    init(id: UUID = UUID(), name: String, items: [TodoItem] = [], subfolders: [Folder] = []) {
        self.id = id
        self.name = name
        self.items = items
        self.subfolders = subfolders
    }
}
