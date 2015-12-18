//
//  FullScreenSlideshowViewController.swift
//  ImageSlideshow
//
//  Created by Petr Zvoníček on 31.08.15.
//  Copyright (c) 2015 Petr Zvonicek. All rights reserved.
//

import UIKit

public class FullScreenSlideshowViewController: UIViewController {
    
    public var slideshow: ImageSlideshow!
    public var pageSelected: ((page: Int) -> ())?
    public var initialPage: Int = 0
    public var inputs: [InputSource]?
    public var urls: [NSURL]?
    public var descriptionOfImage = [[String]]()
    public var urlsOfImages: [String]!
    public var pageControlHidden = false
    public var shareImage = false
    public var urlForShare: String!
    
    private (set)var index = 0
    
    var textView: ReadMoreTextView!
    var imageCountLabel: UILabel!
    var closeButton:UIButton!
    var shareImageButton: UIButton! = UIButton()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blackColor()
        slideshow = ImageSlideshow(frame: self.view.frame);
        slideshow.backgroundColor = UIColor.blackColor()
        slideshow.zoomEnabled = true
        slideshow.contentScaleMode = UIViewContentMode.ScaleAspectFit
        slideshow.pageControlPosition = PageControlPosition.InsideScrollView
        slideshow.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        if let urlsOfImages = urlsOfImages {
            slideshow.urlsOfImages = urlsOfImages
        }
        if let inputs = inputs {
            slideshow.setImageInputs(inputs)
        }
        
        if pageControlHidden {
            slideshow.pageControlPosition = PageControlPosition.Hidden
        }
        slideshow.frame = self.view.frame
        slideshow.slideshowInterval = 0
        slideshow.delegate = self
        self.view.addSubview(slideshow);
        let swipeDown = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeDown.direction = [.Down]
        let swipeUp = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeUp.direction = [.Up]
        self.view.addGestureRecognizer(swipeDown)
        self.view.addGestureRecognizer(swipeUp)
        
        if shareImage {
            shareImageButton = UIButton(frame: CGRectMake(5, 20, 40, 40))
            shareImageButton.setImage(UIImage(named: "ic_share"), forState: .Normal)
            shareImageButton.addTarget(self, action: Selector("shareImage:"), forControlEvents: .TouchUpInside)
            shareImageButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            shareImageButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            shareImageButton.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin
            self.view.addSubview(shareImageButton)
        }
        
