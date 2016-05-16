//
//  SchoolTweets.swift
//  
//
//  Created by Collin DeWaters on 6/14/15.
//


import UIKit
import TwitterKit

class TimelineViewController: UIView{
    
    var twitterVC = TWTRTimelineViewController()
            
    init(frame: CGRect, dataSource: TWTRTimelineDataSource) {
        super.init(frame: frame)
        
        Twitter.sharedInstance().logInGuestWithCompletion { session, error in
            if let validSession = session {
                
                self.twitterVC.dataSource = dataSource
            } else {
                print("error: %@", error!.localizedDescription, terminator: "")
            }
        }
        twitterVC.tableView.contentInset = UIEdgeInsetsMake(60, 0, 60, 0)
        
        let tblView = twitterVC.tableView
        
        self.addSubview(tblView)
        tblView.center = self.center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SchoolTweets: UIViewController, TwitterAccountScrollViewDelegate {
    @IBOutlet weak var changeButton: UIBarButtonItem!
    
    var timelineVC: TimelineViewController!
    var client: TWTRAPIClient!
    var twit: TwitterAccountSelector!
    var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tabBarIndex = self.tabBarController!.selectedIndex
        dataManager.saveObjectInEntity("UserSettings", objects: [tabBarIndex, showStaffFavorites], keys: ["selectedTab", "showFavoritedStaff"], deletePrevious: true)
        
        client = Twitter.sharedInstance().APIClient
        let dataSource = TWTRUserTimelineDataSource(screenName: "KGHSFoxes", APIClient: client)
        
        
        titleLabel = UILabel(frame: CGRectMake(0, 0, 160, 300))
        titleLabel.text = "@KGHSFoxes"
        titleLabel.font = UIFont.systemFontOfSize(17)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.textAlignment = .Center
        self.navigationItem.titleView = titleLabel
      
        timelineVC = TimelineViewController(frame: view.frame, dataSource: dataSource)
        view.addSubview(timelineVC)
        timelineVC.center.y += -10
        
    }
    
    func selectorDidSelectAccount(name: String) {
        for acct in twit.accounts {
            if acct["username"] as! String == name {
                print("ACCOUNT WITH USERNAME \(acct["username"]) SELECTED")
                changeTwitterAccount(acct["username"] as! String)
                changeButton.title = "Change"
                twit.deactivate()
                break
            }
        }
    }
    
    func changeTwitterAccount(screenName: String){
        timelineVC.twitterVC.dataSource = TWTRUserTimelineDataSource(screenName: screenName, APIClient: client)
        titleLabel.text = "@\(screenName)"
        twit.deactivate()
    }
    
    @IBAction func changeAccount(sender: AnyObject) {
        if changeButton.title == "Change" {
            twit = TwitterAccountSelector(frame: self.view.frame, mainViewFrame: CGRectMake(0, 0, self.view.frame.width * 0.9, self.view.frame.height / 2.5))
            twit.center = self.view.center
            twit.mainView.selectDelegate = self
            self.view.addSubview(twit)
            changeButton.title = "Close"
        }
        else {
            twit.deactivate()
            changeButton.title = "Change"
        }
    }
    
}

@objc protocol TwitterAccountScrollViewDelegate{
    optional func selectorDidSelectAccount(username: String)
}

class TwitterAccountSelector: UIView {
    
