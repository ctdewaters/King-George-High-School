//
//  CategoryMenuTableViewController.swift
//  KGHS
//
//  Created by Collin DeWaters and Taylor Courtney on 2/12/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import UIKit

protocol CategoryMenuTableViewControllerDelegate{
    func menuControlDidSelectRow(indexPath: NSIndexPath)
}

class CategoryMenuTableViewController: UITableViewController {
    
    var delegate: CategoryMenuTableViewControllerDelegate?
    var imageScroller = UIImageView()
    
    //Category Arrays
    var categories: Array<String> = []
    var acaCategories: NSMutableArray!
    var athCategories: NSMutableArray!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "MenuCell", bundle: nil), forCellReuseIdentifier: "menu")
        tableView.separatorStyle = .None
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
      
        return categories.count + 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return 1
        case 1:
            return 2
        case 2:
            return acaCategories.count
        case 3:
            return athCategories.count
        default:
            break
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0{
            return 200
        }
        else{
            return 60
        }
    }
    
    //Set height of each header
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 || section == 1{
            return 0
        }
        else{
            return 25
        }
    }
    
    //Set header in each section
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 || section == 1{
            return nil
        }
        else{
            let headerTitle = UILabel(frame: CGRectMake(0, 0, 300, 50))
            headerTitle.text = "   \(categories[section-2])"
            headerTitle.textColor = UIColor.whiteColor()
            headerTitle.backgroundColor = UIColor(rgba: "#00335b")
            headerTitle.font = UIFont(name: "Avenir Next:Bold", size: 20)
            
            return headerTitle
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //Set up image scroller
        if indexPath.section == 0 && indexPath.row == 0{
            
            var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("imgScroller") as UITableViewCell?
            
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "imgScroller")
                
                cell?.backgroundColor = UIColor.clearColor()
                cell!.selectionStyle = UITableViewCellSelectionStyle.None
                cell?.textLabel?.text = ""
                
                imageScroller.frame = CGRectMake(0, 0, cell!.bounds.width, cell!.bounds.height)
                imageScroller.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
                cell?.backgroundView = imageScroller
            return cell!
        }
        
        //Set up category sections
        else{
            
             let cell = tableView.dequeueReusableCellWithIdentifier("menu", forIndexPath: indexPath) as? MenuTableViewCell

                cell!.backgroundColor = UIColor.clearColor()
                //Setting the view that will appear when the cell is tapped
                let selectedView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: cell!.frame.size.width, height: cell!.frame.size.height))
                selectedView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
                cell!.selectedBackgroundView = selectedView

            //Set text in cell
            switch indexPath.section{
            case 1:
                if indexPath.row == 0{
                    cell!.label?.text = "Display All Events"
                    cell!.rowImage.image = UIImage(named: "kglogo")!
                }
                else{
                    cell!.label?.text = "Display My Favorited Events"
                    cell!.rowImage.image = UIImage(named: "favoriteFilled")!
                }
            case 2:
                //academic categories
                cell!.label?.text = (acaCategories.objectAtIndex(indexPath.row) as! String)
                cell!.rowImage.image = chooseCategoryImage(categories[0], subCategory: cell!.label.text)
            case 3:
                //athletic categories
                cell!.label?.text = (athCategories.objectAtIndex(indexPath.row) as! String)
                cell!.rowImage.image = chooseCategoryImage(categories[1], subCategory: cell!.label.text)
            default:
                break
            }
        return cell!
        }
        
        
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.menuControlDidSelectRow(indexPath)
    }
    
    //Add category image to cell and detail page
    func chooseCategoryImage(category: String, subCategory: String?)-> UIImage!{
        var image = UIImage()
        if category == "Athletic Events"{
            image = UIImage(named: "athletics")!
        }
        if category == "School Events"{
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

    
}


