//
//  FriendTownListController.swift
//  MapKitTry
//
//  Created by Ryan Drum on 7/16/16.
//  Copyright © 2016 pdrum. All rights reserved.
//

import Foundation
import UIKit
import FBSDKCoreKit
//import FirebaseAuth
import FirebaseDatabase

class FriendTownListController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let ref = FIRDatabase.database().reference()
    var townList:[String] = []
    var parseList:[String]! = []
    var friendID = ""
    var friendName = ""
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topBar: UINavigationBar!
    @IBOutlet weak var friendLoader: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.topBar.topItem?.title = "\(friendName)'s Towns"
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        getFriendTownList()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getFriendTownList() {
        self.ref.child("users").child(self.friendID).observeSingleEventOfType(.Value, withBlock: { (snapshot) in

        self.townList = snapshot.value!["towns"] as! [String]
        self.townList.removeFirst() //remove "empty"
        self.setupArray()
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func setupArray() {
        for i in 0..<townList.count {
            parseList = self.townList[i].componentsSeparatedByString(", ")
            
            ref.child("towns").child(parseList[1]).child(parseList[0]).child("\(parseList[0])0").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                let snap = snapshot.value as! [String:AnyObject]
                let ruler = snap["ruler"] as! [String:AnyObject]
                let facebookIDtown = ruler["picID"] as! String
                //print(facebookIDtown)
                if facebookIDtown == self.friendID {
                    self.townList[i] = "👑\(self.townList[i])"
                } else {
                    self.townList[i] = "\(self.townList[i])"
                }
                self.tableView.reloadData()
                if i  == self.townList.count - 1 {
                    self.friendLoader.stopAnimating()
                }
            }) { (error) in
                print(error.localizedDescription)
            }
            
        }
        if townList.count == 0 {
            self.friendLoader.stopAnimating()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return townList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        cell.textLabel?.text = townList[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {});
    }
    
}