    var accounts = [[String: AnyObject]]()
    var buttons = [String: UIImageView]()
    var mainView = TwitterAccountsScrollView()
    var background = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    
    init(frame: CGRect, mainViewFrame: CGRect) {
        super.init(frame: frame)
        //set background
        background.frame = frame
        background.alpha = 0
        self.addSubview(background)
        
        animator.simpleAnimationForDuration(0.25, animation: {
            self.background.alpha = 1
        })
        
        //Set main view
        mainView = TwitterAccountsScrollView(frame: mainViewFrame)
        mainView.center = self.center
        self.addSubview(mainView)
        mainView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
        mainView.clipsToBounds = true
        mainView.layer.cornerRadius = 25
        mainView.transform = CGAffineTransformMakeScale(0, 0)
        mainView.alpha = 0
        
        getTwitterAccounts({
            self.setUI(mainViewFrame)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func deactivate() {
        animator.simpleAnimationForDuration(0.12, animation: {
            self.background.alpha = 1
        })
        animator.complexAnimationForDuration(0.12, delay: 0, animation1: {
            self.mainView.transform = CGAffineTransformMakeScale(0.0000001, 0.0000001)
            self.mainView.alpha = 0
            }, animation2: {
                self.removeFromSuperview()
        })
    }
    
    func setUI(frame: CGRect) {
        let xIncrement = 2 * (frame.width / 6)
        let yIncrement = frame.height / 2
        var startX = frame.width / 6
        var startY = yIncrement / 2
        
        mainView.contentSize.height = frame.height / 2 * ceil(CGFloat((accounts.count) / 3))
        mainView.showsVerticalScrollIndicator = false
        mainView.showsHorizontalScrollIndicator = false
        
        for account in accounts {
            let acctButton = UIImageView(frame: CGRectMake(0, 0, 75, 75))
            acctButton.setImageWithURL(NSURL(string:account["profilePicURL"] as! String), usingActivityIndicatorStyle: .White)
            acctButton.contentMode = .ScaleAspectFill
            acctButton.clipsToBounds = true
            acctButton.layer.cornerRadius = 75 / 2
            acctButton.center = CGPointMake(startX, startY)
            buttons[account["username"] as! String] = acctButton
            
            let titleLabel = UILabel(frame: CGRectMake(0, 0, 130, 20))
            titleLabel.text = account["name"] as! String
            titleLabel.font = UIFont(name: "Avenir Next", size: 12)
            titleLabel.textAlignment = .Center
            titleLabel.center = CGPointMake(acctButton.center.x, acctButton.center.y + (acctButton.frame.height / 2) + 15)
            self.mainView.addSubview(titleLabel)
            
            self.mainView.addSubview(acctButton)
            if startX != (5 * frame.width) / 6 {
                startX += xIncrement
            }
            else {
                startY += yIncrement
                startX = frame.width / 6
            }
        }
        
        mainView.accountImageViews = buttons
        
        for view in mainView.subviews {
            view.center.y -= 10
        }
        
        UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.45, initialSpringVelocity: 10.0, options: UIViewAnimationOptions.AllowUserInteraction, animations: {
            self.mainView.transform = CGAffineTransformMakeScale(1.1, 1.1)
            self.mainView.alpha = 1
            }, completion: nil)
    }
    
    func getTwitterAccounts(completion: (()->Void)) {
        let url = NSURL(string: "http://www.pillocompany.com/kghs/getTwitterAccounts.php")!
        returnedJSONFromURL(url, completion: completion)
        
    }
    
    func returnedJSONFromURL(url: NSURL, completion: (()->Void)) {
        let request = NSURLRequest(URL: url)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request){ data, response, error in
            
            do {
                if let data = data {
                    self.accounts = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! [[String: AnyObject]]
                }
            }
            catch {
                print(error)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                completion()
            })
            
        }
        task.resume()
    }
}

class TwitterAccountsScrollView: UIScrollView {
    var accountImageViews = [String: UIImageView]()
    var selectDelegate: TwitterAccountScrollViewDelegate?
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInView(self)
            for key in Array<String>(accountImageViews.keys) {
                if accountImageViews[key]!.frame.contains(location) {
                    
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInView(self)
            if let del = selectDelegate {
                for key in Array<String>(accountImageViews.keys) {
                    if accountImageViews[key]!.frame.contains(location) {
                        del.selectorDidSelectAccount!(key)
                        print("SELECTED")
                    }
                }
            }
        }
    }
}
