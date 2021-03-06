//
//  ViewController.swift
//  ImageSlideshow
//
//  Created by Atakishiyev Orazdurdy on 12/15/15.
//  Copyright © 2015 AsmanOky. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageSlideshow: ImageSlideshow!
    @IBOutlet weak var imageView1: UIImageView!
    
    var transitionDelegate: ZoomAnimatedTransitioningDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var imagesPath = [ImageSource]()
        imagesPath.append(ImageSource(imageString: "")!)
        imagesPath.append(ImageSource(imageString: "https://pp.vk.me/c543105/v543105254/a5c7/wyt-inDVeiY.jpg")!)
        
        let recognizer = UITapGestureRecognizer(target: self, action: "click:")
        imageSlideshow.addGestureRecognizer(recognizer)
        let recognizer1 = UITapGestureRecognizer(target: self, action: "fullScreen:")
        imageView1.addGestureRecognizer(recognizer1)

        imageSlideshow.slideshowInterval = 5.0
        imageSlideshow.circular = true
        imageSlideshow.pageControlPosition = PageControlPosition.InsideScrollView
        imageSlideshow.pageControl.currentPageIndicatorTintColor = UIColor.lightGrayColor()
        imageSlideshow.pageControl.pageIndicatorTintColor = UIColor.whiteColor()
        imageSlideshow.setImageInputs(imagesPath)

    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func click(sender: UIGestureRecognizer) {
       let ctr = FullScreenSlideshowViewController()
        ctr.pageSelected = {(page: Int) in
            self.imageSlideshow.setScrollViewPage(page, animated: false)
        }
        ctr.descriptionOfImage = [["s1"], ["s2"]]
        ctr.initialPage = imageSlideshow.scrollViewPage
        ctr.inputs = imageSlideshow.images
        self.transitionDelegate = ZoomAnimatedTransitioningDelegate(slideshowView: imageSlideshow);
        ctr.transitioningDelegate = self.transitionDelegate!
        self.presentViewController(ctr, animated: true, completion: nil)
    }

    func fullScreen(sender: UIGestureRecognizer) {
        let ctr = FullScreenSlideshowViewController()
        ctr.descriptionOfImage = [ ["Ищете вдохновения? Нужны свежие решения в оформлении помещения? Хотите обновить интерьер вашего дома? Тогда вы пришли по адресу. В нашей группе Дизайн интерьера, ремонт - Вира-АртСтрой вы найдете много необычных и интересных идей для современного декора или дизайна помещений. Присоединяйтесь к нам! Будет интересно."], ["По воссоединяется с семьей: новый дублированный трейлер мультфильма «Кунг-фу Панда 3»"], ["s3"], ["s4"]]
        let imagesPath = [ImageSource](count: 4, repeatedValue: ImageSource(imageString: "")!)
        ctr.inputs = imagesPath
        ctr.initialPage = 1
        ctr.urlForShare = "s"
        ctr.shareImage = true
        
        ctr.urlsOfImages = ["https://pp.vk.me/c625621/v625621656/2521f/gNUXgiY4sSE.jpg", "http://media.ashgabat2017.gov.tm/thumb/870/382/media/sliders/pictures/40/original_3.jpg", "http://media.ashgabat2017.gov.tm/thumb/870/382/media/sliders/pictures/42/original_5.jpg", "http://media.ashgabat2017.gov.tm/thumb/870/382/media/sliders/pictures/39/original_2.jpg"]
        self.presentViewController(ctr, animated: true, completion: nil)
    }

}

