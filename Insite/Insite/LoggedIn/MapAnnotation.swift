//
//  MapAnnotation.swift
//  Insite
//
//  Created by Varun Iyer on 3/11/20.
//  Copyright © 2020 spott. All rights reserved.
//

import UIKit
import Mapbox
import SnapKit

class MapAnnotation: MGLPointAnnotation {
    var type: String?
    var place: Place!
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PlaceAnnotationView: MGLAnnotationView {
    var placeImageView: UIImageView!
    var placeLabel: UILabel!
    var place: Place!
    var animator: UIViewPropertyAnimator!
    
    convenience init (reuseIdentifier: String?, place: Place)
    {
        self.init(reuseIdentifier: reuseIdentifier)
        self.alpha = 0
        self.place = place
        
        self.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        
        placeImageView = UIImageView(image: place.image)
        placeImageView.contentMode = .scaleAspectFill
        placeImageView.layer.cornerRadius = 45/2
        placeImageView.clipsToBounds = true
        
        placeImageView.layer.borderColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0).cgColor
        placeImageView.layer.borderWidth = 2
        placeImageView.frame = CGRect(x: self.frame.width/2 - 45/2, y: 0, width: 45, height: 45)
        
        addSubview(placeImageView)
        
        placeLabel = UILabel()
        placeLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.bold)
        placeLabel.textColor = .white
        placeLabel.textAlignment = .center
        placeLabel.alpha = 0.9
        placeLabel.text = place.name.lowercased()
        
        addSubview(placeLabel)
        placeLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(placeImageView.snp.centerX)
            make.top.equalTo(placeImageView.snp.bottom).offset(5)
        }
        
        showAnimation()
    }
    
    func showAnimation() {
        animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeOut, animations: {
            self.alpha = 1
        })
        
        animator.startAnimation()
    }
    
    func selectAnimation() {
        placeImageView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        placeLabel.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        UIView.animate(withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.3,
            initialSpringVelocity: 6.0,
            options: .allowUserInteraction,
            animations: { [weak self] in
                self?.placeImageView.transform = .identity
                self?.placeLabel.transform = .identity
            },
            completion: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
      
        if animator != nil {
            animator.stopAnimation(true)
        }
        self.alpha = 0
        
        animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeOut, animations: {
            self.alpha = 1
        })
        
        animator.startAnimation()
    }
    
    override init (reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
