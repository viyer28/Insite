//
//  AppDelegate.swift
//  Insite
//
//  Created by Varun Iyer on 2/11/20.
//  Copyright © 2020 spott. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var application: UIApplication?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.application = application
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let mapViewController = MapViewController(w: window.frame.width, h: window.frame.height)
        self.window?.rootViewController = mapViewController
        self.window?.makeKeyAndVisible()
        
        FirebaseApp.configure()
        return true
    }

}

