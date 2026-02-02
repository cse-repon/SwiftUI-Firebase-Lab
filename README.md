SwiftUI and Firebase: Building Modern iOS Apps with a Cloud‑Backed Stack
Introduction

SwiftUI is Apple’s modern user‑interface framework. Apple describes it as a declarative system in which you write down the desired outcome and let the framework translate that into a functional UI. Declarative code helps keep SwiftUI apps succinct and readable. Views are composed hierarchically using struct types, and SwiftUI automatically updates the UI when the state changes. The framework runs on all Apple platforms—iOS, macOS, watchOS and tvOS—making it a unified approach to interface design.

Firebase is Google’s serverless backend platform. It offers ready‑made services such as authentication, scalable NoSQL databases, file storage, analytics and crash reporting. By connecting a SwiftUI app to Firebase you can implement sign‑in, real‑time data sync and cloud storage without writing custom server code. The Firebase SDK for Apple platforms integrates seamlessly with SwiftUI, and the backend scales automatically as your app’s user base grows.

This guide summarises Octavia’s Medium tutorial on integrating Firebase with SwiftUI (published 8 December 2024) and supplements it with official documentation from Apple and Firebase. It walks through creating a Firebase project, adding the Firebase SDK via Swift Package Manager (SPM), initialising Firebase in your app, implementing email/password authentication, building a real‑time notes app using Cloud Firestore and testing and deploying the app.

Why Use Firebase with SwiftUI?

Before adding a cloud backend to your app, you should understand what Firebase provides and why it pairs well with SwiftUI:

Authentication – Firebase offers a secure identity platform with SDKs and drop‑in UI components. It supports email/password login, phone number verification and federated providers like Google, Facebook, Twitter and GitHub. The SDK can also send password‑reset emails and link multiple providers to a single account.

Cloud Firestore – A flexible, scalable NoSQL database built on Google Cloud. It stores data in documents organized into collections, supports expressive queries, provides real‑time updates via listeners and works offline—changes are synchronized when the device regains connectivity.

Storage – Firebase Cloud Storage makes it easy to upload and serve user‑generated images, audio or video files.

Analytics & Crashlytics – Built‑in analytics track user engagement, and Crashlytics reports crashes in real time to help you identify and fix issues quickly.

Combining SwiftUI with Firebase enables you to build reactive UIs that stay up to date with backend data, handle authentication flows elegantly and leverage production‑ready backend services with minimal configuration.

Setting Up Your Firebase Project

Create a Firebase project. Visit the Firebase console
, click Add project, and follow the wizard. For an iOS app, select iOS and enter your app’s Bundle Identifier (found in Xcode’s General → Identity section).

Download your configuration file. After registering the app, Firebase generates a GoogleService-Info.plist file. Download it and drag it into your Xcode project, making sure it’s added to all targets. This file contains API keys and configuration needed by the Firebase SDK.

Adding Firebase to Your SwiftUI Project

Firebase can be added to an Xcode project via the Swift Package Manager (SPM):

In Xcode select File → Add Packages…

Paste the Firebase iOS SDK URL https://github.com/firebase/firebase-ios-sdk .

Select the modules you need—FirebaseAuth for authentication and FirebaseFirestore for the database. You can add other modules like Storage, Analytics or Crashlytics if needed.

Initialising Firebase in Your App

Create or modify your main App struct to configure Firebase when the app launches:

import SwiftUI
import SwiftData
import Firebase

@main
struct YourAppName: App {
    init() {
        FirebaseApp.configure()            // initialize Firebase
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory) // enable App Check in debug builds
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


The FirebaseApp.configure() call registers your GoogleService‑Info.plist file. App Check is optional but recommended; it helps protect backend resources from abuse by verifying that requests originate from legitimate instances of your app.

Implementing Email and Password Authentication

Firebase Authentication abstracts away server‑side sign‑in logic and integrates with SwiftUI. The tutorial implements authentication in two parts: a view model and a view.

Authentication ViewModel

Create a class conforming to ObservableObject that exposes user state and methods to sign up, sign in and sign out:

import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var isSignedIn: Bool = false

    init() {
        self.user = Auth.auth().currentUser
        self.isSignedIn = (user != nil)
    }

    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign Up Error: \(error.localizedDescription)")
                return
            }
            self.user = result?.user
            self.isSignedIn = true
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign In Error: \(error.localizedDescription)")
                return
            }
            self.user = result?.user
            self.isSignedIn = true
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isSignedIn = false
        } catch {
            print("Sign Out Error: \(error.localizedDescription)")
        }
    }
}


The @Published properties automatically trigger UI updates when the user’s sign‑in state changes. Firebase’s Authentication SDK methods handle account creation, sign‑in and sign‑out; errors are printed to the console for debugging.

SwiftUI Authentication View

In your SwiftUI view you can observe the AuthViewModel and present different UI depending on whether a user is signed in:

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            if viewModel.isSignedIn {
                FContentView()                       // show Firestore content
            } else {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                HStack {
                    Button("Sign In") {
                        viewModel.signIn(email: email, password: password)
                    }
                    Button("Sign Up") {
                        viewModel.signUp(email: email, password: password)
                    }
                }
            }
        }
        .padding()
    }
}


