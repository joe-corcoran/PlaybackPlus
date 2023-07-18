//
//  PlaybackPlusApp.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/10/23.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

struct FirestoreEnvironmentKey: EnvironmentKey {
    static let defaultValue: Firestore? = nil
}

extension EnvironmentValues {
    var firestore: Firestore? {
        get { self[FirestoreEnvironmentKey.self] }
        set { self[FirestoreEnvironmentKey.self] = newValue }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var firestore: Firestore!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        firestore = Firestore.firestore()
        return true
    }
}

class SessionManager: ObservableObject {
    @Published var isLoggedIn = false
    private var firestore: Firestore!

    init() {
        isLoggedIn = Auth.auth().currentUser != nil
        firestore = Firestore.firestore()
    }

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                self?.isLoggedIn = true
                completion(.success(()))
            }
        }
    }

    func signup(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                self?.isLoggedIn = true
                completion(.success(()))
            }
        }
    }

    func saveUserData(_ data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "wristruments.PlaybackPlus.SessionManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }

        firestore.collection("users").document(userId).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func saveSnippets(_ snippets: [Snippet], forSong song: Song, completion: @escaping (Result<Void, Error>) -> Void) {
            do {
                // Convert the snippets to a dictionary representation
                let snippetData = try snippets.map { snippet -> [String: Any] in
                    let snippetDict: [String: Any] = [
                        "id": snippet.id.uuidString,
                        "startTime": snippet.startTime,
                        "endTime": snippet.endTime,
                        "name": snippet.name,
                        "isPlaying": snippet.isPlaying,
                        "note": snippet.note
                    ]
                    return snippetDict
                }

                // Save the snippets data to Firestore
                guard let userId = Auth.auth().currentUser?.uid else {
                    let error = NSError(domain: "wristruments.PlaybackPlus.SessionManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(.failure(error))
                    return
                }

                let documentRef = firestore.collection("users").document(userId).collection("songs").document(song.id.uuidString)
                documentRef.setData(["snippets": snippetData]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    


    func getUserData(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "wristruments.PlaybackPlus.SessionManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }

        firestore.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = snapshot?.data() {
                completion(.success(data))
            } else {
                let error = NSError(domain: "wristruments.PlaybackPlus.SessionManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
                completion(.failure(error))
            }
        }
    }
}

@main
struct PlaybackPlusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            if sessionManager.isLoggedIn {
                EmptyMusicPlayerView()
                    .environment(\.firestore, delegate.firestore)
                    .environmentObject(sessionManager)
            } else {
                LoginView()
                    .environment(\.firestore, delegate.firestore)
                    .environmentObject(sessionManager)
            }
        }
    }
}



//test

//test
