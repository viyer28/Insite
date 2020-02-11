//
//  MapViewController.swift
//  Insite
//
//  Created by Varun Iyer on 2/11/20.
//  Copyright © 2020 spott. All rights reserved.
//

import UIKit
import Mapbox

final class MapViewController: UIViewController {
    
    init(w: CGFloat, h: CGFloat) {
        self.w = w
        self.h = h
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Method is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        _setupMapView()
        view.addSubview(mapView)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        createLocationManager()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom]
    }
    
    private func createLocationManager() {
        locationManager = CLLocationManager()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.distanceFilter = 5
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = false
        } else {
            // Fallback on earlier versions
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func _setupMapView() {
        let url = URL(string: "mapbox://styles/spottiyer/ck05sz4xx1qmn1co21xc9c1e9")
        mapView = MGLMapView(frame: CGRect(x: 0, y: 0, width: w, height: h), styleURL: url)
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.automaticallyAdjustsContentInset = true
        mapView.compassView.isHidden = true
        mapView.center = view.center
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        mapView.isUserInteractionEnabled = true
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    private var mapView: MGLMapView!
    private let w: CGFloat
    private let h: CGFloat
    private var location: CLLocation?
    private var locationManager: CLLocationManager!
}

extension MapViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        return nil
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return false
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        
        // Add a MGLFillExtrusionStyleLayer.
        addFillExtrusionLayer(style: style)

        // Create an MGLLight object.
        let light = MGLLight()

        // Create an MGLSphericalPosition and set the radial, azimuthal, and polar values.
        // Radial : Distance from the center of the base of an object to its light. Takes a CGFloat.
        // Azimuthal : Position of the light relative to its anchor. Takes a CLLocationDirection.
        // Polar : The height of the light. Takes a CLLocationDirection.
        let position = MGLSphericalPositionMake(10, 0, 80)
        light.position = NSExpression(forConstantValue: NSValue(mglSphericalPosition: position))

        // Set the light anchor to the map and add the light object to the map view's style. The light anchor can be the viewport (or rotates with the viewport) or the map (rotates with the map). To make the viewport the anchor, replace `map` with `viewport`.
        light.anchor = NSExpression(forConstantValue: "map")
        style.light = light
    }
    
    func addFillExtrusionLayer(style: MGLStyle) {
        // Access the Mapbox Streets source and use it to create a `MGLFillExtrusionStyleLayer`. The source identifier is `composite`. Use the `sources` property on a style to verify source identifiers.
        let source = style.source(withIdentifier: "composite")!
        let layer = MGLFillExtrusionStyleLayer(identifier: "extrusion-layer", source: source)
        layer.sourceLayerIdentifier = "building"
        layer.fillExtrusionBase = NSExpression(forKeyPath: "min_height")
        layer.fillExtrusionHeight = NSExpression(forKeyPath: "height")
        layer.fillExtrusionOpacity = NSExpression(forConstantValue: 0.2)
        layer.fillExtrusionColor = NSExpression(forConstantValue: UIColor.white)
        
        // Access the map's layer with the identifier "poi-scalerank3" and insert the fill extrusion layer below it.
        if let symbolLayer = style.layer(withIdentifier: "poi-scalerank3") {
            style.insertLayer(layer, below: symbolLayer)
        } else {
            style.addLayer(layer)
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let mostRecentLocation = locations.last else {
            return
        }
        self.location = mostRecentLocation
        
        mapView.setCenter(location!.coordinate, zoomLevel: 14, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.denied) {
            // The user denied authorization

        } else if (status == CLAuthorizationStatus.authorizedAlways) {
            // The user accepted authorization

        } else if (status == CLAuthorizationStatus.notDetermined) {
            
        } else if (status == CLAuthorizationStatus.authorizedWhenInUse) {

        }
    }
}

