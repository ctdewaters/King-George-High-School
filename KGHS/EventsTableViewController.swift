//
//  EventsTableViewController.swift
//  KGHS
//
//  Created by Collin DeWaters and Taylor Courtney on 2/5/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import UIKit
import Foundation
import CoreData

public var animator = Animator()

extension UIImageView{
    func addToImage(image: UIImage){
        let imageView = UIImageView(frame: self.frame)
        imageView.image = image
        self.addSubview(imageView)
        self.sendSubviewToBack(imageView)
    }
}

//Add property to NSDate type for day only (no time)
extension NSDate {
    var date: NSDate{
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let str = dateFormatter.stringFromDate(self)
        return dateFormatter.dateFromString(str)!
    }
}

class EventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MenuDelegate, UIViewControllerPreviewingDelegate {
    
    @IBOutlet weak var eventsTableView: UITableView!
    @IBOutlet weak var titleButton: UIButton!
    
    var events = NSMutableArray()

    var menuEvents = NSMutableArray()
    var backgroundImage = UIImageView()
    
    var previewVC = DetailViewController()
    
    var menu = DropDownMenu()
    var titleImage = UIImageView()
    var imageScroller = UIImageView()
    let imageScrollerImages = [UIImage(named: "frontName")!, UIImage(named: "cafeteria"), UIImage(named: "front"), UIImage(named: "field"), UIImage(named: "hall")]
    var index = 0
    var noEvents = Bool()
    
    var chosenCategory = "All"
    var chosenSubCategory = "All"
    
    var usingOriginalArray = Bool()
    var usingCoreDataArray = false
    
    var favoritedEvents = NSArray()
    
    var alertImage = UIImageView()
    
    var eventsTableSelected = Bool()
    
    var connectedToInternet: Bool!
    
    var alert = UIAlertController()
    var refreshControl: UIRefreshControl!
    
    let athSearchCategories = ["All", "VFB", "JVFB", "Golf", "FH", "V BB/SB", "JV BB/SB", "B Soccer", "G Soccer", "B Tennis", "G Tennis", "Track", "VB"]
    let kgSearchCategories = ["All", "Graduation", "Faculty", "Department Chair", "FBLA", "DECA", "Band", "Chorus", "SOL", "AP", "Theatre"]
    
