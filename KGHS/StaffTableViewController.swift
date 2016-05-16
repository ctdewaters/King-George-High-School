//
//  StaffTableViewController.swift
//  KGHS
//
//  Created by Collin DeWaters on 2/18/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import UIKit
import CoreData

class StaffMember: NSObject {
    var name: String!
    var affiliation: String!
    var department: String!
    var email: String!
    var webpage: String!
    var departmentChair: Bool!
    var favorited = false
}

class StaffTableViewController: UITableViewController, UIViewControllerPreviewingDelegate {
    
    var favoritesButton: UIButton!
    
    var favoritedStaff = Array<StaffMember>()

    var staff = [String: [StaffMember]]()
    var previewVC: StaffDetailViewController!
    
    var alphabeticalKeys = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: tableView)
                
            }
        }
        
        tabBarIndex = self.tabBarController!.selectedIndex
        dataManager.saveObjectInEntity("UserSettings", objects: [tabBarIndex, showStaffFavorites], keys: ["selectedTab", "showFavoritedStaff"], deletePrevious: true)
        
        loadFavoritedStaff()
        
        let settingsTitle = (showStaffFavorites == true) ? "Show All" : "Show Favorites"
        let titleImage = (showStaffFavorites == true) ? UIImage(named: "favoriteFilled") : UIImage(named: "staff")
        
        tableView.separatorStyle = .SingleLine
        tableView.separatorColor = UIColor.whiteColor()
        tableView.backgroundColor = UIColor(rgba: "#4E6285")
        tableView.alpha = 0
        
        //Set the favorites toggle button for the navbar
        favoritesButton = UIButton(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width / 2, 35))
        favoritesButton.imageView?.contentMode = .ScaleAspectFit
        favoritesButton.setAttributedTitle(NSAttributedString(string: "  \(settingsTitle)", attributes: [NSFontAttributeName: UIFont(name: "Avenir Next", size: 16)!, NSForegroundColorAttributeName: UIColor(red: 1, green: 1, blue: 0.502, alpha: 1)]), forState: .Normal)
        favoritesButton.setAttributedTitle(NSAttributedString(string: settingsTitle, attributes: [NSFontAttributeName: UIFont(name: "Avenir Next", size: 16)!, NSForegroundColorAttributeName: UIColor.grayColor()]), forState: .Highlighted)
        favoritesButton.setImage(titleImage, forState: .Normal)
        favoritesButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
        favoritesButton.layer.masksToBounds = true
        favoritesButton.layer.cornerRadius = favoritesButton.frame.height / 3.5
        favoritesButton.addTarget(self, action: #selector(StaffTableViewController.showFavorites(_:)), forControlEvents: .TouchUpInside)
        self.navigationItem.titleView = favoritesButton
        favoritesButton.layer.zPosition = 1000

        getStaff({
            self.tableView.reloadData()
            self.tableView.alpha = 1
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        loadFavoritedStaff()
        checkAllStaffForFavorites()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func loadFavoritedStaff() {
        let lastFavorites = favoritedStaff
        favoritedStaff.removeAll(keepCapacity: false)
        let originalArray = dataManager.loadObjectInEntity("FavoritedStaff") as! Array<NSManagedObject>
        for object in originalArray {
            favoritedStaff.append(staffMemberFromManagedObject(object))
        }
        if showStaffFavorites == true && lastFavorites != favoritedStaff {
            tableView.reloadData()
        }
    }
    
    //Convert Managed or PF Object to StaffMember object
    func staffMemberFromManagedObject(object: NSManagedObject) -> StaffMember {
        let member = StaffMember()
        member.name = object.valueForKey("name") as! String
        member.email = object.valueForKey("email") as! String
        member.department = object.valueForKey("department") as! String
        member.departmentChair = object.valueForKey("departmentChair") as! Bool
        member.affiliation = object.valueForKey("affiliation") as! String
        member.webpage = object.valueForKey("webpage") as! String
        member.favorited = true
        return member
    }
    
    func checkForFavoritedStaffMember(member: StaffMember) {
        for favorite in favoritedStaff {
            if member.favorited == false {
                if favorite.name == member.name {
                    member.favorited = true
                    print("Member \(member.name) has been favorited")
                }
            }
        }
    }
    
    func checkAllStaffForFavorites() {
        let reloadData = false
        for key in alphabeticalKeys {
            for object in staff[key]! {
                checkForFavoritedStaffMember(object)
            }
        }
        if reloadData == true && showStaffFavorites == false{
            tableView.reloadData()
        }
    }
    
    func getStaff(completion: (()->Void)) {
        let url = NSURL(string: "http://www.pillocompany.com/kghs/getStaff.php")!
        
        returnedJSONFromURL(url, completion: completion)
        
    }
    
    func returnedJSONFromURL(url: NSURL, completion: (()->Void)) {
        let request = NSURLRequest(URL: url)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request){ data, response, error in
            
            do {
                if let data = data {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! [[String: AnyObject]]
                    for object in json {
                        let staffMember = self.convertToStaffMember(object)
                        
                        if self.staff.keys.contains(staffMember.department) {
                           self.staff[staffMember.department]?.append(staffMember)
                            
                        }
                        else {
                            self.staff[staffMember.department] = [staffMember]
                        }
                    }
                    self.alphabeticalKeys = Array<String>(self.staff.keys)
                    self.alphabeticalKeys.sortInPlace{$0 < $1}
                }
            }
            catch {
                print(error)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                print("POST ARRAY IS \(self.staff)")
                completion()
            })
            
        }
        task.resume()
    }
    
    func convertToStaffMember(dict: [String: AnyObject]) -> StaffMember {
        let staffMember = StaffMember()
        staffMember.name = dict["Name"] as! String
        if let department = dict["Department"] as? String {
            staffMember.department = department
            if let lastChar = staffMember.department.characters.last {
                if lastChar == " " {
                    staffMember.department = staffMember.department.substringToIndex(staffMember.department.endIndex.predecessor())
                }
            }
        }
        else {
            staffMember.department = "Other"
        }
        
        staffMember.email = dict["Email"] as! String
        staffMember.affiliation = dict["Affiliation"] as! String
        staffMember.departmentChair = (dict["departmentChair"] as! String == "True") ? true : false
        
        if let webpage = dict["Webpage"] as? String {
            staffMember.webpage = webpage
        }
        else {
            staffMember.webpage = ""
        }
        
        return staffMember
    }

    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if showStaffFavorites == false{
            return staff.keys.count
        }
        return 1
    }
    
    //Number of rows in each section
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showStaffFavorites == false {
            return staff[alphabeticalKeys[section]]!.count
        }
        return favoritedStaff.count
    }
    
    //Row height
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if showStaffFavorites == false {
            return 25
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 125
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //Set up header in each section
        let label = UILabel(frame: CGRectMake(0, 0, 300, 200))
        label.text = "  \(alphabeticalKeys[section])"
        label.font = UIFont(name: "Avenir Next", size: 20)
        label.backgroundColor = UIColor(rgba: "#00335b")
        label.textColor = UIColor.whiteColor()
        return label
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("staff", forIndexPath: indexPath) as! StaffTableViewCell
        cell.contentView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        cell.nameLabel.textColor = UIColor(rgba: "#C9DCF2")
        
        if showStaffFavorites == false {
            if let array = staff[alphabeticalKeys[indexPath.section]] {
                setNameAndDepartmentForCell(cell, memberArray:  array, row: indexPath.row)
            }
        }
        if showStaffFavorites == true {
            print("SHOWING FAVORITES")
            setNameAndDepartmentForFavoritedCell(cell, row: indexPath.row)
        }
        /*cell.nameLabel.textColor = UIColor(rgba: "#00335b")
        cell.affiliationLabel.textColor = UIColor(rgba: "#00335b").colorWithAlphaComponent(0.75)*/
        
        //cell.layer.addAnimation(animator.caBasicAnimation(M_PI * 0.75, to: 0, repeatCount: 0, keyPath: "transform.rotation.x", duration: 0.25), forKey: "rotation")
        
        return cell
        
    }
    
    //Since there are many sections, we used a single function with parameters for the cell, array, and row to set up the cell's subviews
    func setNameAndDepartmentForCell(cell: StaffTableViewCell, memberArray: [StaffMember], row: Int){
        let member = memberArray[row]
        
        let name = member.name
        let affiliation = member.affiliation
        let departmentChair = member.departmentChair
        
        cell.nameLabel.text = name
        
        
        //If no affiliation, this field is blank in parse-nothing will be shown.
        cell.affiliationLabel.text = affiliation
        
        //Check for department chair
        if departmentChair == false{
            cell.departmentChair.hidden = true
        }
        else{
            cell.departmentChair.hidden = false
        }
        
    }
    
    func setNameAndDepartmentForFavoritedCell(cell: StaffTableViewCell, row: Int) {
        let member = favoritedStaff[row]
        
        cell.nameLabel.text = member.name

        
        //If no affiliation, this will show blank
        cell.affiliationLabel.text = member.affiliation
        
        //Check for department chair
        if member.departmentChair == false{
            cell.departmentChair.hidden = true
        }
        else{
            cell.departmentChair.hidden = false
        }
    }
    
    
    //Cell Selected
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if showStaffFavorites == false {
            if let array = staff[alphabeticalKeys[indexPath.section]] {
                let object = array[indexPath.row]
                self.performSegueWithIdentifier("staffDetail", sender: object)
            }
        }
        else {
            self.performSegueWithIdentifier("staffDetail", sender: favoritedStaff[indexPath.row])
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    //Set up the detail view controller
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! StaffDetailViewController
        var index = tableView.indexPathForSelectedRow
        
        let member = sender as! StaffMember
        
        setStaffDetails(member, vc: vc)
    }
    
    //Set variables in the StaffDetailViewController class
    func setStaffDetails(staff: StaffMember, vc: StaffDetailViewController){
        vc.name = staff.name
        vc.department = staff.department
        vc.email = staff.email
        vc.webpage = staff.webpage
        vc.departmentChair = staff.departmentChair
        vc.affiliation = staff.affiliation
        vc.isFavorited = staff.favorited
    }
    
    func showFavorites(sender: AnyObject) {
        if showStaffFavorites == false {
            showStaffFavorites = true
            tableView.reloadData()
        }
        else {
            showStaffFavorites = false
            tableView.reloadData()
        }
        
        animator.complexAnimationForDuration(0.2, delay: 0, animation1: {
            self.favoritesButton.layer.addAnimation(animator.caBasicAnimation(0, to: -M_PI - 0.0000001, repeatCount: 0, keyPath: "transform.rotation.y", duration: 0.2), forKey: "rotate")
            self.favoritesButton.alpha = 0
            }, animation2: {
                let settingsTitle = (showStaffFavorites == true) ? "Show All" : "Show Favorites"
                let titleImage = (showStaffFavorites == true) ? UIImage(named: "favoriteFilled") : UIImage(named: "staff")
                
                self.favoritesButton.setAttributedTitle(NSAttributedString(string: "  \(settingsTitle)", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(16), NSForegroundColorAttributeName: UIColor(red: 1, green: 1, blue: 0.502, alpha: 1)]), forState: .Normal)
                self.favoritesButton.setAttributedTitle(NSAttributedString(string: settingsTitle, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(16), NSForegroundColorAttributeName: UIColor.grayColor()]), forState: .Highlighted)
                self.favoritesButton.setImage(titleImage, forState: .Normal)
                
                
                self.favoritesButton.layer.addAnimation(animator.caBasicAnimation( -M_PI - 0.0000001, to: 0, repeatCount: 0, keyPath: "transform.rotation.y", duration: 0.2), forKey: "rotateRest")
                animator.simpleAnimationForDuration(0.2, animation: {
                    self.favoritesButton.alpha = 1
                })
        })
        
        dataManager.saveObjectInEntity("UserSettings", objects: [tabBarIndex, showStaffFavorites], keys: ["selectedTab", "showFavoritedStaff"], deletePrevious: true)
    }
    
    //UIViewControllerPreviewingDelegate
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRowAtPoint(location), cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        if let vc = storyboard?.instantiateViewControllerWithIdentifier("staffDetailVC") as? StaffDetailViewController {
            var object: StaffMember!
            if showStaffFavorites == false {
                if let array = staff[alphabeticalKeys[indexPath.section]] {
                    object = array[indexPath.row]
                }
            }
            else {
                object = favoritedStaff[indexPath.row]
            }
            self.setStaffDetails(object, vc: vc)
            previewVC = vc
            
            previewVC.preferredContentSize = CGSizeMake(0, 500)
            if #available(iOS 9.0, *) {
                previewingContext.sourceRect = cell.frame
            }
            
            return previewVC
        }
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        showViewController(previewVC, sender: self)
    }
    
}
