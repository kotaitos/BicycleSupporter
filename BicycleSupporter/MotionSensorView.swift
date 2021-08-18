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
            Text("実験の名前を入力してください")
            TextField("実験の名前", text: $motionSensor.experimentName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Text("status: \(motionSensor.state)")
            HStack {
                VStack {
                    Text("Accelometer")
                        .padding()
                    Text("x = \(motionSensor.xAcc)")
                    Text("y = \(motionSensor.yAcc)")
                    Text("z = \(motionSensor.zAcc)")
                }
                VStack {
                    Text("Gyro")
                        .padding()
                    Text("x = \(motionSensor.xGyro)")
                    Text("y = \(motionSensor.yGyro)")
                    Text("z = \(motionSensor.zGyro)")
                }
            }
            HStack {
                VStack {
                    Text("Gravity")
                        .padding()
                    Text("x = \(motionSensor.xGrav)")
                    Text("y = \(motionSensor.yGrav)")
                    Text("z = \(motionSensor.zGrav)")
                }
                VStack {
                    Text("Attitude")
                        .padding()
                    Text("x = \(motionSensor.xAtt)")
                    Text("y = \(motionSensor.yAtt)")
                    Text("z = \(motionSensor.zAtt)")
                }
            }
            Button(action: {
                self.motionSensor.isStarted ? self.motionSensor.stop() : self.motionSensor.start()
            }) {
                self.motionSensor.isStarted ? Text("STOP").padding() : Text("START").padding()
            }
            .disabled(motionSensor.experimentName.isEmpty)
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
    @Published var xGrav = "0.0"
    @Published var yGrav = "0.0"
    @Published var zGrav = "0.0"
    @Published var xAtt = "0.0"
    @Published var yAtt = "0.0"
    @Published var zAtt = "0.0"
    @Published var time = 0.0
    @Published var state = "waiting"
    @Published var experimentName = ""
    var startDate = Date()
    var endDate = Date()
    var accelerationArrData: [[Double]] = [[Double]]()
    var gyroArrData: [[Double]] = [[Double]]()
    var gravArrData: [[Double]] = [[Double]]()
    var attArrData: [[Double]] = [[Double]]()
    let motionManager = CMMotionManager()
    
    func start() {
        self.experimentName = experimentName
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
        let fileName = self.experimentName + "_" + dateFormatter.string(from: startDate) + "~" + dateFormatter.string(from: endDate)
        saveToLocalCsv(fileName: "\(fileName)-acc", fileArrData: accelerationArrData)
        saveToLocalCsv(fileName: "\(fileName)-gyro", fileArrData: gyroArrData)
        saveToLocalCsv(fileName: "\(fileName)-grav", fileArrData: gravArrData)
        saveToLocalCsv(fileName: "\(fileName)-att", fileArrData: attArrData)
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
        xGrav = String(deviceMotion.gravity.x)
        yGrav = String(deviceMotion.gravity.y)
        zGrav = String(deviceMotion.gravity.z)
        gravArrData.append([atof(xGrav), atof(yGrav), atof(zGrav)])
        xAtt = String(deviceMotion.attitude.pitch)
        yAtt = String(deviceMotion.attitude.roll)
        zAtt = String(deviceMotion.attitude.yaw)
        attArrData.append([atof(xAtt), atof(yAtt), atof(zAtt)])
        time += 0.1
    }
    
    //多次元配列からDocuments下にCSVファイルを作る
    func saveToLocalCsv(fileName : String, fileArrData : [[Double]]){
        // save acc data to csv
        let filePath = NSHomeDirectory() + "/Documents/" + fileName + ".csv"
        var fileStrData:String = "x,y,z\n"
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