When the user is signed in, the app navigates to FContentView, which displays Firestore data. Otherwise, text fields and buttons allow the user to sign in or register.

Integrating Firestore for Real‑Time Data

Firestore is Firebase’s scalable, cloud‑hosted NoSQL database. It stores data as documents inside collections and can stream updates in real time. The tutorial builds a simple notes app.

Define a Model

Define a Note structure that conforms to Identifiable and Codable and uses the @DocumentID property wrapper so Firestore automatically manages document IDs:

import FirebaseFirestore

struct Note: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var content: String
}


Create a Firestore Manager

The FirestoreManager is an ObservableObject that encapsulates all Firestore operations:

import FirebaseFirestore

class FirestoreManager: ObservableObject {
    private var db = Firestore.firestore()
    @Published var notes = [Note]()

    // Create note
    func addNote(title: String, content: String) {
        let newNote = Note(title: title, content: content)
        do {
            _ = try db.collection("notes").addDocument(from: newNote)
        } catch {
            print("Error adding document: \(error)")
        }
    }

    // Read notes with realtime updates
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

    // Update note
    func updateNote(note: Note) {
        guard let noteID = note.id else { return }
        do {
            try db.collection("notes").document(noteID).setData(from: note)
        } catch {
            print("Error updating note: \(error)")
        }
    }

    // Delete note
    func deleteNote(note: Note) {
        guard let noteID = note.id else { return }
        db.collection("notes").document(noteID).delete { error in
            if let error = error {
                print("Error deleting note: \(error)")
            }
        }
    }
}


Using a snapshot listener ensures the notes array updates whenever documents change in Firestore.

Displaying and Editing Notes

In your FContentView, observe the FirestoreManager and present a list of notes. Provide actions for creating, editing and deleting notes, and a sign‑out button:

struct FContentView: View {
    @StateObject private var firestoreManager = FirestoreManager()
    @State private var showingAddNote = false
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack {
            NavigationView {
                List {
                    ForEach(firestoreManager.notes) { note in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(note.title).font(.headline)
                                Text(note.content).font(.subheadline)
                            }
                            Spacer()
                            Button("Delete") {
                                firestoreManager.deleteNote(note: note)
                            }
                        }
                        .swipeActions {
                            Button("Edit") {
                                showingAddNote = true
                                // open editing UI
                            }.tint(.blue)
                        }
                    }
                }
                .navigationTitle("Notes")
                .navigationBarItems(trailing: Button(action: {
                    showingAddNote = true
                }) {
                    Image(systemName: "plus")
                })
                .onAppear {
                    firestoreManager.getNotes()
                }
                .sheet(isPresented: $showingAddNote) {
                    AddNoteView(firestoreManager: firestoreManager)
                }
            }
            Button(action: {
                authViewModel.signOut()
            }) {
                Text("Sign Out")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
    }
}


AddNoteView is presented as a sheet and provides a form for entering the note’s title and content. When the Save button is tapped, it calls addNote on FirestoreManager and dismisses the sheet:

struct AddNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var firestoreManager: FirestoreManager
    @State private var title = ""
    @State private var content = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Details")) {
                    TextField("Title", text: $title)
                    TextField("Content", text: $content)
                }
                Button("Save") {
                    firestoreManager.addNote(title: title, content: content)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Add")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}


This pattern of using an ObservableObject for data access and a separate View for UI scales to more complex apps. Cloud Firestore ensures that changes propagate in real time across devices and sessions.

Testing and Deployment

Once you’ve implemented authentication and Firestore functionality, you should test on both physical devices and simulators. Verify that user sign‑in, registration and note management work correctly. The tutorial suggests enabling App Check for additional security and thoroughly testing on real devices before submission.

When you’re satisfied, you can prepare your app for release:

Enable App Check: In the Firebase console, configure App Check to protect your project’s resources.

Build & test release builds: Use TestFlight or internal testers to validate the app on a variety of devices and iOS versions.

Submit to the App Store: Follow Apple’s guidelines to distribute your app. Ensure that GoogleService‑Info.plist is included in the release build and that any necessary privacy statements (e.g., data collection via Firebase Analytics) are included.

Conclusion

SwiftUI’s declarative UI model and Firebase’s cloud services form a powerful combination for building modern mobile apps. Firebase simplifies authentication, real‑time data storage and analytics, allowing you to focus on delivering a great user experience. This guide covered integrating Firebase into a SwiftUI project, implementing email/password sign‑in and building a note‑taking app with Cloud Firestore. From here you can explore more Firebase features such as Cloud Functions for server‑side logic, Storage for media files, Remote Config for feature flagging, and Analytics for understanding user behaviour.

References

O. Octavia, “SwiftUI + Firebase: The Complete Step‑by‑Step Guide to Building Mobile Apps,” Medium, 8 Dec 2024.

Apple Developer Documentation: Get Started with SwiftUI.

Google Firebase Documentation: Cloud Firestore.

Google Firebase Documentation: Firebase Authentication.
