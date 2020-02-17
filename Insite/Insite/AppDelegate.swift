//
//  AppDelegate.swift
//  Insite
//
//  Created by Varun Iyer on 2/11/20.
//  Copyright © 2020 spott. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var application: UIApplication?
    var locationManager: CLLocationManager?
    var notificationCenter: UNUserNotificationCenter?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
        self.notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter!.delegate = self
        
        if launchOptions?[UIApplication.LaunchOptionsKey.location] == nil {
            let options: UNAuthorizationOptions = [.alert, .sound]
            notificationCenter?.requestAuthorization(options: options, completionHandler: { (granted, errors) in
                if !granted {
                    print("Permission not granted")
                }
            })
            
            FirebaseApp.configure()
            
            self.application = application
            
            let window = UIWindow(frame: UIScreen.main.bounds)
            self.window = window
            
            let mapViewController = MapViewController(w: window.frame.width, h: window.frame.height)
            self.window?.rootViewController = mapViewController
            self.window?.makeKeyAndVisible()
        }

        return true
    }

}

extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            self.handleEvent(forRegion: region,
                             accuracy: locationManager?.location?.horizontalAccuracy,
                             entryFlag: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            self.handleEvent(forRegion: region,
                             accuracy: locationManager?.location?.horizontalAccuracy,
                             entryFlag: false)
        }
    }
    
    func handleEvent(forRegion region: CLRegion, accuracy: Double?, entryFlag: Bool) {
        let content = UNMutableNotificationContent()
        
        if entryFlag {
            content.title = "You have arrived at \(region.identifier)"
        } else {
            content.title = "You are now exiting \(region.identifier)"
        }
        
        if let accuracy = accuracy {
            content.body = "\(accuracy)m"
        } else {
            content.body = "No Accuracy Data Available"
        }
        
        content.sound = UNNotificationSound.default
        
        let timeInSeconds: TimeInterval = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInSeconds,
                                                        repeats: false)
        
        let identifier = region.identifier
        
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        
        notificationCenter?.add(request, withCompletionHandler: {(error) in
            if error != nil {
                print("Error adding notificaion with identifier: \(identifier)")
            }
        })
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
        completionHandler([.alert, .sound])
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let _ = response.notification.request.identifier
        
    }
}
