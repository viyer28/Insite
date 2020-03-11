//
//  Places.swift
//  Insite
//
//  Created by Varun Iyer on 3/11/20.
//  Copyright © 2020 spott. All rights reserved.
//

import RxSwift
import UIKit
import CoreLocation
import MapboxDirections

public class Place: NSObject {
    var name: String = ""
    
    var image: UIImage!
    
    var coordinate: CLLocationCoordinate2D!
    
    var distance: Double = 0
    
    var address: String = "locating..."
    
    var walkRoute: Route?
    
    var driveRoute: Route?
}

public protocol PlacesStream: class {
    var places: Observable<[Place]> { get }
    func getPlaces() -> [Place]
}

public protocol MutablePlacesStream: PlacesStream {
    func updatePlaces(with places: [Place])
    func prioritizePlace(with indexPath: IndexPath)
}

public class PlacesStreamImpl: MutablePlacesStream {
    
    public init() {}
    
    public var places: Observable<[Place]> {
        return variable
            .asObservable()
    }
    
    public func updatePlaces(with places: [Place]) {
        allPlaces = places
        variable.value = places
    }
    
    public func prioritizePlace(with indexPath: IndexPath) {
        if allPlaces.count > 0 {
            let place = allPlaces.remove(at: indexPath.row)
            allPlaces.insert(place, at: 0)
            variable.value = allPlaces
        }
    }
    
    public func getPlaces() -> [Place] {
        return variable.value
    }
    
    // MARK: - Private
    
    private let variable = Variable<[Place]>([])
    private var allPlaces: [Place] = []
}