        closeButton = UIButton(frame: CGRectMake(CGRectGetWidth(self.view.frame) - 45, 20, 40, 40))
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            closeButton.frame = CGRectMake(CGRectGetWidth(self.view.frame) - 50, 20, 40, 40)
        }
        
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        closeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        closeButton.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin
        closeButton.setImage(UIImage(named: "ic_close"), forState: UIControlState.Normal)
        closeButton.addTarget(self, action: "close", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(closeButton)
        setTextView()
    }
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.Down:
                self.dismissViewControllerAnimated(true, completion: nil)
            case UISwipeGestureRecognizerDirection.Up:
                self.dismissViewControllerAnimated(true, completion: nil)
            default:
                break
            }
        }
    }
    
    func setTextView() {
        
        imageCountLabel = UILabel(frame: CGRect(x:20, y: slideshow.frame.size.height - 25, width: 100, height: 20))
        imageCountLabel.textColor = UIColor.whiteColor()
        imageCountLabel.numberOfLines = 0
        imageCountLabel.font = UIFont(name: "FiraSans-Regular", size: 12)
        if (initialPage > descriptionOfImage.count) {
            initialPage = 1
        }
        imageCountLabel.text = "\(initialPage)/\(self.descriptionOfImage.count)"
 
        self.view.addSubview(imageCountLabel)
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            textView = ReadMoreTextView(frame: CGRect(x:0, y: slideshow.frame.size.height - 110, width: self.view.frame.size.width, height: 60))
            textView.font = UIFont(name: "FiraSans-Regular", size: 12)
        }else{
            textView = ReadMoreTextView(frame: CGRect(x:0, y: slideshow.frame.size.height - 110, width: self.view.frame.size.width, height: 100))
            textView.font = UIFont(name: "FiraSans-Regular", size: 16)
        }

        self.index = initialPage-1
        if descriptionOfImage.count >= initialPage {
            textView.text = descriptionOfImage[initialPage-1][0] as String
        }

        textView.maximumNumberOfLines = 2
        textView.tag = 101
        textView.trimText = ""
        textView.shouldTrim = true
        textView.userInteractionEnabled = true
        textView.selectable = false
        textView.backgroundColor = UIColor.clearColor()
        textView.textColor = UIColor.whiteColor()
        textView.scrollEnabled = false
        let textTap = UITapGestureRecognizer(target: self, action: Selector("textTapped"))
        textView.addGestureRecognizer(textTap)
        
        if let view = self.view.superview?.viewWithTag(101) {
            view.removeFromSuperview()
        }
        
        self.view.addSubview(textView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        let textViewCenterXConts = NSLayoutConstraint(item: textView, attribute: NSLayoutAttribute.CenterX, relatedBy: .Equal, toItem: view, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: textView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 10)
        let trailingConstraint = NSLayoutConstraint(item: textView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: -10)
        let topConstraint = NSLayoutConstraint(item: textView, attribute: .Top, relatedBy: .LessThanOrEqual, toItem: self.slideshow, attribute: .Bottom, multiplier: 1.0, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: textView, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: -40)
        self.view.addConstraints([textViewCenterXConts, leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    }
    
    override public func viewWillAppear(animated: Bool) {
        slideshow.setScrollViewPage(self.initialPage, animated: false)
    }
    
    func shareImage(sender:UIButton) {
        var activityItems: [AnyObject]?
        let title = descriptionOfImage[index][0]
        var image: UIImage?

        let imageV:UIImageView? = self.slideshow.slideshowItems[self.index].imageView
        if imageV != nil {
            image = imageV!.image
        }
        
        if urlForShare != nil {
            let url = NSURL(string: urlForShare)
            if (image != nil) {
                activityItems = [title, image!, url!]
            } else {
                activityItems = [title]
            }

            let activityVC = UIActivityViewController(activityItems: activityItems! as [AnyObject], applicationActivities: nil)
            if let presentationController = activityVC.popoverPresentationController {
                presentationController.sourceRect = sender.frame
            }
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    func close() {
        if let pageSelected = pageSelected {
            pageSelected(page: slideshow.scrollViewPage)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textTapped() {
        UIView.animateWithDuration(0.5, delay: 0.0, options: [UIViewAnimationOptions.CurveEaseInOut, UIViewAnimationOptions.AllowUserInteraction], animations: {
            self.textView.trimText = ""
            self.textView.shouldTrim = false
            self.textView.text = String(self.descriptionOfImage[self.index][0])
            self.textView.resetText()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}
extension FullScreenSlideshowViewController: ImageSlideshowItemDelegate {
    public func twoTap(isZoomed: Bool) {
        if isZoomed {
            UIView.animateWithDuration(0.5, animations: {
                self.closeButton.alpha = 0.0
                self.imageCountLabel.alpha = 0.0
                self.textView.alpha = 0.0
                self.shareImageButton.alpha = 0.0
            })
        }else{
            UIView.animateWithDuration(0.5, animations: {
                self.closeButton.alpha = 1.0
                self.imageCountLabel.alpha = 1.0
                self.textView.alpha = 1.0
                self.shareImageButton.alpha = 1.0
            })
        }
    }
}
extension FullScreenSlideshowViewController: ImageSldeShowDelegate {
    public func didChange(index: Int) {
        if slideshow.slideshowItems[index].mydelegate == nil {
            slideshow.slideshowItems[index].mydelegate = self
        }
 
        self.closeButton.alpha = 1.0
        self.imageCountLabel.alpha = 1.0
        self.textView.alpha = 1.0
        self.shareImageButton.alpha = 1.0
        imageCountLabel.text = "\(index+1)/\(self.descriptionOfImage.count)"
        if descriptionOfImage.count > index {
            self.index = index
            UIView.animateWithDuration(1.0, delay: 0.0, options: [UIViewAnimationOptions.CurveEaseInOut, UIViewAnimationOptions.AllowUserInteraction], animations: {
                self.textView.text = String(self.descriptionOfImage[index][0])
            }, completion: nil)
            
        }
    }
}

