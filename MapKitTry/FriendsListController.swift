//
//  FriendsListController.swift
//  MapKitTry
//
//  Created by Ryan Drum on 7/16/16.
//  Copyright © 2016 pdrum. All rights reserved.
//

import Foundation
import UIKit
import FBSDKCoreKit
import SwiftyJSON

class FriendsListController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var TopBar: UINavigationBar!
    @IBOutlet weak var friendLoader: UIActivityIndicatorView!
    var info : [String] = []
    var ids : [String] = []
    var names : [String] = []
    var profPics : [UIImage] = []
    var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        getFriends()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return info.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        cell.textLabel?.text = self.info[indexPath.row]
        cell.imageView?.image = self.profPics[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.index = indexPath.item
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.performSegueWithIdentifier("FriendTowns", sender: nil)
    }
    
    func getFriends() {
        let parameters = ["fields": "friends"]
        FBSDKGraphRequest(graphPath: "me", parameters: parameters).startWithCompletionHandler {(connection, result, error) -> Void in
            let data = JSON(result)
            //print(data)
            var index = 0
            while "\(data["friends"]["data"][index]["name"])" != "null" {
                self.info.append("\(data["friends"]["data"][index]["name"])")
                self.ids.append("\(data["friends"]["data"][index]["id"])")
                self.profPics.append(self.getProfPic(self.ids[index])!)
                let parseData = self.info[index].componentsSeparatedByString(" ")
                self.names.append(parseData[0])
                index += 1
            }
            self.friendLoader.stopAnimating()
            self.tableView.reloadData()
        }
    }
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {});
    }
    
    func getProfPic(fid: String) -> UIImage? {
        if (fid != "" && fid != "-1") {
            let imgURLString = "http://graph.facebook.com/" + fid + "/picture?height=100&width=100"
            let imgURL = NSURL(string: imgURLString)
            let imageData = NSData(contentsOfURL: imgURL!)
            let image = UIImage(data: imageData!)
            return image
        } else if (fid == "-1") {
            let image = UIImage(named: "profileDefault.png")
            return image
        }
        return nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "FriendTowns") {
            let svc = segue.destinationViewController as! FriendTownListController;
            //town, state, zip, ruler, motto, pictureID, keycoords
            svc.friendID = ids[self.index]
            svc.friendName = names[self.index]
        }
    }
    

}