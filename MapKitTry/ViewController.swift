//
//  ViewController.swift
//  MapKitTry
//
//  Created by Ryan Drum on 5/18/16.
//  Copyright © 2016 pdrum. All rights reserved.
//
import Foundation
import UIKit
import MapKit
import CoreLocation
import Alamofire
import SwiftyJSON
import Firebase
import FirebaseStorage
import FBSDKCoreKit
//import GameKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    
    
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var mapLoadingCircle: UIActivityIndicatorView!
    @IBOutlet weak var getKeyButton: UIButton!
    @IBOutlet weak var keyRequestButton: UIButton!
    @IBOutlet weak var townMotto: UILabel!
    @IBOutlet weak var kingName: UILabel!
    @IBOutlet weak var kingProfPic: UIImageView!
    @IBOutlet weak var scoreTop: UIBarButtonItem!
    @IBOutlet weak var townLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    var key = MKPointAnnotation()
    let locationManager = CLLocationManager()
    var first: Bool = true
    var lastCoords = CLLocation(latitude: 0, longitude: 0)
    var score = 0
    var timer = 0
    var window: UIWindow?
    var ref = FIRDatabase.database().reference()
    var name = ""
    var facebookID = ""
    var townList:[String] = []
    let storageRef = FIRStorage.storage().referenceForURL("firebaseKey")
    let user = FIRAuth.auth()?.currentUser
    var userPushID = ""
    
    
    //cached data
    var currentPushID = ""
    var currentTown = ""
    var currentState = ""
    var currentTownPath = ""
    var currentZip = ""
    var currentIndex = 0
    var oldSeed = -1
    var requestLast = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getKeyButton.hidden = true
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
        self.mapView.delegate = self
        //self.mapView.showsCompass = false
        self.score = 0
        // Get user value
        if  !(user?.anonymous)! {
            
            if FBSDKAccessToken.currentAccessToken() != nil {
                getFacebookInfo()
            }
        } else {
            self.facebookID = "-1"
            self.userPushID = "-1"
            self.name = "Guest"
        }
        
        //code for sending a push notification based on player ID
        /*
        OneSignal.defaultClient().postNotification(["contents": ["en": "Test Message"], "include_player_ids": ["700c1c41-924d-4315-8712-d87f30c36a8d"]])
         */
    }
    
    func getFacebookInfo() {
        let parameters = ["fields": "first_name, last_name, id"]
        FBSDKGraphRequest(graphPath: "me", parameters: parameters).startWithCompletionHandler {(connection, result, error) -> Void in
        
            if error != nil {
                print(error)
                return
            }
            
            if let fName = result["first_name"] as? String {
                self.name = fName
            }
            /*if let lName = result["last_name"] as? String { //add if you want last name shown
                self.name += lName
            }*/
            if let id = result["id"] as? String {
                self.facebookID = id
                self.ref.child("users/\(self.facebookID)/userFBID").setValue(id)
            }
            self.ref.child("users/\(self.facebookID)/name").setValue(self.name)
            
            
            self.ref.child("users").child(self.facebookID).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if "\(snapshot.value!["pushID"])" == "nil" {
                    //print("creating new data")
                    self.ref.child("users/\(self.facebookID)/towns/0").setValue("empty")
                    self.townList = ["empty"]
                } else {
                    self.townList = snapshot.value!["towns"] as! [String]
                }
                //every time because phone may change
                OneSignal.defaultClient().IdsAvailable({ (userId, pushToken) in
                    self.userPushID = userId
                    self.ref.child("users/\(self.facebookID)/pushID").setValue(userId)
                })
            }) { (error) in
                print(error.localizedDescription)
            }
        
        }
    }
    
    func getProfPic(fid: String) -> UIImage? {
        if (fid != "" && fid != "-1") {
            let imgURLString = "http://graph.facebook.com/" + fid + "/picture?height=350&width=350"
            let imgURL = NSURL(string: imgURLString)
            let imageData = NSData(contentsOfURL: imgURL!)
            let image = UIImage(data: imageData!)
            return image
        } else if (fid == "-1") {
            //print("use default")
            let image = UIImage(named: "profileDefault.png")
            //self.keyRequestButton.setTitle("", forState: UIControlState.Normal)
            return image
        }
        return nil
    }
    
    
    
    @IBAction func CheckKeyGet(sender: UIButton) {
        //make sure the key of this town hasn't moved
        placeKey(currentTown, state: currentState, zip: currentZip, condition: 0, condition2: 0, offset: 0)
        let latDist = key.coordinate.latitude - lastCoords.coordinate.latitude
        let longDist = key.coordinate.longitude - lastCoords.coordinate.longitude
        let distance = pow(pow(latDist, 2.0) + pow(longDist, 2.0),0.5)
        if distance < 1.00025 {
            self.mapLoadingCircle.startAnimating()
            //self.mapView.removeAnnotations(self.mapView.annotations)
            self.sendPushNotification()
            self.ref.child("towns/\(self.currentState)/\(self.currentTown)/\(self.currentTown)0/ruler/picID").setValue(self.facebookID)
            self.ref.child("towns/\(self.currentState)/\(self.currentTown)/\(self.currentTown)0/ruler/pushID").setValue(self.userPushID)
            self.ref.child("towns/\(self.currentState)/\(self.currentTown)/\(self.currentTown)0/ruler/king").setValue(self.name)
            let alert = UIAlertController(title: "Key!", message:"Enter the new town motto (100 character limit):", preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler(configurationTextField)
            let action = UIAlertAction(title: "OK", style: .Default) { _ in
                var message = alert.textFields![0].text!
                if message.characters.count > 100 {
                    message = message.substringToIndex(message.startIndex.advancedBy(99)) + "..."
                }
                self.ref.child("towns/\(self.currentState)/\(self.currentTown)/\(self.currentTown)0/ruler/motto").setValue("\(message)")
                self.townMotto.text = message
                self.kingProfPic.image = self.getProfPic(self.facebookID)
                self.kingName.text = self.name
            }
            alert.addAction(action)
            self.presentViewController(alert, animated: true){}
            
            if user?.anonymous == false {
            
            //let userID = FIRAuth.auth()?.currentUser?.uid
            let userID = self.facebookID
            ref.child("users").child(userID).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                // Get user value
                let oldTowns = snapshot.value!["towns"] as! [String]
                //print(oldTowns)
                let townArray = ["\(self.currentTown), \(self.currentState)"]
                if !oldTowns.contains(townArray[0]) {
                    let towns = oldTowns + townArray
                    self.townList += townArray
                    self.ref.child("users/\(self.facebookID)/towns").setValue(towns)
                }
            }) { (error) in
                print(error.localizedDescription)
            }
            
        }
        
            let rand = arc4random_uniform(UInt32(10000))
            self.ref.child("towns").child(self.currentState).child(self.currentTown).child("\(self.currentTown)\(currentIndex)/index").setValue(Int(rand))
            print("placing key")
            placeKey(currentTown, state: currentState, zip: currentZip, condition: 0, condition2: 0, offset: 0)
        }
    }
    
    
    @IBAction func requestKeyReportPressed(sender: AnyObject) {
        /*if user?.anonymous == true {
            nonGuestFeature(0)
            return
        }*/
        if keyRequestButton.titleLabel?.text == "Request Key" {
            keyRequest()
        } else if keyRequestButton.titleLabel?.text == "Report" {
            let refreshAlert = UIAlertController(title: "Report", message: "Report this user's content?", preferredStyle: UIAlertControllerStyle.Alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
                let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .ShortStyle)
                self.ref.child("contentReports/\(timestamp)").setValue("\(self.currentTown), \(self.currentState). User \(self.kingName.text!) said \(self.townMotto.text!)")
                let verify = UIAlertController(title: "Thank you!", message:"Your report has been sent and will be reviewed.", preferredStyle: .Alert)
                
                let action = UIAlertAction(title: "OK", style: .Default) { _ in
                }
                verify.addAction(action)
                self.presentViewController(verify, animated: true){}
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in
            }))
            
            presentViewController(refreshAlert, animated: true, completion: nil)
        }
    }
    
    func configurationTextField(textField: UITextField!)
    {
        if textField != nil {
            textField.text = ""
        }
    }
    
    func sendPushNotification() {
        if self.currentPushID != "-1" && self.userPushID != self.currentPushID && self.currentPushID != "nil" {
            OneSignal.defaultClient().postNotification(["contents": ["en": "\(self.name) has taken \(self.currentTown)! Log in and get the key to take it back!"], "include_player_ids": [self.currentPushID]])
        }
    }
    
    @IBAction func UpdateButtonPress(sender: AnyObject) {
        updateButton.hidden = true
        self.timer = 5
        self.mapLoadingCircle.startAnimating()
        let url = "http://nominatim.openstreetmap.org/reverse"
        let parameters = ["format" : "json", "lat" : "\(lastCoords.coordinate.latitude)", "lon" : "\(lastCoords.coordinate.longitude)"]

        Alamofire.request(.GET, url, parameters: parameters)
            .responseJSON { response in
                if let lol = response.result.value {
                    //print("JSON: \(lol)")
                    let json = JSON(lol)
                    self.currentZip = "\(json["address"]["postcode"])"
                    self.currentState = "\(json["address"]["state"])"
                    //do a callback beginning thing here?
                    self.largestTown(json){ (resultString: String) in
                        print(resultString)
                        self.currentTown = resultString.stringByReplacingOccurrencesOfString(".", withString: "")
                        self.townLabel.text = "\(self.currentTown), \(self.currentState)"
                        //print(self.townLabel.text!)
                        self.placeKey(self.currentTown, state: self.currentState, zip: self.currentZip, condition: 0, condition2: 0, offset: 0)
                    }
                }
                
        }
    }
    
    func largestTown(json:JSON, callback: (result: String) ->()) {
        
        /*print(json["address"]["village"])
        print(json["address"]["town"])
        print(json["address"]["city"])
        print(json["address"]["borough"])
        print(json["address"]["hamlet"])
        print(json["address"]["locality"])*/
        
        let nominatimTry = nominatimResult(json)
        let pathTry = self.currentState + "/" + nominatimTry + "0.txt"
        
        // Create reference to the file whose metadata we want to retrieve
        let pathRef = storageRef.child(pathTry)
        // Get metadata properties
        pathRef.metadataWithCompletion { (metadata, error) -> Void in
            if (error != nil) {
                let parameters = ["latlng" : "\(self.lastCoords.coordinate.latitude),\(self.lastCoords.coordinate.longitude)"]
                let url = "https://maps.googleapis.com/maps/api/geocode/json"
                
                Alamofire.request(.GET, url, parameters: parameters)
                    .responseJSON { response in
                        if let lol = response.result.value {
                            //print(response.request)  // original URL request
                            //print("JSON: \(lol)")
                            let json = JSON(lol)
                            //print(json)
                            var resultIndex = 0
                            var componentIndex = 0
                            while(json["results"][resultIndex] != nil) {
                                while(json["results"][resultIndex]["address_components"][componentIndex] != nil) {
                                    if ("\(json["results"][resultIndex]["address_components"][componentIndex]["types"])".containsString("locality")) {
                                        //print("woo hoo! \(json["results"][resultIndex]["address_components"][componentIndex]["long_name"])")
                                        callback(result: "\(json["results"][resultIndex]["address_components"][componentIndex]["long_name"])")
                                    }
                                    componentIndex += 1
                                    
                                }
                                resultIndex += 1
                            }
                            
                        }
                }
            } else {
                callback(result: nominatimTry)
            }
        }
    }
    
    func nominatimResult(json: JSON) -> String {
        if json["address"]["village"] == nil {
            if json["address"]["town"] == nil {
                if json["address"]["city"] == nil {
                    if json["address"]["borough"] == nil {
                        if json["address"]["hamlet"] == nil {
                            if json["address"]["locality"] == nil {
                                return "???"
                            }
                            return "\(json["address"]["locality"])"
                        }
                        return "\(json["address"]["hamlet"])"
                    }
                    return "\(json["address"]["borough"])"
                }
                return "\(json["address"]["city"])"
            }
            return "\(json["address"]["town"])"
        }
        return "\(json["address"]["village"])"
    }
    
    func placeKey(town:String, state:String, zip:String, condition: Int, condition2: Int, offset: Int) {
        self.placeKeyTest(town, state: state, zip: zip, state1: condition, state2: condition2, offset: offset){ (finalState :Int?, finalState2 :Int?, off: Int?) in
            if(finalState != -1) {
                self.placeKey(town, state: state, zip: zip, condition: finalState!, condition2: finalState2!, offset: off!)
            }
        }
    }
    
    func placeKeyTest(town: String, state: String, zip: String, state1: Int, state2: Int, offset: Int, callback: (id:Int?, id2: Int?, off:Int) ->()) -> () {
            let validStreet = true
            var index = state1
        
            //index2 and newFoldercreated are from the old zip code tests. Keep them for now just in case
        
            //var index2 = state2
            var streetPath = ""
            var dayMod = 0
            //var newFolderCreated = false
        
            ref.child("towns").child(state).child(town).child("\(town)\(index)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            // Get user value
                let possiblePath = snapshot.value!["streets"] as? String
                if possiblePath == nil {
                    print("danger: not a town in the database")
                    let returns = self.setupTownInDB(town, state: state, condition1: state1, condition2: state2)
                    streetPath = "\(state)/\(returns[0])"
                    index = Int(returns[1])!
                    //index2 = 0
                    //newFolderCreated = true
                } else {
                    streetPath = "\(state)/\(snapshot.value!["streets"] as! String)"
                    index = snapshot.value!["index"] as! Int
                    let rulerInfo = snapshot.value!["ruler"]!!["king"] as! String
                    self.kingName.text = rulerInfo
                    let townMotto = snapshot.value!["ruler"]!!["motto"] as! String
                    self.townMotto.text = townMotto
                    let facebookID = snapshot.value!["ruler"]!!["picID"] as! String
                    self.kingProfPic.image = self.getProfPic(facebookID)
                    print("\(facebookID), \(self.facebookID)")
                    if facebookID == self.facebookID {
                        self.ref.child("towns/\(state)/\(town)/\(town)\(state1)/ruler/pushID").setValue(self.userPushID)
                        self.currentPushID = self.userPushID
                    } else {
                        self.currentPushID = "\(snapshot.value!["ruler"]!!["pushID"] as! String)"
                    }
                
                }
                // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                let streetRef = self.storageRef.child("\(streetPath)")
                streetRef.dataWithMaxSize(3 * 1024 * 1024) { (data, error) -> Void in
                    if (error != nil) {
                        print(error!.localizedDescription)
                        self.keyRequestButton.setTitle("Request Key", forState: UIControlState.Normal)
                        self.mapLoadingCircle.stopAnimating()
                        self.mapView.removeAnnotations(self.mapView.annotations)
                    } else {
                        self.keyRequestButton.setTitle("Report", forState: UIControlState.Normal)
                        // Data for streets its returned
                        let streetFile: NSString! = NSString(data: data!, encoding: NSUTF8StringEncoding)
                        let streetList = streetFile!.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                        //here test the zip codes
                        //print("\(streetList)")
                        //zipcode test for duplicates, more trouble than its worth
                        //let zips = streetList[0].componentsSeparatedByString("|")
                        /*if !self.zipcodeTest(zips, currentZip: zip) && streetList[0] != " " {
                            if newFolderCreated {
                                callback(id: state1, id2: index2 + 1, off: offset)
                                return
                            } else {
                                callback(id: state1 + 1, id2: index2, off: offset)
                                return
                            }
                        }*/
                        Alamofire.request(.GET, "http://www.timeapi.org/est/now.json")
                            .responseJSON { response in
                                if let lol = response.result.value {
                                    let json = JSON(lol)
                                    //print(json)
                                    if !self.mapLoadingCircle.isAnimating() {
                                        return
                                    }
                                    let date = "\(json["dateString"])"
                                    dayMod = 0
                                    for char in date.characters {
                                        var toAdd = 0
                                        let sChar = "\(char)"
                                        if sChar == "T" {
                                            break
                                        } else if sChar == "-" {
                                            toAdd = 0
                                        } else {
                                            toAdd = Int(sChar)!
                                            dayMod += toAdd
                                        }
                                    }
                                    var randGen = ((dayMod * index) + offset) % streetList.count
                                    if randGen == 0 {
                                        randGen = 1
                                    }
                                    if streetList[randGen] == "" {
                                        randGen += 1
                                        randGen % streetList.count
                                        if randGen == 0 {
                                            randGen = 1
                                        }
                                        else if randGen == streetList.count {
                                            randGen -= 3
                                        }
                                        if randGen <= 0 {
                                            randGen = 1
                                        }
                                    }
                                    print("\(streetList[randGen]) \(town) \(state)")
                                    if "\(streetList[randGen]) \(town) \(state)" == self.requestLast {
                                        print("call ignored")
                                        self.mapLoadingCircle.stopAnimating()
                                        return
                                        //Keep the key in the same exact spot. Don't waste API calls.
                                    } else {
                                        self.requestLast = "\(streetList[randGen]) \(town) \(state)"
                                        //Update the latest one and let it go through
                                    }
                                    let url = "https://maps.googleapis.com/maps/api/geocode/json"
                                    let parameters = ["address" : "\(streetList[randGen]) \(town) \(state)"]
                                    Alamofire.request(.GET, url, parameters: parameters)
                                        .responseJSON { response in
                                            if let lol = response.result.value {
                                                let json = JSON(lol)
                                                let result = 0
                                                //TODO test for valid street?
                                                if validStreet {
                                                    let latitude = "\(json["results"][result]["geometry"]["location"]["lat"])"
                                                    let longitude = "\(json["results"][result]["geometry"]["location"]["lng"])"
                                                    if latitude != "null" && longitude != "null" {
                                                        let keyCoords = CLLocationCoordinate2D(latitude: Double(latitude)!, longitude: Double(longitude)!)
                                                        self.mapView.removeAnnotation(self.key)
                                                        self.key = MKPointAnnotation()
                                                        self.key.coordinate = keyCoords
                                                        self.mapView.addAnnotation(self.key)
                                                        callback(id: -1, id2: 0, off: offset)
                                                        print("success")
                                                        self.mapLoadingCircle.stopAnimating()
                                                    }
                                                }
                                            }
                                    }

                                }
                        }
                        
                    }
                }
            }) { (error) in
                print(error.localizedDescription)
            }

    }
    
    func setupTownInDB(town: String, state: String, condition1: Int, condition2: Int) -> [String] {
        let rand = Int(arc4random_uniform(UInt32(10000)))
        let returnArr = ["\(town)\(condition2).txt", "\(rand)"]
        self.ref.child("towns/\(state)/\(town)/\(town)\(condition1)/streets").setValue("\(town)\(condition2).txt")
        self.ref.child("towns/\(state)/\(town)/\(town)\(condition1)/index").setValue(rand)
        self.ref.child("towns/\(state)/\(town)/\(town)\(condition1)/ruler/king").setValue("Unclaimed")
        self.kingName.text = "Unclaimed"
        self.ref.child("towns/\(state)/\(town)/\(town)\(condition1)/ruler/motto").setValue("Welcome to \(town)!")
        self.townMotto.text = "Welcome to \(town)!"
        self.ref.child("towns/\(state)/\(town)/\(town)\(condition1)/ruler/picID").setValue("-1")
        self.ref.child("towns/\(state)/\(town)/\(town)\(condition1)/ruler/pushID").setValue("-1")
        self.currentPushID = "-1"
        self.kingProfPic.image = self.getProfPic("-1")
        return returnArr
    }
    
    func zipcodeTest(zipList: [String], currentZip: String) -> Bool {
        var result = false
        for zip in zipList {
            if currentZip.rangeOfString(zip) != nil
            {
                result = true
                break
            }
        }
        return result
    }
    
    func keyRequest() {
        let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        self.ref.child("townRequests/\(self.currentState)/\(timestamp)").setValue("\(self.currentTown), \(self.currentState)") //TEST THIS?
        let verify = UIAlertController(title: "Thank you!", message:"Your request has been submitted and we'll get to it as soon as we can.", preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "OK", style: .Default) { _ in
        }
        verify.addAction(action)
        self.presentViewController(verify, animated: true){}
        
    }
    
    func nonGuestFeature(num: Int) {
        var message = "This feature is disabled on guest accounts. Sign in for free to use this feature and other locked features!"
        if num == 1 {
            message = "This feature is disabled on guest accounts. Sign in for free to become king of this town right now!"
        }
        let alert = UIAlertController(title: "Log in to access this feature!", message: message, preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "OK", style: .Default) { _ in
        }
        alert.addAction(action)
        self.presentViewController(alert, animated: true){}
    }
    
    @IBAction func scoreButtonPressed(sender: AnyObject) {

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if let ident = identifier {
            if ident == "segueTest" {
                if user?.anonymous == true {
                    nonGuestFeature(0)
                    return false
                }
            }
        }
        return true
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "segueTest") {
            let svc = segue.destinationViewController as! TownListViewController;
            //town, state, zip, ruler, motto, pictureID, keycoords
            
            self.townList[0] = facebookID
            svc.toPass = self.townList
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if timer > 0 {
            timer -= 1
        } else if timer == 0 && updateButton.hidden {
            updateButton.hidden = false
        }
        let location = locations.last
        lastCoords = location!
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let latDist = key.coordinate.latitude - lastCoords.coordinate.latitude
        let longDist = key.coordinate.longitude - lastCoords.coordinate.longitude
        let distance = pow(pow(latDist, 2.0) + pow(longDist, 2.0),0.5)
        //print(distance)
        if distance < 0.00025 {
            getKeyButton.hidden = false
        } else {
            getKeyButton.hidden = true
        }
        if first {
            let region = MKCoordinateRegionMake(center, MKCoordinateSpan (latitudeDelta: 0.02, longitudeDelta: 0.02))
            self.mapView.setRegion(region, animated: true)
            let url = "http://nominatim.openstreetmap.org/reverse"
            let parameters = ["format" : "json", "lat" : "\(lastCoords.coordinate.latitude)", "lon" : "\(lastCoords.coordinate.longitude)"]
            
            Alamofire.request(.GET, url, parameters: parameters)
                .responseJSON { response in
                    if let lol = response.result.value {
                        //print("JSON: \(lol)")
                        let json = JSON(lol)
                        self.currentZip = "\(json["address"]["postcode"])"
                        self.currentState = "\(json["address"]["state"])"
                        self.largestTown(json){ (resultString: String) in
                            //print(resultString)
                            self.currentTown = resultString.stringByReplacingOccurrencesOfString(".", withString: "")
                            self.townLabel.text = "\(self.currentTown), \(self.currentState)"
                            //print(self.townLabel.text!)
                            self.placeKey(self.currentTown, state: self.currentState, zip: self.currentZip, condition: 0, condition2: 0, offset: 0)
                        }
                    }
                    
            }
            first = false
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("boo " + error.localizedDescription)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("---")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "---")
            annotationView!.canShowCallout = false
        }
        else {
            annotationView!.annotation = annotation
        }
        
        annotationView!.image = UIImage(named: "keyEmoji")
        
        return annotationView
        
    }
    
    
}