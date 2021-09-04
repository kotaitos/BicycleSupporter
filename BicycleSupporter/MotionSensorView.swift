//
//  MotionSensorView.swift
//  BicycleSupporter
//
//  Created by 斉藤虎太郎 on 2021/07/10.
//

import SwiftUI
import CoreMotion
import FirebaseFirestore
import FirebaseStorage


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
            Button(action: {self.motionSensor.clear()}, label: {
                Text("CLEAR").padding()
            })
        }
    }
}

struct MotionSensorView_Previews: PreviewProvider {
    static var previews: some View {
        MotionSensorView()
    }
}

class MotionSensor: NSObject, ObservableObject {
    private var db = Firestore.firestore()
    private var storage = Storage.storage(url: "gs://bicycle-supporter.appspot.com")
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
    
    func clear() {
        self.isStarted = false
        self.xAcc = "0.0"
        self.yAcc = "0.0"
        self.zAcc = "0.0"
        self.xGyro = "0.0"
        self.yGyro = "0.0"
        self.zGyro = "0.0"
        self.xGrav = "0.0"
        self.yGrav = "0.0"
        self.zGrav = "0.0"
        self.xAtt = "0.0"
        self.yAtt = "0.0"
        self.zAtt = "0.0"
        self.time = 0.0
        self.state = "waiting"
        self.experimentName = ""
        self.startDate = Date()
        self.endDate = Date()
        self.accelerationArrData = [[Double]]()
        self.gyroArrData = [[Double]]()
        self.gravArrData = [[Double]]()
        self.attArrData = [[Double]]()
    }
    
    func start() {
        self.experimentName = experimentName
        if motionManager.isDeviceMotionAvailable {
            state = "running"
            startDate = Date()
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.showsDeviceMovementDisplay = true
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
        let csvRootPath = uploadToFirestore()
        uploadLocalfileToFirestorage(csvRootPath: csvRootPath)
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
    
    func uploadToFirestore() -> String{
        let document = db.collection("experiment").document()
        let csvRootPath = "experiment/\(document.documentID)/"
        document.setData([
            "name": self.experimentName,
            "lastUpdatedAt": FieldValue.serverTimestamp(),
            "startAt": Timestamp(date: self.startDate),
            "duration": Double(self.accelerationArrData.count) / 10.0,
            "csvRootUrl": csvRootPath
        ]){ err in
            if let err = err {
                self.state = "Error writing document: \(err)"
            } else {
                self.state = "Document successfully written!"
            }
        }
        return csvRootPath
    }
    
    func uploadLocalfileToFirestorage(csvRootPath: String){
        let storageRef = storage.reference()
        
        // acc
        var accStr:String = "x,y,z\n"
        for singleArray in self.accelerationArrData{
            for singleString in singleArray{
                accStr += "\"" + String(singleString) + "\""
                if singleString != singleArray[singleArray.count-1]{
                    accStr += ","
                }
            }
            accStr += "\n"
        }
        let accCsvRef = storageRef.child("\(csvRootPath)acc.csv")
        let _ = accCsvRef.putData(Data(accStr.utf8), metadata: nil) { metadata, error in
          guard let metadata = metadata else {
            self.state = "Error1 uploading acc file."
            return
          }
          let _ = metadata.size
            accCsvRef.downloadURL { (url, error) in
            guard let _ = url else {
                self.state = "Error2 uploading acc file."
              return
            }
          }
        }
        
        // gyro
        var gyroStr:String = "x,y,z\n"
        for singleArray in self.gyroArrData{
            for singleString in singleArray{
                gyroStr += "\"" + String(singleString) + "\""
                if singleString != singleArray[singleArray.count-1]{
                    gyroStr += ","
                }
            }
            gyroStr += "\n"
        }
        let gyroCsvRef = storageRef.child("\(csvRootPath)gyro.csv")
        let _ = gyroCsvRef.putData(Data(gyroStr.utf8), metadata: nil) { metadata, error in
          guard let metadata = metadata else {
            self.state = "Error1 uploading gyro file."
            return
          }
          let _ = metadata.size
            gyroCsvRef.downloadURL { (url, error) in
            guard let _ = url else {
                self.state = "Error2 uploading gyro file."
              return
            }
          }
        }
        
        // grav
        var gravStr:String = "x,y,z\n"
        for singleArray in self.gravArrData{
            for singleString in singleArray{
                gravStr += "\"" + String(singleString) + "\""
                if singleString != singleArray[singleArray.count-1]{
                    gravStr += ","
                }
            }
            gravStr += "\n"
        }
        let gravCsvRef = storageRef.child("\(csvRootPath)grav.csv")
        let _ = gravCsvRef.putData(Data(gravStr.utf8), metadata: nil) { metadata, error in
          guard let metadata = metadata else {
            self.state = "Error1 uploading grav file."
            return
          }
          let _ = metadata.size
            gravCsvRef.downloadURL { (url, error) in
            guard let _ = url else {
                self.state = "Error2 uploading grav file."
              return
            }
          }
        }
        
        // att
        var attStr:String = "x,y,z\n"
        for singleArray in self.attArrData{
            for singleString in singleArray{
                attStr += "\"" + String(singleString) + "\""
                if singleString != singleArray[singleArray.count-1]{
                    attStr += ","
                }
            }
            attStr += "\n"
        }
        let attCsvRef = storageRef.child("\(csvRootPath)att.csv")
        let _ = attCsvRef.putData(Data(attStr.utf8), metadata: nil) { metadata, error in
          guard let metadata = metadata else {
            self.state = "Error1 uploading att file."
            return
          }
          let _ = metadata.size
            attCsvRef.downloadURL { (url, error) in
            guard let _ = url else {
                self.state = "Error2 uploading att file."
              return
            }
          }
        }
    }
}
