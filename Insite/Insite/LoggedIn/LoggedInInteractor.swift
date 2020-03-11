//
//  LoggedInInteractor.swift
//  Insite
//
//  Created by Varun Iyer on 2/27/20.
//  Copyright © 2020 spott. All rights reserved.
//

import RIBs
import RxSwift
import FirebaseFirestore
import FirebaseAuth
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
import SwiftLocation

protocol LoggedInRouting: ViewableRouting {
    // TODO: Declare methods the interactor can invoke to manage sub-tree via the router.
}

protocol LoggedInPresentable: Presentable {
    var listener: LoggedInPresentableListener? { get set }
    func resetGeofences()
    func createGeofence(lat: Double, long: Double, rad: Double, name: String)
    func addAnnotations(places: [Place])
    func resetAnnotations()
    func drawRoute(id: String, route: Route, dest: CLLocationCoordinate2D)
    func resetRoute()
    func showAnnotations()
    func backButtonEntranceAnimation()
    func backButtonExitAnimation()
    // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol LoggedInListener: class {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

final class LoggedInInteractor: PresentableInteractor<LoggedInPresentable>, LoggedInInteractable, LoggedInPresentableListener {

    weak var router: LoggedInRouting?
    weak var listener: LoggedInListener?

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    init(presenter: LoggedInPresentable, placesStream: MutablePlacesStream, menuStateStream: MutableMenuStateStream) {
        self.placesStream = placesStream
        self.menuStateStream = menuStateStream
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        // TODO: Implement business logic here.
        print("attached LoggedIn")
        updatePlaceAnnotations()
        updateMenuState()
    }

    override func willResignActive() {
        super.willResignActive()
        // TODO: Pause any business logic.
    }
    
    // MARK: - MenuListener
    
    func drawRoute(id: String, route: Route, dest: CLLocationCoordinate2D) {
        presenter.drawRoute(id: id, route: route, dest: dest)
    }
    
    // MARK: - LoggedInPresentableListener
    
    func updateLocation(coordinate: CLLocationCoordinate2D) {
        getGeofences(coordinate: coordinate)
    }
    
    func tappedBackButton() {
        menuStateStream.updateMenuState(with: .collapsed)
    }
    
    func tappedOnPlaceAnnotation(place: Place) {
        if let index = placesStream.getPlaces().firstIndex(of: place) {
            placesStream.prioritizePlace(with: IndexPath(row: index, section: 0))
            menuStateStream.updateMenuState(with: .expanded)
        }
    }
    
    // MARK: - Private
    
    private func getGeofences(coordinate: CLLocationCoordinate2D) {
        if geofenceListener != nil {
            geofenceListener?.remove()
        }
        print(Auth.auth().currentUser!.uid)
        geofenceListener = Firestore.firestore().collection("Users").document(Auth.auth().currentUser!.uid).collection("data").document("geofences").addSnapshotListener({ querySnapshot, error in
            guard let snapshot = querySnapshot else {
               print("Error fetching snapshots: \(error!)")
               return
            }

            if let dict = snapshot.data() {
                self.presenter.resetGeofences()
                
                var places: [Place] = []
                
                for fence in dict as! [String: [String: Any]] {
                    if fence.value["active"] as! Bool == true {
                        if let location = fence.value["location"] as? GeoPoint {
                            if let radius = fence.value["radius"] as? Double {
                                self.presenter.createGeofence(lat: location.latitude, long: location.longitude, rad: radius, name: fence.key)
                            }
                            
                            let place = Place()
                            place.name = fence.key
                            place.image = UIImage(named: place.name)
                            place.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                            place.distance = place.coordinate.distance(from: coordinate)*3.28084
                            
                            let options = GeocoderRequest.Options()

                            LocationManager.shared.locateFromCoordinates(place.coordinate, service: .apple(options)) { result in
                              switch result {
                                case .failure(let error):
                                    debugPrint("An error has occurred: \(error)")
                                case .success(let places):
                                    if places.count > 0 {
                                        if let address = places[0].formattedAddress {
                                            let formattedAddress = address.replacingOccurrences(of: "\n", with: ", ")
                                            place.address = formattedAddress
                                            print("\(place.name) at \(place.address)")
                                        }
                                    }
                                }
                            }
                            
                            let origin = Waypoint(coordinate: coordinate, name: "you")
                            let destination = Waypoint(coordinate: place.coordinate, name: place.name)
                            
                            let walkingOptions = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .walking)
                            
                            Directions.shared.calculate(walkingOptions) { (waypoints, routes, error) in
                                if let route = routes?.first {
                                    place.walkRoute = route
                                    print("\(place.name) got walk")
                                }
                            }
                            
                            let drivingOptions = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobile)
                            Directions.shared.calculate(drivingOptions) { (waypoints, routes, error) in
                                if let route = routes?.first {
                                    place.driveRoute = route
                                    print("\(place.name) got drive")
                                }
                            }
                            
                            places.append(place)
                        }
                    }
                }
                
                self.placesStream.updatePlaces(with: places)
            }
        })
    }
    
    private var geofenceListener: ListenerRegistration?
    
    private func updatePlaceAnnotations() {
        placesStream.places
            .subscribe(onNext: { [weak self] places in
                self?.presenter.resetAnnotations()
                self?.presenter.addAnnotations(places: places)
                self?.presenter.showAnnotations()
            })
            .disposeOnDeactivate(interactor: self)
    }
    
    private func updateMenuState() {
        menuStateStream.state
            .subscribe(onNext: { [weak self] state in
                if state == .expanded {
                    self?.presenter.backButtonEntranceAnimation()
                } else if state == .collapsed {
                    self?.presenter.resetRoute()
                    self?.presenter.showAnnotations()
                    self?.presenter.backButtonExitAnimation()
                }
            })
            .disposeOnDeactivate(interactor: self)
    }
    
    private var placesStream: MutablePlacesStream
    private var menuStateStream: MutableMenuStateStream
}
