//
//  AppDelegate.swift
//  Insite
//
//  Created by Varun Iyer on 2/11/20.
//  Copyright © 2020 spott. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseMessaging
import CoreLocation
import RIBs

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var application: UIApplication?
    var locationManager: CLLocationManager?
    var notificationCenter: UNUserNotificationCenter?
    var fcmToken: String! {
        didSet {
            if self.idToken != nil {
                self.updateFCMToken()
            }
        }
    }
    var idToken: String? {
        didSet {
            if self.fcmToken != nil {
                self.updateFCMToken()
            }
        }
    }
    
    private var launchRouter: LaunchRouting?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
        self.notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter!.delegate = self
        
        FirebaseApp.configure()
            
        Messaging.messaging().delegate = self
        
        self.application = application
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let launchViewController = LaunchViewController(w: window.frame.width, h: window.frame.height)
        self.window?.rootViewController = launchViewController
        self.window?.makeKeyAndVisible()
        
        if Auth.auth().currentUser != nil {
            Auth.auth().currentUser!.getIDTokenForcingRefresh(true) { idToken, error in
                if let error = error {
                    print("Error getting API ID Token:" + error.localizedDescription)
                    self.launchRouter = RootBuilder(dependency: AppComponent()).build(loggedIn: false)
                    self.launchRouter?.launchFromWindow(window)
                    return
                }
                print(idToken!)
                
                self.idToken = idToken!
                
                self.registerForNotifications()
                
                self.launchRouter = RootBuilder(dependency: AppComponent()).build(loggedIn: true)
                self.launchRouter?.launchFromWindow(window)
            }
        } else {
            launchRouter = RootBuilder(dependency: AppComponent()).build(loggedIn: false)
            launchRouter?.launchFromWindow(window)
        }

        return true
    }

    // MARK: - Helper
    
    func updateFCMToken() {
        // update token in firebase for FCM
    }
    
    func registerForNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { granted, error in
                    guard granted else {
                        UserDefaults.standard.set("denied", forKey: "notificationsPermission")
                        return
                    }
                    
                    UserDefaults.standard.set("authorized", forKey: "notificationsPermission")
                    DispatchQueue.main.async {
                        self.application!.registerForRemoteNotifications()
                    }
            })
            
            application!.registerForRemoteNotifications()
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application!.registerUserNotificationSettings(settings)
            
            application!.registerForRemoteNotifications()
        }
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        let firebaseAuth = Auth.auth()
        firebaseAuth.setAPNSToken(deviceToken, type: AuthAPNSTokenType.unknown)
        
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            if let location = locationManager?.location {
                self.handleEvent(forRegion: region,
                location: location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            if let location = locationManager?.location {
                self.handleEvent(forRegion: region,
                location: location)
            }
        }
    }
    
    func handleEvent(forRegion region: CLRegion, location: CLLocation) {
        let content = UNMutableNotificationContent()
        
        if region.identifier == "myLocation" {
            locationManager?.stopMonitoring(for: region)
            
            if Auth.auth().currentUser != nil {
                Firestore.firestore().collection("Users").document(Auth.auth().currentUser!.uid).collection("data").document("location").updateData(["history": FieldValue.arrayUnion([["location": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), "time": Timestamp(date: Date()), "accuracy": location.horizontalAccuracy]])])
            }
            
            let geofenceRegion = CLCircularRegion(center: location.coordinate, radius: 5, identifier: "myLocation")
            geofenceRegion.notifyOnExit = true
            geofenceRegion.notifyOnEntry = false
            
            locationManager?.startMonitoring(for: geofenceRegion)
        } else {
            content.title = "Near \(region.identifier)?"
            content.body = "There are \(Int.random(in: 2..<15)) friends there now, \(Int.random(in: 15..<50)) people total."
            
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
                } else {
                    if Auth.auth().currentUser != nil {
                        Firestore.firestore().collection("Users").document(Auth.auth().currentUser!.uid).collection("data").document("notifications").updateData(["\(region.identifier).sent": FieldValue.arrayUnion([["location": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), "time": Timestamp(date: Date()), "accuracy": location.horizontalAccuracy]])])
                    }
                }
            })
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
        completionHandler([.alert, .sound])
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let id = response.notification.request.identifier
        
        if locationManager == nil {
            self.locationManager = CLLocationManager()
        }
        
        if let location = locationManager?.location {
            if Auth.auth().currentUser != nil {
                Firestore.firestore().collection("Users").document(Auth.auth().currentUser!.uid).collection("data").document("notifications").updateData(["\(id).opened": FieldValue.arrayUnion([["location": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), "time": Timestamp(date: Date()), "accuracy": location.horizontalAccuracy]])])
            }
        }
        
//        let userInfo = response.notification.request.content.userInfo
//
//        print("USERINFO\n")
//        print(userInfo)
//
//        if let aps = userInfo["aps"] as? [String: Any] {
//            if let chatID = aps["chatID"] as? String {
//                mutableNotificationStream.notificationTapped(with: ["chat": chatID])
//            } else if let userID = aps["userXID"] as? String {
//                mutableNotificationStream.notificationTapped(with: ["stream": userID])
//            } else if let eventID = aps["promoUID"] as? String {
//                mutableNotificationStream.notificationTapped(with: ["trending": eventID])
//            }
//        }
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    // The callback to handle data message received via FCM for devices running iOS 10 or above.
    func applicationReceivedRemoteMessage(_ remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
        
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        
        self.fcmToken = fcmToken
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}
