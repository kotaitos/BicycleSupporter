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
    var sensors:[String: [[Double]]] = [
        "acc": [[Double]]([[0.0, 0.0, 0.0]]),
        "gyro": [[Double]]([[0.0, 0.0, 0.0]]),
        "grav": [[Double]]([[0.0, 0.0, 0.0]]),
        "att": [[Double]]([[0.0, 0.0, 0.0]])
    ]
    var startDate = Date()
    var endDate = Date()
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
        self.sensors = [
            "acc": [[Double]]([[0.0, 0.0, 0.0]]),
            "gyro": [[Double]]([[0.0, 0.0, 0.0]]),
            "grav": [[Double]]([[0.0, 0.0, 0.0]]),
            "att": [[Double]]([[0.0, 0.0, 0.0]])
        ]
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
        
        // save to firebase
        let csvRootPath = uploadToFirestore()
        uploadLocalfileToFirestorage(csvRootPath: csvRootPath)
        
        // save to local
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMdHms", options: 0, locale: Locale(identifier: "ja_JP"))
        let fileName = self.experimentName + "_" + dateFormatter.string(from: startDate) + "~" + dateFormatter.string(from: endDate)
        for (sensorName, sensorArr) in self.sensors {
            saveToLocalCsv(fileName: "\(fileName)-\(sensorName)", fileArrData: sensorArr)
        }
    }

    func updateMotionData(deviceMotion: CMDeviceMotion) {
        self.xAcc = String(deviceMotion.userAcceleration.x)
        self.yAcc = String(deviceMotion.userAcceleration.y)
        self.zAcc = String(deviceMotion.userAcceleration.z)
        self.sensors["acc"]!.append([atof(self.xAcc), atof(self.yAcc), atof(self.zAcc)])
        self.xGyro = String(deviceMotion.rotationRate.x)
        self.yGyro = String(deviceMotion.rotationRate.y)
        self.zGyro = String(deviceMotion.rotationRate.z)
        self.sensors["gyro"]!.append([atof(self.xGyro), atof(self.yGyro), atof(self.zGyro)])
        self.xGrav = String(deviceMotion.gravity.x)
        self.yGrav = String(deviceMotion.gravity.y)
        self.zGrav = String(deviceMotion.gravity.z)
        self.sensors["grav"]!.append([atof(self.xGrav), atof(self.yGrav), atof(self.zGrav)])
        self.xAtt = String(deviceMotion.attitude.pitch)
        self.yAtt = String(deviceMotion.attitude.roll)
        self.zAtt = String(deviceMotion.attitude.yaw)
        self.sensors["att"]!.append([atof(self.xAtt), atof(self.yAtt), atof(self.zAtt)])
        time += 0.1
    }
    
    func uploadToFirestore() -> String{
        let document = db.collection("experiment").document()
        let csvRootPath = "experiment/\(document.documentID)/"
        document.setData([
            "name": self.experimentName,
            "lastUpdatedAt": FieldValue.serverTimestamp(),
            "startAt": Timestamp(date: self.startDate),
            "duration": Double(self.sensors["acc"]!.count) / 10.0,
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
        for (sensorName, sensorArr) in self.sensors {
            var csvStr:String = "x,y,z\n"
            for singleArray in sensorArr{
                for singleString in singleArray{
                    csvStr += "\"" + String(singleString) + "\""
                    if singleString != singleArray[singleArray.count-1]{
                        csvStr += ","
                    }
                }
                csvStr += "\n"
            }
            let csvRef = storageRef.child("\(csvRootPath)\(sensorName).csv")
            let _ = csvRef.putData(Data(csvStr.utf8), metadata: nil) { metadata, error in
              guard let metadata = metadata else {
                self.state = "Error1 uploading \(sensorName) file."
                return
              }
              let _ = metadata.size
                csvRef.downloadURL { (url, error) in
                guard let _ = url else {
                    self.state = "Error2 uploading \(sensorName) file."
                  return
                }
              }
            }
        }
        self.state = "Success uploading csv files."
    }
    
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
