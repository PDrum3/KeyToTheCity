//
//  TownListViewController.swift
//  MapKitTry
//
//  Created by Ryan Drum on 6/14/16.
//  Copyright © 2016 pdrum. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase
import GameKit

class TownListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GKGameCenterControllerDelegate {
    
    //Game center
    var myEnabled = Bool()
    var myDefaultLeaderBoard = String()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var TopBar: UINavigationBar!
    @IBOutlet weak var townLoader: UIActivityIndicatorView!
    
    let ref = FIRDatabase.database().reference()
    let user = FIRAuth.auth()?.currentUser
    var toPass:[String]!
    var parseList:[String]! = []
    var facebookID = ""
    var score = 0
    var score2 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        facebookID = self.toPass.removeAtIndex(0)
        //print(toPass)
        setupArray()
        self.authenticateLocalPlayer()
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        if localPlayer.authenticated {
            self.showHighScore()
        }
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func setupArray() {
        for i in 0..<toPass.count {
            parseList = self.toPass[i].componentsSeparatedByString(", ")
            
            ref.child("towns").child(parseList[1]).child(parseList[0]).child("\(parseList[0])0").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                let snap = snapshot.value as! [String:AnyObject]
                let ruler = snap["ruler"] as! [String:AnyObject]
                let facebookIDtown = ruler["picID"] as! String
                //print(facebookIDtown)
                if facebookIDtown == self.facebookID {
                    self.toPass[i] = "👑\(self.toPass[i])"
                    self.score += 1
                    self.score2 += 1
                } else {
                    self.toPass[i] = "\(self.toPass[i])"
                    self.score2 += 1
                }
                if i == self.toPass.count - 1 {
                    self.townLoader.stopAnimating()
                }
                self.TopBar.topItem?.title = "\(self.score):\(self.score2)"
                self.tableView.reloadData()
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        if toPass.count == 0 {
            self.townLoader.stopAnimating()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.toPass.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        parseList = self.toPass[indexPath.row].componentsSeparatedByString(", ")
        cell.textLabel?.text = self.toPass[indexPath.row]
        
        cell.textLabel
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    
    //Game center stuff
    func showHighScore() {
        let myScore =  self.score
        let leaderboardID = "TownKeysLeaderboard1030"
        let sScore = GKScore(leaderboardIdentifier: leaderboardID)
        sScore.value = Int64(myScore)
        
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticated
        
        GKScore.reportScores([sScore], withCompletionHandler: { (error: NSError?) -> Void in
            if error != nil {
                print(error!)
            } else {
                print("score submitted")
            }
        })
        
        let myScore2 =  self.score2
        let leaderboardID2 = "TownKeysLeaderboard1031"
        let sScore2 = GKScore(leaderboardIdentifier: leaderboardID2)
        sScore2.value = Int64(myScore2)
        
        let localPlayer2: GKLocalPlayer = GKLocalPlayer.localPlayer()
        localPlayer2.authenticated
        
        GKScore.reportScores([sScore2], withCompletionHandler: { (error: NSError?) -> Void in
            if error != nil {
                print(error!)
            } else {
                print("score submitted")
            }
        })
    }
    
    @IBAction func showGameCenter(sender: AnyObject) {
        self.showHighScore()
        let gcVC: GKGameCenterViewController = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = GKGameCenterViewControllerState.Leaderboards
        gcVC.leaderboardIdentifier = "TownKeysLeaderboard1030"
        self.presentViewController(gcVC, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {(ViewController : UIViewController?, error : NSError?) -> Void in
            if((ViewController) != nil) {
                self.presentViewController(ViewController!, animated: true, completion: nil)
            } else if(localPlayer.authenticated) {
                self.myEnabled = true
                localPlayer.loadDefaultLeaderboardIdentifierWithCompletionHandler({(leaderboardIdentifier: String?, error: NSError?) -> Void in
                self.showHighScore()
                    if error != nil {
                        print(error)
                    } else {
                        self.myDefaultLeaderBoard = leaderboardIdentifier!
                    }
                })
            } else {
                self.myEnabled = false
                print("error with game center!")
            }
        }
    }
    
    //end of game center stuff
    
    
    @IBAction func MapButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {});
        self.dismissViewControllerAnimated(true, completion: {});
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    
}