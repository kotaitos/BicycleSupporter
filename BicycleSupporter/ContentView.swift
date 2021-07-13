//
//  ContentView.swift
//  BicycleSupporter
//
//  Created by 斉藤虎太郎 on 2021/06/28.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("map")
                }
            ReportView()
                .tabItem {
                    Image(systemName: "doc.plaintext.fill")
                    Text("report")
                }
            MotionSensorView()
                .tabItem {
                    Image(systemName: "waveform")
                    Text("debug")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
