//
//  ContentView.swift
//  BicycleSupporter
//
//  Created by 斉藤虎太郎 on 2021/06/28.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    @ObservedObject var accelerationSensor = AccelerationSensor()
    var body: some View {
        VStack {
            Text("Accelometer")
                .padding()
            Text("status: \(accelerationSensor.state)")
                .padding()
            Text("x = \(accelerationSensor.xStr)")
                .padding()
            Text("y = \(accelerationSensor.yStr)")
                .padding()
            Text("z = \(accelerationSensor.zStr)")
                .padding()
            Button(action: {
                self.accelerationSensor.isStarted ? self.accelerationSensor.stop() : self.accelerationSensor.start()
            }) {
                self.accelerationSensor.isStarted ? Text("STOP").padding() : Text("START").padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class AccelerationSensor: NSObject, ObservableObject {
    @Published var isStarted = false
    @Published var xStr = "0.0"
    @Published var yStr = "0.0"
    @Published var zStr = "0.0"
    @Published var time = 0.0
    @Published var state = "waiting"
    var startDate = Date()
    var endDate = Date()
    var accelerationArrData: [[Double]] = [[Double]]()
    let motionManager = CMMotionManager()
    
    func start() {
        state = "running"
        if motionManager.isDeviceMotionAvailable {
            startDate = Date()
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(motion:CMDeviceMotion?, error:Error?) in
                self.updateMotionData(deviceMotion: motion!)
            })
        }
        
        isStarted = true
    }
    
    func stop() {
        state = "finish"
        endDate = Date()
        isStarted = false
        motionManager.stopDeviceMotionUpdates()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMdHms", options: 0, locale: Locale(identifier: "ja_JP"))
        let fileName = dateFormatter.string(from: startDate) + "~" + dateFormatter.string(from: endDate)
        saveToCsv(fileName: fileName, fileArrData: accelerationArrData)
    }

    func updateMotionData(deviceMotion: CMDeviceMotion) {
        xStr = String(deviceMotion.userAcceleration.x)
        yStr = String(deviceMotion.userAcceleration.y)
        zStr = String(deviceMotion.userAcceleration.z)
        accelerationArrData.append([atof(xStr), atof(yStr), atof(zStr)])
        time += 0.1
    }
    
    //多次元配列からDocuments下にCSVファイルを作る
    func saveToCsv(fileName : String, fileArrData : [[Double]]){
        let filePath = NSHomeDirectory() + "/Documents/" + fileName + ".csv"
        var fileStrData:String = "x,y,z\n"
        //StringのCSV用データを準備
        for singleArray in fileArrData{
            for singleString in singleArray{
                fileStrData += "\"" + String(singleString) + "\""
                if singleString != singleArray[singleArray.count-1]{
                    fileStrData += ","
                }
            }
            fileStrData += "\n"
        }
        do{
            try fileStrData.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
            state = "Success to Wite the File"
        }catch let error as NSError{
            state = "Failure to Write File\n\(error)"
        }
    }
}
