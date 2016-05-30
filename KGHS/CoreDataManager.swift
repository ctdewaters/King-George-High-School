//
//  CoreDataManager.swift
//  KGHS
//
//  Created by Collin DeWaters on 4/15/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import Foundation
import CoreData
import UIKit

public class DataManager: NSObject {
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.CDWApps.KGHS" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("KGHS", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        
        
        let containerPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.KGHS.Stuff")?.path
        let sqlitePath = NSString(format: "%@/%@", containerPath!, "KGHS")
        let url = NSURL(fileURLWithPath: sqlitePath as String)
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        var error: NSError? = nil
        
        var failureReason = "There was an error creating or loading the application's saved data."
        let mOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true]
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: mOptions)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }

    
    //MARK: - Load and Save Methods
    
    func loadObjectInEntity(entity: String) -> NSArray?{
        
        let context: NSManagedObjectContext = self.managedObjectContext!
        
        let request = NSFetchRequest(entityName: entity)
        request.returnsObjectsAsFaults = false
        
        let results: NSArray = try! context.executeFetchRequest(request)
        
        return results
    }
    
    //save new object
    func saveObjectInEntity(entity: String, objects: Array<NSObject>?, keys: Array<String>?, deletePrevious: Bool){
        let context: NSManagedObjectContext = self.managedObjectContext!
        
        //delete
        if deletePrevious == true{
            let fetch = NSFetchRequest(entityName: entity)
            fetch.returnsObjectsAsFaults = false
            let events: NSArray = try! context.executeFetchRequest(fetch)
            for event in events{
                context.deleteObject(event as! NSManagedObject)
                print("Event deleted")
            }
        }
        
        let entDisc = NSEntityDescription.insertNewObjectForEntityForName(entity, inManagedObjectContext: context) 
        if objects != nil{
            for (var i = 0; i < objects!.count; i++){
                let key = keys![i]
                let object = objects![i]
                entDisc.setValue(object, forKey: key)
            }
        
            do {
                try context.save()
            } catch _ {
            }
        }
    }
    
    func deleteObjectsInEntity(entity: String){
        let context: NSManagedObjectContext = self.managedObjectContext!
        let fetch = NSFetchRequest(entityName: entity)
        fetch.returnsObjectsAsFaults = false
        let events: NSArray = try! context.executeFetchRequest(fetch)
        for event in events{
            context.deleteObject(event as! NSManagedObject)
        }
        do {
            try context.save()
        } catch _ {
        }
    }
    
    func deleteObjectInEntity(entity: String, object: String, key: String){
        let context = self.managedObjectContext!
        let fetch = NSFetchRequest(entityName: entity)
        fetch.returnsObjectsAsFaults = false
        let objects = try! context.executeFetchRequest(fetch)
        for o in objects{
            let objectKey = o.valueForKey(key) as! String
            if objectKey == object{
                context.deleteObject(o as! NSManagedObject)
            }
        }
        do {
            try context.save()
        } catch _ {
        }
    }
}