    override func viewDidLoad() {
        
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: eventsTableView)
                
            }
        } else {
            // Fallback on earlier versions
        }
        
        eventsTableView.backgroundColor = UIColor(rgba: "#4E6285")
        eventsTableView.separatorStyle = .SingleLine
        eventsTableView.separatorColor = UIColor(rgba: "#00335b")
        
        let titleImage = UIImageView(frame: CGRectMake(0, 0, 40, 40))
        titleImage.image = UIImage(named: "kglogo")!
        titleImage.contentMode = .ScaleAspectFit
        
        let titleView = UIView(frame: CGRectMake(0, 0, 44, 44))
        titleImage.frame = titleView.bounds
        titleView.addSubview(titleImage)
        self.navigationItem.titleView = titleView
        
        alertImage = UIImageView(frame: CGRectMake(0, 0, view.frame.width * 0.4, view.frame.width * 0.4))
        
        tabBarIndex = self.tabBarController!.selectedIndex
        dataManager.saveObjectInEntity("UserSettings", objects: [tabBarIndex, showStaffFavorites], keys: ["selectedTab", "showFavoritedStaff"], deletePrevious: true)
        
        //Initializing the drop down menu
        menu = DropDownMenu(view:view, imageScroller: imageScroller)
        menu.delegate = self
        
        //load events
        usingOriginalArray = true
        print("You are connected to the internet")
        loadEvents(["All"], subCategory: ["All"])
        print(events)
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(EventsViewController.refresh), forControlEvents: .ValueChanged)
        refreshControl.tintColor = UIColor(rgba: "#00335b")
        refreshControl.backgroundColor = .clearColor()
        self.eventsTableView.addSubview(refreshControl)
        
        //Title view
        titleButton.setTitle(" \(chosenSubCategory)", forState: .Normal)
        titleButton.layer.masksToBounds = true
        titleButton.imageView?.contentMode = .ScaleAspectFit
        titleButton.layer.cornerRadius = titleButton.frame.height / 3.5
        titleButton.layer.zPosition = 1000
        titleButton.setTitle(" \(chosenSubCategory)", forState: .Normal)
        titleButton.frame.size.width += 100
        titleButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        
        //Setting the image scroller
        imageScroller.contentMode = UIViewContentMode.ScaleAspectFill
        imageScroller.image = imageScrollerImages[index+1]
        imageScroller.clipsToBounds = true
        animateImageView()
    }
    
    override func viewDidAppear(animated: Bool) {
        if usingCoreDataArray == true{
            favoritedEvents = dataManager.loadObjectInEntity("FavoritedEvents")!
            eventsTableView.reloadData()
            
        }
    }
    
    //Transition for image scroller
    func animateImageView() {
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.4)
        CATransaction.setCompletionBlock {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(5 * NSTimeInterval(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.animateImageView()
            }
        }
        let transition = CATransition()
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromLeft
        imageScroller.layer.addAnimation(transition, forKey: kCATransition)
        imageScroller.image = imageScrollerImages[index]
        
        CATransaction.commit()
        
        //If index is less than the array.count, add by one. Else, index is set to zero.
        index = index < imageScrollerImages.count - 1 ? index + 1 : 0
    }
    
    //Load events from .ics
    func loadEvents(category: Array<String>, subCategory: Array<String>){
        events.removeAllObjects()
        loading()
        // Set feed url.
        let url = NSURL(string: "http://www.calendarwiz.com/CalendarWiz_iCal.php?crd=kgcs")!
        //let url = NSBundle.mainBundle().URLForResource("CalendarWiz_iCal.php", withExtension: "ics")
        let dataFromURL = NSData(contentsOfURL: url)
        
        
        if dataFromURL != nil{ // user connected to internet
            connectedToInternet = true
            let str = NSString(data: dataFromURL!, encoding: NSUTF8StringEncoding)
            //Parse ics string
            let parser = MXLCalendarManager()
            parser.parseICSString(str as! String, withCompletionHandler: ({
            (calendar: MXLCalendar?, error: NSError?) -> Void in
            
            //Add events to array
                print(calendar!.events.count)
                for event in calendar!.events{
                    let eve: MXLCalendarEvent = event as! MXLCalendarEvent
                
                    //filter for kghs events (school division calendar)
                    if eve.eventCategory == "King George High" || eve.eventCategory == "KGHS Athletics"{
                    
                        //Add events based on parameters
                        for str in category{
                            if eve.eventCategory == str || str == "All"{
                            
                                for sub in subCategory{
                                    if sub == "All"{
                                        //Check if date is current or future
                                        if (eve.eventStartDate.date.compare(NSDate().date) == NSComparisonResult.OrderedDescending) || (eve.eventStartDate.date.compare(NSDate().date) == NSComparisonResult.OrderedSame){
                                            self.setEventSubcategory(eve)
                                            self.events.addObject(eve)
                                        }
                                    }
                                    else if eve.eventSummary.lowercaseString.rangeOfString(sub.lowercaseString, options: .LiteralSearch) != nil && sub != "All"{
                                    //Check if date is current or future
                                        if (eve.eventStartDate.date.compare(NSDate().date) == NSComparisonResult.OrderedDescending) || (eve.eventStartDate.date.compare(NSDate().date) == NSComparisonResult.OrderedSame){
                                            self.setEventSubcategory(eve)
                                            self.events.addObject(eve)
                                        }
                                    }
                            }
                            }
                        }
                    }
                }
            }))
        
            //Setting boolean
            if events.count == 0{
                noEvents = true
                print("No events")
            }
            else{
                noEvents = false
            }
            eventsTableView.reloadData()
            alert.dismissViewControllerAnimated(true, completion: nil)
        }
            
        else {
            alert.dismissViewControllerAnimated(true, completion: nil)
            connectedToInternet = false
            eventsTableView.reloadData()
        }
    }
    
    //loading events indicator
    func loading(){
        alert = UIAlertController(title: "Loading Events", message: "Please wait...", preferredStyle: .Alert)
        
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0, 0, 75, 75)) as UIActivityIndicatorView
        loadingIndicator.center = CGPointMake(self.view.frame.width / 2, self.view.frame.height / 2)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        loadingIndicator.startAnimating()
        loadingIndicator.tintColor = UIColor(red: 0/255, green: 0/255, blue: 170/255, alpha: 1)
        
        alert.view.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //User selected a category from the drop down menu
    func loadFromMenu(category: String, subCategory: String){
        loading()
        menuEvents.removeAllObjects()
        usingOriginalArray = false
        for event in events{
            let e  = event as! MXLCalendarEvent
            if e.eventCategory == category{
                if e.eventSubCategory == subCategory || subCategory == "All"{
                    menuEvents.addObject(e)
                }
            }
        }
        checkForNoEvents(menuEvents)
        alert.dismissViewControllerAnimated(true, completion: nil)
        eventsTableView.reloadData()
    }
    
    //Set MXLCalendarEvent's sub category from preset arrays
    func setEventSubcategory(e: MXLCalendarEvent){
        if e.eventSubCategory == nil{
            if e.eventCategory == "KGHS Athletics"{
                for s in athSearchCategories{
                    if checkSummaryText(e.eventSummary, forText: s) != nil{
                        if checkSummaryText(s, forText: "V") != nil && checkSummaryText(s, forText: "JV") == nil{
                            e.eventSubCategory = s
                        }
                        if checkSummaryText(s, forText: "JV") != nil{
                            e.eventSubCategory = s
                           
                        }
                        else{
                            e.eventSubCategory = s
                        }
                    }
                }
                if e.eventSubCategory == nil{
                    e.eventSubCategory = "All"
                }
            }
            if e.eventCategory == "King George High"{
                for s in kgSearchCategories{
                    if s == "AP" {
                        if checkSummaryText(e.eventSummary, forText: "AP ") != nil {
                            e.eventSubCategory = s
                        }
                    }
                    else if checkSummaryText(e.eventSummary, forText: s) != nil{
                        e.eventSubCategory = s
                    }
                    
                }
                if e.eventSubCategory == nil{
                    e.eventSubCategory = "All"
                }
                
            }
        }
    }
    
    //Check event's summary for keyword
    func checkSummaryText(string: String, forText: String) -> Range<String.Index>?{
        return string.lowercaseString.rangeOfString(forText.lowercaseString, options: .LiteralSearch)
    }
    
    func refresh() {
        self.eventsTableView.scrollEnabled = false
        loadEvents(["All"], subCategory: ["All"])
        self.refreshControl.endRefreshing()
        self.eventsTableView.scrollEnabled = true
    }
    
    @IBAction func openMenu(sender: UIButton) {
        //Check if menu is already open
    
        self.titleButton.layer.addAnimation(animator.caBasicAnimation(0, to: -2 * M_PI, repeatCount: 0, keyPath: "transform.rotation.x", duration: 0.4), forKey: "rotate")
        
        if menu.menuOpen == false{
            menu.moveMenu(true)
            simpleAnimationForDuration(0.5, animation: {
                self.titleButton.imageView?.transform = CGAffineTransformMakeRotation(3.1415)
            })
            //Disable interaction with the events table view
            eventsTableView.allowsSelection = false
            eventsTableView.scrollEnabled = false
            eventsTableView.userInteractionEnabled = false
            alertImage.removeFromSuperview()
        }
        else if menu.menuOpen == true{
            menu.moveMenu(false)
            simpleAnimationForDuration(0.5, animation: {
                self.titleButton.imageView?.transform = CGAffineTransformMakeRotation(0 - 0.0001)
            })
            titleButton.imageView?.transform = CGAffineTransformMakeRotation(0)
            //Enable interaction
            eventsTableView.allowsSelection = true
            eventsTableView.scrollEnabled = true
            eventsTableView.userInteractionEnabled = true
            
            if eventsTableView.numberOfRowsInSection(0) == 0{
                //addAlertImage(UIImage(named: "noEvents")!)
            }
            
        }
    }
    
    //Display date as string
    func convertEventDateToString(date: NSDate)->String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
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
    
    func addAlertImage(image: UIImage){
        alertImage.removeFromSuperview()
        alertImage.center = CGPointMake(view.frame.width / 2, view.frame.height / 2)
        alertImage.image = image
        alertImage.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        alertImage.clipsToBounds = true
        alertImage.layer.cornerRadius = alertImage.frame.height / 4
        alertImage.transform = CGAffineTransformMakeScale(0, 0)
        view.addSubview(alertImage)
        
        complexAnimationForDuration(0.25, delay: 0, animation1: {
            self.alertImage.transform = CGAffineTransformMakeScale(1.35, 1.35)
            }, animation2: {
                self.alertImage.transform = CGAffineTransformMakeScale(1, 1)
        })
    }
    
    //Get category menu selection
    func menuControlDidSelectButtonAtIndex(section: Int, row: Int) {
        //Load events based on users chosen category and subcategory
        switch section{
            //First set of event sort options
        case 1:
            chosenCategory = "All"
            chosenSubCategory = "All"
            if row == 0{
                usingOriginalArray = true
                usingCoreDataArray = false
                eventsTableView.reloadData()
            }
            else{
                usingOriginalArray = false
                usingCoreDataArray = true
                chosenSubCategory = "Favorites"
                favoritedEvents = dataManager.loadObjectInEntity("FavoritedEvents")!
                eventsTableView.reloadData()
            }
            
            menu.moveMenu(false)
            //School Events section
        case 2:
            chosenCategory = "King George High"
            usingCoreDataArray = false
            chosenSubCategory = menu.acCat.objectAtIndex(row) as! String
            menu.moveMenu(false)
            loadFromMenu(chosenCategory, subCategory: chosenSubCategory)
            //School athletics section
        case 3:
            chosenCategory = "KGHS Athletics"
            usingCoreDataArray = false
            chosenSubCategory = menu.atCat.objectAtIndex(row) as! String
            switch chosenSubCategory {
            case "V Football" :
                chosenSubCategory = "VFB"
            case "JV Football" :
                chosenSubCategory = "JVFB"
            case "Field Hockey" :
                chosenSubCategory = "FH"
            case "Volleyball" :
                chosenSubCategory = "VB"
            default:
                break
            }
            loadFromMenu(chosenCategory, subCategory: chosenSubCategory)
            menu.moveMenu(false)
        default:
            break
        }
        
        eventsTableView.allowsSelection = true
        eventsTableView.scrollEnabled = true
        eventsTableView.userInteractionEnabled = true
        
        switch chosenSubCategory {
        case "VFB" :
            chosenSubCategory = "V Football"
        case "JVFB" :
            chosenSubCategory = "JV Football"
        case "FH" :
            chosenSubCategory = "Field Hockey"
        case "VB" :
            chosenSubCategory = "Volleyball"
        default:
            break
        }
        
        titleButton.setTitle(" \(chosenSubCategory)", forState: .Normal)
        
        if menuEvents.count != 0{
            alertImage.removeFromSuperview()
        }
        simpleAnimationForDuration(0.5, animation: {
       self.titleButton.imageView?.transform = CGAffineTransformMakeRotation(0 - 0.0001)
        })
        titleButton.imageView?.transform = CGAffineTransformMakeRotation(0)
    }
    
    //Check if the current event array has no events
    func checkForNoEvents(eventArray: NSMutableArray){
        if eventArray.count == 0{
            noEvents = true
        }
        else{
            noEvents = false
        }
    }
    
    // MARK: - Table view data source
    
    //One section in table view
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    //Set number of rows in table view
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if connectedToInternet == false {
            return 0
        }
        else{
            //events table view
            if usingCoreDataArray == false{
                if usingOriginalArray == true{
                    if events.count == 0{
                        //addAlertImage(UIImage(named: "noEvents")!)
                        return 0
                    }
                    alertImage.removeFromSuperview()
                    
                    return events.count
                }
                    //User is using menu array
                else{
                    if menuEvents.count == 0{
                        //addAlertImage(UIImage(named: "noEvents")!)
                        return 0
                    }
                    alertImage.removeFromSuperview()
                    
                    return menuEvents.count
                }
            }
            else{
                if events.count == 0{
                    //addAlertImage(UIImage(named: "noEvents")!)
                    return 0
                }
                alertImage.removeFromSuperview()
                return favoritedEvents.count
            }
        }
    }
    
    //set the height of each row in the tableview
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 150
    }
    
    //Set each tableview cell
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let  cell = eventsTableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! EventTableViewCell
        
        cell.titleLabel.textColor = UIColor(rgba: "#00335b")
        
            if usingCoreDataArray == false{
                //Eventstableview cell
                var currentEvent = MXLCalendarEvent()
                
                //Check if the selected category has any events
                if usingOriginalArray == true{
                    currentEvent = events.objectAtIndex(indexPath.row) as! MXLCalendarEvent
                }
                else{
                    currentEvent = menuEvents.objectAtIndex(indexPath.row) as! MXLCalendarEvent
                }
                
                setUpCell(cell, thisEvent: currentEvent)
                
                //Animate the cell
               cell.layer.addAnimation(animator.caBasicAnimation(M_PI * 0.75, to: 0, repeatCount: 0, keyPath: "transform.rotation.x", duration: 0.25), forKey: "rotation")
                
                animator.simpleAnimationForDuration(0.25, animation: {
                    cell.contentView.alpha = 1
                })
                
                return cell
                
            }
            else{
                let currentEvent = favoritedEvents.objectAtIndex(indexPath.row) as! NSManagedObject
                setCoreDataCell(cell, object: currentEvent)
                
                //Animate the cell
                cell.layer.addAnimation(animator.caBasicAnimation(M_PI * 0.75, to: 0, repeatCount: 0, keyPath: "transform.rotation.x", duration: 0.25), forKey: "rotation")
                
                animator.simpleAnimationForDuration(0.25, animation: {
                    cell.contentView.alpha = 1
                })
                
                return cell
            }
        
        
    }
    
    //Runs if user is viewing their favorited events
    func setCoreDataCell(cell: EventTableViewCell, object: NSManagedObject){
        let title = object.valueForKey("title") as! String
        var startDate = object.valueForKey("date") as! NSDate
        let category = object.valueForKey("category") as! String
        let subCategory = object.valueForKey("subcategory") as! String
        let allDay = object.valueForKey("allDay") as! Bool
        
        cell.dateLabel.text = "\(convertEventDateToString(startDate)), "
        
        //Check if event is all day
        if allDay == true{
            startDate = object.valueForKey("endDate") as! NSDate
            cell.dateLabel.text = "\(cell.dateLabel.text)All Day"
        }
        else {
            cell.dateLabel.text = "\(cell.dateLabel.text)\(convertEventTimeToString(startDate))"
            
        }
        
        //Check if date is today
        if startDate.date.compare(NSDate().date) == NSComparisonResult.OrderedSame{
            cell.dateLabel.text = "Today"
        }
        
        cell.titleLabel.text = title
        
        cell.categoryImage.image = chooseCategoryImage(category, subCategory: subCategory)
    }
    
    //Set up custom cell's information
    func setUpCell(cell: EventTableViewCell, thisEvent: MXLCalendarEvent){
        var eventTime = convertEventTimeToString(thisEvent.eventStartDate)
        let eventCategory = thisEvent.eventCategory
        let eventSubCategory = thisEvent.eventSubCategory
        var eventDate = convertEventDateToString(thisEvent.eventStartDate)
        
        eventDate = convertEventDateToString(thisEvent.eventEndDate)
        
        if thisEvent.eventStartDate.date.compare(NSDate().date) == NSComparisonResult.OrderedSame{
            eventDate = "Today"
        }
        
        if thisEvent.eventIsAllDay == true{
            //Use end date if event is all day (ics file issue)
            eventDate += ", All Day"
        }
        else {
            eventDate += ", \(eventTime)"
        }
        
        //Fill in the cell
        cell.titleLabel.text = (thisEvent.eventSummary)
        cell.titleLabel.fadeLength = 10
        cell.titleLabel.rate = 50
        cell.titleLabel.marqueeType = MarqueeType.MLContinuous
        cell.dateLabel.text = eventDate
        cell.categoryLabel.text = "\(eventCategory) - \(eventSubCategory)"
        cell.categoryImage.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.25)
        cell.categoryImage.layer.cornerRadius = 50
        cell.categoryImage.image = chooseCategoryImage(eventCategory, subCategory: eventSubCategory)
        
    }
    
    //Add category image to cell and detail page
    func chooseCategoryImage(category: String, subCategory: String?)-> UIImage!{
        var image = UIImage()
        if category == "KGHS Athletics"{
            image = UIImage(named: "athletics")!
        }
        if category == "King George High"{
            if subCategory == "DECA"{
                image = UIImage(named: "decaLogo")!
            }
            if subCategory == "FBLA"{
                image = UIImage(named: "fblaLogo")!
            }
            if subCategory == "Band" || subCategory == "Chorus"{
                image = UIImage(named: "band")!
            }
            if subCategory == "AP"{
                image = UIImage(named: "AP")!
            }
            if subCategory == "Graduation"{
                image = UIImage(named: "graduation")!
            }
            if subCategory == "Faculty"{
                image = UIImage(named: "academics")!
            }
            if subCategory == "Department Chair"{
                image = UIImage(named: "departmentChair")!
            }
            if subCategory == "SOL"{
                image = UIImage(named: "SOL")!
            }
            if subCategory == "Theatre"{
                image = UIImage(named: "theatre")!
            }
            if subCategory == nil || subCategory == "All"{
                image = UIImage(named: "academics")!
            }
        }
        
        return image
    }
    
    //Cell Was Selected
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            //events table view
            eventsTableSelected = true
            self.performSegueWithIdentifier("detail", sender: self)
            
            //Deselect the row
            eventsTableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        titleButton.transform = CGAffineTransformMakeRotation(0)
    }
    
    //Set up the detail view controller
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {//Runs when the segue is called
        if segue.identifier == "detail"{
            
            //store the destination view controller in a variable
            let vc = segue.destinationViewController as! DetailViewController
            
            if eventsTableSelected == true{
                var arr = NSMutableArray()
                //check if core data is being used
                if usingCoreDataArray{
                    let index = eventsTableView.indexPathForSelectedRow
                    let event = favoritedEvents.objectAtIndex(index!.row) as! NSManagedObject
                    setEventDetailsForManagedObject(event, vc: vc)
                }
                else{
                    if usingOriginalArray{
                        arr = events
                    }
                    else{
                        arr = menuEvents
                    }
                    let index = eventsTableView.indexPathForSelectedRow
                    let event = arr.objectAtIndex(index!.row) as! MXLCalendarEvent
                    setEventDetailsForCalendarEvent(event, vc: vc)
                }
                
            }
        }
    }
    
    //Set up variables in the DetailViewController Class (using mxlcalendar array)
    func setEventDetailsForCalendarEvent(event: MXLCalendarEvent, vc: DetailViewController){
        
        vc.eventTitle = event.eventSummary
        vc.date = event.eventStartDate
        vc.desc = event.eventDescription
        vc.allDay = event.eventIsAllDay
        vc.endDate = event.eventEndDate
        let cat = event.eventCategory
        let subCat = event.eventSubCategory
        
        vc.category = cat
        vc.subCategory = subCat
        vc.image = chooseCategoryImage(cat, subCategory: subCat)
    }
    
    //Set up variables in the DetailViewControllerClass (using mxlcalendar array)
    func setEventDetailsForManagedObject(object: NSManagedObject, vc: DetailViewController){
        vc.eventTitle = object.valueForKey("title") as! String
        vc.date = object.valueForKey("date") as! NSDate
        let category = object.valueForKey("category") as! String
        let subCategory = object.valueForKey("subcategory") as! String
        vc.category = category
        vc.subCategory = subCategory
        vc.endDate = object.valueForKey("endDate") as? NSDate
        vc.allDay = object.valueForKey("allDay") as! Bool
        vc.desc = object.valueForKey("desc") as! String
        vc.image = chooseCategoryImage(category, subCategory: subCategory)
    }
    
    //Animation functions
    func simpleAnimationForDuration(duration: NSTimeInterval, animation: (() -> Void)){
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        animation()
        UIView.commitAnimations()
    }
    
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
    
    
    //UIViewControllerPreviewingDelegate protocol
    
    //Pop
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        showViewController(previewVC, sender: self)
    }
    
    //Peek
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = eventsTableView.indexPathForRowAtPoint(location), cell = eventsTableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        if let vc = storyboard?.instantiateViewControllerWithIdentifier("eventDetailVC") as? DetailViewController {
            previewVC = vc
            if usingCoreDataArray{
                let event = favoritedEvents.objectAtIndex(indexPath.row) as! NSManagedObject
                setEventDetailsForManagedObject(event, vc: previewVC)
            }
            else {
                var arr = NSMutableArray()
                if self.usingOriginalArray{
                    arr = self.events
                }
                else{
                    arr = self.menuEvents
                }
                let event = arr.objectAtIndex(indexPath.row) as! MXLCalendarEvent
                setEventDetailsForCalendarEvent(event, vc: previewVC)
            }
            
            previewVC.preferredContentSize = CGSizeMake(0, 500)
            if #available(iOS 9.0, *) {
                previewingContext.sourceRect = cell.frame
            } else {
                // Fallback on earlier versions
            }
            return previewVC
        }
        else {
            return nil
        }
        
    }
}
