//
//  StaffPageViewController.swift
//  KGHS
//
//  Created by Collin DeWaters on 3/30/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import UIKit
import MediaPlayer

class StaffPageViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var webView: UIWebView!
    var url = String()
    var name = String()
    var contentSize = Int64()
    var webdata = NSMutableData()
    var page: NSURL!
        
    override func viewDidLoad() {
        super.viewDidLoad()
 
        //Set the title label for the navbar
        let titleLabel = UILabel(frame: CGRectMake(0, 0, 160, 300))
        titleLabel.text = "\(name)'s Webpage"
        titleLabel.font = UIFont.systemFontOfSize(17)
        titleLabel.textColor = UIColor(red: 243/255, green: 231/255, blue: 33/255, alpha: 1)
        titleLabel.textAlignment = .Center
        
        self.navigationItem.titleView = titleLabel
        
        view.backgroundColor = UIColor(red: 187/255, green: 222/255, blue: 250/255, alpha: 1)
        
        webView.transform = CGAffineTransformMakeScale(0, 0)
        webView.delegate = self
        
        //Open url
        page = NSURL(string: url)
        let requestPage = NSURLRequest(URL: page!)
        webView.loadRequest(requestPage)
        
        webView.scalesPageToFit = true
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
            self.webView.transform = CGAffineTransformMakeScale(0, 0)
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
            self.webView.transform = CGAffineTransformMakeScale(1, 1)
            self.activity.transform = CGAffineTransformMakeScale(0, 0)
            }, completion: {
                Bool in
                if true{
                    self.simpleAnimationForDuration(0.25, animation: {
                        self.activity.stopAnimating()
                        self.webView.transform = CGAffineTransformMakeScale(1, 1)
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
