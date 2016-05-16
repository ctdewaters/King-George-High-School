//
//  PSViewController.swift
//  KGHS
//
//  Created by Collin DeWaters on 5/3/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import UIKit

class PSViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var web: UIWebView!
    var webdata = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarIndex = self.tabBarController!.selectedIndex
        dataManager.saveObjectInEntity("UserSettings", objects: [tabBarIndex, showStaffFavorites], keys: ["selectedTab", "showFavoritedStaff"], deletePrevious: true)
        
        view.backgroundColor = UIColor(red: 187/255, green: 222/255, blue: 250/255, alpha: 1)
        
        web.transform = CGAffineTransformMakeScale(0, 0)
        web.delegate = self
        
        //Open url
        let page = NSURL(string: "https://ps.kgcs.k12.va.us/public/")
        let requestPage = NSURLRequest(URL: page!)
        web.loadRequest(requestPage)
        web.scalesPageToFit = false
        web.scrollView.contentInset.top = -110
        web.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.85)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func webViewDidStartLoad(webView: UIWebView) {
        self.activity.startAnimating()
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: [], animations: {
            ()->Void in
            self.web.transform = CGAffineTransformMakeScale(0, 0)
            self.activity.transform = CGAffineTransformMakeScale(1.25, 1.25)
            }, completion: {
                Bool in
                if true{
                    self.simpleAnimationForDuration(0.25, animation: {
                        self.activity.transform = CGAffineTransformMakeScale(1, 1)
                    })
                }
        })
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: [], animations: {
            ()->Void in
            self.web.transform = CGAffineTransformMakeScale(1, 1)
            self.activity.transform = CGAffineTransformMakeScale(0, 0)
            }, completion: {
                Bool in
                if true{
                    self.simpleAnimationForDuration(0.25, animation: {
                        self.activity.stopAnimating()
                        self.web.transform = CGAffineTransformMakeScale(1, 1)
                    })
                }
        })
    }
    
    func simpleAnimationForDuration(duration: NSTimeInterval, animation: (() -> Void)){
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        animation()
        UIView.commitAnimations()
    }
    

}
