//
//  LoginViewController.swift
//  MapKitTry
//
//  Created by Ryan Drum on 5/23/16.
//  Copyright © 2016 pdrum. All rights reserved.
//
import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, UIAlertViewDelegate, FBSDKLoginButtonDelegate {
    
    let ref = FIRDatabase.database().reference()
    var uid = ""
    var quickLogin = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        
        loginButton.frame=CGRectMake(0,0,200,50);
        loginButton.center = self.view.center
        loginButton.delegate = self
        self.view.addSubview(loginButton)
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)        
    }
    
    override func viewDidAppear(animated: Bool) {
        if FIRAuth.auth()?.currentUser != nil && FBSDKAccessToken.currentAccessToken() != nil && quickLogin {
            print("transitioning")
            self.performSegueWithIdentifier("login", sender: nil)
        }
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        quickLogin = false
        if error == nil && result.isCancelled == false {
            print("login good")
            let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
            FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                if error != nil {
                    if error!.localizedDescription == "The email address is already in use by another account." {
                        print("that was hard!")
                        //**Something that says this email is already in use
                        return
                    } else {
                        print("user created")
                        //self.uid = user!.uid OLD STUFF
                        //print("aaa")
                        //self.ref.child("users/\(user!.uid)/score").setValue(0)
                        //self.ref.child("users/\(user!.uid)/towns/0").setValue("empty")
                        self.performSegueWithIdentifier("login", sender: nil)
                    }
                } else {
                    print("login success")
                    self.performSegueWithIdentifier("login", sender: nil)
                }
            }
        } else {
            print("login fail")
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("user logged out")
    }
    
    
    @IBAction func guestLogin(sender: AnyObject) {
        let refreshAlert = UIAlertController(title: "Continue as Guest", message: "Warning! As a guest your score will not be saved and you will not be notified when other people take your towns! Continue anyway?", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
            //Yes
            print("yes")
            FIRAuth.auth()?.signInAnonymouslyWithCompletion() { (user, error) in
                if error != nil {
                    print("error occurred")
                } else {
                    self.performSegueWithIdentifier("loginGuest", sender: nil)
                }
            }
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in
            //No
            print("no")
        }))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
    }
    
    /*
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        var username = ""
        if buttonIndex == 0 {
            // there is only one text field
            let textField = alertView.textFieldAtIndex(0)!
            username = textField.text!.capitalizedString
        } else {
            username = "Username"
        }
        self.ref!.child("users/\(uid)/username").setValue(username)
    }*/
    
}