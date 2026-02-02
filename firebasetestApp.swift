//
//  firebasetestApp.swift
//  firebasetest
//
//  Created by macos on 1/2/26.
//

import SwiftUI
import Firebase

@main
struct firebasetestApp: App {
    
    @StateObject private var viewModel = AuthViewModel()

    @State private var email = ""
    @State private var password = ""

    init()
    {
        FirebaseApp.configure()
        print("Configured Firebase!!!")
        
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if viewModel.isSignedIn {
                    ContentView() .environmentObject(viewModel)
                    
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
}
