//
//  FirebaseService.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/18/23.
//

import Foundation
import FirebaseAuth

class FirebaseService {
    func signup(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
         Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
             if let error = error {
                 // Signup failed
                 completion(.failure(error))
             } else {
                 // Signup successful
                 completion(.success(()))
             }
         }
     }
    
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    // Login failed
                    completion(.failure(error))
                } else {
                    // Login successful
                    completion(.success(()))
                }
            }
        }
    
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
