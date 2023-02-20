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
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.window != nil {
            DispatchQueue.main.async {
                self.dragger_0.update(forwardsViewFrame: self.view.window!.bounds)
                self.dragger_1.update(forwardsViewFrame: self.view.window!.bounds)
                if self.exampleView_0.moveableContent.superview != self.exampleView_0 {
                    self.dragger_0.travel(to: .forwards, animated: false)
                }
                if self.exampleView_1.moveableContent.superview != self.exampleView_1 {
                    self.dragger_1.travel(to: .forwards, animated: false)
                }
            }
        }
    }
    
    func setup() {
        exampleView_0.descriptionLabel.text = "Horizontal Window Drag"
        exampleView_0.animateButton.tag = 0
        exampleView_0.moveableContent.tag = 0
        exampleView_0.animateButton.addTarget(self, action: #selector(onClickExpandBtn), for: .touchUpInside)
        dragger_0 = ViewDragger(animationView: exampleView_0.moveableContent,
                                backwardsSuperView: exampleView_0,
                                forwardSuperView: view.window!,
                                backwardsViewFrame: frameInExampleContainer,
                                forwardsViewFrame: view.window!.bounds,
                                gestureAxis: .horizontal)
        dragger_0.delegate = self
        
        exampleView_1.descriptionLabel.text = "Vertical Window Drag"
        exampleView_1.animateButton.tag = 1
        exampleView_1.moveableContent.tag = 1
        exampleView_1.animateButton.addTarget(self, action: #selector(onClickExpandBtn), for: .touchUpInside)
        dragger_1 = ViewDragger(animationView: exampleView_1.moveableContent,
                                backwardsSuperView: exampleView_1,
                                forwardSuperView: view.window!,
                                backwardsViewFrame: frameInExampleContainer,
                                forwardsViewFrame: view.window!.bounds,
                                gestureAxis: .vertical)
        dragger_1.delegate = self
    }
    
    @objc func onClickExpandBtn(_ sender: UIButton) {
        let dragger = draggerFor(animateButton: sender)
        let container = containerFor(button: sender)
        if container?.moveableContent.superview == container {
            dragger.travel(to: .forwards)
        } else {
            dragger.travel(to: .backwards)
        }
    }

    @IBOutlet weak var exampleView_1: ExampleContainer!
    @IBOutlet weak var exampleView_0: ExampleContainer!
    
    var dragger_1: ViewDragger!
    var dragger_0: ViewDragger!
    
    func containerFor(button: UIButton) -> ExampleContainer? {
        switch button.tag {
        case 0: return exampleView_0
        default: return exampleView_1
        }
    }
    
    func containerFor(animationView: UIView) -> ExampleContainer? {
        switch animationView.tag {
        case 0: return exampleView_0
        default: return exampleView_1
        }
    }
    
    func draggerFor(animateButton: UIButton) -> ViewDragger {
        switch animateButton.tag {
        case 0: return dragger_0
        default: return dragger_1
        }
    }
}

extension ViewController: ViewDraggerDelegate {
    func travelAnimationDidStartWith(travelAnimation: ViewDragger, view: UIView, travelState: ViewDragger.TravelState) {
        switch travelState {
        case .backwards:
            containerFor(animationView: view)?.updateAnimateButton(expand: true)
        case .forwards:
            containerFor(animationView: view)?.updateAnimateButton(expand: false)
        }
    }
    
    func travelAnimationDidCancelWith(travelAnimation: ViewDragger, view: UIView, travelState: ViewDragger.TravelState) {
        switch travelState {
        case .backwards:
            containerFor(animationView: view)?.updateAnimateButton(expand: false)
        case .forwards:
            containerFor(animationView: view)?.updateAnimateButton(expand: true)
        }
    }
    
    func travelAnimationDidCompleteWith(travelAnimation: ViewDragger, view: UIView, travelState: ViewDragger.TravelState) {
    }
}
