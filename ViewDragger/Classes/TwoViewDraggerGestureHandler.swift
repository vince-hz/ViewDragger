//
//  TwoViewDraggerGestureHandler.swift
//  ViewDragger
//
//  Created by xuyunshi on 2023/2/28.
//

import Foundation

class TwoViewDraggerGestureHandler: DraggerGestureHandler {
    /// Indicate the gesture ended velocity effect on animation.
    /// The smaller this is, the more likely it is that the completion animation will be triggered.
    var velocityTriggerNum = CGFloat(200)
    
    /// Indicate whether the gesture offset position is sufficient to trigger the end animation when the gesture ends.
    /// The value is between 0-1.
    var tranlationTriggerPercentNum = CGFloat(0.33333)
    
    weak var animationView: UIView!
    weak var backwardsSuperView: UIView!
    weak var forwardsSuperView: UIView!
    weak var targetDraggingView: UIView?
    weak var ref: ViewDragger!
    
    var backwardsViewFrame: CGRect
    var forwardsViewFrame: CGRect
    var gestureAxis: GestureAxis
    var animationType: AnimationType
    var animator: UIViewPropertyAnimator
    
    private var travelState = TravelState.forwards
    private(set) weak var commonAncestorView: UIView?
    var travelUnit: CGFloat = .infinity
    private var lastPanPosition: CGFloat = 0
    
    internal init(animationView: UIView,
                  backwardsSuperView: UIView,
                  forwardsSuperView: UIView,
                  targetDraggingView: UIView?,
                  backwardsViewFrame: CGRect,
                  forwardsViewFrame: CGRect,
                  gestureAxis: GestureAxis,
                  animationType: AnimationType,
                  animator: UIViewPropertyAnimator,
                  ref: ViewDragger) {
        self.animationView = animationView
        self.backwardsSuperView = backwardsSuperView
        self.forwardsSuperView = forwardsSuperView
        self.targetDraggingView = targetDraggingView
        self.backwardsViewFrame = backwardsViewFrame
        self.forwardsViewFrame = forwardsViewFrame
        self.gestureAxis = gestureAxis
        self.animationType = animationType
        self.animator = animator
        self.ref = ref
    }
    
    deinit {
        destory()
    }
    
    func destory() {
        if animator.isRunning {
            animator.stopAnimation(false)
            switch animator.state {
            case .stopped:
                animator.finishAnimation(at: .end)
            case .inactive, .active:
                return
            @unknown default:
                print("Get unknown value from animtion state \(animator.state.rawValue)")
            }
            
        }
    }
    
    func onPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            if animator.isRunning {
                stopDisplayLink()
                // Turn reversed to positive when animatin was cancel.
                animator.isReversed = false
                animator.pauseAnimation()
                if let commonAncestorView {
                    lastPanPosition = tranlationIn(gesture: gesture, gestureAxis: gestureAxis, ancestor: commonAncestorView)
                }
                if let animationView {
                    ref.delegate?.travelAnimationDidRecoverWith(travelAnimation: ref, view: animationView, travelState: travelState)
                }
            } else {
                let toState: TravelState = animationView?.superview === backwardsSuperView ? .forwards : .backwards
                if let ancestor = getCommonAncestorView() {
                    prepareAnimatorFor(toState, ancestorView: ancestor)
                    lastPanPosition = tranlationIn(gesture: gesture, gestureAxis: gestureAxis, ancestor: ancestor)
                }
            }
        case .changed:
            if let ancestor = commonAncestorView {
                let position = tranlationIn(gesture: gesture, gestureAxis: gestureAxis, ancestor: ancestor)
                let delta = (position - lastPanPosition) / travelUnit
                if let animationView {
                    let progress = animator.fractionComplete + delta
                    let limitedDelta = safeProgress(progress)
                    ref.delegate?.travelAnimationDidUpdateProgress(travelAnimation: ref,
                                                               view: animationView,
                                                               travelState: travelState,
                                                               progress: limitedDelta)
                }
                animator.fractionComplete += delta
                lastPanPosition = position
            }
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
    
    func travel(to travelState: TravelState, animated: Bool = true) {
        if let ancestor = getCommonAncestorView() {
            prepareAnimatorFor(travelState, ancestorView: ancestor)
            if animated {
                startDisplayLink(needDuration: animator.duration)
                animator.startAnimation()
            } else {
                animator.fractionComplete = 1
                animator.stopAnimation(false)
                animator.finishAnimation(at: .end)
            }
        }
    }
    
    func getCommonAncestorView() -> UIView? {
        if let targetDraggingView {
            return targetDraggingView
        }
        guard let backwardsSuperView,
              let forwardsSuperView
        else { return nil }
        return getCommonAncestor(backwardsSuperView, forwardsSuperView)
    }
    
    func tranlationIn(gesture: UIPanGestureRecognizer, gestureAxis: GestureAxis, ancestor: UIView) -> CGFloat {
        switch gestureAxis {
        case .horizontal:
            return gesture.translation(in: ancestor).x
        case .vertical:
            return gesture.translation(in: ancestor).y
        }
    }
    
