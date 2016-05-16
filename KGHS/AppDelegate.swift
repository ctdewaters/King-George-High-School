//
//  AppDelegate.swift
//  KGHS
//
//  Created by Collin DeWaters on 2/3/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import TwitterKit

public var showStaffFavorites = Bool()
public var tabBarIndex = Int()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var userFavoritedCategories = NSArray()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        
        
        self.window?.tintColor = UIColor(rgba: "#00335b")
        
        let tabBarController = self.window?.rootViewController as! UITabBarController
        tabBarController.tabBar.tintColor = UIColor(red: 243/255, green: 231/255, blue: 33/255, alpha: 1)
        tabBarController.tabBar.barTintColor = UIColor(rgba: "#00335b")
        tabBarController.tabBar.translucent = true
        tabBarController.tabBar.clipsToBounds = true
        
        //Open from saved tab index
        var objects = dataManager.loadObjectInEntity("UserSettings") as! Array<NSManagedObject>
        if objects.count != 0 {
            let settings = objects[0]
            showStaffFavorites = settings.valueForKey("showFavoritedStaff") as! Bool
            tabBarIndex = settings.valueForKey("selectedTab") as! Int
        }
        else {
            showStaffFavorites = false
            tabBarIndex = 0
        }
        
        tabBarController.selectedIndex = tabBarIndex

        UINavigationBar.appearance().translucent = true
        UINavigationBar.appearance().barTintColor = UIColor(rgba: "#00335b")
        UINavigationBar.appearance().tintColor = .lightGrayColor()
        
        let itemArray: Array<UITabBarItem> = tabBarController.tabBar.items! 
        
        for item: UITabBarItem in itemArray{
            item.image = item.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
            
            item.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(12), NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Normal)
            item.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(12), NSForegroundColorAttributeName: UIColor(red: 243/255, green: 231/255, blue: 33/255, alpha: 1)], forState: UIControlState.Selected)
            
        }
        
        application.applicationIconBadgeNumber = 0
        
        Fabric.with([Twitter()])
        
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
        // Override point for customization after application launch.
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        print("\n\nWE MADE IT")
        print(shortcutItem.type)
        
        let tabBarController = self.window?.rootViewController as! UITabBarController
        
        switch shortcutItem.type {
        case "com.kghs.events" :
            tabBarIndex = 0
            break
        case "com.kghs.staff" :
            tabBarIndex = 1
            break
        case "com.kghs.powerschool" :
            tabBarIndex = 2
            break
        case "com.kghs.twitter" :
            tabBarIndex = 3
            break
        default :
            break
        }
        tabBarController.selectedIndex = tabBarIndex
    }
    
}

public extension UIColor {
    public convenience init(rgba: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        if rgba.hasPrefix("#") {
            let index = rgba.startIndex.advancedBy(1)
            let hex = rgba.substringFromIndex(index)
            let scanner = NSScanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexLongLong(&hexValue) {
                switch (hex.characters.count) {
                case 3:
                    red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                    green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                    blue  = CGFloat(hexValue & 0x00F)              / 15.0
                case 4:
                    red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                    green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                    blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                    alpha = CGFloat(hexValue & 0x000F)             / 15.0
                case 6:
                    red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
                case 8:
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                default:
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
                }
            } else {
                print("Scan hex error")
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}
