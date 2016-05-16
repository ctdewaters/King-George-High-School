//
//  StaffDetailViewController.swift
//  KGHS
//
//  Created by Collin DeWaters on 2/19/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import UIKit
import MessageUI
import CoreData
import SafariServices


class StaffDetailViewController: UIViewController, MFMailComposeViewControllerDelegate, UIViewControllerPreviewingDelegate, SFSafariViewControllerDelegate {
    
    //Detail Variables
    var name = String()
    var departmentChair = Bool()
    var department = String()
    var affiliation = String()
    var email = String()
    var webpage = String()
    var isFavorited: Bool!
    var favoriteButton: UIButton!
    
    var previewVC: UIViewController!
    
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var webpageButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var departmentLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: webpageButton.superview!)
                
            }
        }
        
        nameLabel.text = name
        if affiliation != ""{
            departmentLabel.text = "\(department) - \(affiliation)"
        }
        else{
            departmentLabel.text = department
        }
        
        //Check if staff member has a webpage
        if webpage == "None" || webpage == ""{
            webpageButton.alpha = 0.3
        }
        
        print(isFavorited)
        
        //Set the title label for the navbar
        favoriteButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
        favoriteButton.imageView?.contentMode = .ScaleAspectFit
        if isFavorited == true{
            favoriteButton.setImage(UIImage(named: "favoriteFilled")!, forState: .Normal)
        }
        else{
            favoriteButton.setImage(UIImage(named: "favoriteEmpty")!, forState: .Normal)
        }
        favoriteButton.addTarget(self, action: #selector(StaffDetailViewController.addToFavorites), forControlEvents: .TouchUpInside)
        self.navigationItem.titleView = favoriteButton
        
        
        //set up webpage button
        webpageButton.layer.cornerRadius = 95 / 2
        webpageButton.clipsToBounds = true
        webpageButton.backgroundColor = UIColor(rgba: "#00335b")
        
        emailButton.backgroundColor = UIColor(rgba: "#00335b")
        emailButton.layer.cornerRadius = 95 / 2
        emailButton.clipsToBounds = true
        
        nameLabel.textColor = UIColor(rgba: "#00335b")
        departmentLabel.textColor = UIColor(rgba: "#00335b").colorWithAlphaComponent(0.75)
        
        
        let backgroundImageView = UIImageView(frame: self.view.frame)
        backgroundImageView.image = UIImage(named: "front")!
        backgroundImageView.contentMode = .ScaleAspectFill
        self.view.addSubview(backgroundImageView)
        self.view.sendSubviewToBack(backgroundImageView)
        backgroundImageView.addBlur(.ExtraLight)
        backgroundImageView.clipsToBounds = true
        
        self.view.clipsToBounds = true
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
    }
    
    func setUpParallax(object: UIView, value: Int){
        //Parallax Effect
        
        // Set vertical effect
        let verticalMotionEffect : UIInterpolatingMotionEffect =
        UIInterpolatingMotionEffect(keyPath: "center.y",
            type: .TiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -value
        verticalMotionEffect.maximumRelativeValue = value
        
        // Set horizontal effect
        let horizontalMotionEffect : UIInterpolatingMotionEffect =
        UIInterpolatingMotionEffect(keyPath: "center.x",
            type: .TiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -value
        horizontalMotionEffect.maximumRelativeValue = value
        
        let group : UIMotionEffectGroup = UIMotionEffectGroup()
        group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        object.addMotionEffect(group)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Open staff member's webpage
    @IBAction func goToWebpage(sender: UIButton) {
        
        if webpage != "None" && webpage != "" {
            if #available(iOS 9.0, *) {
                let staffVC = SFSafariViewController(URL: NSURL(string: self.webpage)!)
                staffVC.delegate = self
                self.presentViewController(staffVC, animated: true, completion: {
                    UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default
                })
            } else {
                // Fallback on earlier versions
                self.performSegueWithIdentifier("showWebPage", sender: self)
            }

        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! StaffPageViewController
        vc.url = webpage
        vc.name = name
    }
    
    @IBAction func emailStaffMember(sender: UIButton) {
        let mailVC = setUpEmailComposeController()
        if MFMailComposeViewController.canSendMail(){
            //Present the user with a prefilled email
            self.presentViewController(mailVC, animated: true, completion: nil)
        }
        else{
            //Problem, show alertview
            mailErrorAlert()
        }
    }
    
    func addToFavorites(){
        if isFavorited == false{
            dataManager.saveObjectInEntity("FavoritedStaff", objects: [name, department, affiliation, email, webpage, departmentChair], keys: ["name", "department", "affiliation", "email", "webpage", "departmentChair"], deletePrevious: false)
            isFavorited = true
            complexAnimationForDuration(0.15, delay: 0, animation1: {
                self.favoriteButton.alpha = 0
                }, animation2: {
                    self.favoriteButton.setImage(UIImage(named: "favoriteFilled")!, forState: .Normal)
                    self.favoriteButton.alpha = 1
            })
        }
        else{
            dataManager.deleteObjectInEntity("FavoritedStaff", object: name, key: "name")
            isFavorited = false
            complexAnimationForDuration(0.15, delay: 0, animation1: {
                self.favoriteButton.alpha = 0
                }, animation2: {
                    self.favoriteButton.setImage(UIImage(named: "favoriteEmpty")!, forState: .Normal)
                    self.favoriteButton.alpha = 1
            })
        }
    }
    
    //Set up the compose VC
    func setUpEmailComposeController() -> MFMailComposeViewController{
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        mailVC.navigationBar.barTintColor = .whiteColor()
        mailVC.setToRecipients([email])//Email sent to this contact
        mailVC.setSubject("Email From the KGHS iOS App")//Email Subject
        mailVC.setMessageBody("Hello \(name), ", isHTML: false)//Initial body of the email
        return mailVC
    }
    
    //Runs when user cannot send email
    func mailErrorAlert(){
        let sendMailErrorAlert = UIAlertView(title: "Unable To Send Email", message: "Email seems to not be working properly. Check your email settings and try again.", delegate: self, cancelButtonTitle: "Ok")//Messages for alertview
        sendMailErrorAlert.show()
    }
    
    //Mail compose delegate
    //Close mailcomposeviewcontroller
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?){
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Animate Favorite Icon
    func complexAnimationForDuration(duration: NSTimeInterval, delay: NSTimeInterval, animation1: (() ->Void), animation2: (() ->Void)){
        UIView.animateWithDuration(duration, delay: delay, options: [], animations: {
            ()->Void in
            animation1()
            }, completion: {
                Bool in
                if true{
                    UIView.beginAnimations(nil, context: nil)
                    UIView.setAnimationDuration(duration)
                    animation2()
                    UIView.commitAnimations()
                }
        })
    }

    //UIViewControllerPreviewingDelegate
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if #available(iOS 9.0, *) {
            
            if webpage != "None" && webpage != "" && webpageButton.frame.contains(location){
                let webVC = SFSafariViewController(URL: NSURL(string: webpage)!)
                webVC.delegate = self
                previewVC = webVC
                previewingContext.sourceRect = webpageButton.frame
                return previewVC
            }
            
        }
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        if #available(iOS 9.0, *) {
            presentViewController(previewVC as! SFSafariViewController, animated: false, completion: nil)
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 9.0, *)
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(false, completion: nil)
    }

}

extension UIImageView {
    func addBlur(style: UIBlurEffectStyle) {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: style))
        blur.frame = self.frame
        self.addSubview(blur)
    }
}
