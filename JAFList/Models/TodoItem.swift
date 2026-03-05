//
//  TodoItem.swift
//  JAFList

import Foundation

struct TodoItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var isExpanded: Bool
    var children: [TodoItem]

    init(id: UUID = UUID(), text: String, isCompleted: Bool = false, isExpanded: Bool = false, children: [TodoItem] = []) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.isExpanded = isExpanded
        self.children = children
    }
}
