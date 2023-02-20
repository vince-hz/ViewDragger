//
//  ViewTravelAnimation.swift
//  TransitionTest
//
//  Created by xuyunshi on 2023/2/17.
//

import UIKit

public protocol ViewTravelAnimationDelegate: AnyObject {
    func travelAnimationDidStartWith(travelAnimation: ViewDragger, view: UIView, travelState: ViewDragger.TravelState)
    
    func travelAnimationDidCancelWith(travelAnimation: ViewDragger, view: UIView, travelState: ViewDragger.TravelState)
    
    func travelAnimationDidCompleteWith(travelAnimation: ViewDragger, iew: UIView, travelState: ViewDragger.TravelState)
}

public class ViewDragger {
    /// The travel animation direction.
    public enum TravelState {
        /// Indicate animation from forwardsSuperView to backwardsSuperView.
        case backwards
        /// Indicate animation from backwardsSuperView to forwardsSuperView.
        case forwards
    }

    public enum GestureAxis {
        case horizontal
        case vertical
    }
    
    // MARK: - Public
    
    /// Indicate the gesture ended velocity effect on animation.
    /// The smaller this is, the more likely it is that the completion animation will be triggered.
    public var velocityTriggerNum = CGFloat(200)
    
    /// Indicate whether the gesture offset position is sufficient to trigger the end animation when the gesture ends.
    /// The value is between 0-1.
    public var tranlationTriggerPercentNum = CGFloat(0.166666)
    
    public weak var delegate: ViewTravelAnimationDelegate?
    
    /// Manually triggered animations.
    public func travel(to travelState: TravelState) {
        prepareAnimatorFor(travelState)
        animator.startAnimation()
    }
    
    public func update(backwardsViewFrame: CGRect? = nil,
                       forwardsViewFrame: CGRect? = nil,
                       gestureAxis: GestureAxis? = nil) {
        if let backwardsViewFrame { self.backwardsViewFrame = backwardsViewFrame }
        if let forwardsViewFrame { self.forwardsViewFrame = forwardsViewFrame }
        if let gestureAxis { self.gestureAxis = gestureAxis }
    }
    
    fileprivate(set) weak var animationView: UIView?
    fileprivate(set) weak var backwardsSuperView: UIView?
    fileprivate(set) weak var forwardsSuperView: UIView?
    fileprivate var backwardsViewFrame: CGRect
    fileprivate var forwardsViewFrame: CGRect
    fileprivate var gestureAxis: GestureAxis

    fileprivate var travelUnit: CGFloat = .infinity
    fileprivate var lastPanPosition: CGFloat = 0
    fileprivate var travelState = TravelState.forwards
    
    fileprivate lazy var animator = UIViewPropertyAnimator()
    
    
    /// Init
    /// - Parameters:
    ///   - animationView: which want to perform animation.
    ///   - backwardsSuperView: backwards animationView's superView.
    ///   - forwardSuperView: forwards animationView's superView.
    ///   - backwardsViewFrame: animationView frame in backwardsSuperView.
    ///   - forwardsViewFrame: animationView frame in forwardsSuperView.
    ///   - gestureAxis: indicate the panGesture's animation axis.
    public init(
        animationView: UIView,
        backwardsSuperView: UIView,
        forwardSuperView: UIView,
        backwardsViewFrame: CGRect,
        forwardsViewFrame: CGRect,
        gestureAxis: GestureAxis
    ) {
        self.animationView = animationView
        self.backwardsSuperView = backwardsSuperView
        self.forwardsSuperView = forwardSuperView
        self.backwardsViewFrame = backwardsViewFrame
        self.forwardsViewFrame = forwardsViewFrame
        self.gestureAxis = gestureAxis
        self.setup()
    }
    
    deinit {
        animator.stopAnimation(false)
        animator.finishAnimation(at: .end)
    }
    
