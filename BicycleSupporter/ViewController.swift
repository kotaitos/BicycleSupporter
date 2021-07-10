//
//  ViewController.swift
//  BicycleSupporter
//
//  Created by 斉藤虎太郎 on 2021/07/10.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
  @IBOutlet weak var mapView: MKMapView!
  var locationManager: CLLocationManager!

  override func viewDidLoad() {
     super.viewDidLoad()
     locationManager = CLLocationManager()
     locationManager.delegate = self
     locationManager!.requestWhenInUseAuthorization()
     let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
     let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: span)
     mapView.region = region
  }

 func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            break
        default:
            break
        }
    }
}
