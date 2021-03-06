//
//  AppDelegate.swift
//  Messenger
//
//  Created by Carlos Cardona on 08/06/20.
//  Copyright © 2020 D O G. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        FirebaseApp.configure()
          
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self

        return true
    }
          
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        return GIDSignIn.sharedInstance().handle(url)
        
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with google: \(error)")
            }
            return
        }
        guard let user = user else {
            return
        }
        
        print("Did sign in with Google: \(user)")
        
        guard let email = user.profile.email,
            let firsName = user.profile.givenName,
            let lastName = user.profile.familyName else {
                return
        }
        
        DatabaseManager.shared.userExists(with: email, completion: { exists in
            if !exists {
                // Instert to database
                DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firsName, lastName: lastName, emailAddress: email))
            }
        })
        
        guard let authentication = user.authentication else {
            print("Missing auth object of google user")
            return
            
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult, error in
            guard authResult != nil, error == nil else{
                print("failed to log in with google credential")
                return
            }
            
            print("succesfully signed in with google credential")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user was disconnected")
    }
    
    
    

}

    
