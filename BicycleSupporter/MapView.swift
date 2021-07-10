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
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.011_286, longitude: -116.166_868),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    @State private var userTrackingMode: MapUserTrackingMode = .follow

    var body: some View {
        ZStack {
            VStack {
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode
                )
                .edgesIgnoringSafeArea(.all)
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        print("Button tapped.")
                    }) {
                        Image(systemName: "location")
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
