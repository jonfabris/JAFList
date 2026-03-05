//
//  AppData.swift
//  JAFList

import Foundation

struct AppData: Codable {
    var folders: [Folder]
    var lastModified: Date

    static var empty: AppData {
        AppData(folders: [], lastModified: Date(timeIntervalSince1970: 0))
    }

    init(folders: [Folder], lastModified: Date = Date()) {
        self.folders = folders
        self.lastModified = lastModified
    }
}
