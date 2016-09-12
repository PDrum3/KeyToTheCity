//
//  SettingsViewController.swift
//  MapKitTry
//
//  Created by Ryan Drum on 6/23/16.
//  Copyright © 2016 pdrum. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit

class SettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func mapPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {});
    }
    
    @IBAction func logOutPressed(sender: AnyObject) {
        if FIRAuth.auth()?.currentUser?.anonymous == true {
            print("deleting temp account")
            FIRAuth.auth()?.currentUser?.deleteWithCompletion(nil)
        } else {
            print("logging out")
            try! FIRAuth.auth()!.signOut()
            FBSDKLoginManager().logOut()
        }
        
        self.view.window!.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func CreditsPressed(sender: AnyObject) {
        let verify = UIAlertController(title: "Credits", message:"Thanks to the APIs that help gather map data (Nominatim of OpenStreetMap, Google Maps Geocoding API) and user data (Facebook API). Thanks also to the plugins used to receive and parse this data (Alamofire and SwiftyJSON) and Firebase for storing this data. Lastly, thank you for downloading this app!", preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "OK", style: .Default) { _ in
        }
        verify.addAction(action)
        self.presentViewController(verify, animated: true){}
    }
    
    
}
