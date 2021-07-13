//
//  MapView.swift
//  BicycleSupporter
//
//  Created by 斉藤虎太郎 on 2021/07/10.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @State var manager = CLLocationManager()
    @State var alert = false
    @State var focus = true
    
    var body: some View {
        VStack(alignment: .leading){
            ZStack(alignment: .bottomTrailing){
                mapView(manager: $manager, alert: $alert, focus: $focus).alert(isPresented: $alert) {
                    Alert(title: Text("Please Enable Location Access In Setting Panel."))
                }
                .edgesIgnoringSafeArea(.all)
                VStack {
                    Button(action: {
                        focus = true
                    }) {
                        Image(systemName: "location.fill")
                            .frame(width: 60, height: 60)
                            .imageScale(.large)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}

struct mapView : UIViewRepresentable{
    typealias UIViewType = MKMapView

    @Binding var manager : CLLocationManager
    @Binding var alert : Bool
    @Binding var focus : Bool
    
    let map = MKMapView()
    let zoomValue = 0.01
    
    func makeCoordinator() -> mapView.Coordinator {
        return mapView.Coordinator(parent1: self)
    }

    func makeUIView(context: UIViewRepresentableContext<mapView>) -> MKMapView {
        let center = CLLocationCoordinate2D(latitude: 35.6804, longitude: 139.7690)
        let span = MKCoordinateSpan(latitudeDelta: zoomValue, longitudeDelta: zoomValue)
        let region = MKCoordinateRegion(center: center, span: span)
        map.setRegion(region, animated: false)
        map.showsUserLocation = true
        map.setUserTrackingMode(.followWithHeading, animated: true)
        manager.delegate = context.coordinator
        manager.startUpdatingLocation()
        manager.requestWhenInUseAuthorization()
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: UIViewRepresentableContext<mapView>) {
        if focus {
            let span = MKCoordinateSpan(latitudeDelta: zoomValue, longitudeDelta: zoomValue)
            let region = MKCoordinateRegion(center: map.userLocation.coordinate, span: span)
            map.setRegion(region, animated: true)
            focus = false
        } else {
            map.setCenter(map.centerCoordinate, animated: false)
        }
        map.setUserTrackingMode(.followWithHeading, animated: true)
    }

    class Coordinator: NSObject, CLLocationManagerDelegate {
        var parent : mapView

        init(parent1 : mapView) {
            parent = parent1
        }

        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

            if status == .denied{
                parent.alert.toggle()
            }
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

            let location = locations.last

            let georeader = CLGeocoder()
            georeader.reverseGeocodeLocation(location!) { (places, err) in

                if err != nil {
                    print((err?.localizedDescription)!)
                    return
                }
            }
        }
    }
}
