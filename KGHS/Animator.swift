//
//  Animator.swift
//  KGHS
//
//  Created by Collin DeWaters on 6/22/15.
//  Copyright © 2015 Pillo. All rights reserved.
//

import UIKit


public class Animator: NSObject {
    
    func simpleAnimationForDuration(duration: NSTimeInterval, animation: (() -> Void)){
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        animation()
        UIView.commitAnimations()
    }
    
    func complexAnimationForDuration(duration: NSTimeInterval, delay: NSTimeInterval, animation1: (() ->Void), animation2: (() ->Void)){
        UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            ()->Void in
            animation1()
            }, completion: {
                Bool in
                if true{
                    animation2()
                }
        })
        
    }
    
    func caBasicAnimation(from: Double, to: Double, repeatCount: Float, keyPath: String, duration: CFTimeInterval) -> CABasicAnimation{
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        animation.repeatCount = repeatCount
        animation.removedOnCompletion = true
        
        return animation
    }
    
}