    @objc fileprivate func onPan(_ gesture: UIPanGestureRecognizer) {
        let position: CGFloat
        switch gestureAxis {
        case .horizontal:
            position = gesture.translation(in: animationView).x
        case .vertical:
            position = gesture.translation(in: animationView).y
        }
        switch gesture.state {
        case .began:
            lastPanPosition = position
            if animator.isRunning {
                animator.pauseAnimation()
            } else {
                travelState = animationView?.superview === backwardsSuperView ? .forwards : .backwards
                prepareAnimatorFor(travelState)
            }
        case .changed:
            let delta = (position - lastPanPosition) / travelUnit
            animator.fractionComplete += delta
            lastPanPosition = position
        case .cancelled:
            cancelAnimation()
        case .ended:
            let velocity: CGFloat
            switch gestureAxis {
            case .horizontal:
                velocity = gesture.velocity(in: animationView).x
            case .vertical:
                velocity = gesture.velocity(in: animationView).y
            }
            // Velocity first
            if travelUnit > 0 {
                if velocity >= velocityTriggerNum {
                    finishAnimation()
                    return
                }
                if velocity <= -velocityTriggerNum {
                    cancelAnimation()
                    return
                }
            }
            if travelUnit < 0 {
                if velocity <= -velocityTriggerNum {
                    finishAnimation()
                    return
                }
                if velocity >= velocityTriggerNum {
                    cancelAnimation()
                    return
                }
            }
            if animator.fractionComplete >= tranlationTriggerPercentNum {
                finishAnimation()
                return
            }
            cancelAnimation()
        default:
            cancelAnimation()
        }
    }
    
    fileprivate func prepareAnimatorFor(_ travelState: TravelState) {
        guard
            let backwardsSuperView,
            let forwardsSuperView,
            let animationView,
            let window = animationView.window
        else { return }
        animator.isReversed = false
        delegate?.travelAnimationDidStartWith(travelAnimation: self, view: animationView, travelState: travelState)
        // Calc center translate
        switch gestureAxis {
        case .horizontal:
            let forwardsXInWindow = forwardsSuperView.convert(CGPoint(x: forwardsViewFrame.origin.x + forwardsViewFrame.width / 2,
                                                                      y: 0),
                                                              to: window).x
            let backwardsXInWindow = backwardsSuperView.convert(CGPoint(x: backwardsViewFrame.origin.x + backwardsViewFrame.width / 2,
                                                                        y: 0),
                                                                to: window).x
            switch travelState {
            case .backwards:
                travelUnit = backwardsXInWindow - forwardsXInWindow
            case .forwards:
                travelUnit = forwardsXInWindow - backwardsXInWindow
            }
        case .vertical:
            let forwardsYInWindow = forwardsSuperView.convert(CGPoint(x: 0,
                                                                      y: forwardsViewFrame.origin.y + forwardsViewFrame.height / 2),
                                                              to: window).y
            let backwardsYInWindow = backwardsSuperView.convert(CGPoint(x: 0,
                                                                        y: backwardsViewFrame.origin.y + backwardsViewFrame.height / 2),
                                                                to: window).y
            switch travelState {
            case .backwards:
                travelUnit = backwardsYInWindow - forwardsYInWindow
            case .forwards:
                travelUnit = forwardsYInWindow - backwardsYInWindow
            }
        }
        // Calc frametranlate
        switch travelState {
        case .backwards:
            window.addSubview(animationView)
            animationView.frame = forwardsSuperView.convert(forwardsViewFrame, to: window)
            let to = backwardsSuperView.convert(backwardsViewFrame, to: window)
            animator.addAnimations { animationView.frame = to }
        case .forwards:
            window.addSubview(animationView)
            animationView.frame = backwardsSuperView.convert(backwardsViewFrame, to: window)
            let toFrameInWindow = forwardsSuperView.convert(forwardsViewFrame, to: window)
            animator.addAnimations { animationView.frame = toFrameInWindow }
        }
        animator.addCompletion { [weak self] position in
            guard let self, let t = self.forwardsSuperView, let f = self.backwardsSuperView, let v = self.animationView
            else { return }
            switch position {
            case .end:
                self.delegate?.travelAnimationDidCompleteWith(travelAnimation: self, iew: v, travelState: travelState)
                switch travelState {
                case .backwards:
                    f.addSubview(v)
                    v.frame = self.backwardsViewFrame
                case .forwards:
                    t.addSubview(v)
                    v.frame = self.forwardsViewFrame
                }
            case .start:
                self.delegate?.travelAnimationDidCancelWith(travelAnimation: self, view: v, travelState: travelState)
                switch travelState {
                case .backwards:
                    t.addSubview(v)
                    v.frame = self.forwardsViewFrame
                case .forwards:
                    f.addSubview(v)
                    v.frame = self.backwardsViewFrame
                }
            case .current:
                return
            @unknown default:
                return
            }
        }
    }
    
    fileprivate func finishAnimation() {
        animator.isReversed = false
        animator.continueAnimation(withTimingParameters: nil, durationFactor: 1)
    }
    
    fileprivate func cancelAnimation() {
        animator.isReversed = true
        animator.continueAnimation(withTimingParameters: nil, durationFactor: 1)
    }
    
    fileprivate func setup() {
        let panGesutre = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        animationView?.addGestureRecognizer(panGesutre)
    }
}
