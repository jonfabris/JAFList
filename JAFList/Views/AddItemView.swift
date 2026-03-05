//
//  AddItemView.swift
//  JAFList

import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    
    var newItemText: Binding<String>
    var onSave: () -> Void = { }
    
    var body: some View {
        VStack {
            TextEditor(text: newItemText)
                .border(Color.gray)
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    onSave()
                }
            }
        }
        .padding(20)
    }
}
