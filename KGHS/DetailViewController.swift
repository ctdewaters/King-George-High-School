//
//  DetailViewController.swift
//  KGHS
//
//  Created by Collin DeWaters on 2/5/15.
//  Copyright (c) 2015 Collin DeWaters. All rights reserved.
//

import UIKit
import MessageUI
import Social
import EventKit
import CoreData

public var dataManager = DataManager()

class DetailViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var categoryImage: UIImageView!
    
    var date = NSDate()
    var eventTitle = String()
    var category = String()
    var subCategory = String()
    var image = UIImage()
    var desc: NSString?
    var allDay = Bool()
    var endDate: NSDate?
    let eventStore = EKEventStore()
    var actualPhone = NSString()
    
    var prefix: NSString?
    var name: NSString?
    var phone: NSString?
    var email: NSString?
    var next: NSString?
    var morePhone: NSString?
    var ext: NSString?
    
    var isFavorited: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundImageView = UIImageView(frame: self.view.frame)
        backgroundImageView.image = UIImage(named: "front")!
        backgroundImageView.contentMode = .ScaleAspectFill
        self.view.addSubview(backgroundImageView)
        self.view.sendSubviewToBack(backgroundImageView)
        backgroundImageView.addBlur(.ExtraLight)
        backgroundImageView.clipsToBounds = true
        
        self.view.clipsToBounds = true
        
        favoriteButton.imageView?.contentMode = .ScaleAspectFit
        
        phoneButton.clipsToBounds = true
        emailButton.clipsToBounds = true
        phoneButton.layer.cornerRadius = 70 / 2
        emailButton.layer.cornerRadius = 70 / 2
        emailButton.backgroundColor = UIColor(rgba: "#00335b")
        phoneButton.backgroundColor = UIColor(rgba: "#00335b")
        
        //Set category image for the selected event
        categoryImage.layer.cornerRadius = 40
        categoryImage.clipsToBounds = false
        categoryImage.contentMode = UIViewContentMode.ScaleAspectFit
        
        
        //Setting detail labels based on selected event
        titleLabel.text = eventTitle
        dateLabel.text = "\(convertEventDateToString(date))"
        if allDay == true{

            dateLabel.text = "\(convertEventDateToString(endDate!)), All Day"
        }
        else {
            dateLabel.text = "\(dateLabel.text!), \(convertEventTimeToString(date))"
        }
        dateLabel.textColor = UIColor(rgba: "#00335b").colorWithAlphaComponent(0.7)
        categoryImage.image = image
        
        //Check if user favorited this event
        isFavorited = coreDataContainsEventWithTitle(eventTitle)
        if isFavorited == true{
            favoriteButton.setImage(UIImage(named: "favoriteFilled")!, forState: .Normal)
        }
        print(isFavorited)
        
        print("\"\(desc)\"")
        
        descriptionText.textColor = UIColor(rgba: "#00335b")
        
        //Check if event has a description
        if desc != nil && desc != ""{
            if (desc!.lowercaseString.rangeOfString("contact", options: NSStringCompareOptions.LiteralSearch) != nil){
                getContactInformation()
            }
            else{
                //hide unneeded view
                emailButton.hidden = true
                phoneButton.hidden = true
            }
            descriptionText.text = desc as! String
            descriptionText.allowsEditingTextAttributes = false
            descriptionText.userInteractionEnabled = false
            changeDescriptionTextSize(descriptionText.text.characters.count)
        }
        else{
            //hide unneeded views
            descriptionText.hidden = true
            phoneButton.removeFromSuperview()
            emailButton.hidden = true
        }
        
    }
    
    func changeDescriptionTextSize(textCount: Int){
        print(textCount)
        
        if textCount > 800{
            descriptionText.font = UIFont.systemFontOfSize(9)
            
        }
        if textCount > 600 && textCount < 800{
            descriptionText.font = UIFont.systemFontOfSize(10)
        }
        if textCount > 400 && textCount < 600{
            descriptionText.font = UIFont.systemFontOfSize(12)
        }
        if textCount > 200 && textCount < 400{
            descriptionText.font = UIFont.systemFontOfSize(14)
        }
        if textCount < 200{
            descriptionText.font = UIFont.systemFontOfSize(16)
        }
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
    
    //Display date as string
    func convertEventDateToString(date: NSDate)->String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.FullStyle
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        let returnDate = dateFormatter.stringFromDate(date)
        return returnDate
    }
    
    //Display time as string
    func convertEventTimeToString(date: NSDate)->String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        let returnTime = dateFormatter.stringFromDate(date)
        return returnTime
    }
    
    //Runs if error occurs
    func alert(title: String, message: String) -> UIAlertController{
        let errorAlert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: { action->Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        errorAlert.addAction(cancelAction)
        return errorAlert
    }
    
    //Send email
    @IBAction func mail(sender: UIButton) {
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
    
    //Call Phone
    @IBAction func call(sender: UIButton) {
        if let url = NSURL(string: "tel://\(actualPhone)") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    //Email setup
    //Set up the compose VC
    func setUpEmailComposeController() -> MFMailComposeViewController{
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        
        let mail = email as! String
        
        mailVC.setToRecipients([mail])//Email sent to this contact
        mailVC.setSubject(eventTitle)//Email Subject
        mailVC.setMessageBody("Hello \(name!), ", isHTML: false)//Initial body of the email
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
    
    
    //Favoriting
    @IBAction func addToFavorites(sender: UIButton) {
        if isFavorited == false{
            //Check if description exists
            if desc != nil{
                dataManager.saveObjectInEntity("FavoritedEvents", objects: [eventTitle, category, subCategory, date, allDay, endDate!, desc!], keys: ["title", "category", "subcategory", "date", "allDay", "endDate", "desc"], deletePrevious: false)
            }
            else{
                dataManager.saveObjectInEntity("FavoritedEvents", objects: [eventTitle, category, subCategory, date, allDay, endDate!, ""], keys: ["title", "category", "subcategory", "date", "allDay", "endDate", "desc"], deletePrevious: false)
            }
            isFavorited = true
            complexAnimationForDuration(0.15, delay: 0, animation1: {
                self.favoriteButton.alpha = 0
                }, animation2: {
                    self.favoriteButton.setImage(UIImage(named: "favoriteFilled")!, forState: .Normal)
                    self.favoriteButton.alpha = 1
            })
        }
        else{
            dataManager.deleteObjectInEntity("FavoritedEvents", object: eventTitle, key: "title")
            isFavorited = false
            complexAnimationForDuration(0.15, delay: 0, animation1: {
                self.favoriteButton.alpha = 0
                }, animation2: {
                    self.favoriteButton.setImage(UIImage(named: "favoriteEmpty")!, forState: .Normal)
                    self.favoriteButton.alpha = 1
            })
        }
    }
    
    func coreDataContainsEventWithTitle(title: String)->Bool{
        let events = dataManager.loadObjectInEntity("FavoritedEvents") as! Array<NSManagedObject>
        let titles = NSMutableArray()
        
        for event in events{
            let title = event.valueForKey("title") as! String
            titles.addObject(title)
        }
        for arrayTitle in titles{
            if title == arrayTitle as! String{
                return true
            }
        }
        return false
    }
    
    
    //Scanning out the contact information from the event's description
    func getContactInformation(){
        var strin: NSString?
        var scanner = NSScanner(string: desc! as String)
        print(desc)
        
        if desc?.rangeOfString("Phone:", options: NSStringCompareOptions.LiteralSearch) != nil {
           scanPhoneFromDescription()
        }
        if desc?.rangeOfString("Email:", options: NSStringCompareOptions.LiteralSearch) != nil {
            scanEmailFromDescription()
        }
        if desc?.rangeOfString("Contact:", options: NSStringCompareOptions.LiteralSearch) != nil {
            scanNameFromDescription()
            let scanner = NSScanner(string: desc as! String)
            var str: NSString?
            scanner.scanUpToString("Contact: ", intoString: &str)
            scanner.scanUpToString("\n", intoString: &str)
            
            desc = desc?.stringByReplacingOccurrencesOfString("\(str!)", withString: "")
        }
        if email == nil{
            emailButton.alpha = 0.3
        }
        if phone == nil {
            phoneButton.alpha = 0.3
        }
        if phone == nil && name == nil && email == nil {
        }
    }
    
    func scanNameFromDescription() {
        let scanner = NSScanner(string: desc as! String)
        var str: NSString?
        scanner.scanUpToString("Contact: ", intoString: nil)
        scanner.scanUpToString(" ", intoString: nil)
        scanner.scanUpToString(" ", intoString: &name)
        scanner.scanUpToString(" ", intoString: &str)
        if str != "Email:" && str != "Phone:" {
            name = "\(name!) \(str!)"
            print(name!)
            scanner.scanUpToString(" ", intoString: &str)
            if str != "Email:" && str != "Phone:" {
                name = "\(name!) \(str!)"
                print(name!)
            }
            else {
            }
        }
        
        let remove = NSScanner(string: desc as! String)
        var remString: NSString?
        remove.scanUpToString("Contact: ", intoString: &remString)
        remove.scanUpToString(name! as String, intoString: &remString)
        remove.scanUpToString(" ", intoString: &remString)
        desc = desc?.stringByReplacingOccurrencesOfString("\(remString!)", withString: "")
    }
    
    func scanRestOfName(scanner: NSScanner) {
        prefix = nil
        scanner.scanUpToString(" ", intoString: &prefix)
        if prefix != "Email:" && prefix != "Phone:" {
            name = "\(name!) \(prefix!)"
            scanRestOfName(scanner)
        }
    }
    
    func scanPhoneFromDescription() {
        let scanner = NSScanner(string: desc as! String)
        scanner.scanUpToString("Phone:", intoString: nil)
        scanner.scanUpToString(" ", intoString: nil)
        scanner.scanUpToString(" ", intoString: &phone)
        scanner.scanUpToString(" ", intoString: &morePhone)
        if morePhone == "ext" || morePhone == "ext."{
            scanner.scanUpToString(" ", intoString: &ext)
            if ext != nil && ext != " "{
                phone = "\(phone!) \(ext!)"
            }
        }
        print("phone: \(phone!)")
        formatPhone()
        
        let remove = NSScanner(string: desc as! String)
        var remString: NSString?
        remove.scanUpToString("Phone: ", intoString: &remString)
        remove.scanUpToString(phone! as String, intoString: &remString)
        remove.scanUpToString(" ", intoString: &remString)
        desc = desc?.stringByReplacingOccurrencesOfString("\(remString!)", withString: "")
    }
    
    func scanEmailFromDescription() {
        let scanner = NSScanner(string: desc as! String)
        scanner.scanUpToString("Email:", intoString: nil)
        scanner.scanUpToString(" ", intoString: nil)
        scanner.scanUpToString(" ", intoString: &email)
        if email != nil{
            let remove = NSScanner(string: desc as! String)
            var remString: NSString?
            remove.scanUpToString("Email: ", intoString: &remString)
            remove.scanUpToString(email! as String, intoString: &remString)
            remove.scanUpToString(" ", intoString: &remString)
            desc = desc?.stringByReplacingOccurrencesOfString("\(remString!)", withString: "")
        }
    }
    
    func formatPhone(){
        var firstThree = NSString()
        var secondThree = NSString()
        var finalFour = NSString()
        firstThree = phone!.substringWithRange(NSRange(location: 0, length: 3))
        secondThree = phone!.substringWithRange(NSRange(location: 4, length: 3))
        finalFour = phone!.substringWithRange(NSRange(location: 8, length: 4))
        
        if ext != nil{
            actualPhone = "\(firstThree)\(secondThree)\(finalFour)\(ext!)"
        }
        else{
            actualPhone = "\(firstThree)\(secondThree)\(finalFour)"
        }
        print(actualPhone)
    }
    
    //Tweet
    func tweet() {
        //Check if device can tweet
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter){
            let twitter:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            twitter.setInitialText("Check out \(eventTitle), which I found in the #KGHS iOS App!")
            self.presentViewController(twitter, animated: true, completion: nil)
        }
        else{
            //Device can't tweet
            self.presentViewController(alert("No Twitter Account", message: "Please login to a Twitter account to share."), animated: true, completion: nil)
        }
    }
    
    //Facebook
    func facebook() {
        //Check for facebook
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
            let facebook:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            facebook.setInitialText("Check out \(eventTitle), which I found in the #KGHS iOS App!")
            self.presentViewController(facebook, animated: true, completion: nil)
        }
        else{
            self.presentViewController(alert("No Facebook Account", message: "Please login to a Facebook account to share."), animated: true, completion: nil)
        }
    }
    @IBAction func action(sender: UIBarButtonItem) {
        let alertview = UIAlertController(title: "Share Event", message: "What would you like to do with this event?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        let calendarAction: UIAlertAction = UIAlertAction(title: "Add To My Calendar", style: .Default) { action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.addToCalendar()
        }
        let tweetAction: UIAlertAction = UIAlertAction(title: "Share on Twitter", style: .Default) { action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.tweet()
        }
        let facebookAction: UIAlertAction = UIAlertAction(title: "Share on Facebook", style: .Default, handler: { action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.facebook()
        })
        alertview.addAction(calendarAction)
        alertview.addAction(tweetAction)
        alertview.addAction(facebookAction)
        alertview.addAction(cancelAction)
        self.presentViewController(alertview, animated: true, completion: nil)
        for subview in alertview.view.subviews{
            if subview.isKindOfClass(UIButton){
                let label = subview as! UIButton
                label.titleLabel!.font = UIFont.systemFontOfSize(17)
            }
        }
    }
    
    //Add event to the calendar
    func addToCalendar(){
        switch EKEventStore.authorizationStatusForEntityType(EKEntityType.Event){
        case .Authorized:
            print("Authorized")
            insertEvent(eventStore)
            self.presentViewController(alert("Event Added To Calendar", message: "Event \(eventTitle) has been added to your main calendar"), animated: true, completion: nil)
        case .Denied:
            print("Denied")
            self.presentViewController(alert("Calendar Unavailable", message: "Couldn't add the event to your calendar."), animated: true, completion: nil)
        case .NotDetermined:
            
            
            eventStore.requestAccessToEntityType(EKEntityType.Event, completion:
                {(granted: Bool, error: NSError?) -> Void in
                    if granted {
                        self.insertEvent(self.eventStore)
                    } else {
                        print("Access denied")
                    }
                })
        default:
            break
        }
    }
    func insertEvent(store: EKEventStore){
        let event = EKEvent(eventStore: eventStore)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        event.title = self.eventTitle
        event.startDate = date
        event.endDate = endDate!
        event.notes = desc as? String
        event.allDay = allDay
        
        var error: NSError?
        let result: Bool
        do {
            try store.saveEvent(event, span: EKSpan.ThisEvent)
            result = true
        } catch let error1 as NSError {
            error = error1
            result = false
        }
        
        if result == false{
            if let theError = error {
                print("An error occured \(theError)")
            }
        }
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
    
    
}

