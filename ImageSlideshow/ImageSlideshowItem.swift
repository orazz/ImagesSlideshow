//
//  ZoomablePhotoView.swift
//  PhotoCollectionView
//
//  Created by Petr Zvoníček on 30.07.15.
//  Copyright (c) 2015 Petr Zvonicek. All rights reserved.
//

import UIKit
//import SDWebImage

@objc public protocol ImageSlideshowItemDelegate: class {
    func twoTap(isZoomed:Bool)
}

public class ImageSlideshowItem: UIScrollView, UIScrollViewDelegate {
    
    public weak var mydelegate: ImageSlideshowItemDelegate?
    
    var imageView = UIImageView()
    
    let zoomEnabled: Bool
    
    private var myContext = 0
    
    var imageUrl: String! {
        didSet {
            if let url = NSURL(string: imageUrl) {
                imageView.kf_showIndicatorWhenLoading = true
                imageView.kf_setImageWithURL(url, placeholderImage: nil, optionsInfo: nil, completionHandler: {
                    [weak self](image, error, cacheType, imageURL) -> () in
                    UIView.animateWithDuration(0.5, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
                        self?.imageView.alpha = 1
                        }, completion: nil)
                    })
                
            }
            //if self.imageView.image == nil {
                /*imageView.setImageWithURL(NSURL(string: imageUrl), completed: { [weak self]
                    (image:UIImage!, error:NSError!, type:SDImageCacheType, url:NSURL!) -> Void in
                    self?.imageView.alpha = 0.0
                    if error != nil {
                        self?.imageView.image = UIImage(named: "back")
                    }
                    self?.calculateMaximumScale()
                    self?.layoutSubviews()
                    if type.rawValue == 0 {
                        UIView.animateWithDuration(0.3, animations: { () -> Void in
                            self?.imageView.alpha = 1.0
                        })
                    }else{
                        self?.imageView.alpha = 1.0
                    }
                }, usingActivityIndicatorStyle: .WhiteLarge)*/
            
           // }
        }
    }
    
    init(image: InputSource, zoomEnabled: Bool) {
        self.zoomEnabled = zoomEnabled
        super.init(frame: CGRectNull)
        imageView.addObserver(self, forKeyPath: "image", options: .New, context: &myContext)
        image.setToImageView(imageView, load: false)
        
        if imageUrl == nil {
            image.setToImageView(imageView, load: true)
        }
        
        imageView.clipsToBounds = true
        setPictoCenter()
        
        self.delegate = self
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.addSubview(imageView)
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = calculateMaximumScale()
        
        let tap = UITapGestureRecognizer(target: self, action: "tapZoom")
        tap.numberOfTapsRequired = 2
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(tap)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        imageView.removeObserver(self, forKeyPath: "image", context: &myContext)
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            self.maximumZoomScale = calculateMaximumScale()
        } else {
            super.observeValueForKeyPath(keyPath!, ofObject: object!, change: change!, context: context)
        }
    }
    
    func isZoomed() -> Bool {
        return self.zoomScale != self.minimumZoomScale
    }
    
    func zoomOut() {
        self.setZoomScale(minimumZoomScale, animated: false)
    }
    
    func tapZoom() {
        if isZoomed() {
            self.setZoomScale(minimumZoomScale, animated: true)
        } else {
            self.setZoomScale(maximumZoomScale, animated: true)
        }
        self.mydelegate?.twoTap(isZoomed())
    }
    
    private func screenSize() -> CGSize {
        return CGSize(width: frame.width, height: frame.height)
    }
    
    private func calculatePictureFrame() {
        let boundsSize: CGSize = self.bounds.size
        var frameToCenter: CGRect = imageView.frame
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
    
    private func calculatePictureSize() -> CGSize {
        if let image = imageView.image {
            let picSize = image.size
            let picRatio = picSize.width / picSize.height
            let screenRatio = screenSize().width / screenSize().height
            
            if (picRatio > screenRatio){
                return CGSize(width: screenSize().width, height: screenSize().width / picSize.width * picSize.height)
            } else {
                return CGSize(width: screenSize().height / picSize.height * picSize.width, height: screenSize().height)
            }
        } else {
            return CGSize(width: screenSize().width, height: screenSize().height)
        }
    }
    
    private func calculateMaximumScale() -> CGFloat {
        if let image = imageView.image {
            return image.size.width / calculatePictureSize().width
        } else {
            return 1.0
        }
    }
    
    private func setPictoCenter(){
        var intendHorizon = (screenSize().width - imageView.frame.width ) / 2
        var intendVertical = (screenSize().height - imageView.frame.height ) / 2
        intendHorizon = intendHorizon > 0 ? intendHorizon : 0
        intendVertical = intendVertical > 0 ? intendVertical : 0
        contentInset = UIEdgeInsets(top: intendVertical, left: intendHorizon, bottom: intendVertical, right: intendHorizon)
    }
    
    private func isFullScreen() -> Bool{
        if (imageView.frame.width >= screenSize().width && imageView.frame.height >= screenSize().height){
            return true
        } else {
            return false
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if (!zoomEnabled) {
            imageView.frame.size = frame.size;
        } else if (!isZoomed()) {
            imageView.frame.size = calculatePictureSize()
            setPictoCenter()
        }
        
        if (self.isFullScreen()) {
            self.clearContentInsets()
        } else {
            setPictoCenter()
        }
        
        self.maximumZoomScale = calculateMaximumScale()
    }
    
    func clearContentInsets() {
        self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    //MARK: UIScrollViewDelegate
    
    public func scrollViewDidZoom(scrollView: UIScrollView) {
        setPictoCenter()
    }
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.zoomEnabled ? imageView : nil;
    }
    
}
