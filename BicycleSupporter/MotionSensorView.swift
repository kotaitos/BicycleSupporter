//
//  MotionSensorView.swift
//  BicycleSupporter
//
//  Created by 斉藤虎太郎 on 2021/07/10.
//

import SwiftUI
import CoreMotion


struct MotionSensorView: View {
    @ObservedObject var motionSensor = MotionSensor()
    var body: some View {
        VStack {
            Text("status: \(motionSensor.state)")
            Text("Accelometer")
                .padding()
            Text("x = \(motionSensor.xAcc)")
            Text("y = \(motionSensor.yAcc)")
            Text("z = \(motionSensor.zAcc)")
            Text("Gyro")
                .padding()
            Text("x = \(motionSensor.xGyro)")
            Text("y = \(motionSensor.yGyro)")
            Text("z = \(motionSensor.zGyro)")
            Button(action: {
                self.motionSensor.isStarted ? self.motionSensor.stop() : self.motionSensor.start()
            }) {
                self.motionSensor.isStarted ? Text("STOP").padding() : Text("START").padding()
            }
        }
    }
}

struct MotionSensorView_Previews: PreviewProvider {
    static var previews: some View {
        MotionSensorView()
    }
}

class MotionSensor: NSObject, ObservableObject {
    @Published var isStarted = false
    @Published var xAcc = "0.0"
    @Published var yAcc = "0.0"
    @Published var zAcc = "0.0"
    @Published var xGyro = "0.0"
    @Published var yGyro = "0.0"
    @Published var zGyro = "0.0"
    @Published var time = 0.0
    @Published var state = "waiting"
    var startDate = Date()
    var endDate = Date()
    var accelerationArrData: [[Double]] = [[Double]]()
    var gyroArrData: [[Double]] = [[Double]]()
    let motionManager = CMMotionManager()
    
    func start() {
        if motionManager.isDeviceMotionAvailable {
            state = "running"
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
        xAcc = String(deviceMotion.userAcceleration.x)
        yAcc = String(deviceMotion.userAcceleration.y)
        zAcc = String(deviceMotion.userAcceleration.z)
        accelerationArrData.append([atof(xAcc), atof(yAcc), atof(zAcc)])
        xGyro = String(deviceMotion.rotationRate.x)
        yGyro = String(deviceMotion.rotationRate.y)
        zGyro = String(deviceMotion.rotationRate.z)
        gyroArrData.append([atof(xGyro), atof(yGyro), atof(zGyro)])
        time += 0.1
    }
    
    //多次元配列からDocuments下にCSVファイルを作る
    func saveToCsv(fileName : String, fileArrData : [[Double]]){
        // save acc data to csv
        let accFilePath = NSHomeDirectory() + "/Documents/" + fileName + ".accelometer.csv"
        var accFileStrData:String = "x,y,z\n"
        for singleArray in fileArrData{
            for singleString in singleArray{
                accFileStrData += "\"" + String(singleString) + "\""
                if singleString != singleArray[singleArray.count-1]{
                    accFileStrData += ","
                }
            }
            accFileStrData += "\n"
        }
        do{
            try accFileStrData.write(toFile: accFilePath, atomically: true, encoding: String.Encoding.utf8)
            state = "Success to Wite the File"
        }catch let error as NSError{
            state = "Failure to Write File\n\(error)"
        }
        
        // save gyro data to csv
        let gyroFilePath = NSHomeDirectory() + "/Documents/" + fileName + ".gyro.csv"
        var gyroFileStrData:String = "x,y,z\n"
        for singleArray in fileArrData{
            for singleString in singleArray{
                gyroFileStrData += "\"" + String(singleString) + "\""
                if singleString != singleArray[singleArray.count-1]{
                    gyroFileStrData += ","
                }
            }
            gyroFileStrData += "\n"
        }
        do{
            try accFileStrData.write(toFile: gyroFilePath, atomically: true, encoding: String.Encoding.utf8)
            state = "Success to Wite the File"
        }catch let error as NSError{
            state = "Failure to Write File\n\(error)"
        }
    }
}

