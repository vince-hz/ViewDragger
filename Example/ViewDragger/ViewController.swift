//
//  ViewController.swift
//  ViewDragger
//
//  Created by xuyunshi on 02/20/2023.
//  Copyright (c) 2023 xuyunshi. All rights reserved.
//

import UIKit
import ViewDragger

let frameInExampleContainer = CGRect(x: 0, y: 0, width: 100, height: 100)
class ExampleContainer: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    func updateAnimateButton(expand: Bool) {
        let imageName = expand ? "arrow.up.backward.and.arrow.down.forward" : "arrow.down.right.and.arrow.up.left"
        if #available(iOS 13.0, *) {
            let img = UIImage(systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(weight: .heavy))
            animateButton.setImage(img, for: .normal)
        }
    }
    
    override func layoutSubviews() {
        descriptionLabel.frame = .init(x: 0, y: bounds.height - 44, width: bounds.width, height: 44)
        super.layoutSubviews()
    }
    
    func setupViews() {
        backgroundColor = .lightGray
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemGray.cgColor
        addSubview(descriptionLabel)
        
        addSubview(moveableContent)
        moveableContent.isUserInteractionEnabled = true
        moveableContent.addSubview(animateButton)
        moveableContent.backgroundColor = .black
        moveableContent.frame = frameInExampleContainer
        animateButton.frame = frameInExampleContainer.insetBy(dx: 33, dy: 33)
        
        animateButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        animateButton.tintColor = .black
        updateAnimateButton(expand: true)
    }
    
    lazy var animateButton = UIButton(type: .system)
    lazy var moveableContent = UIImageView(image: UIImage(named: "mask"))
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        return label
    }()
}

class ViewController: UIViewController {
    @IBOutlet var gestureAxisSegmentControl: UISegmentedControl!
    @IBOutlet var animationTypeSegmentControl: UISegmentedControl!
    @IBOutlet var dragSyleSegmentControl: UISegmentedControl!
    @IBOutlet var exampleView: ExampleContainer!
    var dragger: ViewDragger!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    var oldBound = CGRect.zero
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if view.bounds != oldBound {
            oldBound = view.bounds
            DispatchQueue.main.async {
                self.updateDragger()
                
                if self.exampleView.moveableContent.superview == self.view {
                    self.dragger.travel(to: .forwards, animated: true)
                }
            }
        }
    }
    
    func updateDragger() {
        let isfree = dragSyleSegmentControl.selectedSegmentIndex == 1
        let animationType: AnimationType = animationTypeSegmentControl.selectedSegmentIndex == 0 ? .frame : .tranform
        let gestureAxis: GestureAxis = gestureAxisSegmentControl.selectedSegmentIndex == 0 ? .vertical : .horizontal
        
        if isfree {
            dragger.updateWithFreeDrag(targetDraggingView: view)
        } else {
            dragger.updateTwoViewsDrag(backwardsSuperView: exampleView,
                                       forwardsSuperView: view,
                                       targetDraggingView: nil,
                                       backwardsViewFrame: frameInExampleContainer,
                                       forwardsViewFrame: view.bounds,
                                       gestureAxis: gestureAxis,
                                       animationType: animationType)
        }
    }
    
    func setup() {
        exampleView.descriptionLabel.text = "Drag Me"
        exampleView.animateButton.tag = 0
        exampleView.moveableContent.tag = 0
        exampleView.animateButton.addTarget(self, action: #selector(onClickExpandBtn), for: .touchUpInside)
        dragger = ViewDragger(animationView: exampleView.moveableContent, targetDraggingView: view)
        dragger.delegate = self
        updateDragger()
    }
    
    @objc func onClickExpandBtn(_ sender: UIButton) {
        if exampleView.moveableContent.superview == exampleView {
            dragger.travel(to: .forwards)
        } else {
            dragger.travel(to: .backwards)
        }
    }
    
    @IBAction func segmentUpdated(_ sender: UISegmentedControl) {
        updateDragger()
    }
}

extension ViewController: ViewDraggerDelegate {
    func travelAnimationStartFreeDragging(travelAnimation: ViewDragger, view: UIView) {}
    
    func travelAnimationFreeDraggingUpdate(travelAnimation: ViewDragger, view: UIView) {}
    
    func travelAnimationCancelFreeDragging(travelAnimation: ViewDragger, view: UIView) {}
    
    func travelAnimationEndFreeDragging(travelAnimation: ViewDragger, view: UIView, velocity: CGPoint) {}
    
    func travelAnimationDidRecoverWith(travelAnimation: ViewDragger, view: UIView, travelState: TravelState) {}
    
    func travelAnimationDidUpdateProgress(travelAnimation: ViewDragger, view: UIView, travelState: TravelState, progress: CGFloat) {}
    
    func travelAnimationDidStartWith(travelAnimation: ViewDragger, view: UIView, travelState: TravelState) {
        switch travelState {
        case .backwards:
            exampleView.updateAnimateButton(expand: true)
        case .forwards:
            exampleView.updateAnimateButton(expand: false)
        }
    }
    
    func travelAnimationDidCancelWith(travelAnimation: ViewDragger, view: UIView, travelState: TravelState) {
        switch travelState {
        case .backwards:
            exampleView.updateAnimateButton(expand: false)
        case .forwards:
            exampleView.updateAnimateButton(expand: true)
        }
    }
    
    func travelAnimationDidCompleteWith(travelAnimation: ViewDragger, view: UIView, travelState: TravelState) {}
}
