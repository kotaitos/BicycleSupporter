//
//  ContentView.swift
//  BicycleSupporter
//
//  Created by 斉藤虎太郎 on 2021/06/28.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    @ObservedObject var sensor = MotionSensor()
    var body: some View {
        VStack {
            Text("time: \(sensor.time)")
                .padding()
            Text("x = \(sensor.xStr)")
                .padding()
            Text("y = \(sensor.yStr)")
                .padding()
            Text("z = \(sensor.zStr)")
                .padding()
            Button(action: {
                self.sensor.isStarted ? self.sensor.stop() : self.sensor.start()
            }) {
                self.sensor.isStarted ? Text("STOP").padding() : Text("START").padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class MotionSensor: NSObject, ObservableObject {
    @Published var isStarted = false
    @Published var xStr = "0.0"
    @Published var yStr = "0.0"
    @Published var zStr = "0.0"
    @Published var time = 0.0
    var axisData: [[Double]] = [[0.0, 0.0, 0.0]]
    let motionManager = CMMotionManager()
    
    func start() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(motion:CMDeviceMotion?, error:Error?) in
                self.updateMotionData(deviceMotion: motion!)
            })
        }
        
        isStarted = true
    }
    
    func stop() {
        isStarted = false
        motionManager.stopDeviceMotionUpdates()
        print(axisData.count)
        print(axisData)
    }

    func updateMotionData(deviceMotion: CMDeviceMotion) {
        xStr = String(deviceMotion.userAcceleration.x)
        yStr = String(deviceMotion.userAcceleration.y)
        zStr = String(deviceMotion.userAcceleration.z)
        axisData.append([atof(xStr), atof(yStr), atof(zStr)])
        time += 0.1
    }
}
