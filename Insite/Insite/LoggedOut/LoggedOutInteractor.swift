//
//  LoggedOutInteractor.swift
//  Insite
//
//  Created by Varun Iyer on 2/27/20.
//  Copyright © 2020 spott. All rights reserved.
//

import RIBs
import RxSwift
import FirebaseAuth
import FirebaseFirestore

protocol LoggedOutRouting: ViewableRouting {
    // TODO: Declare methods the interactor can invoke to manage sub-tree via the router.
}

protocol LoggedOutPresentable: Presentable {
    var listener: LoggedOutPresentableListener? { get set }
    // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol LoggedOutListener: class {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
    func login()
}

final class LoggedOutInteractor: PresentableInteractor<LoggedOutPresentable>, LoggedOutInteractable, LoggedOutPresentableListener {

    weak var router: LoggedOutRouting?
    weak var listener: LoggedOutListener?

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: LoggedOutPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        // TODO: Implement business logic here.
        print("attached LoggedOut")
    }

    override func willResignActive() {
        super.willResignActive()
        // TODO: Pause any business logic.
    }
    
    // MARK: - LoggedOutPresentableListener
    
    func authenticate(verificationID: String, verificationCode: String) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        Auth.auth().signIn(with: credential) { authData, error in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                if Auth.auth().currentUser != nil
                {
                    Auth.auth().currentUser!.getIDTokenForcingRefresh(true) { idToken, error in
                        if let error = error {
                            print("Error getting API ID Token:" + error.localizedDescription)
                        }
                        
                        Firestore.firestore()
                            .collection("Users")
                            .document(Auth.auth().currentUser!.uid).setData([:]) { err in
                            if let err = err {
                                print("Error writing document: \(err)")
                            } else {
                                print("Document successfully written!")
                                
                                Firestore.firestore()
                                    .collection("Users")
                                    .document(Auth.auth().currentUser!.uid)
                                    .collection("data")
                                    .document("location")
                                    .setData(["history": []])
                                
                                Firestore.firestore()
                                    .collection("Users")
                                    .document(Auth.auth().currentUser!.uid)
                                    .collection("data")
                                    .document("notifications")
                                    .setData(["Reg": ["sent": [], "opened": []],
                                              "Harper": ["sent": [], "opened": []],
                                              "Crerar": ["sent": [], "opened": []],
                                              "North": ["sent": [], "opened": []],
                                              "Booth": ["sent": [], "opened": []],
                                              "Quad": ["sent": [], "opened": []],
                                              "Ratner": ["sent": [], "opened": []],
                                              "Saieh": ["sent": [], "opened": []],
                                              "Crown": ["sent": [], "opened": []],
                                              "Reynold's": ["sent": [], "opened": []]])
                                
                                Firestore.firestore()
                                    .collection("Users")
                                    .document(Auth.auth().currentUser!.uid)
                                    .collection("data")
                                    .document("geofences")
                                    .setData(["Reg": ["active": true,
                                                       "location": GeoPoint(latitude: 41.792171, longitude: -87.599934),
                                                       "radius": 75.0],
                                                "Harper": ["active": false,
                                                        "location": GeoPoint(latitude: 41.787953, longitude: -87.599584),
                                                        "radius": 40.0],
                                                "Crerar": ["active": false,
                                                        "location": GeoPoint(latitude: 41.790534, longitude: -87.602835),
                                                        "radius": 50.0],
                                                "North": ["active": true,
                                                        "location": GeoPoint(latitude: 41.794764, longitude: -87.598754),
                                                        "radius": 40.0],
                                                "Booth": ["active": false,
                                                        "location": GeoPoint(latitude: 41.789115, longitude: -87.595585),
                                                        "radius": 55.0],
                                                "Quad": ["active": true,
                                                        "location": GeoPoint(latitude: 41.789587, longitude: -87.599659),
                                                        "radius": 50.0],
                                                "Ratner": ["active": false,
                                                           "location": GeoPoint(latitude: 41.794361, longitude:  -87.602028),
                                                           "radius": 30.33],
                                                "Saieh": ["active": false,
                                                          "location": GeoPoint(latitude: 41.789861, longitude:  -87.597232),
                                                          "radius": 32.03],
                                                "Crown": ["active": false,
                                                          "location": GeoPoint(latitude: 41.793573, longitude:  -87.598938),
                                                          "radius": 34.64],
                                                "Reynold's": ["active": false,
                                                              "location": GeoPoint(latitude: 41.791120, longitude:  -87.598675),
                                                              "radius": 20.0]])
                                self.listener?.login()
                            }
                        }
                    }
                }
            }
        }
    }
}
