//
//  NoteViewModel.swift
//  firebasetest
//
//  Created by macos on 1/2/26.
//

import Foundation

import FirebaseFirestore
import FirebaseFirestoreSwift

struct Note: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var content: String
}


class FirestoreManager: ObservableObject {
    private var db = Firestore.firestore()
    @Published var notes = [Note]()
    
    // Create Note
    func addNote(title: String, content: String) {
        let newNote = Note(title: title, content: content)
        
        do {
            _ = try db.collection("notes").addDocument(from: newNote)
        } catch {
            print("Error adding document: \(error)")
        }
    }
    
    // Read Notes
    func getNotes() {
        db.collection("notes").order(by: "title").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error getting notes: \(error)")
                return
            }
            
            self.notes = snapshot?.documents.compactMap { document in
                try? document.data(as: Note.self)
            } ?? []
        }
    }
    
    // Update Note
    func updateNote(note: Note) {
        guard let noteID = note.id else { return }
        
        do {
            try db.collection("notes").document(noteID).setData(from: note)
        } catch {
            print("Error updating note: \(error)")
        }
    }
    
    // Delete Note
    func deleteNote(note: Note) {
        guard let noteID = note.id else { return }
        
        db.collection("notes").document(noteID).delete { error in
            if let error = error {
                print("Error deleting note: \(error)")
            }
        }
    }
}