    private func prepareAnimatorFor(_ travelState: TravelState, ancestorView: UIView) {
        guard
            let backwardsSuperView,
            let forwardsSuperView,
            let animationView
        else { return }
        commonAncestorView = ancestorView
        self.travelState = travelState
        animator.isReversed = false
        ref.delegate?.travelAnimationDidStartWith(travelAnimation: ref, view: animationView, travelState: travelState)
        travelUnit = getTravelUnit(forwardsSuperView: forwardsSuperView,
                                   forwardsViewFrame: forwardsViewFrame,
                                   backwardsSuperView: backwardsSuperView,
                                   backwardsViewFrame: backwardsViewFrame,
                                   commonAncestorView: ancestorView,
                                   travelState: travelState,
                                   axis: gestureAxis)
        
        let superView = animationView.superview!
        let startFrameInAncestor = superView.convert(animationView.frame, to: ancestorView)
        
        // Move view to commonAncestor
        if animationView.superview != ancestorView {
            ancestorView.addSubview(animationView)
        }
        animationView.frame = startFrameInAncestor
        switch animationType {
        case .tranform:
            let animationTransform = getTransform(forwardsSuperView: forwardsSuperView,
                                                  forwardsViewFrame: forwardsViewFrame,
                                                  backwardsSuperView: backwardsSuperView,
                                                  backwardsViewFrame: backwardsViewFrame,
                                                  commonAncestorView: ancestorView,
                                                  travelState: travelState,
                                                  currentFrameInAncestorView: startFrameInAncestor)
            animator.addAnimations {
                animationView.transform = animationTransform
            }
        case .frame:
            switch travelState {
            case .backwards:
                let endFrameInAncestor = backwardsSuperView.convert(backwardsViewFrame, to: ancestorView)
                animator.addAnimations {
                    animationView.frame = endFrameInAncestor
                }
            case .forwards:
                let endFrameInAncestor = forwardsSuperView.convert(forwardsViewFrame, to: ancestorView)
                animator.addAnimations {
                    animationView.frame = endFrameInAncestor
                }
            }
        }
        
        animator.addCompletion { [weak self] position in
            guard
                let self,
                let t = self.forwardsSuperView,
                let f = self.backwardsSuperView,
                let v = self.animationView
            else { return }
            
            switch self.animationType {
            case .frame:
                break
            case .tranform:
                v.transform = .identity
            }
            
            switch position {
            case .end:
                self.ref.delegate?.travelAnimationDidCompleteWith(travelAnimation: self.ref, view: v, travelState: travelState)
                switch travelState {
                case .backwards:
                    f.addSubview(v)
                    v.frame = self.backwardsViewFrame
                case .forwards:
                    t.addSubview(v)
                    v.frame = self.forwardsViewFrame
                }
            case .start:
                switch travelState {
                case .backwards:
                    t.addSubview(v)
                    v.frame = self.forwardsViewFrame
                case .forwards:
                    f.addSubview(v)
                    v.frame = self.backwardsViewFrame
                }
                self.ref.delegate?.travelAnimationDidCancelWith(travelAnimation: self.ref, view: v, travelState: travelState)
            case .current:
                print("cc:: scurrent ... ", self.animator.fractionComplete)
                return
            @unknown default:
                return
            }
        }
    }
    
    private func finishAnimation() {
        let lastDuration = animator.duration * (1 - animator.fractionComplete)
        // CADisplay link to track propertyAnimater seems has two frame delay. So do this.
        let framePerseconds = startDisplayLink(needDuration: lastDuration)
        if lastDuration != 0 {
            addingFractionComplete = (1 - animator.fractionComplete) / lastDuration / framePerseconds * 2
        } else {
            addingFractionComplete = 0
        }
        animator.isReversed = false
        animator.startAnimation()
    }
    
    private func cancelAnimation() {
        let spentDuration = animator.duration * animator.fractionComplete
        let framePerseconds = startDisplayLink(needDuration: spentDuration)
        if spentDuration != 0 {
            addingFractionComplete = (-animator.fractionComplete) / spentDuration / framePerseconds * 2
        } else {
            addingFractionComplete = 0
        }
        animator.isReversed = true
        animator.startAnimation()
    }
    
    var displayLink: CADisplayLink?
    var startTime = 0.0
    var displayLinkNeedDuration = 0.0
    var addingFractionComplete = 0.0
    func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    /// Return frame perSeconds
    @discardableResult
    func startDisplayLink(needDuration: Double) -> CGFloat {
        stopDisplayLink()
        startTime = CACurrentMediaTime()
        displayLinkNeedDuration = needDuration
        let displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdate))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
        if #available(iOS 15.0, *) {
            return CGFloat(displayLink.preferredFrameRateRange.maximum)
        } else {
            return CGFloat(displayLink.preferredFramesPerSecond)
        }
    }

    @objc func displayLinkUpdate(_ link: CADisplayLink) {
        let elapsed = CACurrentMediaTime() - startTime
        if elapsed > displayLinkNeedDuration {
            stopDisplayLink()
        }
        if animator.isRunning {
            if let animationView {
                let animatorProgress = animator.isReversed ? 1 - animator.fractionComplete : animator.fractionComplete
                ref.delegate?.travelAnimationDidUpdateProgress(travelAnimation: ref,
                                                           view: animationView,
                                                           travelState: travelState,
                                                           progress: safeProgress(animatorProgress + addingFractionComplete))
            }
        }
    }
}
