//
//  ImageSlideshow.swift
//  ImageSlideshow
//
//  Created by Petr Zvoníček on 30.07.15.
//  Copyright (c) 2015 Petr Zvonicek. All rights reserved.
//

import UIKit
import Kingfisher

@objc public protocol InputSource {
    func setToImageView(imageView: UIImageView, load: Bool);
}

public class ImageSource: NSObject, InputSource {
    var image: UIImage
    var imageString: String
    
    public init(image: UIImage) {
        self.image = image
        self.imageString = ""
    }
    
    public init?(imageString: String) {
        if let imageObj = UIImage(named: "back") {
            self.imageString = imageString
            self.image = imageObj
            super.init()
        } else {
            self.imageString = ""
            // working around Swift 1.2 failure initializer bug
            self.image = UIImage(named: "back")!
            super.init()
            return nil
        }
    }
    
    @objc public func setToImageView(imageView: UIImageView, load: Bool) {
        if load {
            let url_str = imageString
            if let url = NSURL(string: url_str) {
                imageView.kf_setImageWithURL(url, placeholderImage: nil, optionsInfo: nil, completionHandler: {
                    (image, error, cacheType, imageURL) -> () in
                    UIView.animateWithDuration(0.5, delay: 0, options: .CurveEaseIn, animations: { () -> Void in
                        imageView.image = image
                        }, completion: nil)
                    })
            }
            /*imageView.sd_setImageWithURL(NSURL(string: url_str), placeholderImage: nil) {
                    (image:UIImage!, error:NSError!, type:SDImageCacheType, url:NSURL!) -> Void in
                    if error == nil {
                        imageView.image = image
                    }
            }*/
        }
    }
}

@objc public enum PageControlPosition: Int {
    case Hidden
    case InsideScrollView
    case UnderScrollView
}

@objc public protocol ImageSldeShowDelegate: class {
    func didChange(index:Int)
}

public class ImageSlideshow: UIView, UIScrollViewDelegate {
    
    public let scrollView = UIScrollView()
    public let pageControl = UIPageControl()
    public var urlsOfImages = [String]()
    
    public weak var delegate: ImageSldeShowDelegate?
    // state properties
    
    public var pageControlPosition = PageControlPosition.InsideScrollView {
        didSet {
            setNeedsLayout()
            layoutScrollView()
        }
    }
    public private(set) var currentPage: Int = 0 {
        didSet {
            pageControl.currentPage = currentPage;
        }
    }
    public var currentSlideshowItem: ImageSlideshowItem? {
        get {
            if (self.slideshowItems.count > self.scrollViewPage) {
                return self.slideshowItems[self.scrollViewPage]
            } else {
                return nil
            }
        }
    }
    public private(set) var scrollViewPage: Int = 0
    
    // preferences
    public var circular = true
    public var zoomEnabled = false
    public var slideshowInterval = 0.0 {
        didSet {
            self.slideshowTimer?.invalidate()
            self.slideshowTimer = nil
            setTimerIfNeeded()
        }
    }
    public var contentScaleMode: UIViewContentMode = UIViewContentMode.ScaleAspectFit {
        didSet {
            for view in slideshowItems {
                view.imageView.contentMode = contentScaleMode
            }
        }
    }
    
    private var slideshowTimer: NSTimer?
    public private(set) var images = [InputSource]()
    private var scrollViewImages = [InputSource]()
    public private(set) var slideshowItems = [ImageSlideshowItem]()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        self.autoresizesSubviews = true
        self.clipsToBounds = true
        
        scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 50.0)
        scrollView.delegate = self
        scrollView.pagingEnabled = true
        scrollView.bounces = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.autoresizingMask = self.autoresizingMask

        self.addSubview(scrollView)
        self.addSubview(pageControl)
        setTimerIfNeeded()
        layoutScrollView()
    }
    
    override public func layoutSubviews() {
        
        pageControl.hidden = pageControlPosition == .Hidden
        pageControl.frame = CGRectMake(0, 0, self.frame.size.width, 10)
        pageControl.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height - 32.0)
        
        layoutScrollView()
    }
    
    func layoutScrollView() {
        let scrollViewBottomPadding: CGFloat = self.pageControlPosition == .UnderScrollView ? 30.0 : 0.0
        scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - scrollViewBottomPadding)
        
        self.scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * CGFloat(scrollViewImages.count), scrollView.frame.size.height)

        var i = 0
        for view in self.slideshowItems {
            view.frame = CGRectMake(scrollView.frame.size.width * CGFloat(i), 0, scrollView.frame.size.width, scrollView.frame.size.height)
            i++
        }
        self.scrollView.zoomScale = 0.0
        self.scrollView.maximumZoomScale = 0.0
        setCurrentPage(currentPage, animated: false)
        if urlsOfImages.count > 0  {
            currentSlideshowItem?.imageUrl = urlsOfImages[currentPage]
        }
    }
    
    func reloadScrollView() {
        for view in self.slideshowItems {
            view.removeFromSuperview()
        }
        self.slideshowItems = []
                
        var i = 0
        for image in scrollViewImages {
            
            let item = ImageSlideshowItem(image: image, zoomEnabled: self.zoomEnabled)
            item.imageView.contentMode = self.contentScaleMode
            slideshowItems.append(item)
            scrollView.addSubview(item)
            i++
        }
        
        if circular && (scrollViewImages.count > 1) {
            scrollViewPage = 1
            scrollView.scrollRectToVisible(CGRectMake(scrollView.frame.size.width, 0, scrollView.frame.size.width, scrollView.frame.size.height), animated: false)
        } else {
            scrollViewPage = 0
        }
    }
    
    //MARK: image setting
    
    public func setImageInputs(inputs: [InputSource]) {
        self.images = inputs
        self.pageControl.numberOfPages = inputs.count;
        
        // in circular mode we add dummy first and last image to allow smooth scrolling
        if circular && images.count > 1 {
            var scImages = [InputSource]()
            
            if let last = images.last {
                scImages.append(last)
            }
            scImages += images
            if let first = images.first {
                scImages.append(first)
            }
            
            self.scrollViewImages = scImages
        } else {
            self.scrollViewImages = images;
        }
        
        reloadScrollView()
        setTimerIfNeeded()
    }
    
    //MARK: paging methods
    
    public func setCurrentPage(currentPage: Int, animated: Bool) {
        var pageOffset = currentPage
        if circular {
            pageOffset += 1
        }
        
        self.setScrollViewPage(pageOffset, animated: animated)
    }
    
    public func setScrollViewPage(scrollViewPage: Int, animated: Bool) {
        if scrollViewPage < scrollViewImages.count {
            self.scrollView.scrollRectToVisible(CGRectMake(scrollView.frame.size.width * CGFloat(scrollViewPage), 0, scrollView.frame.size.width, scrollView.frame.size.height), animated: animated)
            self.setCurrentPageForScrollViewPage(scrollViewPage)
        }
    }
    
    private func setTimerIfNeeded() {
        if slideshowInterval > 0 && scrollViewImages.count > 1 && slideshowTimer == nil {
            slideshowTimer = NSTimer.scheduledTimerWithTimeInterval(slideshowInterval, target: self, selector: "slideshowTick:", userInfo: nil, repeats: true)
        }
    }
    
    func slideshowTick(timer: NSTimer) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        var nextPage = page + 1
        
        if !circular && page == scrollViewImages.count - 1 {
            nextPage = 0
        }
        
        self.scrollView.scrollRectToVisible(CGRectMake(scrollView.frame.size.width * CGFloat(nextPage), 0, scrollView.frame.size.width, scrollView.frame.size.height), animated: true)

        self.setCurrentPageForScrollViewPage(nextPage);
        self.delegate?.didChange(nextPage)
    }
    
    public func setCurrentPageForScrollViewPage(page: Int) {
        if (scrollViewPage != page) {
            // current page has changed, zoom out this image
            if (slideshowItems.count > scrollViewPage) {
                slideshowItems[scrollViewPage].zoomOut()
            }
        }
        
        scrollViewPage = page
        
        if (circular) {
            if page == 0 {
                // first page contains the last image
                currentPage = Int(images.count) - 1
            } else if page == scrollViewImages.count - 1 {
                // last page contains the first image
                currentPage = 0
            } else {
                currentPage = page - 1
            }
        } else {
            currentPage = page
        }

    }
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if slideshowTimer?.valid != nil {
            slideshowTimer?.invalidate()
            slideshowTimer = nil
        }
        setTimerIfNeeded()
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        var index = 0
        setCurrentPageForScrollViewPage(page);
        if page == 0 {
            // first page contains the last image
            index = Int(images.count) - 1
        } else if page == scrollViewImages.count - 1 {
            // last page contains the first image
            index = 0
        } else {
            index = page - 1
        }
        if urlsOfImages.count > 0 {
            currentSlideshowItem?.imageUrl = urlsOfImages[index]
        }
        self.delegate?.didChange(index)
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if circular {
            let regularContentOffset = scrollView.frame.size.width * CGFloat(images.count)
            
            if (scrollView.contentOffset.x >= scrollView.frame.size.width * CGFloat(images.count + 1)) {
                scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x - regularContentOffset, 0)
                
            } else if (scrollView.contentOffset.x < 0) {
                scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x + regularContentOffset, 0)
            }
        }
    }
}