//
//  DropDownMenu.swift
//  KGHS
//
//  Created by Collin DeWaters and Taylor Courtney on 2/12/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import UIKit

//protocol for when the menu is selected
@objc protocol MenuDelegate{
    func menuControlDidSelectButtonAtIndex(section:Int, row: Int)
}

class DropDownMenu: NSObject, CategoryMenuTableViewControllerDelegate {
    
    var menuWidth:CGFloat = CGFloat()
    var menuHeight = CGFloat()
    
    let menuContainerView:UIView = UIView()
    let categoryMenu: CategoryMenuTableViewController = CategoryMenuTableViewController()
    var sourceView = UIView()
    var delegate:MenuDelegate?
    var animator:UIDynamicAnimator!
    var menuOpen = Bool()
    
    var acCat: NSMutableArray = ["All", "Graduation", "Faculty", "Department Chair", "FBLA", "DECA", "Band", "Chorus", "SOL", "AP", "Theatre"]
    var atCat: NSMutableArray = ["All", "V Football", "JV Football", "Golf", "Field Hockey", "V BB/SB", "JV BB/SB", "B Soccer", "G Soccer", "B Tennis", "G Tennis", "Track", "Volleyball"]
    
    //Menu data
    let menuCategories = ["School Events", "Athletic Events"]
    
    override init() {
        super.init()
    }
    
    //initialize and set up the dropdownmenu
    init(view:UIView, imageScroller: UIImageView){
        super.init()
        sourceView = view
        
        //Setting the data in the cateogory menu table view
        categoryMenu.categories  = menuCategories
        categoryMenu.acaCategories = acCat
        categoryMenu.athCategories = atCat
        categoryMenu.imageScroller = imageScroller
        
        setupMenu()
        
        animator = UIDynamicAnimator(referenceView: sourceView)
        
    }
    
    //row selected
    func menuControlDidSelectRow(indexPath: NSIndexPath){
        delegate?.menuControlDidSelectButtonAtIndex(indexPath.section, row: indexPath.row)
        categoryMenu.tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    //Set up the menu when it loads
    func setupMenu(){
        menuWidth = sourceView.frame.width
        menuHeight = UIScreen.mainScreen().bounds.height
        
        //container view (entire menu setup)
        menuContainerView.frame = CGRectMake(sourceView.frame.origin.y, -menuHeight - 1, menuWidth, menuHeight - 65)
        menuContainerView.center.y = menuContainerView.center.y - 60
        menuContainerView.backgroundColor = UIColor.clearColor()
        menuContainerView.clipsToBounds = false
        
        sourceView.addSubview(menuContainerView)
        
        //blur effect
        let blurView:UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
        blurView.frame = menuContainerView.bounds
        menuContainerView.addSubview(blurView)
        
        //Colorize blur
        let colorView = UIView(frame: blurView.frame)
        colorView.backgroundColor =  UIColor(red: 223/255, green: 199/255, blue: 3/255, alpha: 0.05)
        menuContainerView.addSubview(colorView)
        menuContainerView.sendSubviewToBack(colorView)
        
        //set up and embed the category menu in the containerview
        categoryMenu.delegate = self
        categoryMenu.tableView.frame = menuContainerView.bounds
        categoryMenu.tableView.clipsToBounds = false
        categoryMenu.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        categoryMenu.tableView.separatorColor = UIColor.darkGrayColor()
        categoryMenu.tableView.backgroundColor = UIColor.clearColor()
        categoryMenu.tableView.scrollEnabled = true
        categoryMenu.tableView.reloadData()
        categoryMenu.tableView.contentInset = UIEdgeInsetsMake(0, 0, 65, 0)
        
        menuContainerView.addSubview(categoryMenu.tableView)
    }
    
    
    //Open or close the menu (false to close)
    func moveMenu(open: Bool){
        animator.removeAllBehaviors()
        menuOpen = open
        
        //Set gravity and the boundary of UIDynamics based on the open boolean
        let gravityY = (open) ? 5 : -5
        let boundary = (open) ? menuHeight : -menuHeight - 61
                
        let gravity: UIGravityBehavior = UIGravityBehavior(items: [menuContainerView])
        gravity.gravityDirection = CGVector(dx: 0, dy: gravityY)
        animator.addBehavior(gravity)
        
        let collisionBehavior: UICollisionBehavior = UICollisionBehavior(items: [menuContainerView])
        collisionBehavior.addBoundaryWithIdentifier("boundary", fromPoint: CGPointMake(0, boundary), toPoint: CGPointMake(sourceView.frame.size.width, boundary))
        animator.addBehavior(collisionBehavior)
        
        let menuBehavior: UIDynamicItemBehavior = UIDynamicItemBehavior(items: [menuContainerView])
        menuBehavior.elasticity = 0.1
        animator.addBehavior(menuBehavior)
        
    }
    

}
